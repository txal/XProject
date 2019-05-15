gnMaxMailItemLength = 15 --邮件物品附件最大长度

--对象类型
gtItemType = 
{
	eNone = 0,
    eProp = 1,		--道具
    eCurr = 2,		--货币
    ePet  = 3, 		--宠物
    ePartner = 4,   --伙伴
	eFaBao = 5,		--法宝
	eAppellation = 6,  --称谓
}


--货币类型
gtCurrType = 
{
	eVIP = 1, 			--VIP等级
	eYuanBao = 2,		--非绑元宝
	eBYuanBao = 3, 		--绑定元宝
	eAllYuanBao = 230, 	--所有元宝(取数量,消耗可用,增加不可用)
	eJinBi = 4, 	--金币
	eYinBi = 5,		--银币
	eVitality = 6, 	--活力
	eExp = 7, 		--经验
	eStoreExp = 8, 	--储备经验(已屏蔽)
	ePotential = 9, --潜力点
	eArenaCoin = 10, 	--竞技币
	ePracticeExp = 11,	--修炼经验
	ePartnerStoneCollect = 12,  --灵石采集许可
	ePartnerStoneGreen = 13, 	--绿灵石
	ePartnerStoneBlue = 14, 	--蓝灵石
	ePartnerStonePurple = 15, 	--紫灵石
	ePartnerStoneOrange = 16, 	--橙灵石
	ePetExp = 17, 				--宠物经验
	eChivalry = 18, 	--侠义值
	eActValue = 19,		--活跃值
	eShuangBei = 20,	--双倍点数
	eUnionContri = 21, 	--帮贡
	eUnionExp = 22, 		--联盟经验(不在角色身上)
	eUnionActivity = 23, 	--联盟活跃度(不在角色身上)
	eJinDing = 24,	--金锭
	eFuYuan = 25,	--福缘值
	eLanZuan = 26,	--蓝钻
	eDrawSpirit = 27,           --摄魂灵气
	eMagicPill = 28,            --摄魂内丹
	eEvilCrystal = 29,          --摄魂妖晶
}

gtCurrName = 
{
	[gtCurrType.eYuanBao] = "元宝",
	[gtCurrType.eBYuanBao] = "元宝",
	[gtCurrType.eAllYuanBao] = "元宝",
	[gtCurrType.eJinBi] = "金币",
	[gtCurrType.eYinBi] = "银币",
	[gtCurrType.eVitality] = "活力",
	[gtCurrType.eExp] = "经验",
	[gtCurrType.eStoreExp] = "储备经验",
	[gtCurrType.ePotential] = "潜力点",
	[gtCurrType.eArenaCoin] = "竞技币",
	[gtCurrType.ePracticeExp] = "修炼经验",
	[gtCurrType.ePartnerStoneCollect] = "灵石采集许可令",
	[gtCurrType.ePartnerStoneGreen] = "绿灵石",
	[gtCurrType.ePartnerStoneBlue] = "蓝灵石",
	[gtCurrType.ePartnerStonePurple] = "紫灵石",
	[gtCurrType.ePartnerStoneOrange] = "橙灵石",
	[gtCurrType.ePetExp] = "宠物经验", 
	[gtCurrType.eChivalry] = "侠义值",
	[gtCurrType.eActValue] = "活跃值",
	[gtCurrType.eShuangBei] = "双倍点数", 
	[gtCurrType.eUnionContri] = "帮贡",
	[gtCurrType.eUnionExp] = "联盟经验",
	[gtCurrType.eUnionActivity] = "联盟活跃度",
	[gtCurrType.eJinDing] = "金锭",
	[gtCurrType.eFuYuan] = "福缘值",
	[gtCurrType.eLanZuan] = "蓝钻",
	[gtCurrType.eDrawSpirit] = "灵气",
	[gtCurrType.eMagicPill] = "内丹",
	[gtCurrType.eEvilCrystal] = "妖晶", 
}

