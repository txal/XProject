<?php
if(!defined('IN_APP')) {
	exit('Access Denied');
}
include_once(APP_ROOT.'./include/class_mysql.php');

function recAddSlashes($string) {
	if(is_array($string)) {
		foreach($string as $key => $val) {
			$string[$key] = recAddSlashes($val);
		}
	} else {
		$string = addslashes($string);
	}
	return $string;
}

function checkAuth(&$data, &$parser) {
	global $_SGLOBAL, $_SC;
	$res = $parser->parse($data, "s:key|i:uid");
	$key = $res['key'];
	$uid = $res['uid'];
	$tarkey = md5($_SC['key'].$uid);
	if($key == $tarkey) {
		$_SGLOBAL['uid'] = $uid;
		return true;
	}
	return false;
}

function serverID() {
	global $_COOKIE;
	return (empty($_COOKIE["server"]) ? 1 : $_COOKIE["server"]);
}

function clearcookie() {
	global $_COOKIE;
	foreach ($_COOKIE as $k=>$v) { 
		$_COOKIE[$k] = "";
		ssetcookie($k, "", -86400 * 365);
	}
}


function ssetcookie($var, $value, $life=0) {
	global $_SGLOBAL, $_SC, $_SERVER, $_COOKIE;

	$_COOKIE[$var] = $value; //让cookie立即生效
	setcookie($_SC['cookiepre'].$var
		, $value
		, $life ? ($_SGLOBAL['timestamp']+$life) : 0
		, $_SC['cookiepath']
		, $_SC['cookiedomain']
		, $_SERVER['SERVER_PORT']==443?1:0);
}

function setLoginCookie($user)
{
	ssetcookie('__name', $user['name'], 0);
	ssetcookie('__userid', $user['userid'], 0);
	ssetcookie('__passwd', $user['passwd'], 0);
	ssetcookie('__purview', $user['purview'], 0);
}

function getonlineip($format=0) {
	global $_SGLOBAL;

	if(empty($_SGLOBAL['onlineip'])) {
		if(getenv('HTTP_CLIENT_IP') && strcasecmp(getenv('HTTP_CLIENT_IP'), 'unknown')) {
			$onlineip = getenv('HTTP_CLIENT_IP');
		} elseif(getenv('HTTP_X_FORWARDED_FOR') && strcasecmp(getenv('HTTP_X_FORWARDED_FOR'), 'unknown')) {
			$onlineip = getenv('HTTP_X_FORWARDED_FOR');
		} elseif(getenv('REMOTE_ADDR') && strcasecmp(getenv('REMOTE_ADDR'), 'unknown')) {
			$onlineip = getenv('REMOTE_ADDR');
		} elseif(isset($_SERVER['REMOTE_ADDR']) && $_SERVER['REMOTE_ADDR'] && strcasecmp($_SERVER['REMOTE_ADDR'], 'unknown')) {
			$onlineip = $_SERVER['REMOTE_ADDR'];
		}
		preg_match("/[\d\.]{7,15}/", $onlineip, $onlineipmatches);
		$_SGLOBAL['onlineip'] = $onlineipmatches[0] ? $onlineipmatches[0] : 'unknown';
	}
	if($format) {
		$ips = explode('.', $_SGLOBAL['onlineip']);
		for($i=0;$i<3;$i++) {
			$ips[$i] = intval($ips[$i]);
		}
		return sprintf('%03d%03d%03d', $ips[0], $ips[1], $ips[2]);
	} else {
		return $_SGLOBAL['onlineip'];
	}
}

function authcode($string, $operation = 'DECODE', $key = '', $expiry = 0) {

	$ckey_length = 4;

	$key = md5($key ? $key : YJ_KEY);
	$keya = md5(substr($key, 0, 16));
	$keyb = md5(substr($key, 16, 16));
	$keyc = $ckey_length ? ($operation == 'DECODE' ? substr($string, 0, $ckey_length): substr(md5(microtime()), -$ckey_length)) : '';

	$cryptkey = $keya.md5($keya.$keyc);
	$key_length = strlen($cryptkey);

	$string = $operation == 'DECODE' ? base64_decode(substr($string, $ckey_length)) : sprintf('%010d', $expiry ? $expiry + time() : 0).substr(md5($string.$keyb), 0, 16).$string;
	$string_length = strlen($string);

	$result = '';
	$box = range(0, 255);

	$rndkey = array();
	for($i = 0; $i <= 255; $i++) {
		$rndkey[$i] = ord($cryptkey[$i % $key_length]);
	}

	for($j = $i = 0; $i < 256; $i++) {
		$j = ($j + $box[$i] + $rndkey[$i]) % 256;
		$tmp = $box[$i];
		$box[$i] = $box[$j];
		$box[$j] = $tmp;
	}

	for($a = $j = $i = 0; $i < $string_length; $i++) {
		$a = ($a + 1) % 256;
		$j = ($j + $box[$a]) % 256;
		$tmp = $box[$a];
		$box[$a] = $box[$j];
		$box[$j] = $tmp;
		$result .= chr(ord($string[$i]) ^ ($box[($box[$a] + $box[$j]) % 256]));
	}

	if($operation == 'DECODE') {
		if((substr($result, 0, 10) == 0 || substr($result, 0, 10) - time() > 0) && substr($result, 10, 16) == substr(md5(substr($result, 26).$keyb), 0, 16)) {
			return substr($result, 26);
		} else {
			return '';
		}
	} else {
		return $keyc.str_replace('=', '', base64_encode($result));
	}
}

