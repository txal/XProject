<?php
	define('IN_APP', TRUE);
	include_once('../config.php');
	include_once('../include/class_mysql.php');
	error_reporting(0);
	$appleTishenFlag = 0; 		//大于该标记的是苹果提审服
	$androidTishenFlag = 0; 	//大于该标记的是安卓提审服

	$dbConf = $_SC['mgrdb'];
	$db = new dbstuff();
	$db->charset = $dbConf['dbcharset'];
	$db->connect($dbConf['dbhost'], $dbConf['dbuser'], $dbConf['dbpwd'], $dbConf['dbname'], $dbConf['dbport']);

	$type = empty($_GET['type']) ? 0 : intval($_GET['type']);
	$account = empty($_GET['account']) ? "" : strval($_GET['account']);
	$const = empty($_GET['const']) ? 0 : intval($_GET['const']);
	$platform = empty($_GET['platform']) ? "": strval($_GET['platform']);
	$version = empty($_GET['v']) ? 0: strval($_GET['v']);

	$query = $db->query("select count(1) as white from whitelist where account='$account';");
	$white = $db->fetch_array($query)['white'];

	$sql = "";
	$tishenFlag = "";
	if ($white > 0 || $type == 0) //所有服(包括未开放)
		$sql = "select displayid,servername,gateaddr,hot,notice from serverlist order by serverid;";
	else if ($type == 1) //正式服提审服(已开放的)
		if ($platform == "ios") { //IOS
			$tishenFlag = true;
			if ($const > $appleTishenFlag) { //提审服(已开放的)
				$sql = "select displayid,servername,gateaddr,hot,notice from serverlist where serverid=2 and state=1 and platform='ios' and version=$version order by serverid;";
			} else { //正式服(已开放)
				$tishenFlag = false;
				$sql = "select displayid,servername,gateaddr,hot,notice from serverlist where serverid>=1000 and state=1 and platform='ios' and version=$version order by serverid;";
			}

		} else { //ANDROID
			$tishenFlag = true;
			if ($const > $androidTishenFlag) {//提审服(已开放的)
				$sql = "select displayid,servername,gateaddr,hot,notice from serverlist where serverid=5 and state=1 and platform='android' and version=$version order by serverid;";
			} 
			else { //正式服(已开放)
				$tishenFlag = false;
				$sql = "select displayid,servername,gateaddr,hot,notice from serverlist where serverid>=1000 and state=1 and platform='android' and version=$version order by serverid;";
			}
		}

	$serverList = array();
	if ($sql != "") {
		$tmpid = 0;
		$query = $db->query($sql);
		while ($row=$db->fetch_array($query)) {
			$gateList = array();
			$list = explode("|", $row['gateaddr']);
			foreach($list as $k=>$v) {
				if (empty($v)) continue;
				if ($white > 0) {
					$tmp = explode('-', $v);
					array_push($gateList, $tmp[0]);
				} else {
					array_push($gateList, $v);
				}
			}
			if ($white > 0) {
				$row['displayid'] = ++$tmpid;
			}
			array_push($serverList
				, array("id"=>$row["displayid"]
				, "name"=>$row["servername"]
				, "hot"=>$row["hot"]
				, "gate"=>$gateList
				, "notice"=>$row["notice"]
				, "tishen"=>$tishenFlag)
			);
		}
	}
	echo json_encode($serverList);
?>
