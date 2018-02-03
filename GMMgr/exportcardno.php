<?php 	
	include_once("common.php");
	isaccess("CARDS") or exit('Access Denied');	
	
	if(isset($_GET['startNO'])  &&  isset($_GET['endNO']) && isset($_GET['cardtype']))
	{
		$filename	="cardno_".date('Y_m_d H:i:s',time()).".txt";
		//header("Content-Type: application/text");
		header("Accept-Ranges: bytes");   
		header("Content-Disposition: attachment; filename=$filename");

		echo getdatatoexport(intval($_GET['cardtype']),intval($_GET['startNO']),intval($_GET['endNO']));
		
	}else
	{
		echo "<script>alert(\"".convertPageCharset("生成卡号过程中遇到问题,\n").$error."\")</script>";
	}

	
	function getdatatoexport($cardtype,$startNO,$endNO)
	{	
		global $_SGLOBAL;
		$where=($cardtype==-1)?"":" type=$cardtype and ";

		$sql="  select id,cardNO,buildtime,username,state,usetime, Ip,type from newcards where $where id between $startNO and $endNO ";
		$query	=$_SGLOBAL['mgrdb']->query($sql);

		//输出结果
		$result	="";
		
		//输出标题
		$result.="编号	卡号	生成时间	使用者	状态	使用时间	试用IP	类型\n";
		
		//卡号类型
		$cardtypelist=getcardtypes();

		while($value	=$_SGLOBAL['mgrdb']->fetch_array($query))
		{
			$value['buildtime']	=date('Y/m/d H:i:s',$value['buildtime']);
			$value['usetime']	=date('Y/m/d H:i:s',$value['usetime']);
			$value['type']		=isset($cardtypelist[$value['type']])?$cardtypelist[$value['type']]:"未知卡型";

			
			$value['state']		=($value['state']==0?"未使用":"使用");
			
			$result.= 
				$value['id']."\t".
				$value['cardNO']."\t".
				$value['buildtime']."\t".
				$value['username']."\t".
				$value['state']."\t".
				$value['usetime']."\t".
				$value['Ip']."\t".
				$value['type']."\n";
		}
		
		return $result;
		
	}
	
	function getcardtypes()
	{
		global $_SGLOBAL;
		$sql=" select id,cardname,isunique from cardtype ";
		$result=$_SGLOBAL['mgrdb']->query($sql);
		
		$list		=array();
		$alllist	=array();
		while($value=$_SGLOBAL['mgrdb']->fetch_array($result))
		{	
			$alllist[$value['id']]	=convertPageCharset($value['cardname']);
		}
		
		return $alllist;
	}
?>