//连接数据库
function dbConnect($dbName) {
	assert(!empty($dbName));
	global $_SGLOBAL, $_SC, $_SERVERLIST;
	if(empty($_SGLOBAL[$dbName]))
	{
		if (!empty($_SC[$dbName]))
		{
			$dbConf = $_SC[$dbName];
			$_SGLOBAL[$dbName] = new dbstuff();
			$_SGLOBAL[$dbName]->charset = $dbConf['dbcharset'];
			$_SGLOBAL[$dbName]->connect($dbConf['dbhost'], $dbConf['dbuser'], $dbConf['dbpwd'], $dbConf['dbname'], $dbConf['dbport']);
		} else { //logdb
			$serverID = $_COOKIE['server'];
			$srv = $_SERVERLIST[$serverID]['logdb'];
			$db = new dbstuff();
			$db->charset = "utf8";
			$db->connect($srv['ip'], $srv['usr'], $srv['pwd'], $srv['db'], $srv['port']);
			$_SGLOBAL[$dbName] = $db;
		}
	}
	return $_SGLOBAL[$dbName];
}

function tname($name) {
	global $_SC;
	return $_SC['tablepre'].$name;
}

function showmessage($msgkey, $url_forward='', $second=1) {
	global $uid, $username;
	obclean();
	if($url_forward && empty($second)) {
		header("HTTP/1.1 301 Moved Permanently");
		header("Location: $url_forward");
	} else {
		$message = $msgkey;
		if($url_forward) {
			$message = "$message<br /><a href=\"$url_forward\">跳转中......</a><script>setTimeout(\"window.location.href ='$url_forward';\", ".($second*1000).");</script>";
		} else {
			$message = "$message<br />跳转中......<script>setTimeout(\"history.back();\", ".($second*1000).");</script>";
		}
		include template('showmessage');
	}
	exit();
}

function submitcheck($var) {
	if(!empty($_POST[$var]) && $_SERVER['REQUEST_METHOD'] == 'POST') {
		return true;
		if((empty($_SERVER['HTTP_REFERER']) || preg_replace("/https?:\/\/([^\:\/]+).*/i", "\\1", $_SERVER['HTTP_REFERER']) == preg_replace("/([^\:]+).*/", "\\1", $_SERVER['HTTP_HOST'])))
		{
			return true;
		} else {
			showmessage('submit_invalid');
		}
	} else {
		return false;
	}
}

function insertTable($table, $kvData, $returnID=false) {
	global $_SGLOBAL;

	$insertSql = "insert into $table set ";
	foreach ($kvData as $key=>$value) {
		$insertSql .= "$key='$value',";
	}
	$insertSql[strlen($insertSql)-1] = ";";

	$res = $_SGLOBAL['mgrdb']->query($insertSql);
	if ($returnID) {
		return $_SGLOBAL['mgrdb']->insert_id();
	} else {
		return $res;
	}
}


function updatetable($tablename, $setsqlarr, $wheresqlarr, $silent=0) {
	global $_SGLOBAL;

	$setsql = $comma = '';
	foreach ($setsqlarr as $set_key => $set_value) {
		$setsql .= $comma.'`'.$set_key.'`'.'=\''.$set_value.'\'';
		$comma = ', ';
	}
	$where = $comma = '';
	if(empty($wheresqlarr)) {
		$where = '1';
	} elseif(is_array($wheresqlarr)) {
		foreach ($wheresqlarr as $key => $value) {
			$where .= $comma.'`'.$key.'`'.'=\''.$value.'\'';
			$comma = ' AND ';
		}
	} else {
		$where = $wheresqlarr;
	}
	$_SGLOBAL['mgrdb']->query('UPDATE '.tname($tablename).' SET '.$setsql.' WHERE '.$where, $silent?'SILENT':'');
}

