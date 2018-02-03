 CREATE TABLE IF NOT EXISTS `adminlog` (
  `adminID` int(11) DEFAULT NULL,
  `adminName` varchar(64) DEFAULT NULL,
  `opCode` int(11) DEFAULT NULL,
  `opName` varchar(256) DEFAULT NULL,
  `loginIp` varchar(256) DEFAULT NULL,
  `ext` varchar(256) DEFAULT NULL,
  `time` int(11) DEFAULT NULL
) ENGINE=MyISAM DEFAULT CHARSET=utf8;


CREATE TABLE IF NOT EXISTS `admin` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `name` varchar(16) NOT NULL DEFAULT '' UNIQUE,
  `passwd` varchar(32) NOT NULL DEFAULT '',
  `purview` varchar(128) DEFAULT '',
  `loginIp` varchar(15) NOT NULL DEFAULT '',
  `loginTime` int(11) NOT NULL DEFAULT 0,
  `state` tinyint(4) NOT NULL DEFAULT 0,
  `createTime` int(11) NOT NULL DEFAULT 0,
  PRIMARY KEY (`id`)
) ENGINE=MyISAM  DEFAULT CHARSET=utf8;


CREATE TABLE IF NOT EXISTS `recharge` (
  `orderid` varchar(32) NOT NULL DEFAULT '',
  `source` int(11) NOT NULL DEFAULT 0,
  `serverid` int(11) NOT NULL DEFAULT 0,
  `charid` varchar(32) NOT NULL DEFAULT '',
  `rechargeid` int(11) NOT NULL DEFAULT 0,
  `productid` varchar(256) NOT NULL DEFAULT '',
  `money` double NOT NULL DEFAULT 0,
  `extdata` varchar(256) NOT NULL DEFAULT '',
  `state` tinyint(4) NOT NULL DEFAULT 0 COMMENT '0:已下单未购买;1:已验证成功未发货;2:已发货成功',
  `time` int(11) NOT NULL DEFAULT 0,
  `type` tinyint(4) NOT NULL DEFAULT 0 COMMENT '0:测试;1:正式;2:后台',
  PRIMARY KEY (`orderid`),
  KEY `key_charid` (`charid`,`state`),
  KEY `key_serverid` (`serverid`, `state`)
) ENGINE=MyISAM DEFAULT CHARSET=utf8;

CREATE TABLE IF NOT EXISTS `notice` (
  `id` int NOT NULL AUTO_INCREMENT,
  `serverid` int  NOT NULL DEFAULT 0,
  `sender` varchar(32) NOT NULL DEFAULT '',
  `content` varchar(256) NOT NULL DEFAULT '',
  `interval` int NOT NULL DEFAULT 0 COMMENT '执行间隔(秒)',
  `begintime` varchar(32) NOT NULL DEFAULT '',
  `endtime` varchar(32) NOT NULL DEFAULT '',
  `time` int NOT NULL DEFAULT 0,
  PRIMARY KEY (`id`)
) ENGINE=MyISAM DEFAULT CHARSET=utf8;

CREATE TABLE IF NOT EXISTS `sendmail` (
  `id` int NOT NULL AUTO_INCREMENT,
  `serverid` int NOT NULL DEFAULT 0,
  `sender` varchar(32) NOT NULL DEFAULT '',
  `title` varchar(256) NOT NULL DEFAULT '',
  `content` varchar(512) NOT NULL DEFAULT '',
  `receiver` varchar(32) NOT NULL DEFAULT '',
  `itemlist` varchar(1024) NOT NULL DEFAULT '',
  `sendtime` int NOT NULL DEFAULT 0,
  `state`  tinyint NOT NULL DEFAULT 0 COMMENT '0:未处理; 1:已处理',
  `time` int NOT NULL DEFAULT 0,
  PRIMARY KEY (`id`)
) ENGINE=MyISAM DEFAULT CHARSET=utf8;

