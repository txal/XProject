gnServerID=10000
gbInnerServer=false

------------------------------------------------------------------------------世界服配置
gtServerConf =
{
	--路由服务
	tRouterService={{nID=1, sIP="127.0.0.1", nPort=10001},},
	
	--SSDB数据库(游戏数据)
	tGameDB=
	{
		["center"]={nServer=0, sIP="127.0.0.1", nPort=7100}, --唯一ID生成数据库
		["global"]={nServer=gnServerID, sIP="127.0.0.1", nPort=1021}, --世界全局数据(跨服数据)
		["user"]={
			{nServer=1, sIP="127.0.0.1", nPort=10012},
		},	 --各服玩家自身数据
	},
	--世界场景服务
    tLogicService={{nID=100},},

	--各服全局服务列表(包括世界服的)
    tGlobalService={{nServer=gnServerID, nID=110}, {nServer=1, nID=20}},
	--各服网关列表(世界服没有)
	tGateService={{nServer=1, nID=10,},},
	--各服日志列表(世界服没有)
	tLogService={{nServer=1, nID=30,},}
	--各服登录服列表(世界服没有)
	tLoginService={{nServer=1, nID=40,},}
}

--取登录服ID
function gtServerConf:GetLoginService(nServer)
	for _, tConf in pairs(self.tLoginService) do
		if tConf.nServer == nServer then return tConf.nID end
	end
end