function getstr($string, $length, $s) {
	global $_SC, $_SGLOBAL;

	$string = trim($string);

	if($length && strlen($string) > $length) {
		if(strtolower($_SC['charset']) == 'utf-8') {
			$n = 0;
			$tn = 0;
			$noc = 0;
			while ($n < strlen($string)) {
				$t = ord($string[$n]);
				if($t == 9 || $t == 10 || (32 <= $t && $t <= 126)) {
					$tn = 1;
					$n++;
					$noc++;
				} elseif(194 <= $t && $t <= 223) {
					$tn = 2;
					$n += 2;
					$noc += 2;
				} elseif(224 <= $t && $t < 239) {
					$tn = 3;
					$n += 3;
					$noc += 2;
				} elseif(240 <= $t && $t <= 247) {
					$tn = 4;
					$n += 4;
					$noc += 2;
				} elseif(248 <= $t && $t <= 251) {
					$tn = 5;
					$n += 5;
					$noc += 2;
				} elseif($t == 252 || $t == 253) {
					$tn = 6;
					$n += 6;
					$noc += 2;
				} else {
					$n++;
				}
				if ($noc >= $length) {
					break;
				}
			}
			if ($noc > $length) {
				$n -= $tn;
			}
			$wordscut = substr($string, 0, $n);
		} else {
			for($i = 0; $i < $length - 1; $i++) {
				if(ord($string[$i]) > 127) {
					$wordscut .= $string[$i].$string[$i + 1];
					$i++;
				} else {
					$wordscut .= $string[$i];
				}
			}
		}
		$string = $wordscut;
		$string .= $s;
	}
	return trim($string);
}

//ob
function obclean() {
	ob_end_clean();
	ob_start();
}

function template($name) {
	global $_SC, $_SGLOBAL;

	if(strexists($name,'/')) {
		$tpl = $name;
	} else {
		$tpl = "template/$_SC[template]/$name";
	}
	$objfile = APP_ROOT.'./data/tpl_cache/'.str_replace('/','_',$tpl).'.php';
	if(!file_exists($objfile) || filemtime($objfile) < filemtime(APP_ROOT . "./{$tpl}.htm")) {
		include_once(APP_ROOT.'./include/function_template.php');
		parse_template($tpl);
	}
	return $objfile;
}

function subtplcheck($subfiles, $mktime, $tpl) {
	global $_SC;

	if($_SC['tplrefresh'] && ($_SC['tplrefresh'] == 1 || mt_rand(1, $_SC['tplrefresh']) == 1)) {
		$subfiles = explode('|', $subfiles);
		foreach ($subfiles as $subfile) {
			@$submktime = filemtime(S_ROOT.'./'.$subfile.'.htm');
			if($submktime > $mktime) {
				include_once(S_ROOT.'./source/function_template.php');
				parse_template($tpl);
				break;
			}
		}
	}
}

function getcount($tablename, $wherearr='', $get='COUNT(*)') {
	global $_SGLOBAL;
	if(empty($wherearr)) {
		$wheresql = '1';
	} else {
		$wheresql = $mod = '';
		foreach ($wherearr as $key => $value) {
			$wheresql .= $mod."`$key`='$value'";
			$mod = ' AND ';
		}
	}
	return $_SGLOBAL['mgrdb']->result($_SGLOBAL['mgrdb']->query("SELECT $get FROM ".tname($tablename)." WHERE $wheresql LIMIT 1"), 0);
}

function ob_out() {
	global $_SC;
	$content = ob_get_contents();
	obclean();
	echo $content;
}

function xml_out($content) {
	global $_SC;
	@header("Expires: -1");
	@header("Cache-Control: no-store, private, post-check=0, pre-check=0, max-age=0", FALSE);
	@header("Pragma: no-cache");
	@header("Content-type: application/xml; charset=$_SC[charset]");
	echo '<'."?xml version=\"1.0\" encoding=\"$_SC[charset]\"?>\n";
	echo "<root><![CDATA[".trim($content)."]]></root>";
	exit();
}


function rewrite_url($pre, $para) {
	$para = str_replace(array('&','='), array('-', '-'), $para);
	return '<a href="'.$pre.$para.'.html"';
}

function formatsize($size) {
	$prec=3;
	$size = round(abs($size));
	$units = array(0=>" B ", 1=>" KB", 2=>" MB", 3=>" GB", 4=>" TB");
	if ($size==0) return str_repeat(" ", $prec)."0$units[0]";
	$unit = min(4, floor(log($size)/log(2)/10));
	$size = $size * pow(2, -10*$unit);
	$digi = $prec - 1 - floor(log($size)/log(10));
	$size = round($size * pow(10, $digi)) * pow(10, -$digi);
	return $size.$units[$unit];
}


