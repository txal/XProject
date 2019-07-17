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
RegSrvSrvCmd(135, "KickClientReq", "")		--踢玩家下线(游戏服务->网关)
RegSrvSrvCmd(136, "BroadcastGate", "") 		--广播网关指令(广播全服玩家)
RegSrvSrvCmd(137, "ClientIPReq", "") 		--客户端IP请求
RegSrvSrvCmd(138, "ClientIPRet", "") 		--客户端IP返回
RegSrvSrvCmd(139, "ClientLastPacketTimeRet", "ii")	--客户端最后包时间同步
RegSrvSrvCmd(140, "CloseServerReq", "ii")	--关服请求
RegSrvSrvCmd(141, "PrepCloseServer", "ii")	--关服准备,准备完成通知
RegSrvSrvCmd(142, "ImplCloseServer", "ii")	--执行关服通知


-----------------注册服务器间自定义协议(40001-50000)---------------------
RegSrvSrvCmd(40001, "SyncRoleLogic", "ii")	--同步角色逻辑服到网关
RegSrvSrvCmd(40002, "Srv2SrvCmdTestReq", "q")	--测试1
RegSrvSrvCmd(40003, "Srv2SrvCmdTestRet", "q")	--测试2


-----------------注册浏览器服务器间自定义协议(50001-50100)---------------------
RegBsrCmdReq(50001, "BrowserReq", "s")	--浏览器请求服务器
RegBsrCmdRet(50002, "BrowserRet", "s")	--返回结果给浏览器


---------注册客户端服务器自定义协议(1025-8000)-----------------------
--PING
RegCmdReq(1025, "Ping", "", 0)
RegCmdRet(1025, "Ping", "", 0)

--网关心跳处理
RegCmdReq(1100, "KeepAlive", "ii", 0)
RegCmdRet(1100, "KeepAlive", "i", 0)

---------注册客户端服务器PROTOBUF协议(8001-40000)--------------------
--panda [8001-13000]
--全局
RegPBReq(8001, "TestPack", "global.TestPack", 50)		--测试包请求
RegPBRet(8002, "TestPack", "global.TestPack", 0)		--测试包返回

RegPBReq(8003, "GMCmdReq", "global.GMCmdReq", 20)		--GM指令
RegPBRet(8004, "TipsMsgRet", "global.TipsMsgRet", 0)	--通用飘字提示

RegPBRet(8006, "ConfirmRet", "global.ConfirmRet", 0)				--通知客户端弹确认框
RegPBReq(8007, "ConfirmReactReq", "global.ConfirmReactReq", 0)		--客户端确认框反馈请求

RegPBRet(8008, "ItemConfirmRet", "global.ItemConfirmRet", 0)				--物品消耗通知客户端弹确认框
RegPBReq(8009, "ItemConfirmReactReq", "global.ItemConfirmReactReq", 0)		--物品消耗客户端确认框反馈请求

RegPBRet(8010, "GoldAllNotEnoughtRet", "global.GoldAllNotEnoughtRet", 0)--元宝不足通知
RegPBRet(8011, "JinBiNotEnoughtRet", "global.JinBiNotEnoughtRet", 0)	--金币不足通知
RegPBRet(8012, "YinBiNotEnoughtRet", "global.YinBiNotEnoughtRet", 0)	--银币不足通知
RegPBRet(8013, "PropNotEnoughtRet", "global.PropNotEnoughtRet", 0)		--道具不足通知
RegPBRet(8014, "MagicPillNotEnoughtRet", "global.MagicPillNotEnoughtRet", 0) --内丹不足通知


--登陆
RegPBReq(9000, "RoleListReq", "login.RoleListReq", 40)             --角色列表请求
RegPBRet(9001, "RoleListRet", "login.RoleListRet", 0)              --角色列表返回
RegPBReq(9002, "RoleLoginReq", "login.RoleLoginReq", 40)           --角色登录请求
RegPBRet(9003, "RoleLoginRet", "login.RoleLoginRet", 0)            --角色登成功返回
RegPBReq(9004, "RoleCreateReq", "login.RoleCreateReq", 40)         --创建角色请求
RegPBRet(9005, "OtherPlaceLoginRet", "login.OtherPlaceLoginRet", 0)--异地登录返回
RegPBRet(9006, "RoleLoginQueueRet", "login.RoleLoginQueueRet", 0) 	--登录排队返回

--角色
RegPBRet(9050, "RoleInitDataRet", "login.RoleInitDataRet", 0)		--角色初始数据同步
RegPBRet(9051, "RoleCurrencyRet", "login.RoleCurrencyRet", 0)		--角色货币同步
RegPBReq(9052, "RoleAttrReq", "role.RoleAttrReq", 0)				--角色属性请求
RegPBRet(9053, "RoleAttrRet", "role.RoleAttrRet", 0)				--角色属性返回
RegPBReq(9054, "RoleModNameReq", "role.RoleModNameReq", 0)			--角色改名请求
RegPBRet(9055, "RoleModNameRet", "role.RoleModNameRet", 0)			--角色改名成功返回
RegPBRet(9056, "RoleLevelRet", "login.RoleLevelRet", 0)				--角色等级同步
RegPBRet(9057, "RoleBattleAttrChangeRet", "role.RoleBattleAttrChangeRet", 0)--角色战斗属性变化通知
RegPBRet(9058, "MainWindowHeadInfoRet", "role.MainWindowHeadInfoRet", 0) --主界面角色/宠物信息
RegPBRet(9059, "RolePowerSyncRet", "role.RolePowerSyncRet", 0) --战力同步
RegPBReq(9060, "RoleStuckLevelReq", "role.RoleStuckLevelReq", 0) --卡等级请求
RegPBRet(9061, "RoleStuckLevelRet", "role.RoleStuckLevelRet", 0) --卡等级返回
RegPBReq(9062, "RoleServerLvReq", "role.RoleServerLvReq", 0) 	--服务器等级请求
RegPBRet(9063, "RoleServerLvRet", "role.RoleServerLvRet", 0) 	--服务器等级请求返回
RegPBRet(9064, "RoleColligatePowerSyncRet", "role.RoleColligatePowerSyncRet", 0) --综合战力同步
RegPBReq(9065, "RoleBehaviourReq", "role.RoleBehaviourReq", 30) 	--角色行为



--场景
RegPBReq(9100, "RoleEnterSceneReq", "scene.RoleEnterSceneReq", 0)   --角色进入场景请求
RegPBRet(9101, "RoleEnterSceneRet", "scene.RoleEnterSceneRet", 0)   --角色进入场景返回
RegPBReq(9102, "RoleLeaveSceneReq", "scene.RoleLeaveSceneReq", 0)   --角色离开副本请求
RegPBRet(9103, "RoleLeaveSceneRet", "scene.RoleLeaveSceneRet", 0)   --角色离开副本返回
RegPBRet(9104, "RoleEnterViewRet", "scene.RoleEnterViewRet", 0)     --角色进入视野返回
RegPBRet(9105, "MonsterEnterViewRet", "scene.MonsterEnterViewRet", 0)   --怪物进入视野返回
RegPBRet(9106, "ObjLeaveViewRet", "scene.ObjLeaveViewRet", 0)       	--对象离开视野返回
RegPBRet(9107, "RoleViewFlushRet", "scene.RoleViewFlushRet", 0)       	--角色视野信息刷新返回
RegPBRet(9108, "MonsterFlushViewRet", "scene.MonsterFlushViewRet", 0)       	--怪物场景表现刷新

--背包
RegPBRet(9200, "KnapsackItemListRet", "knapsack.KnapsackItemListRet", 0)		--道具列表返回
RegPBRet(9201, "KnapsackItemAddRet", "knapsack.KnapsackItemAddRet", 0)			--道具增加通知
RegPBRet(9202, "KnapsackItemRemoveRet", "knapsack.KnapsackItemRemoveRet", 0)	--道具删除通知
RegPBRet(9203, "KnapsackItemModRet", "knapsack.KnapsackItemModRet", 0)			--道具数量变更通知
RegPBReq(9204, "KnapsackUseItemReq", "knapsack.KnapsackUseItemReq", 0)			--道具使用请求
RegPBReq(9205, "KnapsackArrangeReq", "knapsack.KnapsackArrangeReq", 0)			--整理背包请求
RegPBReq(9206, "KnapsackBuyGridReq", "knapsack.KnapsackBuyGridReq", 0)			--购买格子请求
RegPBRet(9207, "KnapsackBuyGridRet", "knapsack.KnapsackBuyGridRet", 0)			--购买格子成功返回
RegPBReq(9208, "KnapsackPutStorageReq", "knapsack.KnapsackPutStorageReq", 0)		--存入仓库请求
RegPBReq(9209, "KnapsackGetStorageReq", "knapsack.KnapsackGetStorageReq", 0)		--提取仓库请求
RegPBReq(9210, "KnapsackSellItemReq", "knapsack.KnapsackSellItemReq", 0)			--出售物品请求
RegPBReq(9211, "KnapsacGetPetEquReq", "knapsack.KnapsacGetPetEquReq", 0)			--取多个宠物装备属性请求请求
RegPBRet(9212, "KnapsacGetPetEquRet", "knapsack.KnapsacGetPetEquRet", 0)			--取多个宠物装备属性请求请求返回
RegPBReq(9213, "KnapsackSellItemListReq", "knapsack.KnapsackSellItemListReq", 0) 	--出售道具列表请求
RegPBRet(9214, "KnapsackSaleYuanbaoRecordRet", "knapsack.KnapsackSaleYuanbaoRecordRet", 0) 	--道具出售元宝限额通知
RegPBReq(9215, "KnapsackItemSalePriceReq", "knapsack.KnapsackItemSalePriceReq", 0) 	--道具出售价格查询
RegPBRet(9216, "KnapsackItemSalePriceRet", "knapsack.KnapsackItemSalePriceRet", 0) 	--道具出售价格返回


--战斗
RegPBReq(9249, "BattleStartReq", "battle.BattleStartReq", 0) --开始战斗请求
RegPBRet(9250, "BattleStartRet", "battle.BattleStartRet", 0) --开始战斗返回
RegPBRet(9251, "RoundBeginRet", "battle.RoundBeginRet", 0) --回合开始范湖
RegPBReq(9252, "UnitInstReq", "battle.UnitInstReq", 0) --单位下达指令请求
RegPBRet(9253, "UnitInstRet", "battle.UnitInstRet", 0) --单位下达指令成功返回
RegPBRet(9254, "RoundDataRet", "battle.RoundDataRet", 0) --回合数据返回
RegPBRet(9255, "BattleEndRet", "battle.BattleEndRet", 0) --战斗结束返回
RegPBReq(9256, "BattleSkillListReq", "battle.BattleSkillListReq", 0) --战斗技能请求
RegPBRet(9257, "BattleSkillListRet", "battle.BattleSkillListRet", 0) --战斗技能返回

RegPBReq(9258, "BattlePropListReq", "battle.BattlePropListReq", 0) 	--战斗物品请求
RegPBRet(9259, "BattlePropListRet", "battle.BattlePropListRet", 0) 	--战斗物品返回
RegPBReq(9260, "RoundPlayFinishReq", "battle.RoundPlayFinishReq", 0) --客户端播放回合完成请求
RegPBRet(9261, "BattlePreloadSkillRet", "battle.BattlePreloadSkillRet", 0) --战斗预加载技能返回
RegPBReq(9262, "BattlePetListReq", "battle.BattlePetListReq", 0) --宠物列表请求
RegPBRet(9263, "BattlePetListRet", "battle.BattlePetListRet", 0) --宠物列表返回
RegPBReq(9264, "BattleEscapeFinishReq", "battle.BattleEscapeFinishReq", 0) --客户端播放单位逃跑完成请求

RegPBReq(9265, "BattleAutoInstListReq", "battle.BattleAutoInstListReq", 0) --自动战斗可操作列表请求
RegPBRet(9266, "BattleAutoInstListRet", "battle.BattleAutoInstListRet", 0) --自动战斗可操作列表返回
RegPBReq(9267, "BattleSetAutoInstReq", "battle.BattleSetAutoInstReq", 0) --自动战斗设置指令请求
RegPBRet(9268, "BattleSetAutoInstRet", "battle.BattleSetAutoInstRet", 0) --自动战斗已设置指令返回

RegPBReq(9270, "BattleCommandInfoReq", "battle.BattleCommandInfoReq", 0) --战斗指挥信息请求
RegPBRet(9271, "BattleCommandInfoRet", "battle.BattleCommandInfoRet", 0) --战斗指挥信息返回
RegPBReq(9272, "ChangeBattleCommandReq", "battle.ChangeBattleCommandReq", 0) --编辑战斗指挥请求
RegPBRet(9273, "ChangeBattleCommandRet", "battle.ChangeBattleCommandRet", 0) --成功编辑战斗指挥请求
RegPBReq(9274, "SetBattleCommandReq", "battle.SetBattleCommandReq", 0) --设置战斗指挥
RegPBRet(9275, "SetBattleCommandRet", "battle.SetBattleCommandRet", 0) --设置战斗指挥成功广播




--门派技能
RegPBReq(9350, "SkillListReq", "skill.SkillListReq", 0) --列表请求
RegPBRet(9351, "SkillListRet", "skill.SkillListRet", 0) --列表返回
RegPBReq(9352, "SkillUpgradeReq", "skill.SkillUpgradeReq", 0) --升级请求
RegPBReq(9353, "SkillOnekeyUpgradeReq", "skill.SkillOnekeyUpgradeReq", 0) --1键升级请求
RegPBReq(9354, "SkillManufactureItemReq", "skill.SkillManufactureItemReq", 0) --制造附魔符请求


--阵法
RegPBReq(9400, "FmtListReq", "formation.FmtListReq", 0) --阵法列表请求
RegPBRet(9401, "FmtListRet", "formation.FmtListRet", 0) --阵法列表返回
RegPBReq(9402, "FmtBuyReq", "formation.FmtBuyReq", 0) --购买上限请求
RegPBReq(9403, "FmtUseReq", "formation.FmtUseReq", 0) --启用阵法请求
RegPBReq(9404, "FmtUpgradeReq", "formation.FmtUpgradeReq", 0) --提升阵法请求

--角色洗点
RegPBReq(9420, "RWPlanInfoReq", "rolewash.RWPlanInfoReq", 0) --方案信息请求
RegPBRet(9421, "RWPlanInfoRet", "rolewash.RWPlanInfoRet", 0) --方案信息返回
RegPBReq(9422, "RWSavePlanReq", "rolewash.RWSavePlanReq", 0) --保存当前方案请求
RegPBReq(9423, "RWUsePlanReq", "rolewash.RWUsePlanReq", 0) --启用方案请求
RegPBReq(9424, "RWResetInfoReq", "rolewash.RWResetInfoReq", 0) --洗点信息请求
RegPBRet(9425, "RWResetInfoRet", "rolewash.RWResetInfoRet", 0) --洗点信息返回
RegPBReq(9426, "RWResetReq", "rolewash.RWResetReq", 0) --洗点请求
RegPBReq(9427, "RWSetRecommandPlanReq", "rolewash.RWSetRecommandPlanReq", 0) --设置推荐方案和自动加点否

--系统开放控制
RegPBRet(9440, "OpenSysListRet", "sysopen.OpenSysListRet", 0) --系统已开放列表(登陆推)
RegPBRet(9441, "SysOpenRet", "sysopen.SysOpenRet", 0) --新系统开放通知

--修炼系统
RegPBReq(9460, "PracticeInfoReq", "practice.PracticeInfoReq", 0) --修炼列表请求
RegPBRet(9461, "PracticeInfoRet", "practice.PracticeInfoRet", 0) --修炼列表返回
RegPBReq(9462, "PracticeLearnReq", "practice.PracticeLearnReq", 0) --修炼学习请求
RegPBReq(9463, "PracticeUsePropReq", "practice.PracticeUsePropReq", 0) --使用修炼丹请求
RegPBReq(9464, "PracticeSetDefaultReq", "practice.PracticeSetDefaultReq", 0) --设置默认修炼

