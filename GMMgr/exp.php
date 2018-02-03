<?php
require_once 'common.php';
isaccess("EM") or exit('Access Denied');
header("content-type:text/html;charset=$_SC['charset']");


if (isset($_POST['action'])) {

	$list = array();
	foreach($_POST as $key=>$value)
	{
		if(preg_match('/^(GBC_)/', $key) > 0 )
		{
			$list[$key] = $value;
		}

	}			
	
	$list['GBC_FREECHAT']		= (intval($list['GBC_FREECHAT']) == 1 ? 'true' : 'false');
	$list['GBC_REG_DENY']		= (intval($list['GBC_REG_DENY']) == 1 ? 'true' : 'false');
		
	foreach($list as $key=>$value)
	{
		$left = preg_replace('/^(GBC_)/', "GBC.", $key);
		if(! ($left === $key) )
		{
			$conf = "$left = $value";
			$sql = " update exttable2 set str1 = '".$conf."' where `type`=26 and `int1`=2 and  str1 like '%".$left."%' ";
			$_SGLOBAL['mgrdb']->query($sql);
		}	
	}
	
	
	$user=getUserInfo();
	$log = array(
		'adminId'		=>$user['userid'],
		'type'			=>$_opCodeList["SETEXP"]['code'],
		'ext1'			=>"",
		'ext2'			=>"",
		'remark'		=>$_opCodeList["SETEXP"]['name'],
		'loginIp'		=>$_SERVER['REMOTE_ADDR'],
		'time'			=>time(),
	);
	writeAdminLog($log);
	
	exit('<script>alert("设置成功.");history.back();</script>');
}


$exps = getGBCSettings();

include template('exp');
//**********************************************    functions   ******
	function getGBCSettings()
	{
		global $_SGLOBAL;
		
		$exps = array();
		$sql = " select id, str1 as confs from exttable2 where `type`=26 and `int1`=2 ";
		$result = $_SGLOBAL['mgrdb']->query($sql);
		while( $value = $_SGLOBAL['mgrdb']->fetch_array($result))
		{
			$_id 	= $value['id'];
			$_confs = $value['confs'];
			
			$token = explode("=", $_confs);
			if(isset($token[1]))
			{
				$ttype 	= str_replace(".", "_", trim($token[0]));
				$num 	= trim($token[1]);
					
				$exps[$ttype] = $num;
			}
		}
		
		if (empty($exps['GBC_EXP_BONUS_YD'])) 	{ $exps['GBC_EXP_BONUS_YD'] =  '0'	; }
		if (empty($exps['GBC_EXP_BONUS_XS'])) 	{ $exps['GBC_EXP_BONUS_XS'] =  '0'	; }
		if (empty($exps['GBC_BD_BONUS'])) 		{ $exps['GBC_BD_BONUS'] 	=  '1'	; }
		if (empty($exps['GBC_SK_BONUS'])) 		{ $exps['GBC_SK_BONUS'] 	=  '1'	; }
		if (empty($exps['GBC_RC_BONUS'])) 		{ $exps['GBC_RC_BONUS'] 	=  '1'	; }
		if (empty($exps['GBC_SO_BONUS'])) 		{ $exps['GBC_SO_BONUS'] 	=  '1'	; }
		if (empty($exps['GBC_NONEEDBONUS'])) 	{ $exps['GBC_NONEEDBONUS'] 	=  '0'	; }
		if (empty($exps['GBC_FREECHAT'])) 		{ $exps['GBC_FREECHAT'] 	=  'false'; }
		if (empty($exps['GBC_REG_DENY'])) 		{ $exps['GBC_REG_DENY'] 	=  'false'; }
		
		return $exps;
	}
	
	

?>

















