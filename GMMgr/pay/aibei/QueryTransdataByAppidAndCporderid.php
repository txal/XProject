<?php
header("Content-type: text/html; charset=utf-8");
/*
 * Created on 2015-8-28
 *
 * To change the template for this generated file go to
 * Window - Preferences - PHPeclipse - PHP - Code Templates
 */
require_once ("config.php");
require_once ("base.php");
   /**
	 * 类名：demo 功能 服务器端签名与验签Demo 版本：1.0 日期：2014-06-26 '说明：
	 * '以下代码只是为了方便商户测试而提供的样例代码，商户可以根据自己的需要，按照技术文档编写,并非一定要使用该代码。
	 * '该代码仅供学习和研究爱贝云计费接口使用，只是提供一个参考。
	*/
	
	/*
	 * 此demo 代码 使用于 cp 通过主动查询方式 获取同步数据。
	 * 请求地址见文档
	 * 请求方式:post
	 * 流程：cp服务端组装请求参数并对参数签名，以post方式提交请求并获得响应数据，处理得到的响应数据，调用验签函数对数据验签。 
	 * 请求参数及请求参数格式：transdata={"appid":"123456","cporderid":"3213213"}&sign=xxxxxx&signtype=RSA
	 * 注意：只有在客户端支付成功的订单，主动查询才会有交易数据。
	 * 以下实现 各项请求参数 处理代码：
	 * 
	 * */
	function ReqData() {
	 global $queryResultUrl, $appkey, $platpkey;
	 //数据现组装成：{"appid":"12313","logintoken":"aewrasera98seuta98e"}
	 $contentdata["appid"]="3002495803";
	 $contentdata["cporderid"]="55e37ac2c0dc98972475d640";
	  //组装请求报文 格式：$reqData="transdata={"appid":"123","logintoken":"3213213"}&sign=xxxxxx&signtype=RSA" 
     $reqData = composeReq($contentdata, $appkey);
     echo "reqData:$reqData\n";
     HttpPost($queryResultUrl,$reqData);
	 
}

	ReqData();
?>
