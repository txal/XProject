<?php
require_once '../../common.php';
require_once "pub/lib/WxPay.Api.php";
require_once "pub/example/WxPay.JsApiPay.php";
require_once 'pub/example/log.php';

//初始化日志
$logHandler= new CLogFileHandler("pub/logs/".date('Y-m-d').'.log');
$log = Log::Init($logHandler, 15);

//输出结果
function output($res, $data="") {
	$result = array();
	$result["res"] = $res;
	$result["data"] = $data;
	echo json_encode($result);
}

$json = file_get_contents("php://input");
if (empty($json)) {
	output("FAIL", "参数非法");
	exit();
}
$data = json_decode($json, true);

if (empty($data['money']) || empty($data['charid']) || empty($data['charname'])
	|| empty($data['rechargeid']) || empty($data['rechargename']) || empty($data['rechargetype'])
	|| empty($data['openid']) || empty($data['sign'])) {
		output("FAIL", "参数为空");
		Log::ERROR("参数为空:$json");
		exit();
}

$orderID = genUniqueID("wxweb_");
$money = floatval($data['money']);
$charID = strval($data['charid']);
$charName = strval($data['charname']);
$rechargeID  = strval($data['rechargeid']);
$rechargeName= strval($data['rechargename']);
$rechargeType = strval($data['rechargetype']);
$openId = strval($data['openid']);
$sign = strval($data['sign']);

$rawString = $RECHARGE_KEY.$charID.$charName.$rechargeID.$rechargeName.$rechargeType.strval($money).$openId;
if (md5($rawString) != $sign) { //这里不靠谱,网页端可以看到KEY,聊胜于无,主要靠下面的商品检测
	output("FAIL", "签名错误");
	Log::ERROR("签名错误:$rawString->".md5($rawString)."->$sign");
	exit();
}

$body = $rechargeName;
$attach = $rechargeID;
$goodsTag = "";
$serverID = 1;

$rechargeType = 20 + $rechargeType; //config.php $RECHARGE_CONF
if ($rechargeID == 0 || ($rechargeType != 21 && $rechargeType != 22)) {
	output("FAIL", "充值ID或类型错误");
	exit();
}

//查询充值表
$productMap = array();
$productList = request(serverID(), "productlist", array("type"=>$rechargeType));
$jsonProductList = json_encode($productList);
foreach ($productList as $k => $v) {
	$productMap[$v["nID"]] = $v;
}

//校验商品
if (empty($productMap[$rechargeID])) {
	output("FAIL", "充值商品不存在或服务器维护中");
	Log::ERROR("充值商品不存在或服务器维护中: type:$rechargeType id:$rechargeID");
	exit();
}

//校验金额
$productMoney = $productMap[$rechargeID]["nMoney"];
if ($productMoney != $money) {
	output("FAIL", "充值金额错误");
	Log::ERROR("充值金额错误: [$money]=>[$productMoney]");
	exit();
}

//①、获取用户openid(前端传过来)
$tools = new JsApiPay();

//②、统一下单
dbConnect("mgrdb");
Log::INFO("我们下单:".print_r($data, true));
if (!makeOrder($orderID, $serverID, $charID, $money, $rechargeID, $rechargeType)) {
	output("FAIL", "插入订单失败");
	Log::ERROR("插入订单失败");
	exit();
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
Log::INFO("统一下单: ".print_r($order, true));

$jsApiParameters = $tools->GetJsApiParameters($order);
Log::INFO("统一下单结果: ".$jsApiParameters);
output("SUCCESS", $jsApiParameters);

?>
