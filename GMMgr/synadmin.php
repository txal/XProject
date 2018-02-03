<?php
	include_once("common.php");
	isaccess("SYNADMIN") or exit('Access Denied');
	
	$serverlist		=$_SERVERLIST;
	
	if(isset($_POST['submit']))
	{
		$sourceServer = $_POST['sourceServer'];
		$desServer = $_POST['iServer'];

		$result = SynAccounts($sourceServer, $desServer);
		echo('<script language="javascript"> alert("'.$result.'"); </script>');
		if($result==1)
			echo('<script language="javascript"> alert("无法连接数据源['.$sourceServer.']"); </script>');
		elseif($result ==0)
			echo('<script language="javascript"> alert("数据同步成功"); </script>');
	}
	include template("synadmin");
	
	
	
	function SynAccounts($sourceServerID, $desServer)
	{
		global $_SERVER_DB;
		$MAX = 500;
		
		
		$dbsvr = $_SERVER_DB[intval($sourceServerID)]; 
		if($dbsvr['test'] and $dbsvr['test'] == 1)
		{
			echo('<script language="javascript"> alert("所选数据源为测试服,如确实需要同步该数据源,请修改配置文件"); </script>');
			return
		}
		
		$llink = mysql_connect($dbsvr['server'], $dbsvr['user'], $dbsvr['pwd'],true);
		if( $llink == false ) return 1;
		if(!mysql_select_db($dbsvr['mgrdb'],$llink))
		{
			if($llink and !empty($llink))
				@mysql_close($llink);
			return 1;
		}
			
		$starter = 0;
		mysql_set_charset($_SC['dbcharset'], $llink);
		do
		{
			$sql	= " select name, realName, passwd, purview from admin limit $starter, $MAX ";
			$result	=@mysql_query($sql);
			$list = array();
			
			//获取源数据
			while($value = @mysql_fetch_array($result)) $list[] = $value ;
			if(empty($list)) break;
			if($llink and !empty($llink)) @mysql_close($llink);
			
			$desServerList = explode(" ",$desServer);
			foreach( $desServerList as $srvID)
			{	

				$dbsvr = $_SERVER_DB[intval($srvID)]; //新服务器信息
				$llink = @mysql_connect($dbsvr['server'], $dbsvr['user'], $dbsvr['pwd'],true);
				if( $llink != false and @mysql_select_db($dbsvr['mgrdb'],$llink))
				{
					@mysql_query("  truncate table admin; ");
					$sql2 = " insert into admin(name,realName,passwd,purview) values ";
					$mod = " ";
					foreach($list as $v)
					{
						$sql2 = $sql2.$mod." ('{$v['name']}','{$v['realName']}','{$v['passwd']}','{$v['purview']}')  " ;
						$mod = " , ";
					}
					@mysql_query($sql2);
		
					return $sql2;
				}
				if($llink and !empty($llink)) @mysql_close($llink);
			}
			
			$starter = $starter + $MAX;
			
		
		}while(true);
		
		return 0;
	}
?>