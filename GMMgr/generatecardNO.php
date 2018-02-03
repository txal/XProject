<?php 
	include_once("common.php");

	isaccess("CARDS") or exit('Access Denied');		
	
	//按照权限显示不用的导航标签
	isaccess("GENCARDNO")	&&  $memulist[]=array('href'=>'newcards.php?tabindex=1'	,	'hreftext'=>'&nbsp;卡号生成&nbsp;|');
								$memulist[]=array('href'=>'newcards.php?tabindex=2'	,	'hreftext'=>'&nbsp;新手卡列表&nbsp;|');
								$memulist[]=array('href'=>'newcards.php?tabindex=3'	,	'hreftext'=>'&nbsp;公会卡列表&nbsp;|');
	isaccess("ADDCARDTYPE")	&&  $memulist[]=array('href'=>'newcards.php?tabindex=4'	,	'hreftext'=>'&nbsp;卡型创建&nbsp;');

	$serverlist		=$_SERVERLIST;
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
		$fileName = "./data/temp/cardno-import-". date("Y-m-d", time(0)) ."-". rand(100, 999). ".txt";
		if ( file_exists($fileName) ) 
			unlink( $fileName );
		$fp = fopen($fileName, "w");

		$result = $_SGLOBAL['mgrdb']->query( "select cardNO, uid, username, buildtime, usetime, state, ip, type from newcards where `type` in( ". strval($_POST['nametypehidden'] ) ." ) and `state`=0 ");
		while( $value = $_SGLOBAL['mgrdb']->fetch_array($result) )
		{
			$sql = sprintf(" insert into newcards set cardNO='%s', uid=%d, username='%s', buildtime=%d, usetime=%d, state=%d, ip='%s', `type`=%d ; ", strval($value['cardNO']), intval($value['uid']), strval($value['username']), intval($value['buildtime']), intval($value['usetime']), intval($value['state']), strval($value['ip']), intval($value['type']) );
			fputs( $fp, $sql);
		}

		fclose($fp);
		$exportresults = ("导出成功！<a href='$fileName'> 下载(右键另存为) </a>");	
	}elseif (isset( $_POST['nameimport']) ){

		$upload_file = $_FILES['upload_file']['tmp_name'];
		$upload_file_name = $_FILES['upload_file']['name']; 

		if ( $upload_file){
			$file_size_max = 1000* 1000;
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

	define('PAGESIZE',20);

	//获取各种卡型名称
	$list=getcardtypes();
	$typelist		=$list['cardtypes'];
	$alltypelist	=$list['allcardtypes'];

	$newcardlist=array();
	$param=array();

	//查询页面
	$page = !empty($_GET['page']) && intval($_GET['page']) > 0 ? intval($_GET['page']) : 1;	

	//页面大小
	$param['pagesize']	=PAGESIZE;
	
	//保存上一次查询的筛选条件，如’卡号类型‘’待搜索的卡号‘’用户名‘
	$msg=array(
		'scardtype'	=>"-1",
		'scardno'	=>"",
		'susername'	=>""
	);


	$opmessage = "";
	//处理卡号生成表单
	if(isset($_POST['generatesubmit']))
	{	
		$serveridList 	= $_POST['n_servers'];
		if( strlen( $serveridList) < 1 ) $serveridList = "$G_SERVERID"; 
		$servers = explode(",", $serveridList);	

		$opresult	=("成功");
		$opmessage	=("生成卡号成功");	

		$error=generatecards($servers , $_POST['cardamount'],$_POST['cardtype']);
		if( empty($error))
		{
			$user=getUserInfo();
			writeAdminLog(array
				(
				'adminId'		=>$user['userid'],
				'adminName'		=>$user['realName'],
				'type'			=>$_opCodeList['GENCARDNO']['code'],
				'ext1'			=>"",
				'ext2'			=>"",
				'remark'		=>($_opCodeList['GENCARDNO']['name']." : [cardtype]={$_POST['cardtype']},[cardamount]={$_POST['cardamount']} "),
				'loginIp'		=>$_SERVER['REMOTE_ADDR'],
				'time'			=>time()
				)
			);

		}else
		{
			$opresult	=("失败");
			$opmessage	=("生成卡号失败:$error");
		}
		

	}elseif(isset($_POST['exportsubmit']))//导出卡号	
	{
		header("Location:exportcardno.php?cardtype=".$_POST['excardtype']."&startNO=".$_POST['startNO']."&endNO=".$_POST['endNO']);
		
		$user=getUserInfo();
		writeAdminLog(array
			(
			'adminId'		=>$user['uerid'],
			'adminName'		=>$user['realName'],
			'type'			=>$_opCodeList['EXPCARDNO']['code'],
			'ext1'			=>"",
			'ext2'			=>"",
			'remark'		=>($_opCodeList['EXPCARDNO']['name']." : CardNO[ {$_POST['startNO']} --> {$_POST['endNO']} ]"),
			'loginIp'		=>$_SERVER['REMOTE_ADDR'],
			'time'			=>time()
			)
		);
	}elseif(!empty($_POST)  &&  isset($_POST['ssubmit']))//按照筛选条件进行卡信息查询
	{
		//获取筛选条件
		$scardtype	=intval($_POST['scardtype']);
		$scardid	=trim($_POST['scardid']);
		$susername	=trim($_POST['susername']);
		
		//配置where语句
		$where		="";
		$mod		=" ";
		
		//卡号类型过滤
		if($scardtype!=-1)
		{
			$where				=$where.$mod." type=$scardtype ";
			$mod				=" and ";
			$msg['scardtype']	=$scardtype;
		}
		
		if(!empty($scardid))
		{
			$where				=$where.$mod." cardNO='$scardid' ";
			$mod				=" and ";
			$msg['scardno']		=$scardid;
		}
		
		if(!empty($susername))
		{
			$where				=$where.$mod." username='$susername' ";
			$mod				=" and ";
			$msg['susername']	=$susername;
		}		
		
		$param['where']=$where;
	}
	
	$param['page']	=$page;
	$list=readcardlist($param);
	$cardlist=$list['data'];
	$pageblock="";
	if($list['recordcount']>PAGESIZE)
		$pageblock = convertPageCharset(multi($list['recordcount'], PAGESIZE, $page, ''));
	
	
	include template("generatecardNO");
	
	function readcardlist($param)
	{
		global  $_SGLOBAL;
		global  $typelist;
		global  $alltypelist;

		//过滤条件
		$where =" ";
		if(isset($param['where']))
		{
			$where =(empty($param['where']))?" ":" where ".$param['where'];
		}
		
		//页面限制
		$limit=" ";
		if(isset($param['page']) && isset($param['pagesize']))
		{
			$limit	=((empty($param['page']) || empty($param['pagesize']) )?" ":" limit ".($param['page']-1)*$param['pagesize']." , ".$param['pagesize']);
		}
	
		//查询页面	
		$page=1;
		$start		=($page-1)*$param['pagesize'];
		
		$sql="  select id,cardNO,buildtime,username,state,usetime, Ip,type from newcards $where order by id desc $limit";

		$query	=$_SGLOBAL['mgrdb']->query($sql);
		$list	=array();
	
		while($value	=$_SGLOBAL['mgrdb']->fetch_array($query))
		{
			$value['buildtime']	=date('Y/m/d H:i:s',$value['buildtime']);
			$value['usetime']	=date('Y/m/d H:i:s',$value['usetime']);
			
			$value['type']		=array_key_exists($value['type'],$alltypelist)?$alltypelist[$value['type']]:"单一卡";
			
			$value['state']		=($value['state']==0?"未使用":"已使用");
			$list[]=$value;
		}
		
		//记录总条数
		$query	=$_SGLOBAL['mgrdb']->query(" select count(1) as recordCount from newcards $where" );
		$value	=$_SGLOBAL['mgrdb']->fetch_array($query);
		
		return array(
			'data'			=>$list,
			'recordcount'	=>$value['recordCount']
		);
	}
	
	function generatecards( $servers, $cardamount,$cardtype)
	{
		global $cardprename;
		global $_SGLOBAL;
				
		//每次生成记录数
		$batchsize	=5000;
		while($cardamount>0)
		{			
			try{

						
				//待生成的卡号数量
				$codecount = $cardamount<=$batchsize?$cardamount:$batchsize;
				
				$sql ="	insert into newcards(cardNO,uid,username,buildTime,useTime,state,Ip,type) values";
				for($i=1;$i<=$codecount;++$i)
				{
					$mod=($i==$codecount?";":",");
					$unicode=substr(md5(uniqid(rand(), true)),0,16);
					$sql.=" ('$unicode',0,'',".time().",0,0,'','$cardtype') ".$mod;
				}


				//insert into all the servers --------------------------
				$affect_rows = 0 ;
				foreach( $servers as $serverid) 
				{
					$conn = getConnection( $serverid);

					//开始事务
					mysql_query( " start transaction; " , $conn);
					$result = mysql_query( $sql, $conn);
					$affect_rows = max( $affect_rows, mysql_affected_rows($conn) );

					mysql_query(" commit ; ");
					mysql_close( $conn);
					unset( $conn);
				}

			
				//剩余未生成的卡号数量
				$cardamount -=($affect_rows>0?$affect_rows:0);
				
			}catch(Exception $e)
			{
				return "message : ".$e->getMessage();
			}
		}
	
		return "";
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
			if($value['isunique']!=1)
			{
				$list[$value['id']]		=convertPageCharset($value['cardname']);
			}	
			$alllist[$value['id']]	=convertPageCharset($value['cardname']);
		}
		
		return array(
			'cardtypes'		=>$list,
			'allcardtypes'	=>$alllist
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
	
?>
