<?php
require_once 'common.php';
isaccess("USERMAIL") or exit('Access Denied');

$receiver = isset($_GET["target"]) ? strval($_GET["target"]) : "";
$title = isset($_GET["title"]) ? strval($_GET["title"]) : "";
$content = isset($_GET["content"]) ? strval($_GET["content"]) : "";
$itemlist = isset($_GET["itemlist"]) ? strval($_GET["itemlist"]) : "";
$serverid = isset($_GET["serverid"]) ? intval($_GET["serverid"]) : 0;
$sendtime = isset($_GET["sendtime"]) ? intval(strtotime($_GET["sendtime"])) : 0;
$sendtime = $sendtime == 0 ? time() : $sendtime;
$strTime = makeStrTime($sendtime);
$time = time();

if($receiver<0){
    $server = true;
    $receiver = "";
}else{
    $server = false;
    $receiver = $receiver;
}
$curServerID = isset($_COOKIE['server']) ? $_COOKIE['server'] : 0;
if ($curServerID == 0 && isset($_SERVERLIST)) {
    $curServerID = next($_SERVERLIST)['id'];
}


if (isset($_GET['action']) && $_GET['action'] == 'sendmail') {

    dbConnect("logdb");
    $selCharIDSql = "select * from account where char_id='$receiver'";
    $query_selCharIDSql = $_SGLOBAL["logdb"]->query($selCharIDSql);
    $sourceRow = $_SGLOBAL["logdb"]->fetch_array($query_selCharIDSql);

    $user = getUserInfo();
    $itemlist = $itemlist == "" ? "[]" : $itemlist;
    $sql = "insert into sendmail set sender='$user[name]',serverid=$serverid,title='$title',content='$content',receiver='$receiver',itemlist='$itemlist',time=$time,sendtime=$sendtime;";

    if($receiver==""){
        $mail = array("title"=>$title, "content"=>$content, "itemlist"=>$itemlist,"target"=>$receiver);
        $query = $_SGLOBAL["mgrdb"]->query($sql);
        $result = ($query) ? "SUCCESS" : "FAIL";
        writeAdminLog("USERMAIL", print_r($mail, true));
        echo $result;
        exit();
    }
    else if(!$sourceRow){
    	$result = "NOTEXIST";
    	echo $result;
    	exit();

	}else{
        $mail = array("title"=>$title, "content"=>$content, "itemlist"=>$itemlist,"target"=>$receiver);
        $query = $_SGLOBAL["mgrdb"]->query($sql);
        $result = ($query) ? "SUCCESS" : "FAIL";
        writeAdminLog("USERMAIL", print_r($mail, true));
        echo $result;
        exit();
    }
} else if (isset($_GET['action']) && $_GET['action'] == 'deleteMail') {
    dbConnect("mgrdb");
    $db = $_SGLOBAL["mgrdb"];
    $id = (empty($_GET['id'])) ? "" : intval($_GET['id']);
    $query = $db->query("delete from sendmail where id=$id;");
    $result = $query>0 ? "SUCCESS" : "FALSE";
    echo $result;
    exit();
}

$pageSize = 10;
$currPage = empty($_GET['page']) ?1:intval($_GET['page']);
$total = 0;

dbConnect("mgrdb");
$query = $_SGLOBAL["mgrdb"]->query("select count(1) as total from sendmail where serverid=$curServerID;");
$row = $_SGLOBAL["mgrdb"]->fetch_array($query);
$total = $row["total"];

$mailList = array();
$begin = ($currPage - 1) * $pageSize;
$query = $_SGLOBAL["mgrdb"]->query("select *  from serverlist join sendmail where serverlist.serverid=sendmail.serverid and sendmail.serverid=$curServerID order by sendmail.time  desc limit $begin,$pageSize;");
while ($row=$_SGLOBAL["mgrdb"]->fetch_array($query)) {
	$row['stime'] = makeStrTime($row['time']);
    $row['etime'] = makeStrTime($row['sendtime']);
	$row['sreceiver'] = $row['receiver'] == "" ? "全服" : $row['receiver'];
	$row['state'] = $row['state'] == 0 ? "未处理" : "已处理";
	array_push($mailList, $row);
}

$etitle = urlencode($title);
$econtent = urlencode($content);
$multi = multi($total, $pageSize, $currPage, "/sendmail.php?receiver=$receiver&title=$etitle&content=$econtent&itemlist=$itemlist");

include template('sendmail');
?>