--元宝兑换系数
gtCurrYuanbaoExchangeRatio = 
{
	[gtCurrType.eYuanBao] = 1,  --主要简化其他地方计算逻辑
	[gtCurrType.eBYuanBao] = 1,
	[gtCurrType.eAllYuanBao] = 1,
	[gtCurrType.eJinBi] = 10,
	[gtCurrType.eYinBi] = 1000,
}

--货币比例
gnGoldRatio = gtCurrYuanbaoExchangeRatio[gtCurrType.eJinBi] 		--1元宝金币数
gnSilverRatio = gtCurrYuanbaoExchangeRatio[gtCurrType.eYinBi] 	--1元宝银币数
gnGold2SilverRatio = gnSilverRatio // gnGoldRatio --金币换银币比率

gnSaleSilverRatio = 2000

--道具品质颜色
gtQualityColor = {
	eWhite = 1, 		--白
	eGreen = 2, 		--绿
	eBlue = 3, 			--蓝
	ePurple = 4,		--紫
	eOrange = 5,		--橙
}

gtQualityStringColor = 
{
	[gtQualityColor.eWhite] = "whitequality",
	[gtQualityColor.eGreen] = "greenquality",
	[gtQualityColor.eBlue] = "bluequality",
	[gtQualityColor.ePurple] = "purplequality",
	[gtQualityColor.eOrange] = "orangequality",
}


--场景对象类型
gtObjType = 
{
	eRole = 1,	 	--角色
	eChild = 2, 	--子女
	ePartner = 3, 	--伙伴
	ePet = 4, 		--宠物
	eMonster = 5, 	--怪物
}


--门派类型
gtSchoolType = 
{
	eGW = 1, 	--鬼王(物理单攻)
	eQY = 2, 	--青云(法术群攻)
	eTY = 3,	--天音(治疗辅助)
	eHH = 4, 	--合欢(物理群攻)
	eSW = 5, 	--圣巫(封印控制)
}

--门派名称
gtSchoolName = {}
for _, nSchoolID in pairs(gtSchoolType) do 
	gtSchoolName[nSchoolID] = ctRolePotentialConf[nSchoolID].sName
end

--主属性
gtMAT =
{
	eTZ = 1, 	--体质
	eML = 2,	--魔力
	eLL = 3,	--力量
	eNL = 4,	--耐力
	eMJ = 5,	--敏捷
}
--主属性名
gtMATName = 
{
	[gtMAT.eTZ] = "体质",
	[gtMAT.eML] = "魔力",
	[gtMAT.eLL] = "力量",
	[gtMAT.eNL] = "耐力",
	[gtMAT.eMJ] = "敏捷",
}

--战斗属性类型(值)
gtBAT = 
{
	eQX = 101, 	--气血
	eMF = 102, 	--魔法
	eNQ = 103, 	--怒气
	eGJ = 104, 	--攻击
	eFY = 105, 	--防御
	eLL = 106, 	--灵力
	eSD = 107, 	--速度
	eWLSH = 108, 	--物理伤害(百分比100倍,战斗中用)
	eWLSS = 109, 	--物理受伤(百分比100倍,战斗中用)
	eFSGJ = 201,	--法术攻击(值)
	eFSFY = 202, 	--法术防御(值)
	eZLQD = 203, 	--治疗强度(值)
	eFYMZ = 204,	--封印命中(百分比100倍)
	eFYKX = 205, 	--封印抗性(百分比100倍)
	eFSMZ = 206, 	--法术命中(百分比100倍)
	eFSSB = 207,	--法术闪避(百分比100倍)
	eFSSH = 208, 	--法术伤害(百分比100倍,战斗中用)
	eFSSS = 209, 	--法术受伤(百分比100倍,战斗中用)
	eFSBJ = 210, 	--法术暴击(百分比100倍,战斗中用)
	eFSKB = 211, 	--法术抗暴(百分比100倍,战斗中用)
	eMZL = 301, 	--命中率(百分比100倍,战斗中用)
	eSBL = 302, 	--闪避率(百分比100倍,战斗中用)
	eBJL = 303, 	--暴击率(百分比100倍,战斗中用)
	eKBL = 304, 	--抗暴率(百分比100倍,战斗中用)
	eTPL = 305, 	--逃跑率(百分比100倍,战斗中用)
	eZBL = 306, 	--追捕率(百分比100倍,战斗中用)
	eSH = 401,		--物理+法术伤害(百分比100倍),注意这个只在阵法加成中用,进入战斗时转成物理伤害和法术伤害
	eSS = 402,		--物理+法术受伤(百分比100倍),注意这个只在阵法加成中用,进入战斗时转成物理受伤和法术受伤
	eZLXG = 501, 	--治疗效果
	eQXSX = 502, 	--气血上限
}

