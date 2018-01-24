--创建游戏数据库
local sGameSql = 
[[
#创建数据库
CREATE DATABASE IF NOT EXISTS %s DEFAULT CHARSET utf8; USE %s;

#账号存储过程
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
, "unique(char_id),"
, "unique(char_name)"
, ") ENGINE=MyISAM charset=utf8;"
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
END;

#日志存储过程
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
, ") ENGINE=MyISAM charset=utf8;"
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
END;
]]


--创建管理数据库
local sMgrSql = 
[[
#创建数据库
CREATE DATABASE IF NOT EXISTS %s DEFAULT CHARSET utf8; USE %s;

#充值表
CREATE TABLE IF NOT EXISTS `recharge` (
	`order_id` varchar(32) NOT NULL DEFAULT '',
	`server_id` int NOT NULL DEFAULT 0,
	`char_id` varchar(32) NOT NULL DEFAULT '',
	`recharge_id` int NOT NULL DEFAULT 0,
	`product_id` varchar(256) NOT NULL DEFAULT '',
	`money` int NOT NULL DEFAULT 0,
	`extdata` varchar(256) NOT NULL DEFAULT '',
	`channel` varchar(32) NOT NULL DEFAULT '',
	`state` tinyint NOT NULL DEFAULT 0  COMMENT '0:已下单未购买;1:已验证成功未发货;2:已发货成功',
	`time` int NOT NULL DEFAULT 0,
  PRIMARY KEY (`order_id`),
  KEY (`char_id`, `state`)
) ENGINE=MyISAM DEFAULT CHARSET=utf8;

#网关表
CREATE TABLE IF NOT EXISTS `gateway` (
	`id` int auto_increment,
	`url` varchar(32) NOT NULL DEFAULT '',
	`state` tinyint NOT NULL DEFAULT 0 COMMENT '0:不可用;1:可用',
	`time` int NOT NULL DEFAULT 0,
  PRIMARY KEY (`id`)
) ENGINE=MyISAM DEFAULT CHARSET=utf8;
]]

local function InitMysql()
	--游戏数据库初始化
	local tMysqlConf = gtGameMysqlConf[1]
	local sGameSql = string.format(sGameSql, tMysqlConf.sDBName, tMysqlConf.sDBName)
	local oGameMysql = MysqlDriver:new()
	if not oGameMysql:Connect(tMysqlConf.sIP, tMysqlConf.nPort, '', tMysqlConf.sUserName, tMysqlConf.sPassword, "utf8") then
		LuaTrace("Connect to mysql: "..table.ToString(tMysqlConf).." fail")
		return
	end
	oGameMysql:Query(sGameSql)
	LuaTrace("Init mysql: "..table.ToString(tMysqlConf, true).." successful")

	--管理数据库初始化
	local tMysqlConf = gtMgrMysqlConf[1]
	local sMgrSql = string.format(sMgrSql, tMysqlConf.sDBName, tMysqlConf.sDBName)
	local oMgrMysql = MysqlDriver:new()
	if not oMgrMysql:Connect(tMysqlConf.sIP, tMysqlConf.nPort, '', tMysqlConf.sUserName, tMysqlConf.sPassword, "utf8") then
		LuaTrace("Connect to mysql: "..table.ToString(tMysqlConf, true).." fail")
		return
	end
	oMgrMysql:Query(sMgrSql)	
	LuaTrace("Init mysql: "..table.ToString(tMysqlConf, true).." successful")
	gbMysqlInited = true
end
if not gbMysqlInited then
	InitMysql()
end
