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

--知己
RegPBRet(8090, "MCListRet", "mingchen.MCListRet", 0)					--知己列表返回
RegPBReq(8091, "MCUpgradeReq", "mingchen.MCUpgradeReq", 0)				--知己升级请求
RegPBReq(8092, "MCOneKeyUpgradeReq", "mingchen.MCOneKeyUpgradeReq", 0)  --知己一键升级
RegPBReq(8093, "SKUpgradeReq", "mingchen.SKUpgradeReq", 0)				--技能升级请求
RegPBReq(8094, "SKOneKeyUpgradeReq", "mingchen.SKOneKeyUpgradeReq", 0)	--技能1键请求
RegPBReq(8095, "SKAdvanceReq", "mingchen.SKAdvanceReq", 0)				--技能升阶请求
RegPBReq(8096, "GiveTreasureReq", "mingchen.GiveTreasureReq", 0)		--赏赐珍宝
RegPBReq(8097, "OneKeyGiveTreasureReq", "mingchen.OneKeyGiveTreasureReq", 0)--知己一键赏赐
RegPBReq(8098, "MCTrainReq", "mingchen.MCTrainReq", 0)					--知己培养
RegPBReq(8099, "QuaBreachReq", "mingchen.QuaBreachReq", 0)				--资质突破
RegPBReq(8100, "GLRankingReq", "mingchen.GLRankingReq", 0)   			--国力排行榜请求
RegPBRet(8101, "GLRankingRet", "mingchen.GLRankingRet", 0)   			--国力排行榜返回
RegPBReq(8102, "MCRankingReq", "mingchen.MCRankingReq", 0)   			--知己属性排行请求
RegPBRet(8103, "MCRankingRet", "mingchen.MCRankingRet", 0)   			--知己属性排行返回
RegPBReq(8104, "MCModNameReq", "mingchen.MCModNameReq", 0)				--知己封号
RegPBReq(8105, "MCAttrDetailReq", "mingchen.MCAttrDetailReq", 0)		--知己详细属性请求
RegPBRet(8106, "MCAttrDetailRet", "mingchen.MCAttrDetailRet", 0)		--知己详细属性返回
RegPBReq(8107, "MCFengJueReq", "mingchen.MCFengJueReq", 0)				--知己封爵请求
RegPBReq(8108, "MCUpgradeTalentReq", "mingchen.MCUpgradeTalentReq", 0)	--知己晋升请求
RegPBReq(8109, "MCSendGiftReq", "mingchen.MCSendGiftReq", 0)			--送礼请求
RegPBReq(8110, "MCOneKeySendGiftReq", "mingchen.MCOneKeySendGiftReq", 0)--一键送礼请求
RegPBRet(8111, "MCBornChildRet", "mingchen.MCBornChildRet", 0)			--知己邀约获得宠物返回
RegPBReq(8112, "MCYaoYueReq", "mingchen.MCYaoYueReq", 0)				--知己邀约请求
RegPBReq(8113, "MCRecruitReq", "mingchen.MCRecruitReq", 0)				--知己入宫请求
RegPBReq(8114, "MCFengGuanReq", "mingchen.MCFengGuanReq", 0)			--知己封官请求
RegPBRet(8115, "MCFengGuanRet", "mingchen.MCFengGuanRet", 0)			--知己封官返回

--妃子	
RegPBRet(8117, "FZNaShaRet", "feizi.FZNaShaRet", 0)			--妃子那啥返回
RegPBRet(8118, "FZBornChildRet", "feizi.FZBornChildRet", 0)	--妃子生孩子返回
RegPBReq(8119, "FZRuGongReq", "feizi.FZRuGongReq", 0)		--妃子入宫请求
RegPBRet(8120, "FZListRet", "feizi.FZListRet", 0)			--妃子列表返回
RegPBReq(8121, "FZModNameReq", "feizi.FZModNameReq", 0)		--妃子改名请求
RegPBReq(8122, "FZModDescReq", "feizi.FZModDescReq", 0)		--妃子改描述请求
RegPBReq(8123, "FZUpgradeStarReq", "feizi.FZUpgradeStarReq", 0)	--妃子升级星级
RegPBReq(8124, "FZLearnReq", "feizi.FZLearnReq", 0)			--妃子修集
RegPBReq(8125, "FZUpFeiWeiReq", "feizi.FZUpFeiWeiReq", 0)	--妃子进封
RegPBReq(8126, "FZNaShaReq", "feizi.FZNaShaReq", 0)			--妃子那啥
RegPBReq(8127, "FZGiveTreasureReq", "feizi.FZGiveTreasureReq", 0)--妃子赏赐珍宝

RegPBReq(8128, "JZListReq", "feizi.JZListReq", 0) 			--建筑列表请求
RegPBRet(8129, "JZListRet", "feizi.JZListRet", 0) 			--建筑列表返回
RegPBReq(8130, "JZUpgradeReq", "feizi.JZUpgradeReq", 0) 	--建筑升级请求
RegPBRet(8131, "JZUpgradeRet", "feizi.JZUpgradeRet", 0) 	--建筑升级成功返回
RegPBReq(8131, "JZRankingReq", "feizi.JZRankingReq", 0) 	--建筑加成排行榜请求
RegPBRet(8132, "JZRankingRet", "feizi.JZRankingRet", 0) 	--建筑加成排行榜返回

RegPBReq(8133, "FZQingAnReq", "feizi.FZQingAnReq", 0) 		--妃子请安请求
RegPBRet(8134, "FZQingAnRet", "feizi.FZQingAnRet", 0) 		--妃子请安成功返回

RegPBReq(8140, "LGInfoReq", "feizi.LGInfoReq", 0) 			--冷宫信息请求
RegPBRet(8141, "LGInfoRet", "feizi.LGInfoRet", 0) 			--冷宫信息返回
RegPBReq(8142, "LGOpenGridReq", "feizi.LGOpenGridReq", 0) 	--冷宫扩建请求
RegPBReq(8143, "LGPutFZReq", "feizi.LGPutFZReq", 0) 		--冷宫翻牌请求
RegPBReq(8144, "LGCallFZReq", "feizi.LGCallFZReq", 0) 		--冷宫完成请求

RegPBReq(8145, "CXGInfoReq", "chuxiugong.CXGInfoReq", 0) 		--储秀宫信息请求
RegPBRet(8146, "CXGInfoRet", "chuxiugong.CXGInfoRet", 0) 		--储秀宫信息返回
RegPBReq(8147, "CXGDrawReq", "chuxiugong.CXGDrawReq", 0) 		--储秀宫选秀请求
RegPBRet(8148, "CXGDrawRet", "chuxiugong.CXGDrawRet", 0) 		--储秀宫选秀返回


--国库
RegPBRet(8150, "GuoKuItemListRet", "guoku.GuoKuItemListRet", 0)					--道具列表返回
RegPBRet(8151, "GuoKuItemAddRet", "guoku.GuoKuItemAddRet", 0)					--道具增加通知
RegPBRet(8152, "GuoKuItemRemoveRet", "guoku.GuoKuItemRemoveRet", 0)				--道具删除通知
RegPBRet(8153, "GuoKuItemModRet", "guoku.GuoKuItemModRet", 0)					--道具数量变更通知
RegPBReq(8154, "GuoKuSellItemReq", "guoku.GuoKuSellItemReq", 0)					--出售道具请求
RegPBReq(8155, "GuoKuUseItemReq", "guoku.GuoKuUseItemReq", 0)					--使用道具请求
RegPBRet(8156, "GuoKuUseItemRet", "guoku.GuoKuUseItemRet", 0)					--使用道具成功返回
RegPBReq(8157, "GuoKuComposeReq", "guoku.GuoKuComposeReq", 0)					--道具合成请求
RegPBRet(8158, "GuoKuComposeRet", "guoku.GuoKuComposeRet", 0)					--道具合成成功返回
RegPBRet(8159, "GuoKuUseAttrBoxRet", "guoku.GuoKuUseAttrBoxRet", 0)				--使用随机属性宝箱返回

--征服世界
RegPBReq(8180, "ChapterInfoReq", "battle.ChapterInfoReq", 0)				--请求章节信息
RegPBRet(8181, "ChapterInfoRet", "battle.ChapterInfoRet", 0)				--章节信息返回
RegPBReq(8182, "DupInfoReq", "battle.DupInfoReq", 0)						--请求关卡信息
RegPBRet(8183, "DupInfoRet", "battle.DupInfoRet", 0)						--关卡信息返回
RegPBReq(8184, "BattleReq", "battle.BattleReq", 0)						--战斗请求
RegPBRet(8185, "BattleRet", "battle.BattleRet", 0)						--战斗结果返回
RegPBReq(8186, "DupRankingReq", "battle.DupRankingReq", 0)				--副本排行榜请求
RegPBRet(8187, "DupRankingRet", "battle.DupRankingRet", 0)				--副本排行榜返回

RegPBReq(8188, "DupMCListReq", "battle.DupMCListReq", 0)				--名臣列表请求
RegPBRet(8189, "DupMCListRet", "battle.DupMCListRet", 0)				--名臣列表返回
RegPBReq(8190, "DupMCCZReq", "battle.DupMCCZReq", 0)					--名臣出战请求
RegPBReq(8191, "DupMCRecReq", "battle.DupMCRecReq", 0)					--名臣恢复出战请求

