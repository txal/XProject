<?php
require_once 'common.php';
header("content-type:text/html;charset=$_SC['charset']");

include './include/gift.inc.php';

include template('gift');
?>