--队伍系统
RegPBReq(9479, "CreateTeamReq", "team.CreateTeamReq", 110)	--创建队伍请求
RegPBReq(9480, "TeamReq", "team.TeamReq", 110)	--队伍信息请求
RegPBRet(9481, "TeamRet", "team.TeamRet", 0)	--队伍信息返回(变化会主动推送)
RegPBReq(9482, "TeamQuitReq", "team.TeamQuitReq", 110)		--退出队伍请求
RegPBReq(9483, "TeamReturnReq", "team.TeamReturnReq", 110)	--归队请求
RegPBReq(9484, "TeamLeaveReq", "team.TeamLeaveReq", 110)		--暂离请求
RegPBReq(9485, "TeamFriendReq", "team.TeamFriendReq", 110)	--好友列表请求
RegPBRet(9486, "TeamFriendRet", "team.TeamFriendRet", 0)	--好友列表返回
RegPBReq(9487, "TeamUnionMemberReq", "team.TeamUnionMemberReq", 110)	--帮派成员列表请求
RegPBRet(9488, "TeamUnionMemberRet", "team.TeamUnionMemberRet", 0)	--帮派成员列表返回
RegPBReq(9489, "TeamInviteReq", "team.TeamInviteReq", 110)		--邀请请求
RegPBReq(9490, "TeamApplyJoinReq", "team.TeamApplyJoinReq", 110)	--申请入队请求
RegPBReq(9491, "TeamApplyListReq", "team.TeamApplyListReq", 110)	--申请列表请求
RegPBRet(9492, "TeamApplyListRet", "team.TeamApplyListRet", 0)	--申请列表返回
RegPBReq(9493, "TeamAgreeJoinReq", "team.TeamAgreeJoinReq", 110)	--同意入队申请请求
RegPBReq(9494, "TeamExchangePosReq", "team.TeamExchangePosReq", 110)	--交换队员位置请求
RegPBReq(9495, "TeamCallReturnReq", "team.TeamCallReturnReq", 110)	--召回所有队员归队请求
RegPBReq(9496, "TeamKickMemberReq", "team.TeamKickMemberReq", 110)	--请离队伍请求
RegPBReq(9497, "TeamTransferLeaderReq", "team.TeamTransferLeaderReq", 110)	--移交队长请求
RegPBReq(9498, "TeamApplyLeaderReq", "team.TeamApplyLeaderReq", 110)	--申请带队请求
RegPBRet(9499, "TeamLeaderChangeRet", "team.TeamLeaderChangeRet", 0)	--队长变更通知
RegPBReq(9501, "TeamClearApplyListReq", "team.TeamClearApplyListReq", 110)--清空申请表
RegPBReq(9502, "TeamMatchReq", "team.TeamMatchReq", 110)--匹配请求(测试用)
RegPBReq(9503, "TeamMatchInfoReq", "team.TeamMatchInfoReq", 110)	--获取匹配状态信息
RegPBRet(9504, "TeamMatchInfoRet", "team.TeamMatchInfoRet", 110)	--队伍匹配状态响应
RegPBReq(9505, "CancelTeamMatchReq", "team.CancelTeamMatchReq", 110)	--取消匹配请求
RegPBRet(9506, "TeamMemberInfoChangeRet", "team.TeamMemberInfoChangeRet", 0) --队员信息变化通知


--聊天
RegPBReq(9600, "TalkReq", "talk.TalkReq", 110) --聊天请求
RegPBRet(9601, "TalkRet", "talk.TalkRet", 0) --聊天返回
RegPBRet(9602, "ShieldRoleListRet", "talk.ShieldRoleListRet", 0) --屏蔽名单返回
RegPBReq(9603, "ShieldRoleReq", "talk.ShieldRoleReq", 110) --添加/移除屏蔽名单
RegPBRet(9604, "TalkHistoryRet", "talk.TalkHistoryRet", 0) --聊天记录返回

--好友系统
RegPBReq(9630, "FriendListReq", "friend.FriendListReq", 110) --好友列表请求
RegPBRet(9631, "FriendListRet", "friend.FriendListRet", 0) --好友列表返回
RegPBReq(9632, "AddFriendReq", "friend.AddFriendReq", 110) --添加好友请求
RegPBReq(9633, "DelFriendReq", "friend.DelFriendReq", 110) --删除好友请求
RegPBReq(9634, "SearchFriendReq", "friend.SearchFriendReq", 110) 	--查找好友请求
RegPBRet(9635, "SearchFriendRet", "friend.SearchFriendRet", 0) 		--查找好友返回
RegPBReq(9636, "FriendSendPropReq", "friend.FriendSendPropReq", 110) --赠送物品请求
RegPBRet(9637, "FriendDegreesRet", "friend.FriendDegreesRet", 0) --友好度同步
RegPBReq(9638, "FriendTalkReq", "friend.FriendTalkReq", 110) --聊天请求
RegPBRet(9639, "FriendTalkRet", "friend.FriendTalkRet", 0) 	--聊天返回

RegPBReq(9640, "FriendApplyReq", "friend.FriendApplyReq", 110) --申请好友请求
RegPBReq(9641, "FriendApplyListReq", "friend.FriendApplyListReq", 110) --好友申请列表请求
RegPBRet(9642, "FriendApplyListRet", "friend.FriendApplyListRet", 0) --好友申请列表返回
RegPBReq(9643, "DenyFriendApplyReq", "friend.DenyFriendApplyReq", 110) --拒绝好友申请请求
RegPBRet(9644, "FriendApplySuccessRet", "friend.FriendApplySuccessRet", 0) --申请好友成功返回
RegPBReq(9645, "FriendHistoryTalkReq", "friend.FriendHistoryTalkReq", 110) --好友/陌生人历史聊天记录请求
RegPBRet(9646, "FriendHistoryTalkRet", "friend.FriendHistoryTalkRet", 0) --好友/陌生人历史聊天记录返回

--邮件
RegPBReq(9670, "MailListReq", "mail.MailListReq", 20)	--取邮件列表
RegPBRet(8671, "MailListRet", "mail.MailListRet", 0)	--邮件列表返回
RegPBReq(8672, "MailBodyReq", "mail.MailBodyReq", 20)	--邮件体请求
RegPBRet(8673, "MailBodyRet", "mail.MailBodyRet", 0)	--邮件体返回
RegPBReq(8674, "DelMailReq", "mail.DelMailReq", 20)	    --删除邮件(删除前如果有物品需要确认提示)
RegPBReq(8675, "MailItemsReq", "mail.MailItemsReq", 20)	--提取物品(需要判断背包是否有空闲位置)
RegPBRet(8676, "MailItemsRet", "mail.MailItemsRet", 0)	--提取物品成功返回

--角色信息框
RegPBReq(8700, "RoleInfoReq", "role.RoleInfoReq", 110)	--角色信息框请求
RegPBRet(8701, "RoleInfoRet", "role.RoleInfoRet", 0)	--角色信息框返回

--帮派
RegPBRet(8720, "UnionInfoRet", "union.UnionInfoRet", 0)		--联盟基本信息返回
RegPBReq(8721, "UnionDetailReq", "union.UnionDetailReq", 20)--联盟详细信息请求
RegPBRet(8722, "UnionDetailRet", "union.UnionDetailRet", 0)	--联盟详细信息返回
RegPBReq(8723, "UnionListReq", "union.UnionListReq", 20)	--联盟列表请求
RegPBRet(8724, "UnionListRet", "union.UnionListRet", 0)		--联盟列表返回
RegPBReq(8725, "UnionApplyReq", "union.UnionApplyReq", 20)	--申请加入联盟请求
RegPBRet(8729, "UnionApplyRet", "union.UnionApplyRet", 0)	--申请加入联盟成功返回
RegPBReq(8726, "UnionCreateReq", "union.UnionCreateReq", 20)--创建联盟请求
RegPBReq(8727, "UnionExitReq", "union.UnionExitReq", 20)	--退出联盟请求
RegPBRet(8728, "UnionExitRet", "union.UnionExitRet", 0)		--退出联盟通知

RegPBReq(8730, "UnionSetAutoJoinReq", "union.UnionSetAutoJoinReq", 20)		--设置自动进入请求
RegPBReq(8731, "UnionSetDeclarationReq", "union.UnionSetDeclarationReq", 20)--设置联盟公告请求
RegPBRet(8732, "UnionDeclarationRet", "union.UnionDeclarationRet", 0)		--联盟公告列表返回

RegPBReq(8733, "UnionApplyListReq", "union.UnionApplyListReq", 20)		--申请列表请求
RegPBRet(8734, "UnionApplyListRet", "union.UnionApplyListRet", 20)		--申请列表返回
RegPBReq(8735, "UnionAcceptApplyReq", "union.UnionAcceptApplyReq", 20)		--接受申请请求
RegPBReq(8736, "UnionRefuseApplyReq", "union.UnionRefuseApplyReq", 20)		--拒绝申请请求
RegPBReq(8737, "UnionMemberListReq", "union.UnionMemberListReq", 20)		--队员列表请求
RegPBRet(8738, "UnionMemberListRet", "union.UnionMemberListRet", 0)			--队员列表返回
RegPBReq(8739, "UnionKickMemberReq", "union.UnionKickMemberReq", 20)		--移除队员请求

RegPBReq(8740, "UnionAppointReq", "union.UnionAppointReq", 20)		--任命职位请求
RegPBRet(8741, "UnionPosChangeRet", "union.UnionPosChangeRet", 0) 	--职位变更返回
RegPBReq(8742, "UnionJoinRandReq", "union.UnionJoinRandReq", 20) 	--随机加入联盟
RegPBReq(8743, "UnionManagerInfoReq", "union.UnionManagerInfoReq", 20) 	--联盟管理信息请求
RegPBRet(8744, "UnionManagerInfoRet", "union.UnionManagerInfoRet", 0) 	--联盟管理信息返回
RegPBReq(8745, "UnionSignReq", "union.UnionSignReq", 20) 	--联盟签到请求
RegPBReq(8746, "UnionModPosNameReq", "union.UnionModPosNameReq", 20) 	--联盟改职位名请求
RegPBReq(8747, "UnionGetSalaryReq", "union.UnionGetSalaryReq", 20) 	--联盟领取俸禄请求
RegPBReq(8748, "UnionSetPurposeReq", "union.UnionSetPurposeReq", 20) --联盟设置宗旨
RegPBReq(8749, "UnionDeclarationReadedReq", "union.UnionDeclarationReadedReq", 20) --联盟公告已读请求
RegPBReq(8750, "UnionPowerRankingReq", "union.UnionPowerRankingReq", 20) --联盟战力榜请求
RegPBRet(8751, "UnionPowerRankingRet", "union.UnionPowerRankingRet", 0) --联盟战力榜返回
RegPBReq(8752, "UnionOpenGiftBoxReq", "union.UnionOpenGiftBoxReq", 20) --联盟礼盒界面打开
RegPBRet(8753, "UnionOpenGiftBoxRet", "union.UnionOpenGiftBoxRet", 0) --联盟礼盒界面返回,刷新
RegPBReq(8754, "UnionDispatchGiftReq", "union.UnionDispatchGiftReq", 20) --联盟礼盒发放
RegPBReq(8755, "UnionEnterSceneReq", "union.UnionEnterSceneReq", 20) --进入联盟场景
RegPBRet(8756, "UnionLoginRet", "union.UnionLoginRet", 0)	--联盟登录发送数据
RegPBRet(8757, "UnionKickMemberRet", "union.UnionKickMemberRet", 0)		--移除队员响应

--滚动公告
RegPBRet(8780, "ScrollNoticeRet", "notice.ScrollNoticeRet", 0) --滚动公告

--累登
RegPBReq(8810, "LDInfoReq", "leideng.LDInfoReq", 0)	--累登界面请求
RegPBRet(8811, "LDInfoRet", "leideng.LDInfoRet", 0)	--累登界面返回
RegPBReq(8812, "LDAwardReq", "leideng.LDAwardReq", 0)	--领取奖励请求
RegPBRet(8813, "LDAwardRet", "leideng.LDAwardRet", 0)	--领取奖励返回

--签到
RegPBReq(8850, "QDInfoReq", "qiandao.QDInfoReq", 0)	--签到界面请求
RegPBRet(8851, "QDInfoRet", "qiandao.QDInfoRet", 0)	--签到界面返回
RegPBReq(8852, "QDAwardReq", "qiandao.QDAwardReq", 0)	--领取奖励请求
RegPBRet(8853, "QDAwardRet", "qiandao.QDAwardRet", 0)	--领取奖励返回
RegPBReq(8854, "QDTiredSignAwardReq", "qiandao.QDTiredSignAwardReq", 0)	--领取累签奖励

--基金
RegPBReq(8880, "FundAwardProgressReq", "fund.FundAwardProgressReq", 0)	--基金界面请求
RegPBRet(8881, "FundAwardProgressRet", "fund.FundAwardProgressRet", 0)	--基金界面返回
RegPBReq(8882, "FundAwardReq", "fund.FundAwardReq", 0)	--领取奖励请求
RegPBRet(8883, "FundAwardRet", "fund.FundAwardRet", 0)	--领取奖励返回

--月卡
RegPBReq(8910, "MonthCardInfoReq", "monthcard.MonthCardInfoReq", 0)	--月卡/周卡请求
RegPBRet(8911, "MonthCardInfoRet", "monthcard.MonthCardInfoRet", 0)	--月卡/周卡返回
RegPBReq(8912, "MonthCardAwardReq", "monthcard.MonthCardAwardReq", 0)	--月卡/周卡奖励请求
RegPBRet(8913, "MonthCardAwardRet", "monthcard.MonthCardAwardRet", 0)	--月卡/周卡奖励返回
RegPBReq(8914, "TrialMonthCardReq", "monthcard.TrialMonthCardReq", 0)	--试用月卡请求

--成长礼包
RegPBReq(8940, "UpgradeBagInfoReq", "upgradebag.UpgradeBagInfoReq", 0)	--成长礼包界面请求
RegPBRet(8941, "UpgradeBagInfoRet", "upgradebag.UpgradeBagInfoRet", 0)	--成长礼包界面返回
RegPBReq(8942, "GetUpgradeBagAwardReq", "upgradebag.GetUpgradeBagAwardReq", 0)	--领取奖励请求
RegPBRet(8943, "GetUpgradeBagAwardRet", "upgradebag.GetUpgradeBagAwardRet", 0)	--领取奖励返回

--找回奖励
RegPBReq(8950, "FindAwardInfoReq", "findaward.FindAwardInfoReq", 0)	--找回奖励界面请求
RegPBRet(8951, "FindAwardInfoRet", "findaward.FindAwardInfoRet", 0)	--找回奖励界面返回
RegPBReq(8952, "FindAwardGetAwardReq", "findaward.FindAwardGetAwardReq", 0)	--领取奖励请求
RegPBReq(8953, "OneKeyFindAwardReq", "findaward.OneKeyFindAwardReq", 0)		--一键领取奖励请求
RegPBRet(8954, "FindAwardGetAwardRet", "findaward.FindAwardGetAwardRet", 0)	--领取奖励返回

--下载微端奖励
RegPBReq(8969, "WDDownloadedReq", "wddownload.WDDownloadedReq", 0)	--下载微端成功请求
RegPBReq(8970, "WDDownloadInfoReq", "wddownload.WDDownloadInfoReq", 0)	--下载微端奖励界面请求
RegPBRet(8971, "WDDownloadInfoRet", "wddownload.WDDownloadInfoRet", 0)	--下载微端奖励界面返回
RegPBReq(8972, "GetWDDownloadAwardReq", "wddownload.GetWDDownloadAwardReq", 0)	--领取奖励请求
RegPBRet(8973, "GetWDDownloadAwardRet", "wddownload.GetWDDownloadAwardRet", 0)	--领取奖励返回

--五鬼财运
RegPBReq(9690, "WuGuiCaiYunInfoReq", "wuguicaiyun.WuGuiCaiYunInfoReq", 0)	--五鬼财运界面请求
RegPBRet(9691, "WuGuiCaiYunInfoRet", "wuguicaiyun.WuGuiCaiYunInfoRet", 0)	--五鬼财运界面返回
RegPBReq(9692, "GetWuGuiCaiYunAwardReq", "wuguicaiyun.GetWuGuiCaiYunAwardReq", 0)	--领取奖励请求
RegPBRet(9693, "GetWuGuiCaiYunAwardRet", "wuguicaiyun.GetWuGuiCaiYunAwardRet", 0)	--领取奖励返回

--角色战斗外状态
RegPBRet(9715, "RoleStateSyncRet", "rolestate.RoleStateSyncRet", 0)	--状态同步
RegPBReq(9716, "RoleStateBuyBaoShiReq", "rolestate.RoleStateBuyBaoShiReq", 0) --购买饱食请求
RegPBReq(9717, "RoleStateMarriageSuitSetReq", "rolestate.RoleStateMarriageSuitSetReq", 0) 	--新婚礼服激活设置请求

--邀请玩家
RegPBRet(9736, "InviteInfoRet", "invite.InviteInfoRet", 0) --邀请信息返回
RegPBReq(9737, "InviteAwardReq", "invite.InviteAwardReq", 110) --领取邀请奖励请求

