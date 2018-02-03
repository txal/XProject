<?php
	//推广员后台登陆
	require_once '../../common.php';

	//登录
	$strErr = "";
	$account = "";
	$rawpassword = "";

	if (!empty($_COOKIE['__pmtid']) && !empty($_COOKIE['__pmtname']) && !empty($_COOKIE['__pmtpasswd'])) {
		Header("Location: promoterfunc.php");

	} else if(isset($_POST['submit'])) {
		session_start();
		$validCode = $_SESSION['seccode'];
		$account = $_POST['account'];
		$rawpassword = $_POST['password'];
		$password = md5($rawpassword);
		$validCodeIn = $_POST['validcode'];

		dbConnect("mgrdb");
		if(trim(strtolower($validCode))!=trim(strtolower($validCodeIn))) {
			$strErr = "验证码不正确";
		} else {
			$query = $_SGLOBAL['mgrdb']->query("select count(1) as result from promoter where name='$account' and passwd='$password'");
			if (!$query) {
				$strErr = "查询账号失败";
			} else {
				$value = $_SGLOBAL['mgrdb']->fetch_array($query);
				if(intval($value['result']) <= 0) {
					$strErr = "此用户名或密码不匹配";
				} else {
					$query = $_SGLOBAL['mgrdb']->query("select * from promoter where name='$account' and passwd='$password'");
					$user = $_SGLOBAL['mgrdb']->fetch_array($query);
					ssetcookie('__pmtid', $user['id'], 3600);
					ssetcookie('__pmtname', $user['name'], 3600);
					ssetcookie('__pmtpasswd', $user['passwd'], 3600);

					//LOG
					$id = $user['id'];
					$loginIp = $_SGLOBAL['onlineip'];
					$loginTime = time();
					$_SGLOBAL['mgrdb']->query("update promoter set loginIp='$loginIp', loginTime='$loginTime' where id=$id;");

					Header("Location: promoterfunc.php");
					return;
				}
			}
		}
	}
?>

<html>
<head>
    <meta http-equiv="content-type" content="text/html;charset=utf-8"/>
    <meta name="viewport" content="width=device-width, initial-scale=1"/> 
    <title>推广员-登录</title>
    <style type="text/css">
        ul {
            margin-left:10px;
            margin-right:10px;
            margin-top:10px;
            padding: 0;
        }
        li {
            width: 100%;
            float: left;
            margin: 0px;
            margin-left:1%;
            padding: 0px;
            height: 40px;
            display: inline;
            line-height: 38px;
            color: #000000;
			background-color:#FFFFFF;
            font-size: large;
            word-break:break-all;
            word-wrap: break-word;
            margin-bottom: 1px;
        }
    </style>
	<script language="javascript" type="text/javascript">
		function recharge(json) {
		}
		function updateseccode() {
			var img = '../../do_seccode.php?ac=seccode&rand='+Math.random();
			if(document.getElementById('id_img_seccode')) {
				document.getElementById('id_img_seccode').src = img;
			}
		}
		function onSubmit(form) {
			if (account.value == "") {
				alert("请输入账号");
				return false;
			}
			if (password.value == "") {
				alert("请输入密码");
				return false;
			}
			if (validcode.value == "") {
				alert("请输入验证码");
				return false;
			}
			return true;
		}
	</script>
</head>
<body>
<form method="post" action="" onsubmit="return onSubmit(this);">
	<div align="center">
        <ul>
			<li style="text-align:center;">
			账号: <input name='account' id='account' type='text' style="height:30; width:60%;" value="<?=$account?>"> </input>
			</li>
			<li style="text-align:center;">
			密码: <input name='password' id='password' type='password' style="height:30; width:60%;" value="<?=$rawpassword?>"> </input>
			</li>
			<li style="text-align:center;">
				<div align="center">
				验证码:
				<input name="validcode" type="text" id="validcode" style="height:25; width:25%;"></input>
			    <img align="absMiddle" id="id_img_seccode" src="../../do_seccode.php?ac=seccode&rand="+javascript:updateseccode() complete="complete"/>
				<a href=javascript:updateseccode()>换一张</a>
				</div>
			</li>
			<li style="text-align:center;">
			<input name='submit' id='submit' type='submit' style="height:30; width:30%;" value="登录"> <font color="red"><?=$strErr?></font></input>
			</li>
        </ul>
	</div>
</form>
</body>
</html>
