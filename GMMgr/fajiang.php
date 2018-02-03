<?php
require_once 'common.php';
isaccess("PR") or exit('Access Denied');
header("content-type:text/html;charset=$_SC['charset']");

if (!empty($_POST['action'])) {
	$type = !empty($_POST['type']) && in_array($_POST['type'], array(1, 2, 3)) ? intval($_POST['type']) : 1;
	$giftids = trim($_POST['giftids']);
	$title = trim($_POST['title']);
	$content = trim($_POST['content']);
	$remark  = trim($_POST['remark']);
	$msg = strip_tags(trim($_POST['msg']));
	$content = str_replace("\r\n", "", $content);
	$gids = explode('|', $giftids);
	
	switch ($type) {
		case 1:
			$ext = trim($_POST['members']);

			$ext = str_replace("\r", "", $ext);
			$arr = explode("\n", trim($ext));
			foreach($arr as $k=>$v)
			{
				$arr[$k] = $v."+S";
			}
			$ext = implode("|", $arr);
	
			$user = trim(str_replace("\r\n", ";", $_POST['members']));
			break;
		case 2:
			$ext = '';
			$user = '全服发放';
			break;
		case 3:
			$ext = trim($_POST['union']);
			$user = trim($_POST['union']);
			break;
			
		// 11 发奖通过
		// 12 发奖不通过
	}
	
	$ptime = time();
	$admininfo = getUserInfo();
	$ip = getonlineip();
	
	//*
	foreach ($gids as $gid) {
		//$gid = explode(',', $gid);
		$data = array(
			'adminId'	=> $admininfo['userid'],
			'type'		=> $_opCodeList['FAJIANG']['code'],
			'ext1'		=> $user,
			'ext2'		=> $gid,
			'remark'	=> $remark,
			'time'		=> $ptime,
			'loginIp'   => $ip,
		);
		writeAdminLog($data);
	}
	//*/
	
	$info = array(
		'type' => $type,
		'title' => $title,
		'content' => $content,
		'gifts' => $giftids,
		'remark' => $remark,
		'ext' => $ext,
		'ptime' => $ptime,
		'users' => $user,
		'msg' => $msg,
	);

	$v = insertTable('gifts', $info);
	if ($v> 0) {
		exit("<script>alert('发奖成功, 等待管理员审核');location.href='fajiang.php';</script>");
	} else {
		exit("<script>alert('发奖失败');location.href='fajiang.php';</script>");
	}
	

/*	
$CMD =<<<CMD
do
	DoFun("SENDMAIL", $type, "$title", "$content", "$giftids", "$remark", "$ext")
end
CMD;

//echo $CMD;exit;

	$ret = query_cmd(101, $CMD);
	//echo $ret;
	
	exit("<script>alert('发奖成功');location.href='fajiang.php';</script>");
*/
}
/*
$CMD =<<<CMD
do
	DoFun("GETUNIONS", 1, 1000)
end
CMD;

eval('$unions = '.query_cmd(101, $CMD));
array_pop($unions);
array_pop($unions);
*/

include_once(APP_ROOT.'./include/shop.inc.php');

$type = $_opCodeList['FAJIANG']['code'];

$total = $_SGLOBAL['mgrdb']->result($_SGLOBAL['mgrdb']->query("SELECT COUNT(id) FROM adminlog WHERE type='$type'"), 0);
if ($total > 10) {
	$page = !empty($_GET['page']) ? intval($_GET['page']) : 1;
	$start = ($page - 1) * 10;
	$limit = "LIMIT $start, 10";
	
	$multi = multi($total, 10, $page, 'fajiang.php');
} else {
	$limit = '';
	$multi = '';
}

$logs = array();
$query = $_SGLOBAL['mgrdb']->query("SELECT * FROM adminlog WHERE type='$type' ORDER BY id DESC $limit");
while ($row = $_SGLOBAL['mgrdb']->fetch_array($query)) {
	$goods = explode(',', $row['ext2']);
	$id = $goods[0];
	$tmp = $shopgoods[$id{0} - 1];
	foreach ($tmp as $e) {
		if ($e['id'] == $id) {
			$row['goods'] = $e['name'];
			break;
		}
	}
	
	$row['amount'] = $goods[1];
	
	$logs[] = $row;
}

include template('fajiang');
?>
