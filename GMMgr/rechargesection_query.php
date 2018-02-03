<?php

        require_once 'common.php';
        isaccess("RECHARGESECTIONQUERY") or exit('Access Denied');

        $stime = "";
        $etime = "";

        //充值区间
        $section = array(
            array("1-10", 1, 10),
            array("11-50", 11, 50),
            array("51-100", 51, 100),
            array("101-200", 101, 200),
            array("201-300", 201, 300),
            array("301-500", 301, 500),
            array("501-1000", 501, 1000),
            array("1001-3000", 1001, 3000),
            array("3001-5000", 3001, 5000),
            array("5001-10000", 5001, 10000),
            array("10001-20000", 10001, 20000),
            array("20001-50000", 20001, 50000),
            array("50001-100000", 50001, 100000),
            array("100001", 100001, 0x7FFFFFFF)
        );

        $resList = array();
        $tableList = array();

        if (isset($_GET['action']) && $_GET['action'] == "search") {
            $stime = $_GET['stime'];
            $etime = $_GET['etime'];

            $sitime = strtotime($stime);
            $eitime = strtotime($etime) + 24*3600-1;

            $db = dbConnect("logdb");

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
                    $sql .= "select char_id, field3 from $table where event=9";
                    if ($i < count($tableList)-1) {
                        $sql .= " union all ";
                    }
                }

                function getSection($money) {
                    global $section;
                    for ($k = count($section)-1; $k >= 0; $k--) {
                        if ($money >= $section[$k][1])
                            return $k;
                    }
                    return -1;
                }

                $totalPlayer = 0;
                $totalMoney = 0;
                $sql = "select char_id, sum(field3) as money from ($sql) as tmp group by char_id";
                $query = $db->query($sql);
                while ($row = $db -> fetch_array($query)) {
                    $money = $row['money'];
                    $seIndex = getSection($money);
                    $secName = $section[$seIndex][0];
                    if (empty($resList[$secName])) {
                        $resList[$secName] = array(0, 0, 0, 0); //人数,人数比,充值,充值比
                    }
                    $resList[$secName][0]++;
                    $resList[$secName][2] += $row['money'];
                    $totalPlayer++;
                    $totalMoney += $row['money'];
                }

                foreach ($resList as &$value) {
                    $value[1] = sprintf("%.2f%%", $value[0]/$totalPlayer*100);
                    $value[3] = sprintf("%.2f%%", $value[2]/$totalMoney*100);
                }
            }
            ksort($resList, SORT_NATURAL);
        }

        include template("rechargesection_query");

?>