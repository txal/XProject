<?php

        require_once 'common.php';
        isaccess("GAMENOTICE") or exit('Access Denied');

        if(empty($_GET['action'])){
            dbConnect("mgrdb");
            $onlineCount = 0;
            $curPage = 1;
            $pageSize = 20;
            if (!empty($_GET["page"])) {
                $curPage = $_GET["page"];
            }
            $query = $_SGLOBAL["mgrdb"]->query("select count(1) as total from gamenotice;");
            $row = $_SGLOBAL["mgrdb"]->fetch_array($query);
            $total = $row["total"];
            $begin = ($curPage - 1) * $pageSize;
            $query = $_SGLOBAL["mgrdb"]->query("select gamenotice.id,server,servername,title,content,gamenotice.time,endtime,effect from gamenotice left join serverlist on gamenotice.server=serverlist.serverid order by server desc limit $begin,$pageSize;");
            $noticeList = noticeList($query);
            $multi = multi($total, $pageSize, $curPage, "youxinotice.php");
        } else if(!empty($_GET["action"]) && $_GET["action"] == "updateNotice"){
            $db = $_SGLOBAL["mgrdb"];
            $id = empty($_GET['id']) ? 0 : intval($_GET['id']);
            $title = empty($_GET['title']) ? "" : strval($_GET['title']);
            $content = empty($_GET['content']) ? "" : strval($_GET['content']);
            $endTime = empty($_GET['endTime']) ? 0 : intval(strtotime($_GET['endTime']));
            $effect = empty($_GET['effect']) ? 0 : intval($_GET['effect']);
            $time = time();
            $serverID = empty($_GET['serverID']) ? "" : intval($_GET['serverID']);
            $query = $db->query("update gamenotice set title='$title',content='$content',time='$time',endtime=$endTime,effect=$effect,server=$serverID where id=$id;");
            $result = $query>=0 ? "SUCCESS" : "FALSE";
            echo $result;
            exit();
        } else if(!empty($_GET["action"]) && $_GET["action"] == "addNotice"){
            $db = $_SGLOBAL["mgrdb"];
            $time = time();
            $title = empty($_GET['title']) ? "" : strval($_GET['title']);
            $content = empty($_GET['content']) ? "" : strval($_GET['content']);
            $serverID = empty($_GET['serverID']) ? "" : intval($_GET['serverID']);
            $endTime = empty($_GET['endTime']) ? "" : intval(strtotime($_GET['endTime']));
            $query = $db->query("insert into gamenotice set title='$title',content='$content',time=$time,endTime=$endTime,server=$serverID;");
            $result = $query>=0 ? "SUCCESS" : "FALSE";
            echo $result;
            exit();
        } else if(!empty($_GET["action"]) && $_GET["action"] == "delNotice"){
            $db = $_SGLOBAL["mgrdb"];
            $noticeID = empty($_GET['noticeID']) ? 0 : intval($_GET['noticeID']);
            $delNotice = $db->query("delete from gamenotice where id = $noticeID");
            $result = ($delNotice) ? "SUCCESS" : "FALSE";
            echo $result;
            exit();
        }


        //游戏公告
        function noticeList($query){
            global $_SGLOBAL;
            $codes = array();
            while($row = $_SGLOBAL['mgrdb']->fetch_array($query)){
                $code = array();
                $code['id'] = $row['id'];
                $code['server'] = $row['server'];
                $code['servername'] = $row['servername'];
                $code['title'] = $row['title'];
                $code['content'] = $row['content'];
                $code['econtent'] = urlencode($row['content']);
                $code['time'] = makeStrTime($row['time']);
                $code['endtime'] = makeStrTime($row['endtime']);
                $code['effect'] = $row['effect']==1 ? "有效" : "无效";
                array_push($codes,$code);
            }
            return $codes;
        }

        include  template("gamenotice");