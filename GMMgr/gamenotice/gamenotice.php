<?php

        include_once("../common.php");

        $noticeData = array();
        $sql = "";
        $server = 0;

        $time = time();
        if (!isset($_GET['server'])) {
            $sql = "SELECT id,title,content,`time` FROM gamenotice WHERE effect=1 AND endtime>=$time AND server=0 ORDER BY time DESC ";
        } else {
            $server = intval($_GET['server']);
            $sql = "SELECT id,title,content,`time` FROM gamenotice WHERE effect=1 AND endtime>=$time AND (server=0 OR server={$server}) ORDER BY time DESC";
        }

        $db = dbConnect("mgrdb");
        $query = $db->query($sql);

        while($row = $db->fetch_array($query)){
            $notice = array();
            $notice['id'] = $row['id'];
            $notice['title'] = $row['title'];
            $notice['content'] = $row['content'];
            $notice['time'] = $row['time'];

            array_push($noticeData,$notice);
        }

        echo json_encode($noticeData);
?>