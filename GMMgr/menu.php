<?php
	require_once 'common.php';

	$memulist=array();

	isaccess("USERQUERY") && $memulist[]=array('href'=>'member.php', 'hreftext'=>'用户查询');
	isaccess("PUBNOTICE") && $memulist[]=array('href'=>'report.php', 'hreftext'=>'系统公告');
	isaccess("USERMAIL") && $memulist[]=array('href'=>'sendmail.php', 'hreftext'=>'用户邮件');
	isaccess("GMRECHARGE") && $memulist[]=array('href'=>'gmrecharge.php', 'hreftext'=>'后台充值');
	isaccess("SYS") && $memulist[]=array('href'=>'sys.php', 'hreftext'=>'系统管理');
	isaccess("USERLOG") && $memulist[]=array('href'=>'userlog.php', 'hreftext'=>'玩家日志');
	isaccess("OPLOG") && $memulist[]=array('href'=>'operationlog.php', 'hreftext'=>'操作日志');
	isaccess("OPENACT") && $memulist[]=array('href'=>'openact.php', 'hreftext'=>'开启活动');
	
	include template('menu');
?>