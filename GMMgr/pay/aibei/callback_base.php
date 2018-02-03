<?php
header("Content-type: text/html; charset=utf-8");
/*
 * Created on 2015-9-1
 *
 * To change the template for this generated file go to
 * Window - Preferences - PHPeclipse - PHP - Code Templates
 */
require_once ("base.php");
require_once ("config.php");
require_once ("../common.php");

//道盟热云
function reportReYun($appid, $deviceid, $uid, $orderid, $money, $areaid, $channel) {
	global $logFile;
	$url = "http://log.reyun.com/receive/rest/payment";
	$data = array(
		"appid"=>"$appid",
		"who"=>"$uid",
		"context"=>array (
			"transactionid"=>"$orderid",
			"paymenttype"=>"unknown",
			"currencytype"=>"CNY",
			"currencyamount"=>"$money",
			"virtualcoinamount"=>"unknown",
			"deviceid"=>"$deviceid",
			"iapamount"=>"unknown",
			"iapname"=>"unknown",
			"serverid"=>"$areaid",
			"channelid"=>"$channel",
			"level"=>"unknown",
		)
	);
	$data = json_encode($data);
	$res = sendPost($url, $data);
	$param = "param: [$appid] [$deviceid] [$uid] [$orderid] [$money] [$areaid] [$channel]";
	writeLog("reportReYun: $param order:$orderid res:$res[res]", $logFile);
}

function callback($appid, $platpkey) {
	global $queryResultUrl, $logFile;
	global $_SGLOBAL, $_ORDER_STATE;

	$string = $_POST;//接收post请求数据
	$cporderid;
	if($string == null) {
		writeLog("callback: 请使用post方式提交数据", $logFile);
		echo "FAILURE";
	} else {
		$transdata=$string['transdata'];
		//echo "$transdata\n";
		if(stripos("%22",$transdata)) {
			//判断接收到的数据是否做过Urldecode处理，如果没有处理则对数据进行Urldecode处理
			$string= array_map ('urldecode',$string);
		}
		$respData = 'transdata='.$string['transdata'].'&sign='.$string['sign'].'&signtype='.$string['signtype'];
		//把数据组装成验签函数要求的参数格式
		//验签函数parseResp()中只接受明文数据。数据如：transdata={"appid":"3003686553","appuserid":"10123059","cporderid":"1234qwedfq2as123sdf3f1231234r","cpprivate":"11qwe123r23q232111","currency":"RMB","feetype":0,"money":0.12,"paytype":403,"result":0,"transid":"32011601231456558678","transtime":"2016-01-23 14:57:15","transtype":0,"waresid":1}&sign=jeSp7L6GtZaO/KiP5XSA4vvq5yxBpq4PFqXyEoktkPqkE5b8jS7aeHlgV5zDLIeyqfVJKKuypNUdrpMLbSQhC8G4pDwdpTs/GTbDw/stxFXBGgrt9zugWRcpL56k9XEXM5ao95fTu9PO8jMNfIV9mMMyTRLT3lCAJGrKL17xXv4=&signtype=RSA
		writeLog("进入了2 $appid->$respData", $logFile);
		if(!parseResp($respData, $platpkey, $respJson)) {
			//验签失败
			writeLog("callback: 验证签名失败", $logFile);
		} else {
		    //验签成功
			//echo '成功'."\n";
			//以下是 验签通过之后 对数据的解析。
			$transdata=$string['transdata'];
			$arr=json_decode($transdata);
			$sdkappid=$arr->appid;
			$appuserid=$arr->appuserid;
			$cporderid=$arr->cporderid;
			$cpprivate=$arr->cpprivate;
			$money=$arr->money;
			$paytype=$arr->paytype;
			$result=$arr->result;
			$transid=$arr->transid;
			$transtime=$arr->transtime;
			$waresid=$arr->waresid;

			$log = "callback param:[$sdkappid] [$appuserid] [$cporderid] [$cpprivate] [$money] [$result] [$transid] [$transtime] [$waresid]";
			writeLog($log, $logFile);

			dbConnect();
			$query = $_SGLOBAL["db"]->query(sprintf("select * from payorder where orderId='%s';", $cporderid));
			$order = $_SGLOBAL["db"]->fetch_array($query);
			if (!$order) {
				writeLog("callback: order not found:".$cporderid, $logFile);
				echo "FAILURE";
				return;
			}

			if ($sdkappid != $appid) {
				writeLog("callback: appid error: [$sdkappid]->[$appid].order:$cporderid", $logFile);
				echo "FAILURE";
				return;
			}

			if ($order['state'] != $_ORDER_STATE['new']) {
				writeLog("callback: order: ".$cporderid." state is:".$order['state'], $logFile);
				echo "SUCCESS";
				return;
			}


			//道盟热云
			$extend = $order['extend'];
			$res = explode("|", $extend);
			if (count($res) >= 2 && $res[0] && $res[1]) {
				reportReYun($res[0], $res[1], $order['uid'], $order['orderId'], $money, $order['area_id'], $order['channel']);
			}

			//验证钱
			if ($money != $order['money']) {
				writeLog("callback: money error: [$money]->[$order[money]].order:$cporderid", $logFile);
				echo "SUCCESS";
				return;
			}

			$URL = getZoneURL($order["area_id"], "gm");
			writeLog("callback: send good url: $URL", $logFile);

			$param = '{"cmd":"sendOrderProduct","userId":"'.$order['uid'].'","product":"'.$order['product'].'","platform":"'.$order['platform'].'"}';
			$res = sendPost($URL, $param);
			$jsonRet = json_decode($res['res'], true);
			if (is_array($jsonRet) && $jsonRet[0]['state']) {
				writeLog("callback: ******发货成功", $logFile);
				$sqlUpdate = sprintf("update payorder set payAt='%s',state=%d where orderId='%s';", date('Y-m-d H:i:s'), $_ORDER_STATE['finish'], $cporderid);
				$_SGLOBAL['db']->query($sqlUpdate);
				echo "SUCCESS";
			} else {
				writeLog("callback: ******发货失败:".$res["res"], $logFile);
				echo "FAILURE";
			}
		}
	}
		
}

?>
