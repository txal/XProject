<?php 
	require_once("common.php");
	isaccess("OPENACT") or exit('Access Denied');

	$pageSize = 50;
	$curPage = empty($_GET["page"])?1:intval($_GET["page"]);

	$actIndex = empty($_GET['actindex']) ? 0 : intval($_GET['actindex']);
	$actSubIndex = empty($_GET['actSubIndex']) ? 0 : intval($_GET['actSubIndex']);
	$fzIndex = empty($_GET['fzIndex']) ? 0 : intval($_GET['fzIndex']);

	$propID = empty($_GET['propID']) ? 0 : intval($_GET['propID']);
	$roundID = empty($_GET['roundID']) ? 0 : intval($_GET['roundID']);

	$serverID = $_COOKIE['server'];
	$awardTime = empty($_GET['awardTime']) ? 0 : intval($_GET['awardTime']);

	$fzList = request(serverID(), "fzlist");
	$hdList = request(serverID(), "hdlist");
	$bigActList = $hdList['bigActList'];
	$subActList = $hdList['subActList'];
	$bigActListJS = json_encode($hdList['bigActList']);
	$subActListJS = json_encode($hdList['subActList']);
	$fzListJS = json_encode($fzList);

	//父活动
	$actID = 0;
	$actName = "";
	if (!empty($bigActList[$actIndex])) {
		$bigActObj = $bigActList[$actIndex];
		$actID = $bigActObj['nID'];
		$actName = $bigActObj['sName'];
    }

    //子活动
	$subActID = 0;
	$subActName = "";
	if (isset($subActList[$actID])) {
		if (!empty($subActList[$actID][$actSubIndex])) {
            $subActObj = $subActList[$actID][$actSubIndex];
            $subActID = $subActObj['nID'];
            $subActName = $subActObj['sName'];
		}
	}

	//限时选秀
	$fzID = 0;
	if ($actID == 14) {
		if (!empty($fzList[$fzIndex])) {
			$fzObj = $fzList[$fzIndex];
			$fzID = $fzObj['nID'];
		}
	}

	$stimeStamp = empty($_GET['stime']) ? time() : strtotime($_GET['stime']);
	$etimeStamp = empty($_GET['etime']) ? time()+24*3600 : strtotime($_GET['etime']);
	$stime = makeStrTime(floor($stimeStamp/60)*60);
	$etime = makeStrTime(floor($etimeStamp/60)*60);
	$multi = "";

	function getActState($dbstime, $dbetime, $dbatime) {
        $now = time();
        if($now < $dbstime){
            return "将开始";
        }else if($now >= $dbstime && $now < $dbetime){
            return "进行中";
        }else if($now >= $dbetime && $now < $dbatime){
            return "领奖中";
        }else if($now >= $dbatime){
            return "已结束";
        }
        return "错误";
	}

	$list = array();
	if (empty($_GET['action'])) {
		$db = dbConnect("mgrdb");
		$query = $db->query("select count(1) total from activity;");
		$total = $db->fetch_array($query)['total'];
		$begin = ($curPage - 1) * $pageSize;
		$query = $db->query("select * from activity order by srvid desc,time desc limit $begin, $pageSize;");
		while ($row=$db->fetch_array($query)) {
			$row['optime'] = makeStrTime($row['time']);
			$row['prop'] = $row['propid'] == 0 ? '' : $row['propid'];
            $row['round'] = $row['roundid'] == 0 ? '' : $row['roundid'];
			$row['srvname'] = "";
			if (isset($row['srvid'])) {
				$row['srvname'] = $_SERVERLIST[$row['srvid']]['name'];
			}
            $dbstime = strtotime($row['stime']);
            $dbetime = strtotime($row['etime']);
            $dbatime = strtotime($row['atime']);
            $row['sstate'] = getActState($dbstime, $dbetime, $dbatime);
			array_push($list, $row);
		}
		$multi = multi($total, $pageSize, $curPage, "openact.php");

	} else if (isset($_GET['action']) && $_GET['action'] == "search") {
			$db = dbConnect("mgrdb");

			//分页
			$begin = ($curPage - 1) * $pageSize;
			if($subActID>0){
                $queryRow = $db->query("select count(1) as total from activity where actid=$actID and subactid=$subActID");
                $sql = "select * from activity where actid=$actID and subactid=$subActID order by srvid desc,time desc limit $begin,$pageSize";
			}else if($fzID>0) {
                $queryRow = $db->query("select count(1) as total from activity where actid=$actID and propid='$fzID'");
                $sql = "select * from activity where actid=$actID and propid='$fzID'order by srvid desc,time desc limit $begin,$pageSize";
			} else {
				$queryRow = $db->query("select count(1) as total from activity where actid=$actID");
                $sql = "select * from activity where actid=$actID order by srvid desc,time desc limit $begin,$pageSize";
			}
			$rowTotal = $db->fetch_array($queryRow);
			$total = $rowTotal["total"];

			$query = $db->query($sql);
			while ($row=$db->fetch_array($query)) {
				$row['optime'] = makeStrTime($row['time']);
				$row['srvname'] = "";
				if (isset($row['srvid'])) {
					$row['srvname'] = $_SERVERLIST[$row['srvid']]['name'];
				}
                $dbstime = strtotime($row['stime']);
                $dbetime = strtotime($row['etime']);
                $dbatime = strtotime($row['atime']);
                $row['sstate'] = getActState($dbstime, $dbetime, $dbatime);
				array_push($list, $row)	;
			}
        	$multi = multi($total, $pageSize, $curPage, "openact.php");

	} else if (isset($_GET['action']) && $_GET['action'] == 'open') {
			$db = dbConnect("mgrdb");
			if(isset($_GET['server']) || $_GET['serverAll']==""){
                $server = explode("|", $_GET['server']);
			}
            if($_GET['serverAll']!=""){
                $server = array();
                foreach($_SERVERLIST as $k=>$v){
                    array_push($server,$k);
                }
            }

			$time = time();
			$success = true;
            $atime = makeStrTime(floor(($etimeStamp+$awardTime)/60)*60);
            $extID = $extID1 = 0;
            if ($fzID > 0) {
            	$extID1 = $fzID;
            } else {
  		  		$extID = $roundID;
  		  		$extID1 = $propID;
          	} 


			foreach ($server as $v) {
				if (empty($v)) continue;
				$sql = "replace into activity set actid=$actID,actname='$actName',subactname='$subActName'".
					",srvid=$v,stime='$stime',etime='$etime',time=$time,subactid=$subActID".
					",atime='$atime',propid=$propID,roundid=$roundID;";
				if ($db->query($sql)) {
					$data = array("actid"=>$actID, "stime"=>strtotime($stime)
						,"etime"=>strtotime($etime),"subactid"=>$subActID
						,"extid"=>$extID,"extid1"=>$extID1,"awardtime"=>$awardTime);

					request($v, "openact", $data,true);
					writeAdminLog("OPENACT", "$actID->$subActID->$fzID->$propID->$roundID->$awardTime");
				} else {
					echo "<script>alert('开启活动失败');window.location.href='openact.php';</script>";
					$success = false;
					break;
				}
			}
			if ($success) {
				echo "<script>alert('开启活动成功');window.location.href='openact.php';</script>";
			}

	} 
	
	include template("openact");
?>