function sreadfile($filename) {
	$content = '';
	if(function_exists('file_get_contents')) {
		@$content = file_get_contents($filename);
	} else {
		if(@$fp = fopen($filename, 'r')) {
			@$content = fread($fp, filesize($filename));
			@fclose($fp);
		}
	}
	return $content;
}

function swritefile($filename, $writetext, $openmod='w') {
	if(@$fp = fopen($filename, $openmod)) {
		flock($fp, 2);
		fwrite($fp, $writetext);
		fclose($fp);
		return true;
	} else {
		runlog('error', "File: $filename write error.");
		return false;
	}
}

function runlog($file, $log, $halt=0) {
	global $_SGLOBAL, $_SERVER;

	$nowurl = $_SERVER['REQUEST_URI']?$_SERVER['REQUEST_URI']:($_SERVER['PHP_SELF']?$_SERVER['PHP_SELF']:$_SERVER['SCRIPT_NAME']);
	$log = sgmdate('Y-m-d H:i:s', $_SGLOBAL['timestamp'])."\t".getonlineip()."\t{$nowurl}\t".str_replace(array("\r", "\n"), array(' ', ' '), trim($log))."\n";
	$yearmonth = sgmdate('Ym', $_SGLOBAL['timestamp']);
	$logdir = './data/log/';
	if(!is_dir($logdir)) mkdir($logdir, 0777);
	$logfile = $logdir.$yearmonth.'_'.$file.'.php';
	if(@filesize($logfile) > 2048000) {
		$dir = opendir($logdir);
		$length = strlen($file);
		$maxid = $id = 0;
		while($entry = readdir($dir)) {
			if(strexists($entry, $yearmonth.'_'.$file)) {
				$id = intval(substr($entry, $length + 8, -4));
				$id > $maxid && $maxid = $id;
			}
		}
		closedir($dir);
		$logfilebak = $logdir.$yearmonth.'_'.$file.'_'.($maxid + 1).'.php';
		@rename($logfile, $logfilebak);
	}
	if($fp = @fopen($logfile, 'a')) {
		@flock($fp, 2);
		fwrite($fp, "<?PHP exit;?>\t".str_replace(array('<?', '?>', "\r", "\n"), '', $log)."\n");
		fclose($fp);
	}
	if($halt) exit();
}

function sgmdate($dateformat, $timestamp='', $format=0) {
	global $_SCONFIG, $_SGLOBAL;
	if(empty($timestamp)) {
		$timestamp = $_SGLOBAL['timestamp'];
	}
	$result = '';
	if($format) {
		$time = $_SGLOBAL['timestamp'] - $timestamp;
		if($time > 24*3600) {
			$result = gmdate($dateformat, $timestamp + 8 * 3600);
		} elseif ($time > 3600) {
			$result = intval($time/3600).lang('hour').lang('before');
		} elseif ($time > 60) {
			$result = intval($time/60).lang('minute').lang('before');
		} elseif ($time > 0) {
			$result = $time.lang('second').lang('before');
		} else {
			$result = lang('now');
		}
	} else {
		$result = gmdate($dateformat, $timestamp + 8 * 3600);
	}
	return $result;
}

function random($length, $numeric = 0) {
	PHP_VERSION < '4.2.0' ? mt_srand((double)microtime() * 1000000) : mt_srand();
	$seed = base_convert(md5(print_r($_SERVER, 1).microtime()), 16, $numeric ? 10 : 35);
	$seed = $numeric ? (str_replace('0', '', $seed).'012340567890') : ($seed.'zZ'.strtoupper($seed));
	$hash = '';
	$max = strlen($seed) - 1;
	for($i = 0; $i < $length; $i++) {
		$hash .= $seed[mt_rand(0, $max)];
	}
	return $hash;
}


function strexists($haystack, $needle) {
	return !(strpos($haystack, $needle) === FALSE);
}

function fileext($filename) {
	return strtolower(trim(substr(strrchr($filename, '.'), 1)));
}

function format_time($t){
	global $lan_g_day,$lan_g_hour,$lan_g_min,$lan_g_sec;
	$days = floor($t/86400);
	$t = $t - ($days*86400);

	$hours = floor($t/3600);
	$t = $t - ($hours*3600);

	$minutes = floor($t/60);
	$t = $t - ($minutes*60);

	$seconds = $t;

	$i = 0;
	if($days>0) {
		$output .= "{$days}{$lan_g_day}";
		$i++;
	}
	if($hours>0) {
		$output .= "{$hours}{$lan_g_hour}";
		$i++;
	}
	if($minutes>0&&$i<2) {
		$output .= "{$minutes}{$lan_g_min}";
		$i++;
	}
	if($i<2) {
		$output .= "{$seconds}{$lan_g_sec}";
	}
	return $output;
}

