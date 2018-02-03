<?php 
	error_reporting(0);
	require_once("common.php");
	require_once("./include/gift_key_value.inc.php");
	isaccess("EXCHANGE") or isaccess("EXCHANGE1") or exit('Access Denied');
	
	
	$admin = isaccess("EXCHANGE1");
	$isSuperAdmin = false;
	$canViewAuction = isaccess("VIEWAUCTION");
	$userinfo	=getUserInfo();
	if ($userinfo['name'] == 'mytadmin')
		$isSuperAdmin = true;		

	if ( !empty($_REQUEST['export']) && $_REQUEST['export'] == 'csv' ) 
	{
		toExport();
		exit;
	}
	
	
	$pageblock = "";
	$view = getView();
	if(!isset($view))
	{
		if($canViewAuction)
		{
			$auctionData = getAuctionList(1);
			$auctionAmount = $auctionData['count'] ;
			$auctionList  = $auctionData['data'];
			$pageblock = convertPageCharset(ajax_multi2($auctionAmount, 10, 1, 'viewAuction'));
		}
		include template("exchange");
		exit;
	}
	
	$_DataDriver = dataDriver();
	$operator = $_DataDriver[$view];
	$operator();
	exit();

	
	
	//-------------------------------------  functions 
	function toExport()
	{
		global $userinfo;
		global $gifts;
		global $_SGLOBAL;
		
		isaccess("EXEXP") or exit('Access Denied');
		try{
			$log		=array();			
			$log['adminId']		=$userinfo['userid'];
			$log['type']		=getOptionCode("EXEXP");		
			$log['remark']		=convertDBCharset("导出 购买记录");
			$log['time']		=time();
			writeAdminLog($log);
		} catch(Exception $e)  {
			$error="error";
		}

		$giftlist		= array();
		foreach($gifts as $key=>$value)
		{
			foreach($value as $k=>$v)
				$giftlist[$v]=convertPageCharset($k);
		}

		$where1 = "";
		$psource = array( 1=>"元宝购买",2=>"礼券购买",3=>"荣誉购买");
		$sql	=" select A.id, B.loginName as username ,A.goodid ,A.num,A.way ,A.totalprice ,A.operation,A.time,C.loginName as targetName 
					from mallrecord as A inner join player as B on A.uid = B.id
					left join player as C on A.targetid = C.id 
					$where1 
					order by A.id desc";

		$result	=$_SGLOBAL['mgrdb']->query($sql);
		$line = '';

		$fileName = "purchase-all-". date("Y-m-d", time(0)) ."-". rand(100, 999). ".csv";
		header("Content-Disposition:attachment;filename=$fileName"); 
		header("ContentType:application/octet-stream");
		
		//echo "\xEF\xBB\xBF";
		$title = "购买编号,玩家帐号,物品名称,买数量,消费类型,消费金额,购买渠道,获得者,消费时间\n";
		$title = convertDBCharset($title);
		echo $title;
		while($value =$_SGLOBAL['mgrdb']->fetch_array($result)) {
			$way		= $psource[intval($value['way'])];
			$goodname	= isset($giftlist[$value['goodid']]) ? ($giftlist[$value['goodid']]) : "";
			$value['operation'] = intval($value['operation'])==1?("商城"):("商城/赠送给其他玩家");

			//$line = convertPageCharset($line);
			$line = $value['id'] .','. $value['username'] .','. ($goodname) .','. $value['num'] .','. $way .','. $value['totalprice'] .','. $value['operation'] .','. $value['targetName'] .','. date("Y-m-d H:i:s", $value['time']) ."\n";			
			$line = convertDBCharset($line);
			
			echo $line;
		}
		exit(0);
	
	}
	
	
	function dataDriver()
	{
		$drivers = array(
			1 => 'getComsumeExchange',
			2 => 'getRecharge',
			3 => 'getAuction',
		);

		
		return $drivers;
	}
	
	function getAuction()
	{
		$page = isset($_GET['page'])? $_GET['page']: 1 ;
		$auctionData = getAuctionList($page);
		$auctionAmount = $auctionData['count'] ;
		$pageblock = "";
		
echo <<<HTML
	<table width="98%" border="0" cellpadding="2" cellspacing="1" bgcolor="#D1DDAA" align="center" style="margin-top:8px">
		<tr><td colspan="5">拍卖交易记录</td></tr>
		<tr align="center" bgcolor="#FAFAF1" height="22">
		  <td>拍卖类型</td>
		  <td>物品</td>
		  <td>价格</td>
		  <td>卖家</td>
		  <td>买家</td>
		  <td>成交时间</td>
		</tr>
HTML;
		
		foreach($auctionData['data'] as $v)
		{
			$type = $v['type'];
			$color = $v['color'];
echo <<<HTML
		<tr align='center' bgcolor="$color" onMouseMove="javascript:this.bgColor='#FCFDEE';" onMouseOut="javascript:this.bgColor='$color';" height="22">
			<td>$type</td>
			<td>$v[gname]</td>
		  <td>$v[price]</td>
		  <td>$v[seller]</td>
		  <td>$v[buyer]</td>
		  <td>$v[extime]</td>
		</tr>
HTML;
		
		}
		
		if($auctionAmount > 10 )
			$pageblock = convertPageCharset(ajax_multi2($auctionAmount, 10, $page, 'viewAuction','0'));
			
echo <<<HTML
		<tr align="right" bgcolor="#EEF4EA">
			<td height="36" colspan="6" align="left">$pageblock</td>
		</tr> 
	</table>
HTML;
	
		exit;
	}
	
	function getRecharge()
	{
		$result = getobjectlist($_GET);
		$pageblock = "";
		$page = isset($_GET['page'])? $_GET['page'] : 1 ;

echo <<<HTML
	<table width="98%" border="0" cellpadding="2" cellspacing="1" bgcolor="#D1DDAA" align="center" style="margin-top:8px">
		<tr align="center" bgcolor="#FAFAF1" height="22">
		  <td>编号</td>
		  <td>玩家名</td>		  
		  <td>登陆名</td>
		  <td>道具名</td>
		  <td>数量</td>
		  <td>获取时间</td>
		</tr>
HTML;
		
		$list = $result['data'];
		if($list)
		{
			foreach($list as $value)
			{
				$seqno = $value['seqno'];
				$username = $value['username'];
				$loginName = $value['loginname'];
				$giftname = $value['giftname'];
				$num = $value['num'];
				$buytime = $value['buytime'];
				
echo <<<HTML
				
		<tr align='center' bgcolor="#FFFFFF" onMouseMove="javascript:this.bgColor='#FCFDEE';" onMouseOut="javascript:this.bgColor='#FFFFFF';" height="22">
		  <td>$seqno</td>
		  <td>$username</td>
		  <td>$loginName</td>		  
		  <td>$giftname</td>
		  <td>$num</td>
		  <td>$buytime</td>

		</tr>	
HTML;
			}
			
			
			$totalcount = $result['recordCount'];
			if( $totalcount > 10)	
			{
				$player = isset($_GET['username']) ? $_GET['username'] : 0;
				$loginname = isset($_GET['loginname']) ? $_GET['loginname'] : 0 ;
				$obname = isset($_GET['obname']) ? $_GET['obname'] : 0 ;
				$pageblock = convertPageCharset(ajax_multi2($totalcount, 10, $page, 'viewRecharge'));
			}			
		}
		
echo <<<HTML
		<tr align="right" bgcolor="#EEF4EA">
			<td height="36" colspan="9" align="left">$pageblock</td>
		</tr> 
	</table>
HTML;
		
		exit;
	}
	
	function getComsumeExchange()
	{
		global $isSuperAdmin;
		global $giftListKeyValue;
		
		$result = getmallrecord($_GET);		
		$page = isset($_GET['page']) ? intval($_GET['page']) : 1 ;
		$list	=$result['data'];
		$psource = array( 1=>"元宝购买",2=>"礼券购买",3=>"荣誉购买");
		$pageblock = "";
		
		//购买记录[导出数据]权限
		$exportPurview = "";
		if ( isaccess("EXEXP") && $isSuperAdmin)
		{
			$exportPurview =  '<a href="?export=csv" target="_blank"><B><font size="1" color="blue">导出数据</font></B></a>' ;
		}
		
echo <<<HTML
	<table width="98%" border="0" cellpadding="2" cellspacing="1" bgcolor="#D1DDAA" align="center" style="margin-top:8px">
		<tr><td colspan="8">购买记录</td><td>$exportPurview</td></tr>
		<tr align="center" bgcolor="#FAFAF1" height="22">
		  <td>购买编号</td>
		  <td>玩家帐号</td>
		  <td>物品名称</td>
		  <td>买数量</td>
		  <td>消费类型</td>
		  <td>消费金额</td>
		  <td>购买渠道</td>
		  <td>获得者</td>
		  <td>消费时间</td>
		</tr>
HTML;
		

		if($list)
		{
			foreach($list as $value)
			{
				$goodname	= isset($giftListKeyValue[$value['goodid']])?($giftListKeyValue[$value['goodid']]):"";
				$goodname	= convertPageCharset($goodname);
				$id 		= $value['id'];
				$username	= $value['username'];
				$num		= $value['num'];
				$way		= ($psource[intval($value['way'])]);
				$totalprice = $value['totalprice'];
				$source 	= intval($value['operation'])==1?("商城"):("商城/赠送给其他玩家");
				$target 	= intval($value['operation'])==1?$value['username']:$value['targetName'];
				$optime 	= date('Y-m-d H:i:s',intval($value['time']));
				
echo <<<HTML
				
		<tr align='center' bgcolor="#FFFFFF" onMouseMove="javascript:this.bgColor='#FCFDEE';" onMouseOut="javascript:this.bgColor='#FFFFFF';" height="22">
			<td>$id</td>
			<td>$username</td>
			<td>$goodname</td>
			<td>$num</td>
			<td>$way</td>
			<td>$totalprice</td>
			<td>$source</td>
			<td>$target</td>
			<td>$optime</td>
		</tr>	
HTML;

			}

		
		$totalcount = $result['recordCount'];
		if( $totalcount > 10)	
			$pageblock = convertPageCharset(ajax_multi2($totalcount, 10, $page, 'viewComsumeExchange','0'));
		}
echo <<<HTML
		<tr align="right" bgcolor="#EEF4EA">
			<td height="36" colspan="9" align="left">$pageblock</td>
		</tr> 
	</table>
HTML;
	
		
	}
	
	function getView()
	{
		if(! isset($_GET)) return null ;
		if(! isset($_GET['view'])) return null;
		
		return intval($_GET['view']);
	}
	
	//old
	
	function getobjectlist($param)
	{

		global $_SGLOBAL;
		global $gifts;
		global $giftListKeyValue;
		
		$param['pagesize'] = 10 ;

		$start	=($param['page']-1)*$param['pagesize'];
		$limit	=" limit $start, {$param['pagesize']} ";

		if(empty($param['loginname']) && empty($param['username']) && empty($param['obname']))
		{
			return array(
				'data'			=>array(),
				'recordCount'	=>0
			);
		}
		
		$loginname = $param['username'];
		$playername = isset($param['loginname'])?$param['loginname']:null;
		if( !empty($loginname) && strlen(trim($loginname)) > 0 )
			$where1 = " where player = '".$loginname."' and " ;
		elseif( !empty($playername) && strlen(trim($playername)) > 0 )
			$where1 = " where loginname = '".$playername."' and " ;
		else
			$where1 = " where ";

		$giftlist2		=array();
		foreach($gifts as $key=>$value)
		{
			foreach($value as $k=>$v)
				$giftlist2[$k]=($v);
		}
		
		$where2	=" ";
		if(!empty($param['obname']))
		{
			$gid	=convertDBCharset($param['obname']);

			$gid	=$giftlist2[$gid];
			$where2	=" and gid=$gid ";
		}

		$sql="
			select A.id as seqno,gid as giftname,way,time as buytime ,count as num, C.loginName as loginname , C.player as username
			from proprecord as A left join player as C on C.id=A.uid
			where exists(select 1 from player as B $where1 B.id=A.uid) $where2
			order by A.id desc 
			$limit 
		";

		$data=array();
		$query=$_SGLOBAL['mgrdb']->query($sql);
		while($value=$_SGLOBAL['mgrdb']->fetch_array($query))
		{		
			$giftname = $giftListKeyValue[$value['giftname']];
			$value['buytime']	=date('Y-m-d H:i:s',$value['buytime']);
			$value['giftname']	=convertPageCharset(empty($giftname)?"????":$giftname);
			$value['username']	= convertPageCharset($value['username']);
			$value['loginname']	= convertPageCharset($value['loginname']);
			$data[]				=$value;

		}
		
		$sql="
			select count(1) as recordCount
			from proprecord as A
			where exists(select 1 from player as B $where1 B.id=A.uid) $where2
		";

		$recordCount=0;
		$query=$_SGLOBAL['mgrdb']->query($sql);
		if($value=$_SGLOBAL['mgrdb']->fetch_array($query))
		{
			$recordCount=$value['recordCount'];
		}
		
		return array(
			'data'			=>$data,
			'recordCount'	=>$recordCount
		);
	}
	

	function getmallrecord($param)
	{
		global $_SGLOBAL;
		global $gifts;

		$where1	=" ";
		$mod	=" where ";
		
		$param['pagesize'] = 10 ;
		if(!isset($param['page']))
			$param['page'] = 1 ;

		//过滤用户名
		if(!empty($param['username']))
		{
			$result	=$_SGLOBAL['mgrdb']->query(" select id as uid from player where loginName='".$param['username']."' ");
			if($result && ($value	=$_SGLOBAL['mgrdb']->fetch_array($result)))
			{
				$uid	=$value['uid'];

				$where1	=$where1.$mod." A.uid=$uid ";
				$mod	=" and ";
			}else
			{
				return array(
					'data'			=>null,
					'recordCount'	=>0
				);			
			}
		}

		//过滤物品名
		if(!empty($param['objname']))
		{
			$giftlist		=array();
			foreach($gifts as $key=>$value)
			{
				foreach($value as $k=>$v)
					$giftlist[$k]=($v);
			}

			if (!empty($giftlist[convertDBCharset($param['objname'])])) 
			{
				$goodid	=$giftlist[convertDBCharset($param['objname'])];
				$where1	=$where1.$mod." A.goodid=$goodid ";
				$mod	=" and ";
			}
		}

		//过滤查询时间
		$startdatetime	=!empty($param['start'])?($param['start']):0;
		$enddatetime	=!empty($param['end'])?($param['end']):time();

		$where1	=$where1.$mod." A.time between $startdatetime and $enddatetime ";
		$mod	=" and ";

		$startpos	=($param['page']-1)*$param['pagesize'];
		$limit		=" limit $startpos,".$param['pagesize']." ";
		$sql	=" select A.id, B.loginName as username ,A.goodid ,A.num,A.way ,A.totalprice ,A.operation,A.time,C.loginName as targetName 
					from mallrecord as A inner join player as B on A.uid = B.id
					left join player as C on A.targetid = C.id
					$where1 
					order by A.id desc 
					$limit ";

		$result	=$_SGLOBAL['mgrdb']->query($sql);
		$list	=array();
		while($value	=$_SGLOBAL['mgrdb']->fetch_array($result))
		{
			$list[]	=$value;
		}

		$result	=$_SGLOBAL['mgrdb']->query(" select count(1) as recordCount from mallrecord as A inner join player as B on A.uid = B.id $where1 ");
		$value	=$_SGLOBAL['mgrdb']->fetch_array($result);
		$ccount = $value['recordCount'];

		return array(
			'data'			=>$list,
			'recordCount'	=>$ccount
		);
	}
	
	function getAuctionList($auctionIndex)
	{

		global $_SGLOBAL;
		$startIndex = max(0,$auctionIndex-1)* 10;
		$list = array();
		$sql = "select `type`,gname, gold, money, cid, scid, from_unixtime(downtime) as downtime from auction where (`type`=1 or `type`=2 or `type`=3 ) and flag =1 and cid > 0 order by id desc limit $startIndex, 10 ";
		
		$result = $_SGLOBAL['mgrdb']->query($sql);
		while( $value = $_SGLOBAL['mgrdb']->fetch_array($result))
		{
			//$list['type'] = 1;//$value['type'] == 1 ? "系统拍卖" : "玩家拍卖" ;
			//$list['gname'] = $value['gname'];
			
			
			if(! empty($value['type']) && ($value['type'] =="1" or $value['type']=="2" or $value['type']=="3"))
			{ 
				$optype = $value['type'];
				if($optype=="1")
				{
					$value['type'] = "系统拍卖";
					$value['price'] = $value['gold'];
					$value['color'] = "#FFFFFF";
				}else if ($optype=="2")
				{
					$value['type'] = "活动拍卖";
					$value['price'] = $value['money'];
					$value['color'] = "#0FFF00";
				}else if ($optype=="3")
				{
					$value['type'] = "玩家拍卖";
					$value['price'] = $value['money'];
					$value['color'] = "#FFF000";
				}
				$value['buyer'] = "";
				$value['seller'] = "";
				$value['extime'] = $value['downtime'];
				$list[] = $value;
			}
		}
		
		$clist = "";
		$mod="";
		foreach($list as $v )
		{
			$clist = $clist.$mod.$v['scid'];
			$mod = ",";
			$clist = $clist.$mod.$v['cid'];
			$mod = ",";			
		}
		
		$plist = array();
		if($mod == ",")
		{
			$sql = "select C.id ,A.player from city as C inner join player as A on A.id = C.uid where C.id in(".$clist.") ";
			$result = $_SGLOBAL['mgrdb']->query($sql);
			while($value = $_SGLOBAL['mgrdb']->fetch_array($result))
			{
				$cid = $value['id'];
				if(!isset($plist[$cid]) || empty($plist[$cid])) 
				{
					$plist[$cid] = $value['player'];
				}
			}
		}
		$plist[0] = "系统";
		
		foreach($list as $id => $v)
		{
			if(!empty($plist[ $v['scid']]) ) 
				$list[$id]['seller'] = $plist[$v['scid']];
				
			if(!empty($plist[ $v['cid']]) ) 
				$list[$id]['buyer'] = $plist[$v['cid']];
		}
		
		
		//总页数
		$result = $_SGLOBAL['mgrdb']->query(" select count(1) as count from auction where (`type`=1 or `type`=2 or `type`=3 ) and flag=1 and cid>0 limit 1 ");
		if($value = $_SGLOBAL['mgrdb']->fetch_array($result))
		{
			return array( 'count'=> $value['count'], 'data'=>$list);
		}else
		{
			return array( 'count'=> 0, 'data'=>$list);
		}
		
	}
?>