RegPBReq(8192, "RecFashionReq", "battle.RecFashionReq", 0)				--查看时装推荐请求
RegPBRet(8193, "RecFashionRet", "battle.RecFashionRet", 0)				--查看时装推荐返回

--内阁
RegPBReq(8200, "NeiGeInfoReq", "neige.NeiGeInfoReq", 0)						--界面信息请求
RegPBRet(8201, "NeiGeInfoRet", "neige.NeiGeInfoRet", 0)						--界面信息返回
RegPBReq(8203, "NeiGeCollectReq", "neige.NeiGeCollectReq", 0)				--征收请求
RegPBReq(8204, "NeiGeOneKeyCollectReq", "neige.NeiGeOneKeyCollectReq", 0)	--1键征收请求
RegPBReq(8205, "NeiGeCancelCDReq", "neige.NeiGeCancelCDReq", 0)				--加速请求
RegPBReq(8207, "NeiGeRecoverReq", "neige.NeiGeRecoverReq", 0)				--内阁恢复次数
RegPBReq(8208, "NeiGeOneKeyRecoverReq", "neige.NeiGeOneKeyRecoverReq", 0)	--内阁一键恢复次数

--皇子
RegPBReq(8270, "HZListReq", "huangzi.HZListReq", 0)				--皇子列表请求
RegPBRet(8271, "HZListRet", "huangzi.HZListRet", 0)				--皇子列表返回
RegPBRet(8272, "HZSyncInfo", "huangzi.HZSyncInfo", 0)			--同步单个皇子信息
RegPBReq(8273, "HZModNameReq", "huangzi.HZModNameReq", 0)			--皇子改名请求
RegPBReq(8274, "HZSpeedGrowUpReq", "huangzi.HZSpeedGrowUpReq", 0)	--皇子加速成长请求
RegPBReq(8275, "HZUpLearnEffReq", "huangzi.HZUpLearnEffReq", 0)		--皇子提升学习效率请求
RegPBReq(8276, "HZLearnReq", "huangzi.HZLearnReq", 0)				--皇子学习请求
RegPBReq(8277, "HZFengJueReq", "huangzi.HZFengJueReq", 0)			--皇子封爵请求

RegPBReq(8278, "HZUnmarriedListReq", "huangzi.HZUnmarriedListReq", 0)	--未婚皇子列表请求
RegPBRet(8279, "HZUnmarriedListRet", "huangzi.HZUnmarriedListRet", 0)	--未婚皇子列表返回
RegPBReq(8280, "HZMarriedListReq", "huangzi.HZMarriedListReq", 0)		--已婚皇子列表请求
RegPBRet(8281, "HZMarriedListRet", "huangzi.HZMarriedListRet", 0)		--已婚皇子列表返回

RegPBReq(8282, "LYListReq", "huangzi.LYListReq", 0)					--联姻列表请求
RegPBRet(8283, "LYListRet", "huangzi.LYListRet", 0)					--联姻列表返回
RegPBReq(8284, "LYPlayerSendReq", "huangzi.LYPlayerSendReq", 0)		--指定玩家发送联姻请求
RegPBReq(8285, "LYServerSendReq", "huangzi.LYServerSendReq", 0)		--全服玩家联姻请求
RegPBReq(8286, "LYCancelReq", "huangzi.LYCancelReq", 0)				--取消联姻请求
RegPBReq(8287, "LYRejectReq", "huangzi.LYRejectReq", 0)				--拒绝联姻请求
RegPBReq(8288, "LYAgreeReq", "huangzi.LYAgreeReq", 0)				--同意联姻请求
RegPBReq(8289, "LYHZMatchListReq", "huangzi.LYHZMatchListReq", 0)	--取符合条件的皇子列表
RegPBRet(8290, "LYHZMatchListRet", "huangzi.LYHZMatchListRet", 0)	--符合条件的皇子列表返回
RegPBRet(8291, "LYSuccessRet", "huangzi.LYSuccessRet", 0)			--联姻成功返回

RegPBReq(8292, "HZRankingReq", "huangzi.HZRankingReq", 0)		--皇子排行榜请求
RegPBRet(8293, "HZRankingRet", "huangzi.HZRankingRet", 0)		--皇子排行榜返回
RegPBReq(8294, "HZOpenGridReq", "huangzi.HZOpenGridReq", 0)		--扩建宗人府请求
RegPBRet(8295, "HZOpenGridRet", "huangzi.HZOpenGridRet", 0)		--扩建宗人府返回
RegPBReq(8296, "OneKeyLearnReq", "huangzi.OneKeyLearnReq", 0)		--一键学习(突飞猛进)请求
RegPBReq(8297, "OneKeyRecoverReq", "huangzi.OneKeyRecoverReq", 0)	--一键恢复(突飞猛进)请求
RegPBReq(8298, "HZCaiLiInfoReq", "huangzi.HZCaiLiInfoReq", 0)		--联姻彩礼信息请求
RegPBRet(8299, "HZCaiLiInfoRet", "huangzi.HZCaiLiInfoRet", 0)		--联姻彩礼信息返回
RegPBReq(8210, "HZSetCaiLiReq", "huangzi.HZSetCaiLiReq", 0)			--设置彩礼请求
RegPBReq(8211, "ZRFGridInfoReq", "huangzi.ZRFGridInfoReq", 0) 		--宗人府席位信息请求
RegPBRet(8212, "ZRFGridInfoRet", "huangzi.ZRFGridInfoRet", 0) 		--宗人府席位信息返回

--奏章
RegPBReq(8330, "ZZZouZhangReq", "zouzhang.ZZZouZhangReq", 0)		--奏章数请求
RegPBRet(8331, "ZZZouZhangRet", "zouzhang.ZZZouZhangRet", 0)		--奏章数返回
RegPBReq(8332, "ZZInfoReq", "zouzhang.ZZInfoReq", 0)	        	--信息请求
RegPBRet(8333, "ZZInfoRet", "zouzhang.ZZInfoRet", 0)	        	--信息返回
RegPBReq(8334, "ZZAwardReq", "zouzhang.ZZAwardReq", 0)	        	--盖章请求
RegPBRet(8335, "ZZAwardRet", "zouzhang.ZZAwardRet", 0)	        	--盖章返回
RegPBReq(8336, "ZZAddZouZhangTimesReq", "zouzhang.ZZAddZouZhangTimesReq", 0)	--增加奏章数

--邮件
RegPBReq(8360, "MailListReq", "mail.MailListReq", 0)	--取邮件列表
RegPBRet(8361, "MailListRet", "mail.MailListRet", 0)	--邮件列表返回
RegPBReq(8362, "MailBodyReq", "mail.MailBodyReq", 0)	--邮件体请求
RegPBRet(8363, "MailBodyRet", "mail.MailBodyRet", 0)	--邮件体返回
RegPBReq(8364, "DelMailReq", "mail.DelMailReq", 0)	    --删除邮件(删除前如果有物品需要确认提示)
RegPBReq(8365, "MailItemsReq", "mail.MailItemsReq", 0)	--提取物品(需要判断背包是否有空闲位置)
RegPBRet(8366, "MailItemsRet", "mail.MailItemsRet", 0)	--提取物品成功返回

--聊天
RegPBReq(8390, "TalkReq", "talk.TalkReq", 0)	--聊天请求
RegPBRet(8391, "TalkRet", "talk.TalkRet", 0)	--聊天返回
RegPBRet(8392, "TalkHistoryRet", "talk.TalkHistoryRet", 0)	--聊天记录返回


--势力排行榜
RegPBReq(8420, "SLRankingReq", "feizi.SLRankingReq", 0)	--势力排行榜请求
RegPBRet(8421, "SLRankingRet", "feizi.SLRankingRet", 0)	--势力排行榜返回
RegPBReq(8422, "QMRankingReq", "feizi.QMRankingReq", 0)	--亲密排行榜请求
RegPBRet(8423, "QMRankingRet", "feizi.QMRankingRet", 0)	--亲密排行榜返回
RegPBReq(8424, "NLRankingReq", "feizi.NLRankingReq", 0)	--能力排行榜请求
RegPBRet(8425, "NLRankingRet", "feizi.NLRankingRet", 0)	--能力排行榜返回
RegPBReq(8426, "CDRankingReq", "feizi.CDRankingReq", 0)	--才德排行榜请求
RegPBRet(8427, "CDRankingRet", "feizi.CDRankingRet", 0)	--才德排行榜返回

--请安折
RegPBReq(8550, "QingAnZheReq", "qinganzhe.QingAnZheReq", 0)      --请安折数请求
RegPBRet(8551, "QingAnZheRet", "qinganzhe.QingAnZheRet", 0)      --请安折数返回
RegPBReq(8552, "QAZInfoReq", "qinganzhe.QAZInfoReq", 0)          --请安请求
RegPBRet(8553, "QAZInfoRet", "qinganzhe.QAZInfoRet", 0)          --请安返回

