<?php
	require_once 'common.php';
	
	isaccess("BASICDATA") or isaccess("AUCTIONSHIFT") or isaccess("CARDS") or isaccess('RECHARGEGIFT') or exit('Access Denied');

	include './include/gift.inc.php';	

	foreach($gift_sorts as $key =>$value)
	{
		$gift_sorts[$key]=convertPageCharset($value);
	}

	foreach($gifts as $key =>$subgift)
	{
		$subgift=array_flip($subgift);
		foreach($subgift as $k=>$v)
		{
			$subgift[$k]=convertPageCharset($v);
		}

		$subgift=array_flip($subgift);
		$gifts[$key]=$subgift;
	}


	if( !empty($_GET['auction'])){
		include template('auctioncardgift');
	}elseif( isset($_GET['recharge']) && !empty($_GET['recharge'])){	
		$parent = $_GET['pnt'];
		$itemvalue = str_replace(",","_",$_GET['iv']);
		$token = explode("_", $itemvalue);
		$ilist = array();
		foreach($token as $t)
		{
			$kv = explode("=", $t);
			if($kv && isset($kv[1]))
				$ilist[$kv[0]] = $kv[1];
		}

		include template('cardgiftmpl');
	}elseif( isset($_GET['searchAjax'])){
	
		$itemname = $_GET['searchAjax'];

		if( isset($_GET['toch']) ){
			$itemname = convertPageCharset($itemname);
		}
		$tid = -1;
		$sid = -2;
		foreach($gifts as $key => $sub)
		{
			if( array_key_exists($itemname, $sub))
			{
				$tid = $key;
				$sid = $sub[$itemname];
				break;
			}
		}
		
		echo "$tid,$sid";
	}else{	
		include template('cardgift');
	}
?>