function multi($num, $perpage, $curpage, $mpurl) {
	global $_SCONFIG;
	$page = 5;
	$multipage = '';
	$mpurl .= strpos($mpurl, '?') !== FALSE ? '&' : '?';
	$realpages = 1;
	if($num > $perpage) {
		$offset = 2;
		$realpages = ceil($num / $perpage);
		$pages = isset($_SCONFIG['maxpage']) && $_SCONFIG['maxpage'] < $realpages ? $_SCONFIG['maxpage'] : $realpages;
		if($page > $pages) {
			$from = 1;
			$to = $pages;
		} else {
			$from = $curpage - $offset;
			$to = $from + $page - 1;
			if($from < 1) {
				$to = $curpage + 1 - $from;
				$from = 1;
				if($to - $from < $page) {
					$to = $page;
				}
			} elseif($to > $pages) {
				$from = $pages - $page + 1;
				$to = $pages;
			}
		}
		$multipage = ($curpage - $offset > 1 && $pages > $page ? '<a href="'.$mpurl.'page=1">1 ...</a>' : '').
			($curpage > 1 ? '<a href="'.$mpurl.'page='.($curpage - 1).'">&lsaquo;&lsaquo;</a>' : '');
		for($i = $from; $i <= $to; $i++) {
			$multipage .= $i == $curpage ? '<strong>'.$i.'</strong>' :
				'<a href="'.$mpurl.'page='.$i.'">['.$i.']</a>';
		}
		$multipage .= ($curpage < $pages ? '<a href="'.$mpurl.'page='.($curpage + 1).'">&rsaquo;&rsaquo;</a>' : '').
			($to < $pages ? '<a href="'.$mpurl.'page='.$pages.'">... '.$realpages.'</a>' : '');
		$multipage = $multipage ? ('<span>&nbsp;共'.$num.'条记录&nbsp;</span>'.$multipage):'';
	}
	$maxpage = $realpages;
	
	return $multipage;
}

function ref() {
	if (isset($_SERVER['HTTP_REFERRER'])) {
		$rt = $_SERVER['HTTP_REFERRER'];
	} else {
		$rt = getenv("HTTP_REFERER");
	}
	return $rt;
}

function goto_login($refer = NULL) {
	setcookie($_SC['cookiepre'] . 'refer', $refer ? $refer : (isset($_SERVER['PHPP_SELF']) ? basename($_SERVER['PHP_SELF']) : basename($_SERVER['SCRIPT_NAME'])), time() + 60);
	
	if (!headers_sent()) {
		header('location:login.php');
	} else {
		echo '<script type="text/javascript">location.href="login.php";</script>';
	}
	exit;
}

function goto_page($msg, $page) {
	echo '<script type="text/javascript">alert("' . $msg . '");location.href="' . $page . '";</script>';
	exit;
}

function run_time() {
	global $_SGLOBAL;
	$etime = array_sum(explode(' ', microtime()));
	return number_format($etime - $_SGLOBAL['start_time'], 5);
}

function back_to($msg = NULL) {
	if ($msg)
		echo "<script type=\"text/javascript\">alert('$msg');history.back();</script>";
	else
		echo '<script type="text/javascript">history.back();</script>';
	exit;
}

function read_cache($file, $time = 60) {
	$file = APP_ROOT . './data/data_cache/' . $file . '.cache.php';
	if (file_exists($file) && filemtime($file) + $time > time()) {
		$ret = @include($file);
		return $ret;
	} else {
		return false;
	}
}

function write_cache($file, $data) {
	$file = APP_ROOT . './data/data_cache/' . $file . '.cache.php';
	$data = var_export($data, TRUE);
	$data = "<?php\nreturn " . $data . ";\n?>";
	file_put_contents($file, $data);
}

function query_cmd($cmd, $query, $ret=true)
{
	global $_SC, $_SERVER_APP, $G_SERVERID;
	$buf = "";
	
	$fp = fsockopen($_SERVER_APP[$G_SERVERID]['server'], intval($_SERVER_APP[$G_SERVERID]['port']), $errno, $errstr, 10);
  if (!$fp) return 0;

	$query = $query . "0";
	$len = strlen($query);
	$packet = pack("LLa".$len, $len + 4 , $cmd, $query);

	fwrite($fp, $packet, $len+8);
	if ( $ret ) {
		  if (!feof($fp)) {
		  	$buf = fread($fp, 4);
		  	$array = unpack("Llen", $buf);
		  	$len = $array['len'];
				if($len > 0) {
					$buf = fread($fp, 4);
					$array = unpack("Lb", $buf);
					$len = $array['b'];
					if ( $len > 0 ) {
						$less = $len;
						$buf = '';
						while( $less > 0 ) {
							$buf .= fread($fp, $less);
							$less = $len - strlen($buf);
						}
						$array = unpack("a".($len-1), $buf);
						return $array[1];
					}
				}
		}
  } else {
  	fclose($fp);
  	return "";
  }
  
	fclose($fp);
	
	return $buf;
}

