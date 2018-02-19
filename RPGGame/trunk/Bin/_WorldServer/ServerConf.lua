gnServerID=10000
gbInnerServer=false

------------------------------------------------------------------------------世界服配置
gtServerConf =
{
	--SSDB数据库(游戏数据)
	tGameDB=
	{
		["center"]={sIP="127.0.0.1", nPort=7000, nServer=0}, --唯一ID生成数据库
		["global"]={sIP="127.0.0.1", nPort=8100, nServer=gnServerID}, --世界全局数据(跨服数据)
	},
	--世界全局服务
    tGlobalService={{nID=100},},
	--世界场景服务
    tLogicService={{nID=110},},
	
	--路由服务
	tRouterService={{nID=1, sIP="127.0.0.1", nPort=8600},},
	
	--各服网关列表
	tGateService={{nID=10, nServer=1,},},
	--各服日志列表
	tLogService={{nID=30, nServer=1},}
}