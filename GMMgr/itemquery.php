<?php
    require_once("common.php");
    isaccess("ITEMQUERY") or exit('Access Denied');
    error_reporting(1);

   	//物品列表
	$itemList = array(
        array("元宝", 2, 2),
        array("银两", 2, 3),
        array("粮草", 2, 4),
        array("兵力", 2, 5),
        array("活力", 2, 6),
        array("体力", 2, 8),
        array("精力", 2, 10),
        array("势力", 2, 13),
        array("外交", 2, 14),
        array("威望", 2, 24),
	);
    $propList = request(serverID(), "djlist");
    foreach ($propList as $v) {
        array_push($itemList, array($v['sName'], 1, $v['nID']));
    }

    $stime = "";
    $etime = "";
    $resList = array();

    $event = empty($_GET['event']) ? 0 : intval($_GET['event']);
    $item = empty($_GET['item']) ? 0 : intval($_GET['item']);
    $itemType = $itemList[$item][1];
    $itemID = $itemList[$item][2];

    $eventStr = $event==3 ? "增加" : "消耗";
    $itemName = $itemList[$item][0];

    if(isset($_GET['action']) && $_GET['action'] == "search"){
        $stime = strval($_GET["stime"]);
        $etime = strval($_GET["etime"]);
        $sitime = strtotime($stime);
        $eitime = strtotime($etime) + 24*3600-1;

        $pageSize = 1000;
        $currPage = empty($_GET["page"])?1:intval($_GET["page"]);

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
            for ($i = 0; $i < count($tableList); $i++) {
                $table = $tableList[$i];
                $sql .= "select reason, abs(field3) as num, char_id from $table where event=$event and field1='$itemType' and field2='$itemID' and time>=$sitime and time<=$eitime";
                if ($i < count($tableList)-1) {
                    $sql .= " union all ";
                }
            }
            $sql = "select reason, sum(num) as yuanbao, count(1) as times, count(distinct char_id) as users from ($sql) as tmp group by reason";

            $totalSql = "select count(1) as total from ($sql) as table1";
            $query = $db->query($totalSql);
            $total = $db->fetch_array($query)["total"];

            $begin = ($currPage - 1) * $pageSize;
            $pageSql = "$sql order by yuanbao desc;";
            $query = $db->query($pageSql);
            while ($row=$db->fetch_array($query)) {
                //项目,总元宝,购买次数,购买人数,占比
                array_push($resList, array($row['reason'], $row['yuanbao'], 0, $row['times'], $row['users'], $row['yuanbao'])); 
            }

            //时间段注册人数
            $query = $db->query("select count(1) as total from account where time>=$sitime and time<=$eitime;");
            $row = $db -> fetch_array($query);
            $playerCount = $row['total'];

            //人均消费
            $totalCount = 0;
            foreach ($resList as &$val) {
                $val[1] = floor($val[1]/$playerCount);
	            $totalCount += $val[1];
            }
           	//占比 
            foreach ($resList as &$val) {
                $val[2] = $val[1]/$totalCount;
                $val[2] = sprintf("%.2f", $val[2]*100)."%";
            }
        }
    }

    include template("itemquery");
?>
