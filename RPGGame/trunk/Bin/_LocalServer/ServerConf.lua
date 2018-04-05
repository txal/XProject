gnServerID=1 --[1-100]:测试服; [1001-32767]:正式服
gnWorldServerID=10000
gsGamePrefix = "mengzhu"
gbInnerServer=false

------------------------------------------------------------------------------本服配置
gtServerConf=
{
	--路由服务
	tRouterService={ {nID=1, sIP="127.0.0.1", nPort=10001},},

	--游戏SSDB
	tGameDB=
	{
		--唯一ID生成数据库
		["center"]={nServer=0, sIP="127.0.0.1", nPort=7100,},
		--本服全局数据(排行榜,活动,帮会等)
		["global"]={nServer=gnServerID, sIP="127.0.0.1", nPort=10011,},
		--玩家自身数据
		["user"]={
			{nServer=gnServerID, sIP="127.0.0.1", nPort=10012,},
		},
	},
	--日志MYSQL
	tLogDB={ sIP="127.0.0.1", nPort=3306, sDBName=gsGamePrefix.."_s"..gnServerID, sUserName="root",sPassword="123456",},
	
	
	--网关服务
    tGateService={ {nServer=gnServerID, nID=10, nPort=10013, nMaxConns=20000, nSecureCPM=120, nSecureQPM=180, nSecureBlock=60, nDeadLinkTime=120},},
	--全局服务
    tGlobalService={ {nServer=gnServerID, nID=20, sIP="127.0.0.1", nPort=10014},},
	--日志服务
    tLogService={ {nServer=gnServerID, nID=30, nWorkers=4 },},
	--登录服务
    tLoginService={ {nServer=gnServerID, nID=40}, },
	--场景服务
    tLogicService={ {nServer=gnServerID, nID=50}, },
}

-----------------------------世界服配置
gtWorldConf =
{
    tLogicService={{nServer=gnWorldServerID, nID=100, },},
	tGlobalService={{nServer=gnWorldServerID, nID=110, },},
}

----------------------------后台MYSQL
gtMgrMysqlConf=
{
    sIP="127.0.0.1",
    nPort=3306,
    sDBName=gsGamePrefix.."_mgr",
    sUserName="root",
    sPassword="123456",
}


------------------------------辅助函数
--取登录服ID
function gtServerConf:GetLoginService(nServer)
	local tService =self.tLoginService[1]
	assert(tService.nServer == nServer)
	return tService.nID
end

--取日志服ID
function gtServerConf:GetLogService(nServer)
	local tService = self.tLogService[1]
	assert(tService.nServer == nServer)
	return tService.nID
end

--取日志服列表
function gtServerConf:GetLogServiceList()
	return self.tLogService
end

--取[W]GLOBAL服务ID
function gtServerConf:GetGlobalService(nServer)
	if nServer == gnServerID then
		return self.tGlobalService[1].nID
	end

	if nServer == gnWorldServerID then
		return gtWorldConf.tGlobalService[1].nID
	end
	return 0
end

--取[W]GLOBAL服务列表
function gtServerConf:GetGlobalServiceList()
	local tGlobalServiceList = {}
	for _, tConf in pairs(self.tGlobalService) do
		table.insert(tGlobalServiceList, tConf)
	end
	for _, tConf in pairs(gtWorldConf.tGlobalService) do
		table.insert(tGlobalServiceList, tConf)
	end
	return tGlobalServiceList
end