//转换为数据库的编码
function convertDBCharset($value)
{
	return $value;
} 

//转换为页面编码
function convertPageCharset($value)
{
	return $value;
} 

//写操作日志
function writeAdminLog($op, $ext="")
{
	global $_opCodeList, $_SERVER;
	$user = getUserInfo();
	$insertSql = array(
		'adminID' => $user['userid'],
		'adminName'	=> $user['name'],
		'opCode' => $_opCodeList[$op]['code'],
		'opName' => $_opCodeList[$op]['name'],
		'loginIP' => $_SERVER['REMOTE_ADDR'],
		'ext' => $ext,
		'time' => time(),
	);
	if (empty($_SGLOBAL["mgrdb"])) {
		dbConnect("mgrdb");
	}
	insertTable("adminlog", $insertSql);
	return true;
}

//判读是否已经登陆
function isloggedin()
{
	global $_COOKIE;
	if(isset($_COOKIE['__name']) && $_COOKIE['__name'] 
		&& isset($_COOKIE['__userid']) && $_COOKIE['__userid']
		&& isset($_COOKIE['__passwd']) && $_COOKIE['__passwd'])
	{
		return true;
	}else 
		return false;

}

//取玩家信息
function getUserInfo()
{
	global $_COOKIE;
	$user = array();
	if(!empty($_COOKIE['__name']) && !empty($_COOKIE['__userid']) && !empty($_COOKIE['__passwd']))
	{
		$user['name'] = $_COOKIE['__name'];
		$user['userid'] = $_COOKIE['__userid'];
		$user['passwd'] = $_COOKIE['__passwd'];
		$user['purview'] = $_COOKIE['__purview'];
	}
	return $user;
}

//获取操作编码
function getOptionCode($option)
{
	global $_opCodeList;
	return $_opCodeList[$option]['code'];
}

function isaccess($moduleShortName)
{
	global $_moduleCodeList;
	//获取当前用户信息
	$user = getUserInfo();
	if($user==null || $user['purview']==null || empty($user['purview']))
	{
		return false;
	}
	//当前用户权限
	$purview = explode(" ",$user['purview']);
	$list = $_moduleCodeList;

	$modulecode = $list[$moduleShortName]['code'];
	return in_array($modulecode, $purview);
}

//转换日期 Y-m-d H:i:s 为  时间戳timestamp
function dt2timestamp($strtime) {
	$array = explode("-",$strtime);
	$year = $array[0];
	$month = $array[1];
	
	$array = explode(":",$array[2]);
	$minute = $array[1];
	$second = $array[2];
	
	$array = explode(" ",$array[0]);
	$day = $array[0];
	$hour = $array[1];
	
	return mktime($hour,$minute,$second,$month,$day,$year);
}	

//时间戳转日期
function makeStrTime($timeStamp) {
	return date("Y-m-d H:i:s", $timeStamp);
}

function extParamStr($allParams, $startPos, $endPos)
{
	$str = "";
	for($i = $startPos; $i <= $endPos ; $i ++)
	{
		$str = $str . $allParams[$i] . ",";
	}
	return $str;
}

function ajax_multi2($num, $perpage, $curpage, $func) {
	global $_SCONFIG;
	$allParams = func_get_args();
	$paramCount = func_num_args();
	$page = 5;
	$multipage = '';
	$realpages = 1;
	
	if($num > $perpage) {
		$offset = 2;
		$realpages = ceil($num / $perpage);
		$pages = isset($_SCONFIG['maxpage']) && $_SCONFIG['maxpage'] < $realpages ? $_SCONFIG['maxpage'] : $realpages;
		if($page > $pages) {
			$from = 1;
			$to = $pages;
		} else {
			$from = $curpage - $offset;
			$to = $from + $page - 1;
			if($from < 1) {
				$to = $curpage + 1 - $from;
				$from = 1;
				if($to - $from < $page) {
					$to = $page;
				}
			} elseif($to > $pages) {
				$from = $pages - $page + 1;
				$to = $pages;
			}
		}
		
		$extParamStr = extParamStr($allParams, 4, $paramCount - 1 );
		$multipage = ($curpage - $offset > 1 && $pages > $page ? '<a href="javascript:'.$func.'('.$extParamStr .' 1);">1 ...</a>' : '').
		($curpage > 1 ? '<a href="javascript:'.$func.'('.$extParamStr .' '.($curpage - 1).');">&lsaquo;&lsaquo;</a>' : '');
		
		for($i = $from; $i <= $to; $i++) {
			$multipage .= $i == $curpage ? '<strong>'.$i.'</strong>' :
			'<a href="javascript:'.$func.'('.$extParamStr.' '.$i.');">'.$i.'</a>';
		}
		
		$multipage .= ($curpage < $pages ? '<a href="javascript:'.$func.'('.$extParamStr.' '.($curpage + 1).');">&rsaquo;&rsaquo;</a>' : '').
		($to < $pages ? '<a href="javascript:'.$func.'('.$extParamStr.' '.$pages.');">... '.$realpages.'</a>' : '');
		$multipage = $multipage ? ('<span>&nbsp;共'.$num.'条记录&nbsp;</span>'.$multipage):'';
	}
	
	$maxpage = $realpages;
	return $multipage;
}