--VIP
RegPBReq(9757, "VIPAwardListReq", "vip.VIPAwardListReq", 0)     	--VIP特权列表请求
RegPBRet(9758, "VIPAwardListRet", "vip.VIPAwardListRet", 0) 		--VIP特权列表返回
RegPBReq(9759, "VIPAwardReq", "vip.VIPAwardReq", 0)     			--VIP特权领取请求
RegPBRet(9760, "VIPAwardRet", "vip.VIPAwardRet", 0) 				--VIP特权领取返回
RegPBReq(9761, "RechargeListReq", "vip.RechargeListReq", 0)     	--充值列表请求
RegPBRet(9762, "RechargeListRet", "vip.RechargeListRet", 0) 		--充值列表返回
RegPBRet(9763, "RechargeSuccessRet", "vip.RechargeSuccessRet", 0) 	--充值成功返回
RegPBRet(9764, "FirstRechargeStateRet", "vip.FirstRechargeStateRet", 0) 	--首充状态同步
RegPBReq(9765, "FirstRechargeAwardReq", "vip.FirstRechargeAwardReq", 0) 	--领取首充奖励
RegPBRet(9766, "FirstRechargeAwardRet", "vip.FirstRechargeAwardRet", 0) 	--领取首充奖励成功返回
RegPBReq(9767, "RechargeRebateAwardInfoReq", "vip.RechargeRebateAwardInfoReq", 0) --充值返利列表请求
RegPBRet(9768, "RechargeRebateAwardInfoRet", "vip.RechargeRebateAwardInfoRet", 0) 	--充值返利列表请求返回
RegPBReq(9769, "RechargeRebateAwardReq", "vip.RechargeRebateAwardReq", 0)           --充值返利领奖请求
RegPBRet(9770, "RechargeRebateAwardRet", "vip.RechargeRebateAwardRet", 0) 	         --充值返利领奖请求返回
RegPBReq(9771, "RechargeGetTotalPureYuanBaoReq", "vip.RechargeGetTotalPureYuanBaoReq", 0) --获取累计充值请求
RegPBRet(9772, "RechargeGetTotalPureYuanBaoRet", "vip.RechargeGetTotalPureYuanBaoRet", 0) --获取累计充值请求返回

--兑换码
RegPBReq(9790, "KeyExchangeReq", "keyexchange.KeyExchangeReq", 20) --兑换码兑换

--充值翻倍活动
RegPBReq(9800, "ActFBStateReq", "actfb.ActFBStateReq", 20) --活动状态请求
RegPBRet(9801, "ActFBStateRet", "actfb.ActFBStateRet", 0) --活动状态返回

--首次登录福利通知
RegPBRet(9820, "RoleFirstOnlineAwardRet", "role.RoleFirstOnlineAwardRet", 0)

--开服目标活动
RegPBReq(9851, "GrowthTargetActInfoReq", "growthtargetact.GrowthTargetActInfoReq", 20) 	--活动信息请求
RegPBRet(9852, "GrowthTargetActInfoRet", "growthtargetact.GrowthTargetActInfoRet", 20) 	--活动信息响应
RegPBReq(9853, "GrowthTargetActRankInfoReq", "growthtargetact.GrowthTargetActRankInfoReq", 20) 	--活动排行榜信息请求
RegPBRet(9854, "GrowthTargetActRankInfoRet", "growthtargetact.GrowthTargetActRankInfoRet", 20) 	--活动排行榜信息响应
RegPBReq(9855, "GrowthTargetActRewardReq", "growthtargetact.GrowthTargetActRewardReq", 20) 	--活动奖励领取请求
RegPBReq(9856, "GrowthTargetActRankRewardReq", "growthtargetact.GrowthTargetActRankRewardReq", 20) 	--活动排名奖励领取请求
RegPBReq(9857, "GrowthTargetActRechargeRewardReq", "growthtargetact.GrowthTargetActRechargeRewardReq", 20) 	--活动充值奖励领取请求
RegPBReq(9859, "GrowthTargetActShopReq", "growthtargetact.GrowthTargetActShopReq", 20) 	--活动商店信息请求
RegPBRet(9860, "GrowthTargetActShopRet", "growthtargetact.GrowthTargetActShopRet", 20) 	--活动商店信息响应
RegPBReq(9861, "GrowthTargetActShopPurchaseReq", "growthtargetact.GrowthTargetActShopPurchaseReq", 20) 	--活动商店购买请求
RegPBReq(9863, "GrowthTargetActInfoListReq", "growthtargetact.GrowthTargetActInfoListReq", 20) 	--活动信息列表请求
RegPBRet(9864, "GrowthTargetActInfoListRet", "growthtargetact.GrowthTargetActInfoListRet", 20) 	--活动信息列表响应



------戴连春[13001-18000]
RegPBReq(13001, "KnapsacWearEquReq", "knapsack.KnapsacWearEquReq", 0) --穿装备请求
RegPBRet(13002, "KnapsacWearEquRet", "knapsack.KnapsacWearEquRet", 0) --穿装备返回
RegPBReq(13003, "KnapsacTakeOffEquReq", "knapsack.KnapsacTakeOffEquReq", 0) --脱装备请求
RegPBRet(13004, "KnapsacTakeOffEquRet", "knapsack.KnapsacTakeOffEquRet", 0) --脱装备返回
RegPBReq(13005, "KnapsacFixEquReq", "knapsack.KnapsacFixEquReq", 0) --装备维修请求
RegPBRet(13006, "KnapsacFixEquRet", "knapsack.KnapsacFixEquRet", 0) --单个装备维修返回
RegPBReq(13007, "KnapsacFixSingleEquReq", "knapsack.KnapsacFixSingleEquReq", 0) --单个装备维修请求
RegPBReq(13008, "KnapsacMakeEquReq", "knapsack.KnapsacMakeEquReq", 0) --装备打造请求
RegPBReq(13009, "KnapsacGemReq", "knapsack.KnapsacGemReq", 0) --装备宝石镶嵌请求
RegPBReq(13010, "KnapsacRemoveGemReq", "knapsack.KnapsacRemoveGemReq", 0) --装备宝石拆除请求
RegPBReq(13011, "KnapsacStrengthenEquReq", "knapsack.KnapsacStrengthenEquReq", 0) --装备强化请求
RegPBRet(13012, "KnapsacStrengthenEquRet", "knapsack.KnapsacStrengthenEquRet", 0) --装备强化返回
RegPBReq(13013, "KnapsacWearEquListReq", "knapsack.KnapsacWearEquListReq", 0) 	--身上装备列表请求
RegPBRet(13014, "KnapsacWearEquListRet", "knapsack.KnapsacWearEquListRet", 0)	--身上装备列表返回
RegPBReq(13015, "KnapsacPropDetailReq", "knapsack.KnapsacPropDetailReq", 0)	--背包道具查询请求
RegPBRet(13016, "KnapsacPropDetailRet", "knapsack.KnapsacPropDetailRet", 0)	--背包道具查询返回
RegPBReq(13017, "PropEquipReMakeReq", "knapsack.PropEquipReMakeReq", 0)		--装备重铸
RegPBRet(13018, "PropEquipReMakeRet", "knapsack.PropEquipReMakeRet", 0)		--装备重铸响应
RegPBReq(13019, "KnapsacQuickWearEquReq", "knapsack.KnapsacQuickWearEquReq", 0)		--一键穿戴请求
RegPBRet(13020, "KnapsackGemTipsRet", "knapsack.KnapsackGemTipsRet", 0)	--身上穿戴装备宝石孔镶嵌提示
RegPBReq(13021, "KnapsacLegendEquExchangeReq", "knapsack.KnapsacLegendEquExchangeReq", 0)	--神兵兑换请求
RegPBReq(13023, "KnapsacLegendEquExchangeInfoReq", "knapsack.KnapsacLegendEquExchangeInfoReq", 0)	--神兵兑换信息请求
RegPBRet(13024, "KnapsacLegendEquExchangeInfoRet", "knapsack.KnapsacLegendEquExchangeInfoRet", 0)	--神兵兑换信息响应
RegPBReq(13025, "KnapsackEquTriggerAttrReq", "knapsack.KnapsackEquTriggerAttrReq", 0)	--装备共鸣属性请求
RegPBRet(13026, "KnapsackEquTriggerAttrRet", "knapsack.KnapsackEquTriggerAttrRet", 0)	--装备共鸣属性响应
RegPBReq(13027, "KnapsackRecastSellReq", "knapsack.KnapsackRecastSellReq", 0)	--重铸界面出售请求
RegPBRet(13028, "KnapsackRecastSellRet", "knapsack.KnapsackRecastSellRet", 0)	--重铸界面出售请求响应
RegPBRet(13029, "KnapsacGemRet", "knapsack.KnapsacGemRet", 0) 	--宝石镶嵌响应
RegPBRet(13030, "knapsacRemoveGemRet", "knapsack.knapsacRemoveGemRet", 0) 	--宝石拆除响应
RegPBReq(13031, "KnapsackTransferReq", "knapsack.KnapsackTransferReq", 0) 	--请求能转移的所有装备请求
RegPBRet(13032, "knapsacTransferkRet", "knapsack.knapsacTransferkRet", 0) 	--请求能转移的所有装备请求响应

--伙伴 [13101 - 13199]
RegPBReq(13101, "PartnerBlockDataReq", "partner.PartnerBlockDataReq", 0)	--获取伙伴模块数据
RegPBRet(13102, "PartnerBlockDataRet", "partner.PartnerBlockDataRet", 0)	--伙伴模块数据响应
RegPBReq(13103, "PartnerDetailReq", "partner.PartnerDetailReq", 0)	--获取指定伙伴详细数据
RegPBRet(13104, "PartnerDetailRet", "partner.PartnerDetailRet", 0)	--指定伙伴详细数据响应
RegPBReq(13105, "PartnerListReq", "partner.PartnerListReq", 0)	--获取所有伙伴详细数据
RegPBRet(13106, "PartnerListRet", "partner.PartnerListRet", 0)	--所有伙伴详细数据响应
RegPBReq(13107, "PartnerRecruitReq", "partner.PartnerRecruitReq", 0)	--伙伴招募请求
RegPBRet(13108, "PartnerRecruitRet", "partner.PartnerRecruitRet", 0)	--伙伴招募响应
RegPBReq(13109, "PartnerAddMaterialCollectCountReq", "partner.PartnerAddMaterialCollectCountReq", 0)	--购买灵石采集许可次数请求
RegPBRet(13110, "PartnerAddMaterialCollectCountRet", "partner.PartnerAddMaterialCollectCountRet", 0)	--购买灵石采集许可次数响应
RegPBReq(13111, "PartnerStoneCollectReq", "partner.PartnerStoneCollectReq", 0)	--灵石采集请求
RegPBRet(13112, "PartnerStoneCollectRet", "partner.PartnerStoneCollectRet", 0)	--灵石采集响应
RegPBReq(13113, "PartnerBattleActiveReq", "partner.PartnerBattleActiveReq", 0)	--伙伴上阵请求
RegPBRet(13114, "PartnerBattleActiveRet", "partner.PartnerBattleActiveRet", 0)	--伙伴上阵响应
RegPBReq(13115, "PartnerBattleRestReq", "partner.PartnerBattleRestReq", 0)	--伙伴下阵请求
RegPBRet(13116, "PartnerBattleRestRet", "partner.PartnerBattleRestRet", 0)	--伙伴下阵响应
RegPBReq(13117, "PartnerSwitchPlanReq", "partner.PartnerSwitchPlanReq", 0)	--伙伴上阵方案切换请求
RegPBRet(13118, "PartnerSwitchPlanRet", "partner.PartnerSwitchPlanRet", 0)	--伙伴上阵方案切换响应
RegPBReq(13119, "PartnerAddStarCountReq", "partner.PartnerAddStarCountReq", 0)	--点亮伙伴星级星星请求
RegPBRet(13120, "PartnerAddStarCountRet", "partner.PartnerAddStarCountRet", 0)	--点亮伙伴星级星星响应
RegPBReq(13121, "PartnerSendGiftReq", "partner.PartnerSendGiftReq", 0)	--给指定伙伴送礼请求
RegPBRet(13122, "PartnerSendGiftRet", "partner.PartnerSendGiftRet", 0)	--给指定伙伴送礼响应
RegPBReq(13123, "PartnerAddSpiritReq", "partner.PartnerAddSpiritReq", 0)	--给指定伙伴增加灵气请求
RegPBRet(13124, "PartnerAddSpiritRet", "partner.PartnerAddSpiritRet", 0)	--给指定伙伴赠送灵气响应
RegPBReq(13125, "PartnerPlanSwapPosReq", "partner.PartnerPlanSwapPosReq", 0)	--交换上阵伙伴位置请求
RegPBRet(13126, "PartnerPlanSwapPosRet", "partner.PartnerPlanSwapPosRet", 0)	--交换上阵伙伴位置响应
RegPBRet(13128, "PartnerRecruitTipsRet", "partner.PartnerRecruitTipsRet", 0)	--伙伴招募提示
RegPBReq(13129, "PartnerRecruitTipsCloseReq", "partner.PartnerRecruitTipsCloseReq", 0)	--关闭伙伴招募提示请求
RegPBReq(13131, "PartnerStarLevelUpReq", "partner.PartnerStarLevelUpReq", 0)	--伙伴星级升级请求
RegPBRet(13132, "PartnerStarLevelUpRet", "partner.PartnerStarLevelUpRet", 0)	--伙伴星级升级响应
RegPBRet(13134, "PartnerAddStarTipsRet", "partner.PartnerAddStarTipsRet", 0)	--伙伴升星提示
RegPBReq(13135, "PartnerXianzhenInfoReq", "partner.PartnerXianzhenInfoReq", 0)	--仙侣仙阵信息请求
RegPBRet(13136, "PartnerXianzhenInfoRet", "partner.PartnerXianzhenInfoRet", 0)	--仙侣仙阵信息响应
RegPBReq(13137, "PartnerXianzhenLevelUpReq", "partner.PartnerXianzhenLevelUpReq", 0)	--仙侣仙阵升级请求
RegPBRet(13138, "PartnerXianzhenLevelUpRet", "partner.PartnerXianzhenLevelUpRet", 0)	--仙侣仙阵升级响应
RegPBReq(13139, "PartnerReviveLevelUpReq", "partner.PartnerReviveLevelUpReq", 0)	--仙侣觉醒请求
RegPBRet(13140, "PartnerReviveLevelUpRet", "partner.PartnerReviveLevelUpRet", 0)	--仙侣觉醒响应


--交易系统
RegPBReq(13201, "MarketGoodsPriceDataReq", "market.MarketGoodsPriceDataReq", 20)	--获取商品价格信息请求
RegPBRet(13202, "MarketGoodsPriceDataRet", "market.MarketGoodsPriceDataRet", 20)	--获取商品价格信息响应
RegPBReq(13203, "MarketStallDataReq", "market.MarketStallDataReq", 20)	--玩家摊位数据请求
RegPBRet(13204, "MarketStallDataRet", "market.MarketStallDataRet", 20)	--玩家摊位数据响应
RegPBReq(13205, "MarketItemOnSaleReq", "market.MarketItemOnSaleReq", 20)	--商品上架销售请求
RegPBRet(13206, "MarketItemOnSaleRet", "market.MarketItemOnSaleRet", 20)	--商品上架销售响应
RegPBReq(13207, "MarketItemReSaleReq", "market.MarketItemReSaleReq", 20)	--商品重新上架请求
RegPBRet(13208, "MarketItemReSaleRet", "market.MarketItemReSaleRet", 20)	--商品重新上架响应
RegPBReq(13209, "MarketRemoveSaleReq", "market.MarketRemoveSaleReq", 20)	--商品下架请求
RegPBRet(13210, "MarketRemoveSaleRet", "market.MarketRemoveSaleRet", 20)	--商品下架响应
RegPBReq(13211, "MarketDrawMoneyReq", "market.MarketDrawMoneyReq", 20)	--商品提现请求
RegPBRet(13212, "MarketDrawMoneyRet", "market.MarketDrawMoneyRet", 20)	--商品提现响应
RegPBReq(13213, "MarketViewPageFlushDataReq", "market.MarketViewPageFlushDataReq", 20)	--获取交易列表刷新数据请求
RegPBRet(13214, "MarketViewPageFlushDataRet", "market.MarketViewPageFlushDataRet", 20)	--获取交易列表刷新数据响应
RegPBReq(13215, "MarketViewPageDataReq", "market.MarketViewPageDataReq", 20)	--获取交易页表数据请求
RegPBRet(13216, "MarketViewPageDataRet", "market.MarketViewPageDataRet", 20)	--获取交易页表数据响应
RegPBReq(13217, "MarketFlushViewPageReq", "market.MarketFlushViewPageReq", 20)	--刷新整个交易页表数据请求
RegPBRet(13218, "MarketFlushViewPageRet", "market.MarketFlushViewPageRet", 20)	--刷新整个交易页表数据响应
RegPBReq(13219, "MarketPurchaseReq", "market.MarketPurchaseReq", 20)	--购买商品请求
RegPBRet(13220, "MarketPurchaseRet", "market.MarketPurchaseRet", 20)	--购买商品响应
RegPBReq(13221, "MarketUnlockStallGridReq", "market.MarketUnlockStallGridReq", 20)	--解锁摊位格子请求
RegPBRet(13222, "MarketUnlockStallGridRet", "market.MarketUnlockStallGridRet", 20)	--解锁摊位格子响应
RegPBReq(13223, "MarketStallItemDetailInfoReq", "market.MarketStallItemDetailInfoReq", 20)	--摊位出售的商品详细信息请求
RegPBReq(13225, "MarketViewItemDetailInfoReq", "market.MarketViewItemDetailInfoReq", 20)	--浏览的商品详细信息请求

