<?php
	require_once 'common.php';

	$memulist=array();

	isaccess("ADDADMIN")	&& $memulist[]=array('href'=>'addadmin.php',	'hreftext'=>'创建管理员');
	isaccess("LISADMIN")	&& $memulist[]=array('href'=>'adminlist.php',	'hreftext'=>'管理员列表');
	
	include template('menuadminpriority');
?>