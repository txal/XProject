<?php
include_once "../../../common.php";
require_once "jssdk.php";
error_reporting(E_ERROR);

$APPID = 'wx3b320acdafaa6d2c';
$APPSECRET = '72f751669cceb334768f7300a40e1145';

$url = file_get_contents("php://input");
$jssdk = new JSSDK($APPID, $APPSECRET);
$signPackage = $jssdk->GetSignPackage($url);
echo json_encode($signPackage);

?>
