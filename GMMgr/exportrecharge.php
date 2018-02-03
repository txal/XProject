<?php 	
	include_once("common.php");
	isaccess("RECHARGE_QUERY") or exit('Access Denied');	
	
	if(isset($_GET['startdatetime'])  &&  isset($_GET['enddatetime']) )
	{

		$filename	="recharge_".date('Y_m_d H:i:s',time()).".txt";
		//header("Content-Type: application/text");
		header("Accept-Ranges: bytes");   
		header("Content-Disposition: attachment; filename=$filename");

		echo getdatatoexport($_GET['startdatetime'],$_GET['enddatetime']);
		
	}else
	{
		echo "<script>alert(\"".convertPageCharset("导出过程中遇到问题,\n").$error."\")</script>";
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

	
	function getdatatoexport($start,$end)
	{	
		global $_SGLOBAL;
		global $_SC;
		global $_SERVER_APP;
		global $G_SERVERID;
		
		$istart	=makeTimeStamp($start);
		$iend	=makeTimeStamp($end);
		
		$sql="
			select * from 
			(
				select count(distinct(B.uid)) as players 
				from player as A inner join recharges as B on A.id=B.uid
				where B.time between $istart and $iend
			)as t1 left join
			(
				select 
					sum(B.money) 			as money,
					format(sum(B.fee),2) 	as fee,
					sum(B.gold) 			as gold,
					sum(B.gold-B.balance) 	as goldconsumed,
					sum(B.balance) 			as goldremained
				from player as A inner join recharges as B on A.id=B.uid
				where B.time between $istart and $iend
			)as t2 on 1=1
		";

		$query	=$_SGLOBAL['mgrdb']->query($sql);

		//输出结果
		$result	="";

		while($value	=$_SGLOBAL['mgrdb']->fetch_array($query))
		{
			$result.="充值统计: \n";
			$result.="开服日期: ".$_SERVER_APP[$G_SERVERID]['serverstartat']."\n";
			$result.="总充值额度: ￥".$value['money']."元    实收金额：￥".($value['money']-$value['fee'])."元    充值手续费: ￥".$value['fee']."元    充值人数: ".$value['players']."人 \n";
			$result.="全服元宝数: ".$value['gold']."元宝    已消费元宝: ".$value['goldconsumed']."元宝    未消费元宝: ".$value['goldconsumed']."元宝\n";
			$result.="开始时间: $start    结束时间: $end \n";
		}
		
		return $result;
		
	}
?>