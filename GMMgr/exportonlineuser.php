<?php 	
	include_once("common.php");
	isaccess("ONLINE") or exit('Access Denied');	
	
	if(isset($_GET['monthstart'])  &&  isset($_GET['monthend']) )
	{

		$filename	="onlineusermonthly_".intval((intval($_GET['monthstart'])/100)).".xls";
		//header("Content-Type: application/text");
		header("Accept-Ranges: bytes");   
		header("Content-Disposition: attachment; filename=$filename");

		echo getdatamonthly($_GET['monthstart'],$_GET['monthend']);
		
	}else
	{
		echo "<script>alert(\"".convertPageCharset("导出过程中遇到问题,\n").$error."\")</script>";
	}
	

	function getdatamonthly($monthstart,$monthend)
	{
		global $_SGLOBAL;
		global $_SC;
					
		$CLIENT_MULTI_RESULTS=131072;
		
		$list=array();
		$con=mysql_connect($_SC['dbhost'], $_SC['dbuser'], $_SC['dbpwd'], 0,$CLIENT_MULTI_RESULTS);
		mysql_select_db($_SC['dbname'],$con);
		
		$result	="在线用户统计：  $monthstart - $monthend \n";
		$result.="日期\t1\t2\t3\t4\t5\t6\t7\t8\t9\t10\t11\t12\t13\t14\t15\t16\t17\t18\t19\t20\t21\t22\t23\t24\n";
		
		$sql=" select t1.ddate,t2.* from( select $monthstart as ddate ";
		for($date=$monthstart+1;$date<=$monthend;++$date)
		{
			$sql	=$sql." union all select $date as ddate ";
		}
		
		$sql	=$sql."
			)as t1 left join
			(
				SELECT * from onlinehourly where onlineDate between $monthstart and $monthend 
			)as t2 on t2.onlineDate=t1.ddate
			order by t1.ddate DESC
		";
		
		$query = $_SGLOBAL['mgrdb']->query($sql);
		while($value=$_SGLOBAL['mgrdb']->fetch_array($query))
		{
			$result	=$result.$value['ddate']."\t";
			for($i=1;$i<=24;++$i)
			{
				$result	=$result.(empty($value['hour'.$i])?"0":$value['hour'.$i])."\t";
			}
			$result.="\n";
		}

		return $result;
		
	}
?>