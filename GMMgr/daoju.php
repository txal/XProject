<?php
require_once 'common.php';
isaccess("MM") or exit('Access Denied');

header('content-type:text/html;charset=gbk');

include './include/shop.inc.php';

include template('daoju');
?>