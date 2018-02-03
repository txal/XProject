<?php
	require_once 'common.php';	
	if (!isaccess("LISADMIN"))
	{
		exit('Access Denied');
	}

	$curUser = getUserInfo();

	$moduleList	= array();
	foreach ($_moduleCodeList as $key=>$value) {
		$moduleList[$value['code']]=array('type'=>$value['name'],'value'=>$value['code'],'checked'=>'');
	}

	//处理上层页面操作，用于显示修改页面
	if(!empty($_GET['userID']) ) {
		dbConnect("mgrdb");
		$userID = $_GET['userID'];
		$query = $_SGLOBAL['mgrdb']->query("select id,purview from admin where id=$userID;");
		$value = $_SGLOBAL['mgrdb']->fetch_array($query);
		$purviewOld = $value['purview'];
		$purviewNew = $value['purview'];
		$purviewList = explode(" ",$purviewOld);
		foreach($purviewList as $v) {
			if(intval($v) > 0 && !empty($moduleList[intval($v)])) {
				$moduleList[$v]['checked'] = "checked";
			}
		}
		include template('modifypurview');
	}

	//处理修改权限表单
	if(!empty($_POST['submit'])) {
		dbConnect("mgrdb");
		$userid = $_POST['userID'];
		$userName  = $_POST['userName'];
		$purviewOld	= $_POST['purviewOld'];
		$purviewNew	= $_POST['purviewNew'];
		$_SGLOBAL['mgrdb']->query("update admin set purview='$purviewNew' where id=$userID;");
		$curUser['purview']	= $purviewNew;
		setLoginCookie($curUser);
		echo("<script language=\"javascript\"> parent.location.reload(); </script>");
		$ext = "修改".(isSuper($purviewOld)?"超级管理员帐号":"GM帐号").$userName;
		writeAdminLog("MODADMIN", $ext);
	}
?>