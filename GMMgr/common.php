<?php
define('IN_APP', TRUE);
define('DS', DIRECTORY_SEPARATOR);
define('APP_ROOT', dirname(__FILE__) . DS);
define('MAGIC_QUOTES_GPC', get_magic_quotes_gpc());

include_once(APP_ROOT.'config.php');
include_once(APP_ROOT.'request/request.php');
include_once(APP_ROOT.'include/function_common.php');
include_once(APP_ROOT.'include/modulecode.inc.php');
include_once(APP_ROOT.'include/mypayfunction.php');
$_SGLOBAL = $_SCONFIG = $_SCOOKIE = $_TPL = array();
ini_set('date.timezone','Asia/Shanghai');

if (PHP_VERSION < '4.0') {
	$_POST = $HTTP_POST_VARS;
	$_GET = $HTTP_GET_VARS;
	$_COOKIE = $HTTP_COOKIE_VARS;
	$_SERVER = $HTTP_SERVER_VARS;
	$_FILES  = $HTTP_FILES_VARS;
}

//时间
$mtime = explode(' ', microtime());
$_SGLOBAL['timestamp'] = $mtime[1];
$_SGLOBAL['start_time'] = $mtime[0] + $mtime[1];
$_SGLOBAL['onlineip'] = getonlineip();

//GPC过滤
foreach(array('_POST', '_GET') as $_request) {
	$_req = $$_request;
	foreach($_req as $_key => $_value) {
		$_value = preg_replace(array("/(javascript|script|eval|behaviour|expression)/i", "/(\s+|&quot;|')on/i"), array('.', ' .'), $_value);
		if ($_key{0} != '_') {
			$$_key = recAddSlashes($_value);
			$_req[$_key] = $$_key;
		}
	}
}

if (!MAGIC_QUOTES_GPC && $_FILES) {
	$_FILES = recAddSlashes($_FILES);
}
unset($_request, $_key, $_value);

$prelength = strlen($_SC['cookiepre']);
foreach($_COOKIE as $key => $val) {
	if(substr($key, 0, $prelength) == $_SC['cookiepre']) {
		$val = preg_replace(array("/(javascript|script|eval|behaviour|expression)/i", "/(\s+|&quot;|')on/i"), array('.', ' .'), $val);
		$_SCOOKIE[(substr($key, $prelength))] = MAGIC_QUOTES_GPC ? $val : recAddSlashes($val);
	}
}
unset($prelength, $_request, $_key, $_value);

//服务器列表
$_SERVERLIST = array();
$db = dbConnect("mgrdb");
$query = $db->query("select * from serverlist order by serverid asc;");
$serverIdArr = array();
while ($row=$db->fetch_array($query)) {
	$srv = array();
	$srv['id'] = $row['serverid'];
	$srv['name'] = $row['servername'];
	$srv['gate'] = $row['gateaddr'];
	$srv['state'] = $row['state'];
	$srv['hot'] = $row['hot'];
	$srv['time'] = $row['time'];

	$srv['gm'] = array();
    $gmaddr = @explode('|', $row['gmaddr']);
    if(count($gmaddr) == 2) {
        $srv['gm']['ip'] = $gmaddr[0];
        $srv['gm']['port'] = $gmaddr[1];
    }

	$logdb = @explode('|', $row['logdb']);
    $srv['logdb'] = array();
    if(count($logdb) == 5) {
        $srv['logdb']['ip'] = $logdb[0];
        $srv['logdb']['port'] = $logdb[1];
        $srv['logdb']['usr'] = $logdb[2];
        $srv['logdb']['pwd'] = $logdb[3];
        $srv['logdb']['db'] = $logdb[4];
    }
    array_push($serverIdArr,$srv['id']);
	$_SERVERLIST[$row['serverid']] = $srv;
}


?>
