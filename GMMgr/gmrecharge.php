<?php 
	require_once("common.php");
	isaccess("GMRECHARGE") or exit('Access Denied');
		
	$pageSize = 10;
	$currPage = empty($_GET["page"])?1:intval($_GET["page"]);
	$multi = "";

	$rechargeID = 0;
	$rechargeType = 0;
	$searchCharID = "";
	$totalRecharge = 0;

	$productList = request(serverID(), "productlist");
	$productMap = array();
	foreach ($productList as $k => $v) {
		$productMap[$v["nID"]] = $v;
	}

	$url = "gmrecharge.php";
	$where = " where recharge.state>0 and type=2 ";

	$rechargeList = array();
	if(isset($_GET['action']) && $_GET['action'] == "recharge") {
		dbConnect("mgrdb");
        dbConnect("logdb");
		$orderID = uniqid("gm_");
		$charID = strval($_GET["charid"]);
		$rechargeID = intval($_GET['rechargeid']);
		$serverID = $_COOKIE['server'];

		if (!empty($productMap[$rechargeID])) {
			$money = $productMap[$rechargeID]["nMoney"];
            $productid = $productMap[$rechargeID]["sProduct"];
			$time = time();

			$selCharIDSql = "select * from account where char_id='$charID'";
            $query_selCharIDSql = $_SGLOBAL["logdb"]->query($selCharIDSql);
            $sourceRow = $_SGLOBAL["logdb"]->fetch_array($query_selCharIDSql);
            $source = intval($sourceRow['source']);

			$sql = "insert into recharge set serverid=$serverID,orderid='$orderID',charid='$charID'"
				.",rechargeid=$rechargeID,productid='$productid',source=$source,money=$money,state=1,time=$time,type=2;";

            if(!$sourceRow){
                showAlert("此角色ID不存在");
            } else if ($_SGLOBAL["mgrdb"]->query($sql)) {
				$opDesc = $_opCodeList["GMRECHARGE"]["name"]."[$orderID,$charID,$rechargeID]";
				writeAdminLog("GMRECHARGE");
				showAlert("充值成功");
			}
			else {
				showAlert("操作失败");
			}
		} else {
			showAlert("充值ID:$rechargeID不存在");
		}

	} else if (isset($_GET['action']) && $_GET['action'] == "search") {
		$charid = strval($_GET["charid"]);
		$rechargeStr = "recharge.";
		$rechargeID = empty($_GET["rechargeid"]) ? 0 : intval($_GET["rechargeid"]);
		$searchCharID = $charid;
		if (!empty($charid)) {
			$where = " where recharge.state>0 and type=2 and charid='$charid'";
			$url = "gmrecharge.php?action=search&charid=$charid";
		}

	} else if (isset($_GET['action']) && $_GET['action'] == "productlist") {
		echo json_encode($productMap);
		exit();
	}

	dbConnect("mgrdb");
	$totalSql = "select count(1) as total, sum(money) as money from recharge $where;";
	$query = $_SGLOBAL["mgrdb"]->query($totalSql);
	$row = $_SGLOBAL["mgrdb"]->fetch_array($query);
	$total = $row["total"];
	$totalRecharge = empty($row["money"]) ? 0 : $row["money"];

	$begin = ($currPage - 1) * $pageSize;
	$joinStr = " on recharge.serverid=serverlist.serverid ";
	$pageSql = "select * from serverlist inner join recharge $joinStr".$where." order by recharge.time desc limit $begin,$pageSize;";

	$query = $_SGLOBAL["mgrdb"]->query($pageSql);
	while ($row=$_SGLOBAL["mgrdb"]->fetch_array($query)) {
		$row["sstate"] = $_RECHARGE_STATE[$row["state"]];
		$row["stype"] = $_RECHARGE_TYPE[$row["type"]];
		$row['stime'] = makeStrTime($row['time']);

		array_push($rechargeList, $row);
	}
	$multi = multi($total, $pageSize, $currPage, $url);
	
	include template("gmrecharge");
?>
