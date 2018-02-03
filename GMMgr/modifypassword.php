<?php
	require_once 'common.php';
	require_once './include/modulecode.inc.php';

	//获取用户信息
	$user = getUserInfo();

	//判断用户是否已经登录
	if(empty($user['name'])  || empty($user['passwd']))
	{
		exit('User not login.Access Denied');
	}

	//所在服务器
	$sServerID = $_COOKIE['server'];
	$sServerName =$_SERVERLIST[$sServerID]['name'];

	if(!empty($_POST['submit']))
	{
		session_start();
		$passwordold	=md5(trim($_POST['passwordold']));
		$passwordnew	=md5(trim($_POST['passwordnew']));
		$validcode		=$_SESSION['seccode'];
		$validcodein	=$_POST['validcode'];
		
		if($user['passwd'] != $passwordold)
		{
			$opresult	="失败";
			$opmessage	="您输入的旧密码错误"."<br/><br/><img align='absMiddle' src='images/back.gif'/><a href=modifypassword.php >返回</a>";;

			include template("result");
			return;
		}

		if(trim(strtolower($validcode)) != trim(strtolower($validcodein)))
		{
			$opresult	="失败";
			$opmessage	="验证码输入错误"."<br/><br/><img align='absMiddle' src='images/back.gif'/><a href=modifypassword.php >返回</a>";;

			include template("result");
			return;
		}

		$success = $_SGLOBAL['mgrdb']->query(" update admin set passwd='$passwordnew' where id='$userid' ");
		if($success)
		{
			$loginUser = getUserDetail($user['name'], $passwordnew);
			setLoginCookie($loginUser);
			$opName = $_opCodeList['MODPWD']['name'].":$passwordold->$passwordnew";
			writeAdminLog("MODPWD", $opName);
			$opresult = "成功";
			$opmessage = "密码修改成功";

			include template("result");
			return;
		}
		else//有错误信息 
		{
			$opresult	="失败";
			$opmessage	="<br/><br/><img align='absMiddle' src='images/back.gif'/><a href=modifypassword.php >返回</a>";

			include template("result");
			return ;
		}
	}

	include template('modifypassword');

?>
