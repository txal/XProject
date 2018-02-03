<?php
	//推广员赠送房卡
	include_once("../../common.php");
    require_once("pub/lib/WxPay.Config.php");
    require_once("pub/example/WxPay.JsApiPay.php");

	$pmtName = empty($_COOKIE['__pmtname']) ? "" : $_COOKIE['__pmtname'];
	if (empty($pmtName)) {
		exit("请先登录推广员后台");
	}

    $ownCard = 0;
    $sendCard = 1;
    $tarCharID = "";

    $wxNick = "";
    $pmtCharID = "";
    $disabled = false;

    if (!empty($_POST['pmtcharid'])) {
        $pmtCharID = intval($_POST['pmtcharid']);
        $ownCard = intval($_POST['owncard']);
        $sendCard = intval($_POST['sendcard']);
        $tarCharID = intval($_POST['tarcharid']);
        $wxNick = strval($_POST['wxnick']);
        if ($ownCard <= 0) {
            showAlert("您当前没有房卡可赠送");

        } else if ($sendCard <= 0) {
            showAlert("至少须赠送1张房卡");

        } else if ($sendCard > $ownCard) {
            showAlert("赠送数量大于拥有数量");

        } else {
            dbConnect("logdb");
            $sql = "select id from account where char_id='$tarCharID';";
            $query = $_SGLOBAL['logdb']->query($sql);
            $row = $_SGLOBAL['logdb']->fetch_array($query);
            if (!$row) {
                showAlert("目标角色不存在");
            } else {
                $resJson = request(serverID(), "givecard"
                    , array("nSrcCharID"=>$pmtCharID, "nTarCharID"=>$tarCharID, "nGiveCount"=>$sendCard));
                if (empty($resJson)) {
                    showAlert("赠送房卡失败");
                } else {
                    $ownCard = $resJson["nRemainCard"];
                    showAlert("赠送房卡成功");
                }
            }
        }
    } else {
        $tools = new JsApiPay();
        $openId = $tools->GetOpenid();
        $appId = WxPayConfig::APPID;
        $secret = WxPayConfig::APPSECRET;
        $url = "https://api.weixin.qq.com/cgi-bin/token?grant_type=client_credential&appid=$appId&secret=$secret";
        $resp = json_decode(file_get_contents($url), true);
        $access_token = $resp['access_token'];
        $url = "https://api.weixin.qq.com/cgi-bin/user/info?access_token=$access_token&openid=$openId&lang=zh_CN";
        $resp = json_decode(file_get_contents($url), true);

        if (!empty($resp['nickname'])) {
            $wxNick = $resp['nickname'];
			$unionID = $resp['unionid'];

            dbConnect("logdb");
            $sql = "select char_id from account where account='$unionID';";
            $query = $_SGLOBAL['logdb']->query($sql);
            $row = $_SGLOBAL['logdb']->fetch_array($query);
            if (!$row) {
                $disabled = true;
                showAlert("您的微信未绑定游戏");

            } else {
                $pmtCharID = $row['char_id'];
                $ownCard = request($serverID, "querycard", array("nCharID"=>$pmtCharID));
                $ownCard = empty($ownCard) ? 0 : intval($ownCard);
            }

        } else {
            showAlert("获取微信昵称失败,请重新打开页面");
        }
    }
?>

<html>
<head>
    <meta http-equiv="content-type" content="text/html;charset=utf-8"/>
    <meta name="viewport" content="width=device-width, initial-scale=1"/> 
    <title>推广员-赠送房卡</title>
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

        function sendCard() {
            var ownCard = document.getElementById("owncard").value.trim();
            var srcCharID = document.getElementById("pmtcharid").value.trim();
            var tarCharID = document.getElementById("tarcharid").value.trim();
            var giveCard = document.getElementById("sendcard").value.trim();
            if (!tarCharID.match(/^\d+$/g)) {
                alert("请输入正确的角色ID");
                return false;
            }
            if (srcCharID == tarCharID) {
                alert("不能赠送房卡给自己");
                return false;
            }
            if (ownCard <= 0) {
                alert("您当前没有房卡可赠送");
                return false;
            }
            if (giveCard <= 0) {
                alert("至少须赠送1张房卡");
                return false;
            }
            if (giveCard > ownCard) {
                alert("赠送数量大于拥有数量");
                return false;
            }
            if (!confirm("是否赠送"+giveCard+"个房卡给玩家"+tarCharID+"?")) {
                return false;
            }
            return true;
        }

	</script>
</head>
<body>
	<?php if(!empty($pmtName)) { ?>
		<div id="pmtname" name="pmtname" style="border-bottom:1px solid #ddd;">
			<font color="red">当前推广员: </font><?=$pmtName?>
		</div>
	<?php } ?>
<form action="" method="post" onsubmit="return sendCard()">
	<div align="center" style="margin-top:5px;">
            <div>
            <label>你的微信名:</label>
            <input type='text' style="height:30; width:60%;" disabled="true" value="<?=$wxNick?>"/><br/>
            <input name='wxnick' id='wxnick' style="display:none" value="<?=$wxNick?>"/>
            <input name='pmtcharid' id='pmtcharid' style="display:none" value="<?=$pmtCharID?>"/>
            </div>

            <div style="margin-top: 5px;">
            <label>拥有房卡数:</label>
            <input name='owncard' id='owncard' type='text' style="height:30; width:60%;" disabled="true" value="<?=$ownCard?>"/><br/>
            <input name='owncard' id='owncard' style="display:none" value="<?=$ownCard?>"/>
            </div>

            <div style="margin-top: 5px;">
            <label>赠送角色ID: </label>
    		<input name='tarcharid' id='tarcharid' type='text' style="height:30; width:60%;" varlue="<?=$tarCharID?>"/><br/>
            </div>

            <div style="margin-top: 5px;">
            <label>赠送房卡数: </label>
    		<input name='sendcard' id='sendcard' type='text' style="height:30; width:60%;" value="<?=$sendCard?>"/><br/>
            </div>
            <div style="margin-top: 5px;">
            <input name='send' id='send' type='submit' style="height:30; width:30%;"
                <?php if ($disabled) {?>disabled="true"<?php } ?> value="赠送"/><br/>
            </div>
    </div>
</form>
</body>
</html>
