<?php
header("Content-type: text/html; charset=utf-8");
/*
 * Created on 2015-8-31
 *
 * To change the template for this generated file go to
 * Window - Preferences - PHPeclipse - PHP - Code Templates
 */
require_once ("config.php");
require_once ("base.php");
require_once ("../common.php");
 /*
 * 在客户端调用登陆接口，得到返回 logintoken 客户端把 logintoken 传给 服务端
 * 服务端组装验证令牌的请求参数：transdata={"appid":"123","logintoken":"3213213"}&sign=xxxxxx&signtype=RSA
 * 请求地址：以文档给出的为准
 */
 function ReqData() {
	global $tokenCheckUrl, $appkey, $platpkey, $appid;
	global $_POST;
	$loginToken = $_POST["logintoken"];
	//数据现组装成：{"appid":"12313","logintoken":"aewrasera98seuta98e"}
	$contentdata["appid"]="$appid";
	$contentdata["logintoken"]="$loginToken"; //这个需要调登录接口时时获取。有效期10min
	//组装请求报文 格式：$reqData="transdata={"appid":"123","logintoken":"3213213"}&sign=xxxxxx&signtype=RSA" 
	$reqData = composeReq($contentdata, $appkey);
	//echo "reqData:$reqData\n";
	HttpPost($tokenCheckUrl,$reqData);
}
ReqData();
 
?>
