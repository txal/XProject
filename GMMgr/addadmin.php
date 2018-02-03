<?php 
	include_once("common.php");
	
	if (!isaccess("ADDADMIN"))
	{
		exit('Access Denied');
	}

	$user = getUserInfo();
	$moduleCodeList = array();
	if(!isset($_POST['submit']))
	{
		foreach ($_moduleCodeList as $key=>$value)
		{
			//屏蔽其他管理员有 创建管理员, 修改管理员 的权限,
			if(!($key == "ADDADMIN"  ||  $key == "LISADMIN"))
			{
				$moduleCodeList[] = array('type'=>$value['name'], 'value'=>$value['code']);
			}
		}
		include template("addadmin");
	}
	else
	{
		$_POST['optime'] = time();
		$user=array(
			'name' => $_POST['name'],
			'passwd' => $_POST['passwd'],
			'purview' => $_POST['purview'],
			'createtime' => $_POST['optime']
		);
		
		$opmessage = checkUserInfo($user);
		if(!empty($opmessage))
		{
			$opresult = "失败";
			include template("result");
			return;
		}

		$opresult = "";
		$opmessage= "";
		
		addAdmin2DB($_COOKIE['server']);
		include template("result");
	}
?>