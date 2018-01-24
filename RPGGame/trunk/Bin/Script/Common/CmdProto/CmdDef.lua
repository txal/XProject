--消息类型(126-10245)
gtMsgType =
{
	eLuaRpcMsg = 1, --Rpc消息
	eLuaCmdMsg = 2, --Cmd消息
}

---------注册服务器间系统指令(126-1024)--------------------------
--126 		--注册服务到Router
--127 		--Router返回注册结果
--129 		--客户端断开
--130 		--服务断开
RegSrvSrvCmd(135, "KickClient", "")			--踢玩家下线
RegSrvSrvCmd(136, "BroadcastGate", "") 		--广播网关指令(广播全服玩家)
RegSrvSrvCmd(130, "OnServiceClose", "i") 	--服务断开


-----------------注册服务器间自定义协议(40001-50000)---------------------
RegSrvSrvCmd(40001, "PlayerLogicServiceSync", "i")	--同步玩家逻辑服到网关


-----------------注册浏览器服务器间自定义协议(50001-50100)---------------------
RegBsrCmdReq(50001, "BrowserReq", "s")	--浏览器请求服务器
RegBsrCmdRet(50002, "BrowserRet", "s")	--返回结果给浏览器


---------注册客户端服务器自定义协议(1025-8000)-----------------------
--Ping
RegCmdReq(1025, "Ping", "", 0)
RegCmdRet(1025, "Ping", "", 0)

--网关心跳处理
RegCmdReq(1100, "KeepAlive", "i", 0)
RegCmdRet(1100, "KeepAlive", "i", 0)


---------注册客户端服务器Protobuf协议(8001-40000)--------------------
--GM
RegPBReq(8001, "GMCmdReq", "global.GMCmdReq", 0)

--TEST
RegPBReq(8004, "TestPack", "global.TestPack", 0)
RegPBRet(8005, "TestPack", "global.TestPack", 0)

--NOTICE
RegPBRet(8010, "TipsMsgRet", "global.TipsMsgRet", 0)					--TIPS

--LOGIN
RegPBReq(9001, "LoginReq", "login.LoginReq", 0)							--登录请求
RegPBRet(9002, "LoginRet", "login.LoginRet", 0)							--登录返回
RegPBReq(9003, "CreateRoleReq", "login.CreateRoleReq", 0)				--创建角色请求
RegPBRet(9004, "CreateRoleRet", "login.CreateRoleRet", 0)				--创建角色返回
RegPBRet(9005, "OtherPlaceLoginRet", "login.OtherPlaceLoginRet", 0)    	--异地登录返回
RegPBReq(9006, "LogoutReq", "login.LogoutReq", 0)						--登出(注销)请求
RegPBRet(9007, "LogoutRet", "login.LogoutRet", 0)						--登出成功返回
RegPBRet(9008, "PlayerInitDataRet", "login.PlayerInitDataRet", 0)		--角色初始数据同步
RegPBRet(9009, "PlayerCurrSync", "login.PlayerCurrSync", 0)				--角色初始数据同步

--广东麻将房间
RegPBReq(9020, "CreateRoomReq", "room.CreateRoomReq", 0)						--创建房间请求
RegPBReq(9021, "JoinRoomReq", "room.JoinRoomReq", 0)							--加入房间请求
RegPBRet(9022, "JoinRoomRet", "room.JoinRoomRet", 0)							--进入房间返回
RegPBRet(9023, "PlayerJoinBroadcast", "room.PlayerJoinBroadcast", 0)			--玩家进入房间消息,广播给房间内其他玩家
RegPBReq(9024, "LeaveRoomReq", "room.LeaveRoomReq", 0)							--离开房间请求
RegPBRet(9025, "LeaveRoomRet", "room.LeaveRoomRet", 0)							--离开房间成功返回
RegPBRet(9026, "PlayerLeaveBroadcast", "room.PlayerLeaveBroadcast", 0)			--玩家离开房间消息,广播给房间内其他玩家
RegPBRet(9027, "PlayerOfflineBroadcast", "room.PlayerOfflineBroadcast", 0)		--玩家离线消息,广播给房间内其他玩家
RegPBReq(9028, "PlayerReadyReq", "room.PlayerReadyReq", 0)						--玩家准备请求
RegPBRet(9029, "PlayerReadyBroadcast", "room.PlayerReadyBroadcast", 0) 			--玩家准备消息,广播给房间内所有玩家(包括自己)
RegPBReq(9030, "DismissRoomReq", "room.DismissRoomReq", 0)						--解散房间请求
RegPBRet(9031, "DismissRoomBroadcast", "room.DismissRoomBroadcast", 0)			--解散房间消息,广播给房间内所有玩家(包括自己)
RegPBRet(9032, "AskDismissRoomBroadcast", "room.AskDismissRoomBroadcast", 0)	--解散房间询问广播
RegPBReq(9033, "AgreeDismissRoomReq", "room.AgreeDismissRoomReq", 0)			--是否同意解散房间回复
RegPBRet(9034, "PlayerOnlineBroadcast", "room.PlayerOnlineBroadcast", 0)		--玩家上线消息,广播给房间内其他玩家

