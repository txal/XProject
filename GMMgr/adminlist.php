<?php 
	include_once("common.php");
	if (!isaccess("LISADMIN"))
	{
		exit('Access Denied');
	}

	//页面大小
	define('PAGESIZE',10);
	define('SUPERADMIN','cyadmin');
	
	$currentUser = getUserInfo();

	//模块编码表
	$moduleCodeList	= array();
	foreach($_moduleCodeList as $short => $desc) {
		$moduleCodeList[$desc['code']] = $desc['name'];
	}
	
	//查询页面号
	$page = !empty($_GET['page']) && intval($_GET['page']) > 0 ? intval($_GET['page']) : 1;
	
	//页码链接
	$pageblock="";
	if(isset($_GET['option']) && $_GET['option']=="delete") {
		if($_GET['option']	=="delete") {
			//删除管理员
			if(deleteUser($_GET['id'])) {
				header("Location:adminlist.php");
			}
		}
	} else {
		$admintable = readAdminList($page,PAGESIZE);
		$adminlist = $admintable['data'];		

		if($admintable['recordCount']>PAGESIZE) {
			$pageblock = convertPageCharset(multi($admintable['recordCount'], PAGESIZE, $page, ''));
		}
		include template("adminlist");
	}
	
	function readAdminList($page, $pagesize) {
		global $currentUser;
		global $moduleCodeList;
		global $_SGLOBAL;
		
		//获取选定页面记录
		dbConnect("mgrdb");
		$start = ($page-1)*$pagesize;
		$query = $_SGLOBAL['mgrdb']->query("select id,name,purview,createtime from admin limit $start,$pagesize;");
		$list = array();
		while($value = $_SGLOBAL['mgrdb']->fetch_array($query)) {
			$deleteop = "";
			$modifyop = "";
			if(isSuper($currentUser['purview'])) {
				$deleteop = "<input type=\"button\" name=\"delete\" value=\"删除\" onClick=\"deleteAdmin({$value['id']},'{$value['name']}')\">";
				$modifyop = "<input type=\"button\" name=\"modify\" value=\"编辑\" onClick=\"modifyPurview({$value['id']},'{$value['name']}');\">";
			}
			$value['option'] = $modifyop." ".$deleteop;
			$value['purview'] = parasModulePurview($value['purview'], $moduleCodeList);			
			$value['createtime'] = date('Y-m-d', $value['createtime']); 		
			$list[] = $value;
		}

		//总页数
		$query = $_SGLOBAL['mgrdb']->query(" select count(1) as recordCount from admin;");
		$value = $_SGLOBAL['mgrdb']->fetch_array($query);

		return array('data'=>$list, 'recordCount'=>intval($value['recordCount']));
	}
	
?>