<?php 
	require_once 'common.php';
	isaccess("CARDS") or exit('Access Denied');	
	
	//道具详细信息列表
	require_once './include/gift.inc.php';	
	require_once './include/modulecode.inc.php';

	$serverlist		=$_SERVERLIST;

	//按照权限显示不用的导航标签
	isaccess("GENCARDNO")	&&  $memulist[]=array('href'=>'newcards.php?tabindex=1'	,	'hreftext'=>'&nbsp;卡号生成&nbsp;|');
								$memulist[]=array('href'=>'newcards.php?tabindex=2'	,	'hreftext'=>'&nbsp;新手卡列表&nbsp;|');
								$memulist[]=array('href'=>'newcards.php?tabindex=3'	,	'hreftext'=>'&nbsp;公会卡列表&nbsp;|');
	isaccess("ADDCARDTYPE")	&&  $memulist[]=array('href'=>'newcards.php?tabindex=4'	,	'hreftext'=>'&nbsp;卡型创建&nbsp;');


	$exportresults = "";
	if(isset($_GET['list']) && intval($_GET['list']) == 1 ) 
	{
		$list = listTypes();
foreach($list as $id=>$name ):
echo <<<HTML
		<input type="checkbox" id=$id />$name <br/>
	
HTML;

endforeach;		

		exit();
	}elseif (isset($_POST['exporttypes'])){
		$fileName = "./data/temp/cardtypes-". date("Y-m-d", time(0)) ."-". rand(100, 999). ".txt";
		if ( file_exists($fileName) ) 
			unlink( $fileName );
		$fp = fopen($fileName, "w");

	
		//$types = explode(",", $_POST['nametypehidden']);
		$result = $_SGLOBAL['mgrdb']->query( "select id, cardname, isunique, uniquecode, extdata from cardtype where id in( " . strval($_POST['nametypehidden'] ) . " ) " );
		while( $value = $_SGLOBAL['mgrdb']->fetch_array( $result))
		{
			$sql = sprintf(" insert into cardtype set cardname='%s', isunique='%s', uniquecode='%s', extdata='%s' ;" , strval($value['cardname']), strval( $value['isunique']),  strval($value['uniquecode']), strval( $value['extdata']));
			fputs( $fp, $sql);
		}

		fclose($fp);
		$exportresults = ("导出成功！<a href='$fileName'> 下载(右键另存为) </a>");		
	}elseif (isset( $_POST['nameimport']) ){

		$upload_file = $_FILES['upload_file']['tmp_name'];
		$upload_file_name = $_FILES['upload_file']['name']; 

		if ( $upload_file){
			$file_size_max = 1000* 1000;
			$store_dir = "./data/temp/";
			$accept_overwrite = 1;
			
			$upload_file_size = $_FILES['upload_file']['size'];
			if( $upload_file_size > $file_size_max ){
				echo "file too large.";
				exit;
			}

			if(  substr( strrchr($upload_file_name, "."), 1)!= "txt")
			{
				echo "file type not permit.";
				exit;
			}

			$content = 	file_get_contents ( $upload_file);
			insertImportFileContent( $content);

		}else{
			echo "not uploaded file" . $upload_file;
			exit;
		}
	}
	
	//顶部导航
	include template("newcards");


	//获取已存卡型数据
	$cardinfolist	=getcardinfo();
	$giftlist		=array();
	foreach($gifts as $key=>$value)
	{
		foreach($value as $k=>$v)
			$giftlist[$v]=($k);
	}

	$giftlist2		=array();
	foreach($gifts as $key=>$value)
	{
		foreach($value as $k=>$v)
			$giftlist2[$v]=convertPageCharset($k);
	}

	//处理创建卡型表单
	if(isset($_POST) && !empty($_POST) && isset($_POST['submit']))
	{
		global $_SGLOBAL;		
		try{

			
			$serveridList 	= $_POST['n_servers'];
			$cardtype = intval($_POST['cardtype']);

			
			if( strlen( $serveridList) < 1 ) $serveridList = "$G_SERVERID"; 
			$servers = explode(",", $serveridList);	

			//获取统一的最大卡型编号
			$maxseq = 1;
			foreach($servers as $serverid)
			{	
				$conn = getConnection( $serverid);
				$result = mysql_query( "select max(id) + 1 as maxseq from cardtype ", $conn);
				if( $value = mysql_fetch_array($result))
				{
					if( intval($value['maxseq']))
					{
						$maxseq = max( $maxseq, intval($value['maxseq']));
					}
				}
				mysql_close( $conn);
				unset($conn);
			}
			
			
			foreach($servers as $serverid)
			{		
				$opresult	="";
				$opmessage	="";
				$conn = getConnection( $serverid);	 
				
				//对非单一卡号重复性检测
				if( $cardtype !=1)
				{		
					mysql_set_charset($_SC['dbcharset'], $conn);	
					$sql=" select count(1) as isDup from cardtype where isunique!=1 and cardname='".convertDBCharset($_POST['cardname'])."' ; ";			
					$result = mysql_query($sql, $conn);
					$isDup= 0;
					if($value= mysql_fetch_array($result))
					{						
						$isDup=$value['isDup'];
					}
		
					if(intval($isDup)>0)
					{
			
						$opresult	=("失败");
						$opmessage	=("卡型[{$_POST['cardname']}] 已存在数据库中!");
					}
				}
			
				//入库操作
				if(empty($opresult))
				{
					//卡型名称
					$cardname	=($_POST['cardname']);

					//单一卡型标记
					$isunique	=intval($_POST['cardtype']);

					//单一卡型卡号
					$uniquecode	=$_POST['cardno'];

					//中文名称物品列表
					$extdataCN	=$_POST['extdataCN'];

					//物品列表				
					$extdata	=preg_replace("/\s*\|\s*/",",",trim($_POST['extdata']));//分隔符改|为，
					$extdata	="{".preg_replace("/,$/","",$extdata)."}";	//去除末尾的，

					$time		=time();
					$now		=date('Y-m-d H:i:s');
					$sql		=" insert into cardtype(id, cardname,isunique,uniquecode,extdata,time,exptime) values('$maxseq', '$cardname',$isunique,'$uniquecode', '$extdata' , $time ,0  );";
					$sql		=convertDBCharset($sql);
					$newcardinfo="";
			
					if($isunique==1)
					{				
						$newcardinfo="单一卡型,[卡型名称]=$cardname,[卡号]=$uniquecode,[道具]=$extdataCN,[生成时间]=$now ";
					}else
					{				
						$newcardinfo="非单一卡型,[卡型名称]=$cardname,[道具]=$extdataCN,[生成时间]=$now ";
					}
				
					$result= mysql_query( $sql, $conn );				
					if($result)
					{
						$opresult	=("成功");
						$opmessage	=("卡型创建成功!");

						$user=getUserInfo();
						writeAdminLog(array
							(
							'adminId'		=>$user['userid'],
							'adminName'		=>$user['realName'],
							'type'			=>$_opCodeList['ADDCARDTYPE']['code'],
							'ext1'			=>"",
							'ext2'			=>"",
							'remark'		=>$_opCodeList['ADDCARDTYPE']['name']." . ".convertDBCharset($newcardinfo),
							'loginIp'		=>$_SERVER['REMOTE_ADDR'],
							'time'			=>time()
							)
						);

					}else
					{
						$opresult	=("失败");
						$opmessage	=("卡型创建失败访问数据异常");
					}
				}
				
				mysql_close( $conn);
				unset( $conn);
			}
		}catch(Exception $e)
		{
			$opresult	=("失败");
			$opmessage	=("卡型创建失败访问数据异常".($e->getMessage()));
		}
		include template("result");
		exit();
	}else if(isset($_GET['delete']) && $_GET['delete']=="true")
	{//删除卡型

		$cardtypeid	=intval($_GET['cardtypeid']);
		deletecardtype($cardtypeid);
	}

	//道具信息中文化
	foreach($gift_sorts as $key =>$value)
	{
		$gift_sorts[$key]=convertPageCharset($value);
	}
	


	//解析卡型字符串成  带中文卡型名称的列表$cardinflist
	foreach($cardinfolist as $key=>$value)
	{
		$cardinfolist[$key]['extdata']= preg_replace('/\[\s*([0-9]*)\s*]\s*=\s*([0-9]*)/e','parseobject("\\1","\\2")',$value['extdata']);
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

	function parseobject($key,$count)
	{
		global $giftlist;
		
		return convertPageCharset($giftlist[$key])." x $count 个";
	}

	
	function parseobject2($key,$count)
	{
		global $giftlist2;

		return ($giftlist2[$key])." x $count 个";
	}

	function deletecardtype($cardtypeid)
	{
		global $_SGLOBAL;
		global $_opCodeList;

		$cardinfo="";
		$list	=getcardinfo(" where id=$cardtypeid ");

		if(count($list)>0)
		{
			//解析卡型字符串成  带中文卡型名称的列表$cardinflist
			foreach($list as $key=>$value)
			{
				$list[$key]['extdata']= preg_replace('/\[\s*([0-9]*)\s*]\s*=\s*([0-9]*)/e','parseobject2("\\1","\\2")',$value['extdata']);
			}

			$mod		=" ";

			foreach($list[0] as $key=>$value)
			{
				$cardinfo	=$cardinfo.convertDBCharset(" [$key]=$value ");
			}

		}


		$result	=$_SGLOBAL['mgrdb']->query(" delete from cardtype where id=$cardtypeid ; ");
		if(!$result)
		{
			echo "<script language=\"javascript\"> alert(\"删除卡型失败:\""+$_SGLOBAL['mgrdb']->error()+")</script>";
			return;
		}

		$user=getUserInfo();
		writeAdminLog(array
			(
			'adminId'		=>$user['userid'],
			'adminName'		=>$user['realName'],
			'type'			=>$_opCodeList['DELCARDTYPE']['code'],
			'ext1'			=>"",
			'ext2'			=>"",
			'remark'		=>$_opCodeList['DELCARDTYPE']['name']." . ".($cardinfo),
			'loginIp'		=>$_SERVER['REMOTE_ADDR'],
			'time'			=>time()
			)
		);
		
	}


	function getConnection( $serverid)
	{
		global $_SERVER_DB;
		$CommonConnection = mysql_connect( $_SERVER_DB[$serverid]["server"], $_SERVER_DB[$serverid]["user"], $_SERVER_DB[$serverid]["pwd"], true) ;
		if($CommonConnection and !empty($CommonConnection))
		{
			mysql_select_db( $_SERVER_DB[$serverid]["db"], $CommonConnection) OR exit("E_MYSQL_SELECTDB") ;
			mysql_set_charset($_SC['dbcharset'], $CommonConnection);	
		}
		
		return $CommonConnection;
	}

	function listTypes()
	{
		global $_SGLOBAL;
		$list = array();
		
		$result = $_SGLOBAL['mgrdb']->query("select id, cardname from cardtype limit 100 ");
		while( $value = $_SGLOBAL['mgrdb']->fetch_array( $result))
		{
			$list[ intval($value['id'])] = convertPageCharset(strval( $value['cardname']));
		}

		return $list ;
	}
	
	function insertImportFileContent( $content)
	{
		global $_SGLOBAL;
		
		$explode = explode(";", $content);
		foreach( $explode as $sql)
		{	
			if( preg_match( "/insert/", $sql) >= 1 )
				$_SGLOBAL['mgrdb']->query( $sql);
		}
	}
	
	include template("generatecardtype");
	

	
?>
