<?php
header("Content-type: text/html; charset=utf-8");
/**
 *功能：配置文件
 *版本：1.0
 *修改日期：2014-06-26
 '说明：
 '以下代码只是为了方便商户测试而提供的样例代码，商户可以根据自己的需要，按照技术文档编写,并非一定要使用该代码。
 '该代码仅供学习和研究爱贝云计费接口使用，只是提供一个参考。
 */
 
//爱贝商户后台接入url
// $coolyunCpUrl="http://pay.coolyun.com:6988";
$iapppayCpUrl="http://ipay.iapppay.com:9999";
//登录令牌认证接口 url
$tokenCheckUrl=$iapppayCpUrl . "/openid/openidcheck";

//下单接口 url
// $orderUrl=$coolyunCpUrl . "/payapi/order";
$orderUrl=$iapppayCpUrl . "/payapi/order";

//支付结果查询接口 url
$queryResultUrl=$iapppayCpUrl ."/payapi/queryresult";

//契约查询接口url
$querysubsUrl=$iapppayCpUrl."/payapi/subsquery";

//契约鉴权接口Url
$ContractAuthenticationUrl=$iapppayCpUrl."/payapi/subsauth";

//取消契约接口Url
$subcancel=$iapppayCpUrl."/payapi/subcancel";
//H5和PC跳转版支付接口Url
$h5url="https://web.iapppay.com/h5/exbegpay?";
$pcurl="https://web.iapppay.com/pc/exbegpay?";

//应用编号
$appid="3008496872";
//应用私钥
$appkey="MIICWgIBAAKBgQCF5KKiW1n3HSAPrnhKm3jBYrft9WCUJTA1sUFoh9Fz+CtI/J7Js4MSIf1eXAFfHD3JKFct+2x2A42kZ/e/8OaoZ4/ejQTR14C5VCIifEAVymLBwVIX7wIgA5PSvSVmNzK35BTjKexOMcWkmfZ8Dtb8cfOgDJoq2ihSSZif2SMENQIDAQABAoGAJjwrQUfrAglcLX46Nbv+GONy+M4YnVWdVcffkNUwN/jHi5kwUxMjO9te+kI11g4/iqEtfCEPUQgku61A75wAke7uRq0bBrMqidRbn1UHLVer2dvlgWT2n4NE+QBhBJlP6gu9oVIW6rvh/LnebzcIvEGsOl2Pb3oCYeBQs4Y6sMECQQC/CfZVlu6ixL1d/VBvTlatEncJfdx5Y2/2rRV6QRKEzbIIn0/G4YfRm3ODbEHUoExwZI1Zsr7/LZr0AfrtWgXlAkEAs2wZtxIh4UM6LKXfBd2JrFnVHFKbeotFV9BX4eUQ3v6QMkUR0xGaYxwNm2aNQ/CiUlbyuHXYXR89g7SoaPwgEQI/PTDztnah+YELJw/8s6pkGQvRFTk7ZaZ0No86Ue6GAAPjAuAEra+P0ZP5bB9A9tphoZ6TqCeZBiOVfpMjzOMJAkABkDCNKshGySopl2xhBbQcX0//Bi06nRoGkNcjLba+6qLg/T8RgrbApE7uCq+yZtdTNlS5DLXM4efMTPemqoOxAkBLFEBiWTEKBIjJMPGB7DWsiFTEmzbnvGwlHmPgkDuudKgCN9KTBNdaxtzllhLBf3NfwKApfSzWT67Ak5jMD8+d";
//平台公钥
$platpkey="MIGfMA0GCSqGSIb3DQEBAQUAA4GNADCBiQKBgQCb2ODeM/SnhHE9P2YZL+VuCl3EBSr6HGRHzG86EmPavmeCL7AwBgER1ghbtU5W8o5x64dlegIsjG/2xd36t/HYj7wJ1jp4Qley9ldz6lpcHuDCytvnPcya7zwPUGPr4RzORnuuOAhU4jB+KxjMKUy4mHLuj9ksuVdc+TU5CW3sJQIDAQAB";

//回调URL
$notifyURL = 'http://sg.df.baoyugame.com/30002/aibei/callback.php';
$logFile = "log.txt";

?>
