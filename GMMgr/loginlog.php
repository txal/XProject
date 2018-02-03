<?php 
	include_once("common.php");
	isaccess("OPLOG") or exit('Access Denied');	
	
	//GM  和  超级管理员都具有 “后台登陆日志权限”
	{
		$loglisttable2	=readloginlog($msg[2]['page'],$msg[2]['pagesize']);
		$loglist2		=$loglisttable2['data'];
		$pagecount2		=ceil($loglisttable2['recordCount']/$msg[2]['pagesize']);

		$url="";
		//如果‘用户操作日志’可见，配置其查询条件
		if(isset($msg[1]) &&  !empty($msg[1]))
		{
			$url="?s_operator={$msg[1]['selected_operator']}&s_optype={$msg[1]['selected_optype']}&page1={$msg[1]['page']}";
		}

		$pageblock2 = '';		
		if($loglisttable2['recordCount']>PAGESIZE)
			$pageblock2 = (mymulti($loglisttable2['recordCount'], $msg[2]['pagesize'], $msg[2]['page'], $url,'page2'));
		
	}
	
	function readloginlog($page,$pagesize) {
		global  $_SGLOBAL;
		dbConnect("mgrdb");
		
		//获取选定页面记录
		$start =($page-1)*$pagesize;
		$query = $_SGLOBAL['mgrdb']->query("select adminID, adminName as operator, loginIp, time, opCode as state from adminlog where opCode=1 or opCode=2 order by adminID desc, time desc limit $start,$pagesize;");
		$list = array();
		while($value = $_SGLOBAL['mgrdb']->fetch_array($query)) {
			$value['operator'] = convertPageCharset($value['operator']);
			$value['time'] = date('Y-m-d H:i:s',$value['time']); 		
			$value['state'] = convertPageCharset(intval($value['state']==1)?"登入":"登出");
			$list[]=$value;
		}
		
		//总页数
		$query	=$_SGLOBAL['mgrdb']->query("select count(1) as recordCount from adminlog where opCode=1 or opCode=2 " );
		$value	=$_SGLOBAL['mgrdb']->fetch_array($query);
		
		return array(
			'data' => $list,
			'recordCount' => intval($value['recordCount'])
		);
	}
	include template("loginlog");
?>