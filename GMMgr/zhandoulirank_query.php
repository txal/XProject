<?php

        require_once 'common.php';
        isaccess("ZHANDOULIRANKQUERY") or exit('Access Denied');

        $stime = "";
        $resList = array();

        $db = dbConnect("logdb");

        //排行榜
        $listRank = array(
            array("国力榜","国力"),
            array("威望榜","威望"),
            array("妃子榜","妃子亲密度")
        );

        $item = (empty($_GET['item'])) ? 0 : intval($_GET['item']);
        $title = $listRank[$item][0];
        $columName = $listRank[$item][1];

        if (isset($_GET['action']) && $_GET['action'] == "search") {
            $stime = $_GET['stime'];
            $sitime = strtotime($stime);
            $eitime = strtotime($stime) + 24*3600-1;
            $curDate = strtotime(date("Y-m-d")) + 24*3600-1;

            if ($item == 0) {
                $sql = "SELECT charid,charname,vip,recharge, max(rankvalue)as rankvalue FROM ranking WHERE time<=$curDate AND rankid=2 GROUP BY charid ORDER BY rankvalue DESC LIMIT 0,500";

            } else if ($item == 1) {
                $sql = "SELECT charid,charname,vip,recharge, max(rankvalue)as rankvalue FROM ranking WHERE time<=$curDate AND rankid=5 GROUP BY charid ORDER BY rankvalue DESC LIMIT 0,500";

            } else {
                $sql = "SELECT charid,charname,vip,recharge, max(rankvalue)as rankvalue FROM ranking WHERE time<=$curDate AND rankid=8 GROUP BY charid ORDER BY rankvalue DESC LIMIT 0,500";
            }

            $num = 0;
            $query = $db -> query($sql);
            while ($row = $db -> fetch_array($query)) {
                $num++;
                $row['num'] = $num;
                array_push($resList,$row);
            }
        }

        include template("zhandoulirank_query");

?>