--微服私访
RegPBReq(8650, "WFSFInfoReq", "weifusifang.WFSFInfoReq", 0)           --微服私访请求
RegPBRet(8651, "WFSFInfoRet", "weifusifang.WFSFInfoRet", 0)           --微服私访返回
RegPBReq(8652, "XXunFangReq", "weifusifang.XXunFangReq", 0)           --寻访请求
RegPBRet(8653, "XXunFangRet", "weifusifang.XXunFangRet", 0)           --寻访返回
RegPBReq(8654, "XFBuildEventAwardReq", "weifusifang.XFBuildEventAwardReq", 0) --建筑物奖励请求
RegPBRet(8655, "XFBuildEventAwardRet", "weifusifang.XFBuildEventAwardRet", 0) --建筑物奖励返回   
RegPBReq(8656, "XXunBaoReq", "weifusifang.XXunBaoReq", 0)             --寻宝请求
RegPBRet(8657, "XXunBaoRet", "weifusifang.XXunBaoRet", 0)             --寻宝返回
RegPBReq(8658, "XFBlankEventAwardReq", "weifusifang.XFBlankEventAwardReq", 0)   --空格奖励请求
RegPBRet(8659, "XFBlankEventAwardRet", "weifusifang.XFBlankEventAwardRet", 0)   --空格奖励返回

RegPBReq(8660, "XFSpecifyBuildInfoReq", "weifusifang.XFSpecifyBuildInfoReq", 0)   --指定寻访建筑信息请求
RegPBRet(8661, "XFSpecifyBuildInfoRet", "weifusifang.XFSpecifyBuildInfoRet", 0)   --指定寻访建筑信息返回
RegPBReq(8662, "XFSpecifyXunFangReq", "weifusifang.XFSpecifyXunFangReq", 0)   	--指定寻访请求(扣钱后走普通寻访流程)


--任务
RegPBReq(8680, "MainTaskListReq", "task.MainTaskListReq", 0)    	--主线请求
RegPBRet(8681, "MainTaskListRet", "task.MainTaskListRet", 0)    	--主线返回
RegPBReq(8682, "DailyTaskListReq", "task.DailyTaskListReq", 0)  	--每日任务请求
RegPBRet(8683, "DailyTaskListRet", "task.DailyTaskListRet", 0)  	--每日任务返回
RegPBReq(8684, "MainTaskAwardReq", "task.MainTaskAwardReq", 0)    	--主线任务领奖请求
RegPBReq(8685, "DailyTaskAwardReq", "task.DailyTaskAwardReq", 0)    --每日任务领奖请求
RegPBRet(8686, "TaskAwardRet", "task.TaskAwardRet", 0)     			--任务奖励领取成功返回
RegPBReq(8687, "CompleteTaskReq", "task.CompleteTaskReq", 0)     	--客户端请求完成任务(特定任务)

--联盟
RegPBRet(8720, "UnionInfoRet", "union.UnionInfoRet", 0)		--联盟基本信息返回
RegPBReq(8721, "UnionDetailReq", "union.UnionDetailReq", 0)	--联盟详细信息请求
RegPBRet(8722, "UnionDetailRet", "union.UnionDetailRet", 0)	--联盟详细信息返回
RegPBReq(8723, "UnionListReq", "union.UnionListReq", 0)		--联盟列表请求
RegPBRet(8724, "UnionListRet", "union.UnionListRet", 0)		--联盟列表返回
RegPBReq(8725, "ApplyUnionReq", "union.ApplyUnionReq", 0)	--申请加入联盟请求
RegPBReq(8726, "CreateUnionReq", "union.CreateUnionReq", 0)	--创建联盟请求
RegPBReq(8727, "ExitUnionReq", "union.ExitUnionReq", 0)		--退出联盟请求
RegPBRet(8728, "ExitUnionRet", "union.ExitUnionRet", 0)		--退出联盟通知
RegPBRet(8729, "ApplyUnionRet", "union.ApplyUnionRet", 0)	--申请加入联盟成功返回

RegPBReq(8744, "SetAutoJoinReq", "union.SetAutoJoinReq", 0)		--设置自动进入请求
RegPBReq(8747, "SetUnionDeclReq", "union.SetUnionDeclReq", 0)	--设置联盟宣言请求

RegPBReq(8760, "ApplyListReq", "union.ApplyListReq", 0)			--申请列表请求
RegPBRet(8761, "ApplyListRet", "union.ApplyListRet", 0)			--申请列表返回
RegPBReq(8762, "AcceptApplyReq", "union.AcceptApplyReq", 0)		--接受申请请求
RegPBReq(8763, "RefuseApplyReq", "union.RefuseApplyReq", 0)		--拒绝申请请求
RegPBReq(8764, "MemberListReq", "union.MemberListReq", 0)		--队员列表请求
RegPBRet(8765, "MemberListRet", "union.MemberListRet", 0)		--队员列表返回
RegPBReq(8766, "KickUnionMemberReq", "union.KickUnionMemberReq", 0)	--移除队员请求

RegPBReq(8800, "AppointReq", "union.AppointReq", 0)				--任命职位请求
RegPBRet(8801, "PosChangeRet", "union.PosChangeRet", 0) 		--职位变更返回

RegPBReq(8802, "UnionUpgradeReq", "union.UnionUpgradeReq", 0)	--联盟升级请求
RegPBReq(8803, "MemberDetailReq", "union.MemberDetailReq", 0) 	--成员信息请求
RegPBRet(8804, "MemberDetailRet", "union.MemberDetailRet", 0) 	--成员信息返回
RegPBReq(8805, "JoinRandUnionReq", "union.JoinRandUnionReq", 0) --随机加入联盟

RegPBReq(8806, "UnionBuildInfoReq", "union.UnionBuildInfoReq", 0)		--联盟建设情况请求
RegPBRet(8807, "UnionBuildInfoRet", "union.UnionBuildInfoRet", 0) 		--联盟建设情况返回
RegPBReq(8808, "UnionBuildReq", "union.UnionBuildReq", 0) 				--联盟建设请求
RegPBReq(8809, "UnionExchangeListReq", "union.UnionExchangeListReq", 0) --联盟兑换列表请求
RegPBRet(8810, "UnionExchangeListRet", "union.UnionExchangeListRet", 0) --联盟兑换列表返回
RegPBReq(8811, "UnionExchangeReq", "union.UnionExchangeReq", 0) 		--联盟兑换请求
RegPBRet(8812, "UnionExchangeSuccRet", "union.UnionExchangeSuccRet", 0) --联盟兑换成功返回

RegPBReq(8813, "UnionPartyListReq", "union.UnionPartyListReq", 0)		--宴会列表请求
RegPBRet(8814, "UnionPartyListRet", "union.UnionPartyListRet", 0) 		--宴会列表返回
RegPBReq(8815, "UnionPartyRankingReq", "union.UnionPartyRankingReq", 0) --宴会伤害排行榜请求
RegPBRet(8816, "UnionPartyRankingRet", "union.UnionPartyRankingRet", 0) --宴会伤害排行榜返回
RegPBReq(8817, "UnionPartyOpenReq", "union.UnionPartyOpenReq", 0) 		--举办宴会请求
RegPBReq(8818, "UnionPartyMCListReq", "union.UnionPartyMCListReq", 0) 	--出战知己列表请求
RegPBRet(8819, "UnionPartyMCListRet", "union.UnionPartyMCListRet", 0) 	--出战知己列表返回
RegPBReq(8820, "UnionPartyAddMCReq", "union.UnionPartyAddMCReq", 0) 	--出战知己请求
RegPBReq(8821, "UnionPartyRemoveMCReq", "union.UnionPartyRemoveMCReq", 0) 		--撤下知己请求
RegPBReq(8822, "UnionPartyStartBattleReq", "union.UnionPartyStartBattleReq", 0) --开始战斗请求
RegPBRet(8823, "UnionPartyBattleRet", "union.UnionPartyBattleRet", 0) 			--战斗结果返回
RegPBReq(8832, "UnionPartyRecoverMCReq", "union.UnionPartyRecoverMCReq", 0) 	--恢复知己出战请求
RegPBReq(8833, "UnionPartyBossReq", "union.UnionPartyBossReq", 0) 		--BOSS界面信息请求
RegPBRet(8834, "UnionPartyBossRet", "union.UnionPartyBossRet", 0) 		--BOSS界面信息返回

RegPBReq(8824, "UnionMiracleListReq", "union.UnionMiracleListReq", 0)		--奇迹列表请求
RegPBRet(8825, "UnionMiracleListRet", "union.UnionMiracleListRet", 0) 		--奇迹列表返回
RegPBReq(8826, "UnionMiracleDonateReq", "union.UnionMiracleDonateReq", 0) 	--奇迹捐献请求
RegPBRet(8827, "UnionMiracleUpgradeRet", "union.UnionMiracleUpgradeRet", 0) --奇迹升级返回
RegPBReq(8828, "UnionDonateDetailReq", "union.UnionDonateDetailReq", 0) 	--奇迹捐献详细请求
RegPBRet(8829, "UnionDonateDetailRet", "union.UnionDonateDetailRet", 0) 	--奇迹捐献详细返回

RegPBReq(8830, "UGLRankingReq", "union.UGLRankingReq", 0) 	--联盟国力排行榜请求
RegPBRet(8831, "UGLRankingRet", "union.UGLRankingRet", 0) 	--联盟国力排行榜返回

