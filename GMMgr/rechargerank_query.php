<?php

        require_once 'common.php';
        isaccess("RECHARGERANKQUERY") or exit('Access Denied');

        $stime = "";
        $resList = array();

        if (isset($_GET['action']) && $_GET['action'] == "search") {
            $stime = $_GET['stime'];

            $sitime = strtotime($stime);
            $eitime = $sitime + 24*3600-1;

            $db = dbConnect("mgrdb");
            $db2 = dbConnect("logdb");

            $curServerID = isset($_COOKIE['server']) ? $_COOKIE['server'] : 0;
            if ($curServerID == 0 && isset($_SERVERLIST)) {
                $curServerID = next($_SERVERLIST)['id'];
            }

            $sql = "SELECT charid,sum(money) as mon,max(time) as time FROM recharge WHERE time>=$sitime and time<=$eitime and serverid=$curServerID GROUP BY charid ORDER BY money DESC,time ASC 
  limit 0,1000 ";
            $query = $db -> query($sql);
            $num = 0;
            while ($row = $db -> fetch_array($query)) {
                $sql2 = "SELECT char_name,vip FROM account WHERE char_id = $row[charid]";
                $query2 = $db2 -> query($sql2);
                while ( $row2 = $db2 -> fetch_array($query2)) {
                    $num++;
                    array_push($resList,array($row2['char_name'],$row['charid'],$row['mon'],$row2['vip'],$num));
                }
            }
        }

        include template("rechargerank_query");

?>