--广东麻将推倒胡
RegPBRet(9060, "SendMJRet", "room.SendMJRet", 0)					--发牌通知
RegPBRet(9061, "SwitchPlayerRet", "room.SwitchPlayerRet", 0)		--切换玩家通知
RegPBRet(9062, "TouchMJRet", "room.TouchMJRet", 0)					--摸牌通知
RegPBReq(9063, "OutMJReq", "room.OutMJReq", 0)						--出牌请求
RegPBRet(9064, "OutMJRet", "room.OutMJRet", 0)						--出牌通知
RegPBReq(9065, "PengReq", "room.PengReq", 0)						--碰请求
RegPBRet(9066, "PengRet", "room.PengRet", 0)						--碰通知
RegPBReq(9067, "GangReq", "room.GangReq", 0)						--杠请求
RegPBRet(9068, "GangRet", "room.GangRet", 0)						--杠通知
RegPBReq(9069, "GangSelectRet", "room.GangSelectRet", 0)			--杠选择询问
RegPBRet(9070, "GangSelectReq", "room.GangSelectReq", 0)			--选择杠请求
RegPBReq(9071, "HuReq", "room.HuReq", 0)							--胡请求
RegPBRet(9072, "HuRet", "room.HuRet", 0)							--胡通知
RegPBReq(9073, "GiveUpReq", "room.GiveUpReq", 0)					--放弃请求
RegPBRet(9074, "OperationRet", "room.OperationRet", 0)				--可操作通知
RegPBRet(9075, "QiangGangRet", "room.QiangGangRet", 0)				--抢杠胡通知
RegPBRet(9076, "FollowMJRet", "room.FollowMJRet", 0)				--跟庄通知
RegPBRet(9077, "TouchGhostRet", "room.TouchGhostRet", 0)			--翻鬼通知
RegPBRet(9078, "RoundEndRet", "room.RoundEndRet", 0)				--一局结束
RegPBRet(9079, "GameEndRet", "room.GameEndRet", 0)					--一盘结束
RegPBRet(9080, "RecoverDeskRet", "room.RecoverDeskRet", 0)			--恢复牌局
RegPBRet(9081, "GiveUpRet", "room.GiveUpRet", 0)					--玩家放弃成功返回

--广东麻将自由房匹配相关
RegPBReq(9110, "FreeRoomEnterReq", "room.FreeRoomEnterReq", 0) 		--自由房进入请求
RegPBRet(9111, "FreeRoomEnterRet", "room.FreeRoomEnterRet", 0) 		--自由房进入返回
RegPBReq(9112, "FreeRoomLeaveReq", "room.FreeRoomLeaveReq", 0) 		--自由房离开请求
RegPBRet(9113, "FreeRoomLeaveRet", "room.FreeRoomLeaveRet", 0) 		--自由房离开返回
RegPBReq(9114, "FreeRoomMatchReq", "room.FreeRoomMatchReq", 0) 		--自由房匹配请求
RegPBReq(9115, "FreeRoomSwitchReq", "room.FreeRoomSwitchReq", 0) 	--自由房切换房间请求
RegPBRet(9116, "FreeRoomTiliLimitRet", "room.FreeRoomTiliLimitRet", 0)	--自由房体力不足通知
RegPBReq(9117, "FreeRoomFullTiliReq", "room.FreeRoomFullTiliReq", 0) 	--自由房补充体力请求
RegPBRet(9118, "FreeRoomFullTiliRet", "room.FreeRoomFullTiliRet", 0) 	--自由场补充体力成功返回
RegPBRet(9119, "FreeRoomWinRoundRet", "room.FreeRoomWinRoundRet", 0) 	--自由场连胜对局信息更新
RegPBRet(9120, "FreeRoomEnterAIRet", "room.FreeRoomEnterAIRet", 0) 		--自由场进入托管通知
RegPBReq(9121, "FreeRoomCancelAIReq", "room.FreeRoomCancelAIReq", 0) 	--自由场取消托管通知

--大厅
RegPBReq(9150, "HallCreateRoomReq", "room.HallCreateRoomReq", 0) 	--大厅创建房间请求
RegPBReq(9151, "HallJoinRoomReq", "room.HallJoinRoomReq", 0) 		--大厅加入房间请求
RegPBReq(9152, "HallClickGameReq", "room.HallClickGameReq", 0) 		--大厅点击游戏图标(自由场)
RegPBReq(9153, "HallEtcReq", "room.HallEtcReq", 0) 	--大厅杂项请求
RegPBRet(9154, "HallEtcRet", "room.HallEtcRet", 0) 	--大厅杂项返回

--牛牛房间
RegPBRet(9500, "NNJoinRoomRet", "niuniu.NNJoinRoomRet", 0)			--进入房间返回
