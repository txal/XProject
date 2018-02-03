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
 /*
	 * 此demo 代码 使用于 用户可以对已经完成购买的契约进行退订，退订时会将契约置为退订状态，在该状态下用户仍然可以使用该商品，直到契约失效，但是不再进行自动续费。
	 * 请求地址见文档
	 * 请求方式:post
	 * 流程：cp服务端组装请求参数并对参数签名，以post方式提交请求并获得响应数据，处理得到的响应数据，调用验签函数对数据验签。 
	 * 请求参数及请求参数格式：transdata={"appid":"500000185","appuserid":"A100003A832D40","waresid":1}&sign=VvT9gHqGjwuhj07/lbcErBo6b23tX1Z5f/aiBItCw5YlFZb6MQpg/NLc9SCA6qc+S6Pw+Jqe87QiiWpXhPf1fEIclLdu5vWmbFMvA4VMW+Il+6oTJFuJItjfIfhGhljEIrgqXO5ZrNs8mrbKBkJHjUtHv1jRFzFtCQZeMgwZr3U=&signtype=RSA
	 * 以下实现 各项请求参数 处理代码：
	 * 
	 * */
	  function ReqData() {
	 global $subcancel, $appkey, $platpkey;
	 //数据现组装成：{"appid":"12313","appuserid":"aewrasera98seuta98e"}
	 $contentdata["appid"]="3002495803";
	 $contentdata["appuserid"]="55e37ac2c0dc98972475d640";
	 $contentdata["waresid"]=1;
	  //组装请求报文 格式：$reqData="transdata={"appid":"500000185","appuserid":"A100003A832D40","waresid":1}&sign=xxxxxx&signtype=RSA" 
     $reqData = composeReq($contentdata, $appkey);
     echo "reqData:$reqData\n";
     HttpPost($subcancel,$reqData);
}

	ReqData();
	 
	 
	 
	 
?>
