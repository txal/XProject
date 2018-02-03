<?php 
ini_set('date.timezone','Asia/Shanghai');
//error_reporting(E_ERROR);
require_once '../../../../common.php';

require_once "WxPay.JsApiPay.php";
require_once "../lib/WxPay.Api.php";
require_once 'log.php';


//初始化日志
$logHandler= new CLogFileHandler("../logs/".date('Y-m-d').'.log');
$log = Log::Init($logHandler, 15);

//打印输出数组信息
function printOrder($data) {
	echo '<font color="#f00"><b>订单信息</b></font><br/>';
    foreach($data as $key=>$value){
        echo "<div style='word-break:break-all'><font color='#00ff55;'>$key</font> : $value <div>";
    }
}

if (empty($_GET['data'])) {
	exit("参数非法1");
}
$data = json_decode($_GET['data'], true);
$pmtName = empty($_GET['pmtname']) ? "" : strval($_GET['pmtname']);

//①、获取用户openid
$tools = new JsApiPay();
$_SERVER['QUERY_STRING'] = ""; //by panda
$openId = $tools->GetOpenid();

//②、统一下单
$orderID = genUniqueID("wx_");
$money = floatval($data['money']);
$charID = strval($data['charid']);
$charName = strval($data['charname']);
$rechargeID  = strval($data['rechargeid']);
$rechargeName= strval($data['rechargename']);
$body = $rechargeName;
$attach = $rechargeID;
$goodsTag = "";
$serverID = 1;

if ($money <= 0) {
	exit("参数非法2");
}

$rechargeType = empty($pmtName) ? 11 : 12; //config.php $RECHARGE_CONF
if (!makeOrder($orderID, $serverID, $charID, $money, $rechargeID, $rechargeType, $pmtName)) {
	exit("下单失败");
}

$input = new WxPayUnifiedOrder();
$input->SetBody($body);
$input->SetAttach($attach);
$input->SetOut_trade_no($orderID);
$input->SetTotal_fee($money*100);
$input->SetTime_start(date("YmdHis"));
$input->SetTime_expire(date("YmdHis", time() + 600));
$input->SetGoods_tag($goodsTag);
$input->SetNotify_url($NOTIFY_URL);
$input->SetTrade_type("JSAPI");
$input->SetOpenid($openId);
$order = WxPayApi::unifiedOrder($input);

$orderInfo = array("订单号:"=>$orderID, "商品ID:"=>$rechargeID, "商品类型:"=>$rechargeType, "商品名称:"=>$rechargeName,
	"角色ID:"=>$charID, "角色昵称:"=>"$charName", "订单金额:"=>$money, "订单状态:"=>json_encode($order));
printOrder($orderInfo);

$jsApiParameters = $tools->GetJsApiParameters($order);

//获取共享收货地址js函数参数
$editAddress = "{}";
//$editAddress = $tools->GetEditAddressParameters();

//③、在支持成功回调通知中处理成功之后的事宜，见 notify.php
/**
 * 注意：
 * 1、当你的回调地址不可访问的时候，回调通知会失败，可以通过查询订单来确认支付是否成功
 * 2、jsapi支付时需要填入用户openid，WxPay.JsApiPay.php中有获取openid流程 （文档可以参考微信公众平台“网页授权接口”，
 * 参考http://mp.weixin.qq.com/wiki/17/c0f37d5704f0b64713d5d2c37b468d75.html）
 */
?>

<html>
<head>
    <meta http-equiv="content-type" content="text/html;charset=utf-8"/>
    <meta name="viewport" content="width=device-width, initial-scale=1"/> 
    <title>微信支付</title>
    <script type="text/javascript">
	//调用微信JS api 支付
	function jsApiCall() {
		WeixinJSBridge.invoke(
			'getBrandWCPayRequest',
			<?php echo $jsApiParameters; ?>,
			function(res){
				WeixinJSBridge.log(res.err_msg);
				//alert(res.err_code+res.err_desc+res.err_msg);
			}
		);
	}

	function callpay() {
		if (typeof WeixinJSBridge == "undefined"){
		    if( document.addEventListener ){
		        document.addEventListener('WeixinJSBridgeReady', jsApiCall, false);
		    }else if (document.attachEvent){
		        document.attachEvent('WeixinJSBridgeReady', jsApiCall); 
		        document.attachEvent('onWeixinJSBridgeReady', jsApiCall);
		    }
		}else{
		    jsApiCall();
		}
	}
	</script>
	<script type="text/javascript">
	//获取共享地址
	function editAddress() {
		WeixinJSBridge.invoke(
			'editAddress',
			<?php echo $editAddress; ?>,
			function(res){
				var value1 = res.proviceFirstStageName;
				var value2 = res.addressCitySecondStageName;
				var value3 = res.addressCountiesThirdStageName;
				var value4 = res.addressDetailInfo;
				var tel = res.telNumber;
				
				alert(value1 + value2 + value3 + value4 + ":" + tel);
			}
		);
	}
	
	window.onload = function(){
		return;
		if (typeof WeixinJSBridge == "undefined"){
		    if( document.addEventListener ){
		        document.addEventListener('WeixinJSBridgeReady', editAddress, false);
		    }else if (document.attachEvent){
		        document.attachEvent('WeixinJSBridgeReady', editAddress); 
		        document.attachEvent('onWeixinJSBridgeReady', editAddress);
		    }
		}else{
			editAddress();
		}
	};
	
	</script>
</head>
<body>
    <br/>
    <font color="#9ACD32"><b>该笔订单支付金额为<span style="color:#f00;font-size:50px"><?=$money?></span>元</b></font><br/><br/>
	<div align="center">
		<button style="width:210px; height:50px; border-radius: 15px;background-color:#FE6714; border:0px #FE6714 solid; cursor: pointer;  color:white;  font-size:16px;" type="button" onclick="callpay()" >立即支付</button>
	</div>
</body>
</html>
