--消息类型(126-10245)
gtMsgType =
{
	eLuaRpcMsg = 1, --Rpc消息
	eLuaCmdMsg = 2, --Cmd消息
}

---------注册服务器间系统指令(126-1024)--------------------------
-- ssRegServiceReq = 126,			--注册服务到Router
-- ssRegServiceRet = 127,			--Router返回注册结果
RegSrvSrvCmd(129, "OnClientClose", "ii") 	--客户端断开(网关->游戏服务)
RegSrvSrvCmd(130, "OnServiceClose", "ii") 	--服务断开(路由->所有服务)
RegSrvSrvCmd(136, "BroadcastGate", "") 		--广播网关指令(广播全服玩家)
RegSrvSrvCmd(135, "KickClient", "")			--踢玩家下线(游戏服务->网关)


-----------------注册服务器间自定义协议(40001-50000)---------------------
RegSrvSrvCmd(40001, "SyncPlayerLogicService", "i")	--同步玩家逻辑服到网关


-----------------注册浏览器服务器间自定义协议(50001-50100)---------------------
RegBsrCmdReq(50001, "BrowserReq", "s")	--浏览器请求服务器
RegBsrCmdRet(50002, "BrowserRet", "s")	--返回结果给浏览器


---------注册客户端服务器自定义协议(1025-8000)-----------------------
--PING
RegCmdReq(1025, "Ping", "", 0)
RegCmdRet(1025, "Ping", "", 0)

--网关心跳处理
RegCmdReq(1100, "KeepAlive", "i", 0)
RegCmdRet(1100, "KeepAlive", "i", 0)

---------注册客户端服务器PROTOBUF协议(8001-40000)--------------------
--全局
RegPBReq(8001, "TestPack", "global.TestPack", 0)		--测试包请求
RegPBRet(8002, "TestPack", "global.TestPack", 0)		--测试包返回

RegPBReq(8003, "GMCmdReq", "global.GMCmdReq", 31)		--GM指令	
RegPBRet(8004, "TipsMsgRet", "global.TipsMsgRet", 0)	--通用飘字消息提示
RegPBRet(8005, "NoticeRet", "global.NoticeRet", 0)		--公告返回
RegPBRet(8006, "YBDlgRet", "global.YBDlgRet", 0)		--元宝不足弹框
RegPBRet(8007, "IconTipsRet", "global.IconTipsRet", 0)	--图标飘字

--LOGIN
RegPBReq(8030, "LoginReq", "login.LoginReq", 0)                      	--登陆请求
RegPBRet(8031, "LoginRet", "login.LoginRet", 0)                      	--登陆返回
RegPBReq(8032, "CreateRoleReq", "login.CreateRoleReq", 0)            	--创角请求
RegPBRet(8033, "CreateRoleRet", "login.CreateRoleRet", 0)            	--创角返回
RegPBRet(8034, "OtherPlaceLoginRet", "login.OtherPlaceLoginRet", 0)  	--异地登录
RegPBReq(8035, "LogoutReq", "login.LogoutReq", 0)						--登出(注销)请求
RegPBRet(8036, "LogoutRet", "login.LogoutRet", 0)						--登出(注销)成功返回
RegPBReq(8037, "UpgradeReq", "login.UpgradeReq", 0)						--国家进阶请求
RegPBRet(8038, "PlayerLevelRet", "login.PlayerLevelRet", 0)				--国家等级/经验返回

--角色
RegPBRet(8060, "PlayerInitDataSync", "login.PlayerInitDataSync", 0)		--角色初始数据同步
RegPBRet(8061, "PlayerCurrSync", "login.PlayerCurrSync", 0)				--角色货币同步

RegPBReq(8062, "PlayerInfoReq", "login.PlayerInfoReq", 0)		--请求玩家信息
RegPBRet(8063, "PlayerInfoRet", "login.PlayerInfoRet", 0)		--玩家信息返回

RegPBReq(8064, "PlayerModNameReq", "login.PlayerModNameReq", 0)		--玩家改名请求
RegPBRet(8065, "PlayerModNameRet", "login.PlayerModNameRet", 0)		--改名成功返回
