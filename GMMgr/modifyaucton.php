<?php
	
	require_once 'common.php';
	require_once './include/gift.inc.php';	
	isaccess("AUCTIONSHIFT") or exit('Access Denied');	

	//处理修改道具表单
	if(isset($_POST['modify_submit']))
	{
		$id	=intval($_POST['cardtypeid']);
		$money = intval($_POST['money']);
		$uptime = dt2timestamp($_POST['uptime']);
		$cardname = $_POST['cardname'];

		$error		=savecardtype($id, $cardname, $money,$uptime);
		if(!empty($error))
		{
			echo("<script language=\"javascript\"> alert(\"$error\"); </script>");
		}

		echo('<script language="javascript"> parent.location.reload(); </script>');
	}

	//处理上层页面操作，用于显示修改页面s
	if(isset($_GET['id']) && !empty($_GET['id']))
	{
		$id	=intval($_GET['id']);
		$cardname = $_GET['cardname'];
		$money = intval($_GET['money']);
		$uptime = $_GET['uptime'];
echo '
		<html>
		<script language="javascript" type="text/javascript" src="js/calendar_with_time.js"></script>	
		<script type="text/javascript">
			function checkform()
			{
				
				if(document.getElementById("id_money").value.length==0)
				{
					alert("元宝数不能为空!");
					return false;
				}

				if(document.getElementById("id_uptime").value.length==0)
				{
					alert("上架时间不能为空!");
					return false;
				}

				return true;
			}
		</script>

		<body leftmargin="8" topmargin="8" background=\'skin/images/allbg.gif\'>
		<div style="text-align:center;">
			<div align="center" style="padding:1px 0;background:#EEE; border-top:1px solid #BBB; border-bottom:1px solid #BBB;border-left:1px solid #BBB;border-right:1px solid #BBB;">
				<form method="post" onSubmit="javascript: return checkform();">
					<table width="100%">
						<tr><td width="20%" align="center"><input type="hidden" name="cardtypeid" id="id_cardtypeid" value="'.$id.'" />
															<input type="hidden" name="cardname" id="id_cardname" value="'.$cardname.'" />'.$cardname.'</td>
							<td width="20%" align="center"><input type="text"  name="money" id="id_money" value="'.$money.'" /></td>
							<td width="20%" align="center"><input name="uptime" id="id_uptime" value="'.$uptime.'" style="width:150px" onFocus="new Calendar().show(this);" onKeyDown="javascript: return false;"></input></td>
							<td align="center"><input type="submit" name="modify_submit" id="id_modify_submit" value="确定"></input></td>
						</tr>
					</table>
				</form>
			</div>
		</div>
		</body>
		</html>
		';

	}
	

	function savecardtype($id, $cardname, $money, $uptime)
	{
		global $_SGLOBAL;
		global $_opCodeList;
		if ( $_SGLOBAL['mgrdb']->query(" update auction set money=$money , uptime=$uptime where id=$id ;") )
		{
			$user=getUserInfo();
			writeAdminLog(array
				(
				'adminId'		=>$user['userid'],
				'adminName'		=>$user['realName'],
				'type'			=>$_opCodeList['AUCTIONMODIFY']['code'],
				'ext1'			=>"",
				'ext2'			=>"",
				'remark'		=>convertDBCharset("修改道具:$cardname {元宝=$money, 上架时间=".date("Y-m-d H:i:s",$uptime).", 操作时间=".time()."} "),
				'loginIp'		=>$_SERVER['REMOTE_ADDR'],
				'time'			=>time()
				)
			);
			return "";
		}else{
			return " faild ";
		}

	}
		

?>