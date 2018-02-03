<?php
//微信浏览器登陆授权
	include_once("../../common.php");
    require_once("pub/lib/WxPay.Config.php");

	$appId = WxPayConfig::APPID;
	$secret = WxPayConfig::APPSECRET;
	$baseUrl = 'http://'.$_SERVER['HTTP_HOST'].$_SERVER['REQUEST_URI'];
	$baseUrl = urlencode($baseUrl);
	if (empty($_GET['code'])) {
		$url = "https://open.weixin.qq.com/connect/oauth2/authorize?appid=$appId&redirect_uri=$baseUrl&response_type=code&scope=snsapi_userinfo&state=STATE#wechat_redirect"; 
		Header("Location: $url");
		exit();
	}
	$code = $_GET['code'];
	$url = "https://api.weixin.qq.com/sns/oauth2/access_token?appid=$appId&secret=$secret&code=$code&grant_type=authorization_code";
	$json = file_get_contents($url);
	$resp = json_decode($json, true);
	if (empty($resp['access_token'])) {
		writeLog($json, "weblogin.log");
	}
	$access_token = $resp['access_token'];
	$openId = $resp['openid'];
	$url = "https://api.weixin.qq.com/sns/userinfo?access_token=$access_token&openid=$openId&lang=zh_CN";
	$json = file_get_contents($url);
	$resp = json_decode($json, true);
	if (!empty($resp['nickname'])) {
		$time = time();
		$min = ceil($time / 60) + 1; //最小1分钟,多大两分钟

		$key = md5($MD5_KEY.$min);
		$roomid = empty($_GET['roomid']) ? 0 : $_GET['roomid'];
		$pkid = empty($_GET['pkid']) ? 0 : $_GET['pkid'];
		$pksign = empty($_GET['pksign']) ? 0 : $_GET['pksign'];
		$pkname = empty($_GET['pkname']) ? 0 : $_GET['pkname'];
		$pkimg= empty($_GET['pkimg']) ? 0 : $_GET['pkimg'];

		$b64json = base64_encode($json);
		$data = base64_encode("user=$b64json&key=$key&roomid=$roomid&pkid=$pkid&pksign=$pksign&pkname=$pkname&pkimg=$pkimg");

		$signStr = $MD5_KEY.$resp['openid'].$resp['nickname'].$resp['sex'].$resp['unionid'];
		$sign = md5($signStr); //感觉没必要

		$gameUrl = "http://sgadmin.df.baoyugame.com/chess/web-mobile/?data=$data";
		Header("Location: $gameUrl");
	} else {
		echo "获取微信玩家信息失败";
	}

?>
