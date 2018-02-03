<?php
	include_once("../common.php");
	$path = "./sound/";
	if (!file_exists($path)) {
		mkdir($path);
	}
	$data = file_get_contents("php://input", null, null, -1, 1024*1024);
	if (empty($data)) {
		exit();
	}
	$id = uniqid();
	$file = "$path/$id.amr";
	file_put_contents($file, $data);
	echo $id;
?>
