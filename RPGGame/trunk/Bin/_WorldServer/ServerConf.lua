gnServerID=10000
gbInnerServer=false

------------------------------------------------------------------------------世界服配置
gtServerConf
{
	--SSDB数据库(游戏数据)
	tGameDB=
	{
		["center"]={sIP="192.168.0.9", nPort=7500, nServer=0} --唯一ID生成数据库
		["global"]={sIP="127.0.0.1", nPort=8100, nServer=gnServerID}, --跨服全局数据(跨服聊天,组队关系,跨服好友)
	},
	--全局服务
    tGlobalService={ {nID=100, sIP="192.168.3.182", nPort=8101} },
	--场景服务
    tLogicService=
	{
		{nID=105}, 
	},
	--路由服务
	tRouterService=
	{
		{nID=1, sIP="127.0.0.1", nPort=8600},
	},
	
	--各服网关列表: {{nID=0,nServer=0},...}
	tGateService=
	{
		{nServer=1, nID=10},
	},
	--各服日志列表: {{nID=0,nServer=0},...}
	tLogService=
	{
		{nServer=1, nID=30},
	},
}