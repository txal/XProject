<?php
	if(!defined('IN_APP')) exit('Access Denied');
	$logFile = "log.txt";
	dbConnect("mgrdb");
    $app_secret='650821424e78be2541d694d099cdaab1';


	//输出下单结果
	function output($ret,$msg,$orderId=0) {
		$result = array();
		$result["ret"] = $ret;
		$result["msg"] = $msg;
		$result["orderId"] = $orderId;
		echo json_encode($result);
	}

	//输出回调结果
	function callResult($ret){
        $result = array();
        $result["ret"] = $ret;
        echo json_encode($result);
	}

	//生成签名
	function createSign($data,$app_secret) {
		ksort($data);
        $strSign = "";
        foreach ($data as $key => $val){
            $strSign .= $key."=".$val;
        }
        $sign = $strSign.$app_secret;
		$sign = md5($sign);
		return $sign;
	}

	//生成订单
	function order() {
		global $_POST, $_SGLOBAL, $MD5_KEY;
		global $logFile;
		$cont = file_get_contents("php://input");
		$orderID = genUniqueID("yinghun_");
		writeLog("下单:".$cont." :$orderID", $logFile);

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
			writeLog("下单:签名错误 [$strCont]", $logFile);
			return output("FAIL","签名错误");
		}

		if (!makeOrder($orderID, $source, $serverID, $charID, $money, $rechargeID, $productID)) {
			writeLog("下单:".$_SGLOBAL["mgrdb"]->error(), $logFile);
			return output("FAIL","插入订单失败");
		}
		return output("SUCCESS","下单成功",$orderID);
	}

	//成功回调
	function callback() {

		global $_POST, $_SGLOBAL,$app_secret;
		global $logFile;

		//$cont = file_get_contents("php://input");
        //$log = "回调: [$cont]";
        //writeLog($log, $logFile);
		//$param = json_decode($cont, true);

		$gameId = $_POST["gameId"];
		$channelId = $_POST["channelId"];
		$appId = $_POST["appId"];
        $userId = $_POST["userId"];
        $bfOrderId = $_POST["bfOrderId"];
        $channelOrderId = $_POST["channelOrderId"];
        $callback = $_POST["callbackInfo"];
        $orderStatus = $_POST["orderStatus"];
        $channelInfo = $_POST["channelInfo"];
        $orderID = $_POST["cpOrderId"];
        $money = $_POST["money"];
        $time = $_POST["time"];
		$sdkSign = $_POST["sign"];

        writeLog("回调:".print_r($_POST, true), $logFile);
		if ($orderStatus == 0) {
            writeLog("回调: SDK支付失败 :$orderID", $logFile);
            return callResult(1);
		}

        $data = array(
            "cpOrderId" => $orderID,
            "gameId" => $gameId,
            "channelId" => $channelId,
            "appId" => $appId,
            "userId" => $userId,
            "bfOrderId" => $bfOrderId ,
            "channelOrderId" => $channelOrderId ,
            "money" => $money ,
            "callbackInfo" => $callback ,
            "orderStatus" => $orderStatus ,
            "channelInfo" => $channelInfo,
            "time"=>$time
        );

        $sign = createSign($data,$app_secret);

        if ($sign != $sdkSign) {
            writeLog("回调: 签名错误 [$sdkSign]".",$[sign]", $logFile);
            return callResult(1);
        }

		$order = queryOrder($orderID);
		if (!$order) {
			writeLog("回调: order not found order:$orderID", $logFile);
            return callResult(1);
		}

		$mon = $order['money'];
		if($money != $mon*100){
            writeLog("回调: money not equal :$mon".",".$money, $logFile);
            return callResult(1);
		}

		if ($order['state'] != 0) {
			writeLog("回调: state error [$order[state]] order:$orderID", $logFile);
            return callResult(0);
		}

		if (!updateOrder($orderID, array("state"=>1))) {
			writeLog("回调: update order state fail order:$orderID", $logFile);
            return callResult(1);
		}
		writeLog("------充值成功------$orderID", $logFile);
        return callResult(0);
	}

	//用户会话验证
	function token() {
        global $_POST,$app_secret;
        global $logFile;

        $cont = file_get_contents("php://input");
        $param = json_decode($cont, true);
        writeLog("input:[$cont]->[".print_r($param, true)."]",$logFile);

        $userId = (empty($param['userId'])) ? strval($param['userId']) : '';
        $sid = strval($param['sid']);
        $gameId = strval($param['gameId']);
        $channelId = strval($param['channelId']);
        $appId = strval($param['appId']);

        $url = "http://token.aiyinghun.com/user/token";
        $data = array("gameId"=>$gameId, "channelId"=>$channelId, "appId"=>$appId,"sid"=>$sid,"userId" => $userId);

        ksort($data);
        $strSign = "";
        foreach ($data as $key => $val){
            $strSign .= $key."=".$val;
        }
        $strSign = $strSign.$app_secret;
        writelog('签名：'.$strSign,$logFile);

        $data['sign'] = md5($strSign);
        writeLog("post:[".print_r($data, true)." url:$url]", $logFile);
        
        $res = sendPost($url, $data);
        $resData = $res['ret'];
        echo $resData;

        $ret = json_decode($res['ret'], true);
        $log = "token result: [".print_r($ret, true).",error:$res[errno],errmsg:$res[errmsg]]";
        writeLog($log, $logFile);
	}

?>
