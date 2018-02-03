<?php
	function genUniqueID($prefix) {
		return uniqid($prefix);
	}

	function makeOrder($orderID, $source, $serverID, $charID, $money, $rechargeID, $productID="") {
		global $_SGLOBAL;
		$db = dbConnect('mgrdb');
		$timeNow = time();	
		$sql = "insert into recharge set serverid=$serverID"
			.",orderid='$orderID',charid='$charID',money=$money"
			.",rechargeid='$rechargeID'"
			.",productid='$productID',state=0,source='$source'"
			.",time=$timeNow,type=1;";
		return $db->query($sql, "SILENT");
	}

	function queryOrder($orderID) {
		global $_SGLOBAL;
		$db = dbConnect('mgrdb');
		$sql = "select * from recharge where orderid='$orderID';";
		$query = $db->query($sql, "SILENT");
		if (!$query) return false;
		return $db->fetch_array($query);
	}

	function updateOrder($orderID, $data) {
		global $_SGLOBAL;
		$db = dbConnect('mgrdb');
		$sql = "update recharge set ";
		foreach($data as $k=>$v) {
			$sql .= "$k='$v',";
		}
		$sql[strlen($sql)-1] = " ";
		$sql .= "where orderid='$orderID';";
		return $db->query($sql, "SILENT");
	}
?>
