<?php
	//推广员/玩家充值列表
	include_once("../../common.php");
	require_once("pub/lib/WxPay.Config.php");
	require_once("pub/example/WxPay.JsApiPay.php");

	$productMap = array();
	$productJson = array();

	$wxNick = "";
	$unionID = "";

	$pmtName = "";
	$type = 0;

	if (!empty($_POST['json'])) {
		$json = strval($_POST['json']);
		$type = intval($_POST['type']);
		if ($type == 1) {//推广员
			$pmtName = empty($_COOKIE['__pmtname']) ? "" : $_COOKIE['__pmtname'];
			if (empty($pmtName)) {
				exit("请先登录推广员后台");
			}
		}

		$wxNick = strval($_POST['wxnick']);
		$unionID = strval($_POST['unionid']);
		$sql = "select char_id, char_name from account where account='$unionID';";
		$err = "该微信未绑定游戏账号:$unionID";

		dbConnect("logdb");
		$query = $_SGLOBAL["logdb"]->query($sql, true);
		if (!$query) {
			echo "<script type='text/javascript'>alert('查询角色失败')</script>";
			queryProduct();

		} else {
			$row = $_SGLOBAL["logdb"]->fetch_array($query);
			if (!$row) {
				echo "<script type='text/javascript'>alert('$err')</script>";
				queryProduct();
			} else {
				$data = json_decode($json, true);
				$postData = array();
				$postData['charid'] = $row['char_id'];
				$postData['charname'] = $row['char_name'];
				$postData['money'] = $data['nMoney'];
				$postData['rechargeid'] = $data['nID']; //recharge id
				$postData['rechargename'] = $data['sName'];

				$jsonData  = json_encode($postData);
				$signStr = $MD5_KEY.$jsonData.$pmtName;
				$sign = md5($signStr);

				//urlencode在urldecode的时候会把加号弄丢,所以用rawurlencode/decode
				$jsonData = rawurlencode($jsonData);
				$pmtName = rawurlencode($pmtName);

				$url = "pub/example/jsapi.php?data=$jsonData&pmtname=$pmtName&sign=$sign";
				Header("Location: $url");
			}
		}

	} else {
		$type = empty($_GET['type']) ? 0 : $_GET['type'];
		if ($type == 1) {//推广员
			$pmtName = empty($_COOKIE['__pmtname']) ? "" : $_COOKIE['__pmtname'];
			if (empty($pmtName)) {
				exit("请先登录推广员后台");
			}
		}

		$tools = new JsApiPay();
		$appId = WxPayConfig::APPID;
		$secret = WxPayConfig::APPSECRET;
		$openId = $tools->GetOpenid();
		$url = "https://api.weixin.qq.com/cgi-bin/token?grant_type=client_credential&appid=$appId&secret=$secret";
		$cont = file_get_contents($url);
		$resp = json_decode($cont, true);
		$access_token = $resp['access_token'];
		$url = "https://api.weixin.qq.com/cgi-bin/user/info?access_token=$access_token&openid=$openId&lang=zh_CN";
		$cont = file_get_contents($url);
		$resp = json_decode($cont, true);
		if (!empty($resp['nickname'])) {
			$wxNick = $resp['nickname'];
			$unionID = $resp['unionid'];
		} else {
			echo "<script type='text/javascript'>alert('获取微信昵称失败,请重新打开页面')</script>";
		}
		queryProduct();
	}

	function queryProduct() {
		global $productMap, $productJson, $pmtName;
		$type = empty($pmtName) ? 11 : 12;
		$productList = request(serverID(), "productlist", array("type"=>$type));
		foreach ($productList as $k => $v) {
			$productMap[$v["nID"]] = $v;
			$productJson[$v['nID']] = json_encode($v);
		}
	}

	$titleCount = count($productMap);
	$ulDivHeight = $titleCount * 43 + 5;
?>