--军机处
RegPBReq(8900, "JJCInfoReq", "junjichu.JJCInfoReq", 0)							--军机处信息请求
RegPBRet(8901, "JJCInfoRet", "junjichu.JJCInfoRet", 0)							--军机处信息返回
RegPBReq(8902, "JJCAddMCReq", "junjichu.JJCAddMCReq", 0)						--任命大臣请求
RegPBReq(8903, "JJCRemoveMCReq", "junjichu.JJCRemoveMCReq", 0)					--罢免大臣请求
RegPBReq(8904, "JJCSendReq", "junjichu.JJCSendReq", 0)							--出使大臣请求
RegPBRet(8905, "JJCBattleProcedureRet", "junjichu.JJCBattleProcedureRet", 0)	--战斗过程返回
RegPBReq(8906, "JJCExtraRobReq", "junjichu.JJCExtraRobReq", 0)					--是否乘胜追击请求
RegPBRet(8907, "JJCBattleResultRet", "junjichu.JJCBattleResultRet", 0)			--军机处战斗结束返回
RegPBReq(8908, "JJCZhaoJianListReq", "junjichu.JJCZhaoJianListReq", 0)			--召见列表请求
RegPBRet(8909, "JJCZhaoJianListRet", "junjichu.JJCZhaoJianListRet", 0)			--召见列表返回
RegPBReq(8910, "JJCChouHenListReq", "junjichu.JJCChouHenListReq", 0)			--仇恨列表请求
RegPBRet(8911, "JJCChouHenListRet", "junjichu.JJCChouHenListRet", 0)			--仇恨列表返回
RegPBReq(8912, "JJCAttackReq", "junjichu.JJCAttackReq", 0)						--攻击请求
RegPBReq(8913, "JJCTongJiListReq", "junjichu.JJCTongJiListReq", 0)				--通缉列表请求
RegPBRet(8914, "JJCTongJiListRet", "junjichu.JJCTongJiListRet", 0)				--通缉列表返回
RegPBReq(8915, "JJCRankTongJiListReq", "junjichu.JJCRankTongJiListReq", 0)		--排名通缉榜请求
RegPBRet(8916, "JJCRankTongJiListRet", "junjichu.JJCRankTongJiListRet", 0)		--排名通缉榜返回
RegPBReq(8917, "JJCPlayerTongJiReq", "junjichu.JJCPlayerTongJiReq", 0)			--发布通缉令请求
RegPBReq(8918, "WWRankingReq", "junjichu.WWRankingReq", 0)						--威望排行榜请求
RegPBRet(8919, "WWRankingRet", "junjichu.WWRankingRet", 0)						--威望排行榜返回
RegPBReq(8920, "ZJRankingReq", "junjichu.ZJRankingReq", 0)						--战绩排行榜请求
RegPBRet(8921, "ZJRankingRet", "junjichu.ZJRankingRet", 0)						--战绩排行榜返回
RegPBReq(8922, "JJCNoticeListReq", "junjichu.JJCNoticeListReq", 0)				--公告列表
RegPBRet(8923, "JJCNoticeListRet", "junjichu.JJCNoticeListRet", 0)				--公告列表返回
RegPBReq(8924, "JJCOneKeyAddMCReq", "junjichu.JJCOneKeyAddMCReq", 0)			--一键任免

RegPBReq(8925, "JJCJFCTReq", "junjichu.JJCJFCTReq", 0)			--积分刺探请求
RegPBReq(8926, "JJCGuWuReq", "junjichu.JJCGuWuReq", 0)			--鼓舞请求
RegPBReq(8927, "JJCExchangePosReq", "junjichu.JJCExchangePosReq", 0)	--交换大臣位置
RegPBReq(8928, "JJCStartBattleReq", "junjichu.JJCStartBattleReq", 0)	--开始战斗请求
RegPBRet(8929, "JJCPrepareRet", "junjichu.JJCPrepareRet", 0)	--对战准备信息返回



--签到
RegPBReq(8930, "QDInfoReq", "qiandao.QDInfoReq", 0)						--签到请求
RegPBRet(8931, "QDInfoRet", "qiandao.QDInfoRet", 0)						--签到返回
RegPBReq(8932, "QDAwardReq", "qiandao.QDAwardReq", 0)				    --签到奖励请求
RegPBRet(8933, "QDAwardRet", "qiandao.QDAwardRet", 0)					--签到奖励返回

--惩治敌酋
RegPBReq(8940, "CZDQInfoReq", "chengzhidiqiu.CZDQInfoReq", 0)           --惩治请求
RegPBRet(8941, "CZDQInfoRet", "chengzhidiqiu.CZDQInfoRet", 0)           --惩治返回
RegPBReq(8942, "CZDQUseXFReq", "chengzhidiqiu.CZDQUseXFReq", 0)         --使用刑罚请求
RegPBReq(8943, "CZDQReportYinLiangReq", "chengzhidiqiu.CZDQReportYinLiangReq", 0)   --赔款请求
RegPBReq(8944, "CZDQRankingReq", "chengzhidiqiu.CZDQRankingReq", 0)     			--追讨赔款排行榜请求
RegPBRet(8945, "CZDQRankingRet", "chengzhidiqiu.CZDQRankingRet", 0)     			--追讨赔款排行榜返回
RegPBReq(8946, "CZDQOffInterfaceReq", "chengzhidiqiu.CZDQOffInterfaceReq", 0)     	--关闭界面请求

--VIP
RegPBReq(8990, "VIPAwardListReq", "vip.VIPAwardListReq", 0)     	--VIP特权列表请求
RegPBRet(8991, "VIPAwardListRet", "vip.VIPAwardListRet", 0) 		--VIP特权列表返回
RegPBReq(8992, "VIPAwardReq", "vip.VIPAwardReq", 0)     			--VIP特权领取请求
RegPBRet(8993, "VIPAwardRet", "vip.VIPAwardRet", 0) 				--VIP特权领取返回
RegPBReq(8994, "RechargeListReq", "vip.RechargeListReq", 0)     	--充值列表请求
RegPBRet(8995, "RechargeListRet", "vip.RechargeListRet", 0) 		--充值列表返回
RegPBRet(8996, "RechargeSuccessRet", "vip.RechargeSuccessRet", 0) 	--充值成功返回
RegPBRet(8997, "FirstRechargeStateRet", "vip.FirstRechargeStateRet", 0) 	--首充状态同步
RegPBReq(8998, "FirstRechargeAwardReq", "vip.FirstRechargeAwardReq", 0) 	--领取首充奖励
RegPBRet(8999, "FirstRechargeAwardRet", "vip.FirstRechargeAwardRet", 0) 	--领取首充奖励成功返回

--大清皇榜
RegPBReq(9000, "HBInfoReq", "daqinghuangbang.HBInfoReq", 0)              --大清皇榜请求
RegPBRet(9001, "HBInfoRet", "daqinghuangbang.HBInfoRet", 0)				 --大清皇榜返回
RegPBReq(9002, "HBInActivityReq", "daqinghuangbang.HBInActivityReq", 0)  --活动进入请求
RegPBRet(9003, "HBInActivityRet", "daqinghuangbang.HBInActivityRet", 0)	 --活动进入返回
RegPBReq(9004, "HBRankingReq", "daqinghuangbang.HBRankingReq", 0)		 --冲榜榜单请求
RegPBRet(9005, "HBRankingRet", "daqinghuangbang.HBRankingRet", 0)		 --冲榜榜单返回
RegPBReq(9006, "HBGetAwardReq", "daqinghuangbang.HBGetAwardReq", 0)		 --奖励请求
RegPBRet(9007, "HBGetAwardRet", "daqinghuangbang.HBGetAwardRet", 0)		 --奖励返回

--日充值活动
RegPBReq(9050, "DayRechargeStateReq", "dayrecharge.DayRechargeStateReq", 0)		--活动状态信息请求
RegPBRet(9051, "DayRechargeStateRet", "dayrecharge.DayRechargeStateRet", 0)     --活动状态返回
RegPBReq(9052, "DayRechargeInfoReq", "dayrecharge.DayRechargeInfoReq", 0)		--活动信息请求
RegPBRet(9053, "DayRechargeInfoRet", "dayrecharge.DayRechargeInfoRet", 0)   	--活动信息返回
RegPBReq(9054, "DayRechargeAwardReq", "dayrecharge.DayRechargeAwardReq", 0)	 	--领取奖励请求
RegPBRet(9055, "DayRechargeAwardRet", "dayrecharge.DayRechargeAwardRet", 0)	 	--领取奖励成功返回

--周充值活动
RegPBReq(9070, "WeekRechargeInfoReq", "weekrecharge.WeekRechargeInfoReq", 0)		--活动信息请求
RegPBRet(9071, "WeekRechargeInfoRet", "weekrecharge.WeekRechargeInfoRet", 0)   		--活动信息返回
RegPBReq(9072, "WeekRechargeAwardReq", "weekrecharge.WeekRechargeAwardReq", 0)	 	--领取奖励请求
RegPBRet(9073, "WeekRechargeAwardRet", "weekrecharge.WeekRechargeAwardRet", 0)	 	--领取奖励成功返回

--限时特卖
RegPBReq(9090, "TimeMallInfoReq", "timemall.TimeMallInfoReq", 0)	--信息请求
RegPBRet(9091, "TimeMallInfoRet", "timemall.TimeMallInfoRet", 0)   	--信息返回
RegPBReq(9092, "TimeMallBuyReq", "timemall.TimeMallBuyReq", 0)	 	--领取奖励请求
RegPBRet(9093, "TimeMallBuyRet", "timemall.TimeMallBuyRet", 0)	 	--领取奖励返回

