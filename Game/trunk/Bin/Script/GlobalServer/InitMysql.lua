--创建游戏数据库
local sGameSql = 
[[
#创建数据库
CREATE DATABASE IF NOT EXISTS %s DEFAULT CHARSET utf8; USE %s;

#账号存储过程
DELIMITER //
DROP PROCEDURE IF EXISTS proc_account;
CREATE PROCEDURE proc_account(
	IN account varchar(32) charset utf8
	, IN charid varchar(32) charset utf8
	, IN charname varchar(32) charset utf8
	, IN roleid int
	, IN currtime int
)
BEGIN

SET @STMT := CONCAT("CREATE TABLE IF NOT EXISTS ", "account"
, "(id int primary key auto_increment,"
, "account varchar(32) default '',"
, "char_id varchar(32) default '',"
, "char_name varchar(32) default '',"
, "role_id int default 0,"
, "time int default 0,"
, "unique(account),"
, "unique(char_id)"
, ") charset=utf8;"
);
PREPARE STMT FROM @STMT;
EXECUTE STMT;

SET @STMT := CONCAT("insert into ", "account"
, " set account='", account
, "',char_id='", charid
, "',char_name='", charname
, "',role_id=", roleid
, ",time=", currtime
, ";"
);
PREPARE STMT FROM @STMT;
EXECUTE STMT;

END
//
DELIMITER ;

#日志存储过程
DELIMITER //
DROP PROCEDURE IF EXISTS proc_log;
CREATE PROCEDURE proc_log(
  IN event int
, IN reason int
, IN charid varchar(32) charset utf8
, IN charname varchar(32) charset utf8
, IN level tinyint unsigned
, IN vip tinyint unsigned
, IN field1 varchar(1024) charset utf8
, IN field2 varchar(1024) charset utf8
, IN field3 varchar(1024) charset utf8
, IN field4 varchar(1024) charset utf8
, IN field5 varchar(1024) charset utf8
, IN field6 varchar(1024) charset utf8
, IN currtime int
)
BEGIN

DECLARE table_name varchar(32);
SET table_name = DATE_FORMAT(NOW(),'log_%%Y_%%m_%%d');

SET @STMT := CONCAT("CREATE TABLE IF NOT EXISTS ", table_name
, "(id int primary key auto_increment,"
, "event int default 0,"
, "reason int default 0,"
, "char_id varchar(32) default '',"
, "char_name varchar(32) default '',"
, "level tinyint unsigned default 0,"
, "vip tinyint unsigned default 0,"
, "field1 varchar(1024) default '',"
, "field2 varchar(1024) default '',"
, "field3 varchar(1024) default '',"
, "field4 varchar(1024) default '',"
, "field5 varchar(1024) default '',"
, "field6 varchar(1024) default '',"
, "time int default 0,"
, "index(event),"
, "index(char_id)"
, ") charset=utf8;"
);
PREPARE STMT FROM @STMT;
EXECUTE STMT;

SET @STMT := CONCAT("insert into ", table_name
, " set event=", event
, ",reason=", reason
, ",char_id='", charid
, "',char_name='", charname
, "',level=", level
, ",vip=", vip
, ",field1='", field1
, "',field2='", field2
, "',field3='", field3
, "',field4='", field4
, "',field5='", field5
, "',field6='", field6
, "',time=", currtime
,";"
);
PREPARE STMT FROM @STMT;
EXECUTE STMT;

END
//
DELIMITER ;
]]


--创建充值数据库
local sRechargeSql = 
[[
#创建数据库
CREATE DATABASE IF NOT EXISTS %s DEFAULT CHARSET utf8; USE %s;

#充值表
CREATE TABLE IF NOT EXISTS `recharge` (
	`order_id` varchar(32) NOT NULL DEFAULT '',
	`server_id` int NOT NULL DEFAULT '0',
	`char_id` varchar(32) NOT NULL DEFAULT '',
	`recharge_id` int NOT NULL DEFAULT '0',
	`product_id` varchar(256) NOT NULL DEFAULT '',
	`money` int NOT NULL DEFAULT '0',
	`receipt` varchar(2048) NOT NULL DEFAULT '',
	`extdata` varchar(256) NOT NULL DEFAULT '',
	`platform` varchar(32) NOT NULL DEFAULT '',
	`channel` varchar(32) NOT NULL DEFAULT '',
	`state` tinyint NOT NULL DEFAULT '0',
	`time` int NOT NULL DEFAULT '0',
  PRIMARY KEY (`order_id`),
  KEY (`platform`),
  KEY (`server_id`, `state`)
) ENGINE=MyISAM DEFAULT CHARSET=utf8;

#服务器列表表
CREATE TABLE IF NOT EXISTS `serverlist` (
	`server_id` int  NOT NULL DEFAULT '0', 
	`server_name` varchar(64) NOT NULL DEFAULT '',
	`ip` varchar(128) NOT NULL DEFAULT '',
	`port` int NOT NULL DEFAULT '0',
	`state` tinyint NOT NULL DEFAULT '0',
	`time` int NOT NULL DEFAULT '0',
  PRIMARY KEY (`server_id`),
  KEY (`server_id`, `state`)
) ENGINE=MyISAM DEFAULT CHARSET=utf8;
]]

local function InitMysql()
	--游戏数据库初始化
	local tMysqlConf = gtGameMysqlConf
	sGameSql = string.format(sGameSql, tMysqlConf.sDBName, tMysqlConf.sDBName)
	local oGameMysql = MysqlDriver:new()
	LuaTrace("连接游戏数据库:"..tMysqlConf.sDBName, tMysqlConf.sIP, tMysqlConf.nPort)
	if not oGameMysql:Connect(tMysqlConf.sIP, tMysqlConf.nPort, '', tMysqlConf.sUserName, tMysqlConf.sPassword, "utf8") then
		LuaTrace("连接游戏数据库失败,退出进程!")
		os.exit()
	end
	oGameMysql:Query(sGameSql)	

	--充值数据库初始化
	local tMysqlConf = gtRechargeMysqlConf
	sRechargeSql = string.format(sRechargeSql, tMysqlConf.sDBName, tMysqlConf.sDBName)
	local oRechargeMysql = MysqlDriver:new()
	LuaTrace("连接充值数据库:"..tMysqlConf.sDBName, tMysqlConf.sIP, tMysqlConf.nPort)
	if not oRechargeMysql:Connect(tMysqlConf.sIP, tMysqlConf.nPort, '', tMysqlConf.sUserName, tMysqlConf.sPassword, "utf8") then
		LuaTrace("连接充值数据库失败,退出进程!")
		os.exit()
	end
	oRechargeMysql:Query(sRechargeSql)	
	gbMysqlInited = true
end
if not gbMysqlInited then
	InitMysql()
end
