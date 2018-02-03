<?php 
	include_once("common.php");
	isaccess("CARDS") or exit('Access Denied');
		
	//按照权限显示不用的导航标签
	isaccess("GENCARDNO")	&&  $memulist[]=array('href'=>'newcards.php?tabindex=1'	,	'hreftext'=>'&nbsp;卡号生成&nbsp;|');
								$memulist[]=array('href'=>'newcards.php?tabindex=2'	,	'hreftext'=>'&nbsp;新手卡列表&nbsp;|');
								$memulist[]=array('href'=>'newcards.php?tabindex=3'	,	'hreftext'=>'&nbsp;公会卡列表&nbsp;|');
	isaccess("ADDCARDTYPE")	&&  $memulist[]=array('href'=>'newcards.php?tabindex=4'	,	'hreftext'=>'&nbsp;卡型创建&nbsp;');

	//顶部导航
	include template("newcards");
	
	define('PAGESIZE',20);

	
	$newcardlist=array();
	$param=array();

	//查询页面号
	$page = !empty($_GET['page']) && intval($_GET['page']) > 0 ? intval($_GET['page']) : 1;	

	//页面大小
	$param['pagesize']	=PAGESIZE;
	
	//查询限制条件
	$param['where']		=" type=2 ";

	
	//预设卡号值
	$cardNO=isset($_COOKIE['associationcards_cardNO'])?$_COOKIE['associationcards_cardNO']:"";
	
	//预设用户名
	$username=isset($_COOKIE['associationcards_username'])?$_COOKIE['associationcards_username']:"";
	
	//处理”查询“表单
	if(isset($_POST['cardNOsubmit']))//卡号搜索
	{
		$page=1;
		if(isset($_POST['cardNO'])	)
		{		
			setcookie("associationcards_cardNO",trim($_POST['cardNO']));				
			$cardNO=trim($_POST['cardNO']);
			$username="";
			setcookie("associationcards_username","",-3600);
		}
	}elseif(isset($_POST['usernamesubmit']))//用户名搜索
	{
		$page=1;
		if(isset($_POST['username']))
		{
			setcookie("associationcards_username",trim($_POST['username']));			
			$username=trim($_POST['username']);
			$cardNO="";
			setcookie("associationcards_cardNO","",-3600);

		}	
	}else//所有记录
	{
		
	}

	$param['page']	=$page;
	$param['where'].=(empty($cardNO)?"":" and cardNO='".$cardNO."'");
	$param['where'].=(empty($username)?"":" and username='".$username."'");		

	$list=readnewcardlist($param);
	$newcardlist=$list['data'];
	
	$pageblock="";
	if($list['recordcount']>PAGESIZE)
		$pageblock = convertPageCharset(multi($list['recordcount'], PAGESIZE, $page, ''));
	
	
	include template("associationlist");
	
	function readnewcardlist($param)
	{
		global  $_SGLOBAL;
		
		$where =" ";
		if(isset($param['where']))
		{
			$where =(empty($param['where']))?" ":" where ".$param['where'];
		}
		
		$limit=" ";
		if(isset($param['page']) && isset($param['pagesize']))
		{
			$limit	=((empty($param['page']) || empty($param['pagesize']) )?" ":" limit ".($param['page']-1)*$param['pagesize']." , ".$param['pagesize']);
		}
	
		//获取选定页面记录
		$page=1;
		$start		=($page-1)*$param['pagesize'];
		
		$sql="  select id,cardNO,buildtime,username,state,usetime, Ip,type from newcards $where $limit";

		$query	=$_SGLOBAL['mgrdb']->query($sql);
		$list	=array();
		while($value	=$_SGLOBAL['mgrdb']->fetch_array($query))
		{
			$value['buildtime']	=date('Y/m/d H:i',$value['buildtime']);
			$value['usetime']	=date('Y/m/d H:i',$value['usetime']);
			$value['type']		=("公会卡");
			$value['state']		=($value['state']==0?"未使用":"使用");
			$list[]=$value;
		}
		
		//总页数
		$query	=$_SGLOBAL['mgrdb']->query(" select count(1) as recordCount from newcards $where" );
		$value	=$_SGLOBAL['mgrdb']->fetch_array($query);
		
		return array(
			'data'			=>$list,
			'recordcount'	=>$value['recordCount']
		);
	}
?>