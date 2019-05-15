--日程相关常量

--日程活动记录数据的索引
gtDailyData = 
{
    eActType = 1,                   --活动类型
    eActID = 2,                     --活动ID
    eCountComp = 3,                 --今天完成有限奖励次数
    enActValue = 4,                 --今天该活动的活跃值
    ebCanJoin = 5,                  --今天能否参加
    eIsComp = 6,                    --今天是否已经完成该活动
    eIsEnd = 7,                     --活动时间是否接受
    eIsClick = 8,                   --是否已经点击查看
    eIsCanJoin = 9,                 --今日是否已参加
}

gtDailyOpera = 
{
    eAllActInfoReq = 1,                 --所有活动信息请求
    eOneDayActListReq = 2,              --某天活动列表请求
    eJoinAct = 3,                       --参加某个活动
    eGetDailyActReward = 4,             --领取活跃奖励
    eClick = 5,                         --点击活动
}

--开启类型
gtDailyActOpenType = 
{
    eNoOneCond = 1,                     --无限制
    eServerLevel = 2,                   --服务器等级
}


--必须跟配置里ID, BattleDupDef.lua玩法对应统一
gtDailyID = 
{
    --日常活动1开头
    eZhenYao = 101,                     --镇妖副本
    eLuanShiYaoMo = 102,                --乱世妖魔
    eXinMoQinShi = 103,                 --心魔侵蚀
    eShiMenTask = 104,                  --师门任务
    eShenShouLeYuan = 105,              --神兽乐园
    eArena = 106,                       --竞技场
    eBaoTu = 107,                       --宝图任务
    eShangJinTask = 108,                --赏金任务
    eShiLianTask = 109,                 --试炼任务
	eShenMoZhi = 110,                   --神魔志
    eKeJu = 111,                        --日常答题1
    eKeJu2 = 112,                       --日常答题2
    eKeJu3 = 113,                       --科举
    eBaHuangHuoZhen = 114,              --八荒火阵
    eYaoShouTuXi = 116,                 --妖兽突袭

    --限时活动2开头
    ePVEActivityMgr = 200,               --大厅
    eJueZhanJiuXiao = 201,              --决战九霄
    eHunDunShiLian = 202,               --混沌试炼
    eMengZhuWuShuang = 203,             --梦诛无双

    --PVP活动
    eSchoolArena = 1001,                --首席争霸
    eQimaiArena = 1002,                 --七脉会武
    eQingyunBattle = 1003,              --青云之战
    eUnionArena = 1004,                 --帮战
}