--活动礼包
RegPBReq(9110, "TimeGiftStateReq", "timegift.TimeGiftStateReq", 0)	--活动状态信息请求
RegPBRet(9111, "TimeGiftStateRet", "timegift.TimeGiftStateRet", 0)   --活动状态信息返回
RegPBReq(9112, "TimeGiftBuyReq", "timegift.TimeGiftBuyReq", 0)	 	--购买礼包请求
RegPBRet(9113, "TimeGiftBuyRet", "timegift.TimeGiftBuyRet", 0)	 	--购买礼包成功返回
RegPBReq(9114, "TimeGiftGetActItemReq", "timegift.TimeGiftGetActItemReq", 0)	--礼包奖励表请求
RegPBRet(9115, "TimeGiftGetActItemRet", "timegift.TimeGiftGetActItemRet", 0)	--礼包奖励表返回

--累登活动
RegPBReq(9130, "LeiDengStateReq", "leideng.LeiDengStateReq", 0)		--活动状态信息请求
RegPBRet(9131, "LeiDengStateRet", "leideng.LeiDengStateRet", 0)     --活动状态返回
RegPBReq(9132, "LeiDengInfoReq", "leideng.LeiDengInfoReq", 0)		--活动信息请求
RegPBRet(9133, "LeiDengInfoRet", "leideng.LeiDengInfoRet", 0)   	--活动信息返回
RegPBReq(9134, "LeiDengAwardReq", "leideng.LeiDengAwardReq", 0)	 	--领取奖励请求
RegPBRet(9135, "LeiDengAwardRet", "leideng.LeiDengAwardRet", 0)	 	--领取奖励成功返回

--限时奖励
RegPBReq(9150, "TimeAwardStateReq", "timeaward.TimeAwardStateReq", 0)			--限时活动状态请求
RegPBRet(9151, "TimeAwardStateRet", "timeaward.TimeAwardStateRet", 0)     		--限时活动状态返回
RegPBReq(9152, "TimeAwardProgressReq", "timeaward.TimeAwardProgressReq", 0)		--活动进度请求
RegPBRet(9153, "TimeAwardProgressRet", "timeaward.TimeAwardProgressRet", 0)   	--活动进度返回
RegPBReq(9154, "TimeAwardRankingReq", "timeaward.TimeAwardRankingReq", 0)	 	--活动排行榜请求
RegPBRet(9155, "TimeAwardRankingRet", "timeaward.TimeAwardRankingRet", 0)	 	--活动排行榜返回
RegPBReq(9156, "TimeAwardAwardReq", "timeaward.TimeAwardAwardReq", 0)	 		--领取奖励请求
RegPBRet(9157, "TimeAwardAwardRet", "timeaward.TimeAwardAwardRet", 0)	 		--领取奖励成功返回

--挖宝活动
RegPBReq(9200, "WaBaoStateReq", "wabao.WaBaoStateReq", 0)	--活动状态信息请求
RegPBRet(9201, "WaBaoStateRet", "wabao.WaBaoStateRet", 0)	--活动状态信息返回
RegPBReq(9202, "WaBaoPropListReq", "wabao.WaBaoPropListReq", 0)	--道具列表请求
RegPBRet(9203, "WaBaoPropListRet", "wabao.WaBaoPropListRet", 0)	--道具列表返回
RegPBReq(9204, "WaBaoBuyPropReq", "wabao.WaBaoBuyPropReq", 0)	--购买道具请求
RegPBRet(9205, "WaBaoBuyPropRet", "wabao.WaBaoBuyPropRet", 0)	--购买道具成功返回
RegPBReq(9206, "WaBaoUsePropReq", "wabao.WaBaoUsePropReq", 0)	--使用道具请求
RegPBRet(9207, "WaBaoUsePropRet", "wabao.WaBaoUsePropRet", 0)	--使用道具成功返回
RegPBReq(9208, "WaBaoAwardInfoReq", "wabao.WaBaoAwardInfoReq", 0)	--活动奖励信息请求
RegPBRet(9209, "WaBaoAwardInfoRet", "wabao.WaBaoAwardInfoRet", 0)	--活动奖励信息返回
RegPBReq(9210, "WaBaoAwardReq", "wabao.WaBaoAwardReq", 0)	--活动奖励领取请求
RegPBRet(9211, "WaBaoAwardRet", "wabao.WaBaoAwardRet", 0)	--活动奖励领取返回
RegPBReq(9212, "WaBaoExchangeListReq", "wabao.WaBaoExchangeListReq", 0)	--活动兑换列表请求
RegPBRet(9213, "WaBaoExchangeListRet", "wabao.WaBaoExchangeListRet", 0)	--活动兑换列表返回
RegPBReq(9214, "WaBaoExchangeReq", "wabao.WaBaoExchangeReq", 0)	--兑换物品请求
RegPBRet(9215, "WaBaoExchangeRet", "wabao.WaBaoExchangeRet", 0)	--兑换成功返回
RegPBReq(9216, "WaBaoRankingReq", "wabao.WaBaoRankingReq", 0)	--排行榜请求
RegPBRet(9217, "WaBaoRankingRet", "wabao.WaBaoRankingRet", 0)	--排行榜返回
RegPBReq(9218, "WaBaoRankAwardInfoReq", "wabao.WaBaoRankAwardInfoReq", 0)	--排行奖励信息请求
RegPBRet(9219, "WaBaoRankAwardInfoRet", "wabao.WaBaoRankAwardInfoRet", 0)	--排行奖励信息返回
RegPBReq(9220, "WaBaoRankAwardReq", "wabao.WaBaoRankAwardReq", 0)	--领取排行奖励请求
RegPBRet(9221, "WaBaoRankAwardRet", "wabao.WaBaoRankAwardRet", 0)	--领取排行奖励成功返回

--怡红院
RegPBReq(9230, "YHYInfoReq", "yihongyuan.YHYInfoReq", 0)			--怡红院请求
RegPBRet(9231, "YHYInfoRet", "yihongyuan.YHYInfoRet", 0)			--怡红院返回
RegPBReq(9232, "YHYChouJiangReq", "yihongyuan.YHYChouJiangReq", 0)	--抽奖请求
RegPBRet(9233, "YHYChouJiangRet", "yihongyuan.YHYChouJiangRet", 0)	--抽奖返回
RegPBReq(9234, "YHYBuyGongNvReq", "yihongyuan.YHYBuyGongNvReq", 0)	--宫女赎身请求
RegPBRet(9235, "YHYBuyGongNvRet", "yihongyuan.YHYBuyGongNvRet", 0)	--宫女赎身成功返回
RegPBReq(9236, "YHYAddSpeedReq", "yihongyuan.YHYAddSpeedReq", 0)	--怡红院加速

--造人强国
RegPBReq(9240, "ZRQGStateReq", "zaorenqiangguo.ZRQGStateReq", 0)           			--活动状态请求
RegPBRet(9241, "ZRQGStateRet", "zaorenqiangguo.ZRQGStateRet", 0)           			--活动状态返回
RegPBReq(9242, "ZRQGInfoReq", "zaorenqiangguo.ZRQGInfoReq", 0)           			--造人强国请求
RegPBRet(9243, "ZRQGInfoRet", "zaorenqiangguo.ZRQGInfoRet", 0)           			--造人强国返回
RegPBReq(9244, "ZRQGUseDYReq", "zaorenqiangguo.ZRQGUseDYReq", 0)         			--使用丹药请求
RegPBReq(9245, "ZRQGReportSoldierReq", "zaorenqiangguo.ZRQGReportSoldierReq", 0)    --造人校验请求
RegPBReq(9246, "ZRQGRankingReq", "zaorenqiangguo.ZRQGRankingReq", 0)     			--造人强国排行榜请求
RegPBRet(9247, "ZRQGRankingRet", "zaorenqiangguo.ZRQGRankingRet", 0)     			--造人强国排行榜返回
RegPBReq(9248, "ZRQGOffInterfaceReq", "zaorenqiangguo.ZRQGOffInterfaceReq", 0)     	--关闭界面请求

--累充奖励
RegPBReq(9290, "LeiChongStateReq", "leichong.LeiChongStateReq", 0) 		--活动状态请求
RegPBRet(9291, "LeiChongStateRet", "leichong.LeiChongStateRet", 0) 		--活动状态返回
RegPBReq(9292, "LeiChongInfoReq", "leichong.LeiChongInfoReq", 0) 		--活动信息请求
RegPBRet(9293, "LeiChongInfoRet", "leichong.LeiChongInfoRet", 0) 		--活动信息返回
RegPBReq(9294, "LeiChongAwardReq", "leichong.LeiChongAwardReq", 0) 		--领取奖励请求
RegPBRet(9295, "LeiChongAwardRet", "leichong.LeiChongAwardRet", 0) 		--领取奖励成功返回
RegPBReq(9296, "LCGameInfoReq", "leichong.LCGameInfoReq", 0) 			--累充小游戏信息请求
RegPBRet(9297, "LCGameInfoRet", "leichong.LCGameInfoRet", 0) 			--累充小游戏信息返回
RegPBReq(9298, "LCGameRefreshReq", "leichong.LCGameRefreshReq", 0) 		--刷新妃子请求
RegPBReq(9299, "LCGameBuyPropReq", "leichong.LCGameBuyPropReq", 0) 		--购买按摩棒请求
RegPBReq(9300, "LCGameUsePropReq", "leichong.LCGameUsePropReq", 0) 		--使用按摩棒
RegPBRet(9301, "LCGameUsePropRet", "leichong.LCGameUsePropRet", 0) 		--使用按摩棒成功返回

