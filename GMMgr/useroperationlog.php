<?php 
	include_once("common.php");
	isaccess("OPLOG") or exit('Access Denied');		
		
	function readoperationlog($param)
	{
		global  $_SGLOBAL;	

		//记录最终结果
		$result=array();
		
		//**************************获取选定页面记录
		$pagesize =$param['pagesize'];
		$start =($param['page']-1)*$pagesize;
		$sql ="select adminID, adminName as operator, opName,time,ext from adminlog ".$param['where']." order by adminID,time desc limit $start,$pagesize";

		$list =array();
		dbConnect("mgrdb");
		$query =$_SGLOBAL['mgrdb']->query($sql);
		while($value = $_SGLOBAL['mgrdb']->fetch_array($query))
		{
			$value['operator'] = convertPageCharset($value['operator']);
			$value['remark'] = convertPageCharset($value['opName']);
			$value['time'] = date('Y-m-d H:i:s',$value['time']); 		
			$list[]=$value;
		}
		$result['data']=$list;


		//**************************总页数
		$sql=" select count(1) as recordCount from adminlog ".$param['where'];
		$query	=$_SGLOBAL['mgrdb']->query($sql );
		$value	=$_SGLOBAL['mgrdb']->fetch_array($query);
		$result['recordCount']=intval($value['recordCount']);

		return $result;

	}


	function readoperators($selected_operator)
	{

		global $_SGLOBAL;

		//**************************所有用户名，以构造筛选条件
		$query	=$_SGLOBAL['mgrdb']->query(" select distinct(adminName) as operator from adminlog where adminName is not null and trim(adminName)!='' " );
		//全部操作人的筛选
		$list	=array(
			'-1'=>array('selected'=>" selected ",'operator'=>"All")
		);
		
		while($value=$_SGLOBAL['mgrdb']->fetch_array($query))
		{
			$value['operator'] = convertPageCharset($value['operator']);
			if($value['operator'] == $selected_operator)
			{
				$value['selected'] = " selected ";
				$list['-1']['selected']	= " ";
			}else
			{
				$value['selected']=" ";
			}
			$list[] = $value;
		}
		
		return $list;
	}

	function readoptypes($selected_optype)
	{
		global $_SGLOBAL;
		global $_opCodeList;

		//**************************所有操作类型，以构造筛选条件
		$optypeName	=array(
			'-1'=>array('selected'=>" selected ",'opname'=>"ALL")
		);

		foreach($_opCodeList as $short=>$desc)
		{
			//设定默认显示在下拉框的操作名称
			if($desc['code']==$selected_optype)
			{
				$optypeName[$desc['code']] = array('selected'=>" selected ",'opname'=>convertPageCharset($desc['name']));
				$optypeName['-1']['selected'] = " ";
			}else
			{
				$optypeName[$desc['code']] = array('selected'=>" ",'opname'=>convertPageCharset($desc['name']));
			}

		}
		
		return $optypeName;
	}


?>