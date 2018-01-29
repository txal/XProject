--创建游戏数据库
local sGameSql = 
[[
#创建数据库
CREATE DATABASE IF NOT EXISTS %s DEFAULT CHARSET utf8; USE %s;

#账号存储过程
DROP PROCEDURE IF EXISTS proc_account;
CREATE PROCEDURE proc_account(
	IN account varchar(128) charset utf8
	, IN charid varchar(32) charset utf8
	, IN charname varchar(128) charset utf8
	, IN source int
	, IN currtime int
)
BEGIN
SET @STMT := CONCAT("CREATE TABLE IF NOT EXISTS ", "account"
, "(id int primary key auto_increment,"
, "account varchar(128) default '',"
, "char_id varchar(32) default '',"
, "char_name varchar(128) default '',"
, "source int default 0,"
, "vip tinyint default 0,"
, "chapter int default 0,"
, "time int default 0,"
, "unique(char_id),"
, "index(time)"
, ") ENGINE=MyISAM charset=utf8;"
);
PREPARE STMT FROM @STMT;
EXECUTE STMT;
SET @STMT := CONCAT("insert into account set account='",account,"',char_id='",charid
,"',char_name='",charname,"',source=",source,",time=",currtime,";");
PREPARE STMT FROM @STMT;
EXECUTE STMT;
END;

#日志存储过程
DROP PROCEDURE IF EXISTS proc_log;
CREATE PROCEDURE proc_log(
  IN event int
, IN reason varchar(64) charset utf8
, IN charid varchar(32) charset utf8
, IN charname varchar(128) charset utf8
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
SET table_name = concat("log_", DATE_FORMAT(NOW(),'%%Y_%%m_%%d'));
SET @STMT := CONCAT("CREATE TABLE IF NOT EXISTS ", table_name
, "(id int primary key auto_increment,"
, "event int default 0,"
, "reason varchar(64) default '',"
, "char_id varchar(32) default '',"
, "char_name varchar(128) default '',"
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
, "index(char_id),"
, "index(reason),"
, "index(time)"
, ") ENGINE=MyISAM charset=utf8;"
);
PREPARE STMT FROM @STMT;
EXECUTE STMT;
SET @STMT := CONCAT("insert into ", table_name
, " set event=", event, ",reason='", reason, "',char_id='", charid, "',char_name='", charname, "',level=", level, ",vip=", vip
, ",field1='", field1, "',field2='", field2, "',field3='", field3, "',field4='", field4, "',field5='", field5, "',field6='", field6
, "',time=", currtime ,";");
PREPARE STMT FROM @STMT;
EXECUTE STMT;
END;

#排行榜储过程
DROP PROCEDURE IF EXISTS proc_ranking;
CREATE PROCEDURE proc_ranking(
	IN charid varchar(32) charset utf8
	, IN charname varchar(128) charset utf8
	, IN rankid int
	, IN rankvalue int
	, IN vip tinyint
	, IN recharge int
	, IN currtime int
)
BEGIN
SET @STMT := CONCAT("CREATE TABLE IF NOT EXISTS ", "ranking"
, "(id int primary key auto_increment,"
, "charid varchar(32) default '',"
, "charname varchar(128) default '',"
, "rankid int default 0,"
, "rankvalue int default 0,"
, "vip tinyint default 0,"
, "recharge int default 0,"
, "time int default 0,"
, "index(rankid),"
, "index(time)"
, ") ENGINE=MyISAM charset=utf8;"
);
PREPARE STMT FROM @STMT;
EXECUTE STMT;
SET @STMT := CONCAT("insert into ranking set charid='",charid,"',rankid=",rankid
,",charname='",charname,"',rankvalue=",rankvalue,",vip=",vip,",recharge=",recharge,",time=",currtime,";");
PREPARE STMT FROM @STMT;
EXECUTE STMT;
END;
]]


--创建管理数据库
local sMgrSql = 
[[
#创建数据库
CREATE DATABASE IF NOT EXISTS %s DEFAULT CHARSET utf8; USE %s;
#充值表,网关表在后台mgr.sql中创建
]]

function InitMysql()
	if gbMysqlInited then
		return
	end
	--游戏数据库初始化
	local tMysqlConf = gtGameMysqlConf
	local sGameSql = string.format(sGameSql, tMysqlConf.sDBName, tMysqlConf.sDBName)
	local oGameMysql = MysqlDriver:new()
	if not oGameMysql:Connect(tMysqlConf.sIP, tMysqlConf.nPort, '', tMysqlConf.sUserName, tMysqlConf.sPassword, "utf8") then
		return LuaTrace("连接数据库失败: ", tMysqlConf)
	end
	oGameMysql:Query(sGameSql)
	LuaTrace("初始化数据库成功: ", tMysqlConf)

	--管理数据库初始化
	local tMysqlConf = gtMgrMysqlConf
	local sMgrSql = string.format(sMgrSql, tMysqlConf.sDBName, tMysqlConf.sDBName)
	local oMgrMysql = MysqlDriver:new()
	if not oMgrMysql:Connect(tMysqlConf.sIP, tMysqlConf.nPort, '', tMysqlConf.sUserName, tMysqlConf.sPassword, "utf8") then
		return LuaTrace("连接数据库失败:", tMysqlConf)
	end
	oMgrMysql:Query(sMgrSql)	
	LuaTrace("初始化数据库成功: ", tMysqlConf)
	gbMysqlInited = true
end
