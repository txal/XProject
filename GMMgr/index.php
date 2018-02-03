<?php
	require_once 'common.php';

	if(isloggedin()) {
		include template('index');
	} else {
		Header("Location: login.php");
	}

?>