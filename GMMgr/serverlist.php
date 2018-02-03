<?php
	require_once 'common.php';
	isaccess("PUBNOTICE") or exit('Access Denied');

	include template('serverlist');
?>