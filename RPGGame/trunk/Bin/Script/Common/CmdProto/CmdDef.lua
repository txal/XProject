--消息类型(126-10245)
gtMsgType =
{
	eLuaRpcMsg = 1, --Rpc消息
	eLuaCmdMsg = 2, --Cmd消息
}

---------注册服务器间系统指令(126-1024)--------------------------
-- ssRegServiceReq = 126,			--注册服务到Router
-- ssRegServiceRet = 127,			--Router返回注册结果
RegSrvSrvCmd(129, "OnClientClose", "") 	    --客户端断开(网关->游戏服务)
RegSrvSrvCmd(130, "OnServiceClose", "ii") 	--服务断开(路由->所有服务)
RegSrvSrvCmd(136, "BroadcastGate", "") 		--广播网关指令(广播全服玩家)
RegSrvSrvCmd(135, "KickClientReq", "")		--踢玩家下线(游戏服务->网关)


-----------------注册服务器间自定义协议(40001-50000)---------------------
RegSrvSrvCmd(40001, "SyncRoleLogic", "")	--同步角色逻辑服到网关


-----------------注册浏览器服务器间自定义协议(50001-50100)---------------------
RegBsrCmdReq(50001, "BrowserReq", "s")	--浏览器请求服务器
RegBsrCmdRet(50002, "BrowserRet", "s")	--返回结果给浏览器


---------注册客户端服务器自定义协议(1025-8000)-----------------------
--PING
RegCmdReq(1025, "Ping", "", 10)
RegCmdRet(1025, "Ping", "", 0)

--网关心跳处理
RegCmdReq(1100, "KeepAlive", "i", 0)
RegCmdRet(1100, "KeepAlive", "i", 0)

---------注册客户端服务器PROTOBUF协议(8001-40000)--------------------
--全局
RegPBReq(8001, "TestPack", "global.TestPack", 50)		--测试包请求
RegPBRet(8002, "TestPack", "global.TestPack", 0)		--测试包返回

RegPBReq(8003, "GMCmdReq", "global.GMCmdReq", 20)		--GM指令	
RegPBRet(8004, "TipsMsgRet", "global.TipsMsgRet", 0)	--通用飘字提示
RegPBRet(8005, "NoticeRet", "global.NoticeRet", 0)		--滚动公告返回
RegPBRet(8006, "YBDlgRet", "global.YBDlgRet", 0)		--元宝不足弹框

--LOGIN
RegPBReq(9000, "RoleListReq", "login.RoleListReq", 40)             --角色列表请求
RegPBRet(9001, "RoleListRet", "login.RoleListRet", 0)              --角色列表返回
RegPBReq(9002, "RoleLoginReq", "login.RoleLoginReq", 40)           --角色登录请求
RegPBRet(9003, "RoleLoginRet", "login.RoleLoginRet", 0)            --角色登成功返回
RegPBReq(9004, "RoleCreateReq", "login.RoleCreateReq", 40)         --创建角色请求
RegPBRet(9005, "OtherPlaceLoginRet", "login.OtherPlaceLoginRet", 0)--异地登录返回

--角色
RegPBRet(9050, "RoleInitDataRet", "login.RoleInitDataRet", 0)		--角色初始数据同步
RegPBRet(9051, "RoleCurrencyRet", "login.RoleCurrencyRet", 0)		--角色货币同步
