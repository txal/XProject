<?php
	require_once 'common.php';
	require_once './include/gift.inc.php';	

	$giftlist2		=array();
	foreach($gifts as $key=>$value)
	{
		foreach($value as $k=>$v)
			$giftlist2[$v]=convertPageCharset($k);
	}


	//处理修改道具表单
	if(isset($_POST['modify_submit']))
	{
		$cardtypeid	=intval($_POST['cardtypeid']);
		$extdata	=empty($_POST['gifttext'])?"{}":$_POST['gifttext'];

		$error		=savecardtype($cardtypeid,$extdata);
		if(!empty($error))
		{
			echo("<script language=\"javascript\"> alert($error); </script>");
		}

		//echo '<br><br>dfdf   <a href="javascript:window.opener.location = window.opener.location;window.close()">close</a>';
		echo("<script language=\"javascript\"> parent.location.reload(); </script>");
	}

	//处理上层页面操作，用于显示修改页面s
	if(isset($_GET['cardtypeid']) && !empty($_GET['cardtypeid']))
	{
		$cardtypeid	=intval($_GET['cardtypeid']);
		
		//合并所有道具到  $giftlist
		$giftlist		=array();
		foreach($gifts as $key=>$value)
		{
			foreach($value as $k=>$v)
				$giftlist[$v]=($k);
		}
		
				//解析  字符串型道具信息   到数组 $objectlist;
		$sobjectlist=array();
		getinfo($cardtypeid);
		
		include template('modifycardtype');
	}
	
	function getinfo($cardtypeid)
	{
		global $_SGLOBAL;
		$result=$_SGLOBAL['mgrdb']->query(" select id,cardname,extdata from cardtype where id=$cardtypeid ;");
		$extdata="";
		if($value=$_SGLOBAL['mgrdb']->fetch_array($result))
		{
			$extdata= $value['extdata'];	
		}
		
		
		preg_replace('/\[\s*([0-9]*)\s*]\s*=\s*([0-9]*)/e','parseobject("\\1","\\2")',$extdata);
	}
	
	function parseobject($key,$count)
	{
		global $giftlist;
		global $sobjectlist;
		$sobjectlist[]=array(
			'id'		=>$key,
			'cardname'	=>convertPageCharset($giftlist[$key]),
			'count'		=>$count
		);
	}

	function savecardtype($cardtypeid,$extdata)
	{
		global $_SGLOBAL;
		global $_opCodeList;

		//获取删除前道具信息，以便写日志
		$cardinfoold="";
		$cardinfonew="";

		$list	=getcardinfo(" where id=$cardtypeid ");

		if(count($list)>0)
		{
			//解析卡型字符串成  带中文卡型名称的列表$cardinflist
			foreach($list as $key=>$value)
			{
				$list[$key]['extdata']= preg_replace('/\[\s*([0-9]*)\s*]\s*=\s*([0-9]*)/e','parseobject2("\\1","\\2")',$value['extdata']);
			}

			foreach($list[0] as $key=>$value)
			{
				$cardinfoold	=$cardinfoold.(" [$key]=$value ");
			}

			//解析卡型字符串成  带中文卡型名称的列表$cardinflist
			foreach($list as $key=>$value)
			{
				$value['extdata']		=$extdata;
				$list[$key]['extdata']	= preg_replace('/\[\s*([0-9]*)\s*]\s*=\s*([0-9]*)/e','parseobject2("\\1","\\2")',$value['extdata']);
			}
			foreach($list[0] as $key=>$value)
			{
				$cardinfonew	=$cardinfonew.(" [$key]=$value ");
			}
		}

		$result =$_SGLOBAL['mgrdb']->query(" update cardtype set extdata='$extdata' where id=$cardtypeid ;");

		if($result){
			$user=getUserInfo();
			writeAdminLog(array
				(
				'adminId'		=>$user['userid'],
				'adminName'		=>$user['realName'],
				'type'			=>$_opCodeList['EDITCARDTYPE']['code'],
				'ext1'			=>"",
				'ext2'			=>"",
				'remark'		=>$_opCodeList['EDITCARDTYPE']['name']." .<br/> ".convertDBCharset("$cardinfoold 改为 <br/> $cardinfonew"),
				'loginIp'		=>$_SERVER['REMOTE_ADDR'],
				'time'			=>time()
				)
			);

			return "";
		}else{
			return "修改卡型信息失败，".$_SGLOBAL['mgrdb']->error();
		}

	}

	function parseobject2($key,$count)
	{
		global $giftlist2;

		return ($giftlist2[$key])." x $count 个";
	}
		

	function getcardinfo($where=" ")
	{
		global $_SGLOBAL;
		
		$sql=" select id, cardname,isunique as cardtype,extdata from cardtype $where ";
		$result =$_SGLOBAL['mgrdb']->query($sql);
		$list=array();
		while($value=$_SGLOBAL['mgrdb']->fetch_array($result))
		{
			$value['cardname']	=convertPageCharset($value['cardname']);
			$value['cardtype']	=intval($value['cardtype'])==1?"单一卡号":"非单一卡号";
			$list[]=$value;
		}
		
		return $list;
	
	}

?>