--小红点
RegPBRet(9320, "RedPointStateRet", "redpoint.RedPointStateRet", 0)		--小红点同步

--膜拜
RegPBReq(9480, "MoBaiReq", "mobai.MoBaiReq", 0)   	--膜拜请求
RegPBRet(9481, "MoBaiRet", "mobai.MoBaiRet", 0)   	--膜拜返回
RegPBRet(9482, "MoBaiRedPointRet", "mobai.MoBaiRedPointRet", 0)   	--膜拜小红点

--排行榜中玩家信息请求
RegPBReq(9500, "RankingPlayerInfoReq", "login.RankingPlayerInfoReq", 0)   	--排行榜中玩家信息请求
RegPBRet(9501, "RankingPlayerInfoRet", "login.RankingPlayerInfoRet", 0)   	--排行榜中玩家信息返回

--神迹祝福
RegPBRet(9510, "ShenJiZhuFuRet", "shenjizhufu.ShenJiZhuFuRet", 0)			--神迹祝福返回
RegPBReq(9511, "ShenJiCardInfoReq", "shenjizhufu.ShenJiCardInfoReq", 0)		--神迹祝福月卡/季卡请求
RegPBRet(9512, "ShenJiCardInfoRet", "shenjizhufu.ShenJiCardInfoRet", 0)		--神迹祝福月卡/季卡返回
RegPBReq(9513, "ShenJiCardAwardReq", "shenjizhufu.ShenJiCardAwardReq", 0)	--神迹祝福月卡/季卡奖励请求
RegPBRet(9514, "ShenJiCardAwardRet", "shenjizhufu.ShenJiCardAwardRet", 0)	--神迹祝福月卡/季卡奖励成功返回
RegPBReq(9515, "TrialMonthCardReq", "shenjizhufu.TrialMonthCardReq", 0)		--试用月卡请求
RegPBReq(9516, "ShenJiZhuFuInfoReq", "shenjizhufu.ShenJiZhuFuInfoReq", 0)	--神迹祝福次数信息请求
RegPBRet(9517, "ShenJiZhuFuInfoRet", "shenjizhufu.ShenJiZhuFuInfoRet", 0)	--神迹祝福次数信息返回

--神秘宝箱
RegPBRet(9521, "SMBXInfoRet", "shenmibaoxiang.SMBXInfoRet", 0)			--神秘宝箱状态同步
RegPBReq(9522, "SMBXDescReq", "shenmibaoxiang.SMBXDescReq", 31)			--神秘宝箱描述请求
RegPBRet(9523, "SMBXDescRet", "shenmibaoxiang.SMBXDescRet", 0)			--神秘宝箱描述返回
RegPBReq(9524, "SMBXExchangeReq", "shenmibaoxiang.SMBXExchangeReq", 31)	--神秘宝箱兑换请求
RegPBRet(9525, "SMBXExchangeRet", "shenmibaoxiang.SMBXExchangeRet", 0)	--神秘宝箱兑换返回

--限时选秀
RegPBReq(9540, "TimeDrawStateReq", "timedraw.TimeDrawStateReq", 0)			--限时选秀状态请求
RegPBRet(9541, "TimeDrawStateRet", "timedraw.TimeDrawStateRet", 0)			--限时选秀状态返回
RegPBReq(9542, "TimeDrawReq", "timedraw.TimeDrawReq", 0)					--限时选秀请求
RegPBRet(9543, "TimeDrawRet", "timedraw.TimeDrawRet", 0)					--限时选秀返回
RegPBReq(9544, "TimeDrawRankingReq", "timedraw.TimeDrawRankingReq", 0)		--限时选秀排行榜请求
RegPBRet(9545, "TimeDrawRankingRet", "timedraw.TimeDrawRankingRet", 0)		--限时选秀排行榜返回

--宴会
RegPBReq(9565, "PartySceneReq", "party.PartySceneReq", 0) 					--宴会场景请求
RegPBRet(9566, "PartySceneRet", "party.PartySceneRet", 0) 					--宴会场景返回
RegPBReq(9567, "PartyOpenReq", "party.PartyOpenReq", 0) 					--开启宴会请求

RegPBRet(9568, "PartyOpenRet", "party.PartyOpenRet", 0) 					--开启宴会成功返回
RegPBReq(9569, "PartyInfoReq", "party.PartyInfoReq", 0) 					--宴会内部信息请求

RegPBRet(9570, "PartyInfoRet", "party.PartyInfoRet", 0) 					--宴会内部信息返回
RegPBReq(9571, "PartyQueryReq", "party.PartyQueryReq", 0) 					--玩家宴会查询
RegPBRet(9572, "PartyQueryRet", "party.PartyQueryRet", 0) 					--玩家宴会查询返回

RegPBReq(9573, "PartyJoinReq", "party.PartyJoinReq", 0) 					--玩家赴宴请求
RegPBRet(9574, "PartyJoinRet", "party.PartyJoinRet", 0) 					--玩家赴宴成功请求
RegPBReq(9575, "PartyMessageReq", "party.PartyMessageReq", 0) 				--宴会信息请求

RegPBRet(9576, "PartyMessageRet", "party.PartyMessageRet", 0) 				--宴会信息返回
RegPBReq(9577, "PartyGoodsListReq", "party.PartyGoodsListReq", 0) 			--物品列表请求
RegPBRet(9578, "PartyGoodsListRet", "party.PartyGoodsListRet", 0) 			--物品列表返回

RegPBReq(9579, "PartyRefreshGoodsReq", "party.PartyRefreshGoodsReq", 0) 		--刷新物品请求
RegPBReq(9580, "PartyExchangeGoodsReq", "party.PartyExchangeGoodsReq", 0) 		--兑换物品请求
RegPBRet(9581, "PartyExchangeGoodsRet", "party.PartyExchangeGoodsRet", 0) 		--兑换物品成功返回
RegPBReq(9582, "PartyRankingReq", "party.PartyRankingReq", 0) 					--宴会排行榜请求
RegPBRet(9583, "PartyRankingRet", "party.PartyRankingRet", 0) 					--宴会排行榜返回
RegPBRet(9584, "PartyFinishRet", "party.PartyFinishRet", 0) 					--宴会结束返回


--兑换码兑换
RegPBReq(9620, "KeyExchangeReq", "keyexchange.KeyExchangeReq", 31)	--兑换码兑换请求
RegPBRet(9621, "KeyExchangeRet", "keyexchange.KeyExchangeRet", 0)	--兑换码兑换返回

--祈福活动
RegPBReq(9630, "QiFuStateReq", "qifu.QiFuStateReq", 0)								--活动信息状态请求
RegPBRet(9631, "QiFuStateRet", "qifu.QiFuStateRet", 0)								--活动信息状态返回
RegPBReq(9632, "QiFuPropListReq", "qifu.QiFuPropListReq", 0)						--道具列表请求
RegPBRet(9633, "QiFuPropListRet", "qifu.QiFuPropListRet", 0)						--道具列表返回
RegPBReq(9634, "QiFuBuyPropReq", "qifu.QiFuBuyPropReq", 0)							--购买道具请求
RegPBRet(9635, "QiFuBuyPropRet", "qifu.QiFuBuyPropRet", 0)							--购买道具返回
RegPBReq(9636, "QiFuUsePropReq", "qifu.QiFuUsePropReq", 0)							--使用道具请求
RegPBRet(9637, "QiFuUsePropRet", "qifu.QiFuUsePropRet", 0)							--使用道具返回
RegPBReq(9638, "QiFuServerAwardReq", "qifu.QiFuServerAwardReq", 0)					--全服积分奖励信息请求
RegPBRet(9639, "QiFuServerAwardRet", "qifu.QiFuServerAwardRet", 0)					--全服积分奖励信息返回
RegPBReq(9640, "QiFuGetServerAwardReq", "qifu.QiFuGetServerAwardReq", 0)			--全服积分奖励获取请求
RegPBRet(9641, "QiFuGetServerAwardRet", "qifu.QiFuGetServerAwardRet", 0)			--全服积分奖励获取返回
RegPBReq(9642, "QiFuExChangeListReq", "qifu.QiFuExChangeListReq", 0)				--兑换列表请求
RegPBRet(9643, "QiFuExChangeListRet", "qifu.QiFuExChangeListRet", 0)				--兑换列表返回
RegPBReq(9644, "QiFuExChangeItemReq", "qifu.QiFuExChangeItemReq", 0)				--兑换物品请求
RegPBRet(9645, "QiFuExChangeItemRet", "qifu.QiFuExChangeItemRet", 0)				--兑换物品返回
RegPBReq(9646, "QiFuRankingReq", "qifu.QiFuRankingReq", 0)							--排行榜请求
RegPBRet(9647, "QiFuRankingRet", "qifu.QiFuRankingRet", 0)							--排行榜返回
RegPBReq(9648, "QiFuRankingAwardStateReq", "qifu.QiFuRankingAwardStateReq", 0)		--排行榜奖励状态请求
RegPBRet(9649, "QiFuRankingAwardStateRet", "qifu.QiFuRankingAwardStateRet", 0)		--排行榜奖励状态返回
RegPBReq(9650, "QiFuGetRankAwardReq", "qifu.QiFuGetRankAwardReq", 0)				--排行榜领取奖励请求
RegPBRet(9651, "QiFuGetRankAwardRet", "qifu.QiFuGetRankAwardRet", 0)				--排行榜领取奖励返回