<html>
<head>
    <meta http-equiv="content-type" content="text/html;charset=utf-8"/>
    <meta name="viewport" content="width=device-width, initial-scale=1"/> 
    <title>微信支付-充值列表</title>
    <style type="text/css">
        ul {
            margin-left:10px;
            margin-right:10px;
            margin-top:5px;
            padding: 0;
        }
        li {
            width: 100%;
            float: left;
            margin: 0px;
            margin-left:1%;
            padding: 0px;
            height: 40px;
            display: inline;
            line-height: 40px;
            color: #fff;
            font-size: large;
            word-break:break-all;
            word-wrap: break-word;
            margin-bottom: 3px;
        }
        a {
            -webkit-tap-highlight-color: rgba(0,0,0,0);
        	text-decoration:none;
            color:#fff;
        }
        a:link{
            -webkit-tap-highlight-color: rgba(0,0,0,0);
        	text-decoration:none;
            color:#fff;
        }
        a:visited{
            -webkit-tap-highlight-color: rgba(0,0,0,0);
        	text-decoration:none;
            color:#fff;
        }
        a:hover{
            -webkit-tap-highlight-color: rgba(0,0,0,0);
        	text-decoration:none;
            color:#fff;
        }
        a:active{
            -webkit-tap-highlight-color: rgba(0,0,0,0);
        	text-decoration:none;
            color:#fff;
        }
    </style>
	<script language="javascript" type="text/javascript">
		function recharge(json) {
			json = JSON.stringify(json);
			var wxnick = document.getElementById('wxnick');
			wxnick = wxnick.value.trim();
			if (wxnick.match(/^\s*$/g)) {
				return alert('获取微信昵称失败,请重新打开页面');
			}
			post("index.php", {type:'<?=$type?>',json:json,unionid:'<?=$unionID?>',wxnick:wxnick});
		}

		function post(URL, PARAMS) {
			var temp = document.createElement("form");
			temp.action = URL;
			temp.method = "post";
			temp.style.display = "none";
			for (var x in PARAMS) {
				var opt = document.createElement("textarea");
				opt.name = x;
				opt.value = PARAMS[x];
				temp.appendChild(opt);
			}
			document.body.appendChild(temp);
			temp.submit();
			return temp;
		}
	</script>
</head>
<body>
	<?php if(!empty($pmtName)) { ?>
		<div id="pmtname" name="pmtname" style="border-bottom:1px solid #ddd;">
			<font color="red">当前推广员: </font><?=$pmtName?>
		</div>
		</div>
	<?php } ?>

	<div align="center" name="wxdiv" id="wxdiv" style="margin-top:5px;">
		<label>用户昵称: </label><input name="wxnick" id="wxnick" type="text" style="height:30; width:60%; font-color:red" disabled="true" value="<?=$wxNick?>"> </input>
	</div>

	<?php if(empty($pmtName)) { ?>
		<div align='center' name="usrnote" id="usrnote" style="margin-top:5px; font-family:微软雅黑; font-size:0.9em; font-weight:bold; color:#000000; border-top:1px solid #ddd;">
			<div align='left', style='background-color:#ffffff; width:80%;'>
				温馨提示:<br/>
				<font color="red">	
				1. 成功购买后，房卡或金币直接充值到游戏中。<br/>
				2. 房卡或金币将充入您当前微信号绑定的游戏帐号中，请确认无误后再充值。<br/>
				3. 如果充值后未收到房卡或金币，请先检查是否支付成功后，再与客服联系咨询。
				</font>
			</div>
		</div>
	<?php } ?>

	<div align="center", style="height:<?=$ulDivHeight?>px; border-top:1px solid #ddd; border-bottom:1px solid #ddd; margin-top:5px;">
        <ul>
			<?php if(is_array($productMap)) { foreach($productMap as $k => $v) { ?>
				<a href="javascript:;" style="width:100%"><li style="background-color:#FF7F24" onClick='recharge(<?=$productJson[$k]?>)'><?=$v['sName']?></li></a>
			<?php } } ?>
        </ul>
	</div>

	<?php if(!empty($pmtName)) { ?>
		<!--
		<div align='center' name="pmtnote" id="pmtnote", style="margin-top:5px; font-family:微软雅黑; font-size:0.9em; font-weight:bold; color:#000000;">
			<div align='left', style='background-color:#ffffff; width:80%;'>
				累计充值和单价:<br/>
				当累计充值小于3万张时，单张金额为1.2元。<br/>
				当累计充值大于3万张，小于10万张时，单张金额为1元。<br/>
				当累计充值大于10万张，小于50万张时，单张金额为0.8元。<br/>
				当累计充值大于50万张时，单张金额为0.6元。<br/>
			</div>
		</div>
		-->
	<?php } ?>
</body>
</html>
