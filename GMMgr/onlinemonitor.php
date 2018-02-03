<?php

        require_once 'common.php';
        if (!isaccess("ONLINEMONITOR")) {
            exit('Access Denied');
        }

        $db = dbConnect("logdb");

        $stime = "";
        $resList = array();

        if (!empty($_GET['action']) && $_GET['action'] == "search") {
            $stime = empty($_GET['searchTime']) ? 0 : strval($_GET['searchTime']);
            $sitime = strtotime($stime);
            $searchTime = date("Y_m_d", $sitime);
            $table = "log_" .$searchTime;

            $charSql = "select event,char_id,field1, time from $table where event in(1, 2) order by char_id asc, time asc;";
            $query = $_SGLOBAL['logdb']->query($charSql, "SILENT");

            $onlineTime = array(0, 0);
            $charList = array();
            while ($row=$_SGLOBAL['logdb']->fetch_array($query)) {
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
                            if ($onlineTime[1] == 0) $onlineTime[1] = max($onlineTime[0], $time-$field1);

                            array_push($charList[$charID], array(0, 0));
                            $index = count($charList[$charID])-1;
                            $onlineTime = &$charList[$charID][$index];
                        }
                        $onlineTime[0] = $time;

                    } else if ($event == 2) {
                        $onlineTime[1] = $time-1;
                        if ($onlineTime[0] == 0) {
                            $onlineTime[0] = max($sitime,$time-$field1);
                        }
                    }
            }


            
            $lidu = 300; //粒度5分钟
            $timeOnline = array();
            $timeOnlineMap = array();
            foreach ($charList as $charID=>$timeList) {
                foreach ($timeList as $onlineTime) {
                    $begTime = $onlineTime[0];
                    $endTime = $onlineTime[1];

                    $begMin = floor($begTime/$lidu);
                    $endMin = floor($endTime/$lidu);

                    for ($k = $begMin; $k <= $endMin; $k++) {

                        if (!isset($timeOnline[$k])) $timeOnline[$k] = 0;
                        if (!isset($timeOnlineMap[$k])) $timeOnlineMap[$k] = array();
                        if (empty($timeOnlineMap[$k][$charID])) {
                            $timeOnline[$k] += 1;
                            $timeOnlineMap[$k][$charID] = 1;
                        }
                    }
                }
            }

            $unitList = array();
            $flagUnit = floor($sitime/$lidu);

            foreach($timeOnline as $k=>$v) {
                $unit = $k - $flagUnit;
                assert($unit >= 0 && $unit <= 288);
                $unitList[$unit] = array($v, 0, 0, 0); //总在线,新用户,老用户,无效用户
                //角色列表
                $charList = "(";
                $userCount = 0;
                foreach ($timeOnlineMap[$k] as $charID=>$v) {
                    $charList .= $charID.",";
                    $userCount += 1;
                }
                $charList[strlen($charList)-1] = ")";


                //新用户
                $newstime = $sitime;
                $newetime = $sitime + ($unit+1)*$lidu - 1;
                $query = $db->query("select count(1) total from account where char_id in $charList and time>=$newstime  and time<=$newetime;");
                $newUser = $db->fetch_array($query)['total'];
                $unitList[$unit][1] = $newUser;

                //老用户
                $oldetime = $sitime - 1;
                $query = $db->query("select count(1) total from account where char_id in $charList and time<=$oldetime;");
                $oldUser = $db->fetch_array($query)['total'];
                $unitList[$unit][2] = $oldUser;

                //无效用户
                $query = $db->query("select count(1) total from account where char_id in $charList;");
                $validUser = $db->fetch_array($query)['total'];
                $unitList[$unit][3] = $userCount - $validUser;
            }
            ksort($unitList);

            $resList = array();
            foreach ($unitList as $unit=>$value) {
                $hour = floor($unit/12);
                $min = ($unit%12)*5;
                $k = sprintf("%02d:%02d", $hour, $min);
                $resList[$k] = $value;
            }
        }

        include template("onlinemonitor");

?>