<?php
    require_once("common.php");
    isaccess("USERLOG") or exit('Access Denied');
    error_reporting(1);
	$db = dbConnect("logdb");

	$begTime = "2017-08-25 00:00:00";
	$endTime = "2017-08-27 23:59:59";
	$iBegTime = strtotime($begTime);
	$iEndTime = strtotime($endTime);

	$lcList = array();
	for ($k = $iBegTime; $k <= $iEndTime; ) {
		$stime = $k;
		$etime = $k + 24*3600 - 1;
		$k += 24*3600;
		$day= date("Y_m_d", $etime);
		//$query = $db->query("select count(char_id) as total  from account where time>=$stime and time<=$etime");
		$logTable = "log_$day";
		$query = $db->query("select count(1) as total from (select distinct char_id from $logTable where event=1) as tmp;");
		$row = $db->fetch_array($query);	
		$lcList[$day] = $row['total'];
	}
	foreach($lcList as $k=>$v) {
		echo "$k $v<br/>";
	}
?>
