<?php
	if(!defined('IN_APP')) exit('Access Denied');
	$logFile = "log.txt";
	dbConnect("mgrdb");
	$app_secret = '650821424e78be2541d694d099cdaab1';

	//输出结果
	function output($ret, $data="") {
		$result = array();
		$result["ret"] = $ret;
		$result["data"] = $data;
		echo json_encode($result);
	}

	//生成订单
	function order() {
		global $_POST, $_SGLOBAL, $MD5_KEY;
		global $logFile;
		$cont = file_get_contents("php://input");

		writeLog("下单: $cont", $logFile);
		$param = json_decode($cont, true);

        $source = $param["source"];
        $serverID = $param["serverID"];
		$charID = $param["charID"];
		$rechargeID = $param["rechargeID"];
		$money = $param["money"];
		$productID = $param["productID"];
        $platform = $param["platform"];

        $strCont = "$MD5_KEY&$source&$serverID&$charID&$rechargeID&$money&$productID&$platform";
		$sign = md5($strCont);
		if ($sign != $param['sign']) {
			writeLog("下单: 签名错误 [$strCont]", $logFile);
			return output("FAIL","签名错误");
		}

		$orderID = genUniqueID("apple_");
		if (!makeOrder($orderID, $source, $serverID, $charID, $money, $rechargeID, $productID)) {
			writeLog("下单：插入订单失败:".$_SGLOBAL["mgrdb"]->error(), $logFile);
			return output("FAIL","插入订单失败");
		}
		return output("SUCCESS", $orderID);
	}


	//成功回调
	function callback() {
		global $_POST, $_SGLOBAL;
		global $logFile;
		$cont = file_get_contents("php://input");
		$param = json_decode($cont, true);
		
		$orderID = strval($param["orderID"]); 
		$receipt = strval($param["receipt"]);

		writeLog("回调: 单号:$orderID", $logFile);

		if (empty($receipt)) {
			writeLog("回调: 缺少回执,单号:$orderID", $logFile);
			return output("FAIL", "缺少回执");
		}

		$order = queryOrder($orderID);
		if (!$order) {
			writeLog("回调: 订单不存在,单号:$orderID", $logFile);
			return output("FAIL", "订单不存在");
		}
        
		if ($order['state'] != 0) {
			writeLog("回调: 订单已处理,单号:$orderID", $logFile);
			return output("SUCCESS", $orderID);
		}

		$sandbox = 1;
		$inAppProduct = "";
		$inAppTransID = "";
		$productID = "";
		if (!appleReceiptVerify(false, $orderID, $receipt, $inAppProduct, $inAppTransID, $sandbox)) {
			writeLog("回调: 回执验证失败,单号:$orderID 回执:$receipt", $logFile);
			return output("FAIL", "回执校验错误");
		}

		if ($inAppProduct != $order['productid']) {
			writeLog("回调: 商品标识错误 订单中:$productID,回执中:$inAppProduct,回执单号:$inAppTransID", $logFile);
			return output("FAIL", "回执商品标识不匹配");
		}

		$query = $_SGLOBAL["mgrdb"]->query("select count(1) total from recharge where extdata='$inAppTransID';");
		$row = $_SGLOBAL["mgrdb"]->fetch_array($query);
		if ($row['total'] > 0) {
			writeLog("回调: 回执单号:$inAppTransID 已经处理过,单号:$orderID", $logFile);
			return output("FAIL", "回执中的订单号已处理过");
		}
		if (!updateOrder($orderID, array("state"=>1,"extdata"=>$inAppTransID))) {
			writeLog("回调: 更新订单失败,单号:$orderID", $logFile);
			return output("FAIL", "更新订单状态失败");
		}
		writeLog("------发货成功------$orderID", $logFile);
		return output("SUCCESS", $orderID);
	}


	//苹果回执验证
	function appleReceiptVerify($isSandbox, $orderID, $receipt, &$inAppProduct, &$inAppTransID, &$sandbox) {
		global $logFile;
		$buyUrl = "https://buy.itunes.apple.com/verifyReceipt";
		$sandboxUrl = "https://sandbox.itunes.apple.com/verifyReceipt";
		$url = $isSandbox ? $sandboxUrl : $buyUrl;

		$postData = array("receipt-data"=>$receipt);
		$postData = json_encode($postData);
		$tRes = sendPost($url, $postData);
		print_r($tRes);
		if ($tRes['errno'] != 0) {
			writeLog("appleReceiptVerify: sendPost error order:$orderID res:$tRes[res] code: $tRes[errno] msg: $tRes[errmsg]\n"
				, $logFile);
			return false;
		} else {
			$response = json_decode($tRes['ret'], true);
			if (!is_array($response) || !isset($response['status'])) {
				writeLog("appleReceiptVerify: response data error:$response order:$orderID", $logFile);
				return false;
			}
			$status = $response['status'];
	        //验证成功
			if ($status == 0) {
				$receipt = $response['receipt'];
				$len = count($receipt['in_app']);
				$inApp = $receipt['in_app'][$len-1];
				if (empty($inApp)) {
					writeLog("appleReceiptVerify: in_app empty response:".$tRes['res'], $logFile);
					return false;
				}
				$inAppProduct = $inApp['product_id'];
				$inAppTransID = $inApp['transaction_id'];
				$sandbox = $isSandbox ? 1 : 0;
				writeLog("appleReceiptVerify: $inAppProduct $inAppTransID sandbox:$isSandbox", $logFile);
				return true;
			} else if ($status == 21007) {
				//是沙箱
				return appleReceiptVerify(true, $orderID, $receipt, $inAppProduct, $inAppTransID, $sandbox);
			} else if ($status == 21008) {
				//是正式
				 return appleReceiVerify(false, $orderID, $receipt, $inAppProduct, $inAppTransID, $sandbox);
			} else {
	        //验证失败
				writeLog("appleReceiptVerify: fail order:$orderID status: $status", $logFile);
				return false;
			}
		}
		return false;
	}
?>
