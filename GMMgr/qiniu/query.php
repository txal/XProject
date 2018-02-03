<?php
	include_once("../common.php");
	$path = "./sound/";
	if (empty($_GET['id'])) {
		exit();
	}
	$id = strval($_GET['id']);
	$file = "$path/$id.amr";
	if (!file_exists($file)) {
		exit();
	}
	$data = file_get_contents("$path/$id.amr");
	echo $data;
?>
