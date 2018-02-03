<?php
	define('IN_APP', TRUE);
	include_once('../config.php');
	include_once('../include/class_mysql.php');
	error_reporting(0);

	$dbConf = $_SC['mgrdb'];
	$db = new dbstuff();
	$db->charset = $dbConf['dbcharset'];
	$db->connect($dbConf['dbhost'], $dbConf['dbuser'], $dbConf['dbpwd'], $dbConf['dbname'], $dbConf['dbport']);

	$type = empty($_GET['type']) ? 0 : intval($_GET['type']);
	$account = empty($_GET['account']) ? "" : strval($_GET['account']);

	$query = $db->query("select count(1) as white from whitelist where account='$account';");
	$white = $db->fetch_array($query)['white'];

	$sql = "";
	if ($white > 0 ) //所有服(包括未开放)
		$sql = "select displayid,servername,gateaddr,hot from serverlist order by serverid;";
	else if ($type == 0) //封测服(已开放的)
		$sql = "select displayid, servername,gateaddr,hot from serverlist where serverid=4 and state=1 order by serverid;";
	else if ($type == 1) //正式服(已开放的)
		$sql = "select displayid,servername,gateaddr,hot from serverlist where serverid>=1000 and state=1 order by serverid;";
	else if ($type == 2) //提审服(已开放的)
		$sql = "select displayid,servername,gateaddr,hot from serverlist where serverid=1 and state=1 order by serverid;";
	else if ($type == 3) //测试服(所有服)
		$sql = "select displayid, servername,gateaddr,hot from serverlist where state=1 order by serverid;";

	$serverList = array();
	$query = $db->query($sql);
	while ($row=$db->fetch_array($query)) {
		$gateList = array();
		$list = explode("|", $row['gateaddr']);
		foreach($list as $k=>$v) {
			if (!empty($v))	array_push($gateList, $v);
		}
		array_push($serverList, array("id"=>$row["displayid"], "name"=>$row["servername"], "hot"=>$row["hot"], "gate"=>$gateList,"notice"=>$row["notice"]));
	}
	echo json_encode($serverList);
?>
