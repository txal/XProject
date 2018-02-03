<?php
	require_once 'common.php';
	require_once './include/gift.inc.php';	
	
	isaccess("VIEWPROPINFO") or exit('Access Denied');
	header("content-type:text/html;charset=$_SC['charset']");

	$g_name = "";
	$g_date = "";
	$g_index = 1;
	$g_ptype = 1 ;	
	$g_multi = "";
	$perpage = 50 ;
	
	$result = getPropInfoList();
	$propInfoList = array();
	
	if( isset($result) && $result['length'] >0 )
	{
		$propInfoList = $result['data'];
		
		//$multi = multi($amount,$perpage, $g_index, 'ddd=9');
		$url = "?n_player=$g_name&n_date=$g_date&n_ptype=$g_ptype";
		$g_multi = mymulti($result['recordamount'], $perpage, $g_index, $url,'n_index');		
	}	
	
	
	include template('propickinfo');
	
	//++++++++++++++++++++++++++++++++++++++++++
	function getPropInfoList()
	{
		//$result = Parser::Parse($_POST, "n_player");
		//$g_name = isset($result['n_player']) or null;
		//$g_date = isset($result['n_date']) or null;
		//$g_index = isset($result['n_index']) or 1;
		
		global $g_name;
		global $g_date;
		global $g_index;
		global $g_ptype;
		global $_SGLOBAL;
		global $perpage;
		if(isset($_POST) && isset($_POST['n_submit']))
		{
		
			$g_name = strval($_POST['n_player']);
			$g_date = strval($_POST['n_date']);
			$g_index = intval($_POST['n_index']);
			$g_ptype = intval($_POST['n_ptype']);
		}elseif(isset($_GET) && isset($_GET['n_index']))
		{
			$g_name = strval($_GET['n_player']);
			$g_date = strval($_GET['n_date']);
			$g_index = intval($_GET['n_index']);
			$g_ptype = intval($_GET['n_ptype']);		
		}
		
		
			
		if(strlen($g_name) < 1 )
			return null;

		$uid = null;
		$sql = " select id from player where `player` = '$g_name'  limit 1 " ;
		$result = $_SGLOBAL['mgrdb']->query($sql);
		if($value = $_SGLOBAL['mgrdb']->fetch_array($result))
			$uid = intval($value['id']);

		if( !isset($uid) )
			return null;
			
		
		switch( $g_ptype)
		{
			case 1 : //武将
				return getFighterDetail($g_name, $g_date, $g_index, $uid, $perpage);
			case 2 : //装呗
				return getArmDetail($g_name, $g_date, $g_index, $uid, $perpage);
			case 3 : //道具
				return getPropDetail($g_name, $g_date, $g_index, $uid, $perpage);
		}
	}
	
	function getPropDetail($g_name, $g_date, $g_index, $uid, $perpage)
	{
		global $_SGLOBAL;		
		global $gifts ;
		
		$giftlist		=array();
		foreach($gifts as $key=>$value)
		{
			foreach($value as $k=>$v)
				$giftlist[$v]=($k);
		}
		
		$limit = max(0, $g_index -1) * $perpage;
		$sql = " select gid from prop where uid= $uid order by id desc limit $limit, $perpage ";
		$result = $_SGLOBAL['mgrdb']->query($sql);
		
		$length = 0 ;
		$resultlist = array();
		while($value = $_SGLOBAL['mgrdb']->fetch_array($result))
		{
			$gid = intval($value['gid']);
			$length = $length +  1;
			$prop = isset($giftlist[$gid]) ? $giftlist[$gid] : "未定义";
			$resultlist[] = array("player"=>$g_name, "prop"=> $prop, "gettime"=>"--");
		}
		
		
		$result = $_SGLOBAL['mgrdb']->query(" select count(1) as amount from prop where uid = $uid ") ;
		$amount = 0 ;
		if($value = $_SGLOBAL['mgrdb']->fetch_array($result))
		{
			$amount = intval($value['amount']);
		}
		
		return array("length"=>$length, "data"=> $resultlist, "recordamount"=>$amount);
	}
	
	function getArmDetail($g_name, $g_date, $g_index, $uid, $perpage)
	{
		global $_SGLOBAL;		
		global $gifts ;
		
		$giftlist		=array();
		foreach($gifts as $key=>$value)
		{
			foreach($value as $k=>$v)
				$giftlist[$v]=($k);
		}
	
		$limit = max(0, $g_index -1) * $perpage;
		$sql = " select gid from arm where sid = $uid order by id desc limit $limit, $perpage ";
		$result = $_SGLOBAL['mgrdb']->query($sql);
		
		$length = 0 ;
		$resultlist = array();
		
		while($value = $_SGLOBAL['mgrdb']->fetch_array($result))
		{

			$gid = $value['gid'];
			$colorIndex = (floor($gid/100000) % 10);
			$color = getColorByIndex($colorIndex);
			if($color['index'] >= 4 )
			{
				$length = $length +  1;
				$prop = $color['str']. $giftlist[$gid]. "</font>";
				$resultlist[] = array("player"=>$g_name, "prop"=> $prop, "gettime"=>"--");
			}
		}
		
		$result = $_SGLOBAL['mgrdb']->query(" select count(1) as amount from arm where sid = $uid ") ;
		$amount = 0 ;
		if($value = $_SGLOBAL['mgrdb']->fetch_array($result))
		{
			$amount = intval($value['amount']);
		}
			
		return array("length"=>$length, "data"=> $resultlist, "recordamount"=>$amount);
	}
	
	function getFighterDetail($g_name, $g_date, $g_index, $uid, $perpage)
	{
		global $_SGLOBAL;
		
		$limit = max(0, $g_index -1) * $perpage;
		$citylist = null;
		$sql = " select id from city where uid = $uid ";
		$result = $_SGLOBAL['mgrdb']->query($sql);
		while($value = $_SGLOBAL['mgrdb']->fetch_array($result))
		{
			if( !isset($citylist))
				$citylist = array();
			
			$citylist[] = intval($value['id']);
		}
		
		if( !isset($citylist))
			return null;
			
		
		$strlist = "";
		$mod = " ";
	
		foreach($citylist as $city)
		{
			$strlist = $strlist . $mod . strval($city);
			$mod = " , " ;
		}
		if(strlen($strlist) <1 )
			return null;
		
		
		$sql = " select name, gengu, lastTime from fighter where cid in ( ". $strlist . " )  " ;
		
		if(strlen($g_date)>0)
		{
			$wantDate = strtotime($g_date);
			$sql = $sql . " and `lastTime` >= $wantDate and `lastTime` <= ". ($wantDate+ 24*3600);
		}
		$sql = $sql . " order by lastTime desc limit $limit, $perpage ";
		$result = $_SGLOBAL['mgrdb']->query($sql);
		
		$resultlist = array();
		$length = 0 ;
		while($value = $_SGLOBAL['mgrdb']->fetch_array($result))
		{
		
			$gengu = intval($value['gengu']);
			$talent = ( $gengu & 0xFF);
			$color = getColor($talent);
			
			if($color['index'] >= 4) //4粉   5红
			{
				
				$lasttime = $value['lastTime'];
				$gettime = date('Y-m-d H:i:s', $lasttime);
				$prop = $color['str'] . $value['name'] . "</font>";
				$resultlist[] = array("player"=> $g_name, "prop"=>$prop, "grade"=>$color['str'], "gettime"=>$gettime);
				$length = $length + 1;
			}
		}
		
		$result = $_SGLOBAL['mgrdb']->query(" select count(1) as amount from fighter where cid in ( ". $strlist . " ) ") ;
		$amount = 0 ;
		if($value = $_SGLOBAL['mgrdb']->fetch_array($result))
		{
			$amount = intval($value['amount']);
		}

		
		return array("length"=>$length, "data"=> $resultlist, "recordamount"=>$amount);
	}
	
	function getColor($talent)
	{
		if($talent<45 ) //柏
			return array('index'=>1, 'str'=>"<font color='#948e8c'>");
		elseif ($talent<60 )
			return array('index'=>2, 'str'=>"<font color='#00ff08'>");      //绿
		elseif ($talent<75 )
			return array('index'=>3, 'str'=>"<font color='#006cff'>");     //栏
		elseif ($talent<90 )
			return array('index'=>4, 'str'=>"<font color='#ff59ff'>");	  //字/分
		else
			return array('index'=>5, 'str'=>"<font color='#fe0808'>");   //宏
	}
	
	function getColorByIndex($index)
	{
		if($index==1 ) //柏
			return array('index'=>1, 'str'=>"<font color='#948e8c'>");
		elseif ($index ==2 )
			return array('index'=>2, 'str'=>"<font color='#00ff08'>");      //绿
		elseif ($index == 3 )
			return array('index'=>3, 'str'=>"<font color='#006cff'>");     //栏
		elseif ($index == 4 )
			return array('index'=>4, 'str'=>"<font color='#ff59ff'>");	  //字/分
		else
			return array('index'=>5, 'str'=>"<font color='#fe0808'>");   //宏
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
					'<a href="'.$mpurl.$pname.'='.$i.'">'.$i.'</a>';
			}
			$multipage .= ($curpage < $pages ? '<a href="'.$mpurl.$pname.'='.($curpage + 1).'">&rsaquo;&rsaquo;</a>' : '').
				($to < $pages ? '<a href="'.$mpurl.$pname.'='.$pages.'">... '.$realpages.'</a>' : '');
			$multipage = $multipage ? ('<span>&nbsp;共'.$num.'条记录&nbsp;</span>'.$multipage):'';
		}
		$maxpage = $realpages;
		
		return $multipage;
	}	
	
	
	class Parser{
		public static function Parse($source, $format)
		{
			
			$data = array();
			$length = 0 ;
			$types = explode("|", $format);

			foreach($types as $k=> $key)
			{
				if(!empty($source) && isset($source[$key]))
				{
					$data[$key] = $source[$key];
				}else{
					$data[$key] = null;
				}
			}
			
			return $data;
		}
	}

?>