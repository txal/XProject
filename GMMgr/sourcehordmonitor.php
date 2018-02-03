<?php

        require_once("common.php");
        isaccess("SOURCEHORDMONITOR") or exit('Access Denied');
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

        //消耗&增加查询
        function consumeQuery($table,$event,$itemType,$itemID, $charStr) {
            $db = dbConnect("logdb");
            if (!isLogExist($table)) return 0;

            $sql = "select sum(abs(field3)) as total from $table,account where ".
                "$table.event=$event and ".
                "account.char_id=$table.char_id and ".
                "$table.field1='$itemType' and ".
                "$table.field2='$itemID' and ".
                "$table.char_id in $charStr;";
            ;
            $num = 0;
            if ($query = $db->query($sql)) {
                $num = $db->fetch_array($query)["total"];
                $num = empty($num) ? 0 : $num;
            }
            return $num;
        }

        //某段时间活跃玩家
        function loginQuery($begTime, $endTime, &$charList, $people) {
            $db = dbConnect("logdb");

            $sql = "";
            for ($k = $begTime; $k <= $endTime; $k += 24*3600) {
                $log = "log_".date("Y_m_d", $k);
                if (isLogExist($log)) {
                    $sql .= "select distinct char_id from $log where event=1 union all ";
                }
            }
            if ($sql == "") return "(0)";
            $sql = substr($sql, 0, -10);

            $sql = "select account.char_id from (select char_id, count(1) as num from ($sql) as tmp group by char_id having num>0) as tmp,account where account.char_id=tmp.char_id and account.vip$people;";
            $query = $db->query($sql);

            $charStr = "(";
            while ($row=$db->fetch_array($query)) {
                $charStr .= "'$row[char_id]',";
                array_push($charList, $row['char_id']);
            }
            if ($charStr[strlen($charStr)-1] == ",") {
               $charStr[strlen($charStr)-1] = ")";
            } else {
                $charStr .= ")";
            }
            return $charStr;
        }

        //统计囤积
        function tunjiQuery($charList, $itemType, $itemID, $endTime, $date) {
            $db = dbConnect("logdb");

            $charStr = "(";
            $charMap = array();
            foreach ($charList as $charID) {
                $charStr .= "'$charID',";
                $charMap[$charID] = true;
            }
            $charStr[strlen($charStr)-1] = ")";

            $query = $db->query("select min(time) as ctime from account where char_id in$charStr;");
            $begTime = $db->fetch_array($query)['ctime'];
            $begTime = strtotime(date("Y-m-d", $begTime));

            $tunji = $count = 0;
            for ($k = $endTime; $k >= $begTime; $k -= 24*3600) {
                $log = "log_".date("Y_m_d", $k);
                if (isLogExist($log)) {
                    $count++;
                    $sql .= "select char_id,field4,time,id from $log where event in(3,4) and char_id in$charStr and field1='$itemType' and field2='$itemID' union all ";
                }
                if ($count>=14 || ($count>0 && $k-24*3600<$begTime)) { //一次查14个log或者时间结束
                    $sql = substr($sql, 0, -10);
                    $sql = "select char_id,field4,time,id from ($sql order by char_id asc,time desc,id desc) as tmp group by char_id;";
                    $query = $db->query($sql);
                    while($row=$db->fetch_array($query)) {
                        $tunji += $row['field4'];
                        unset($charMap[$row['char_id']]);
                    }
                    $charStr = "(";
                    foreach ($charMap as $charID=>$v) {
                        $charStr .= "'$charID',";
                    }
                    $charStr[strlen($charStr)-1] = ")"; 
                    $count = 0;
                    $sql = "";
                }
                if (count($charMap) <= 0) {
                    break;
                }
            }
            return $tunji;
        }

        $stime = "";
        $etime = "";
        $resList = array();
        $pageList = array();

        $item = empty($_GET['item']) ? 0 : intval($_GET['item']);
        $userVal = empty($_GET['user']) ? 2 : intval($_GET['user']);
        $people = ($userVal == 2) ? ">=0" : ">0";
        $itemType = $itemList[$item][1];
        $itemID = $itemList[$item][2];
        $db = dbConnect("logdb");

        if (isset($_GET['action']) && $_GET['action'] == "search") {
            $stime = strval($_GET["stime"]);
            $etime = strval($_GET["etime"]);
            $nowitime = strtotime(date("Y-m-d", time()))+24*3600-1;

            $sitime = strtotime($stime);
            $eitime = strtotime($etime) + 24*3600-1;
            $eitime = min($nowitime, $eitime);

            $tableList = array();

            //日期
            for ($s=$sitime; $s<=$eitime; $s+=24*3600) {
                $sdate = date("Y-m-d",$s);
                array_push($pageList,$sdate);
            }

            //消耗统计
            foreach ($pageList as $val) {
                //这一天的活跃玩家(一周内登陆天数不少于1天)
                $begTime = strtotime($val) - 6 * 24 * 3600;
                $endTime = strtotime($val) + 24 * 3600 - 1;
                $charList = array();
                $charStr = loginQuery($begTime, $endTime, $charList, $people);
                $xiaohao = $tunji = 0;
                $avgtunji = 0.00;
                $percent = "0.00%";

                if (count($charList)>0) {
                    $table = "log_" . date("Y_m_d", strtotime($val));
                    $zengjia = consumeQuery($table, 3, $itemType, $itemID, $charStr);
                    $xiaohao = consumeQuery($table, 4, $itemType, $itemID, $charStr);
                    $tunji = tunjiQuery($charList, $itemType, $itemID, $endTime, $val);
                    $avgtunji = sprintf("%.2f", ($tunji / max(1, count($charList))));
                    $percent = sprintf("%.2f%%", (($tunji) / max(1, $tunji + $xiaohao)) * 100);
                }
                $resList[$val] = array($xiaohao, $zengjia, $tunji, count($charList), $avgtunji, $percent);
            }
            krsort($resList, SORT_NATURAL);
        }

        include template("sourcehordmonitor");