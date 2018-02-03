<?php
header("Content-type: text/html; charset=utf-8");
	//require_once 'common.php';
	//$user =getUserInfo();

	setcookie('server', '', -86400 * 365);
	setcookie('__name', '',-86400 * 365);
	setcookie('__userid', '' ,-86400 * 365);
	setcookie('__passwd', '' ,-86400 * 365);
	setcookie('__purview',	'' ,-86400 * 365);

	//写日志
	/*writeAdminLog(array
				(
				'adminId'	=>$user['name'],
				'type'		=>$_opCodeList['LOGOUT']['code'],
				'remark'	=>$_opCodeList['LOGOUT']['name'],
				'loginIp'	=>$_SERVER['REMOTE_ADDR'],
				'time'		=>time()
				)
			);
	*/
	exit("<script language=\"javascript\">alert('退出成功！');window.location.href = 'login.php';</script>");
?>