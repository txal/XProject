gtGameSql = {}
gtGameSql.sInsertAccountSql = "insert into account set source=%d,accountid=%d,accountname='%s',vip=%d,time=%d;"
gtGameSql.sUpdateAccountSql = "update account %s where accountid=%d;"
gtGameSql.sInsertRoleSql = "insert into role set accountid=%d,roleid=%d,rolename='%s',level=%d,time=%d;"
gtGameSql.sUpdateRoleSql = "update role %s where roleid=%d;"

--创建游戏数据库
local sGameSql = 
[[
#创建数据库
CREATE DATABASE IF NOT EXISTS %s DEFAULT CHARSET utf8;
USE %s;

#账号表
CREATE TABLE IF NOT EXISTS account(
	source int not null default 0,
	accountid int not null default 0,
	accountname varchar(128) not null default 0,
	vip tinyint unsigned not null default 0,
	time int not null default 0,
	primary key(source, accountname),
	unique(accountid)
) ENGINE=MyISAM charset=utf8;

#角色表
CREATE TABLE IF NOT EXISTS role(
	accountid int not null default 0,
	roleid int not null default 0,
	rolename varchar(128) not null default 0,
	level tinyint unsigned not null default 0,
	time int not null default 0,
	primary key(roleid),
	unique(rolename),
	index(accountid)
) ENGINE=MyISAM charset=utf8;

#日志存储过程
DROP PROCEDURE IF EXISTS proc_log;
CREATE PROCEDURE proc_log(
  IN event int
, IN reason int
, IN accountid int
, IN roleid int
, IN rolename varchar(128) charset utf8
, IN level tinyint unsigned
, IN vip tinyint unsigned
, IN field1 varchar(1024) charset utf8
, IN field2 varchar(1024) charset utf8
, IN field3 varchar(1024) charset utf8
, IN field4 varchar(1024) charset utf8
, IN field5 varchar(1024) charset utf8
, IN field6 varchar(1024) charset utf8
, IN time int
)
BEGIN
DECLARE table_name varchar(32);
SET table_name = concat("log_", DATE_FORMAT(NOW(),'%%Y_%%m_%%d'));
SET @STMT := CONCAT("CREATE TABLE IF NOT EXISTS ", table_name
, "(id int primary key auto_increment,"
, "event int not null default 0,"
, "reason int not null default 0,"
, "accountid int not null default 0,"
, "roleid int not null default 0,"
, "rolename varchar(128) not null default '',"
, "level tinyint unsigned not null default 0,"
, "vip tinyint unsigned not null default 0,"
, "field1 varchar(1024) default '',"
, "field2 varchar(1024) default '',"
, "field3 varchar(1024) default '',"
, "field4 varchar(1024) default '',"
, "field5 varchar(1024) default '',"
, "field6 varchar(1024) default '',"
, "time int not null default 0,"
, "index(event),"
, "index(roleid),"
, "index(reason),"
, "index(time)"
, ") ENGINE=MyISAM charset=utf8;"
);
PREPARE STMT FROM @STMT;
EXECUTE STMT;
SET @STMT := CONCAT("insert into ", table_name
, " set event=", event
, ",reason=", reason
, ",accountid=", accountid
, ",roleid=", roleid
, ",rolename='", rolename
, "',level=", level
, ",vip=", vip
, ",field1='", field1, "',field2='", field2, "',field3='", field3, "',field4='", field4, "',field5='", field5, "',field6='", field6
, "',time=", time, ";");
PREPARE STMT FROM @STMT;
EXECUTE STMT;
END;
]]


--创建管理数据库
local sMgrSql = 
[[
#创建数据库
CREATE DATABASE IF NOT EXISTS %s DEFAULT CHARSET utf8;
USE %s;
#充值,网关等在后台mgr.sql中创建
]]

function InitMysql()
	if gbMysqlInited then
		return
	end
	--游戏数据库初始化
	local tConf = gtServerConf.tLogDB
	local sGameSql = string.format(sGameSql, tConf.sDBName, tConf.sDBName)
	local oGameMysql = MysqlDriver:new()
	if not oGameMysql:Connect(tConf.sIP, tConf.nPort, '', tConf.sUserName, tConf.sPassword, "utf8") then
		return LuaTrace("连接数据库失败: ", tConf)
	end
	oGameMysql:Query(sGameSql)
	LuaTrace("初始化数据库成功: ", tConf)

	--管理数据库初始化
	local tConf = gtMgrMysqlConf
	local sMgrSql = string.format(sMgrSql, tConf.sDBName, tConf.sDBName)
	local oMgrMysql = MysqlDriver:new()
	if not oMgrMysql:Connect(tConf.sIP, tConf.nPort, '', tConf.sUserName, tConf.sPassword, "utf8") then
		return LuaTrace("连接数据库失败:", tConf)
	end
	oMgrMysql:Query(sMgrSql)	
	LuaTrace("初始化数据库成功: ", tConf)
	gbMysqlInited = true
end