--PVP限时活动
RegPBReq(13301, "PVPActivityEnterReq", "pvpactivity.PVPActivityEnterReq", 0)	--进入PVP活动场景请求
RegPBReq(13303, "PVPActivityInfoReq", "pvpactivity.PVPActivityInfoReq", 0) 	--获取PVP活动信息请求
RegPBRet(13304, "PVPActivityInfoRet", "pvpactivity.PVPActivityInfoRet", 0) 	--获取PVP活动信息响应
RegPBReq(13305, "PVPActivityRoleDataReq", "pvpactivity.PVPActivityRoleDataReq", 0) 	--获取玩家的PVP活动信息请求
RegPBRet(13306, "PVPActivityRoleDataRet", "pvpactivity.PVPActivityRoleDataRet", 0) 	--获取玩家的PVP活动信息响应
RegPBReq(13307, "PVPActivityRankDataReq", "pvpactivity.PVPActivityRankDataReq", 0) 	--获取PVP活动排行榜数据请求
RegPBRet(13308, "PVPActivityRankDataRet", "pvpactivity.PVPActivityRankDataRet", 0) 	--获取PVP活动排行榜数据响应
RegPBReq(13309, "PVPActivityBattleReq", "pvpactivity.PVPActivityBattleReq", 0) 	--PVP活动发起战斗请求
RegPBRet(13310, "PVPActivityRoleStateChangeViewRet", "pvpactivity.PVPActivityRoleStateChangeViewRet", 0) 	--玩家状态变化场景广播
RegPBReq(13311, "PVPActivityLeaveReq", "pvpactivity.PVPActivityLeaveReq", 0) 	--离开PVP活动场景请求
RegPBReq(13313, "PVPActivityMatchTeamReq", "pvpactivity.PVPActivityMatchTeamReq", 0) 	--快速匹配队伍请求
RegPBRet(13314, "PVPUnionDataRet", "pvpactivity.PVPUnionDataRet", 0)				--同步帮派场景人数
RegPBReq(13315, "PVPActivityCancelMatchTeamReq", "pvpactivity.PVPActivityCancelMatchTeamReq", 0) 	--取消匹配队伍请求
RegPBRet(13316, "PVPActivityNpcRet", "pvpactivity.PVPActivityNpcRet", 0)				--通知PVP活动NPC出现和销毁


--竞技场  [13401 - 13430]
RegPBReq(13401, "ArenaRoleInfoReq", "arena.ArenaRoleInfoReq", 20)	--玩家竞技场数据请求
RegPBRet(13402, "ArenaRoleInfoRet", "arena.ArenaRoleInfoRet", 20)	--玩家竞技场数据响应
RegPBReq(13403, "ArenaRankDataReq", "arena.ArenaRankDataReq", 20)	--竞技场排行榜数据请求
RegPBRet(13404, "ArenaRankDataRet", "arena.ArenaRankDataRet", 20)	--竞技场排行榜数据响应
RegPBReq(13405, "ArenaFlushMatchReq", "arena.ArenaFlushMatchReq", 20)	--刷新匹配玩家请求
RegPBReq(13407, "ArenaBattleReq", "arena.ArenaBattleReq", 20)	--发起竞技场挑战请求
RegPBRet(13408, "ArenaBattleResultRet", "arena.ArenaBattleResultRet", 20)	--竞技场战斗结果返回
RegPBReq(13409, "ArenaRewardReceiveReq", "arena.ArenaRewardReceiveReq", 20)	--领取竞技场奖励请求
RegPBRet(13410, "ArenaRewardReceiveRet", "arena.ArenaRewardReceiveRet", 20)	--领取竞技场奖励响应
RegPBReq(13411, "ArenaAddChallengeReq", "arena.ArenaAddChallengeReq", 20)	--元宝购买竞技场挑战次数请求
RegPBRet(13412, "ArenaAddChallengeRet", "arena.ArenaAddChallengeRet", 20)	--元宝购买竞技场挑战次数响应

--多重确认框  [13431 - 13450]
RegPBRet(13432, "MultiConfirmBoxRet", "multiconfirmbox.MultiConfirmBoxRet", 0)	--通知客户端刷新多重确认框
RegPBReq(13433, "MultiConfirmBoxReactReq", "multiconfirmbox.MultiConfirmBoxReactReq", 0)	--多重确认框操作反馈请求
RegPBRet(13436, "MultiConfirmBoxDestroyRet", "multiconfirmbox.MultiConfirmBoxDestroyRet", 0)	--通知销毁确认框

--结婚系统  [13451 - 13500]
RegPBReq(13451, "RoleMarriageDataReq", "marriage.RoleMarriageDataReq", 110)	--玩家婚姻关系数据请求
RegPBRet(13452, "RoleMarriageDataRet", "marriage.RoleMarriageDataRet", 110)	--玩家婚姻关系数据响应
RegPBReq(13453, "MarriageActionDataReq", "marriage.MarriageActionDataReq", 110)	--结婚离婚操作数据请求
RegPBRet(13454, "MarriageActionDataRet", "marriage.MarriageActionDataRet", 110)	--结婚离婚操作数据返回
RegPBReq(13455, "MarryPermitDataReq", "marriage.MarryPermitDataReq", 110)	--玩家结婚条件检查请求
RegPBRet(13456, "MarryPermitDataRet", "marriage.MarryPermitDataRet", 110)	--玩家结婚条件检查响应
RegPBReq(13457, "DivorcePermitDataReq", "marriage.DivorcePermitDataReq", 110)	--离婚条件检查请求
RegPBRet(13458, "DivorcePermitDataRet", "marriage.DivorcePermitDataRet", 110)	--离婚条件检查响应
RegPBReq(13459, "RoleMarryReq", "marriage.RoleMarryReq", 0)	--玩家结婚请求
RegPBRet(13460, "MarriageNotifyChooseWeddingLevelRet", "marriage.MarriageNotifyChooseWeddingLevelRet", 0)	--通知选择婚礼级别
RegPBReq(13461, "MarriageChoosWeddingLevelReactReq", "marriage.MarriageChoosWeddingLevelReactReq", 0)	--选择婚礼级别反馈请求
RegPBRet(13462, "MarriageWeddingStartRet", "marriage.MarriageWeddingStartRet", 0)	--通知婚礼开始
RegPBRet(13463, "MarriageWeddingEndRet", "marriage.MarriageWeddingEndRet", 0)	--通知婚礼结束
RegPBRet(13464, "MarriageWeddingStepNotifyRet", "marriage.MarriageWeddingStepNotifyRet", 0)	--通知婚礼流程开始
RegPBReq(13465, "MarriagePickWeddingCandyReq", "marriage.MarriagePickWeddingCandyReq", 0)	--拾取喜糖请求
RegPBRet(13466, "MarriageWeddingCandyNotifyRet", "marriage.MarriageWeddingCandyNotifyRet", 0)	--通知有喜糖刷新
RegPBReq(13467, "MarriageDivorceReq", "marriage.MarriageDivorceReq", 110)	--离婚请求
RegPBReq(13468, "MarriageDivorceCancelReq", "marriage.MarriageDivorceCancelReq", 110)	--取消离婚请求
RegPBReq(13469, "MarriagePalanquinRentReq", "marriage.MarriagePalanquinRentReq", 0)	--花轿租赁请求
-- RegPBRet(13470, "MarriagePalanquinRentRet", "marriage.MarriagePalanquinRentRet", 0)	--花轿租赁响应
-- RegPBRet(13471, "PalanquinParadeBeginRet", "marriage.PalanquinParadeBeginRet", 0)	--花轿游览开始
-- RegPBRet(13472, "PalanquinParadeEndRet", "marriage.PalanquinParadeEndRet", 0)	--花轿游览结束
RegPBReq(13473, "MarriageGiftSendReq", "marriage.MarriageGiftSendReq", 110)	--赠送贺礼请求
RegPBReq(13475, "MarriageAskCheckReq", "marriage.MarriageAskCheckReq", 110)	--结婚询问条件检查请求
RegPBRet(13476, "MarriageAskCheckRet", "marriage.MarriageAskCheckRet", 110)	--结婚询问条件检查响应
RegPBReq(13477, "MarriageAskReq", "marriage.MarriageAskReq", 110)	--发起结婚询问请求
RegPBRet(13478, "MarriageAskRet", "marriage.MarriageAskRet", 110)	--结婚询问结果响应
RegPBRet(13479, "MarriageWeddingStartBroadcastRet", "marriage.MarriageWeddingStartBroadcastRet", 110)	--婚礼广播通知
RegPBReq(13480, "MarriagePickItemStateReq", "marriage.MarriagePickItemStateReq", 0)	--月老物品当前拾取状态请求
RegPBRet(13481, "MarriagePickItemStateRet", "marriage.MarriagePickItemStateRet", 0)	--月老物品当前拾取状态请求返回



--结拜 [13501 - 13550]
RegPBReq(13501, "BrotherInfoReq", "relationship.BrotherInfoReq", 110)	--玩家结拜数据请求
RegPBRet(13502, "BrotherInfoRet", "relationship.BrotherInfoRet", 110)	--玩家结拜数据响应
RegPBReq(13503, "BrotherSwearCheckReq", "relationship.BrotherSwearCheckReq", 110)	--玩家结拜数据响应
RegPBRet(13504, "BrotherSwearCheckRet", "relationship.BrotherSwearCheckRet", 110)	--结拜条件检查响应
RegPBReq(13505, "BrotherSwearReq", "relationship.BrotherSwearReq", 110)	--结拜请求
RegPBReq(13506, "BrotherDeleteReq", "relationship.BrotherDeleteReq", 110)	--解除结拜请求

--情缘[13551 - 13600]
RegPBReq(13551, "LoverInfoReq", "relationship.LoverInfoReq", 110)	--玩家情缘数据请求
RegPBRet(13552, "LoverInfoRet", "relationship.LoverInfoRet", 110)	--玩家情缘数据响应
RegPBReq(13553, "LoverTogetherCheckReq", "relationship.LoverTogetherCheckReq", 110)	--情缘条件检查请求
RegPBRet(13554, "LoverTogetherCheckRet", "relationship.LoverTogetherCheckRet", 110)	--情缘条件检查响应
RegPBReq(13555, "LoverTogetherReq", "relationship.LoverTogetherReq", 110)	--情缘请求
RegPBReq(13556, "LoverDeleteReq", "relationship.LoverDeleteReq", 110)	--解除情缘请求

--师徒[13601 - 13670]
RegPBReq(13601, "MentorshipCheckReq", "relationship.MentorshipCheckReq", 110)	--师徒关系检查请求
RegPBRet(13602, "MentorshipCheckRet", "relationship.MentorshipCheckRet", 110)	--师徒关系检查响应
RegPBReq(13603, "MentorshipDealMasterReq", "relationship.MentorshipDealMasterReq", 110)	--拜师请求
RegPBReq(13604, "MentorshipDealApprentReq", "relationship.MentorshipDealApprentReq", 110)	--收徒请求
RegPBReq(13605, "DeleteApprenticeReq", "relationship.DeleteApprenticeReq", 110)	--开除徒弟请求
RegPBReq(13606, "DeleteMasterReq", "relationship.DeleteMasterReq", 110)	--叛离师父请求
RegPBReq(13607, "MentorshipUpgradeCheckReq", "relationship.MentorshipUpgradeCheckReq", 110)	--徒弟晋级(出师)检查请求
RegPBRet(13608, "MentorshipUpgradeCheckRet", "relationship.MentorshipUpgradeCheckRet", 110)	--徒弟晋级(出师)检查响应
RegPBReq(13609, "MentorshipUpgradeReq", "relationship.MentorshipUpgradeReq", 110)	--徒弟晋级(出师)请求
RegPBReq(13611, "MentorshipInfoReq", "relationship.MentorshipInfoReq", 110)	--玩家师徒数据请求
RegPBRet(13612, "MentorshipInfoRet", "relationship.MentorshipInfoRet", 110)	--玩家师徒数据响应
RegPBReq(13613, "MentorshipTaskDataListReq", "relationship.MentorshipTaskDataListReq", 110)	--获取师徒任务信息列表请求
RegPBRet(13614, "MentorshipTaskDataListRet", "relationship.MentorshipTaskDataListRet", 110)	--获取师徒任务信息列表响应
RegPBRet(13618, "MentorshipTaskDataUpdateRet", "relationship.MentorshipTaskDataUpdateRet", 110)	--师徒任务数据刷新通知
RegPBReq(13619, "MentorshipFlushTaskReq", "relationship.MentorshipFlushTaskReq", 110)	--刷新师徒任务请求
RegPBReq(13621, "MentorshipTaskPublishReq", "relationship.MentorshipTaskPublishReq", 110)	--发布师徒任务请求
RegPBReq(13623, "MentorshipTaskAcceptReq", "relationship.MentorshipTaskAcceptReq", 110)	--接取师徒任务请求
RegPBRet(13624, "MentorshipTaskAcceptRet", "relationship.MentorshipTaskAcceptRet", 110)	--接取师徒任务响应
RegPBReq(13625, "MentorshipTaskBattleReq", "relationship.MentorshipTaskBattleReq", 110)	--师徒任务战斗请求
RegPBReq(13627, "MentorshipTaskRewardReq", "relationship.MentorshipTaskRewardReq", 110)	--徒弟领取师徒任务奖励请求
RegPBReq(13629, "MentorshiTaskMasterRewardReq", "relationship.MentorshiTaskMasterRewardReq", 110)	--师父领取徒弟任务奖励请求
RegPBReq(13631, "MentorshipActiveRewardReq", "relationship.MentorshipActiveRewardReq", 110)	--徒弟领取活跃度奖励请求
RegPBReq(13633, "MentorshipMasterActiveRewardReq", "relationship.MentorshipMasterActiveRewardReq", 110)	--师父领取徒弟活跃度奖励请求
RegPBReq(13635, "MentorshipGreetMasterReq", "relationship.MentorshipGreetMasterReq", 110)	--给师父请安请求
RegPBRet(13636, "MentorshipGreetMasterRet", "relationship.MentorshipGreetMasterRet", 110)	--给师父请安回传
RegPBReq(13637, "MentorshipTeachApprenticeReq", "relationship.MentorshipTeachApprenticeReq", 110)	--指点徒弟请求
RegPBReq(13638, "MentorshipPublishTaskRemindReq", "relationship.MentorshipPublishTaskRemindReq", 110)	--提醒布置师徒任务请求

--社会关系综合数据[13671 - 13700]
RegPBReq(13671, "BriefRelationshipDataReq", "relationship.BriefRelationshipDataReq", 110)	--有缘简要数据请求
RegPBRet(13672, "BriefRelationshipDataRet", "relationship.BriefRelationshipDataRet", 110)	--有缘简要数据响应
RegPBReq(13673, "RoleRelationshipInviteTalkReq", "relationship.RoleRelationshipInviteTalkReq", 110)	--玩家关系招募喊话请求
RegPBReq(13675, "RoleRelationshipQingyiInfoReq", "relationship.RoleRelationshipQingyiInfoReq", 0)	--缘分情义信息请求
RegPBRet(13676, "RoleRelationshipQingyiInfoRet", "relationship.RoleRelationshipQingyiInfoRet", 0)	--缘分情义信息响应
RegPBReq(13677, "RoleRelationshipQingyiLevelUpReq", "relationship.RoleRelationshipQingyiLevelUpReq", 0)	--缘分情义升级请求
RegPBRet(13678, "RoleRelationshipQingyiLevelUpRet", "relationship.RoleRelationshipQingyiLevelUpRet", 0)	--缘分情义升级响应



