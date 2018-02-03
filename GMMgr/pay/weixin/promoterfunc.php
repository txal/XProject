<?php
	//推广员功能列表
	include_once("../../common.php");
	$pmtName = empty($_COOKIE['__pmtname']) ? "" : $_COOKIE['__pmtname'];
	if (empty($pmtName)) {
		exit("请先登录推广员后台");
	}
?>

<html>
<head>
    <meta http-equiv="content-type" content="text/html;charset=utf-8"/>
    <meta name="viewport" content="width=device-width, initial-scale=1"/> 
    <title>推广员-后台</title>
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

		function recharge() {
			window.location.href = "index.php?type=1";
		}

		function sendcard() {
			window.location.href = "promoter_sendcard.php";
		}

	</script>
</head>
<body>
	<?php if(!empty($pmtName)) { ?>
		<div id="pmtname" name="pmtname" style="border-bottom:1px solid #ddd;">
			<font color="red">当前推广员: </font><?=$pmtName?>
		</div>
	<?php } ?>
	<div align="center" style="margin-top:5px;">
		<input name='recharge' id='recharge' type='button' style="height:30; width:40%; display:inline;" value="充值房卡" onclick="recharge()" />
		<input name='sendcard' id='sendcard' type='button' style="height:30; width:40%; display:inline;" value="赠送房卡" onclick="sendcard()" />
	</div>
</body>
</html>
