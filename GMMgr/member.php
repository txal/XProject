<?php
require_once 'common.php';
if (!isaccess("USERQUERY")) {
	 exit('Access Denied');
}

$searchAccount = "";
$searchID = "";
//修改属性
if (!empty($_GET["action"]) && $_GET["action"] == "moduser") {
    $charid = strval($_GET["charid"]);
	$yuanbao = intval($_GET["yuanbao"]);
	$yinliang = intval($_GET["yinliang"]);
	$weiwang = intval($_GET["weiwang"]);
	$waijiao = intval($_GET["waijiao"]);
	$vip = intval($_GET["vip"]);
	$data = array("charid"=>$charid,"yuanbao"=>$yuanbao,"yinliang"=>$yinliang,"weiwang"=>$weiwang,"waijiao"=>$waijiao,"vip"=>$vip) ;
	$result = request(serverID(), "moduser", $data, true);
	$result = (empty($result) ? "FAIL" : "SUCCESS");
	$ext = print_r($data, true);	
	writeAdminLog("MODUSER", $ext);
	echo $result;
	exit();

} else if (!empty($_GET["action"]) && $_GET["action"] == "kickuser") {
//踢下线
	$data = array("charid"=>$_GET["charid"]);
	$result = request(serverID(), "kickuser", $data, true);
	$result = (empty($result) ? "FAIL" : "SUCCESS");
	echo $result;
	exit();

} else if (!empty($_GET["action"]) && $_GET["action"] == "banuser") {
//封号解封
	$data = array("account"=>$_GET["account"],"state"=>intval($_GET["state"]));
	$result = request(serverID(), "banuser", $data, true);
	$result = (empty($result) ? "FAIL" : "SUCCESS");
	echo $result;
	exit();

} elseif (!empty($_GET["action"]) && $_GET["action"] == "member") {
//查看特定玩家
	dbConnect("logdb");

	//分页
    $curPage = 1;
    $pageSize = 16;
    if (!empty($_GET["page"])) {
        $curPage = $_GET["page"];
    }

    $begin = ($curPage - 1) * $pageSize;
	$onlineCount = 0;
	$members = array();
	$account = $_GET["member"];
	$id = $_GET["memberID"];
	if(isset($_GET["memberID"])) $charID = $_GET["memberID"];
	$searchAccount = $account;
	$searchID = $id;
	if($account!=""&&$charID==""){
        $query = $_SGLOBAL["logdb"]->query("select count(1) as total from account  where account like '%$account%';");
        $sql = $_SGLOBAL["logdb"]->query("select * from account where account like '%$account%' order by time desc limit $begin,$pageSize;");
    }
    if($account==""&&$charID!=""){
        $query = $_SGLOBAL["logdb"]->query("select count(1) as total from account where char_id like '%$charID%';");
        $sql = $_SGLOBAL["logdb"]->query("select * from account where char_id like '%$charID%'order by time desc limit $begin,$pageSize;");
    }
    if($account!=""&&$charID!=""){
        $query = $_SGLOBAL["logdb"]->query("select count(1) as total from account where account like '%$account%' and char_id like '%$charID%';");
        $sql =$_SGLOBAL["logdb"]->query("select * from account where account like '%$account%' and char_id like '%$charID%'order by time desc limit $begin,$pageSize;");
    }
    $row = $_SGLOBAL["logdb"]->fetch_array($query);
    $total = $row["total"];

	$members = getMemberList($sql, $onlineCount);
    $multi = multi($total, $pageSize, $curPage, "member.php?&action=member&member=$account&memberID=$charID");
} else if (empty($_GET["action"])) {
//玩家列表
	dbConnect("logdb");
	$onlineCount = 0;
	$curPage = 1;
	$pageSize = 16;
	if (!empty($_GET["page"])) {
		$curPage = $_GET["page"];
	}

    $total = 0;
    $members = array();
    $multi = "";

	$query = $_SGLOBAL["logdb"]->query("select count(1) as total from account;", true);
    if ($query) {
    	$row = $_SGLOBAL["logdb"]->fetch_array($query);
    	$total = $row["total"];
    }

	$begin = ($curPage - 1) * $pageSize;
	$query = $_SGLOBAL["logdb"]->query("select * from account order by time desc limit $begin,$pageSize;", true);
    if ($query) {
    	$members = getMemberList($query, $onlineCount);
    	$multi = multi($total, $pageSize, $curPage, "member.php");
    }
}

//取玩家列表
function getMemberList(&$query, &$onlineCount) {
    global $_SGLOBAL;
    $members = array();
    $accounts = array();
    $genderMap = array(0=>"", 1=>"", 2=>"");
    $stateMap = array(-1=>"查无此人", 0=>"正常", 1=>"禁言", 2=>"封号");
    while ($row=$_SGLOBAL["logdb"]->fetch_array($query)) {
        $member = array();
        $member["account"] = $row["account"];
        $member["charid"] = $row["char_id"];
        $member["charname"] = $row["char_name"];
        $member["gender"] = $genderMap[0];
        $member["dbname"] = "";
        $member["createtime"] = makeStrTime($row['time']);
        $member["source"] = $row["source"];
        $member["state"] = -1;
        $member["sstate"] = $stateMap[-1];

        $member["guoli"] = 0;
        $member["yuanbao"] = 0;
        $member["yinliang"] = 0;
        $member["weiwang"] = 0;
        $member["waijiao"] = 0;
        $member["vip"] = 0;
        $member["online"] = "否";
        $member["online"] = "否";

        $member['zrfgrid'] = 0;
        $member['qggrid'] = 0;
        $member['lggrid'] = 0;
        $member['zsnum'] = 0;
        $member['nglv'] = 0;
        $member['maxyk'] = 0;
        $member['maxlc'] = 0;
        $member['maxby'] = 0;
        array_push($members, $member);
        array_push($accounts, $row["char_id"]);
    }
    $result = request(serverID(), "memberinfo", $accounts, true);
    if (empty($result)) {
        return $members;
    }

    $memberData = $result[0];
    $onlineCount = $result[1];
    foreach ($members as &$member) {
        $account = $member["charid"];
        if (empty($memberData[$account])) continue;
        $info = $memberData[$account];
        $member["guoli"] = $info["nGuoLi"];
        $member["yuanbao"] = $info["nYuanBao"];
        $member["yinliang"] = $info["nYinLiang"];
        $member["weiwang"] = $info["nWeiWang"];
        $member["waijiao"] = $info["nWaiJiao"];
        $member["vip"] = $info["nVIP"];
        $member["online"] = $info["bOnline"] ? "是":"否";
        $member["state"] = $info["nState"];
        $member["sstate"] = $stateMap[$member["state"]];
        
        $member['zrfgrid'] = $info['nZRFGrid'];
        $member['qggrid'] = $info['nQGGrid'];
        $member['lggrid'] = $info['nLGGrid'];
        $member['zsnum'] = $info['nZSNum'];
        $member['maxyk'] = $info['nMaxYK'];
        $member['maxlc'] = $info['nMaxLC'];
        $member['maxby'] = $info['nMaxBY'];
    }

    return $members;
}

include template('member');
?>