--摄魂[13701 - 13750]
RegPBReq(13701, "DrawSpiritDataReq", "drawspirit.DrawSpiritDataReq", 0)	--摄魂数据请求
RegPBRet(13702, "DrawSpiritDataRet", "drawspirit.DrawSpiritDataRet", 0)	--摄魂数据响应
RegPBReq(13703, "DrawSpiritCurSpiritNumReq", "drawspirit.DrawSpiritCurSpiritNumReq", 0)	--当前灵气数量请求
RegPBRet(13704, "DrawSpiritCurSpiritNumRet", "drawspirit.DrawSpiritCurSpiritNumRet", 0)	--当前灵气数量响应
RegPBReq(13705, "DrawSpiritLevelUpReq", "drawspirit.DrawSpiritLevelUpReq", 0)	--摄魂升级请求
RegPBRet(13706, "DrawSpiritLevelUpRet", "drawspirit.DrawSpiritLevelUpRet", 0)	--摄魂升级响应
RegPBRet(13708, "DrawSpiritTriggerRet", "drawspirit.DrawSpiritTriggerRet", 0)	--摄魂灵气触发消耗通知
RegPBReq(13709, "DrawSpiritSetTriggerLevelReq", "drawspirit.DrawSpiritSetTriggerLevelReq", 0)	--摄魂灵气消耗等级调整请求
RegPBRet(13710, "DrawSpiritSetTriggerLevelRet", "drawspirit.DrawSpiritSetTriggerLevelRet", 0)	--摄魂灵气消耗等级调整响应
RegPBReq(13711, "DrawSpiritLianhunInfoReq", "drawspirit.DrawSpiritLianhunInfoReq", 0)	--摄魂炼魂信息请求
RegPBRet(13712, "DrawSpiritLianhunInfoRet", "drawspirit.DrawSpiritLianhunInfoRet", 0)	--摄魂炼魂信息响应
RegPBReq(13713, "DrawSpiritLianhunLevelUpReq", "drawspirit.DrawSpiritLianhunLevelUpReq", 0)	--摄魂炼魂升级请求
RegPBRet(13714, "DrawSpiritLianhunLevelUpRet", "drawspirit.DrawSpiritLianhunLevelUpRet", 0)	--摄魂炼魂升级响应
RegPBReq(13715, "DrawSpiritFazhenInfoReq", "drawspirit.DrawSpiritFazhenInfoReq", 0)	--摄魂法阵信息请求
RegPBRet(13716, "DrawSpiritFazhenInfoRet", "drawspirit.DrawSpiritFazhenInfoRet", 0)	--摄魂法阵信息响应
RegPBReq(13717, "DrawSpiritFazhenLevelUpReq", "drawspirit.DrawSpiritFazhenLevelUpReq", 0)	--摄魂法阵升级请求
RegPBRet(13718, "DrawSpiritFazhenLevelUpRet", "drawspirit.DrawSpiritFazhenLevelUpRet", 0)	--摄魂法阵升级响应


--称谓[13751 - 13800]
RegPBReq(13751, "AppellationDataReq", "appellation.AppellationDataReq", 0)	--称谓数据请求
RegPBRet(13752, "AppellationDataRet", "appellation.AppellationDataRet", 0)	--称谓数据响应
RegPBRet(13753, "AppellationAddRet", "appellation.AppellationAddRet", 0)	--新增称谓通知
RegPBRet(13754, "AppellationUpdateRet", "appellation.AppellationUpdateRet", 0)	--称谓数据更新通知
RegPBRet(13755, "AppellationRemoveRet", "appellation.AppellationRemoveRet", 0)	--删除称谓通知
RegPBReq(13757, "AppellationDisplayReq", "appellation.AppellationDisplayReq", 0)	--装备称谓请求
RegPBRet(13758, "AppellationDisplayRet", "appellation.AppellationDisplayRet", 0)	--装备称谓响应
RegPBReq(13759, "AppellationAttrSetReq", "appellation.AppellationAttrSetReq", 0)	--称谓属性激活请求
RegPBRet(13760, "AppellationAttrSetRet", "appellation.AppellationAttrSetRet", 0)	--称谓属性激活响应

--玩家物品信息查询[13801 - 14000]
RegPBReq(13801, "ItemQueryReq", "itemquery.ItemQueryReq", 111)	--物品查询请求
RegPBRet(13802, "ItemQueryRet", "itemquery.ItemQueryRet", 111)	--物品查询响应
RegPBReq(13803, "RoleInfoQueryReq", "itemquery.RoleInfoQueryReq", 111)	--玩家基本信息查询请求
RegPBRet(13804, "RoleInfoQueryRet", "itemquery.RoleInfoQueryRet", 111)	--玩家基本信息查询响应

--玩家引导数据[14001 - 14020]
RegPBReq(14001, "PlayerGuideDataReq", "playerguide.PlayerGuideDataReq", 0)	--引导数据请求
RegPBRet(14002, "PlayerGuideDataRet", "playerguide.PlayerGuideDataRet", 0)	--引导数据响应
RegPBReq(14003, "PlayerGuideSetReq", "playerguide.PlayerGuideSetReq", 0)	--设置引导数据值

--结婚活动[14021 - 14030]
RegPBReq(14021, "MarriageActStateReq", "marriage.MarriageActStateReq", 20)	--结婚活动数据请求
RegPBRet(14022, "MarriageActStateRet", "marriage.MarriageActStateRet", 20)	--结婚活动数据响应

--角色养成功能相关[14051 - 14200]
RegPBReq(14051, "ShiZhuangYuQiInfoReq", "shizhuang.ShiZhuangYuQiInfoReq", 0)	--时装御器信息请求
RegPBRet(14052, "ShiZhuangYuQiInfoRet", "shizhuang.ShiZhuangYuQiInfoRet", 0)	--时装御器信息响应
RegPBReq(14053, "ShiZhuangYuQiLevelUpReq", "shizhuang.ShiZhuangYuQiLevelUpReq", 0)	--时装御器升级请求
RegPBRet(14054, "ShiZhuangYuQiLevelUpRet", "shizhuang.ShiZhuangYuQiLevelUpRet", 0)	--时装御器升级响应
RegPBReq(14055, "ShiZhuangXianYuInfoReq", "shizhuang.ShiZhuangXianYuInfoReq", 0)	--时装仙羽信息请求
RegPBRet(14056, "ShiZhuangXianYuInfoRet", "shizhuang.ShiZhuangXianYuInfoRet", 0)	--时装仙羽信息响应
RegPBReq(14057, "ShiZhuangXianYuLevelUpReq", "shizhuang.ShiZhuangXianYuLevelUpReq", 0)	--时装仙羽升级请求
RegPBRet(14058, "ShiZhuangXianYuLevelUpRet", "shizhuang.ShiZhuangXianYuLevelUpRet", 0)	--时装仙羽升级响应
RegPBReq(14059, "ShiZhuangStrengthReq", "shizhuang.ShiZhuangStrengthReq", 0)	--时装强化请求





--蒲谭军[18001-23000]
RegPBReq(18001, "PetAttrListReq", "pet.PetAttrListReq", 0) --宠物属性页面请求
RegPBRet(18002, "PetAttrListRet", "pet.PetAttrListRet", 0)	--宠物页面返回
RegPBReq(18003, "PetAddExpReq", "pet.PetAddExpReq", 0)	--宠物添加经验请求
RegPBRet(18004, "PetAddExpRet", "pet.PetAddExpRet", 0)	--宠物添加经验返回
RegPBReq(18005, "PetAddPointReq", "pet.PetAddPointReq", 0)	--宠物加点
RegPBRet(18006, "PetAddPointRet", "pet.PetAddPointRet", 0) --宠物加点返回
RegPBReq(18007, "PetWashPointReq", "pet.PetWashPointReq", 0) --宠物加点
RegPBRet(18008, "PetWashPointRet", "pet.PetWashPointRet", 0) --宠物洗点返回
RegPBRet(18009, "PetChangeMsgRet", "pet.PetChangeMsgRet", 0) --宠物变更返回,1增加,2删除,3属性变化
RegPBReq(18010, "PetReleaseReq", "pet.PetReleaseReq", 0) --宠物放生请求
RegPBReq(18011, "PetRenamedReq", "pet.PetRenamedReq", 0) --宠物改名请求
RegPBReq(18012, "PetCombatReq", "pet.PetCombatReq", 0) --宠物参战请求
RegPBRet(18013, "PetCombatRet", "pet.PetCombatRet", 0) --宠物参战返回
RegPBReq(18014, "PetLianGuReq", "pet.PetLianGuReq", 0) --宠物炼骨请求
RegPBRet(18015, "PetLianGuRet", "pet.PetLianGuRet", 0) --宠物炼骨返回
RegPBReq(18016, "PetXiSuiReq", "pet.PetXiSuiReq", 0) --宠物洗髓请求
RegPBRet(18017, "PetXiSuiRet", "pet.PetXiSuiRet", 0) --宠物洗髓返回
RegPBReq(18018, "PetAddGUReq", "pet.PetAddGUReq", 0) --宠物添加成长请求
RegPBRet(18019, "PetAddGURet", "pet.PetAddGURet", 0) --宠物添加成长返回
RegPBReq(18020, "PetAddLifeReq", "pet.PetAddLifeReq", 0) --宠物添加寿命请求
RegPBRet(18021, "PetAddLifeRet", "pet.PetAddLifeRet", 0) --宠物添加寿命返回
RegPBReq(18022, "PetSillLearnReq", "pet.PetSillLearnReq", 0) --宠物学习技能请求
RegPBRet(18023, "PetSillLearnRet", "pet.PetSillLearnRet", 0) --宠物学习技能返回
RegPBReq(18024, "PetSkillRememberReq", "pet.PetSkillRememberReq", 0) --宠物技能铭记请求
RegPBRet(18025, "PetSkillRememberRet", "pet.PetSkillRememberRet", 0) --宠物技能铭记返回
RegPBReq(18026, "PetAdvancedReq", "pet.PetAdvancedReq", 0) --宠物进化请求
RegPBRet(18027, "PetRenamedRet", "pet.PetRenamedRet", 0) --宠物改名返回
RegPBReq(18028, "PetCancelSkillRememberReq", "pet.PetCancelSkillRememberReq", 0) --取消技能铭记请求
RegPBRet(18029, "PetCancelSkillRememberRet", "pet.PetCancelSkillRememberRet", 0) --取消技能铭记返回
RegPBReq(18030, "PetSkipTipsReq", "pet.PetSkipTipsReq", 0) --记录便捷打书请求
RegPBRet(18031, "PetSkipTipsRet", "pet.PetSkipTipsRet", 0) --记录便捷打书请求返回
RegPBReq(18032, "PetXiSuiSavaReq", "pet.PetXiSuiSavaReq", 0) --洗髓保存请求
RegPBReq(18033, "PetSynthesisReq", "pet.PetSynthesisReq", 0) --宠物合成请求
RegPBRet(18034, "PetSynthesisRet", "pet.PetSynthesisRet", 0) --宠物合成请求返回
RegPBReq(18035, "PetXiSuiPetReq", "pet.PetXiSuiPetReq", 0) --请求洗髓宠物信息
RegPBReq(18036, "PetBuyReq", "pet.PetBuyReq", 0) --宠物购买请求(兑换)
RegPBReq(18037, "PetCarryEpReq", "pet.PetCarryEpReq", 0)  --宠物扩充请求
RegPBRet(18038, "PetCarryEpRet", "pet.PetCarryEpRet", 0) --宠物扩充请求返回
RegPBRet(18039, "PetXiSuiSavaRet", "pet.PetXiSuiSavaRet", 0) --宠物洗髓保存请求返回
RegPBReq(18040, "PetWearEquitReq", "pet.PetWearEquitReq", 0)  --宠物穿装备请求
RegPBRet(18041, "PetWearEquitRet", "pet.PetWearEquitRet", 0)  --宠物穿装备请求返回
RegPBReq(18042, "PetEquitCptReq", "pet.PetEquitCptReq", 0)  --宠物穿装备合成请求
RegPBRet(18043, "PetEquitCptRet", "pet.PetEquitCptRet", 0)  --宠物穿装备合成请求返回
RegPBReq(18044, "PetTalismanResetReq", "pet.PetTalismanResetReq", 0)  --宠物穿装备重置请求
RegPBRet(18045, "PetTalismanResetRet", "pet.PetTalismanResetRet", 0)  --宠物穿装备重置请求返回
RegPBReq(18046, "PetTalismanPBReq", "pet.PetTalismanPBReq", 0)  --获取技能概率请求
RegPBRet(18047, "PetTalismanPBRet", "pet.PetTalismanPBRet", 0)  --获取技能概率请求返回
RegPBReq(18048, "PetAutoAddPointReq", "pet.PetAutoAddPointReq", 0)  --自动加点设置请求
RegPBRet(18049, "PetAutoAddPointRet", "pet.PetAutoAddPointRet", 0)  --自动加点设置请求返回
RegPBReq(18051, "PetPlanInfoReq", "pet.PetPlanInfoReq", 0) --方案信息请求
RegPBRet(18052, "PetPlanInfoRet", "pet.PetPlanInfoRet", 0) --方案信息返回
RegPBReq(18053, "PetPropUSEReq", "pet.PetPropUSEReq", 0) --使用宠物道具请求(38类型)
RegPBReq(18054, "PetSavaRecruitReq", "pet.PetSavaRecruitReq", 0) --保存招募信息请求
RegPBRet(18055, "PetAdvancedRet", "pet.PetAdvancedRet", 0) --宠物进阶请求返回
RegPBReq(18057, "PetYuShouInfoReq", "pet.PetYuShouInfoReq", 0) --宠物御兽信息请求
RegPBRet(18058, "PetYuShouInfoRet", "pet.PetYuShouInfoRet", 0) --宠物御兽信息响应
RegPBReq(18059, "PetYuShouLevelUpReq", "pet.PetYuShouLevelUpReq", 0) --宠物御兽升级请求
RegPBRet(18060, "PetYuShouLevelUpRet", "pet.PetYuShouLevelUpRet", 0) --宠物御兽升级响应
RegPBReq(18061, "PetReviveLevelUpReq", "pet.PetReviveLevelUpReq", 0) --宠物觉醒请求
RegPBRet(18062, "PetReviveLevelUpRet", "pet.PetReviveLevelUpRet", 0) --宠物觉醒响应




--商城系统
RegPBReq(18101, "SystemMallItemListReq", "systemMall.SystemMallItemListReq", 20) --商城列表请求
RegPBRet(18102, "SystemMallItemListRet", "systemMall.SystemMallItemListRet", 20) --商会列表请求返回
RegPBReq(18103, "SystemMallBuyReq", "systemMall.SystemMallBuyReq", 20) --商城购买请求
RegPBRet(18104, "SystemMalluyRet", "systemMall.SystemMalluyRet", 20) --商城购买请求返回
RegPBRet(18105, "SystemMallShopListRet", "systemMall.SystemMallShopListRet", 20) --商城列表返回
RegPBReq(18106, "SystemMallSellReq", "systemMall.SystemMallSellReq", 20) --商品出售请求
RegPBReq(18107, "SystemMallUpdateReq", "systemMall.SystemMallUpdateReq", 20) --特惠商城刷新请求
RegPBReq(18108, "SystemMallGoidBuyReq", "systemMall.SystemMallGoidBuyReq", 20) --购买金币,银币请求
RegPBReq(18109, "SystemMallFastBuyListReq", "systemMall.SystemMallFastBuyListReq", 20) --快速购买列表请求
RegPBRet(18110, "SystemMallFastBuyListRet", "systemMall.SystemMallFastBuyListRet", 20) --快速购买列表请求返回
RegPBReq(18111, "SystemMallFastBuyReq", "systemMall.SystemMallFastBuyReq", 20) --宠物快速购买技能(学习)
RegPBReq(18112, "SystemUnionContriAmountReq", "systemMall.SystemUnionContriAmountReq", 20) --请求帮贡可购买数目
RegPBRet(18113, "SystemUnionContriAmountRet", "systemMall.SystemUnionContriAmountRet", 20) --返回帮贡可购买数目
RegPBReq(18114, "SystemGetShopPriceReq", "systemMall.SystemGetShopPriceReq", 20) --商会价格获取请(出售专用)
RegPBRet(18115, "SystemGetShopPriceRet", "systemMall.SystemGetShopPriceRet", 20) --商会价格获取请返回
RegPBReq(18116, "SystemGetPropPriceReq", "systemMall.SystemGetPropPriceReq", 20) --商会价格获取请(元宝,金币,银币)
RegPBRet(18117, "SystemGetPropPriceRet", "systemMall.SystemGetPropPriceRet", 20) --商会价格获取请(元宝,金币,银币)返回
RegPBReq(18118, "systemMallMoneyConvertReq", "systemMall.systemMallMoneyConvertReq", 20) --兑换请求
RegPBRet(18119, "systemMallMoneyConvertRet", "systemMall.systemMallMoneyConvertRet", 20) --兑换请求返回







