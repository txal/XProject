<?php 
	include_once("common.php");
	isaccess("CONSUMECD") or exit('Access Denied');		
		
	$pindex = 1 ;
	if( isset($_GET) && isset($_GET['page']))
		$pindex = intval($_GET['page']);
		

	if ( !empty($_GET['export']) && $_GET['export'] == 'csv' ) {

		$sql = "select P.player, A.id, A.uid, A.`type`, case when A.currency = 1 then concat(A.`count`, '') else concat(A.`count`, '') end as CT, from_unixtime(A.`time`) as ttime, A.etr from consume as A, player as P where A.uid = P.id order by A.id desc ";
		$result	=$_SGLOBAL['mgrdb']->query($sql);
		$line = '';

		$fileName = "./data/temp/consumeCD-". date("Y-m-d", time(0)) ."-". rand(100, 999). ".csv";
		if ( file_exists($fileName) ) 
			unlink( $fileName );

		$fp = fopen($fileName, "w");
		$title = "用户名,消耗物品数量,CD类型,CD时间消去数,操作时间\n";
		$title = convertDBCharset($title);
		fputs($fp, $title);

	
		while($value = $_SGLOBAL['mgrdb']->fetch_array($result))
		{
			$etr = $value['etr'];
			switch($value['type'])
			{
				case 1: $value['type'] = "移城冷却"; 		$value['etr'] = sprintf("%02d:%02d:%02d", $etr/3600, ($etr%3600 )/60, $etr %60); break;
				case 2: $value['type'] = "建筑冷却"; 		$value['etr'] = sprintf("%02d:%02d:%02d", $etr/3600, ($etr%3600 )/60, $etr %60); break;
				case 3: $value['type'] = "科技冷却"; 		$value['etr'] = sprintf("%02d:%02d:%02d", $etr/3600, ($etr%3600 )/60, $etr %60); break;
				case 4: $value['type'] = "城防工事"; 		$value['etr'] = sprintf("%02d:%02d:%02d", $etr/3600, ($etr%3600 )/60, $etr %60); break;
				case 5: $value['type'] = "休整时间CD";  	$value['etr'] = sprintf("%02d:%02d:%02d", $etr/3600, ($etr%3600 )/60, $etr %60); break;
				case 6: $value['type'] = "增加副本挑战次数"; 	$value['etr'] = convertDBCharset("1次"); break;
				case 7: $value['type'] = "增加天塔挑战次数";  	$value['etr'] = convertDBCharset("1次"); break;
				case 8: $value['type'] = "增加御城战次数";  	$value['etr'] = convertDBCharset("1次"); break;
			}
			
			
			
			
			$sno = $value['id'];
			$data[$sno] = $value;
			$mod = ",";

			//$value['player'] 	= convertPageCharset($value['player']);
			//$value['currency'] 	= convertPageCharset($value['currency']);
			$value['type'] 		= convertDBCharset($value['type']);
			
			$line = $value['player'] . "," . $value['CT'] . "," .  $value['type'] .",". $value['etr'] .",". $value['ttime'] . "\n";		
			//$line = convertPageCharset($line);
			fputs($fp, $line);
		}		

		fclose($fp);
		echo ("Export OK！<a href='$fileName'> Download </a>");
		exit;		
	
	}		
		
	$psize = 20;
	$result = getConsumeCD($pindex, $psize);
	$datalist = $result['data']; 
	
	$pageblock = "";
	if($result['amount'] > 0 )
		$pageblock = multi($result['amount'], $psize, $pindex, 'consumeCD.php');	
	$pageblock = convertPageCharset($pageblock);
	
	include template("consumeCD");
	
	//++++++++++++++++++++ the functions 
	
	function getConsumeCd($pindex, $psize)
	{
		global $_SGLOBAL;
		
		$data = array();
		$start = max(0, $pindex-1) * $psize;
		$sql = "select id, uid, `type`, currency, `count`, from_unixtime(`time`) as ttime, etr from consume order by id desc limit $start, $psize";
		$rset = $_SGLOBAL['mgrdb']->query($sql);
		
		$plist = "";
		$mod = "";
		while($value = $_SGLOBAL['mgrdb']->fetch_array($rset))
		{
			$uid = $value['uid'];
			
			$currency = $value['currency'];
			
			if($currency == 1 )
				$value['currency'] = $value['count'] . "个元宝";
			else
				$value['currency'] = "<B><font color='red'>". $value['count'] ." 个礼券</font>";
			
			$etr = $value['etr'];
			switch($value['type'])
			{
				case 1: $value['type'] = "移城冷却"; 										$value['etr'] = sprintf("%02d:%02d:%02d", $etr/3600, ($etr%3600 )/60, $etr %60); break;
				case 2: $value['type'] = "<B><font color='blue'>建筑冷却</font></B>"; 		$value['etr'] = sprintf("%02d:%02d:%02d", $etr/3600, ($etr%3600 )/60, $etr %60); break;
				case 3: $value['type'] = "<B><font color='#00ff00'>科技冷却</font></B>"; 	$value['etr'] = sprintf("%02d:%02d:%02d", $etr/3600, ($etr%3600 )/60, $etr %60); break;
				case 4: $value['type'] = "<B><font color='#cccccc'>城防工事</font></B>"; 	$value['etr'] = sprintf("%02d:%02d:%02d", $etr/3600, ($etr%3600 )/60, $etr %60); break;
				case 5: $value['type'] = "<B><font color='#cc00cc'>休整时间CD</font></B>";	$value['etr'] = sprintf("%02d:%02d:%02d", $etr/3600, ($etr%3600 )/60, $etr %60); break;
				case 6: $value['type'] = "增加副本挑战次数"; 	$value['etr'] = ("1次"); break;
				case 7: $value['type'] = "增加天塔挑战次数";  	$value['etr'] = ("1次"); break;
				case 8: $value['type'] = "增加御城战次数";  	$value['etr'] = ("1次"); break;
				
			}
			
			$sno = $value['id'];
			$data[$sno] = $value;
			$plist = $plist . $mod . $uid;
			$mod = ",";
		}
		
		$sql = " select id as uid, player from player where id in(" . $plist . ") " ;
		$rset = $_SGLOBAL['mgrdb']->query($sql);
		$tlist = array();
		while($value = $_SGLOBAL['mgrdb']->fetch_array($rset))
		{
			$uid = $value['uid'];
			$tlist[$uid] = $value['player'];
		}
		
		foreach($data as $k=>$d)
		{
			$d['player'] = convertPageCharset($tlist[$d['uid']]);
			$data[$k] = $d;
		}
		
		$amount = 0 ;
		$rset = $_SGLOBAL['mgrdb']->query(" select count(1) as amount from consume ");
		if($value = $_SGLOBAL['mgrdb']->fetch_array($rset))
			$amount = intval($value['amount']);
			
		return array('amount'=>$amount, 'data'=>$data);
	}

?>