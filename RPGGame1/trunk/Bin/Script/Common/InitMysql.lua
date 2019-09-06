gtGameSql = {}
gtGameSql.sInsertAccountSql = "insert into account set source=%d,channel='%s',accountid=%d,accountname='%s',vip=%d,time=%d;"
gtGameSql.sUpdateAccountSql = "update account set %s where accountid=%d;"
gtGameSql.sInsertRoleSql = "insert into role set accountid=%d,roleid=%d,rolename='%s',level=%d,header='%s',gender=%d,school=%d,time=%d;"
gtGameSql.sUpdateRoleSql = "update role set %s where roleid=%d;"
gtGameSql.sOnlineLogSql = "insert into online set accountid=%d,roleid=%d,level=%d,vip=%d,type=%d,keeptime=%d,time=%d;"
gtGameSql.sInsertShareSql = "insert into share set srcserver=%d,srcroleid=%d,tarserver=%d,tarroleid=%d,time=%d;"
gtGameSql.sInsertYuanBaoSql = "insert into yuanbao set accountid=%d,roleid=%d,level=%d,vip=%d,reason='%s',yuanbao=%d,curryuanbao=%d,bind=%d,time=%d;"
gtGameSql.sInsertActLogSql = "insert into activitylog set userid=%d,userlv=%d,uservip=%d,actid=%d,acttype=%d,actname='%s',subactid=%d,subactname='%s',actcost='%s',actget='%s',actcharge='%s',exdata1='%s',exdata2='%s',createdtime='%s';"
gtGameSql.sInsertTaskSql = "insert into task set accountid=%d,roleid=%d,school=%d,level=%d,vip=%d,taskype=%d,taskid=%d,taskstate=%d,time=%d;"
gtGameSql.sCreateUnionSql = "insert into `union` set unionid=%d,displayid=%d,unionname='%s',unionlevel=%d,leaderid=%d,leadername='%s',createtime=%d;"
gtGameSql.sDelUnionSql = "delete from `union` where unionid=%d;"
gtGameSql.sUpdateUnionSql = "update `union` set %s where unionid=%d;"
gtGameSql.sCreateUnionMemberSql = "insert into unionmember set roleid=%d,rolename='%s',unionid=%d,position=%d,jointime=%d,leavetime=%d,currcontri=%d,totalcontri=%d,daycontri=%d;"
gtGameSql.sUpdateUnionMemberSql = "update unionmember set %s where roleid=%d;"
gtGameSql.sInsertEventLogSql = "insert into event_log set event=%d,reason='%s',accountid=%d,roleid=%d,rolename='%s',level=%d,vip=%d,field1='%s',field2='%s',field3='%s',field4='%s',field5='%s',field6='%s',time=%d;"
gtGameSql.sInsertRoleBehaviourSql = "insert into role_behaviour_log set userid=%d,userlv=%d,behaviourid=%d,timestamp=%d;"