--限时PVE活动
RegPBReq(18120, "PVEMatchTeamReq", "pve.PVEMatchTeamReq", 0) --PVE创建队伍,便捷组队请求
RegPBRet(18121, "PVERewardSendClientRet", "pve.PVERewardSendClientRet", 0) --战斗结束下发奖励到前端
RegPBReq(18122, "PVECreateMonsterReq", "pve.PVECreateMonsterReq", 0) --创建怪物请求
RegPBReq(18123, "PVEEnterBattleDupReq", "pve.PVEEnterBattleDupReq", 0) --玩家点击进入副本
RegPBRet(18124, "PVEDupPinTuSendClientRet", "pve.PVEDupPinTuSendClientRet", 0) --副本为拼图通知客户端
RegPBReq(18125, "PVEClickRewardReq", "pve.PVEClickRewardReq", 0) --玩家点击翻牌请求
RegPBReq(18126, "PVEClickCrackOrganReq", "pve.PVEClickCrackOrganReq", 0) --玩家点击破解机关
RegPBRet(18127, "PVEClickCrackOrganRet", "pve.PVEClickCrackOrganRet", 0) --玩家点击破解机关返回
RegPBReq(18128, "PVEPinTuResuitReq", "pve.PVEPinTuResuitReq", 0) --玩家拼图结果返回请求
RegPBRet(18129, "PVEClickRewardRet", "pve.PVEClickRewardRet", 0) --玩家点击破解机关返回
RegPBRet(18130, "PVEStartTimeRet", "pve.PVEStartTimeRet", 0) --玩家活动倒计时推送
RegPBRet(18131, "PVENavigateRet", "pve.PVENavigateRet", 0) --寻路推送
RegPBRet(18132, "PVEFlopSendClientRet", "pve.PVEFlopSendClientRet", 0) --翻牌奖励通知客户端
RegPBRet(18133, "PVEDupInfoUpdateRet", "pve.PVEDupInfoUpdateRet", 0) --副本信息变化下发
RegPBRet(18134, "PVERoleOnlineRet", "pve.PVERoleOnlineRet", 0) --玩家上线活动信息下发
RegPBReq(18135, "PVESwitchMapReq", "pve.PVESwitchMapReq", 0)	--地图切换
RegPBRet(18136, "PVESwitchMapRet", "pve.PVESwitchMapRet", 0)	--地图切换返回
RegPBRet(18137, "PVECloseBrandRet", "pve.PVECloseBrandRet", 0)	--统一拼图完成返回
RegPBRet(18138, "PVERewardCompleteRet", "pve.PVERewardCompleteRet", 0)	--今日是否全部关卡领取奖励完成



--生活技能
RegPBReq(18140, "lifeskillListReq", "lifeskill.lifeskillListReq", 0)	--生活技能列表请求
RegPBRet(18141, "lifeskillListRet", "lifeskill.lifeskillListRet", 0)	--生活技能列表请求返回
RegPBReq(18142, "lifeskillManufactureItemReq", "lifeskill.lifeskillManufactureItemReq", 0)	--技能制造请求
RegPBReq(18143, "lifeskillUpgradeReq", "lifeskill.lifeskillUpgradeReq", 0)	--技能升级请求
RegPBReq(18144, "lifeskillVitalityPagReq", "lifeskill.lifeskillVitalityPagReq", 0)	--活力兑换页面请求
RegPBRet(18145, "lifeskillVitalityPagRet", "lifeskill.lifeskillVitalityPagRet", 0)	--活力兑换页面请求返回
RegPBReq(18146, "lifeskillVitalityMakeReq", "lifeskill.lifeskillVitalityMakeReq", 0)	--活力兑换制造请求
RegPBRet(18147, "lifeskillVitalityMakeRet", "lifeskill.lifeskillVitalityMakeRet", 0)	--活力兑换制造请求返回
RegPBReq(18148, "lifeskillAddVitalityReq", "lifeskill.lifeskillAddVitalityReq", 0)		--活力增加请求
RegPBRet(18149, "lifeskillAddVitalityRet", "lifeskill.lifeskillAddVitalityRet", 0)	--活力增加请求返回
RegPBRet(18150, "lifeskillStateRet", "lifeskill.lifeskillStateRet", 0)	--小红点推送



--法宝系统
RegPBReq(18160, "FaBaoAttrPageReq", "fabao.FaBaoAttrPageReq", 0) --法宝属性页面请求
RegPBRet(18161, "FaBaoKnapsackItemListRet", "fabao.FaBaoKnapsackItemListRet", 0) --法宝背包信息同步
RegPBReq(18162, "FaBaoWearReq", "fabao.FaBaoWearReq", 0)	--穿法宝请求
RegPBReq(18163, "FaBaoTakeOffReq", "fabao.FaBaoTakeOffReq", 0) --脱法宝请求
RegPBReq(18164, "FaBaoFeastReq", "fabao.FaBaoFeastReq", 0) --法宝祭炼请求
RegPBReq(18165, "FaBaoCompositeReq", "fabao.FaBaoCompositeReq", 0) --法宝合成请求
RegPBReq(18166, "FaBaoResetReq", "fabao.FaBaoResetReq", 0) --法宝重置请求
RegPBRet(18167, "FaBaoResetRet", "fabao.FaBaoResetRet", 0) --法宝重置请求返回
RegPBRet(18168, "FaBaoAttrPageRet", "fabao.FaBaoAttrPageRet", 0) --法宝属性页面请求返回
RegPBRet(18169, "FaBaoWearRet", "fabao.FaBaoWearRet", 0) --穿法宝请求返回
RegPBRet(18170, "FaBaoTakeOffRet", "fabao.FaBaoTakeOffRet", 0) --脫法宝请求返回
RegPBRet(18171, "FaBaoCompositeRet", "fabao.FaBaoCompositeRet", 0) --法宝合成返回
RegPBReq(18172, "FaBaoFalgReq", "fabao.FaBaoFalgReq", 0) --标记请求
RegPBRet(18173, "FaBaoFalgRet", "fabao.FaBaoFalgRet", 0) --标记请求返回
RegPBRet(18174, "FaBaoPropRemoveRet", "fabao.FaBaoPropRemoveRet", 0) --法宝移除返回
RegPBRet(18175, "FaBaoAddRet", "fabao.FaBaoAddRet", 0) --法宝增加返回
RegPBReq(18176, "FaBaoOnekeyUpgradeReq", "fabao.FaBaoOnekeyUpgradeReq", 0) --一键升级
RegPBRet(18177, "FaBaoOnekeyUpgradeRet", "fabao.FaBaoOnekeyUpgradeRet", 0) --一键升级返回




--妖兽突袭
RegPBRet(18190, "yaoshoutuxiInitInfoRet", "yaoshoutuxi.yaoshoutuxiInitInfoRet", 20) --任务信息下发
RegPBReq(18191, "yaoshoutuxiAttacReq", "yaoshoutuxi.yaoshoutuxiAttacReq", 20) --玩家攻击怪物
RegPBRet(18192, "yaoshoutuxiTaskTimesRet", "yaoshoutuxi.yaoshoutuxiTaskTimesRet", 20) --任务次数改变下发



--神器系统
RegPBReq(18220, "ArtifactListReq", "artifact.ArtifactListReq", 0) --神器列表请求
RegPBRet(18221, "ArtifactListRet", "artifact.ArtifactListRet", 0) --神器列表请求返回
RegPBReq(18222, "ArtifactUpgradeReq", "artifact.ArtifactUpgradeReq", 0) --神器升级请求
RegPBRet(18223, "ArtifactUpgradeRet", "artifact.ArtifactUpgradeRet", 0) --神器升级请求返回
RegPBReq(18224, "ArtifactAscendingStarReq", "artifact.ArtifactAscendingStarReq", 0) --神器升星请求
RegPBRet(18225, "ArtifactAscendingStarRet", "artifact.ArtifactAscendingStarRet", 0) --神器升星请求返回
RegPBReq(18226, "ArtifactAddExpReq", "artifact.ArtifactAddExpReq", 0) --进阶经验添加
RegPBRet(18227, "ArtifactAddExpRet", "artifact.ArtifactAddExpRet", 0) --进阶经验添加请求返回
RegPBRet(18228, "ArtifactChangeRet", "artifact.ArtifactChangeRet", 0) --神器属性变化返回
RegPBReq(18229, "ArtifactUseShapeReq", "artifact.ArtifactUseShapeReq", 0) --使用当前神器请求
RegPBRet(18230, "ArtifactUseShapeRet", "artifact.ArtifactUseShapeRet", 0) --使用当前神器请求返回
RegPBReq(18231, "ArtifactCallUseShapeReq", "artifact.ArtifactCallUseShapeReq", 0) --取消使用当前神器请求
RegPBRet(18232, "ArtifactCallUseShapeRet", "artifact.ArtifactCallUseShapeRet", 0) --取消使用当前神器请求返回
RegPBReq(18233, "ArtifactUseReq", "artifact.ArtifactUseReq", 0) --使用神器请求(激活)
RegPBRet(18234, "ArtifactUseRet", "artifact.ArtifactUseRet", 0) --使用神器请求(激活)返回






--赠送系统
RegPBReq(18280, "GiftPropReq", "gift.GiftPropReq", 110) --赠送道具请求
RegPBRet(18281, "GiftPropRet", "gift.GiftPropRet", 0) --赠送道具请求返回
RegPBReq(18282, "GiftGetRecordInfoReq", "gift.GiftGetRecordInfoReq", 110) --获取赠送记录信息请求
RegPBRet(18283, "GiftGetRecordInfoRet", "gift.GiftGetRecordInfoRet", 0) --获取赠送记录信息请求返回
RegPBReq(18284, "GiftGetSendNumReq", "gift.GiftGetSendNumReq", 110) --获取赠送进度数据
RegPBRet(18285, "GiftGetSendNumRet", "gift.GiftGetSendNumRet", 0) --获取赠送进度数据返回

--八荒火阵
RegPBReq(18300, "BaHuangHuoZhenBoxListReq", "bahuanghuozhen.BaHuangHuoZhenBoxListReq", 0) --宝箱列表请求
RegPBRet(18301, "BaHuangHuoZhenBoxListRet", "bahuanghuozhen.BaHuangHuoZhenBoxListRet", 0) --宝箱列表请求返回
RegPBRet(18302, "BaHuangHuoZhenBoxChangeRet", "bahuanghuozhen.BaHuangHuoZhenBoxChangeRet", 0) --单个宝箱信息变化返回
RegPBReq(18303, "BaHuangHuoZhenReceiveReq", "bahuanghuozhen.BaHuangHuoZhenReceiveReq", 0) --领取完成宝箱奖励请求
RegPBRet(18304, "BaHuangHuoZhenReceiveRet", "bahuanghuozhen.BaHuangHuoZhenReceiveRet", 0) --领取完成宝箱奖励请求返回
RegPBReq(18305, "BaHuangHuoZhenPackingReq", "bahuanghuozhen.BaHuangHuoZhenPackingReq", 0) --装箱请求
RegPBRet(18306, "BaHuangHuoZhenPackingRet", "bahuanghuozhen.BaHuangHuoZhenPackingRet", 0) --装箱请求返回
RegPBReq(18307, "BaHuangHuoZhenBoxHelpReq", "bahuanghuozhen.BaHuangHuoZhenBoxHelpReq", 0) --宝箱求助请求
RegPBRet(18308, "BaHuangHuoZhenBoxHelpRet", "bahuanghuozhen.BaHuangHuoZhenBoxHelpRet", 0) --宝箱求助请求返回
RegPBReq(18309, "BahuanghuozhenHelpPackingBoxReq", "bahuanghuozhen.BahuanghuozhenHelpPackingBoxReq", 0) --玩家帮助装箱请求
RegPBRet(18310, "BahuanghuozhenHelpPackingBoxRet", "bahuanghuozhen.BahuanghuozhenHelpPackingBoxRet", 0) --玩家帮助装箱请求返回
RegPBReq(18311, "BaHuangHuoZhenHelpPlayerBoxListReq", "bahuanghuozhen.BaHuangHuoZhenHelpPlayerBoxListReq", 0) --获取求助玩家宝箱列表请求
RegPBRet(18312, "BaHuangHuoZhenHelpPlayerBoxListRet", "bahuanghuozhen.BaHuangHuoZhenHelpPlayerBoxListRet", 0) --获取求助玩家宝箱列表请求返回
RegPBRet(18313, "BaHuangHuoZhenPracticeChangeRet", "bahuanghuozhen.BaHuangHuoZhenPracticeChangeRet", 0) --修炼技能变化通知
RegPBReq(18314, "BaHuangHuoZhenPickupTaskReq", "bahuanghuozhen.BaHuangHuoZhenPickupTaskReq", 0) --接取任务请求
RegPBRet(18315, "BaHuangHuoZhenPickupTaskRet", "bahuanghuozhen.BaHuangHuoZhenPickupTaskRet", 0) --接取任务请求返回
RegPBReq(18316, "BaHuangHuoZhenInfoTaskReq", "bahuanghuozhen.BaHuangHuoZhenInfoTaskReq", 0) --任务信息请求
RegPBRet(18317, "BaHuangHuoZhenInfoTaskRet", "bahuanghuozhen.BaHuangHuoZhenInfoTaskRet", 0) --任务信息请求返回




--付费推送
RegPBRet(18340, "PayPushIDRet", "paypush.PayPushIDRet", 0) --推送付费ID
RegPBReq(18341, "PayPushReceiveRewardReq", "paypush.PayPushReceiveRewardReq", 0) --领奖请求
RegPBRet(18342, "PayPushReceiveRewardRet", "paypush.PayPushReceiveRewardRet", 0) --领奖请求返回


--胡长生[23001-24000]
--野外商店
RegPBReq(23001, "ShopItemListReq", "shop.ShopItemListReq", 0) --商品列表请求
RegPBRet(23002, "ShopItemListRet", "shop.ShopItemListRet", 0) --商品列表返回
RegPBReq(23003, "ShopBuyReq", "shop.ShopBuyReq", 0) 		  --购买商品请求
RegPBRet(23004, "ShopBuyRet", "shop.ShopBuyRet", 0)      	  --购买商品返回

--冲榜活动
RegPBReq(23024, "CBInfoReq", "chongbang.CBInfoReq", 20)               --冲榜信息请求
RegPBRet(23025, "CBInfoRet", "chongbang.CBInfoRet", 0)                --冲榜信息返回
RegPBReq(23026, "CBInActivityReq", "chongbang.CBInActivityReq", 20)   --冲榜进入活动请求
RegPBRet(23027, "CBInActivityRet", "chongbang.CBInActivityRet", 0)    --冲榜进入活动返回
RegPBReq(23028, "CBRankingReq", "chongbang.CBRankingReq", 20)         --冲榜榜单请求
RegPBRet(23029, "CBRankingRet", "chongbang.CBRankingRet", 0)          --冲榜榜单返回
RegPBReq(23030, "CBGetAwardReq", "chongbang.CBGetAwardReq", 20)       --冲榜奖励请求
RegPBRet(23031, "CBGetAwardRet", "chongbang.CBGetAwardRet", 0)  	  --冲榜奖励返回

--仙缘
RegPBReq(23051, "XYStateReq", "actxy.XYStateReq", 20)	--活动状态信息请求
RegPBRet(23052, "XYStateRet", "actxy.XYStateRet", 0)	--活动状态信息返回
RegPBReq(23053, "XYPropListReq", "actxy.XYPropListReq", 20)	--道具列表请求
RegPBRet(23054, "XYPropListRet", "actxy.XYPropListRet", 0)	--道具列表返回
RegPBReq(23055, "XYBuyPropReq", "actxy.XYBuyPropReq", 20)	--购买道具请求
RegPBReq(23056, "XYUsePropReq", "actxy.XYUsePropReq", 20)	--使用道具请求
RegPBRet(23057, "XYUsePropRet", "actxy.XYUsePropRet", 0)	--使用道具成功返回
RegPBReq(23058, "XYAwardInfoReq", "actxy.XYAwardInfoReq", 20)	--活动奖励信息请求
RegPBRet(23059, "XYAwardInfoRet", "actxy.XYAwardInfoRet", 0)	--活动奖励信息返回
RegPBReq(23060, "XYAwardReq", "actxy.XYAwardReq", 20)	--活动奖励领取请求
RegPBReq(23061, "XYExchangeListReq", "actxy.XYExchangeListReq", 20)	--活动兑换列表请求
RegPBRet(23062, "XYExchangeListRet", "actxy.XYExchangeListRet", 0)	--活动兑换列表返回
RegPBReq(23063, "XYExchangeReq", "actxy.XYExchangeReq", 20)	--兑换物品请求
RegPBReq(23064, "XYRankingReq", "actxy.XYRankingReq", 20)	--排行榜请求
RegPBRet(23065, "XYRankingRet", "actxy.XYRankingRet", 0)	--排行榜返回
RegPBReq(23066, "XYRankAwardInfoReq", "actxy.XYRankAwardInfoReq", 20)	--排行奖励信息请求
RegPBRet(23067, "XYRankAwardInfoRet", "actxy.XYRankAwardInfoRet", 0)	--排行奖励信息返回
RegPBReq(23068, "XYRankAwardReq", "actxy.XYRankAwardReq", 20)	--领取排行奖励请求
RegPBReq(23069, "XYDayAwardReq", "actxy.XYDayAwardReq", 20)	--每日奖励领取请求

