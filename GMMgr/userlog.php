<?php 
	require_once("common.php");
	isaccess("USERLOG") or exit('Access Denied');
		
	$pageSize = 100;
	$currPage = empty($_GET["page"])?1:intval($_GET["page"]);
	$stime = makeStrTime(strtotime(date("Y-m-d",time()))-24*3600);
	$etime = makeStrTime(time());
	$searchEvent = $searchCharID = $field1= $field2= $field3= $field4= $field5= $field6="";
	$multi = "";

	$logList = array();
	if(isset($_GET['action']) && $_GET['action'] == "search") {
		$event = $_GET["event"];
		$charid = strval($_GET["charid"]);
		$stime = strval($_GET["stime"]);
		$etime = strval($_GET["etime"]);
		$field1 = (empty($_GET["field1"])) ? "" : strval($_GET["field1"]);
        $field2 = (empty($_GET["field2"])) ? "" : strval($_GET["field2"]);
        $field3 = (empty($_GET["field3"])) ? "" : strval($_GET["field3"]);
        $field4 = (empty($_GET["field4"])) ? "" : strval($_GET["field4"]);
        $field5 = (empty($_GET["field5"])) ? "" : strval($_GET["field5"]);
        $field6 = (empty($_GET["field6"])) ? "" : strval($_GET["field6"]);

		$eventList = explode(",",$event);
		$eventList = array_filter($eventList);
		$event = implode($eventList,",");

		$sitime = strtotime($stime);
		$eitime = max($sitime, strtotime($etime));

		$arrFields = array("field1"=>"'$field1'","field2"=>"'$field2'","field3"=>"'$field3'","field4"=>"'$field4'","field5"=>"'$field5'","field6"=>"'$field6'");
		foreach ($arrFields as $key=>$val){
			if($val=="''"){
				unset($arrFields[$key]);
			}
		}
        function arrToString($array){
            $string = [];
            if($array && is_array($array)){
                foreach ($array as $key=>$value){
                    $string[] = $key.'='.$value;
                }
            }
            return implode(' and ',$string);
        }
        $arrayFields = " and ".arrToString($arrFields);

		$searchEvent = $event;
		$searchCharID = $charid;

		$db = dbConnect("logdb");

		$tableList = array();
		$tmpSTime = $sitime;
		do {
			$table = "log_".date("Y_m_d", $tmpSTime);
			if ($db->query("select 0 from $table limit 0,0;", "SILENT")) {
				array_push($tableList, $table);
			}
			$tmpSTime = strtotime(date("Y-m-d", $tmpSTime)) + 24*3600;
		} while ($tmpSTime <= $eitime);
		if (count($tableList) > 0) {
			$sql = "";
			for ($i = 0; $i < count($tableList); $i++){
				$table = $tableList[$i];
				$sql .= "select * from  $table where event in(".$event.") and time>=$sitime and time<=$eitime";
				if (empty($charid) && $field1=="" && $field2=="" && $field3=="" && $field4=="" && $field5=="" && $field6==""){
					$sql .= "";
				}else if(!empty($charid) && $field1=="" && $field2=="" && $field3=="" && $field4=="" && $field5=="" && $field6==""){
                    $sql .= " and char_id=$charid";
				}else if(empty($charid) && ($field1!="" || $field2!="" || $field3!="" || $field4!="" || $field5!="" || $field6!="")){
					$sql .= $arrayFields;
				}
				else{
                    $sql .= " and char_id=$charid".$arrayFields;
				}
				if ($i < count($tableList)-1) {
					$sql .= " union all ";
				}
			}


			$totalSql = "select count(1) as total from ($sql) as table1";
			$query = $_SGLOBAL["logdb"]->query($totalSql);
			$total = $_SGLOBAL["logdb"]->fetch_array($query)["total"];

			$begin = ($currPage - 1) * $pageSize;
			$pageSql = "select * from ($sql) as table1 order by time desc limit $begin,$pageSize;";

			$query = $_SGLOBAL["logdb"]->query($pageSql);
			while ($row=$_SGLOBAL["logdb"]->fetch_array($query)) {
				$row['sevent'] = empty($eventMap[$row['event']]) ? $row['event'] : $eventMap[$row['event']];
				$row['sreason'] = empty($reasonMap[$row['reason']]) ? $row['reason'] : $reasonMap[$row['reason']];
				$row['stime'] = makeStrTime($row['time']);
				array_push($logList, $row);
			}

			$multi = multi($total, $pageSize, $currPage, "userlog.php?action=search&event=$event&charid=$charid&stime=$stime&etime=$etime&field1=$field1&field2=$field2&field3=$field3&field4=$field4&field5=$field5&field6=$field6");
		}
	}
	
	include template("userlog");
?>
