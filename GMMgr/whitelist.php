<?php

        require_once 'common.php';
        isaccess("WHITELIST") or exit('Access Denied');

        function isAccount($db,$table,$account) {
            global $_SGLOBAL;
            dbConnect($db);
            $sql = "SELECT * FROM $table WHERE account='$account'";
            $query = $_SGLOBAL[$db] -> query($sql);
            $row = $_SGLOBAL[$db] -> fetch_array($query);

            return $row;
        }

        if(empty($_GET['action'])){

            dbConnect("mgrdb");
            dbConnect("logdb");

            $resArray = array();

            $curPage = 1;
            $pageSize = 8;
            if (!empty($_GET["page"])) {
                $curPage = $_GET["page"];
            }
            $query = $_SGLOBAL["mgrdb"]->query("select count(1) as total from whitelist;");
            $row = $_SGLOBAL["mgrdb"]->fetch_array($query);
            $total = $row["total"];
            $begin = ($curPage - 1) * $pageSize;
            $query = $_SGLOBAL["mgrdb"]->query("select * from whitelist ORDER BY time DESC limit $begin,$pageSize;");

            while ($row = $_SGLOBAL["mgrdb"] -> fetch_array($query)) {
                $res = array();
                $res['account'] = $row['account'];
                $res['time'] = makeStrTime($row['time']);
                array_push($resArray,$res);
            }

        } elseif (!empty($_GET['action']) && $_GET['action'] == "addWhite") {
            $time = time();
            $account = strval($_GET['account']);

            //检测此玩家是否在玩家表
            $isAccount = isAccount("logbd","account",$account);

            //检测此玩家是否在白名单表
            $isWhiteAccount = isAccount("mgrdb","whitelist",$account);


            if ($isWhiteAccount) {
                $result = "EXIT";
                echo $result;
                exit();

            } else {
                $sql = "INSERT INTO whitelist SET account='$account',time=$time";
                $query = $_SGLOBAL["mgrdb"] -> query($sql);

                if ($query) {
                    $result = "SUCCESS";
                } else {
                    $result = "FALSE";
                }
                echo $result;
                exit();
            }

        } elseif (!empty($_GET['action']) && $_GET['action'] == "delWhite") {
            $account = strval($_GET['account']);
            $sql = "DELETE FROM whitelist WHERE account='$account'";
            $query = $_SGLOBAL["mgrdb"] -> query($sql);

            if ($query) {
                $result = "SUCCESS";
            } else {
                $result = "FALSE";
            }
            echo $result;
            exit();
        }

        include template("whitelist");

?>