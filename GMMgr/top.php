<?php
	require_once 'common.php';

	//当前登录用户
	$currentUser = getUserInfo();
	$userName = $currentUser['name'];
	if (empty($currentUser)) {
		exit('Access Denied');
	}

	$curServerID = isset($_COOKIE['server']) ? $_COOKIE['server'] : 0;
	if ($curServerID == 0 && isset($_SERVERLIST)) {
		$curServerID = next($_SERVERLIST)['id'];
	}
	
	//改变服务器
	if(!empty($_GET['action']) && $_GET['action']=="chgserver") {
		$curServerID = $_GET['serverid'];
		ssetcookie('server', $curServerID, 0);
	}

	//配置最顶端页面top 的各个主菜单的显示
	$visiable = array(
		1 => "block",	//GM后台管理
		2 => "block",	//运营数据管理
		4 => "block",	//创建管理员
	);
	include template('top');
?>