--战斗属性范围定义
gtBAD = 
{
	eMinRAT = 101, 	--结果属性范围
	eMaxRAT = 109,
	eMinAAT = 201, 	--高级属性范围
	eMaxAAT = 211,
	eMinHAT = 301, 	--隐藏属性范围
	eMaxHAT = 306,
}

--战斗属性名称
gtBATName = 
{
	[gtBAT.eQX] = "气血",
	[gtBAT.eMF] = "魔法",
	[gtBAT.eGJ] = "攻击",
	[gtBAT.eFY] = "防御",
	[gtBAT.eSD] = "速度",
	[gtBAT.eNQ] = "怒气",
	[gtBAT.eFSGJ] = "法术攻击",
	[gtBAT.eFSFY] = "法术防御",
}

--法术分类
gtSKT = 
{
	eGJ = 1, 	--攻击
	eFZ = 2, 	--辅助
	eHX = 4, 	--回血
	eZF = 5, 	--增幅
	eFY = 6, 	--封印
	eJJ = 7, 	--绝技
}

--法术系别
gtSKD =
{
	eL = 1, 	--雷
	eS = 2, 	--水
	eH = 3, 	--火
	eT = 4, 	--土
	eF = 5, 	--风
}

--法术类型
gtSKAT = 
{
	eQW = 1,	--群物
	eDW = 2, 	--单物
	eQF = 3,	--群发
	eDF = 4,	--单发
}

--法术目标类型
gtSKTT = 
{
	eJFSJ = 1, 	--己方随机	
	eDFSJ = 2, 	--敌方随机
	eJFSW = 3, 	--己方死亡
	eDFQX = 4, 	--敌方气血升序
	eJFQX = 5, 	--己方气血升序
	eZJ = 6, 	--自己
	eJFCW = 7, 	--己方宠物
	eDFCW = 8, 	--敌方宠物
}

--技能状态类型
gtSTT = 
{
	eYC = 1, 	--异常状态
	eFZ = 2, 	--辅助状态
	eLS = 3, 	--临时状态
	eTS = 4, 	--特殊状态
}

--BUFF状态属性
gtSTA = 
{
	eWZD = 0, 	--未指定	
	eSXL = 1, 	--属性类
	eFY = 2, 	--封印
	eHF = 3, 	--恢复
	eFZ = 4, 	--辅助
	eJY = 5, 	--减益
}

--账号状态
gtAccountState = 
{
	eNone = 0, 	
	eLockTalk = 1, 		--禁言
	eLockAccount = 2, 	--封号
}

--玩家状态
gtRoleActState =  
{
	eNormal = 0,
	eWeddingApply = 1,     --婚礼申请中
	eWedding = 2,          --婚礼
	ePalanquinApply = 3,   --花轿申请中
	ePalanquinParade = 4,  --花轿游行
}

--玩家动作
gtRoleActID = 
{
	eNormal = 0,
}

--称号数据更新类型(所有模块用，暂时放在common/itemdef中)
gtAppellationOpType = 
{
	eAdd = 1,              --新增
	eUpdate = 2,           --更新
	eRemove = 3,           --删除
}

--师徒身份
gtMentorshipStatus = 
{
    eMaster = 1,            --师父
    eApprentice = 2,        --徒弟
}

--面向定义
gtFaceType = 
{
	eLeftTop = 0, --左上
	eRightTop = 1, --右上
	eRightBottom = 2, --右下
	eLeftBottom = 3, --左下
}

