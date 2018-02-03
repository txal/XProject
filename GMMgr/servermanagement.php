<?php
require_once 'common.php';
isaccess("SERVERMANAGEMENT") or exit('Access Denied');
        if(empty($_GET['action'])){

            dbConnect("mgrdb");
            $curPage = 1;
            $pageSize = 8;
            if (!empty($_GET["page"])) {
                $curPage = $_GET["page"];
            }
            $query = $_SGLOBAL["mgrdb"]->query("select count(1) as total from serverlist;");
            $row = $_SGLOBAL["mgrdb"]->fetch_array($query);
            $total = $row["total"];
            $begin = ($curPage - 1) * $pageSize;
            $query = $_SGLOBAL["mgrdb"]->query("select * from serverlist limit $begin,$pageSize;");
            $servers = serverList($query);
            
        } else if(!empty($_GET["action"]) && $_GET["action"] == "deleteServer"){

            dbConnect("mgrdb");
            $db = $_SGLOBAL["mgrdb"];
            $id = (empty($_GET['id'])) ? "" : intval($_GET['id']);
            $query = $db->query("delete from serverlist where id=$id;");
            $result = $query>0 ? "SUCCESS" : "FALSE";
            echo $result;
            exit();

        } else if(!empty($_GET["action"]) && $_GET["action"] == "updateServer"){
            dbConnect("mgrdb");
            $db = $_SGLOBAL["mgrdb"];
            $id = intval($_GET['id']);
            $serverID = intval($_GET['serverid']);
            $displayID = intval($_GET['displayid']);
            $serverName = strval($_GET['servername']);
            $gateAddr = strval($_GET['gateaddr']);
            $gmAddr = strval($_GET['gmaddr']);
            $logDb = strval($_GET['logdb']);
            $state = intval($_GET['state']);
            $hot = intval($_GET['hot']);
            $time = strval($_GET['time']);
            $time = intval(strtotime($time));
            $notice = strval($_GET['notice']);
            $platform = strval($_GET['platform']);
            $version = intval($_GET['version']);
            $query = $db->query("update serverlist set serverid=$serverID,displayid=$displayID,servername='$serverName',gateaddr='$gateAddr',gmaddr='$gmAddr',logdb='$logDb',state=$state,hot=$hot,time=$time,notice='$notice',platform='$platform',version=$version where id=$id;");
            $result = $query>=0 ? "SUCCESS" : "FALSE";
            writeAdminLog("SERVERUPDATE");
            echo $result;
            exit();

        } else if(!empty($_GET["action"]) && $_GET["action"] == "addServer"){
            dbConnect("mgrdb");
            $time = time();
            $db = $_SGLOBAL["mgrdb"];
            $serverID = intval($_GET['serverid']);
            $displayID = intval($_GET['displayid']);
            $serverName = strval($_GET['servername']);
            $gateAddr = strval($_GET['gateaddr']);
            $gmAddr = strval($_GET['gmaddr']);
            $logDb = strval($_GET['logdb']);
            $state = intval($_GET['state']);
            $hot = intval($_GET['hot']);
            $notice = strval($_GET['notice']);
            $platform = strval($_GET['platform']);
            $version = intval($_GET['version']);
            $query = $db->query("insert into serverlist set serverid=$serverID,displayid=$displayID,servername='$serverName',gateaddr='$gateAddr',gmaddr='$gmAddr',logdb='$logDb',state=$state,hot=$hot,time=$time,notice='$notice',platform='$platform',version=$version;");
            $result = $query ? "SUCCESS" : "FALSE";
            writeAdminLog("SERVERINSERT");
            echo $result;
            exit();
        }

        //服务器列表
        function serverList($query){
            global $_SGLOBAL;
            $servers = array();
            while($row = $_SGLOBAL['mgrdb']->fetch_array($query)){
                $server = array();
                $server['id'] = $row['id'];
                $server['serverid'] = $row['serverid'];
                $server['displayid'] = $row['displayid'];
                $server['servername'] = $row['servername'];
                $server['gateaddr'] = $row['gateaddr'];
                $server['gmaddr'] = $row['gmaddr'];
                $server['logdb'] = $row['logdb'];
                $server['state'] = $row['state'];
                $server['hot'] = $row['hot'];
                $server['notice'] = $row['notice'];
                $server['enotice'] = urlencode($row['notice']);
                $server['platform'] = $row['platform'];
                $server['version'] = $row['version'];
                $server['time'] = makeStrTime($row['time']);
                array_push($servers,$server);
            }
            return $servers;
        }

        include template("servermanagement");