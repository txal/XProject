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
	 * 此demo 代码 使用于 用户契约鉴权。
	 * 请求地址见文档
	 * 请求方式:post
	 * 流程：cp服务端组装请求参数并对参数签名，以post方式提交请求并获得响应数据，处理得到的响应数据，调用验签函数对数据验签。 
	 * 请求参数及请求参数格式：transdata={"appid":"500000185","appuserid":"A100003A832D40","waresid":1}&sign=N85bxusvUozqF3iwfAq3Ts3UeyZn8mKi5BVe+H+Vg1nrcE06AhHt7IrJLO3I5njZSF4g5CbLMLiTJiXCmNsH/t35gU3bmIKFPKiw7g3aq0hMofyhgsCLXSWEOrSIa7W6mLzPcEhUkjdX9XxsASbsILHTrJwZYYG7d9PTyhqSmoA=&signtype=RSA
	 * 以下实现 各项请求参数 处理代码：
	 * 
	 * */
	
 function ReqData($appid,$appuserid,$waresid){
 	 global $ContractAuthenticationUrl, $appkey, $platpkey;
 	 //组装参数json格式：
 	  $contentdata["appid"]="3002495803";
	  $contentdata["appuserid"]="55e37ac2c0dc98972475d640";
	  $contentdata["waresid"]=1;
	  //调用函数组装json格式，并且对数据进行签名，最终组装请求参数   如：：transdata={"appid":"500000185","appuserid":"A100003A832D40","waresid":4}&sign=N85bxusvUozqF3iwfAq3Ts3UeyZn8mKi5BVe+H+Vg1nrcE06AhHt7IrJLO3I5njZSF4g5CbLMLiTJiXCmNsH/t35gU3bmIKFPKiw7g3aq0hMofyhgsCLXSWEOrSIa7W6mLzPcEhUkjdX9XxsASbsILHTrJwZYYG7d9PTyhqSmoA=&signtype=RSA
	  $reqData = composeReq($contentdata, $appkey);
      echo "reqData:$reqData\n";
      HttpPost($ContractAuthenticationUrl,$reqData);
      
 }
 

	ReqData();
 
 
?>
