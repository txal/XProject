<?php 
	include_once("common.php");
	isaccess("PROPCONSM") or exit('Access Denied');
	
	require_once './include/gift.inc.php';	
	require_once './include/modulecode.inc.php';

	
	$giftlist		=array();
	foreach($gifts as $key=>$value)
	{
		foreach($value as $k=>$v)
			$giftlist[$v]=($k);
	}
	
	$msg=array();
	
	//道具消费情况
	$proplist=array();
	$msg[1]=array(
		'page'			=>(isset($_REQUEST['page_1']) && !empty($_REQUEST['page_1']))?$_REQUEST['page_1']:1,
		'pagesize'		=>10,
		'pageblock'		=>""
	);

	
	//按日期查询
	$proplistdaily=array();
	$msg[2]=array(
		'startdatetime'	=>(isset($_REQUEST['startdatetime2']) && !empty($_REQUEST['startdatetime2']))?makeTimeStamp($_REQUEST['startdatetime2']):"",
		'enddatetime'	=>(isset($_REQUEST['enddatetime2']) && !empty($_REQUEST['enddatetime2']))?makeTimeStamp($_REQUEST['enddatetime2']):"",
		'start'			=>(isset($_REQUEST['startdatetime2']) && !empty($_REQUEST['startdatetime2']))?($_REQUEST['startdatetime2']):"",
		'end'			=>(isset($_REQUEST['enddatetime2']) && !empty($_REQUEST['enddatetime2']))?($_REQUEST['enddatetime2']):"",
		'page'			=>(isset($_REQUEST['page_2']) && !empty($_REQUEST['page_2']))?$_REQUEST['page_2']:1,
		'pagesize'		=>10,
		'pageblock'		=>""
	);	
	
	//按日期查询道具来源
	$propsourcedaily=array();
	$msg[3]=array(
		'startdatetime'	=>(isset($_REQUEST['startdatetime3']) && !empty($_REQUEST['startdatetime3']))?makeTimeStamp($_REQUEST['startdatetime3']):"",
		'enddatetime'	=>(isset($_REQUEST['enddatetime3']) && !empty($_REQUEST['enddatetime3']))?makeTimeStamp($_REQUEST['enddatetime3']):"",
		'start'			=>(isset($_REQUEST['startdatetime3']) && !empty($_REQUEST['startdatetime3']))?($_REQUEST['startdatetime3']):"",
		'end'			=>(isset($_REQUEST['enddatetime3']) && !empty($_REQUEST['enddatetime3']))?($_REQUEST['enddatetime3']):"",
		'way'			=>(isset($_REQUEST['way']) && !empty($_REQUEST['way']))?intval($_REQUEST['way']):-1,
		'page'			=>(isset($_REQUEST['page_3']) && !empty($_REQUEST['page_3']))?$_REQUEST['page_3']:1,
		'pagesize'		=>10,
		'pageblock'		=>""
	);	
	
	//使用  道具消费情况
	{	
		$list=getproplist($msg[1]);
		$proplist=$list['data'];
		$recordCount	=$list['recordCount'];
		
		if($list['recordCount']>$msg[1]['pagesize'])
		{
			$url="?startdatetime2={$msg[2]['startdatetime']}".
				"&enddatetime2={$msg[2]['enddatetime']}".
				"&startdatetime3={$msg[3]['startdatetime']}".
				"&enddatetime3={$msg[3]['enddatetime']}".
				"&page_2={$msg[2]['page']}".
				"&page_3={$msg[3]['page']}";
				
			$pageblock=(mymulti($recordCount, $msg[1]['pagesize'], $msg[1]['page'],$url,'page_1'));
			$msg[1]['pageblock']=$pageblock;
		}
	}
	
	//按日期进行 筛选查询
	//if(!empty($msg[2]['startdatetime']))
	{
		$list			=getproplistdaily($msg[2]);
		$proplistdaily	=$list['data'];
		$recordCount	=$list['recordCount'];
		if($list['recordCount']>$msg[2]['pagesize'])
		{
			$url="?startdatetime2={$msg[2]['startdatetime']}".
				"&enddatetime2={$msg[2]['enddatetime']}".
				"&startdatetime3={$msg[3]['startdatetime']}".
				"&enddatetime3={$msg[3]['enddatetime']}".
				"&page_1={$msg[1]['page']}".
				"&page_3={$msg[3]['page']}";
				
			$pageblock=(mymulti($recordCount, $msg[2]['pagesize'], $msg[2]['page'],$url,'page_2'));
			$msg[2]['pageblock']=$pageblock;
		}
	}
	
	//查询道具来源查询
	//if(!empty($msg[3]['startdatetime']))
	{
		$list				=getpropsourcedaily($msg[3]);
		$propsourcedaily	=$list['data'];
		$recordCount		=$list['recordCount'];

		if($list['recordCount']>$msg[3]['pagesize'])
		{
			$url="?startdatetime2={$msg[2]['startdatetime']}".
				"&enddatetime2={$msg[2]['enddatetime']}".
				"&startdatetime3={$msg[3]['startdatetime']}".
				"&enddatetime3={$msg[3]['enddatetime']}".
				"&page_2={$msg[2]['page']}".
				"&page_1={$msg[1]['page']}";

			$pageblock=(mymulti($recordCount, $msg[3]['pagesize'], $msg[3]['page'],$url,'page_3'));					
			$msg[3]['pageblock']=$pageblock;
		}
	}
	

	
	include template("propconsumption");
	
	function getproplist($param)
	{
	
		global $_SGLOBAL;
		global $giftlist;
		
		$start=($param['page']-1)*$param['pagesize'];
		$sql="
			select goodname,
				sum(num) as total,
				max(case when way=3 then num else 0 end) as gold,
				max(case when way=4 then num else 0 end) as gift
				
			from
			(
				select gid as goodname,way,sum(count) as num
				from proprecord
				group by gid,way
			)as t
			group by goodname
			order by total desc
			limit $start,{$param['pagesize']}
		";
	
		$data=array();
		$query=$_SGLOBAL['mgrdb']->query($sql);
		while($value=$_SGLOBAL['mgrdb']->fetch_array($query))
		{
			if ( !empty($giftlist[intval($value['goodname'])]  ))
			{
				$value['goodname']	=convertPageCharset($giftlist[intval($value['goodname'])]);
				$data[]=$value;
			}
		}
		
		$sql="
			select count(1) as recordCount 
			from(
				select 1 
				from proprecord
				group by gid
			)as t
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
	
	function getproplistdaily($param)
	{
		global $_SGLOBAL;
		global $giftlist;
		//充值1, GM赠送2，礼券购买3，元宝购买4, 打怪5， 开宝箱6
		$now			=time();
		$start			=($param['page']-1)*$param['pagesize'];
		$startdatetime	=$param['startdatetime'];
		$enddatetime	=$param['enddatetime'];
		$where			="";
		
		if(!empty($startdatetime)  && !empty($enddatetime))
		{
			$where=" where time between $startdatetime and $enddatetime ";
		}else if(!empty($startdatetime))
		{
			$where=" where time>=$startdatetime ";
		}else if(!empty($enddatetime))
		{
			$where=" where time<=$enddatetime ";
		}else 
		{
			$where=" ";
		}
		
		$sql="
			select goodname,
				sum(num) as total,
				max(case when way=3 then num else 0 end) as gold,
				max(case when way=4 then num else 0 end) as gift,
				ceil(($now-max(ttime))/86400) as dday
			from
			(
				select gid as goodname,way,sum(count) as num,max(time) as ttime
				from proprecord
				$where
				group by gid,way
			
			)as t
			group by goodname
			order by total desc
			limit $start,{$param['pagesize']}
		";
		
		$data=array();
		$query=$_SGLOBAL['mgrdb']->query($sql);
		while($value=$_SGLOBAL['mgrdb']->fetch_array($query))
		{
			if ( !empty($giftlist[intval($value['goodname'])]  ))
			{
				$value['goodname']	=convertPageCharset($giftlist[intval($value['goodname'])]);
				$data[]=$value;
			}
		}
		
		$sql="
			select count(1) as recordCount 
			from(
				select 1 
				from proprecord
				$where
				group by gid
			)as t
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
	
	function getpropsourcedaily($param)
	{
		global $_SGLOBAL;
		global $giftlist;
		global $propdefinition;
		
		$propsource=array();
		foreach($propdefinition as $key=>$value)
		{
			$propsource[$value['code']]=$value['name'];
		}
	
		//充值1, GM赠送2，礼券购买3，元宝购买4, 打怪5， 开宝箱6
		$now			=time();
		$start			=($param['page']-1)*$param['pagesize'];
		$startdatetime	=$param['startdatetime'];
		$enddatetime	=$param['enddatetime'];
		$way			=intval($param['way']);
		$where			="";
		$mod			=" where ";
		
		//动态日期筛选
		if(!empty($startdatetime)  && !empty($enddatetime))
		{
			$where	=$mod." time between $startdatetime and $enddatetime ";
			$mod	=" and ";
		}else if(!empty($startdatetime))
		{
			$where=$mod." time>=$startdatetime ";
			$mod	=" and ";
		}else if(!empty($enddatetime))
		{
			$where=$mod." time<=$enddatetime ";
			$mod	=" and ";
		}else 
		{
			$where=" ";
		}
		
		//道具来源
		if($way!=-1)
		{
			$where=$mod." way=$way ";
		}
		
		$sql="
				select gid as goodname,way,sum(count) as total,ceil(($now-max(time))/86400) as dday
				from proprecord
				$where
				group by gid,way
				limit $start,{$param['pagesize']}
		";
		
		$data=array();
		$query=$_SGLOBAL['mgrdb']->query($sql);
		while($value=$_SGLOBAL['mgrdb']->fetch_array($query))
		{
			$value['goodname']	=convertPageCharset($giftlist[intval($value['goodname'])]);
			$value['way']		=convertPageCharset($propsource[$value['way']]);
			$data[]=$value;
		}
		
		$sql="
			select count(1) as recordCount 
			from(
				select 1 
				from proprecord
				$where
				group by gid,way
			)as t
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
	
	function makeTimeStamp($strtime) {
	
		$array = explode("-",$strtime);
		$year = $array[0];
		$month = $array[1];
		
		$array = explode(":",$array[2]);
		$minute = $array[1];
		$second = $array[2];
		
		$array = explode(" ",$array[0]);
		$day = $array[0];
		$hour = $array[1];
		
		return mktime($hour,$minute,$second,$month,$day,$year);
	}	
	
		
	function mymulti($num, $perpage, $curpage, $mpurl,$pname) {
		global $_SCONFIG;
		$page = 5;
		$multipage = '';
		$mpurl .= strpos($mpurl, '?') !== FALSE ? '&' : '?';
		$realpages = 1;
		if($num > $perpage) {
			$offset = 2;
			$realpages = ceil($num / $perpage);
			$pages = isset($_SCONFIG['maxpage']) && $_SCONFIG['maxpage'] < $realpages ? $_SCONFIG['maxpage'] : $realpages;
			if($page > $pages) {
				$from = 1;
				$to = $pages;
			} else {
				$from = $curpage - $offset;
				$to = $from + $page - 1;
				if($from < 1) {
					$to = $curpage + 1 - $from;
					$from = 1;
					if($to - $from < $page) {
						$to = $page;
					}
				} elseif($to > $pages) {
					$from = $pages - $page + 1;
					$to = $pages;
				}
			}
			$multipage = ($curpage - $offset > 1 && $pages > $page ? '<a href="'.$mpurl.$pname.'=1">1 ...</a>' : '').
				($curpage > 1 ? '<a href="'.$mpurl.$pname.'='.($curpage - 1).'">&lsaquo;&lsaquo;</a>' : '');
			for($i = $from; $i <= $to; $i++) {
				$multipage .= $i == $curpage ? '<strong>'.$i.'</strong>' :
					'<a href="'.$mpurl.$pname.'='.$i.'">['.$i.']</a>';
			}
			$multipage .= ($curpage < $pages ? '<a href="'.$mpurl.$pname.'='.($curpage + 1).'">&rsaquo;&rsaquo;</a>' : '').
				($to < $pages ? '<a href="'.$mpurl.$pname.'='.$pages.'">... '.$realpages.'</a>' : '');
			$multipage = $multipage ? ('<span>&nbsp;共'.$num.'条记录&nbsp;</span>'.$multipage):'';
		}
		$maxpage = $realpages;
		
		return $multipage;
	}	
	
?>