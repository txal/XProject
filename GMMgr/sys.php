<?php
require_once 'common.php';
isaccess("SYS") or exit('Access Denied');

$cmd = isset($_GET['cmd']) ? strval($_GET['cmd']) : "goGMMgr:OnGMCmdReq(0, 'lgm reload', true)";
$err = isset($_GET['err']) ? strval($_GET['err']) : "";

if (isset($_GET['action']) && $_GET['action']=='gmcmd') {
	dbConnect("mgrdb");
	$user = getUserInfo();
	$opName = $_opCodeList['GMCMD']['code'].": $cmd";
	writeAdminLog("GMCMD");
	$result = request(serverID(), "gmcmd", array("cmd"=>$cmd));
	$result = empty($result)?"":"SUCCESS";
	echo $result;
	exit();
}

include template('sys');
?>