--奖励记录
RegPBReq(9660, "AwardRecordReq", "awardrecord.AwardRecordReq", 0) 		--奖励记录请求
RegPBRet(9661, "AwardRecordRet", "awardrecord.AwardRecordRet", 0) 		--奖励记录返回

--电视广告
RegPBRet(9670, "TVRet", "tv.TVRet", 0) 		--电视广告返回

--妃子请安信息
RegPBReq(9680, "FZQingAnInfoReq", "feizi.FZQingAnInfoReq", 0) 	--妃子请安信息请求
RegPBRet(9681, "FZQingAnInfoRet", "feizi.FZQingAnInfoRet", 0) 	--妃子请安信息返回

--狩猎活动
RegPBReq(9690, "ShouLieStateReq", "shoulie.ShouLieStateReq", 0)	--活动状态信息请求
RegPBRet(9691, "ShouLieStateRet", "shoulie.ShouLieStateRet", 0)	--活动状态信息返回
RegPBReq(9692, "ShouLiePropListReq", "shoulie.ShouLiePropListReq", 0)	--道具列表请求
RegPBRet(9693, "ShouLiePropListRet", "shoulie.ShouLiePropListRet", 0)	--道具列表返回
RegPBReq(9694, "ShouLieBuyPropReq", "shoulie.ShouLieBuyPropReq", 0)	--购买道具请求
RegPBRet(9695, "ShouLieBuyPropRet", "shoulie.ShouLieBuyPropRet", 0)	--购买道具成功返回
RegPBReq(9696, "ShouLieUsePropReq", "shoulie.ShouLieUsePropReq", 0)	--使用道具请求
RegPBRet(9697, "ShouLieUsePropRet", "shoulie.ShouLieUsePropRet", 0)	--使用道具成功返回
RegPBReq(9698, "ShouLieAwardInfoReq", "shoulie.ShouLieAwardInfoReq", 0)	--活动奖励信息请求
RegPBRet(9699, "ShouLieAwardInfoRet", "shoulie.ShouLieAwardInfoRet", 0)	--活动奖励信息返回
RegPBReq(9700, "ShouLieAwardReq", "shoulie.ShouLieAwardReq", 0)	--活动奖励领取请求
RegPBRet(9701, "ShouLieAwardRet", "shoulie.ShouLieAwardRet", 0)	--活动奖励领取返回
RegPBReq(9702, "ShouLieExchangeListReq", "shoulie.ShouLieExchangeListReq", 0)	--活动兑换列表请求
RegPBRet(9703, "ShouLieExchangeListRet", "shoulie.ShouLieExchangeListRet", 0)	--活动兑换列表返回
RegPBReq(9704, "ShouLieExchangeReq", "shoulie.ShouLieExchangeReq", 0)	--兑换物品请求
RegPBRet(9705, "ShouLieExchangeRet", "shoulie.ShouLieExchangeRet", 0)	--兑换成功返回
RegPBReq(9706, "ShouLieRankingReq", "shoulie.ShouLieRankingReq", 0)	--排行榜请求
RegPBRet(9707, "ShouLieRankingRet", "shoulie.ShouLieRankingRet", 0)	--排行榜返回
RegPBReq(9708, "ShouLieRankAwardInfoReq", "shoulie.ShouLieRankAwardInfoReq", 0)	--排行奖励信息请求
RegPBRet(9709, "ShouLieRankAwardInfoRet", "shoulie.ShouLieRankAwardInfoRet", 0)	--排行奖励信息返回
RegPBReq(9710, "ShouLieRankAwardReq", "shoulie.ShouLieRankAwardReq", 0)	--领取排行奖励请求
RegPBRet(9711, "ShouLieRankAwardRet", "shoulie.ShouLieRankAwardRet", 0)	--领取排行奖励成功返回

--花魁活动
RegPBReq(9720, "HuaKuiStateReq", "huakui.HuaKuiStateReq", 0)	--活动状态信息请求
RegPBRet(9721, "HuaKuiStateRet", "huakui.HuaKuiStateRet", 0)	--活动状态信息返回
RegPBReq(9722, "HuaKuiPropListReq", "huakui.HuaKuiPropListReq", 0)	--道具列表请求
RegPBRet(9723, "HuaKuiPropListRet", "huakui.HuaKuiPropListRet", 0)	--道具列表返回
RegPBReq(9724, "HuaKuiBuyPropReq", "huakui.HuaKuiBuyPropReq", 0)	--购买道具请求
RegPBRet(9725, "HuaKuiBuyPropRet", "huakui.HuaKuiBuyPropRet", 0)	--购买道具成功返回
RegPBReq(9726, "HuaKuiUsePropReq", "huakui.HuaKuiUsePropReq", 0)	--使用道具请求
RegPBRet(9727, "HuaKuiUsePropRet", "huakui.HuaKuiUsePropRet", 0)	--使用道具成功返回
RegPBReq(9728, "HuaKuiAwardInfoReq", "huakui.HuaKuiAwardInfoReq", 0)	--活动奖励信息请求
RegPBRet(9729, "HuaKuiAwardInfoRet", "huakui.HuaKuiAwardInfoRet", 0)	--活动奖励信息返回
RegPBReq(9730, "HuaKuiAwardReq", "huakui.HuaKuiAwardReq", 0)	--活动奖励领取请求
RegPBRet(9731, "HuaKuiAwardRet", "huakui.HuaKuiAwardRet", 0)	--活动奖励领取返回
RegPBReq(9732, "HuaKuiExchangeListReq", "huakui.HuaKuiExchangeListReq", 0)	--活动兑换列表请求
RegPBRet(9733, "HuaKuiExchangeListRet", "huakui.HuaKuiExchangeListRet", 0)	--活动兑换列表返回
RegPBReq(9734, "HuaKuiExchangeReq", "huakui.HuaKuiExchangeReq", 0)	--兑换物品请求
RegPBRet(9735, "HuaKuiExchangeRet", "huakui.HuaKuiExchangeRet", 0)	--兑换成功返回
RegPBReq(9736, "HuaKuiRankingReq", "huakui.HuaKuiRankingReq", 0)	--排行榜请求
RegPBRet(9737, "HuaKuiRankingRet", "huakui.HuaKuiRankingRet", 0)	--排行榜返回
RegPBReq(9738, "HuaKuiRankAwardInfoReq", "huakui.HuaKuiRankAwardInfoReq", 0)	--排行奖励信息请求
RegPBRet(9739, "HuaKuiRankAwardInfoRet", "huakui.HuaKuiRankAwardInfoRet", 0)	--排行奖励信息返回
RegPBReq(9740, "HuaKuiRankAwardReq", "huakui.HuaKuiRankAwardReq", 0)	--领取排行奖励请求
RegPBRet(9741, "HuaKuiRankAwardRet", "huakui.HuaKuiRankAwardRet", 0)	--领取排行奖励成功返回

--点灯活动
RegPBReq(9750, "DianDengStateReq", "diandeng.DianDengStateReq", 0)	--活动状态信息请求
RegPBRet(9751, "DianDengStateRet", "diandeng.DianDengStateRet", 0)	--活动状态信息返回
RegPBReq(9752, "DianDengPropListReq", "diandeng.DianDengPropListReq", 0)	--道具列表请求
RegPBRet(9753, "DianDengPropListRet", "diandeng.DianDengPropListRet", 0)	--道具列表返回
RegPBReq(9754, "DianDengBuyPropReq", "diandeng.DianDengBuyPropReq", 0)	--购买道具请求
RegPBRet(9755, "DianDengBuyPropRet", "diandeng.DianDengBuyPropRet", 0)	--购买道具成功返回
RegPBReq(9756, "DianDengUsePropReq", "diandeng.DianDengUsePropReq", 0)	--使用道具请求
RegPBRet(9757, "DianDengUsePropRet", "diandeng.DianDengUsePropRet", 0)	--使用道具成功返回
RegPBReq(9758, "DianDengAwardInfoReq", "diandeng.DianDengAwardInfoReq", 0)	--活动奖励信息请求
RegPBRet(9759, "DianDengAwardInfoRet", "diandeng.DianDengAwardInfoRet", 0)	--活动奖励信息返回
RegPBReq(9760, "DianDengAwardReq", "diandeng.DianDengAwardReq", 0)	--活动奖励领取请求
RegPBRet(9761, "DianDengAwardRet", "diandeng.DianDengAwardRet", 0)	--活动奖励领取返回
RegPBReq(9762, "DianDengExchangeListReq", "diandeng.DianDengExchangeListReq", 0)	--活动兑换列表请求
RegPBRet(9763, "DianDengExchangeListRet", "diandeng.DianDengExchangeListRet", 0)	--活动兑换列表返回
RegPBReq(9764, "DianDengExchangeReq", "diandeng.DianDengExchangeReq", 0)	--兑换物品请求
RegPBRet(9765, "DianDengExchangeRet", "diandeng.DianDengExchangeRet", 0)	--兑换成功返回
RegPBReq(9766, "DianDengRankingReq", "diandeng.DianDengRankingReq", 0)	--排行榜请求
RegPBRet(9767, "DianDengRankingRet", "diandeng.DianDengRankingRet", 0)	--排行榜返回
RegPBReq(9768, "DianDengRankAwardInfoReq", "diandeng.DianDengRankAwardInfoReq", 0)	--排行奖励信息请求
RegPBRet(9779, "DianDengRankAwardInfoRet", "diandeng.DianDengRankAwardInfoRet", 0)	--排行奖励信息返回
RegPBReq(9770, "DianDengRankAwardReq", "diandeng.DianDengRankAwardReq", 0)	--领取排行奖励请求
RegPBRet(9771, "DianDengRankAwardRet", "diandeng.DianDengRankAwardRet", 0)	--领取排行奖励成功返回

