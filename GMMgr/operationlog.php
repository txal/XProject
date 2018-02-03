<?php 
	include_once("common.php");
	isaccess("OPLOG") or exit('Access Denied');	

	include 'useroperationlog.php';
	define('PAGESIZE',10);
	
	//两个模块的联合查询的查询条件记录
	$msg=array();


	//‘后台登录日志’的查询页面号
	$msg[2]=array(
		'page' => (isset($_GET['page2'])?intval($_GET['page2']):1),
		'pagesize' => 10	
	);

	$currentUser = getUserInfo();
	
	//如果是超级管理员，显示‘用户操作日志’页面
	if(isSuper($currentUser['purview']))
	{
		//‘用户操作日志’的查询页面号
		$msg[1]=array(
			'page' => (isset($_GET['page1'])?intval($_GET['page1']):1),
			'pagesize' => 10	
		);	

		//默认为选择所有操作人，标记为-1
		if(!isset($_GET['s_operator']) || isset($_GET['s_operator']) && $_GET['s_operator']=="All")	{
			$msg[1]['selected_operator']=-1;
		}else{
			$msg[1]['selected_operator']=$_GET['s_operator'];
		}

		//默认为选择所有操作类型，标记为-1
		if(!isset($_GET['s_optype']) || isset($_GET['s_optype']) && $_GET['s_optype']=="All")	{
			$msg[1]['selected_optype']=-1;
		}else{
			$msg[1]['selected_optype']=intval($_GET['s_optype']);
		}
		

		//超级管理员才具有 ” 浏览用户操作日志 权限“
		$where =" where adminName is not null and trim(adminName)!='' ";
		$where.=($msg[1]['selected_operator']==-1)?"":" and adminName='".convertDBCharset($msg[1]['selected_operator'])."' ";
		$where.=($msg[1]['selected_optype']  ==-1)?"":" and opCode     =".$msg[1]['selected_optype'];
		$msg[1]['where']=$where;

		$list			=readoperationlog($msg[1]);
		$operatorlist	=readoperators($msg[1]['selected_operator']);
		$optypelist 	=readoptypes($msg[1]['selected_optype']);
		$loglist		=$list['data'];

		$pageblock=" ";
		$url="?page2={$msg[2]['page']}&s_operator={$msg[1]['selected_operator']}&s_optype={$msg[1]['selected_optype']}";
		if($list['recordCount']>$msg[1]['pagesize'])
		{
			$pageblock = (mymulti($list['recordCount'], $msg[1]['pagesize'], $msg[1]['page'], $url,"page1"));		
		}

		include template("useroperationlog");
	}
	
	//后台登陆日志
	include 'loginlog.php';

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
				$multipage .= $i == $curpage ? '<strong>['.$i.']</strong>' :
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