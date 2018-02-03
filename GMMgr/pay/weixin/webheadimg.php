<?php
	include_once("../../common.php");
	if (empty($_GET['imgurl'])) {
		$imgurl = "http://wx.qlogo.cn/mmopen/d9vmEwUicIH7LxtyewyRgdYhMIqK11OZ6OwdzFiaLPuYLQRCgTx472TqeLM4brs3FLdrsiaP9bjH9juQQnCtCUTgFpLuMUPF0xL/64"; #谭讯头像
		$res = sendGet($imgurl);
		echo base64_encode($res['res']);
		exit();
	}
	$imgurl = $_GET['imgurl'];
	$res = sendGet($imgurl);
	echo base64_encode($res['res']);
?>
