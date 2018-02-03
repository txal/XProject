<?php

        require_once("common.php");
        isaccess("TASKSTOPQUERY") or exit('Access Denied');
        error_reporting(1);

        $stime = "";
        $etime = "";
        $taskList = array();

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
                    $sql .= "select char_id,field1,time from $table where event=45 and time>=$sitime and time<=$eitime";
                    if ($i < count($tableList)-1) {
                        $sql .= " union all ";
                    }
                }
                $sql = "select char_id, max(field1) as taskid, max(time) as time from ($sql) as tmp group by char_id";
                $totalSql = "select count(1) as total from ($sql) as table1";
                $query = $db->query($totalSql);
                $total = $db->fetch_array($query)["total"];

                $begin = ($currPage - 1) * $pageSize;
                $pageSql = $sql;
                $query = $db->query($pageSql);
                while ($row=$db->fetch_array($query)) {
                    array_push($taskList, $row);
                }

                //第二天没有登录查询
                $strTime = date("Y-m-d 23:59:59", time());
                $todayEnd = dt2timestamp($strTime);
                foreach ($taskList as &$row) {
                    $time = $row["time"] + 24*3600;
                    if ($time <= $todayEnd) {
                        $log = "log_".date("Y_m_d", $time);
                        $sql = "select count(1) as online from $log where event=1 and char_id='$row[char_id]' limit 1";
                        $query = $db->query($sql, true);
                        $olrow = $db->fetch_array($query);
                        if (!$olrow or $olrow['online'] <= 0) {
                            $row['lost'] = true;
                        }
                    }
                }                

                //统计数量
                $res = array();
                foreach($taskList as $val){
                    $taskid = $val['taskid'];
                    if (empty($res[$taskid])) {
                        $res[$taskid] = array(0, 0, 0, 0); //停留数量,占比,流失数,流失率
                    }
                    $res[$taskid][0]++;
                    if (!empty($val['lost'])) {
                        $res[$taskid][2]++;
                    }                    
                }

                $query = $db->query("select count(1) as total from account where time>=$sitime and time<=$eitime;");
                $row = $db -> fetch_array($query);
                $playerCount = $row['total'];
                foreach ($res as &$val) {
                    //占比
                    $val[1] = sprintf("%.2f%%", ($val[0]/$playerCount)*100);
                    //流失率
                    $val[3] = sprintf("%.2f%%", ($val[2]/$val[0])*100);
                }
                $resList = array();
                foreach ($res as $k => $v) {
                    $v[-1] = $k;
                    array_push($resList, $v);
                }
                usort($resList, function($a, $b){
                    if ($a[-1] == $b[-1]) 
                        return 0;
                    if ($a[-1] > $b[-1])
                        return 1;
                    return -1;
                });
            }
        }

        include template("taskstopquery");