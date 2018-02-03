<?php
	require_once 'common.php';

	$memulist=array();

	isaccess("REGISTER") && $memulist[]=array('href'=>'register_query.php', 'hreftext'=>'注册统计');
	isaccess("RECHARGE") && $memulist[]=array('href'=>'recharge_query.php', 'hreftext'=>'充值统计');
    isaccess("SERVERMANAGEMENT") && $memulist[]=array('href'=>'servermanagement.php', 'hreftext'=>'服务器管理');
    isaccess("CODEMANAGEMENT") && $memulist[]=array('href'=>'codemanagement.php', 'hreftext'=>'兑换码管理');
    isaccess("GAMENOTICE") && $memulist[]=array('href'=>'youxinotice.php', 'hreftext'=>'游戏公告');
    isaccess("TASKSTOPQUERY") && $memulist[]=array('href'=>'taskstopquery.php', 'hreftext'=>'任务停留统计');
    isaccess("ITEMQUERY") && $memulist[]=array('href'=>'itemquery.php', 'hreftext'=>'物品消耗统计');
    isaccess("SOURCEHORDMONITOR") && $memulist[]=array('href'=>'sourcehordmonitor.php', 'hreftext'=>'资源囤积监控');
    isaccess("PLAYJOINQUERY") && $memulist[]=array('href'=>'playjoin_query.php', 'hreftext'=>'玩家参与度统计');
    isaccess("SHOPCONSUMEQUERY") && $memulist[]=array('href'=>'shopconsum_query.php', 'hreftext'=>'商城消费统计');
    isaccess("RECHARGESECTIONQUERY") && $memulist[]=array('href'=>'rechargesection_query.php', 'hreftext'=>'充值区间统计');
    isaccess("ZHANDOULIRANKQUERY") && $memulist[]=array('href'=>'zhandoulirank_query.php', 'hreftext'=>'战斗力排名统计');
    isaccess("RECHARGERANKQUERY") && $memulist[]=array('href'=>'rechargerank_query.php', 'hreftext'=>'充值排名统计');
    isaccess("ONLINEMONITOR") && $memulist[]=array('href'=>'onlinemonitor.php', 'hreftext'=>'实时在线监控');
    isaccess("WHITELIST") && $memulist[]=array('href'=>'whitelist.php', 'hreftext'=>'白名单');

	include template('menuoperatingdata');
?>