--副本战斗玩法类型
gtBattleDupType = 
{
	eFBTransitScene = 100,	--副本中转场景
	eZhenYao = 101, 		--镇妖
	eLuanShiYaoMo = 102, 	--乱世妖魔
	eXinMoQinShi = 103, 	--心魔侵蚀
	eShenShouLeYuan = 105,  --神兽乐园
	eShenMoZhi = 109,		--神魔志
	eTeachTest = 115,		--尊师考验
	eGuaJi = 117, 			--挂机

	 --限时活动2开头
    ePVEPrepare = 200,		--Pve准备场地
    eJueZhanJiuXiao = 201,	--决战九霄
    eHunDunShiLian = 202, 	--混沌试炼
	eMengZhuWuShuang = 203,	--梦诛无双
	
	eSchoolArena = 301,    --首席争霸
	eQimaiArena = 302,     --七脉会武
	eQingyunBattle = 303,  --青云之战
	eUnionArena = 304,     --帮战

	eArena = 401,          --竞技场
	
}

--PVP玩法对应配置ID
gtPVPBattleDupConfID = 
{
	[gtBattleDupType.eSchoolArena] = 1001,
	[gtBattleDupType.eQimaiArena] = 1002,
	[gtBattleDupType.eQingyunBattle] = 1003,
	[gtBattleDupType.eUnionArena] = 1004,
}


--用于客户端判断是哪种事件战斗结束(例：通过判断师门任务战斗结束自动进行下一任务)
gtBattleType = 
{
	eShiMen = 1001,			--师门任务战斗
	eShangJin = 1002,	    --赏金任务战斗
	ePrinTask = 1003,		--主线任务战斗
	eBranchTask = 1004,		--支线任务战斗
	eShiLianTask = 1005,	--试炼任务战斗
}


gtGenderDef = 
{
	eMale = 1,            --男
	eFemale = 2,          --女
}


gtAppellationIDDef = 
{
	eHusband = 29,         --xxx夫君
	eWife = 30,            --xxx娘子
	eForceDivorce = 32,    --恩断义绝
	eLover = 92,           --xxx情缘
	eBrother = 48,         --xxx兄弟
	eSister = 104,         --xxx姐妹
	eApprentice = 38,      --xxx徒弟
	eUpgradedApprentice = 93,   --xxx出师徒弟
}

gtSysOpenFlag = 
{
	eInit = 0, --初始
	eOpen = 1, --开放
	eClose = 2, --关闭(开了之后关闭)
}


gnUnionGiftBoxPropID = 11342

gtUnionGiftBoxReason = 
{
	eUnionArena = 1,       --跨服帮战
	eUnionExpCB = 2,       --帮派冲榜
}

gtEquPartType = 
{
	eWeapon = 1,          --武器
	eHat = 2,             --帽子
	eCoat = 3,            --衣服
	eNecklace = 4,        --项链
	eBelt = 5,            --腰带
	eShoes = 6,           --鞋子
}

gtRobotType = 
{
	eTeam = 1,           --队伍机器人
	eNormal = 2,         --正常机器人，需要模块自己管理生命周期
	ePVPAct = 3,         --PVP活动机器人
}

--属性->战力换算
gtEquAttrConvertRate = {
	[gtBAT.eQX]=7.1,
	[gtBAT.eMF]=10,
	[gtBAT.eGJ]=40.8,
	[gtBAT.eFY]=47.6,
	[gtBAT.eLL]=142.8,
	[gtBAT.eSD]=142.8,
	[gtBAT.eFSGJ]=40.8,
	[gtMAT.eTZ]=100,
	[gtMAT.eML]=100,
	[gtMAT.eLL]=100,
	[gtMAT.eNL]=100,
	[gtMAT.eMJ]=100,
}


gnWeddingCandyPropID = 11009  --喜糖ID

gtRoleTarActFlag = 
{
	eNormal = 0,
	eArena = 1,         --竞技场
}

