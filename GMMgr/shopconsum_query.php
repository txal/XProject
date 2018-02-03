<?php

        require_once 'common.php';
        isaccess("SHOPCONSUMEQUERY") or exit('Access Denied');

        $stime = "";
        $etime = "";
        $resList = array();

        if (isset($_GET['action']) && $_GET['action'] == "search") {
            $stime = $_GET['stime'];
            $etime = $_GET['etime'];

            $sitime = strtotime($stime);
            $eitime = strtotime($etime) + 24 * 3600 - 1;

            $db = dbConnect("logdb");
            $tableList = array();
            $tmpSTime = $sitime;
            do {
                $table = "log_" . date("Y_m_d", $tmpSTime);
                if ($db->query("select 0 from $table limit 0,0;", "SILENT")) {
                    array_push($tableList, $table);
                }
                $tmpSTime = strtotime(date("Y-m-d", $tmpSTime)) + 24 * 3600;
            } while ($tmpSTime <= $eitime);

            if (count($tableList) > 0) {
                $sql = "";
                for ($i = 0; $i < count($tableList); $i++) {
                    $table = $tableList[$i];
                    $sql .= "select reason, char_id, field3 from $table where event=4 and field1=2 and field2=2 and reason like '商城%' and time>=$sitime and time<=$eitime";
                    if ($i < count($tableList) - 1) {
                        $sql .= " union all ";
                    }
                }
                $sql = "select reason, count(distinct char_id) as total_usr, sum(field3) as total_money, count(1) as buy_times from ($sql) as tmp group by reason";

                $totalMoney = 0;
                $query = $db->query($sql);
                while ($row=$db->fetch_array($query)) {
                    //项目,购买人数,购买次数,总货币,人均消耗货币,
                    $data = array($row['reason'], $row['total_usr'], $row['buy_times'], $row['total_money'],0,0);
                    $data[4] =  sprintf("%.2f",$data[3]/max(1,$data[1]));
                    $totalMoney += $data[3];
                    array_push($resList, $data);
                }

                //占比
                foreach ($resList as &$val) {
                    $val[5] = sprintf("%.2f%%", ($val[3]/$totalMoney)*100);
                }

            }
        }

        include template("shopconsum_query");

?>