CREATE TABLE IF NOT EXISTS `serverlist` (
  `id` int NOT NULL PRIMARY KEY AUTO_INCREMENT,
  `serverid` int NOT NULL,
  `displayid` int  NOT NULL COMMENT '显示的区号',
  `servername` varchar(32) NOT NULL DEFAULT '',
  `gateaddr` varchar(32) NOT NULL DEFAULT '' COMMENT '服务器网关地址',
  `gmaddr` varchar(32) NOT NULL DEFAULT '' COMMENT 'GM后门:ip|port',
  `logdb` varchar(64) NOT NULL DEFAULT '' COMMENT '日志DB:ip|port|usr|pwd|db',
  `state` tinyint NOT NULL DEFAULT 0 COMMENT '可用状态:0不可用;1可用',
  `hot` tinyint NOT NULL DEFAULT 0 COMMENT '推荐状态:0普通;1推荐;2:爆满;3:维护中',
  `platform` varchar(32) NOT NULL DEFAULT '',
  `version` tinyint NOT NULL DEFAULT 0,
  `notice` varchar(1024) NOT NULL DEFAULT '' COMMENT '维护公共',
  `time` int NOT NULL DEFAULT 0 COMMENT '开服时间',
  key `key_state` (`state`)
) ENGINE=MyISAM DEFAULT CHARSET=utf8;

CREATE TABLE IF NOT EXISTS `activity` (
  `srvid` int NOT NULL DEFAULT 0,
  `actid` int NOT NULL DEFAULT 0,
  `subactid` int NOT NULL DEFAULT 0,
  `actname` varchar(64) NOT NULL DEFAULT '',
  `subactname` varchar(64) NOT NULL DEFAULT '',
  `roundid` int NOT NULL DEFAULT 0 COMMENT '轮次ID',
  `propid` int NOT NULL DEFAULT 0 COMMENT '道具ID/知己ID',
  `stime` varchar(32) NOT NULL DEFAULT '',
  `etime` varchar(32) NOT NULL DEFAULT '',
  `atime` varchar(32) NOT NULL DEFAULT '',
  `time` int NOT NULL DEFAULT 0,
  PRIMARY KEY (srvid,actid, subactid)
) ENGINE=MyISAM DEFAULT CHARSET=utf8;

CREATE TABLE IF NOT EXISTS `cdkeytype` (
  `id` int NOT NULL AUTO_INCREMENT,
  `type` int  NOT NULL DEFAULT 0,
  `name` varchar(64) NOT NULL DEFAULT '',
  `desc` varchar(128) NOT NULL DEFAULT '',
  `starttime` int  NOT NULL DEFAULT 0,
  `endtime` int  NOT NULL DEFAULT 0,
  `award` varchar(128) NOT NULL DEFAULT '',
  PRIMARY KEY (`id`)
) ENGINE=MyISAM DEFAULT CHARSET=utf8;

CREATE TABLE IF NOT EXISTS `cdkeycode` (
  `key` varchar(32) NOT NULL DEFAULT '',
  `giftid` int  NOT NULL DEFAULT 0,
  `server` int  NOT NULL DEFAULT 0,
  `charlist` text NOT NULL COMMENT '兑换过后会保存对应玩家的角色ID',
  `time` int  NOT NULL DEFAULT 0,
  PRIMARY KEY (`key`)
) ENGINE=MyISAM DEFAULT CHARSET=utf8;

CREATE TABLE IF NOT EXISTS `gamenotice` (
  `id` int NOT NULL AUTO_INCREMENT,
  `server` int NOT NULL DEFAULT 0,
  `title` varchar(128) NOT NULL DEFAULT '',
  `content` varchar(256) NOT NULL DEFAULT '',
  `time` int  NOT NULL DEFAULT 0,
  `endtime` int  NOT NULL DEFAULT 0,
  `effect` int  NOT NULL DEFAULT 1,
  PRIMARY KEY (`id`)
) ENGINE=MyISAM DEFAULT CHARSET=utf8;

CREATE TABLE IF NOT EXISTS `whitelist` (
  `account` varchar(64) NOT NULL DEFAULT '',
  `time` int NOT NULL DEFAULT 0,
  PRIMARY KEY (`account`)
) ENGINE=MyISAM DEFAULT CHARSET=utf8;