--累登活动
RegPBReq(23360, "ActLDStateReq", "actld.ActLDStateReq", 20)		--活动状态信息请求
RegPBRet(23361, "ActLDStateRet", "actld.ActLDStateRet", 0)     --活动状态返回
RegPBReq(23362, "ActLDInfoReq", "actld.ActLDInfoReq", 20)		--活动信息请求
RegPBRet(23363, "ActLDInfoRet", "actld.ActLDInfoRet", 0)   		--活动信息返回
RegPBReq(23364, "ActLDAwardReq", "actld.ActLDAwardReq", 20)	 	--领取奖励请求

--冲榜礼包活动
RegPBReq(23370, "ActLCStateReq", "actlc.ActLCStateReq", 20)		--活动状态信息请求
RegPBRet(23371, "ActLCStateRet", "actlc.ActLCStateRet", 0)     	--活动状态返回
RegPBReq(23372, "ActLCInfoReq", "actlc.ActLCInfoReq", 20)		--活动信息请求
RegPBRet(23373, "ActLCInfoRet", "actlc.ActLCInfoRet", 0)   		--活动信息返回
RegPBReq(23374, "ActLCAwardReq", "actlc.ActLCAwardReq", 20)	 	--领取奖励请求

--限时奖励
RegPBReq(23380, "TimeAwardStateReq", "timeaward.TimeAwardStateReq", 20)			--限时活动状态请求
RegPBRet(23381, "TimeAwardStateRet", "timeaward.TimeAwardStateRet", 0)     		--限时活动状态返回
RegPBReq(23382, "TimeAwardProgressReq", "timeaward.TimeAwardProgressReq", 20)	--活动进度请求
RegPBRet(23383, "TimeAwardProgressRet", "timeaward.TimeAwardProgressRet", 0)   	--活动进度返回
RegPBReq(23384, "TimeAwardRankingReq", "timeaward.TimeAwardRankingReq", 20)	 	--活动排行榜请求
RegPBRet(23385, "TimeAwardRankingRet", "timeaward.TimeAwardRankingRet", 0)	 	--活动排行榜返回
RegPBReq(23386, "TimeAwardAwardReq", "timeaward.TimeAwardAwardReq", 20)	 		--领取奖励请求
RegPBRet(23387, "TimeAwardAwardRet", "timeaward.TimeAwardAwardRet", 0)	 		--领取奖励成功返回

--名人堂
RegPBRet(23500, "HallFameInfoRet", "hallfame.HallFameInfoRet", 0)           			--名人堂信息
RegPBReq(23501, "HallFameCongratReq", "hallfame.HallFameCongratReq", 20)           		--名人堂祝贺返回
RegPBReq(23502, "HallFameSetCongratTipsReq", "hallfame.HallFameSetCongratTipsReq", 20) 	--名人堂设置贺词请求
RegPBRet(23503, "HallFameSetCongratTipsRet", "hallfame.HallFameSetCongratTipsRet", 0) 	--名人堂设置贺词返回

--排行榜
RegPBReq(23521, "RankingListReq", "ranking.RankingListReq", 20) 	--排行榜请求
RegPBRet(23522, "RankingListRet", "ranking.RankingListRet", 0) 		--排行榜返回
RegPBRet(23523, "RankingRedpointRet", "ranking.RankingRedpointRet", 0) 	--排行榜祝贺红点返回
RegPBReq(23524, "RankingCongratReq", "ranking.RankingCongratReq", 20) 	--排行榜祝贺请求

--零元活动
RegPBReq(23540, "ZYActStateReq", "actzeroyuan.ZYActStateReq", 20) --活动状态信息请求
RegPBRet(23541, "ZYActStateRet", "actzeroyuan.ZYActStateRet", 0) --活动状态信息请求返回p
RegPBReq(23542, "ZYActInfoReq", "actzeroyuan.ZYActInfoReq", 20) --活动信息请求
RegPBRet(23543, "ZYActInfoRet", "actzeroyuan.ZYActInfoRet", 0) --活动信息请求返回
RegPBReq(23544, "ZYActAwardReq", "actzeroyuan.ZYActAwardReq", 20) --领取奖励请求
RegPBRet(23545, "ZYActAwardRet", "actzeroyuan.ZYActAwardRet", 0) --领取奖励请求返回
RegPBReq(23546, "ZYBuyQualificattionsReq", "actzeroyuan.ZYBuyQualificattionsReq", 20) --购买资格请求
RegPBRet(23547, "ZYBuyQualificattionsRet", "actzeroyuan.ZYBuyQualificattionsRet", 0) --购买资格请求返回

--李柯僖[24001-25000]
--任务系统
RegPBReq(24001, "TouchNpcReq", "tasksystem.TouchNpcReq", 0)					--任务请求
RegPBRet(24002, "TaskAllInfoRet", "tasksystem.TaskAllInfoRet", 0)			--任务列表
RegPBRet(24003, "TaskSingleInfoRet", "tasksystem.TaskSingleInfoRet", 0)		--单个任务信息

--师门任务
RegPBReq(24006, "ShiMenTaskReq", "shimentask.ShiMenTaskReq", 0)
RegPBRet(24007, "ShiMenTaskActRet", "shimentask.ShiMenTaskActRet", 0)
RegPBRet(24008, "ShiMenTaskRet", "shimentask.ShiMenTaskRet", 0)

--战斗副本入口
RegPBReq(24100, "EnterBattleDupReq", "battledup.EnterBattleDupReq", 0) 	--进入战斗副本请求
RegPBReq(24101, "LeaveBattleDupReq", "battledup.LeaveBattleDupReq", 0) 	--离开战斗副本请求

--副本通用
RegPBRet(24130, "BattleDupInfoRet", "battledup.BattleDupInfoRet", 0) 			    --副本信息返回
RegPBReq(24132, "AttackMonsterReq", "battledup.AttackMonsterReq", 0) 				--攻击怪物请求
RegPBReq(24135, "CreateMonsterReq", "battledup.CreateMonsterReq", 0)				--创建怪物

--镇妖
RegPBReq(24131, "ZhenYaoCreateMonsterReq", "battledup.ZhenYaoCreateMonsterReq", 0)  --镇妖创建怪物请求
RegPBReq(24133, "DupBuffOperaReq", "battledup.DupBuffOperaReq", 0) 				    --镇妖服务经验加成操作请求
RegPBRet(24134, "DupBuffOperaRet", "battledup.DupBuffOperaRet", 0) 					--副本特殊面板信息返回
RegPBReq(24136, "ZhenYaoMatchTeamReq", "battledup.ZhenYaoMatchTeamReq", 0)  		--镇妖匹配队伍请求


--心魔侵蚀
RegPBRet(24139, "XinMoQinShiMonListRet", "battledup.XinMoQinShiMonListRet", 0)		--心魔侵蚀怪物信息

--日程
RegPBReq(24149, "ClickCanJoinActButtonReq", "dailyactivity.ClickCanJoinActButtonReq", 0)  	--点击参加活动按钮
RegPBReq(24150, "DailyActivityReq", "dailyactivity.DailyActivityReq", 0)					--日程活动请求
RegPBRet(24151, "ActivityInfoListRet", "dailyactivity.ActivityInfoListRet", 0)				--日程所有活动信息
RegPBRet(24152, "ActivitySingleInfoRet", "dailyactivity.ActivitySingleInfoRet", 0)			--日程单个活动信息
RegPBRet(24153, "DayActListRet", "dailyactivity.DayActListRet", 0)							--日程某天活动信息
RegPBRet(24154, "DailyActOpenEventNotifyRet", "dailyactivity.DailyActOpenEventNotifyRet", 0)  --限时活动开启通知

--挂机
RegPBReq(24155, "GuaJiReq", "guaji.GuaJiReq", 0)												--挂机请求
RegPBRet(24156, "GuaJiStatusRet", "guaji.GuaJiStatusRet", 0)									--挂机信息通知
RegPBReq(24157, "GuaJiBattleEndNoticeReq", "guaji.GuaJiBattleEndNoticeReq", 0)					--挂机战斗动画结束通知
RegPBReq(24158, "GuaJiAutoBattleOperaReq", "guaji.GuaJiAutoBattleOperaReq", 0)					--挂机自动战斗操作		
RegPBReq(24159, "GuaJiChalBossReq", "guaji.GuaJiChalBossReq", 0)								--挂机挑战boss请求
RegPBRet(24160, "GuaJiRet", "guaji.GuaJiRet", 0)												--是否挂机信息

--神兽乐园
RegPBReq(24161, "ShenShouLeYuanChalReq", "battledup.ShenShouLeYuanChalReq", 0)	--挑战貔貅请求

--时装(包含器灵)
RegPBReq(24162, "ShiZhuangAllInfoReq", "shizhuang.ShiZhuangAllInfoReq", 0)		--时装所有信息请求
RegPBReq(24163, "ShiZhuangPutOnReq", "shizhuang.ShiZhuangPutOnReq", 0)			--时装穿戴请求
RegPBReq(24164, "ShiZhuangPutOffReq", "shizhuang.ShiZhuangPutOffReq", 0)		--时装卸下请求
RegPBReq(24165, "ShiZhuangWashReq", "shizhuang.ShiZhuangWashReq", 0)			--时装洗练请求
RegPBReq(24166, "ShiZhuangAttrReplaceReq", "shizhuang.ShiZhuangAttrReplaceReq", 0)			--时装洗练属性置换请求
RegPBReq(24167, "QiLingUpGradeReq", "shizhuang.QiLingUpGradeReq", 0)			--器灵进阶请求
RegPBRet(24168, "ShiZhuangAllInfoRet", "shizhuang.ShiZhuangAllInfoRet", 0)		--时装所有信息应答
RegPBRet(24169, "ShiZhuangWashInfoRet", "shizhuang.ShiZhuangWashInfoRet", 0)	--时装洗练信息应答
RegPBRet(24170, "ShiZhuangInfoRet", "shizhuang.ShiZhuangInfoRet", 0)			--时装单个信息应答
RegPBRet(24171, "QiLingInfoRet", "shizhuang.QiLingInfoRet", 0)					--器灵所有信息应答
RegPBReq(24172, "QiLingAllInfoReq", "shizhuang.QiLingAllInfoReq", 0)			--器灵所有信息请求
RegPBReq(24173, "ShiZhuangActReq", "shizhuang.ShiZhuangActReq", 0)				--激活时装
RegPBReq(24174, "QiLingAutoUpLevelReq", "shizhuang.QiLingAutoUpLevelReq", 0)	--器灵一键升级

--天帝宝物
RegPBReq(24177, "GoldBoxReq", "tiandibaowu.GoldBoxReq", 0)                      --天帝宝物打开界面
RegPBRet(24178, "GoldBoxRet", "tiandibaowu.GoldBoxRet", 0)                      --天帝宝物界面信息应答
RegPBRet(24179, "ShowOpenGoldBoxRet", "tiandibaowu.ShowOpenGoldBoxRet", 0)		--天帝宝物抽到物品展示
RegPBRet(24180, "OpenGoldBoxViewRet", "tiandibaowu.OpenGoldBoxViewRet", 0)		--天帝宝图开启宝箱结果预览
RegPBReq(24181, "OpenGoldBoxReq", "tiandibaowu.OpenGoldBoxReq", 0)				--天帝宝物开启宝箱请求
RegPBReq(24182, "FuYuanExchangeReq", "tiandibaowu.FuYuanExchangeReq", 0)		--天帝宝物福缘兑换请求
RegPBRet(24183, "GoldBoxInfoListRet", "tiandibaowu.GoldBoxInfoListRet", 0)		--天帝宝物信息应答
RegPBRet(24184, "GoleBoxReMoveRet", "tiandibaowu.GoleBoxReMoveRet", 0)			--天帝宝物宝箱移除广播信息

--宝图任务
RegPBReq(24185, "WaBaoReq", "baotu.WaBaoReq", 0)				--挖宝坐标请求
RegPBReq(24186, "MapCompReq", "baotu.MapCompReq", 0)			--高级藏宝图合成
RegPBReq(24187, "WaBaoStatusReq", "baotu.WaBaoStatusReq", 0)	--挖宝状态请求
RegPBRet(24188, "WaBaoPosRet", "baotu.WaBaoPosRet", 0)			--挖宝坐标应答
RegPBRet(24189, "WaBaoResultRet", "baotu.WaBaoResultRet", 0)	--挖宝结果应答
RegPBReq(24190, "WaBaoInfoReq", "baotu.WaBaoInfoReq", 0)		--宝图信息请求

--赏金任务
RegPBReq(24193, "ShangJinAllTaskReq", "shangjintask.ShangJinAllTaskReq", 0)		--赏金任务所有信息请求
RegPBReq(24194, "ShangJinRefreshReq", "shangjintask.ShangJinRefreshReq", 0)		--赏金任务请求刷新
RegPBReq(24195, "ShangJinAccepReq", "shangjintask.ShangJinAccepReq", 0)			--接取赏金任务
RegPBReq(24196, "ShangJinAttReq", "shangjintask.ShangJinAttReq", 0)				--赏金任务攻击请求
RegPBRet(24197, "ShangJinAllTaskRet", "shangjintask.ShangJinAllTaskRet", 0)		--赏金任务所有信息
RegPBRet(24198, "ShangJinAccepRet", "shangjintask.ShangJinAccepRet", 0)			--当前接取赏金任务信息
RegPBReq(24199, "YuanBaoCompReq", "shangjintask.YuanBaoCompReq", 0)				--赏金任务元宝完成

--试炼任务
RegPBReq(24201, "ShiLianTaskAccepReq", "shiliantask.ShiLianTaskAccepReq", 0)	--试炼任务接取
RegPBReq(24202, "ShiLianTaskCommitReq", "shiliantask.ShiLianTaskCommitReq", 0)	--提交试炼任务
RegPBRet(24203, "ShiLianTaskInfoRet", "shiliantask.ShiLianTaskInfoRet", 0)		--接取到的任务
RegPBRet(24204, "ShiLianTaskCommitRet", "shiliantask.ShiLianTaskCommitRet", 0)	--提交任务结果
RegPBRet(24205, "ShiLianRewardRet", "shiliantask.ShiLianRewardRet", 0)			--试炼任务奖励

--副本中转场景
RegPBReq(24211, "EnterFBTransitSceneReq", "battledup.EnterFBTransitSceneReq", 0)--请求进入副本中转场景

--目标任务
RegPBReq(24214, "TargetTaskInfoReq", "targettask.TargetTaskInfoReq", 0)			--目标任务信息请求
RegPBRet(24215, "TargetTaskInfoRet", "targettask.TargetTaskInfoRet", 0)			--目标任务信息应答
RegPBReq(24216, "TargetTaskRewardReq", "targettask.TargetTaskRewardReq", 0)		--目标任务领取奖励
RegPBReq(24217, "TargetTaskBattleReq", "targettask.TargetTaskBattleReq", 0)		--目标任务训练

--节日活动
RegPBReq(24218, "HolidayActAllInfoReq", "holidayactivity.HolidayActAllInfoReq", 0)			--节日活动界面请求
RegPBRet(24219, "HolidayActInfoListRet", "holidayactivity.HolidayActInfoListRet", 0)		--节日活动界面应答
RegPBRet(24220, "HolidayActSingleInfoRet", "holidayactivity.HolidayActSingleInfoRet", 0)	--节日活动单个活动信息
RegPBReq(24221, "HolidayActJoinReq", "holidayactivity.HolidayActJoinReq", 0)				--节日活动请求参加

--学富五车
RegPBReq(24224, "AnswerAllInfoReq", "holidayactivity.AnswerAllInfoReq", 0)					--答题界面信息请求
RegPBRet(24225, "AnswerAllInfoRet", "holidayactivity.AnswerAllInfoRet", 0)					--答题界面所有信息应答
RegPBReq(24226, "AnswerReq", "holidayactivity.AnswerReq", 0)								--答题
RegPBRet(24227, "AnswerNoticeRet", "holidayactivity.AnswerNoticeRet", 0)					--答题活动可参加通知

