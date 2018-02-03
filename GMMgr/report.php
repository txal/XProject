<?php
require_once 'common.php';
isaccess("PUBNOTICE") or exit('Access Denied');


$serverID = $_COOKIE['server'];

dbConnect("mgrdb");
if (isset($_GET['action']) && $_GET['action'] == 'pubnotice') {
	$stime = trim($_GET['stime']);
	$etime = trim($_GET['etime']);
	$rate = intval($_GET['rate']);
	$body = trim($_GET['body']);

	$user = getUserInfo();
	$sender = $user["name"];
	$time = time();

	$server = array();

    if(isset($_GET['server']) || $_GET['serverAll']==""){
        $server = explode("|", $_GET['server']);
        $server = array_filter($server);
    }
    if($_GET['serverAll']!=""){
        foreach($_SERVERLIST as $k=>$v){
            array_push($server,$k);
        }
    }

    $totalResult = "";
    foreach($server as $v){
       if (empty($v)) continue;
        $sql = "insert into notice set serverid=$v,content='$body',sender='$sender',`interval`=$rate,begintime='$stime',endtime='$etime',time=$time;";
        if($_SGLOBAL['mgrdb']->query($sql)){
            $id = $_SGLOBAL['mgrdb']->insert_id();
            $data = array("id"=>intval($id),"starttime"=>strtotime($stime),"endtime"=>strtotime($etime),"interval"=>$rate,"content"=>$body);
            $result = request($v, "pubnotice", $data,true);
            $result = (empty($result) ? "FAIL" : "SUCCESS");
            echo $result;
        }
    }
    exit();

} else if (isset($_GET['action']) && $_GET['action'] == 'delnotice') {
	$id = intval($_GET['id']);
	$data = array("id"=>$id);
	$result = request(serverID(), "delnotice", $data);
	$result = (empty($result) ? "FAIL" : "SUCCESS");
	if ($result == "SUCCESS") {
		$_SGLOBAL['mgrdb']->query("delete from notice where id=$id;");
	}
	echo $result;
	exit();

} else if (empty($_GET['action'])) {
	$curPage = 1;
	$pageSize = 10;
	if (!empty($_GET["page"])) {
		$curPage = $_GET["page"];
	}
	$query = $_SGLOBAL["mgrdb"]->query("select count(1) as total from notice;");
	$total = $_SGLOBAL["mgrdb"]->fetch_array($query)["total"];

	$begin = ($curPage - 1) * $pageSize;
	$query = $_SGLOBAL["mgrdb"]->query("select * from serverlist join notice where serverlist.serverid=notice.serverid order by notice.time desc limit $begin,$pageSize;");

	$notices = array();
	while ($row=$_SGLOBAL["mgrdb"]->fetch_array($query)) {
		$row["stime"] = makeStrTime($row["time"]);
		$row["sstate"] = (strtotime($row["endtime"])>=time()) ? "进行中" : "已结束";
		array_push($notices, $row);
	}
	$multi = multi($total, $pageSize, $curPage, "/report.php");
	include template('report');
}
?>