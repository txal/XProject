<?php
	require_once 'common.php';
	isaccess("RECHARGE") or exit('Access Denied');

	$pageSize = 20;
	$currPage = empty($_GET["page"]) ? 1 : intval($_GET["page"]);
	$totalRecharge = 0;
	$multi = "";
	
	dbConnect("mgrdb");
	$rechargeList = array();	

	$action = isset($_GET["action"]) ? $_GET["action"] : null;
	$searchCharID = "";
	$stime = $etime = "";

	if ($action == "searchuser") {
		$searchCharID = strval($_GET["charid"]);
		$begin = ($currPage - 1) * $pageSize;
		$totalSql = "select count(1) as total, sum(money) as money from recharge where state>0 and charid='$searchCharID';";
		$query = $_SGLOBAL["mgrdb"]->query($totalSql);
		$row = $_SGLOBAL["mgrdb"]->fetch_array($query);
		$total = $row["total"];
		$totalRecharge = $row["money"];

		$pageSql = "select * from serverlist join recharge where recharge.charid='$searchCharID' and recharge.state>0 and serverlist.serverid=recharge.serverid  order by recharge.time desc limit $begin,$pageSize";
		$query = $_SGLOBAL["mgrdb"]->query($pageSql);
		while ($row=$_SGLOBAL["mgrdb"]->fetch_array($query)) {
			$row["sstate"] = $_RECHARGE_STATE[$row["state"]];
			$row["stype"] = $_RECHARGE_TYPE[$row["type"]];
			$row["stime"] = makeStrTime($row["time"]);
			array_push($rechargeList, $row);
		}
		$multi = multi($total, $pageSize, $currPage, "recharge_query.php?action=$action&charid=$searchCharID");

	} else if ($action == "searchtime") {
		$stime = strval($_GET["stime"]);
		$etime = strval($_GET["etime"]);
		$sitime = strtotime($stime);
		$eitime = max($sitime, strtotime($etime)-1);

		$totalSql = "select count(1) as total, sum(money) as money from recharge where state>0 and time>=$sitime and time<=$eitime;";
		$query = $_SGLOBAL["mgrdb"]->query($totalSql);
		$row = $_SGLOBAL["mgrdb"]->fetch_array($query);
		$total = $row["total"];
		$totalRecharge = $row["money"];

		$begin = ($currPage - 1) * $pageSize;
		$pageSql = "select * from serverlist join recharge where recharge.state>0 and recharge.time>=$sitime and recharge.time<=$eitime and serverlist.serverid=recharge.serverid order by recharge.time desc limit $begin,$pageSize";
		$query = $_SGLOBAL["mgrdb"]->query($pageSql);
		while ($row=$_SGLOBAL["mgrdb"]->fetch_array($query)) {
			$row["sstate"] = $_RECHARGE_STATE[$row["state"]];
			$row["stype"] = $_RECHARGE_TYPE[$row["type"]];
			$row["stime"] = makeStrTime($row["time"]);
			array_push($rechargeList, $row);
		}
		$multi = multi($total, $pageSize, $currPage, "recharge_query.php?action=$action&stime=$stime&etime=$etime");

	} else if (empty($_GET["action"])) {
		$begin = ($currPage - 1) * $pageSize;
		$totalSql = "select count(1) as total, sum(money) as money from recharge where state>0;";
		$query = $_SGLOBAL["mgrdb"]->query($totalSql);
		$row = $_SGLOBAL["mgrdb"]->fetch_array($query);
		$total = $row["total"];
		$totalRecharge = $row["money"];
		if (empty($totalRecharge)) {
			$totalRecharge = 0;
		}
		$pageSql = "select * from serverlist join recharge where recharge.state>0 and serverlist.serverid=recharge.serverid  order by recharge.time desc limit $begin,$pageSize";
		$query = $_SGLOBAL["mgrdb"]->query($pageSql);
		while ($row=$_SGLOBAL["mgrdb"]->fetch_array($query)) {
			$row["sstate"] = $_RECHARGE_STATE[$row["state"]];
			$row["stype"] = $_RECHARGE_TYPE[$row["type"]];
			$row["stime"] = makeStrTime($row["time"]);
			array_push($rechargeList, $row);
		}
		$multi = multi($total, $pageSize, $currPage, "recharge_query.php");
	} else if($action == "searchsource"){
        $source = intval($_GET["source"]);
        $begin = ($currPage - 1) * $pageSize;
        $totalSql = "select count(1) as total, sum(money) as money from recharge where state>0 and source=$source;";
        $query = $_SGLOBAL["mgrdb"]->query($totalSql);
        $row = $_SGLOBAL["mgrdb"]->fetch_array($query);
        $total = $row["total"];
        $totalRecharge = $row["money"];

        $pageSql = "select * from serverlist join  recharge where source=$source and recharge.state>0 and serverlist.serverid=recharge.serverid order by recharge.time desc limit $begin,$pageSize";
        $query = $_SGLOBAL["mgrdb"]->query($pageSql);
        while ($row=$_SGLOBAL["mgrdb"]->fetch_array($query)) {
            $row["sstate"] = $_RECHARGE_STATE[$row["state"]];
            $row["stype"] = $_RECHARGE_TYPE[$row["type"]];
            $row["stime"] = makeStrTime($row["time"]);
            array_push($rechargeList, $row);
        }
        $multi = multi($total, $pageSize, $currPage, "recharge_query.php?action=$action&charid=$searchCharID");
	}

	include template('recharge_query');
?>