--创建游戏数据库
local sInitGameSql = 
[[
#创建数据库
CREATE DATABASE IF NOT EXISTS %s DEFAULT CHARSET utf8;
USE %s;

#账号表
CREATE TABLE IF NOT EXISTS account(
	id int primary key auto_increment,
	source int not null default 0 COMMENT '平台ID',
	channel char(127) not null default '' COMMENT '渠道标识',
	accountid int not null default 0 COMMENT '账号ID,游戏生成',
	accountname varchar(128) not null default 0 COMMENT '账号名,SDK',
	accountstate tinyint not null default 0 COMMENT '0正常;1禁言;2封号',
	vip tinyint unsigned not null default 0 COMMENT 'vip等级',
	time int not null default 0 COMMENT '创建时间',
	unique(source, channel, accountname),
	unique(accountid)
) ENGINE=InnoDB charset=utf8 COMMENT '账号表';

#角色表
CREATE TABLE IF NOT EXISTS role(
	accountid int not null default 0 COMMENT '账号ID',
	roleid int not null default 0 COMMENT '角色ID',
	rolename varchar(128) not null default 0 COMMENT '角色名(昵称)',
	level tinyint unsigned not null default 0 COMMENT '等级',
	gender tinyint not null default 0 COMMENT '性别:1男;2女',
	header varchar(32) not null default '' COMMENT '头像',
	school tinyint not null default 0 COMMENT '职业',
	logintime int not null default 0 COMMENT '最后登录时间',
	online tinyint not null default 0 COMMENT '1在线;0离线',
	yuanbao int not null default 0 COMMENT '非绑元宝数',
	bindyuanbao int not null default 0 COMMENT '绑元宝数',
	power bigint not null default 0 COMMENT '战力',
	time int not null default 0 COMMENT '创建时间',
	primary key(roleid),
	unique(rolename),
	index(accountid)
) ENGINE=InnoDB charset=utf8 COMMENT '角色表';

#登录表
CREATE TABLE IF NOT EXISTS online(
	id int primary key auto_increment,
	accountid int not null default 0 COMMENT '账号ID',
	roleid int not null default 0 COMMENT '角色ID',
	level int not null default 0 COMMENT '角色等级',
	vip tinyint not null default 0 COMMENT 'vip等级',
	type tinyint not null default 0 COMMENT '1:登录;0:下线',
	keeptime int not null default 0 COMMENT '上次在线,离线时间持续时间',
	time int not null default 0 COMMENT '操作时间'
) ENGINE=InnoDB charset=utf8 COMMENT '登录表';

#元宝获得,消耗表
CREATE TABLE IF NOT EXISTS yuanbao(
	id int primary key auto_increment,
	accountid int not null default 0 COMMENT '账号ID',
	roleid int not null default 0 COMMENT '角色ID',
	level int not null default 0 COMMENT '等级',
	vip tinyint not null default 0 COMMENT 'vip',
	yuanbao int not null default 0 COMMENT '>0获得;<0消耗',
	curryuanbao int not null default 0 COMMENT '当前元宝',
	bind tinyint not null default 0 COMMENT '0非绑元宝;1绑定元宝',
	reason varchar(256) default '' COMMENT '消耗原因',
	time int not null default 0 COMMENT '操作时间'
) ENGINE=InnoDB charset=utf8 COMMENT '元宝获得,消耗表';

#任务停留
CREATE TABLE IF NOT EXISTS task(
	id int primary key auto_increment,
	accountid int not null default 0 COMMENT '账号ID',
	roleid int not null default 0 COMMENT '角色ID',
	school tinyint not null default 0 COMMENT '职业',
	level int not null default 0 COMMENT '等级',
	vip tinyint not null default 0 COMMENT 'vip',
	tasktype tinyint not null default 0 COMMENT '类型',
	taskid int not null default 0 COMMENT '任务ID',
	taskstate tinyint not null default 0 COMMENT '任务状态',
	time int not null default 0 COMMENT '操作时间'
) ENGINE=InnoDB charset=utf8 COMMENT '任务日志';

#帮派
CREATE TABLE IF NOT EXISTS `union`(
	unionid int primary key COMMENT '帮派ID',
	displayid int COMMENT '帮派显示ID',
	unionname varchar(32) not null default '' COMMENT '帮派名',
	unionlevel int not null default 0 COMMENT '帮派等级',
	leaderid int not null default 0 COMMENT '帮主id',
	leadername varchar(32) not null default '' COMMENT '帮主名',
	createtime int not null default 0 COMMENT '创建时间'
) ENGINE=InnoDB charset=utf8 COMMENT '帮派';

#帮派成员
CREATE TABLE IF NOT EXISTS `unionmember`(
	roleid int primary key COMMENT '角色id',
	rolename varchar(32) not null default '' COMMENT '角色名',
	unionid int not null default 0 COMMENT '帮派id',
	position int not null default 0 COMMENT '职位id',
	jointime int not null default 0 COMMENT '加入时间',
	leavetime int not null default 0 COMMENT '上次退帮时间',
	currcontri int not null default 0 COMMENT '当前贡献',
	totalcontri int not null default 0 COMMENT '历史总贡献',
	daycontri int not null default 0 COMMENT '今日贡献'
) ENGINE=InnoDB charset=utf8 COMMENT '帮派成员';

#事件日志
CREATE TABLE IF NOT EXISTS `event_log` (
	id int primary key auto_increment,
	event int not null default 0,
	reason varchar(64) default '',
	accountid int not null default 0,
	roleid int not null default 0,
	rolename varchar(128) not null default '',
	level tinyint unsigned not null default 0,
	vip tinyint unsigned not null default 0,
	field1 varchar(1024) default '',
	field2 varchar(1024) default '',
	field3 varchar(1024) default '',
	field4 varchar(1024) default '',
	field5 varchar(1024) default '',
	field6 varchar(1024) default '',
	time int not null default 0,
	index(event),
	index(roleid),
	index(time)
) ENGINE=InnoDB charset=utf8 COMMENT '事件日志表';

#活动日志
CREATE TABLE IF NOT EXISTS activitylog (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `userid` int(11) NOT NULL DEFAULT '0' COMMENT '用户id',
  `userlv` int(11) NOT NULL DEFAULT '0' COMMENT '用户参加活动时等级',
  `uservip` int(11) NOT NULL DEFAULT '0' COMMENT '用户参加活动时vip等级',
  `actid` int(11) NOT NULL DEFAULT '0' COMMENT '活动ID',
  `acttype` int(11) NOT NULL DEFAULT '0' COMMENT '活动类型(具体看活动那边的定义,如: 1活跃类;2消费类;3充值类)',
  `actname` varchar(32) NOT NULL DEFAULT '' COMMENT '活动名',
  `subactid` int(11) NOT NULL DEFAULT '0' COMMENT '子活动ID',
  `subactname` varchar(32) NOT NULL DEFAULT '' COMMENT '子活动名',
  `actcost` text COMMENT '{物品id：物品数量，物品id：物品数量}',
  `actget` text COMMENT '{物品id：物品数量，物品id：物品数量}',
  `actcharge` text COMMENT '充值类活动（单冲，累充）在完成相关活动获取奖励时达到的充值树立',
  `exdata1` varchar(256) NOT NULL DEFAULT '' COMMENT '保留字段',
  `exdata2` varchar(256) NOT NULL DEFAULT '' COMMENT '保留字段',
  `createdtime` datetime NOT NULL COMMENT '记录时间',
  PRIMARY KEY (`id`),
  KEY `time` (`createdtime`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8 COMMENT='活动日志表';

#玩家行为
CREATE TABLE IF NOT EXISTS role_behaviour_log (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `userid` int(11) NOT NULL DEFAULT '0' COMMENT '用户id',
  `userlv` int(11) NOT NULL DEFAULT '0' COMMENT '用户等级',
  `behaviourid` int(11) NOT NULL DEFAULT '0' COMMENT '行为ID',
  `timestamp` int(11) NOT NULL DEFAULT '0' COMMENT '行为时间戳',
  PRIMARY KEY (`id`),
  INDEX (`userid`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8 COMMENT='玩家行为表';

]]

local _bMysqlInited = false
function InitMysqlDB()
	if _bMysqlInited then
		return
	end
	_bMysqlInited = true

	--管理数据库初始化
	local tConf = gtMgrSQL
	local oMgrMysql = MysqlDriver:new()
	local bRes = oMgrMysql:Connect(tConf.ip, tConf.port, tConf.db, tConf.usr, tConf.pwd, "utf8")
	assert(bRes, "连接数据库失败:"..tostring(tConf))

	oMgrMysql:Query("select logdb from serverlist where serverid="..gnServerID)
	local bRes = oMgrMysql:FetchRow()
	assert(bRes, "服务器不存在:"..gnServerID)
	local logdb = oMgrMysql:ToString("logdb")
	local tLogDB = string.Split(logdb, "|")

	--游戏数据库初始化
	local oGameMysql = MysqlDriver:new()
	local bRes = oGameMysql:Connect(tLogDB[1], tLogDB[2], '', tLogDB[3], tLogDB[4], "utf8")
	assert(bRes, "连接数据库失败:"..logdb)

	local sInitGameSql = string.format(sInitGameSql, tLogDB[5], tLogDB[5])
	oGameMysql:Query(sInitGameSql)
	LuaTrace("初始化日志数据库成功: ", tLogDB)
end
