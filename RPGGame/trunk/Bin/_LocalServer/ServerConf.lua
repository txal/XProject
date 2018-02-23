gnServerID=1 --[1-100]:测试服; [1001-32767]:正式服
gnWorldServerID=10000
gsGamePrefix = "mengzhu"
gbInnerServer=false

------------------------------------------------------------------------------本服配置
gtServerConf=
{
	--路由服务
	tRouterService={ {nID=1, sIP="127.0.0.1", nPort=8600},},

	--SSDB数据库(游戏数据)
	tGameDB=
	{
		["center"]={nServer=0, sIP="127.0.0.1", nPort=7000,}, --唯一ID生成数据库
		["global"]={nServer=gnServerID, sIP="127.0.0.1", nPort=9100,},	--本服全局数据(排行榜,活动,帮会等)
		["user"]={
			{nServer=gnServerID, sIP="127.0.0.1", nPort=9101,},
		},	 --玩家自身数据
	},
	--MYSQL数据库(日志数据)
	tLogDB={ sIP="127.0.0.1", nPort=3306, sDBName=gsGamePrefix.."_s"..gnServerID, sUserName="root",sPassword="11",},
	
	
	--网关服务
    tGateService={ {nServer=gnServerID, nID=10, nPort=9102, nMaxConns=20000, nSecureCPM=120, nSecureQPM=180, nSecureBlock=60, nDeadLinkTime=120},},
	--全局服务
    tGlobalService={ {nID=20, sIP="127.0.0.1", nPort=9103},},
	--日志服务
    tLogService={ {nServer=gnServerID, nID=30, nWorkers=4 },},
	--登录服务
    tLoginService={ {nID=40}, },
	--场景服务
    tLogicService={ {nID=50}, },
}

-----------------------------世界服配置
gtWorldConf =
{
    tLogicService={{nID=100, },},
	tGlobalService={{nID=110, },},
}

--后台MYSQL
gtMgrMysqlConf=
{
    sIP="127.0.0.1",
    nPort=3306,
    sDBName=gsGamePrefix.."_mgr",
    sUserName="root",
    sPassword="11",
}
