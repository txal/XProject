<?php 
	require_once("common.php");
	isaccess("REGISTER") or exit('Access Denied');
    error_reporting(1);

	$pageSize = 20;
	$currPage = empty($_GET["page"])?1:intval($_GET["page"]);
	$multi = "";
	$total = 0;
	$stime = "";
	$etime = "";

	$memberList = array();
	$totalPlayer = 0;
	$logdb = dbConnect("logdb");

	if (isset($_GET["action"]) && $_GET["action"] == "search") {
		$stime = strval($_GET["stime"]);
		$etime = strval($_GET["etime"]);
		$sitime = strtotime($stime);
		$eitime = strtotime($etime) + 24*3600-1;

		$sql = "select count(1) total from account where time>=$sitime and time<=$eitime;";
		$query = $logdb->query($sql);
		$totalPlayer = $logdb->fetch_array($query)['total'];

		$pageList = array();
		$begin = ($currPage - 1) * $pageSize;
		$end = $begin + $pageSize - 1;

		for ($i = $eitime, $j = 0; $i >= $sitime; $i -= 24*3600, $j++) {
			if ($j >= $begin && $j <= $end) {
				$sdate = date("Y-m-d", $i);
				array_push($pageList, $sdate);
			}
			$total++;
		}
		$memberList = getMemberList($pageList);
		$multi = multi($total, $pageSize, $currPage, "register_query.php?action=search&stime=$stime&etime=$etime");

	} else if (empty($_GET["action"])) {
		$mgrdb = dbConnect('mgrdb');
		$serverID = serverID();
		$query = $mgrdb->query("select time from serverlist where serverid=$serverID;");
		$sitime = $mgrdb->fetch_array($query)['time'];
		$tmptime = date("Y-m-d", $sitime)." 0:0:0";
		$sitime = dt2timestamp($tmptime);
		
		$eitime = time();
		$total = floor($eitime/(24*3600)) - floor($sitime/(24*3600)) + 1;

		$sql = "select count(1) total from account where time>=$sitime and time<=$eitime;";
		$query = $logdb->query($sql);
		$totalPlayer = $logdb->fetch_array($query)['total'];

		$pageList = array();
		$begin = ($currPage - 1) * $pageSize;
		$end = $begin + $pageSize - 1;
		for ($i = $eitime, $j = 0; $i >= $sitime; $i -= 24*3600, $j++) {
			if ($j >= $begin && $j <= $end) {
				$sdate = date("Y-m-d", $i);
				array_push($pageList, $sdate);
			}
		}

		$memberList = getMemberList($pageList);
		$multi = multi($total, $pageSize, $currPage, "register_query.php");

	}

	function getMemberList(&$pageList) {
		global $_SGLOBAL;
		$logdb = $_SGLOBAL['logdb'];

		$dateList = array();
		foreach ($pageList as $date) {
			if (!isset($dateList[$date])) $dateList[$date] = array();
			$pageSql = "select char_id from account where from_unixtime(time, '%Y-%m-%d')='$date' order by time desc;";
			$query = $logdb->query($pageSql);
			while ($row=$logdb->fetch_array($query)) {
				array_push($dateList[$date], $row['char_id']);
			}
		}

        $memberList = array();
		foreach($dateList as $k=>$v) {
			if (!isset($memberList[$k])) $memberList[$k] = array();
			$memberList[$k]["regcount"] = count($v);
			$memberList[$k]["avgonline"] = 0;
		   	$memberList[$k]["toponline"] = 0;
		   	$memberList[$k]["oneonline"] = 0;
		  	$memberList[$k]["rechargemoney"] = 0;
		  	$memberList[$k]["rechargepeople"] = 0;
		  	$memberList[$k]["rechargerate"] = 0;
		}

		fillMemberInfo($memberList);
		return $memberList;
	}

	function fillMemberInfo(&$memberList) {
		global $_SGLOBAL;
		$logdb = $_SGLOBAL['logdb'];
		$mgrdb = dbConnect('mgrdb');
		$serverID = serverID();

		foreach ($memberList as $k=>&$v) {
			$stime = strtotime($k);
			$etime = $stime + 24*3600 - 1;
			//在线人数
			$logTable = "log_".date("Y_m_d", $stime);
			$oneOnlineSql = "select count(1) as oneonline from (select distinct char_id from $logTable where event in(1,2)) as tmp;";
			if (($query=$logdb->query($oneOnlineSql, "SILENT"))) {
				$v["oneonline"] = $logdb->fetch_array($query)["oneonline"];
			}
			$avgOnline = $topOnline = 0;
			calcOnlineInfo($logTable, $avgOnline, $topOnline, $stime, $etime);
			$v["avgonline"] = $avgOnline;
			$v["toponline"] = $topOnline;

			//充值统计
			$sql = "select sum(money) as money, count(1) as people from recharge where serverid=$serverID and time>=$stime and time<=$etime and state>=1 and type=1;";
			$query = $mgrdb->query($sql);
			$row = $mgrdb->fetch_array($query);
			$v["rechargemoney"] = $row["money"] ? $row["money"] : "0";

			$sql = "select count(1) as people from (select distinct charid from recharge where serverid=$serverID and time>=$stime and time<=$etime and state>=1 and type=1) as tmp;";
			$query = $mgrdb->query($sql);
			$row = $mgrdb->fetch_array($query);
			$v["rechargepeople"] = $row["people"];

			$v["rechargerate"] = sprintf("%.2f%%", $row["people"]/max(1,$v["oneonline"])*100);
		}
	}

	function calcOnlineInfo($logTable, &$avgOnline, &$topOnline, $stime, $etime) {
		global $_SGLOBAL;
		$logdb = $_SGLOBAL['logdb'];

		$charList = array();
		$charSql = "select event,char_id,time,field1 from $logTable where event in(1, 2) order by char_id asc, time asc;";
		$query = $logdb->query($charSql, "SILENT");

		$onlineTime = array(0, 0);
		while ($row=$logdb->fetch_array($query)) {
			$charID = $row['char_id'];
			$event = $row['event'];
			$time = $row['time'];
			$field1 = intval($row['field1']);
			if (!isset($charList[$charID])) {
				$charList[$charID] = array(array(0, 0));
			}
			$index = count($charList[$charID])-1;
			$onlineTime = &$charList[$charID][$index];
			if ($event == 1) {
				if ($onlineTime[0] > 0) {
					if ($onlineTime[1] == 0) $onlineTime[1] = max($oneonline[0], $time-$field1);

					array_push($charList[$charID], array(0, 0));
					$index = count($charList[$charID])-1;
					$onlineTime = &$charList[$charID][$index];
				}
				$onlineTime[0] = $time;

			} else if ($event == 2) {
				$onlineTime[1] = $time-1;
				if ($onlineTime[0] == 0) $onlineTime[0] = max($sitime, $time-$field1);
			}
		}


		$minOnline = array(0=>0);
		$minOnlineMap = array();
		$hourOnline = array(0=>0);
		$hourOnlineMap = array();
		foreach ($charList as $charID=>$timeList) {
			foreach ($timeList as $onlineTime) {
				$begTime = $onlineTime[0];
				$endTime = $onlineTime[1];
				$endTime = $endTime == 0 ? $etime : $endTime;

				$begMin = floor($begTime/60);
				$endMin = ceil($endTime/60);
				for ($k = $begMin; $k <= $endMin; $k++) {
					if (!isset($minOnline[$k])) $minOnline[$k] = 0;
					if (!isset($minOnlineMap[$k])) $minOnlineMap[$k] = array();
					if (empty($minOnlineMap[$k][$charID])) {
						$minOnline[$k] += 1;
						$minOnlineMap[$k][$charID] = 1;
					}
				}

				$begHour = floor($begTime/3600);
				$endHour = ceil($endTime/3600);
				for ($k = $begHour; $k <= $endHour; $k++) {
					if (!isset($hourOnline[$k])) $hourOnline[$k] = 0;
					if (!isset($hourOnlineMap[$k])) $hourOnlineMap[$k] = array();
					if (empty($hourOnlineMap[$k][$charID])) {
						$hourOnline[$k] += 1;
						$hourOnlineMap[$k][$charID] = 1;
					}
				}

			}
		}


		$topOnline = max($hourOnline);
		$avgOnline = floor(array_sum($hourOnline)/24);
	}

	include template("register_query");
	
?>