function InitValidArray($luaTable) {
	if(preg_match("/^array/i", $luaTable) == 0) {
		echo "There are errors in the lua process , with following msg:<br/>";
		echo $luaTable;
	}
}

function getUserDetail($userid, $password) {
	global $_SGLOBAL;
	$result = null;
	$query = $_SGLOBAL['mgrdb']->query("select id as userid, name, passwd, purview from admin where name='$userid' and passwd='$password'");
	if (!$query) {
		return $result;
	}
	$result = $_SGLOBAL['mgrdb']->fetch_array($query);
	return $result;
}

function checkLogin($userid, $password, $validcode, $validcodein) {
	global $_SGLOBAL;

	if(trim(strtolower($validcode))!=trim(strtolower($validcodein))) {
		return "验证码不正确";
	}

	if(empty($userid) || empty($password)) {
		return "用户名和密码不能为空";
	}

	$query = $_SGLOBAL['mgrdb']->query("select count(1) as result from admin where name='$userid' and passwd='$password'");
	if (!$query) {
		return "";
	}
	$value = $_SGLOBAL['mgrdb']->fetch_array($query);
	if(intval($value['result']) <= 0) {
		return "此用户名或密码不匹配";
	}
}

function checkUserName($userName)    
{ 

	$str = preg_replace('[^\x00-\xff]', '**', $userName);
	if($str == null || empty($str))
	{
		return "姓名只能由6-16位大小写字母(a-zA-Z)、数字(0-9)，并且必须以字母开头<br/>";     
	}

	$unLen = empty($str)?0:strlen($str);
	$reg = "/^([a-zA-Z]+(?=[0-9])|([a-zA-Z]))[a-zA-Z0-9]+$/";        

	if(!preg_match($reg, $userName))     
	{      
		return "姓名只能由6-16位大小写字母(a-zA-Z)、数字(0-9)，并且必须以字母开头<br/>";      
	}        

	if($unLen < 6 || $unLen > 16)      
	{       
		return ($unLen < 6 ? "姓名小于6个字符<br/>" : "姓名超过 16 个字符<br/>");         
	}    
	return "";
}     

function checkPassword($password)     
{      
		//判断全角
	$str = preg_replace('[^\x00-\xff]', '**', $password);
	if($str == null || empty($str))
	{
		return "密码只能由6-16位大小写字母(a-zA-Z)、数字(0-9)组成";     
	}	
	//处理特殊字符
	$reg = "/[\\\\\'\"]/";        
	if($password == "" || preg_match($reg,$password)) 
	{       
		return "密码包含非法字符  \' \" \\<br/>";
	}

	$reg = '/[a-zA-Z0-9]/';
	if(strlen(preg_replace($reg,'',$password))	>0)
	{
		return "密码只能由字母(a-zA-Z)、数字(0-9)组成";
	}

	$unLen = empty($str)?0:strlen($str);
	if($unLen < 6 || $unLen > 16)      
	{       
		return ($unLen < 6 ? "密码小于6个字符<br/>" : "密码超过 16 个字符<br/>");
	}    
	return "";
}


function checkUserInfo($user)
{
	$error="";
	$error.=checkUserName($user['name']);   
	$error.=checkPassword($user['passwd']);

	return $error;
}

