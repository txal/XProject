<?php 
	include_once("common.php");
	if (!isaccess("PMTMGR")) exit('Access Denied');

	dbConnect("mgrdb");
	if (!empty($_GET['action']) && $_GET['action']=='del') {
		$id = intval($_GET['id']);
		$_SGLOBAL['mgrdb']->query("delete from promoter where id=$id;");

	} else if (!empty($_GET['action']) && $_GET['action']=='add') {
		$name = strval($_GET['name']);
		$passwd = md5(strval($_GET['passwd']));
		$timeNow = time();
		$sql = "insert into promoter set name='$name',passwd='$passwd',createTime=$timeNow;";
		$_SGLOBAL['mgrdb']->query($sql);
	}

	//查询页面号
	$currPage = empty($_GET['page']) ? 1 : intval($_GET['page']);
	$pageSize = 20;

	$query = $_SGLOBAL['mgrdb']->query("select count(1) total from promoter;");
	$row = $_SGLOBAL['mgrdb']->fetch_array($query);
	$total = $row['total'];

	$pmtList = array();
	$begin = ($currPage - 1) * $pageSize;
	$query = $_SGLOBAL['mgrdb']->query("select * from promoter order by createTime desc limit $begin,$pageSize;");
	while ($row=$_SGLOBAL['mgrdb']->fetch_array($query)) {
		$row['loginTime'] = empty($row['loginTime']) ? "" : makeStrTime($row['loginTime']);
		$row['createTime'] = makeStrTime($row['createTime']);
		array_push($pmtList, $row);
	}
	$multi = multi($total, $pageSize, $currPage, "promotermgr.php");

	include template("promotermgr");
?>