--国使馆
RegPBReq(9810, "GSGInfoReq", "guoshiguan.GSGInfoReq", 0)		--国使馆界面请求
RegPBRet(9811, "GSGInfoRet", "guoshiguan.GSGInfoRet", 0)		--国使馆界面返回
RegPBReq(9812, "GSGTaoJiaoReq", "guoshiguan.GSGTaoJiaoReq", 0)	--讨教请求
RegPBRet(9813, "GSGTaoJiaoRet", "guoshiguan.GSGTaoJiaoRet", 0)	--讨教返回
RegPBRet(9816, "GSGRedPointRet", "guoshiguan.GSGRedPointRet", 0)--小红点返回

--播报
RegPBRet(9820, "UpdateRankingRet", "broadcast.UpdateRankingRet", 0)		--国力排名变更返回
RegPBRet(9821, "BroadcastRet", "broadcast.BroadcastRet", 0)				--播报返回

--成就
RegPBReq(9880, "AchievementsInfoReq", "achievements.AchievementsInfoReq", 0) 	 --成就界面请求
RegPBRet(9881, "AchievementsInfoRet", "achievements.AchievementsInfoRet", 0)  	 --成就界面返回
RegPBReq(9882, "AchievementsStateReq", "achievements.AchievementsStateReq", 0) 	 --成就状态请求
RegPBRet(9883, "AchievementsStateRet", "achievements.AchievementsStateRet", 0) 	 --成就状态返回
RegPBReq(9884, "tAchievementsAwardReq", "achievements.tAchievementsAwardReq", 0) --成就奖励请求
RegPBRet(9825, "AchievementsAwardRet", "achievements.AchievementsAwardRet", 0) --成就奖励返回

--浩荡出巡
RegPBReq(9850, "XingGongInfoReq", "chuxun.XingGongInfoReq", 0)	--行宫信息请求
RegPBReq(9851, "CreateXingGongReq", "chuxun.CreateXingGongReq", 0)	--创建行宫请求
RegPBReq(9852, "CXAddFZReq", "chuxun.CXAddFZReq", 0)			--添加妃子请求
RegPBReq(9853, "CXAutoAddFZReq", "chuxun.CXAutoAddFZReq", 0)	--自动添加妃子请求
RegPBRet(9854, "XingGongInfoRet", "chuxun.XingGongInfoRet", 0)	--行宫信息同步
RegPBReq(9855, "ChuXunReq", "chuxun.ChuXunReq", 0)				--出巡请求
RegPBReq(9856, "FinishChuXunReq", "chuxun.FinishChuXunReq", 0)	--结束出巡请求
RegPBReq(9857, "GDInfoListReq", "chuxun.GDInfoListReq", 0)		--宫斗信息列表请求
RegPBRet(9858, "GDInfoListRet", "chuxun.GDInfoListRet", 0)		--宫斗信息列表返回
RegPBReq(9859, "CRInfoListReq", "chuxun.CRInfoListReq", 0)		--仇人列表请求
RegPBRet(9860, "CRInfoListRet", "chuxun.CRInfoListRet", 0)		--仇人列表返回
RegPBReq(9861, "CXTJListReq", "chuxun.CXTJListReq", 0)		--通缉列表请求
RegPBRet(9862, "CXTJListRet", "chuxun.CXTJListRet", 0)		--通缉列表返回
RegPBReq(9863, "StartGDReq", "chuxun.StartGDReq", 0)		--宫斗请求
RegPBReq(9864, "CXFuChouReq", "chuxun.CXFuChouReq", 0)		--复仇请求
RegPBReq(9865, "CXCatchReq", "chuxun.CXCatchReq", 0)		--抓捕请求
RegPBRet(9866, "CXBattleRet", "chuxun.CXBattleRet", 0)		--战斗返回
RegPBReq(9867, "CXTongJiReq", "chuxun.CXTongJiReq", 0)		--通缉玩家请求
RegPBReq(9868, "GDRankingReq", "chuxun.GDRankingReq", 0)	--宫斗排行榜请求
RegPBRet(9869, "GDRankingRet", "chuxun.GDRankingRet", 0)	--宫斗排行榜返回
RegPBRet(9870, "CXAddFZRet", "chuxun.CXAddFZRet", 0)		--添加妃子成功返回
RegPBReq(9871, "CXRemoveFZReq", "chuxun.CXRemoveFZReq", 0)	--移除妃子请求
RegPBRet(9872, "CXRemoveFZRet", "chuxun.CXRemoveFZRet", 0)	--移除妃子返回
RegPBReq(9873, "CXRankingTJListReq", "chuxun.CXRankingTJListReq", 0)	--排名通缉列表请求
RegPBRet(9874, "CXRankingTJListRet", "chuxun.CXRankingTJListRet", 0)	--排名通缉列表返回

--时装
RegPBRet(9890, "FashionListRet", "fashion.FashionListRet", 0)		--已经拥有的时装列表返回
RegPBRet(9891, "FashionWearRet", "fashion.FashionWearRet", 0)		--已穿戴时装返回
RegPBReq(9892, "FashionMallReq", "fashion.FashionMallReq", 0)		--时装商店请求
RegPBRet(9893, "FashionMallRet", "fashion.FashionMallRet", 0)		--时装商店返回
RegPBReq(9894, "FashionBuyReq", "fashion.FashionBuyReq", 0)			--购买时装请求
RegPBReq(9895, "FashionWearReq", "fashion.FashionWearReq", 0)			--穿时装请求
RegPBReq(9896, "FashionStrengthReq", "fashion.FashionStrengthReq", 0)	--强化请求
RegPBReq(9897, "FashionAdvanceReq", "fashion.FashionAdvanceReq", 0)		--进阶请求
RegPBReq(9898, "FashionUpgradeReq", "fashion.FashionUpgradeReq", 0)		--升级请求
RegPBReq(9899, "FashionMakeReq", "fashion.FashionMakeReq", 0)			--制作请求
RegPBReq(9900, "FashionOffReq", "fashion.FashionOffReq", 0)				--时装卸下请求

--天灯祈福
RegPBReq(10001, "TDQFInfoReq", "tiandeng.TDQFInfoReq", 0)		--天灯祈福信息请求
RegPBRet(10002, "TDQFInfoRet", "tiandeng.TDQFInfoRet", 0)		--天灯祈福信息返回
RegPBReq(10003, "TDQFReq", "tiandeng.TDQFReq", 0)				--天灯祈福祈福请求
RegPBRet(10004, "TDQFRet", "tiandeng.TDQFRet", 0)				--天灯祈福祈福返回

--知己游玩
RegPBReq(10050, "JSFInfoReq", "youwan.JSFInfoReq", 0) 			--游玩信息请求
RegPBRet(10051, "JSFInfoRet", "youwan.JSFInfoRet", 0) 			--游玩信息返回
RegPBReq(10052, "JSFOpenGridReq", "youwan.JSFOpenGridReq", 0)	--游玩扩建请求
RegPBReq(10053, "JSFOpenCardReq", "youwan.JSFOpenCardReq", 0) 	--游玩翻牌请求
RegPBReq(10054, "JSFFinishReq", "youwan.JSFFinishReq", 0) 		--游玩完成请求
RegPBReq(10055, "JSFSpeedUpInfoReq", "youwan.JSFSpeedUpInfoReq", 0)	--游玩加速信息请求
RegPBRet(10056, "JSFSpeedUpInfoRet", "youwan.JSFSpeedUpInfoRet", 0)	--游玩加速信息返回
RegPBReq(10057, "JSFSpeedUpReq", "youwan.JSFSpeedUpReq", 0)			--游玩加速请求
RegPBReq(10058, "JSFDetailReq", "youwan.JSFDetailReq", 0)			--游玩详情请求
RegPBRet(10059, "JSFDetailRet", "youwan.JSFDetailRet", 0)			--游玩详情返回

--赐礼
RegPBReq(10100, "LFYInfoReq", "lfy.LFYInfoReq", 0)					--信息请求
RegPBRet(10101, "LFYInfoRet", "lfy.LFYInfoRet", 0)					--信息返回
RegPBReq(10102, "LFYUpgradeReq", "lfy.LFYUpgradeReq", 0)			--赐礼
RegPBReq(10103, "LFYOneKeyUpgradeReq", "lfy.LFYOneKeyUpgradeReq", 0)--一键赐礼
RegPBRet(10104, "LFYUpgradeRet", "lfy.LFYUpgradeRet", 0)			--赐礼返回