function addAdmin2DB()
{
	global $_SGLOBAL;
	global $opresult;
	global $opmessage;

	$user = getUserInfo();
	$opresult = "成功";
	$opmessage = "";
	$insertOk = false;

	//添加管理员
	dbConnect("mgrdb");
	$sql = "select 1 as result from admin where name='".$_POST['name']."' ";
	$query = $_SGLOBAL['mgrdb']->query($sql);
	if (!$_SGLOBAL['mgrdb']->fetch_array($query)) {
		$purview_ =" ";
		if(!empty($_POST['purview'])) {
			$purview_ = $_POST['purview'];
		}
		$name_ = $_POST['name'];
		$passwd_ =md5(trim($_POST['passwd']));
		$createTime_ = $_POST['optime'];

		$UPsql = " insert into admin(name,passwd,purview,createTime) values( '$name_','$passwd_','$purview_',$createTime_ ) ";
		$_SGLOBAL['mgrdb']->query($UPsql);
		$insertOk = $_SGLOBAL['mgrdb']->affected_rows() > 0;
	} else {
		$opresult = "创建管理员失败";
		$opmessage = "此账号已经存在";
	}
	if(!$insertOk) {
		return;
	}
	if(strlen($opmessage)==0) {
		$opmessage = "创建管理员成功";
	}
}

//判断是否为超级管理员
function isSuper($purview)
{
	global $_moduleCodeList;
	$modulecodes = $_moduleCodeList;
	//待要查询的用户权限，如果具有“创建管理员”和“管理员列表”功能的都定义为超级管理员，即返回true

	$modulecode1 = $modulecodes['ADDADMIN']['code'];
	$modulecode2 = $modulecodes['LISADMIN']['code'];
	
	$result1 = stristr($purview,"{$modulecodes['ADDADMIN']['code']}");
	$result2 = stristr($purview,"{$modulecodes['LISADMIN']['code']}");			
	if(!empty($result) || !empty($result2))
	{
		return true;
	}
	return false;
}

//删除后台账号
function deleteUser($id)
{

	global $_SGLOBAL;

	$user = getUserInfo();
	$username = NULL;
	$purview = NULL;

	$query = $_SGLOBAL['mgrdb']->query("select name, purview from admin where id=$id;");
	if ($value=$_SGLOBAL['mgrdb']->fetch_array($query))
	{
		$username = $value['name'];
		$purview  = $value['purview'];
	}
	else
	{
		return false;		
	}
	$_SGLOBAL['mgrdb']->query("delete from admin where name='$username';"); 
	$ext = "删除".(isSuper($purview)?"超级管理员帐号":"GM帐号").$_GET['name'];
	writeAdminLog("DELADMIN", $ext);
	return true;
}

//解析权限列表
function parasModulePurview($purview, $moduleCodeNameList)
{
	//解析每个权限对应的名称
	$result = "";
	$list = explode(" ",$purview);
	foreach($list as $key=>$val) {
		if(!empty($moduleCodeNameList[$val])) {
			$result .= $moduleCodeNameList[$val]." ";
		}
	}
	return trim($result);
}


//发送POST
function sendPost($url, $postData)
{  
	$ctx = curl_init($url);
	curl_setopt($ctx, CURLOPT_RETURNTRANSFER, true);
	curl_setopt($ctx, CURLOPT_POST, true);
	curl_setopt($ctx, CURLOPT_POSTFIELDS, $postData);
	curl_setopt($ctx, CURLOPT_SSL_VERIFYPEER, 0);  //这两行一定要加,不加会报 SSL 错误
    curl_setopt($ctx, CURLOPT_SSL_VERIFYHOST, 0);
    $response = curl_exec($ctx);
    $errno = curl_errno($ctx);
    $errmsg = curl_error($ctx);
    curl_close($ctx);
    return array("ret"=>$response,"errno"=>$errno,"errmsg"=>$errmsg);
}

//发送GET
function sendGet($url)
{  
	$ctx = curl_init($url);
	curl_setopt($ctx, CURLOPT_RETURNTRANSFER, true);
	curl_setopt($ctx, CURLOPT_SSL_VERIFYPEER, 0);  //这两行一定要加,不加会报 SSL 错误
	curl_setopt($ctx, CURLOPT_SSL_VERIFYHOST, 0);
	$response = curl_exec($ctx);
	$errno = curl_errno($ctx);
	$errmsg = curl_error($ctx);
	curl_close($ctx);
	return array("ret"=>$response,"errno"=>$errno,"errmsg"=>$errmsg);
}

//写日志
function writelog($cont, $path="log.txt")
{
	$file = fopen($path, "a");
	$time = makeStrTime(time());
	fwrite($file, $time."  ".$cont."\n");
	fclose($file);
}

//显示alert
function showAlert($cont, $exit=false) {
    echo "<script type='text/javascript'>alert('$cont');</script>";
    if ($exit) {
    	exit();
    }
}

//日志表是否存在
function isLogExist($log) {
    $db = dbConnect("logdb");
    if ($db->query("select 0 from $log limit 0,0;", "SILENT")) {
        return true;
    }
    return false;
}

?>