--江湖历练
RegPBReq(24230, "ExperienceAcceptReq", "holidayactivity.ExperienceAcceptReq", 0)			--江湖历练任务接取
RegPBRet(24231, "ExperienceTaskRet", "holidayactivity.ExperienceTaskRet", 0)				--江湖历练任务信息
RegPBReq(24232, "ExperienceCommitReq", "holidayactivity.ExperienceCommitReq", 0)			--江湖历练提交任务

--尊师考验
RegPBReq(24235, "TeachTestJoinReq", "holidayactivity.TeachTestJoinReq", 0)					--参加尊师考验请求
RegPBRet(24236, "TeachTestNextMonInfoRet", "holidayactivity.TeachTestNextMonInfoRet", 0)	--尊师考验下个目标

--策马奔腾
RegPBReq(24240, "HorseRaceStartReq", "holidayactivity.HorseRaceStartReq", 0)				--策马奔腾开始请求
RegPBRet(24241, "HorseRaceInfoRet", "holidayactivity.HorseRaceInfoRet", 0)					--策马奔腾信息
RegPBReq(24242, "HorseRaceLeaveReq", "holidayactivity.HorseRaceLeaveReq", 0)				--通知服务端点击离开
RegPBReq(24243, "HorseRaceAnswerReq", "holidayactivity.HorseRaceAnswerReq", 0)				--策马奔腾点击验证
RegPBRet(24244, "HorseRaceAnswerRet", "holidayactivity.HorseRaceAnswerRet", 0)				--策马奔腾点击结果
RegPBRet(24245, "HorseRaceEndNoticRet", "holidayactivity.HorseRaceEndNoticRet", 0)			--本次结束通知

--兑换活动
RegPBReq(24251, "ExchangeActInfoReq", "exchangeactivity.ExchangeActInfoReq", 20)				--兑换活动信息请求
RegPBRet(24252, "ExchangeInfoListRet", "exchangeactivity.ExchangeInfoListRet", 0)			--兑换活动信息应答
RegPBReq(24253, "ExchangeReq", "exchangeactivity.ExchangeReq", 20)							--兑换请求
RegPBRet(24254, "ExchangeInfoRet", "exchangeactivity.ExchangeInfoRet", 0)					--单条兑换信息
RegPBRet(24255, "ActStateChangeNoticRet", "exchangeactivity.ActStateChangeNoticRet", 0)		--兑换活动状态改变通知
RegPBReq(24256, "ExchangeActClickReq", "exchangeactivity.ExchangeActClickReq", 20)			--兑换活动点击请求
RegPBRet(24257, "ExchangeActClickRet", "exchangeactivity.ExchangeActClickRet", 0)			--兑换活动点击请求应答

--分享游戏奖励
RegPBReq(24261, "ShareGameStatusReq", "dailyactivity.ShareGameStatusReq", 0)				--分享游戏是否领取过奖励状态请求
RegPBRet(24262, "ShareGameStatusRet", "dailyactivity.ShareGameStatusRet", 0)				--分享游戏是否领取过奖励状态应答
RegPBReq(24263, "ShareGameSuccessReq", "dailyactivity.ShareGameSuccessReq", 0)				--分享游戏成功请求
RegPBReq(24264, "ShareGameRewardReq", "dailyactivity.ShareGameRewardReq", 0)					--分享游戏奖励领取请求

--功能预告
RegPBReq(24266, "WillOpenInfoReq", "willopen.WillOpenInfoReq", 0)							--功能预告信息请求
RegPBRet(24267, "WillOpenInfoRet", "willopen.WillOpenInfoRet", 0)							--功能预告信息应答
RegPBReq(24268, "WillOpenRewardReq", "willopen.WillOpenRewardReq", 0)						--功能预告奖励领取

--每日礼包
RegPBReq(24271, "EverydayGiftInfoReq", "everydaygift.EverydayGiftInfoReq", 0)				--每日礼包信息请求
RegPBRet(24272, "EverydayGiftStatusRet", "everydaygift.EverydayGiftStatusRet", 0)			--每日礼包信息应答
RegPBReq(24273, "EverydayGiftGetReq", "everydaygift.EverydayGiftGetReq", 0)					--每日礼包奖励领取
RegPBReq(24274, "EverydayGiftSeleReq", "everydaygift.EverydayGiftSeleReq", 0)				--每日礼包奖励选择
RegPBRet(24275, "EverydayGiftSelectRet", "everydaygift.EverydayGiftSelectRet", 0)			--每日礼包奖励选择结果

--挂机追加协议
RegPBRet(24280, "GuaJiGuanQiaRet", "guaji.GuaJiGuanQiaRet", 0)								--挂机关卡信息
RegPBRet(24281, "RewardInfoRet", "guaji.RewardInfoRet", 0)									--挂机收益信息
RegPBRet(24282, "BossRewardInfoRet", "guaji.BossRewardInfoRet", 0)							--挂机boss战奖励展示
RegPBReq(24283, "StartNoticReq", "guaji.StartNoticReq", 0)									--开启巡逻通知请求
--指引任务
RegPBReq(24291, "GuideTaskInfoReq", "guidetask.GuideTaskInfoReq", 0)						--指引任务信息请求
RegPBRet(24292, "GuideTaskInfoListRet", "guidetask.GuideTaskInfoListRet", 0)				--指引任务信息列表
RegPBRet(24293, "GuideTaskInfoRet", "guidetask.GuideTaskInfoRet", 0)						--指引任务单个任务信息
RegPBReq(24294, "GuideTaskRewardReq", "guidetask.GuideTaskRewardReq", 0)					--领取任务奖励请求
RegPBRet(24295, "GuideTaskRewardRet", "guidetask.GuideTaskRewardRet", 0)					--领取任务奖励结果

--黃成[25001-26000]
--成就
RegPBRet(25001, "AchieveListRet", "achieve.AchieveListRet", 0)					--成就信息下发
RegPBReq(25002, "OpeneAchieveReq", "achieve.OpeneAchieveReq", 0)					--打开成就详情界面
RegPBRet(25003, "OpenTypeAchieveRet", "achieve.OpenTypeAchieveRet", 0)			--成就详情信息
RegPBReq(25004, "GetAchieveRewardReq", "achieve.GetAchieveRewardReq", 0)		--领取成就奖励
RegPBRet(25005, "SendTypeAchieveRet", "achieve.SendTypeAchieveRet", 0)			--成就差异信息推送
RegPBReq(25006, "OpenAchieveMain", "achieve.OpenAchieveMain", 0)					--打开成就主界面
RegPBRet(25007, "GetAchieveRewardRet", "achieve.GetAchieveRewardRet", 0)			--领取奖励返回

--科举
RegPBReq(25020, "OpenKejuDataReq", "keju.OpenKejuDataReq", 0)						--打开科举界面
RegPBRet(25021, "OpenKejuDataRet", "keju.OpenKejuDataRet", 0)					--科举信息界面
RegPBReq(25022, "AnswerKejuQuestionReq", "keju.AnswerKejuQuestionReq", 0)		--科举答题
RegPBReq(25023, "CloseKejuQuestion", "keju.CloseKejuQuestion", 0)			    --关闭科举答题界面
RegPBReq(25024, "KejuAskHelpReq", "keju.KejuAskHelpReq", 0)		                --点击科举求助按钮
RegPBRet(25025, "KejuAskHelpRet", "keju.KejuAskHelpRet", 0)			            --科举求助返回信息刷新界面
RegPBReq(25026, "KejuAnswerHelpQuestionReq", "keju.KejuAnswerHelpQuestionReq", 0)	--回答科举求助
RegPBReq(25027, "KejuAskHelpDataReq", "keju.KejuAskHelpDataReq", 0)			    --求助者获取他人回答信息
RegPBRet(25028, "KejuHelpDataRet", "keju.KejuHelpDataRet", 0)			            --求助者获取他人回答信息返回
RegPBRet(25029, "KejuFindNpcRet", "keju.KejuFindNpcRet", 0)						--找殿试npc
RegPBReq(25030, "KejuHelpQuestionDataReq", "keju.KejuHelpQuestionDataReq", 0)		--求助题目信息请求
RegPBRet(25031, "KejuHelpQuestionDataRet", "keju.KejuHelpQuestionDataRet", 0)		--求助题目信息返回

--家园
RegPBReq(25040, "C2GSEnterHouseReq", "house.C2GSEnterHouseReq", 111)				--打开家园
RegPBRet(25041, "GS2CEnterHouseRet", "house.GS2CEnterHouseRet", 0)				--家园信息返回
RegPBReq(25042, "C2GSLeaveHouseReq", "house.C2GSLeaveHouseReq", 111)				--离开家园
RegPBReq(25043, "C2GSBuyHouseBoxReq", "house.C2GSBuyHouseBoxReq", 111)				--购买宝箱
RegPBRet(25044, "GS2CBuyHouseBoxRet", "house.GS2CBuyHouseBoxRet", 0)				--购买宝箱返回数目
RegPBReq(25045, "C2GSHouseVisiterReq", "house.C2GSHouseVisiterReq", 111)			--家园访问信息请求
RegPBRet(25046, "GS2CHouseVisiterRet", "house.GS2CHouseVisiterRet", 0)			--家园访问信息返回
RegPBReq(25047, "C2GSHouseGiftInfoReq", "house.C2GSHouseGiftInfoReq", 111)			--家园赠送信息请求
RegPBRet(25048, "GS2CHouseGiftInfoRet", "house.GS2CHouseGiftInfoRet", 0)			--家园赠送信息返回
RegPBReq(25049, "C2GSHouseGiveGiftReq", "house.C2GSHouseGiveGiftReq", 111)			--家园赠送礼物
RegPBRet(25050, "GS2CHouseGiveGiftRet", "house.GS2CHouseGiveGiftRet", 0)			--家园赠送礼物刷新
RegPBReq(25051, "C2GSHousePosFurnitureReq", "house.C2GSHousePosFurnitureReq", 111)	--家园对应部位家具信息请求
RegPBRet(25052, "GS2CHousePosFurnituerRet", "house.GS2CHousePosFurnituerRet", 0)	--家园对应部位家具信息返回
RegPBReq(25053, "C2GSHouseWieldFurnitureReq", "house.C2GSHouseWieldFurnitureReq", 111)--装备某个家具
RegPBRet(25054, "GS2CHouseWieldFurnitureRet", "house.GS2CHouseWieldFurnitureRet", 0)--装备家具信息返回，刷新
RegPBReq(25055, "C2GSHouseMessageReq", "house.C2GSHouseMessageReq", 111)			--家园留言信息请求
RegPBRet(25056, "GS2CHouseMessageRet", "house.GS2CHouseMessageRet", 0)			--家园留言信息返回
RegPBReq(25057, "C2GSHouseMakeMessageReq", "house.C2GSHouseMakeMessageReq", 111)	--家园留言
RegPBRet(25058, "C2GSHouseMessageRedPointRet", "house.C2GSHouseMessageRedPointRet", 0)--家园留言返回
RegPBReq(25059, "C2GSHouseDeleteMessageReq", "house.C2GSHouseDeleteMessageReq", 111)--删除家园留言信息
RegPBRet(25060, "GS2CHouseDeleteMessageRet", "house.GS2CHouseDeleteMessageRet", 0)--删除家园留言信息返回

RegPBReq(25061, "C2GSSetPhotoKeyReq", "house.C2GSSetPhotoKeyReq", 111)				--设置家园照片
RegPBReq(25062, "C2GSHouseWaterPlantReq", "house.C2GSHouseWaterPlantReq", 111)		--家园植物浇水
RegPBRet(25063, "GS2CHousePlantRet", "house.GS2CHousePlantRet", 0)				--家园植物信息刷新
RegPBReq(25064, "C2GSHousePlantGiftDataReq", "house.C2GSHousePlantGiftDataReq", 111)--家园植物送礼界面请求
RegPBRet(25065, "GS2CHousePlantGiftDataRet", "house.GS2CHousePlantGiftDataRet", 0)--家园植物送礼界面返回仙侣信息
RegPBReq(25066, "C2GSHousePlantChangePartner", "house.C2GSHousePlantChangePartner", 111)--家园植物送礼界面刷新仙侣
RegPBReq(25067, "C2GSHousePlantGiveGiftReq", "house.C2GSHousePlantGiveGiftReq", 111)--家园植物送礼
RegPBRet(25068, "GS2CHousePlantGiveGiftRet", "house.GS2CHousePlantGiveGiftRet", 0)--植物送礼界面刷新
RegPBReq(25069, "C2GSHousePlantReceiveReward", "house.C2GSHousePlantReceiveReward", 111)--领取家园植物奖励
RegPBReq(25070, "C2GSHouseDynamicDataReq", "house.C2GSHouseDynamicDataReq", 111)	--家园动态信息请求
RegPBRet(25071, "GS2CHouseDyanmicDataRet", "house.GS2CHouseDyanmicDataRet", 0)	--家园动态信息请求返回
RegPBReq(25072, "C2GSHouseDynamicPublicCommentReq", "house.C2GSHouseDynamicPublicCommentReq", 111)--动态信息发表评论
RegPBRet(25073, "GS2CHouseDynamicRefreshRet", "house.GS2CHouseDynamicRefreshRet", 0)--动态评论的刷新
RegPBReq(25074, "C2GSHouseDynamicDeleteCommentReq", "house.C2GSHouseDynamicDeleteCommentReq", 111)--动态评论删除
RegPBReq(25075, "C2GSHouseDynamicUpVoteReq", "house.C2GSHouseDynamicUpVoteReq", 111)--动态评论点赞
RegPBRet(25076, "GS2CHouseDynamicUpVoteRet", "house.GS2CHouseDynamicUpVoteRet", 0)--动态评论点赞返回
RegPBReq(25077, "C2GSHouseDeleteDynamicReq", "house.C2GSHouseDeleteDynamicReq", 111)--删除家园动态
RegPBRet(25078, "GS2CHouseDeleteDynamicRet", "house.GS2CHouseDeleteDynamicRet", 0)--删除家园动态返回
RegPBReq(25079, "C2GSHouseDynamicPublicReq", "house.C2GSHouseDynamicPublicReq", 111)--发表家园动态
RegPBRet(25080, "GS2CHouseDynamicDeleteCommentRet", "house.GS2CHouseDynamicDeleteCommentRet", 0)--动态评论信息删除返回

--运营活动
RegPBReq(25100, "ActYYStateReq", "actyy.ActYYStateReq", 20)								--运营活动请求活动状态
RegPBRet(25101, "ActYYStateRet", "actyy.ActYYStateRet", 0)									--活动状态信息返回
RegPBReq(25102, "ActYYInfoReq", "actyy.ActYYInfoReq", 20)									--运营活动信息请求
RegPBRet(25103, "ActSCInfoRet", "actyy.ActSCInfoRet", 0)									--返回活动信息:单笔充值
RegPBRet(25104, "ActYYInfoRet", "actyy.ActYYInfoRet", 0)									--返回活动信息:累天充值,累计消耗元宝使用
RegPBReq(25105, "ActYYAwardReq", "actyy.ActYYAwardReq", 20)								--领取运营活动奖励
RegPBRet(25106, "ActYYRewardRet", "actyy.ActYYRewardRet", 0)								--领取奖励返回，刷新单个奖励信息


--湛力健
--神魔志
RegPBReq(26001, "ShenMoZhiMatchTeamReq", "shenmozhi.ShenMoZhiMatchTeamReq", 0)			--神魔志创建队伍,便捷组队请求
RegPBRet(26002,	"OnlineShenMoZhiDataRet", "shenmozhi.OnlineShenMoZhiDataRet", 0)			--登录发送神魔志关卡信息
RegPBReq(26003, "ShenMoZhiFightReq", "shenmozhi.ShenMoZhiFightReq", 0)			        --神魔志战斗请求
RegPBRet(26004,	"ShenMoZhiFightRet", "shenmozhi.ShenMoZhiFightRet", 0)					--神魔志战斗返回
RegPBReq(26005, "ShenMoZhiStarRewardReq", "shenmozhi.ShenMoZhiStarRewardReq", 0)		--请求神魔志章节星级奖励
RegPBRet(26006, "ShenMoZhiStarRewardRet", "shenmozhi.ShenMoZhiStarRewardRet", 0)		--神魔志星级奖励返回
RegPBReq(26007, "OpenShenMoZhiReq", "shenmozhi.OpenShenMoZhiReq", 0)					--请求神魔志章节星级奖励
RegPBRet(26008, "OpenShenMoZhiRet", "shenmozhi.OpenShenMoZhiRet", 0)					--神魔志星级奖励返回
