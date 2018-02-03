<?php
	require_once 'common.php';
	require_once 'include/modulecode.inc.php';
	//登录
	if(isset($_POST['submit']))
	{
		session_start();
		$validCode = $_SESSION['seccode'];
		$userID = $_POST['userid'];
		$password = md5($_POST['password']);
		$validCodeIn = $_POST['validcode'];

		dbConnect("mgrdb");
		sort($serverIdArr);
		$serverID = end($serverIdArr);

		ssetcookie('server', $serverID, 0);

		$error = checkLogin($userID, $password, $validCode, $validCodeIn);
		
		if(empty($error))
		{
			$loginUser = getUserDetail($userID, $password);
			setLoginCookie($loginUser);
			writeAdminLog("LOGIN");
			Header("Location: index.php");
			return;
		}
		else
		{
			$opresult = "失败";
			$opmessage = $error."<br/><br/><img align='absMiddle' src='images/back.gif'/><a href=login.php > 返回 </a>";
			include template("result");
		}
	}
	else
	{		
		include template('login');
	}

?>
