<?php
header('Content-Type: text/html; charset=utf-8');
error_reporting(E_ALL);
define('DEBUG', TRUE);

header('Access-Control-Allow-Origin: *');
header("Access-Control-Allow-Credentials: true"); 
header('Access-Control-Allow-Headers: X-Requested-With');
header('Access-Control-Allow-Headers: Content-Type');
header('Access-Control-Allow-Methods: POST, GET, OPTIONS, DELETE, PUT');
header('Access-Control-Max-Age: 86400'); 

//配置参数
$_SC = array();
$_SC["mgrdb"] = array(
	'dbhost'=>'192.168.0.9', //服务器地址
	'dbport'=>3308, //服务器端口
	'dbuser'=>'root', //用户
	'dbpwd'=>'123456', //密码
	'dbname'=>'taizifei_mgr', //数据库
	'dbcharset'=>'utf8', //字符集
	'pconnect'=>0, 	//是否持续连接
	'tablepre'=>'', //表名前缀
);

$_SC['charset'] = 'utf-8'; //页面字符集
$_SC['template'] = 'admin'; //默认模版
$_SC['tplrefresh'] = 1;

$_SC['cookiepre'] = '';
$_SC['cookiepath'] = '';
$_SC['cookiedomain'] = '';

$_RECHARGE_TYPE = array(0=>"测试", 1=>"正式", 2=>"后台"); //充值类型
$_RECHARGE_STATE = array(0=>"未到帐", 1=>"已到帐", 2=>"已发货"); //充值状态

$_RECHARGE_CONF = array(11=>"公众号玩家", 12=>"公众推广员", 21=>"AppStore房卡", 22=>"APPStore金币"); //配置映射
$NOTIFY_URL = "http://sg.df.baoyugame.com/50001/pay/weixin/pub/example/notify.php"; //微信充值回调
$MD5_KEY = "6XJRju"; //加密秘钥

$_SERVERLIST = array();
// id=>array(id=>0,name=>"",gate=>"",state=0,hot=>0,time=>0
// 	,gm=>array(ip=>"",port=>0)
// 	,logdb=>array(ip=>"",port=>0,usr=>"",pwd=>"",db=>""));

?>
