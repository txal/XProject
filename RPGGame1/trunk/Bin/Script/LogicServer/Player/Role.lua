--角色对象
local table, string, math, os, pairs, ipairs, assert = table, string, math, os, pairs, ipairs, assert

--改名许可证道具
local nModNameProp = 10011
function CRole:Ctor(nServer, nRoleID, nMirrorID, tSaveData)
    ------不保存------
    self.m_bDirty = false
    self.m_nSaveTimer = nil
    self.m_nServer = nServer

    self.m_nSession = 0             --网络句柄
    self.m_nGateway = 0             --网关ID
    self.m_nBattleID = 0            --战斗ID
    self.m_bBattleOffline = false   --战斗后释放角色对象
    self.m_tCurrMsgCache = {}       --货币同步消息

    ------保存--------
    self.m_bCreate = false  --是否新创建的角色
    self.m_nSource = 0
    self.m_nAccountID = 0
    self.m_sAccountName = 0

    self.m_nID = nRoleID
    self.m_nConfID = 0
    self.m_nCreateTime = os.time()
    self.m_nOnlineTime = 0
    self.m_nOfflineTime = 0

    self.m_sName = ""           --名字
    self.m_nLevel = 0           --初始0级
    self.m_tLastDup = {0, 0, 0, 0} --副本唯一ID,坐标X,坐标Y,方向
    self.m_tCurrDup = {0, 0, 0, 0} --副本唯一ID,坐标x,坐标y,方向
    self.m_nVIP = 0                 --VIP等级
    self.m_bStuckLevel = false      --是否卡等级
    self.m_nServerLv = goServerMgr:GetServerLevel(nServer)

    --人物基础属性
    self.m_nExp = 0         --经验
    self.m_nVitality = 0    --活力
    self.m_nStoreExp = 0    --储备经验

    self.m_nYuanBao = 0     --元宝
    self.m_nBYuanBao = 0    --绑定元宝
    self.m_nJinBi = 0       --金币
    self.m_nYinBi = 0       --银币
    self.m_nPower = 0       --角色战斗力
    self.m_nColligatePower = 0  --综合战力
    self.m_nChivalry = 0    --侠义值
    self.m_nJinDing = 0     --金锭
    self.m_nArenaCoin = 0   --竞技币
    self.m_nFuYuan = 0      --福缘值
    self.m_nLanZuan = 0     --蓝钻
    self.m_oToday = CToday:new(0)   --每日相关

    --战斗属性
    self.m_tBaseAttr = {0, 0, 0, 0, 0}          --基本属性(体质,魔力,力量,耐力,敏捷)
    self.m_tBattleAttr = {}                     --结果属性,高级属性,隐藏属性 
    for _, v in pairs(gtBAT) do self.m_tBattleAttr[v] = 0 end
    self.m_nCurrHP = 0   --当前气血
    self.m_nCurrMP = 0   --当前魔法
    self.m_bAutoBattle = false

    self.m_tHouseBattleAttr = {}                --家园增加属性
    --队伍
    self.m_nTeamID = 0
    self.m_bLeader = false
    self.m_bTeamLeave = false
    self.m_nTeamIndex = 0
    self.m_nTeamNum = 0
    self.m_tTeamList = {} --{nRoleID:{nRoleID =, bLeave =, nServer =, }, ...}

    --联盟
    self.m_nUnionID = 0
    self.m_nUnionJoinTime = 0

    --自动战斗默认指令和技能
    self.m_nAutoInst = 0
    self.m_nAutoSkill = 0
    self.m_nManualSkill = 0
    self.m_nBattleCount = 0

    --其他需要保存数据集合
    self.m_tShenShouData = {0, 0}       --个人神兽乐园记录数据{[tChallengeType] = 挑战次数}

    --限时活动数据
    self.m_tPVEActData = {}              --决战九霄,混沌试炼{[nActID]} = {}

    --角色动作状态(叫事件状态更合理点)
    self.m_nActState = gtRoleActState.eNormal  --玩家动作状态，不支持跨逻辑服，上下线，自动还原

    --角色当前动作行为
    self.m_nActID = 0           --当前的动作行为，不存DB，上下线，切换逻辑服，都会还原
    self.m_nActStamp = 0
    self.m_nActTimer = nil      --动作定时器

    --邀请者角色ID
    self.m_nInviteRoleID  = 0 

    --人物经验心得已次数和时间
    self.m_nRoleExpProps = 0
    self.m_nRoleExpPropTime = 0

    --测试属性
    self.m_nTestMan = 0
    self.m_tTargetActData = {nFlag = gtRoleTarActFlag.eNormal, }


    ------其他--------
    self.m_tModuleMap = {}  --映射
    self.m_tModuleList = {} --有序
    tSaveData = tSaveData or {}
    self:LoadSelfData(tSaveData.tSelfSaveData) --这里先加载角色数据,子模块可能要用到角色数据
    self:CreateModules()
    self:LoadModuleData(tSaveData.tModuleSaveData)

    self.m_nSrcID = self.m_nID
    if nMirrorID and nMirrorID > 0 then --机器人
        self.m_nID = nMirrorID
    end

    -----Native-------
    self.m_oNativeObj = goNativePlayerMgr:CreateRole(self.m_nID, self.m_nConfID, self.m_sName, self.m_nServer, self.m_nSession)
    assert(self.m_oNativeObj, "创建C++对象失败")

end

--发送PROTO消息封装
function CRole:SendMsg(sCmd, tMsg, nServer, nSession)
    nServer = nServer or self:GetServer()
    nSession = nSession or self:GetSession()
    assert(nServer < gnWorldServerID, "服务器ID错了")
    if nServer > 0 and nSession > 0 then
        Network.PBSrv2Clt(sCmd, nServer, nSession, tMsg)
    end
end

function CRole:CleanRoleTimer()
    if self.m_nSaveTimer and self.m_nSaveTimer > 0 then
        GetGModule("TimerMgr"):Clear(self.m_nSaveTimer)
    end
    self.m_nSaveTimer = nil

    if self.m_nActTimer and self.m_nActTimer > 0 then 
        GetGModule("TimerMgr"):Clear(self.m_nActTimer)
    end
    self.m_nActTimer = nil
end

--竞技场创建的临时角色释放
function CRole:OnTempObjRelease()
    self:CleanRoleTimer()

    for nModuleID, oModule in pairs(self.m_tModuleMap) do
        oModule:Release()
    end
end

--释放角色对象
function CRole:Release()
    self:CleanRoleTimer()
    self:ResetActState(false)
    --离开场景
    self:LeaveScene()
    --模块调用
    for nModuleID, oModule in pairs(self.m_tModuleMap) do
        oModule:Release()
    end
    --保存下数据
    self:SaveData()

    goRoleTimeExpiryMgr:OnRoleLeaveLogic(self)
    --清理CPP对象
    self.m_oNativeObj = nil
    goNativePlayerMgr:RemoveRole(self:GetID())
end

--创建注册各个子模块
function CRole:CreateModules()
    self.m_oVIP = CVIP:new(self)
    self.m_oKnapsack = CKnapsack:new(self)
    self.m_oSpouse = CSpouse:new(self)
    self.m_oSkill = CSkill:new(self)
    self.m_oPet = CPet:new(self)
  --  self.m_oShop = CShop:new(self)
    self.m_oFormation = CFormation:new(self)
    self.m_oRoleWash = CRoleWash:new(self)
    self.m_oSysOpen = CSysOpen:new(self)
    self.m_oPractice = CPractice:new(self)
    self.m_oTaskSystem = CTaskSystem:new(self)
    self.m_oPartner = CPartner:new(self)
    self.m_oShiMenTask = CShiMenTask:new(self)
    self.m_oDailyActivity = CDailyActivity:new(self)
    self.m_oGuaJi = CGuaJi:new(self)
    self.m_oAssistedSkill = CAssistedSkill:new(self)
    self.m_oShiZhuang = CShiZhuang:new(self)
    self.m_oBaoTu = CBaoTu:new(self)
    self.m_oFaBao = CFaBao:new(self)
    self.m_oLeiDeng = CLeiDeng:new(self)
    self.m_oQianDao = CQianDao:new(self)
    self.m_oFund = CFund:new(self)
    self.m_oShangJinTask = CShangJinTask:new(self)
    self.m_oMonthCard = CMonthCard:new(self)
    self.m_oUpgradeBag = CUpgradeBag:new(self)
    self.m_oYaoShouTuXi = CYaoShouTuXi:new(self)
    self.m_oAchieve = CAchieve:new(self)
    self.m_oOfflineData = COfflineData:new(self)
    self.m_oShiLianTask = CShiLianTask:new(self)
    self.m_oShenMoZhiData = CShenMoZhiData:new(self)
    self.m_oTimeData = CTime:new(self)
    self.m_oFindAward = CFindAward:new(self)
    self.m_oWDDownload = CWDDownload:new(self)
    self.m_oWGCY = CWGCY:new(self)
    self.m_oRoleState = CRoleState:new(self)
    self.m_oKeju = CKeJu:new(self)
    --self.m_oShuangBei = CShuangBei:new(self)
    self.m_oDrawSpirit = CDrawSpirit:new(self)
    self.m_oArtifact = CArtifact:new(self)
    self.m_oTargetTask = CTargetTask:new(self)
    self.m_oAppellation = CAppellationBox:new(self)
    self.m_oBaHuangHuoZhen = CBaHuangHuoZhen:new(self)
    self.m_oMentorship = CMentorshipModule:new(self)
    self.m_oBrother = CBrotherModule:new(self)
    self.m_oLover = CLoverModule:new(self)
    --self.m_oHolidayActMgr = CHolidayActivityMgr:new(self)
    self.m_oGuide = CPlayerGuide:new(self)
    self.m_oPayPush = CPayPush:new(self)
    self.m_oWillOpen = CWillOpen:new(self)
    self.m_oBattleCommand = CBattleCommand:new(self)
    self.m_oEverydayGift = CEverydayGift:new(self)
    self.m_oGuideTask = CGuideTask:new(self)
    self.m_oShenShouLeYuanModule = CShenShouLeYuanModule:new(self)
    self.m_oHoneyRelationship = CHoneyRelationship:new(self)



    self:RegisterModule(self.m_oVIP)
    self:RegisterModule(self.m_oKnapsack)
    self:RegisterModule(self.m_oSpouse)
    self:RegisterModule(self.m_oSkill)
    self:RegisterModule(self.m_oPet)
    --self:RegisterModule(self.m_oShop)
    self:RegisterModule(self.m_oFormation)
    self:RegisterModule(self.m_oRoleWash)
    self:RegisterModule(self.m_oSysOpen)
    self:RegisterModule(self.m_oPractice)
    self:RegisterModule(self.m_oTaskSystem)
    self:RegisterModule(self.m_oPartner)
    self:RegisterModule(self.m_oShiMenTask)
    self:RegisterModule(self.m_oDailyActivity)
    self:RegisterModule(self.m_oGuaJi)
    self:RegisterModule(self.m_oAssistedSkill)
    self:RegisterModule(self.m_oShiZhuang)
    self:RegisterModule(self.m_oBaoTu)
    self:RegisterModule(self.m_oFaBao)
    self:RegisterModule(self.m_oLeiDeng)
    self:RegisterModule(self.m_oQianDao)
    self:RegisterModule(self.m_oFund)
    self:RegisterModule(self.m_oShangJinTask)
    self:RegisterModule(self.m_oMonthCard)
    self:RegisterModule(self.m_oUpgradeBag)
    self:RegisterModule(self.m_oYaoShouTuXi)
    self:RegisterModule(self.m_oAchieve)
    self:RegisterModule(self.m_oOfflineData)
    self:RegisterModule(self.m_oShiLianTask)
    self:RegisterModule(self.m_oShenMoZhiData)
    self:RegisterModule(self.m_oTimeData)
    self:RegisterModule(self.m_oFindAward)
    self:RegisterModule(self.m_oWDDownload)
    self:RegisterModule(self.m_oWGCY)
    self:RegisterModule(self.m_oRoleState)
    self:RegisterModule(self.m_oKeju)
    --self:RegisterModule(self.m_oShuangBei)
    self:RegisterModule(self.m_oDrawSpirit)
    self:RegisterModule(self.m_oArtifact)
    self:RegisterModule(self.m_oTargetTask)
    self:RegisterModule(self.m_oAppellation)
    self:RegisterModule(self.m_oBaHuangHuoZhen)
    self:RegisterModule(self.m_oMentorship)
    self:RegisterModule(self.m_oBrother)
    self:RegisterModule(self.m_oLover)
    --self:RegisterModule(self.m_oHolidayActMgr)    
    self:RegisterModule(self.m_oGuide)
    self:RegisterModule(self.m_oPayPush)
    self:RegisterModule(self.m_oWillOpen)
    self:RegisterModule(self.m_oBattleCommand)
    self:RegisterModule(self.m_oEverydayGift)
    self:RegisterModule(self.m_oGuideTask)
    self:RegisterModule(self.m_oShenShouLeYuanModule)
    self:RegisterModule(self.m_oHoneyRelationship)
     
end

function CRole:RegisterModule(oModule)
	local nModuleID = oModule:GetType()
	assert(not self.m_tModuleMap[nModuleID], "重复注册模块:"..nModuleID)
	self.m_tModuleMap[nModuleID] = oModule
    table.insert(self.m_tModuleList, oModule)
end

function CRole:OnSaveTimer()
    self.m_oAppellation:CheckExpired()
    self:SaveData()
end

--注册自动保存
function CRole:RegAutoSave()
    GetGModule("TimerMgr"):Clear(self.m_nSaveTimer)
    self.m_nSaveTimer = GetGModule("TimerMgr"):Interval(gtGDef.tConst.nAutoSaveTime, 
    function(nTimerID)
        if self:IsRobot() then --加个检查，防止关服定时器错误
            --如果不在管理器中，将定时器都清理掉
            --正常，都是因为，创建角色失败导致的
            if not goLRobotMgr:FindRobot(self:GetID()) then 
                self:CleanRoleTimer()
                return
            end
        end
        self:OnSaveTimer() 
    end)
end

function CRole:InitSelfData(tData)
    self.m_bCreate = tData.m_bCreate or false
    self.m_nSource = tData.m_nSource or 0
    self.m_nAccountID = tData.m_nAccountID or 0
    self.m_sAccountName = tData.m_sAccountName or ""

    self.m_nOnlineTime = tData.m_nOnlineTime or self.m_nOnlineTime
    self.m_nOfflineTime = tData.m_nOfflineTime or self.m_nOfflineTime
    self.m_nCreateTime = tData.m_nCreateTime or self.m_nCreateTime

    self.m_nID = tData.m_nID
    self.m_nConfID = tData.m_nConfID or 1
    self.m_sName = tData.m_sName
    self.m_nLevel = tData.m_nLevel
    self.m_tLastDup = tData.m_tLastDup
    self.m_tCurrDup = tData.m_tCurrDup

    self.m_nVIP = math.min(#ctVIPConf, tData.m_nVIP or self.m_nVIP)
    self.m_bStuckLevel = tData.m_bStuckLevel or self.m_bStuckLevel

    self.m_nVitality = tData.m_nVitality or self.m_nVitality
    self.m_nExp = tData.m_nExp or self.m_nExp
    self.m_nStoreExp = math.floor(tData.m_nStoreExp or self.m_nStoreExp)

    self.m_nYuanBao = tData.m_nYuanBao or self.m_nYuanBao
    self.m_nBYuanBao = tData.m_nBYuanBao or 0
    self.m_nJinBi = tData.m_nJinBi or self.m_nJinBi
    self.m_nYinBi = tData.m_nYinBi or self.m_nYinBi
    self.m_nPower = tData.m_nPower or self.m_nPower
    self.m_nColligatePower = tData.m_nColligatePower or self.m_nColligatePower
    self.m_nChivalry = tData.m_nChivalry or self.m_nChivalry
    self.m_nJinDing = tData.m_nJinDing or self.m_nJinDing
    self.m_nFuYuan = tData.m_nFuYuan or self.m_nFuYuan
    self.m_nArenaCoin = tData.m_nArenaCoin or 0
    self.m_nLanZuan = tData.m_nLanZuan or self.m_nLanZuan

    self.m_tBaseAttr = tData.m_tBaseAttr or self.m_tBaseAttr
    self.m_tBattleAttr = tData.m_tBattleAttr or self.m_tBattleAttr
    self.m_nCurrHP = tData.m_nCurrHP or 0
    self.m_nCurrMP = tData.m_nCurrMP or 0
    self.m_bAutoBattle = tData.m_bAutoBattle or self.m_bAutoBattle

    self.m_nTeamID = tData.m_nTeamID or 0
    self.m_bLeader = tData.m_bLeader or false
    self.m_bTeamLeave = tData.m_bTeamLeave or false
    self.m_nTeamIndex =tData.m_nTeamIndex or 0
    self.m_nTeamNum = tData.m_nTeamNum 
    if not self.m_nTeamNum then 
        if self.m_nTeamID > 0 then 
            self.m_nTeamNum = 1
        else
            self.m_nTeamNum = 0
        end
    end
    self.m_tTeamList = tData.m_tTeamList or self.m_tTeamList

    self.m_nUnionID = tData.m_nUnionID or 0
    self.m_nUnionJoinTime = tData.m_nUnionJoinTime or 0

    self.m_nAutoInst = tData.m_nAutoInst or self.m_nAutoInst
    self.m_nAutoSkill = tData.m_nAutoSkill or self.m_nAutoSkill
    self.m_nManualSkill = tData.m_nManualSkill or 0
    self.m_nBattleCount = tData.m_nBattleCount or 0
    self.m_nInviteRoleID = tData.m_nInviteRoleID or 0
    self.m_nRoleExpProps = tData.m_nRoleExpProps or 0
    self.m_nRoleExpPropTime = tData.m_nRoleExpPropTime or 0

    self.m_tShenShouData = tData.m_tShenShouData or self.m_tShenShouData
    self.m_tHouseBattleAttr = tData.m_tHouseBattleAttr or self.m_tHouseBattleAttr   
    self.m_tPVEActData = tData.m_tPVEActData or self.m_tPVEActData
    self.m_nServerLv = tData.m_nServerLv or self.m_nServerLv
    self.m_tTargetActData = tData.m_tTargetActData or self.m_tTargetActData
    self.m_oToday:LoadData(tData.m_tTodayData or {})
end

--加载角色数据
function CRole:LoadSelfData(tSaveData)
    if not tSaveData then 
        local nServer, nID = self:GetServer(), self:GetID()
        local sData = goDBMgr:GetGameDB(nServer, "user", nID):HGet(gtDBDef.sRoleDB, nID)
        assert(sData ~= "", "角色不存在!!! : "..nID)

        local tData = cseri.decode(sData) 
        self:InitSelfData(tData)
    else
        self:InitSelfData(tSaveData)
    end
end

function CRole:GetSelfSaveData() 
    local tData = {}

    tData.m_nSource = self.m_nSource
    tData.m_nAccountID = self.m_nAccountID
    tData.m_sAccountName = self.m_sAccountName

    tData.m_nOnlineTime = self.m_nOnlineTime
    tData.m_nOfflineTime = self.m_nOfflineTime
    tData.m_nCreateTime = self.m_nCreateTime

    tData.m_nID = self.m_nID
    tData.m_nConfID = self.m_nConfID
    tData.m_sName = self.m_sName
    tData.m_nLevel = self.m_nLevel
    tData.m_tLastDup = self.m_tLastDup
    tData.m_tCurrDup = self.m_tCurrDup
    tData.m_nVIP = self.m_nVIP
    tData.m_bStuckLevel = self.m_bStuckLevel

    tData.m_nVitality = self.m_nVitality
    tData.m_nExp = self.m_nExp
    tData.m_nStoreExp = self.m_nStoreExp

    tData.m_nYuanBao = self.m_nYuanBao
    tData.m_nBYuanBao = self.m_nBYuanBao
    tData.m_nJinBi = self.m_nJinBi
    tData.m_nYinBi = self.m_nYinBi
    tData.m_nPower = self.m_nPower
    tData.m_nColligatePower = self.m_nColligatePower
    tData.m_nChivalry = self.m_nChivalry
    tData.m_nFuYuan = self.m_nFuYuan
    tData.m_nArenaCoin = self.m_nArenaCoin
    tData.m_nLanZuan = self.m_nLanZuan
    tData.m_nJinDing = self.m_nJinDing

    tData.m_tBaseAttr = self.m_tBaseAttr
    tData.m_tBattleAttr = self.m_tBattleAttr
    tData.m_nCurrHP = self.m_nCurrHP
    tData.m_nCurrMP = self.m_nCurrMP
    tData.m_bAutoBattle = self.m_bAutoBattle

    tData.m_nTeamID = self.m_nTeamID
    tData.m_bLeader = self.m_bLeader
    tData.m_bTeamLeave = self.m_bTeamLeave
    tData.m_nTeamIndex = self.m_nTeamIndex
    tData.m_nTeamNum = self.m_nTeamNum
    tData.m_tTeamList = self.m_tTeamList

    tData.m_nUnionID = self.m_nUnionID
    tData.m_nUnionJoinTime = self.m_nUnionJoinTime

    tData.m_nAutoInst = self.m_nAutoInst
    tData.m_nAutoSkill = self.m_nAutoSkill
    tData.m_nManualSkill = self.m_nManualSkill
    tData.m_nBattleCount = self.m_nBattleCount

    tData.m_tShenShouData = self.m_tShenShouData
    tData.m_tPVEActData = self.m_tPVEActData
    tData.m_nInviteRoleID = self.m_nInviteRoleID
    tData.m_nRoleExpProps = self.m_nRoleExpProps
    tData.m_nRoleExpPropTime = self.m_nRoleExpPropTime
    tData.m_tHouseBattleAttr = self.m_tHouseBattleAttr
    tData.m_nServerLv = self.m_nServerLv
    tData.m_tTargetActData = self.m_tTargetActData
    tData.m_tTodayData = self.m_oToday and self.m_oToday:SaveData() or {}
    return tData
end

--保存角色数据
function CRole:SaveSelfData()
    if not self:IsDirty() and not gbDebug then
        return
    end
    local tData = self:GetSelfSaveData()
    self:CheckDirtySave("role", self:IsDirty(), tData)
    if self:IsDirty() then
        goDBMgr:GetGameDB(self:GetServer(), "user", self:GetID()):HSet(gtDBDef.sRoleDB, self:GetID(), cseri.encode(tData))
        self:MarkDirty(false)
    end
end

--加载子模块数据
function CRole:LoadModuleData(tSaveData)
    if not tSaveData then 
        for nModuleID, oModule in pairs(self.m_tModuleMap) do
            local _, sModuleName = oModule:GetType()
            local nServer, nID = self:GetServer(), self:GetID()
            local sData = goDBMgr:GetGameDB(nServer, "user", nID):HGet(sModuleName, nID)
            if sData ~= "" then
                oModule:LoadData(cseri.decode(sData))
            else
                oModule:LoadData()
            end
        end
    else
        for nModuleID, oModule in pairs(self.m_tModuleMap) do
            local _, sModuleName = oModule:GetType()
            local tData = tSaveData[sModuleName]
            oModule:LoadData(tData)
        end
    end
    self:OnLoaded()
end

--保存子模块数据
function CRole:SaveModuleData()
    local nServer = self:GetServer()
    local nID = self:GetID()
    for nModuleID, oModule in pairs(self.m_tModuleMap) do
        local tData = oModule:SaveData()
        local _, sModuleName = oModule:GetType()
        if tData and next(tData) then
            local sData = cseri.encode(tData)
            local bRes = pcall(function() goDBMgr:GetGameDB(nServer, "user", nID):HSet(sModuleName, nID, sData) end) 
            if not bRes then
                oModule:MarkDirty(true)
            end
            self:CheckDirtySave(sModuleName, true, tData)
            print("save module:", sModuleName, "len:", string.len(sData))

        elseif not tData and gbDebug then
            oModule:MarkDirty(true)
            tData = oModule:SaveData()
            self:CheckDirtySave(sModuleName, false, tData)

        end
    end
end

function CRole:GetModuleSaveData() 
    local tModuleData = {}
    for nModuleID, oModule in pairs(self.m_tModuleMap) do
        oModule:MarkDirty(true) --全部标脏，否则取出来的是空
        local tData = oModule:SaveData()
        local _, sModuleName = oModule:GetType()
        if tData and next(tData) then
            tModuleData[sModuleName] = tData
        end
    end
    return tModuleData
end

function CRole:GetRoleSaveData() 
    local tSaveData = {}
    tSaveData.tSelfSaveData = self:GetSelfSaveData()
    tSaveData.tModuleSaveData = self:GetModuleSaveData()
    return tSaveData
end

--保存所有数据
function CRole:SaveData()
    local nBegClock = os.clock()
    self:SaveSelfData()
    self:SaveModuleData()
    local nCostTime = os.clock() - nBegClock
    if nCostTime >= 0.05 then
        LuaTrace("------save------", self:GetID(), self:GetName(), "time:", string.format("%.4f", nCostTime), nBegClock, os.clock())
    else
        print("------save------", self:GetID(), self:GetName(), "time:", string.format("%.4f", nCostTime), nBegClock, os.clock())
    end
end

function CRole:AddInitEqu()
    --基础0级装备1套
    local tConf = self:GetConf()
    for _, nID in ipairs(tConf.tBornEquipment[1]) do
        if nID > 0 then
            self:AddItem(gtItemType.eProp, nID, 1, "创建角色", false, false, {nFrom=0})
            local oProp = self.m_oKnapsack:GetItemByPropID(nID)
            self.m_oKnapsack:WearEquReq(oProp:GetGrid())
        end
    end
end

--加载所有数据完成
function CRole:OnLoaded()
    --新角色
    if self.m_bCreate then
        --初始活力
        self.m_nVitality = 20
        --基础主属性
        self.m_tBaseAttr = {10, 10, 10, 10, 10}
        --身上携带1元价值的铜币，1元的算法为(SLV*25+4000)*10 //SLV为服务器等级
        self.m_nYinBi = (goServerMgr:GetServerLevel(self:GetServer())*25+4000)*10
        --携带道具：改名许可证
        self:AddItem(gtItemType.eProp, nModNameProp, 1, "创建角色")
        self:AddInitEqu()
        self.m_bCreate = false
        self:MarkDirty(true)
    end

    local nLastDupMixID = self:GetLastDupMixID() 
    local nLastDupConfID = CUtil:GetDupID(nLastDupMixID)
    if nLastDupMixID == 0 or not ctDupConf[nLastDupConfID] or ctDupConf[nLastDupConfID].nType ~= CDupBase.tType.eCity then
        local tRoleConf = self:GetConf()
        local tDupConf = ctDupConf[tRoleConf.nInitDup]
        self.m_tLastDup = {tRoleConf.nInitDup, tRoleConf.tBorn[1][1], tRoleConf.tBorn[1][2], tDupConf.nFace}
        self:MarkDirty(true)
    end

    local nCurDupMixID = self:GetCurrDupMixID()
    local nDupConfID = CUtil:GetDupID(nCurDupMixID)
    local tDupConf = ctDupConf[nDupConfID]
    if not tDupConf then 
        self.m_tCurrDup = table.DeepCopy(self.m_tLastDup)
        self:MarkDirty(true)
    end
    --更新结果属性
    self:UpdateAttr()
    self:RegAutoSave() --所有流程都正常执行完，再注册自动保存定时器
end

function CRole:IsDirty() return self.m_bDirty end
function CRole:MarkDirty(bDirty) self.m_bDirty = bDirty end

function CRole:GetID() return self.m_nID end
function CRole:GetSrcID() return self.m_nSrcID end
function CRole:GetConf() return ctRoleInitConf[self.m_nConfID] end
function CRole:GetConfID() return self.m_nConfID end
function CRole:GetObjType() return gtGDef.tObjType.eRole end
function CRole:GetName() return self.m_sName end
function CRole:GetFormattedName()
    local tConf = ctTalkConf["rolename"]
    if not tConf then return end
    return string.format(tConf.sContent, self.m_sName)
end
function CRole:GetGender() return self:GetConf().nGender end
function CRole:GetSchool() return self:GetConf().nSchool end
function CRole:GetModel() return self:GetConf().sModel end
function CRole:GetLevel() return self.m_nLevel end
function CRole:GetServer() return self.m_nServer end --角色所属服务器ID
function CRole:GetStayServer() --角色当前所在服务器ID
    local nLogic = self:GetLogic()
    return ((nLogic>=100) and gnWorldServerID or self:GetServer())
end
function CRole:GetMixObjID() return gtGDef.tObjType.eRole<<32|self.m_nID end
function CRole:GetSession() return self.m_nSession end
function CRole:GetGateway() return self.m_nGateway end
function CRole:GetSource() return self.m_nSource end
function CRole:IsAndroid() return self.m_nSource // 100 == 1 end
function CRole:IsIOS() return self.m_nSource // 100 == 2 end
function CRole:GetAccountID() return self.m_nAccountID end
function CRole:GetAccountName() return self.m_sAccountName end
function CRole:GetVIP() return self.m_nVIP end
function CRole:GetCreateTime() return self.m_nCreateTime end
function CRole:GetOnlineTime() return self.m_nOnlineTime end
function CRole:GetOfflineTime() return self.m_nOfflineTime end
function CRole:GetLogic()return GlobalExport.GetServiceID() end --当前逻辑服ID
function CRole:GetAOIID() return self.m_oNativeObj and self.m_oNativeObj:GetAOIID() or 0 end --AOI编号
function CRole:GetPos() return self.m_oNativeObj:GetPos() end --当前坐标
--@nFace 可选: 不填就是当前方向; 否则填gtFaceType里面的方向
function CRole:SetPos(nPosX, nPosY, nFace) self.m_oNativeObj:SetPos(nPosX, nPosY, nFace) end --设置坐标(瞬移)
function CRole:GetSpeed() return self.m_oNativeObj:GetRunSpeed() end --X,Y轴速度
function CRole:GetTarPos() return self.m_oNativeObj:GetTarPos() end --如果跑动中,目标点坐标
function CRole:StopRun() self.m_oNativeObj:StopRun() end --停止移动
function CRole:RunTo(nPosX, nPosY, nSpeed) self.m_oNativeObj:RunTo(nPosX, nPosY, nSpeed) end --以nSpeed(像素/秒)速度跑动到目标点
function CRole:GetDupMixID() return self.m_oNativeObj:GetDupMixID() end --副本唯一ID
function CRole:GetDupID() return CUtil:GetDupID(self:GetDupMixID()) end --副本配置ID
function CRole:GetDupConf() return ctDupConf[self:GetDupID()] end --副本配置
function CRole:GetNativeObj() return self.m_oNativeObj end --C++对象
function CRole:IsOnline(nSession) return self.m_nSession>0 end
function CRole:IsReleasedd() return self.m_oNativeObj == nil end 

function CRole:IsInBattle() return self.m_nBattleID>0 end
function CRole:GetBattleID() return self.m_nBattleID end
function CRole:SetBattleID(nBattleID) self.m_nBattleID = nBattleID end
function CRole:IsBattleOffline() return self.m_bBattleOffline end --是否战斗后释放角色对象
function CRole:SetBattleOffline(bVal) self.m_bBattleOffline=bVal end --设置战斗后释放对象

function CRole:IsStuckLevel() return self.m_bStuckLevel end
function CRole:GetCurrDup() return self.m_tCurrDup end
function CRole:GetCurrDupMixID() return self.m_tCurrDup[1] end
function CRole:GetLastDup() return self.m_tLastDup end
function CRole:GetLastDupMixID() return self.m_tLastDup[1] end 
function CRole:GetCurrDupObj() return goDupMgr:GetDup(self.m_tCurrDup[1]) end
function CRole:GetLastDupObj() return goDupMgr:GetDup(self.m_tLastDup[1]) end
function CRole:GetPower() return self.m_nPower end
function CRole:GetColligatePower() return self.m_nColligatePower end
function CRole:GetGrade() --评级
    local nLevel = math.max(0, math.min(#ctRoleGradeConf, self:GetLevel()))
    local tConf = ctRoleGradeConf[nLevel]
    local nPower = self:GetPower()
    if nPower >= tConf["SS"] then
        return "SS"
    end
    if nPower >= tConf["S"] then
        return "S"
    end
    if nPower >= tConf["A"] then
        return "A"
    end
    if nPower >= tConf["B"] then
        return "B"
    end
    if nPower >= tConf["C"] then
        return "C"
    end
    return "D"
end
function CRole:GetFace() return self.m_oNativeObj:GetFace() end --角色当前面向
function CRole:GetLine() return self.m_oNativeObj:GetLine() end --当前线
function CRole:IsAutoBattle() return self.m_bAutoBattle end

function CRole:GetTeamID() return self.m_nTeamID end
function CRole:IsLeader() return self.m_bLeader end
function CRole:IsTeamLeave() return self.m_bTeamLeave end  --在队伍中，才是有效值
function CRole:GetTeamIndex() return self.m_nTeamIndex end
function CRole:GetTeamNum()
    if self:GetTeamID() > 0 then 
        return self.m_nTeamNum
    else
        return 0
    end
end
function CRole:GetTeamList() return self.m_tTeamList end

function CRole:CheckTeamOp()
    if self:GetTeamID() > 0 and not self:IsLeader() then 
        if not self:IsTeamLeave() then 
            return false
        end
    end
    return true
end

function CRole:GetUnionID() return self.m_nUnionID end
function CRole:GetUnionJoinTime() return self.m_nUnionJoinTime end

function CRole:GetFlyMountID() return self.m_oShiZhuang.m_nCurrFlyMountID end
function CRole:GetWingID() return self.m_oShiZhuang.m_nCurrWingID end
function CRole:GetHaloID() return self.m_oShiZhuang.m_nCurrHaloID end
function CRole:SetActState(nState, bBroadcast)
    local nOldActState = self.m_nActState
    self.m_nActState = nState
    if nOldActState ~= self.m_nActState then
        local tGlobalServiceList = goServerMgr:GetGlobalServiceList()
        for _, tConf in pairs(tGlobalServiceList) do
            if tConf.nServer == self:GetServer() or tConf.nServer == gnWorldServerID then
                Network:RMCall("GRoleActStateUpdateReq", nil, tConf.nServer, tConf.nID, self:GetSession(), self:GetID(), self.m_nActState)
            end
        end
        if bBroadcast then
            self:OnActStateChange(nOldActState)
        end
    end
end
function CRole:GetActState() return self.m_nActState end

function CRole:GetActID() return self.m_nActID end
function CRole:GetActTime() 
    local nCurTime = os.time()
    return math.abs(nCurTime - self.m_nActStamp)
end

function CRole:GetTarActFlag()
    return self.m_tTargetActData.nFlag, self.m_tTargetActData.tParam
end

function CRole:SetTarActFlag(nFlag, tParam)
    if not nFlag then 
        return
    end
    if self.m_tTargetActData.nFlag ~= nFlag then 
        self.m_tTargetActData.nFlag = nFlag
        if nFlag == gtRoleTarActFlag.eNormal then 
            self.m_tTargetActData.tParam = nil --如果是普通的, 强制置nil
        else
            self.m_tTargetActData.tParam = tParam
        end
        self:MarkDirty(true)
    end
end

-- bSync是否做场景同步刷新
function CRole:SetActID(nActID, bSync)
    assert(nActID and nActID >= 0)
    --查看动作是否在配置表中，防止错误数据
    local tActConf = ctEntityActConf[nActID]
    if nActID ~= 0 and not tActConf then --0动作，即默认动作，不需要配置
        return
    end
    self.m_nActID = nActID
    self.m_nActStamp = os.time()

    --删除旧的定时器，可能旧动作未到时间，就设置了新动作
    if self.m_nActTimer and self.m_nActTimer > 0 then 
        GetGModule("TimerMgr"):Clear(self.m_nActTimer)
    end
    self.m_nActTimer = nil

    if nActID > 0 and tActConf then --大于0，非默认行为，设置定时器，默认行为，不设置
        if tActConf.nActTime >= 1 then 
            self.m_nActTimer = GetGModule("TimerMgr"):Interval(tActConf.nActTime, function() self:OnActTimer() end)
        else --动作时间小于1的，忽略
            self.m_nActID = 0
        end
    end
    if bSync then 
        self:FlushRoleView()
    end
end

function CRole:OnActTimer()
    if self.m_nActTimer and self.m_nActTimer > 0 then 
        GetGModule("TimerMgr"):Clear(self.m_nActTimer)
    end
    self.m_nActTimer = nil
    -- local nActID = self:GetActID()
    -- self.m_nActID = 0 --先设置为默认动作0，防止处理失败，角色动作状态不对
    -- if nActID > 0 then 
    --     local tActConf = ctEntityActConf[nActID]
    --     if tActConf and tActConf.nNextAct > 0 then 
    --         self:SetActID(tActConf.nNextAct, true)
    --         return  --直接退出，其他情况，默认还原到默认动作
    --     end
    -- end
    self:SetActID(0, false)
end


function CRole:ResetActState(bBroadcast) self:SetActState(gtRoleActState.eNormal, bBroadcast) end

function CRole:GetWeapon() return self.m_oKnapsack:GetWeapon() end
function CRole:GetWeaponID() 
    local oWeapon = self:GetWeapon()
    return (oWeapon and oWeapon:GetID() or 0)
end

function CRole:GetArtifactID()
    local oArtifact = self.m_oArtifact:GetoArtifact()
    return (oArtifact and oArtifact:GetID() or 0)
end

function CRole:GetVIP() return self.m_nVIP end
function CRole:SetVIP(nVIP, sReason)
    self.m_nVIP = nVIP
    self:MarkDirty(true)
    self:SyncCurrency(gtCurrType.eVIP, self.m_nVIP)
    self.m_oVIP:OnVIPChange()

    self:GlobalRoleUpdate({m_nVIP=nVIP})
    goLogger:EventLog(gtEvent.eVIP, self, self.m_nVIP, sReason)
    goLogger:UpdateAccountLog(self, {vip=self.m_nVIP}) 
end

function CRole:GetBattleCount() return self.m_nBattleCount end

--获取角色对应的婚礼礼服模型
function CRole:GetWeddingSuitModel()
    return ctWeddingSuitConf[self.m_nConfID].sWeddingSuitModel
end

--绑定会话ID
function CRole:BindSession(nSession)
    self.m_nSession = nSession
    self.m_oNativeObj:BindSession(nSession)
    if self.m_nSession > 0 then
        self.m_nGateway = CUtil:GetGateBySession(self.m_nSession)
    end
end

--取角色身上的装备
function CRole:GetEquipment()
    local tEquipment = {}
    local tWearEqu = self.m_oKnapsack:GetWearEqu()
    for nPart, oEqu in pairs(tWearEqu) do
        table.insert(tEquipment, oEqu:GetID())
    end
    return tEquipment
end

--计算战力(评分)
function CRole:UpdatePower()
    local nOldPower = self.m_nPower
    local nPower = 225000+self:GetLevel()*1000
    nPower = nPower + self.m_oSkill:CalcSkillScore()
    nPower = nPower + self.m_oPractice:CalcPracticeScore()
    nPower = nPower + self.m_oKnapsack:CalcWearEquScore()
    nPower = nPower + self.m_oFaBao:CalcAttrScore()
    nPower = nPower + self.m_oArtifact:CalcAttrScore()
    nPower = nPower + self.m_oShiZhuang:CalcAttrScore()
    nPower = nPower + self.m_oAssistedSkill:CalcAttrScore()
    nPower = nPower + self.m_oDrawSpirit:CalcAttrScore()
    nPower = nPower + self:CalcHouseScore()
    nPower = nPower + self.m_oShiZhuang:GetYuQiScore()
    nPower = nPower + self.m_oShiZhuang:GetXianYuScore()
    nPower = nPower + self.m_oPet:GetYuShouScore()
    nPower = nPower + self.m_oPartner:GetXianzhenScore()
    nPower = nPower + self.m_oDrawSpirit:GetLianhunScore()
    nPower = nPower + self.m_oDrawSpirit:GetFazhenScore()
    nPower = nPower + self.m_oHoneyRelationship:GetQingyiScore()

    nPower = math.min(gtGDef.tConst.nMaxInteger, math.floor(nPower))
    if nOldPower ~= nPower then
        self.m_nPower = nPower
        self:MarkDirty(true)
        self:SendMsg("RolePowerSyncRet", {nPower=nPower, nDiffVal=self.m_nPower-nOldPower})
        self:OnPowerChange(self.m_nPower)
    end
end

--战力变化
function CRole:OnPowerChange(nPower)
    if self:IsTempRole() or self:IsRobot() then 
        return 
    end
    self:GlobalRoleUpdate({m_nPower=nPower})
    self.m_oAchieve:OnPowerChange(nPower,{nPower=nPower})
    CEventHandler:OnFightCapacityChange(self, {nPower=nPower})
    self:UpdateColligatePower()
    --日志
    goLogger:UpdateRoleLog(self, {power=self.m_nPower})
end

--设置基础属性
function CRole:SetBaseAttr(tBaseAttr)
    self.m_tBaseAttr = tBaseAttr
    self:MarkDirty(true)
end

--取主属性
function CRole:GetMainAttr(nType)
    local tMainAttr = {0, 0, 0, 0, 0}
    local tPotenAttr = self.m_oRoleWash:GetPotenPlan() --潜力点
    local tEquMainAttr = self.m_oKnapsack:GetEquMainAttr() --装备属性
    for k = 1, #self.m_tBaseAttr do
        tMainAttr[k] = tMainAttr[k] + self.m_tBaseAttr[k] + tPotenAttr[k] + (tEquMainAttr[k] or 0)
    end
    if nType then
        return tMainAttr[nType]
    end
    return tMainAttr
end

--取战斗属性
function CRole:GetBattleAttr(nType)
    if nType then
        return self.m_tBattleAttr[nType]
    end
    return self.m_tBattleAttr
end

--取结果属性
function CRole:GetResAttr()
    local tResAttr = {}
    for k=gtBAD.eMinRAT, gtBAD.eMaxRAT do
        tResAttr[k] = self.m_tBattleAttr[k]
    end
    return tResAttr
end

--角色成长属性配置预处理数据
local tGrowthAttrRatioConfCache = {} --{nRoleConfID:{nAttrID:nRatio, ...}, ..}
local tGrowthAttrTotalRatioCache = {}  --{nRoleConfID:nTotalRatio, ...}
for nRoleConfID, tConf in ipairs(ctRoleGrowthAttrRatioConf) do 
    local tTemp = {}
    local nTotal = 0
    for _, tAttr in pairs(tConf.tAttrRatio) do 
        if tAttr[1] > 0 then 
            nTotal = nTotal + tAttr[2]
            tTemp[tAttr[1]] = tAttr[2]
        end
    end
    tGrowthAttrRatioConfCache[nRoleConfID] = tTemp
    tGrowthAttrTotalRatioCache[nRoleConfID] = nTotal
end

--计算成长属性
function CRole:CalcGrowthAttr(nAttrID, nParam)
    local tCalcConf = ctRoleGrowthAttrCalcConf[nAttrID]
    if not tCalcConf then 
        return 0
    end
    -- local tRatioConf = ctRoleGrowthAttrRatioConf[self:GetConfID()]
    -- assert(tRatioConf, "配置错误")
    -- local nAttrRatio = 0
    -- local nTotalRatio = 0
    -- for _, tAttr in ipairs(tRatioConf.tAttrRatio) do 
    --     if tAttr[1] > 0 then 
    --         nTotalRatio = nTotalRatio + tAttr[2]
    --         if nAttrID == tAttr[1] then 
    --             nAttrRatio = tAttr[2]
    --         end
    --     end
    -- end

    local nRoleConfID = self:GetConfID()
    local nAttrRatio = tGrowthAttrRatioConfCache[nRoleConfID][nAttrID]
    local nTotalRatio = tGrowthAttrTotalRatioCache[nRoleConfID]
    assert(nTotalRatio > 0, "配置错误")

    return tCalcConf.fnProc(nParam, nAttrRatio, nTotalRatio)
end

function CRole:CalcModuleGrowthAttr(nParam)
    local tAttrList = {}
    for nAttrID, tConf in pairs(ctRoleGrowthAttrCalcConf) do 
        if nAttrID > 0 then 
            tAttrList[nAttrID] = self:CalcGrowthAttr(nAttrID, nParam)
        end
    end
    return tAttrList
end

--重新计算属性
function CRole:UpdateAttr()
    --主属性(基础+潜力点+装备)
    local tMainAttr = self:GetMainAttr()

    local bDebug = false

    --战斗属性
    local tOldBattleAttr = table.DeepCopy(self.m_tBattleAttr) 
    --重置战斗属性
    for _, v in pairs(gtBAT) do self.m_tBattleAttr[v] = 0 end

    --初始值
    self.m_tBattleAttr[gtBAT.eQX] = 200 --气血额外+200 
    self.m_tBattleAttr[gtBAT.eGJ] = 40  --攻击额外+40
    self.m_tBattleAttr[gtBAT.eMF] = self:GetLevel()*20+30 --魔法默认值根据等级计算

    ------结果属性根据主属性计算结果属性(气血,魔法,怒气,攻击,防御,灵力,速度),
    if bDebug then  print("主属性:", tMainAttr) end
    for k=1, #tMainAttr do
        local nMainAttr = tMainAttr[k]
        for _, tAttr in ipairs(ctRoleAttrConf[k].tAttr) do
            self.m_tBattleAttr[tAttr[1]] = self.m_tBattleAttr[tAttr[1]]+math.floor(tAttr[2]*nMainAttr)
        end
    end
    if bDebug then print("主属性计算结果属性:", self.m_tBattleAttr) end

    --门派被动技能属性加成
    local tBattleAttr = self.m_oSkill:GetBattleAttr()
    for k, v in pairs(tBattleAttr) do 
        if k > 100 then self.m_tBattleAttr[k] = self.m_tBattleAttr[k] + v end
    end
    if bDebug then print("门派被动技能加成后:", self.m_tBattleAttr) end

    --装备对战斗属性加成
    local tBattleAttr = self.m_oKnapsack:GetEquBattleAttr()
    for k, v in pairs(tBattleAttr) do
        if k > 100 then self.m_tBattleAttr[k] = self.m_tBattleAttr[k] + v end
    end
    if bDebug then print("装备加成后:", self.m_tBattleAttr) end

    --辅助技能加成
    local tBattleAttr = self.m_oAssistedSkill:GetBattleAttr()
    for k, v in pairs(tBattleAttr) do
        self.m_tBattleAttr[k] = self.m_tBattleAttr[k] + v
    end
    if bDebug then print("辅助技能加成后:", self.m_tBattleAttr) end

    --法宝属性加成
    local tBattleAttr = self.m_oFaBao:GetBattleAttr()
    for k, v in pairs(tBattleAttr) do
        self.m_tBattleAttr[k] = self.m_tBattleAttr[k] + v
    end
    if bDebug then print("法宝属性加成后", self.m_tBattleAttr) end
    
    --时装属性加成
    local tBattleAttr = self.m_oShiZhuang:GetBattleAttr()
    for k, v in pairs(tBattleAttr) do
        self.m_tBattleAttr[k] = self.m_tBattleAttr[k] + v
    end
    if bDebug then print("时装属性加成后", self.m_tBattleAttr) end

    --摄魂系统加成
    local tBattleAttr = self.m_oDrawSpirit:GetBattleAttr()
    for k, v in pairs(tBattleAttr) do 
        self.m_tBattleAttr[k] = self.m_tBattleAttr[k] + v
    end
    if bDebug then print("摄魂系统加成后", self.m_tBattleAttr) end

    --神器系统加成
      local tBattleAttr = self.m_oArtifact:GetBattleAttr()
    for k, v in pairs(tBattleAttr) do 
        self.m_tBattleAttr[k] = self.m_tBattleAttr[k] + v
    end
    if bDebug then print("神器系统加成后", self.m_tBattleAttr) end

    local tHouseBattleAttr = self:GetHouseBattleAttr()
    for k,v in pairs(tHouseBattleAttr) do
        self.m_tBattleAttr[k] = self.m_tBattleAttr[k] + v
    end
    if bDebug then print("家园属性加成后",self.m_tBattleAttr) end

    local tAppellationAttr = self.m_oAppellation:GetBattleAttr()
    for k, v in pairs(tAppellationAttr) do 
        self.m_tBattleAttr[k] = self.m_tBattleAttr[k] + v
    end
    if bDebug then print("称谓属性加成后", self.m_tBattleAttr) end

    local tYuQiAttr = self.m_oShiZhuang:GetYuQiAttr()
    for k, v in pairs(tYuQiAttr) do 
        self.m_tBattleAttr[k] = self.m_tBattleAttr[k] + v
    end
    if bDebug then print("时装御器属性加成后", self.m_tBattleAttr) end

    local tXianYuAttr = self.m_oShiZhuang:GetXianYuAttr()
    for k, v in pairs(tXianYuAttr) do 
        self.m_tBattleAttr[k] = self.m_tBattleAttr[k] + v
    end
    if bDebug then print("时装仙羽属性加成后", self.m_tBattleAttr) end

    local tYuShouAttr = self.m_oPet:GetYuShouAttr()
    for k, v in pairs(tYuShouAttr) do 
        self.m_tBattleAttr[k] = self.m_tBattleAttr[k] + v
    end
    if bDebug then print("宠物御兽属性加成后", self.m_tBattleAttr) end

    local tXianzhenAttr = self.m_oPartner:GetXianzhenAttr()
    for k, v in pairs(tXianzhenAttr) do 
        self.m_tBattleAttr[k] = self.m_tBattleAttr[k] + v
    end
    if bDebug then print("仙侣仙阵属性加成后", self.m_tBattleAttr) end

    local tTempAttr = self.m_oDrawSpirit:GetLianhunAttr()
    for k, v in pairs(tTempAttr) do 
        self.m_tBattleAttr[k] = self.m_tBattleAttr[k] + v
    end
    if bDebug then print("摄魂炼魂属性加成后", self.m_tBattleAttr) end

    local tTempAttr = self.m_oDrawSpirit:GetFazhenAttr()
    for k, v in pairs(tTempAttr) do 
        self.m_tBattleAttr[k] = self.m_tBattleAttr[k] + v
    end
    if bDebug then print("摄魂法阵属性加成后", self.m_tBattleAttr) end

    local tTempAttr = self.m_oHoneyRelationship:GetQingyiAttr()
    for k, v in pairs(tTempAttr) do 
        self.m_tBattleAttr[k] = self.m_tBattleAttr[k] + v
    end
    if bDebug then print("缘分情义属性加成后", self.m_tBattleAttr) end


    if self:IsRobot() then --机器人，属性系数修正
        local nRatio = ctRobotSysConf["sAttrRatio"].nParam / 100
        assert(nRatio >= 0)
        for k, v in pairs(self.m_tBattleAttr) do 
            self.m_tBattleAttr[k] = v * nRatio
        end
    end

    --属性变化同步
    local tAttrList = {}
    for k, v in pairs(self.m_tBattleAttr) do
        v = math.min(gtGDef.tConst.nMaxInteger, math.floor(v))
        self.m_tBattleAttr[k] = v
        
        local nDiff = v - (tOldBattleAttr[k] or 0)
        if nDiff ~= 0 then
            table.insert(tAttrList, {nAttrID=k, nAttrVal=v, nDiffVal=nDiff})
            self:MarkDirty(true)
        end
    end

    --没战斗过一直满血蓝
    --放在上面处理之后，否则会有浮点数
    if (self.m_nBattleCount or 0) == 0 then
        self.m_nCurrHP = self.m_tBattleAttr[gtBAT.eQX]
        self.m_nCurrMP = self.m_tBattleAttr[gtBAT.eMF]
    end
    
    if #tAttrList > 0 then
        self:SendMsg("RoleBattleAttrChangeRet", {tList=tAttrList})
    end

    --更新战力
    self:UpdatePower()
end

--同步角色初始数据
function CRole:SyncInitData()
    local tMsg = {}
    tMsg.nSource = self:GetSource()
    tMsg.nAccountID = self:GetAccountID()
    tMsg.sAccountName = self:GetAccountName()
    tMsg.nRoleID = self.m_nID
    tMsg.sRoleName = self.m_sName
    tMsg.nLevel = self.m_nLevel
    tMsg.nVIP = self:GetVIP()
    tMsg.nYuanBao = self:GetYuanBao()
    tMsg.nBYuanBao = self:GetBYuanBao()
    tMsg.nJinBi = self:GetJinBi() 
    tMsg.nYinBi = self:GetYinBi()
    tMsg.nVitality = self:GetVitality()
    tMsg.nExp = self:GetExp()
    tMsg.nStoreExp = self:GetStoreExp()
    tMsg.nPotential = self:GetPotential()
    tMsg.nBattleID = self:GetBattleID()
    tMsg.sModel = self:GetDisplayModel() --self:GetConf().sModel
    tMsg.nDir = self:GetCurrDup()[4] or 0
    tMsg.nJinDing = self:GetJinDing()
    tMsg.nGender = self:GetGender()
    tMsg.nFuYuan = self:GetFuYuan()
    tMsg.nServerID = self:GetServer()
    tMsg.nArenaCoin = self:GetArenaCoin() 
    tMsg.tShapeData = self:GetShapeData()
    tMsg.nMaxVitality = self:MaxVitality()
    tMsg.nLanZuan = self:GetLanZuan()
    tMsg.nCurrHP = self.m_nCurrHP
    tMsg.nMaxHP = self.m_tBattleAttr[gtBAT.eQX]
    tMsg.nCurrMP = self.m_nCurrMP
    tMsg.nMaxMP = self.m_tBattleAttr[gtBAT.eMF]
    tMsg.nPower = self:GetPower()
    tMsg.nCurrSP = 0
    tMsg.nMaxSP = self.m_tBattleAttr[gtBAT.eNQ]
    tMsg.nSchool = self:GetSchool()
    tMsg.nDrawSpirit = self:ItemCount(gtItemType.eCurr, gtCurrType.eDrawSpirit)
    tMsg.nMagicPill = self:ItemCount(gtItemType.eCurr, gtCurrType.eMagicPill)
    tMsg.nEvilCrystal = self:ItemCount(gtItemType.eCurr, gtCurrType.eEvilCrystal)
    tMsg.nServerLv = goServerMgr:GetServerLevel(self:GetServer())
    tMsg.nRoleConfID = self:GetConfID()
    tMsg.nColligatePower = self:GetColligatePower()
    tMsg.nChivalry = self:GetChivalry()
    self:SendMsg("RoleInitDataRet", tMsg)
end 

function CRole:GetGlobalOnlineData(bRelease)
    local tRole = {}
    tRole.m_bRelease=bRelease
    tRole.m_nOnlineTime=self:GetOnlineTime()
    tRole.m_nOfflineTime=self:GetOfflineTime()

    tRole.m_nServer = self:GetServer()
    tRole.m_nSession = self:GetSession()
    tRole.m_nGateway = self:GetGateway()
    tRole.m_nDupMixID = self:GetCurrDup()[1]

    tRole.m_nID = self:GetID()
    tRole.m_nSrcID = self:GetSrcID()
    tRole.m_sName = self:GetName()
    tRole.m_nConfID = self:GetConfID()
    tRole.m_nAccountID = self:GetAccountID()
    tRole.m_sAccountName = self:GetAccountName()
    tRole.m_nCreateTime = self:GetCreateTime()
    tRole.m_nLevel = self:GetLevel()
    tRole.m_nVIP = self:GetVIP()
    tRole.m_nInviteRoleID = self.m_nInviteRoleID
    tRole.m_tShapeData = self:GetShapeData()
    tRole.m_nSource = self:GetSource()
    tRole.m_tOpenSysMap = self.m_oSysOpen.m_tOpenSysMap

    return tRole
end

function CRole:GetGlobalOfflineData(bRelease)
    local tRole = {}
    tRole.m_bRelease=bRelease
    tRole.m_nOnlineTime=self:GetOnlineTime()
    tRole.m_nOfflineTime=self:GetOfflineTime()
    return tRole
end

--同步角色上下线到[W]GLOBAL
--bRelease: 对象是否已释放
function CRole:GlobalRoleOnline(bOnline, bRelease)
    bRelease = bRelease or false
    local tRole = nil
    local sFunc = nil
    if bOnline then
        sFunc = "GRoleOnlineReq"
        tRole = self:GetGlobalOnlineData(bRelease)
        --邀请只处理一次
        if self.m_nInviteRoleID > 0 then
            self.m_nInviteRoleID = 0
            self:MarkDirty(true)
        end
    else
        sFunc = "GRoleOfflineReq"
        tRole = self:GetGlobalOfflineData(bRelease)
    end

    --[W]GLOBAL
    local tGlobalServiceList = goServerMgr:GetGlobalServiceList()
    for _, tConf in pairs(tGlobalServiceList) do
        if tConf.nServer == self:GetServer() or tConf.nServer == gnWorldServerID then
            Network.oRemoteCall:Call(sFunc, tConf.nServer, tConf.nID, self:GetSession(), self:GetID(), tRole)
        end
    end
end

--更新角色信息到[W]GLOBAL
function CRole:GlobalRoleUpdate(tParam)
    --[W]GLOBAL
    local tGlobalServiceList = goServerMgr:GetGlobalServiceList()
    for _, tConf in pairs(tGlobalServiceList) do
        if tConf.nServer == self:GetServer() or tConf.nServer == gnWorldServerID then
            Network:RMCall("GRoleUpdateReq", nil, tConf.nServer, tConf.nID, self:GetSession(), self:GetID(), tParam)
        end
    end
end

--同步战斗结束信息到[W]GLOBAL
function CRole:GlobalBattleUpdate(tData)
     local tGlobalServiceList = goServerMgr:GetGlobalServiceList()
    for _, tConf in pairs(tGlobalServiceList) do
        if tConf.nServer == self:GetServer() or tConf.nServer == gnWorldServerID then
            Network:RMCall("OnBattleEndReq", nil, tConf.nServer, tConf.nID, self:GetSession(), self:GetID(), tData)
        end
    end
end

--计算储备经验
function CRole:CalcStoreExp()
    --20级以上才有
    if self:GetLevel() < 20 then
        return
    end
    local nOfflineTime = self:GetOnlineTime() - self:GetOfflineTime()
    --离线30分钟才有
    if nOfflineTime < 30*60 then
        return
    end
    local nCalcMin = math.floor(math.min(nOfflineTime/60, 72*60))
    local nStoreExp = math.floor( (self:GetLevel()*200+1000)/60 * nCalcMin )

    local nServerLevel = goServerMgr:GetServerLevel(self:GetServer())
    if self:GetLevel() >= nServerLevel + 8 then
        nStoreExp = 0
    elseif self:GetLevel() >= nServerLevel + 5 then
        nStoreExp = math.floor(nStoreExp * 0.66)
    elseif self:GetLevel() >= nServerLevel then
        nStoreExp = math.floor(nStoreExp * 0.8)
    end

    -- print(self:GetName(), "上线获得储备经验:"..nStoreExp, "离线分钟:"..nCalcMin, "等级:"..self:GetLevel(), "服务器等级:"..nServerLevel)
    self:AddItem(gtItemType.eCurr, gtCurrType.eStoreExp, nStoreExp, "离线储备经验")
end

--登录到逻辑服
function CRole:OnEnterLogic() 
    for _, oModule in ipairs(self.m_tModuleList) do
        oModule:OnEnterLogic()
    end
end

-- function CRole:IsDealOnline()
--     return self.m_bDealOnline and true or false
-- end

function CRole:CheckNativeObj(sInfo)
    if not self.m_oNativeObj then
        LuaTrace(sInfo, self:GetID(), self:GetName(), debug.traceback())
    end
end

--角色上线(注意:切换逻辑服不会调用)
function CRole:Online(bReconnect)
    LuaTrace("CRole:Online***", self:GetAccountName(), self:GetID(), self:GetName(), bReconnect, self.m_oNativeObj)
    -- self.m_bDealOnline = true
    self.m_nOnlineTime = os.time()
    self.m_tCurrMsgCache = {}
    self:MarkDirty(true)
    self:SetBattleOffline(false)
    self:ResetActState(false)

    --发送初始化数据 
    self:SyncInitData()
    --更新战力
    self:UpdatePower()

    --各模块上线(可能有依赖关系所以用list)
    for _, oModule in ipairs(self.m_tModuleList) do
        oModule:Online()
        self:CheckNativeObj(oModule:GetType())
    end
    --NPC管理器通知
    goNpcMgr:Online(self)
    --WGLOBALOBAL上线通知
    self:GlobalRoleOnline(true, false)

    --计算储备经验(策划屏蔽 单2471)
    -- self:CalcStoreExp()

    self:SetTarBattleDupType(0)  --上线清理下旧数据，防止传送过程异常
    self:SetTarActFlag(gtRoleTarActFlag.eNormal)
    --重连进入战斗
    if self:IsInBattle() then
        --战斗中
        local oBattle = goBattleMgr:GetBattle(self.m_nBattleID)
        if oBattle then
            oBattle:ReturnBattle(self)
        else
        --战斗不存在
            self:SetBattleID(0)
        end
    end
    self:AfterOnline()
    --回到场景
    -- self.m_bDealOnline = nil
    self:ReturnScene(bReconnect)
end

function CRole:AfterOnline()
    --首次登陆
    if self.m_nOfflineTime == 0 then
        self.m_bAutoBattle = true
        self.m_nAutoInst = CUnit.tINST.eFS
        local tSkill = self.m_oSkill:GetMainSkill()
        self.m_nAutoSkill = tSkill and tSkill.nID or 0
        self:MarkDirty(true)
    end
    
    if self.m_nVIP == 0 then
        self:SetVIP(15, "上线福利")
        self:SendMsg("RoleFirstOnlineAwardRet", {})
        GetGModule("TimerMgr"):Interval(1, function(nTimerID)
            GetGModule("TimerMgr"):Clear(nTimerID)
            self:AddItem(gtItemType.eCurr, gtCurrType.eBYuanBao, ctRoleInitConf[1].nInitBYuanBao, "上线福利")
        end)
    end
    for _, oModule in ipairs(self.m_tModuleList) do
        oModule:AfterOnline()
    end
end

--角色断线(角色组队的情况下保留25分钟)
function CRole:OnDisconnect()
    LuaTrace("CRole:OnDisconnect***", self:GetSession(), self:GetID(), self:GetName())
    self:BindSession(0)
    self.m_nOfflineTime = os.time()
    self:MarkDirty(true)
    --各模块断线
    for nModuleID, oModule in pairs(self.m_tModuleMap) do
        oModule:Offline()
    end
    self:SaveData()
    print(self:GetName(), "角色断线了")

    --移除观察者身份
    local oDup = self:GetCurrDupObj()
    if oDup then
        oDup:RemoveObserver(self:GetAOIID(), true)
        oDup:OnObjDisconnect(self)
    else
        local tCurDup = self:GetCurrDup()
        LuaTrace("CurrDup:", tCurDup, CUtil:GetDupID(tCurDup[1]), "OnDisconnect: 找不到场景->玩家还没进入场景")
    end

    --更新角色摘要到登录服
    self:UpdateRoleSummary()
    --GLOBAL/WGLOBAL下线通知
    self:GlobalRoleOnline(false, false)
end

--角色对象释放(注意:切换逻辑服不会调用)
function CRole:Offline()
    LuaTrace("CRole:Offline***", self:GetSession(), self:GetID(), self:GetName())
    --保存数据
    self:SaveData()
    
    --如果是战斗中,则等战斗完之后再下线
    if self:IsInBattle() then
        self:SetBattleOffline(true)
        return false
    end
    
    --同步到网关
    self:SyncRoleLogic(true)
    --更新角色摘要到登录服
    self:UpdateRoleSummary()
    --GLOBAL/WGLOBAL下线通知
    self:GlobalRoleOnline(false, true)
    return true
end

function CRole:IsTempRole() return false end
function CRole:IsRobot() return false end
function CRole:GetVIP() return self.m_nVIP end
function CRole:GetVitality() return self.m_nVitality end    --
function CRole:GetExp() return self.m_nExp or 0 end
function CRole:GetNextExp() return ctRoleLevelConf[self.m_nLevel].nNeedExp end
function CRole:GetStoreExp() return self.m_nStoreExp end
function CRole:GetPotential() return self.m_oRoleWash:GetPotential() end
function CRole:AddPotential(nNum) return self.m_oRoleWash:AddPotential(nNum) end
function CRole:GetYuanBao() return self.m_nYuanBao end
function CRole:GetBYuanBao() return self.m_nBYuanBao end
function CRole:GetYinBi() return self.m_nYinBi end
function CRole:GetJinBi() return self.m_nJinBi end
function CRole:GetChivalry() return self.m_nChivalry end
function CRole:GetJinDing() return self.m_nJinDing end
function CRole:GetFuYuan() return self.m_nFuYuan end
function CRole:GetArenaCoin() return self.m_nArenaCoin end
function CRole:GetLanZuan() return self.m_nLanZuan end
function CRole:IsSpouse(nRoleID) return self.m_oSpouse:IsSpouse(nRoleID) end
function CRole:IsLover(nRoleID) return self.m_oLover:IsLover(nRoleID) end
function CRole:IsBrother(nRoleID) return self.m_oBrother:IsBrother(nRoleID) end
function CRole:IsMentorship(nRoleID) return self.m_oMentorship:IsMentorship(nRoleID) end
function CRole:GetSpouse() return self.m_oSpouse:GetSpouse() end
function CRole:IsSysOpen(nSysID, bTips)
    return self.m_oSysOpen:IsSysOpen(nSysID, bTips)
end

--活力上限
function CRole:MaxVitality()
   local nMaxVitality = 50 + self.m_nLevel * 20 
   return nMaxVitality
end

--添加活力
function CRole:AddVitality(nVal)
    local nOldVitality = self.m_nVitality
    self.m_nVitality = math.max(0, math.min(self:MaxVitality(), self.m_nVitality+nVal))
    self:MarkDirty(true)

    self:SyncCurrency(gtCurrType.eVitality, self.m_nVitality)

    if nVal > 0 and self.m_nVitality >= self:MaxVitality() then
        return self:Tips("您的活力已满，请尽快使用")
    end
    if nVal > 0 and self.m_nVitality >= self:MaxVitality()*2/3 then
        return self:Tips("您的活力快满了，请尽快使用")
    end

    --消耗活力限时奖励
    if nVal < 0 then
        Network:RMCall("OnTAHLReq", nil, self:GetServer(), goServerMgr:GetGlobalService(self:GetServer(),20), 0, self:GetID(), self.m_nVitality-nOldVitality)
    end

end

--计算经验加成
function CRole:CalcExp(nExp)
    if nExp <= 0 then
        return nExp, 0
    end

    local nServerLevel = goServerMgr:GetServerLevel(self:GetServer())
    if self.m_nLevel >= nServerLevel + 8 then
        local nYinBi = math.floor(0.33 * nExp)
        self:AddItem(gtItemType.eCurr, gtCurrType.eYinBi, nYinBi, "经验转银币")
        return 0, nYinBi
    end

    if self.m_nLevel >= nServerLevel + 5 then
        return math.floor(nExp*0.66), 0
    end

    if self.m_nLevel >= nServerLevel then
        return math.floor(nExp*0.8), 0
    end

    if self.m_nLevel < nServerLevel and nServerLevel >= 60 then
        nExp = math.floor(nExp*(1+math.max(0, math.min(3, (nServerLevel-self.m_nLevel)*0.02))))
        return nExp, 0
    end
    return nExp, 0
end

--获取的总经验
function CRole:GetAllExp()
    local nRetExp = 0
    local nRoleLevel = self:GetLevel()
    for nLevel,tConf in ipairs(ctRoleLevelConf) do
        if nRoleLevel >= nLevel then
            nRetExp = nRetExp + tConf.nNeedExp
        end
    end
    nRetExp = nRetExp + self.m_nExp
    return nRetExp
end

--添加经验
--@bRawExp: 不受加成影响(包括服务等级修正)
function CRole:AddExp(nVal, bRawExp, bNotSync)
    local nRawAddVal = nVal
    local nStoreExp, nYinBi1, nYinBi2 = 0, 0, 0
    --服务器等级加成计算
    if nVal > 0 and not bRawExp then
        nVal, nYinBi1 = self:CalcExp(nVal)
        --屏蔽储备经验
        -- nStoreExp = math.min(nVal, self:GetStoreExp())
        -- self:SubItem(gtItemType.eCurr, gtCurrType.eStoreExp, nStoreExp, "同步扣储备经验")
        -- nVal = nVal + nStoreExp
    end

    --卡等级经验计算
    nVal, nYinBi2 = self:CheckStuckLevelExchange(nVal)
    self.m_nExp = math.max(0, math.min(self:MaxAddExp(), self.m_nExp+nVal))
    self:MarkDirty(true)

    if bNotSync then
        self:CacheCurrMsg(gtCurrType.eExp, self.m_nExp, math.max(0, nVal-nRawAddVal), nYinBi1+nYinBi2)
    else
        self:SyncCurrency(gtCurrType.eExp, self.m_nExp, math.max(0, nVal-nRawAddVal), nYinBi1+nYinBi2)
    end
    self:CheckUpgrade()
    return self.m_nExp
end

function CRole:MaxAddExp()
    local nServerLevel = goServerMgr:GetServerLevel(self:GetServer())
    local tConf = ctRoleLevelConf[self.m_nLevel]
    local nCriticalVal = tConf.nNeedExp*10
    return nCriticalVal
end

--卡等级经验换算
function CRole:CheckStuckLevelExchange(nVal)
    if not self:IsStuckLevel() then
        return nVal, 0
    end
    local nYinBi = 0
    local nCriticalVal = self:MaxAddExp()
    if self.m_nExp < nCriticalVal then
        nVal = math.floor(nVal / 3 * 2)
    else
        nYinBi = math.floor(nVal / 3)
        self:AddItem(gtItemType.eCurr, gtCurrType.eYinBi, nYinBi, "卡等级换算")
        nVal = 0
    end
    return nVal, nYinBi
end

--检测升级
function CRole:CheckUpgrade()
    if self:IsStuckLevel() then
        return 
    end
    local nServerLevel = goServerMgr:GetServerLevel(self:GetServer())
    --计算升级
    local nLevel = self.m_nLevel
    for k=self.m_nLevel, #ctRoleLevelConf-1 do
        local tConf = ctRoleLevelConf[k]
        if self.m_nExp >= tConf.nNeedExp then
            if self.m_nLevel >= nServerLevel+8 then
                self.m_nExp = math.min(self.m_nExp, tConf.nNeedExp-1)
                self:MarkDirty(true)
                break
            end
            self.m_nLevel = self.m_nLevel + 1
            self.m_nExp = self.m_nExp - tConf.nNeedExp
            self:MarkDirty(true)
        end
    end
    if nLevel ~= self.m_nLevel then
        self:OnLevelChange(nLevel, self.m_nLevel)
        self:SyncCurrency(gtCurrType.eExp, self.m_nExp)
    end
end

--角色等级变化
function CRole:OnLevelChange(nOldLevel, nNewLevel)
    print("CRole:OnLevelChange***", nOldLevel, nNewLevel)
    self:SyncLevel()

    --通知[W]GLOBAL
    self:GlobalRoleUpdate({m_nLevel=nNewLevel})

    --计算基础属性主角每次升级时，每级默认每个主属性增加1点（体质，魔力，耐力，力量，敏捷）
    local nDiffLevel = nNewLevel - nOldLevel
    for k=1, #self.m_tBaseAttr do
        self.m_tBaseAttr[k] = self.m_tBaseAttr[k] + nDiffLevel
    end
    self:MarkDirty(true)

    --添加潜力点
    self:AddItem(gtItemType.eCurr, gtCurrType.ePotential, nDiffLevel*5, "等级潜力")

    --模块调用
    self.m_oSysOpen:OnLevelChange(nNewLevel)
    self.m_oSkill:OnRoleLevelChange(nNewLevel)
    self.m_oTaskSystem:OnRoleLevelChange(nOldLevel, nNewLevel)
    self.m_oPartner:OnRoleLevelChange(nNewLevel)
    self.m_oDailyActivity:OnRoleLevelChange(nNewLevel)
    self.m_oShiMenTask:OnRoleLevelChange(nNewLevel)
    self.m_oFund:OnRoleLevelChange(nNewLevel)
    self.m_oShangJinTask:OnRoleLevelChange(nNewLevel)
    self.m_oUpgradeBag:OnRoleLevelChange(nNewLevel)
    self.m_oYaoShouTuXi:OnRoleLevelChange(nNewLevel)
    self.m_oAchieve:OnLevelChange(nNewLevel)
    self.m_oShiLianTask:OnLevelChange(nNewLevel)
    self.m_oBaHuangHuoZhen:OnLevelChange(nNewLevel)
    self.m_oPractice:OnRoleLevelChange(nOldLevel, nNewLevel)
    self.m_oKnapsack:OnRoleLevelChange(nOldLevel, nNewLevel)
    self.m_oPayPush:OnLevelChange(nNewLevel)
    self.m_oGuideTask:OnRoleLevelChange(nOldLevel, nNewLevel)

    --更新结果属性
    self:UpdateAttr()

    --日志    
    goLogger:UpdateRoleLog(self, {level=nNewLevel})
    CEventHandler:OnRoleLevelChange(self, {nNewLevel=nNewLevel})
end

--同步货币
function CRole:SyncCurrency(nType, nValue, nValue1, nValue2)
    assert(nType and nValue, "参数错误")
    self:SendMsg("RoleCurrencyRet", {tList={{nType=nType, nValue=nValue, nValue1=nValue1, nValue2=nValue2}}})
end

--同步等级
function CRole:SyncLevel()
    local nMaxLevel = #ctRoleLevelConf
    local nNextExp = self:GetNextExp()
    local tMsg = {nLevel=self.m_nLevel,nExp=self.m_nExp,nMaxLevel=nMaxLevel,nNextExp=nNextExp}
    self:SendMsg("RoleLevelRet", tMsg)
end

--添加储备经验
function CRole:AddStoreExp(nVal)
    do return end --策划屏蔽 单2471

    self.m_nStoreExp = math.max(0, math.min(gtGDef.tConst.nMaxInteger, self.m_nStoreExp+nVal))
    self:MarkDirty(true)

    local nOfflineMin = math.floor((self:GetOnlineTime()-self:GetOfflineTime())/60)
    self:SyncCurrency(gtCurrType.eStoreExp, self.m_nStoreExp, nOfflineMin)
    return self.m_nStoreExp
end

--添加元宝
--@bNotSync 是否不同步(用于一键操作时,避免发太多包给客户端)
function CRole:AddYuanBao(nVal, bNotSync)
    local nOldYuanBao = self.m_nYuanBao
    self.m_nYuanBao = math.max(0, math.min(gtGDef.tConst.nMaxInteger, self.m_nYuanBao+nVal))
    nVal = self.m_nYuanBao - nOldYuanBao
    self:MarkDirty(true)

    if bNotSync then
        self:CacheCurrMsg(gtCurrType.eYuanBao, self.m_nYuanBao)
    else
        self:SyncCurrency(gtCurrType.eYuanBao, self.m_nYuanBao)
    end

    local tGlobalServiceList = goServerMgr:GetGlobalServiceList(self:GetServer())
    for _, tService in pairs(tGlobalServiceList) do
        Network:RMCall("OnRoleYuanBaoChange", nil, tService.nServer, tService.nID, 0, self:GetID(), nVal, false)
    end

    --日志
    goLogger:UpdateRoleLog(self, {yuanbao=self.m_nYuanBao})
    return self.m_nYuanBao
end

--添加绑定元宝
--@bNotSync 是否不同步(用于一键操作时,避免发太多包给客户端)
function CRole:AddBYuanBao(nVal, bNotSync)
    local nOldBYuanBao = self.m_nBYuanBao
    self.m_nBYuanBao = math.max(0, math.min(gtGDef.tConst.nMaxInteger, self.m_nBYuanBao+nVal))
    nVal = self.m_nBYuanBao - nOldBYuanBao
    self:MarkDirty(true)

    if bNotSync then
        self:CacheCurrMsg(gtCurrType.eBYuanBao, self.m_nBYuanBao)
    else
        self:SyncCurrency(gtCurrType.eBYuanBao, self.m_nBYuanBao)
    end

    local tGlobalServiceList = goServerMgr:GetGlobalServiceList(self:GetServer())
    for _, tService in pairs(tGlobalServiceList) do
        Network:RMCall("OnRoleYuanBaoChange", nil, tService.nServer, tService.nID, 0, self:GetID(), nVal, true)
    end

    --日志
    goLogger:UpdateRoleLog(self, {bindyuanbao=self.m_nBYuanBao})
    return self.m_nBYuanBao
end

--添加金币
--@bNotSync 是否不同步(用于一键操作时,避免发太多包给客户端)
function CRole:AddJinBi(nVal, bNotSync)
    local nOldJinBi = self.m_nJinBi
    self.m_nJinBi= math.max(0, math.min(gtGDef.tConst.nMaxInteger, self.m_nJinBi+nVal))
    self:MarkDirty(true)

    if bNotSync then
        self:CacheCurrMsg(gtCurrType.eJinBi, self.m_nJinBi)
    else
        self:SyncCurrency(gtCurrType.eJinBi, self.m_nJinBi)
    end

    --累计消耗金币
    if nVal < 0 then
        Network:RMCall("OnTAJBReq", nil, self:GetServer(), goServerMgr:GetGlobalService(self:GetServer(),20), 0, self:GetID(), self.m_nJinBi-nOldJinBi)
    end
    return self.m_nJinBi
end

--添加银币
--@bNotSync 是否不同步(用于一键操作时,避免发太多包给客户端)
function CRole:AddYinBi(nVal, bNotSync)
    local nOldYinBi = self.m_nYinBi
    self.m_nYinBi = math.max(0, math.min(gtGDef.tConst.nMaxInteger, self.m_nYinBi+nVal))
    self:MarkDirty(true)

    if bNotSync then
        self:CacheCurrMsg(gtCurrType.eYinBi, self.m_nYinBi)
    else
        self:SyncCurrency(gtCurrType.eYinBi, self.m_nYinBi)
    end

    if nVal > 0 then
    --银币变化检测技能升级
        self.m_oSkill:OnYinBiChange()
        self.m_oPractice:OnYinBiChange()
        self.m_oAssistedSkill:OnYinBiChange()
    elseif nVal < 0 then
    --累计消耗银币
        Network:RMCall("OnTAYBReq", nil, self:GetServer(), goServerMgr:GetGlobalService(self:GetServer(),20), 0, self:GetID(), self.m_nYinBi-nOldYinBi)
    end
    return self.m_nYinBi
end

--每天侠义可添加数量
function CRole:RemainChivalry()
    if not self.m_oToday then --热更需要
        self.m_oToday = CToday:new(0)
    end
    local nTodayVal = self.m_oToday:Query("chivalry", 0)
    return math.max(0, (120-nTodayVal))
end

--添加侠义值
function CRole:AddChivalry(nVal)
    if nVal < 0 then
        self.m_nChivalry = math.max(0, self.m_nChivalry+nVal)

    else
        nVal = math.min(nVal, self:RemainChivalry())
        if nVal <= 0 then
            return self.m_nChivalry
        end
        self.m_nChivalry = math.max(0, math.min(gtGDef.tConst.nMaxInteger, self.m_nChivalry+nVal))
        self.m_oToday:Add("chivalry", nVal)
    end
    self:MarkDirty(true)
    self:SyncCurrency(gtCurrType.eChivalry, self.m_nChivalry)
    return self.m_nChivalry
end

--添加竞技币
function CRole:AddArenaCoin(nVal)
    local nOldArenaCoin = self.m_nArenaCoin
    self.m_nArenaCoin = math.max(0, math.min(gtGDef.tConst.nMaxInteger, self.m_nArenaCoin+nVal))
    self:MarkDirty(true)
    self:SyncCurrency(gtCurrType.eArenaCoin, self.m_nArenaCoin)
    return self.m_nArenaCoin
end

--添加活跃值(总活跃)
function CRole:AddActValue(nVal)
    if 0 == nValue then return end
    local nActVal = self.m_oDailyActivity.m_nTotalActValue
    self.m_oDailyActivity.m_nTotalActValue = math.max(0, math.min(gtGDef.tConst.nMaxInteger, nActVal+nVal))
    self:MarkDirty(true)
    self.m_oDailyActivity:CheckActRewardState()
    Network:RMCall("GRoleActiveNumChangeReq", nil, gnWorldServerID, goServerMgr:GetGlobalService(gnWorldServerID, 110), 
        self:GetSession(), self:GetID(), nVal)
    return self.m_oDailyActivity.m_nTotalActValue
end

--添加双倍点数
function CRole:AddShuangBei(nShuangBei)
    --return self.m_oShuangBei:AddShuangBei(nShuangBei)
end

--添加金锭
function CRole:AddJinDing(nVal)
    if nVal == 0 then return end
    self.m_nJinDing= math.max(0, math.min(gtGDef.tConst.nMaxInteger, self.m_nJinDing+nVal))
    self:MarkDirty(true)

    self:SyncCurrency(gtCurrType.eJinDing, self.m_nJinDing)
    return self.m_nJinDing
end

function CRole:AddFuYuan(nVal)
    if nVal == 0 then return end
    self.m_nFuYuan= math.max(0, math.min(gtGDef.tConst.nMaxInteger, self.m_nFuYuan+nVal))
    self:MarkDirty(true)

    self:SyncCurrency(gtCurrType.eFuYuan, self.m_nFuYuan)
    return self.m_nFuYuan
end

function CRole:AddLanZuan(nVal)
    if nVal == 0 then return end
    self.m_nLanZuan= math.max(0, math.min(gtGDef.tConst.nMaxInteger, self.m_nLanZuan+nVal))
    self:MarkDirty(true)

    self:SyncCurrency(gtCurrType.eLanZuan, self.m_nLanZuan)
    return self.m_nLanZuan
end



function CRole:SetPVEActData(nActID, nIndex)
    local tActData = self.m_tPVEActData[nActID]
    if not tActData then
        local tActData = {}
        tActData[nIndex] = true
        tActData.nResetTime = os.time()
        self.m_tPVEActData[nActID] = tActData
    else
        if tActData[nIndex] then return end
        tActData[nIndex] = true
        self:MarkDirty(true)
    end
end

function CRole:GetPVEActData(nActID)
    return self.m_tPVEActData[nActID]
end

function CRole:ResetPVEData()
    self.m_tPVEActData = {}
    self:MarkDirty(true)
end

--飘字通知
function CRole:Tips(sCont, nServer, nSession)
    nServer = nServer or self:GetServer()
    nSession = nSession or self:GetSession()
    if nServer >= gnWorldServerID then
        return
    end
    if nServer > 0 and nSession > 0 then
        self:SendMsg("FloatTipsRet", {sCont=sCont}, nServer, nSession)
    end
end

--元宝不足通知,客户端会弹相应的界面
function CRole:YuanBaoTips()
    self:SendMsg("GoldAllNotEnoughtRet", {})
end
--金币不足通知,客户端会弹相应界面
function CRole:JinBiTips()
    self:SendMsg("JinBiNotEnoughtRet", {})
end
--银币不足通知,客户端会弹相应的界面
function CRole:YinBiTips()
    self:SendMsg("YinBiNotEnoughtRet", {})
end

--内丹不足通知
function CRole:MagicPillTips()
    self:SendMsg("MagicPillNotEnoughtRet", {})
end

--道具不足通知,客户端弹出对应的Tips
function CRole:PropTips(nPropID)
    self:SendMsg("PropNotEnoughtRet", {nPropID = nPropID})
end

--获取显示的武器ID
function CRole:GetDisplayWeaponID()
    local nWeaponID = self:GetWeaponID()
    local nActState = self:GetActState()
    if nActState == gtRoleActState.eWedding 
        or nActState == gtRoleActState.ePalanquinParade then 
        nWeaponID = 0
    end
    return nWeaponID
end

--取角色外形信息
function CRole:GetShapeData()
    local tShape = {}
    tShape.nTeamID = self:GetTeamID()
    tShape.bLeader = self:IsLeader()
    tShape.nTeamNum = self:GetTeamNum()
    --判断是否在PVP活动场景
    local tCurrDup = self:GetCurrDup()
    if tCurrDup and tCurrDup[1] > 0 then
        local oPVPActivityInst = goPVPActivityMgr:GetActivityInstByDupMixID(tCurrDup[1])
        if oPVPActivityInst then
            local oRolePVPActData = oPVPActivityInst:GetRoleData(self:GetID())
            if oRolePVPActData then
                tShape.tPVPActivityData = {}
                tShape.tPVPActivityData.nState = oRolePVPActData:GetState()
            end
        end
    end
    local bWeddingModel = self:IsWeddingModel()
    tShape.nFlyMountID = bWeddingModel and 0 or self:GetFlyMountID()
    tShape.nWingID = bWeddingModel and 0 or self:GetWingID()
    tShape.nHaloID = bWeddingModel and 0 or self:GetHaloID()
    tShape.nWeaponID = bWeddingModel and 0 or self:GetDisplayWeaponID()
    tShape.nUnionID = self:GetUnionID()
    tShape.nArtifactID = self:GetArtifactID()
    tShape.tAppellationData = self.m_oAppellation:GetSceneDisplayData()
    tShape.tActData = {}
    tShape.tActData.nActID = self:GetActID()
    if tShape.tActData.nActID > 0 then 
        tShape.tActData.nTime = self:GetActTime()
    end
    tShape.sModel = self:GetDisplayModel()
    return tShape
end

function CRole:GetDisplayModel()
    local nActState = self:GetActState()
    if nActState == gtRoleActState.eWedding or nActState == gtRoleActState.ePalanquinParade 
        or self.m_oRoleState:IsMarriageSuitActive() then
        return self:GetWeddingSuitModel()
    end
    return self:GetConf().sModel
end

function CRole:IsWeddingModel()
    local nActState = self:GetActState()
    if nActState == gtRoleActState.eWedding or nActState == gtRoleActState.ePalanquinParade then
        return true
    end
    return false
end

--取角色视野信息
function CRole:GetViewData()
    if not self.m_oNativeObj then
        return {}
    end

    --为了加快速度，做下缓存
    if not self.m_tViewData then 
        self.m_tViewData = {
            tBaseData = {
                nObjType = gtGDef.tObjType.eRole,
                nObjID = self:GetID(),
                nConfID = self:GetConfID(),
                sName = self:GetName(),

                nAOIID = 0,
                nLevel = 0,
                nPosX = 0,
                nPosY = 0,
                nSpeedX = 0,
                nSpeedY = 0,
                nTarPosX = 0,
                nTarPosY = 0,
                sModel = "",
                nDir = 0,
            },
            tShapeData = nil,
        }
    end
    local tBaseData = self.m_tViewData.tBaseData
    tBaseData.sName = self:GetName()  --角色改名
    tBaseData.nAOIID = self:GetAOIID()
    tBaseData.nLevel = self:GetLevel()
    tBaseData.nPosX, tBaseData.nPosY = self:GetPos()
    tBaseData.nSpeedX, tBaseData.nSpeedY = self:GetSpeed()
    tBaseData.nTarPosX, tBaseData.nTarPosY = self:GetTarPos()
    tBaseData.sModel = self:GetDisplayModel()
    tBaseData.nDir = self:GetFace()
    self.m_tViewData.tShapeData = self:GetShapeData()
    return self.m_tViewData
end

--同步逻辑服到网关
function CRole:SyncRoleLogic(bRelease)
    local nServer = self:GetServer()
    local nGateway = self:GetGateway()
    local nSession = self:GetSession()
    local nRoleID = self:GetID()
    Network.CmdSrv2Srv("SyncRoleLogic", nServer, nGateway, nSession, self:GetID(), (bRelease and 1 or 0))
end

function CRole:SwitchSceneCheck(nDupMixID)
    local nCurState = self:GetActState()
    if nCurState == gtRoleActState.eWeddingApply then 
        self:Tips("正在申请结婚，无法切换场景")
        return false
    elseif nCurState == gtRoleActState.eWedding then 
        self:Tips("正在举行婚礼，无法切换场景")
        return false
    elseif nCurState == gtRoleActState.ePalanquinApply then 
        self:Tips("正在申请花轿游行，无法切换场景")
        return false
    elseif nCurState == gtRoleActState.ePalanquinParade then 
        self:Tips("正在花轿游行，无法切换场景")
        return false
    end
    return true
end

--返还到当前场景: 登陆/战斗返回
function CRole:ReturnScene(bReconnect)
    print("CRole:ReturnScene***", self:GetID(), self:GetName(), bReconnect)
    local oDup = self:GetCurrDupObj()
    if oDup then 
        if bReconnect then
            self:OnEnterScene(oDup:GetMixID(), bReconnect)
            oDup:AddObserver(self:GetAOIID())
            return 
        end
        local tCurrDup = self:GetCurrDup()
        local tDupConf = oDup:GetConf()

        if CUtil:IsBlockUnit(tCurrDup[1], tCurrDup[2], tCurrDup[3]) then
            LuaTrace("******不合理的返回点******", self:GetName(), tCurrDup)
            tCurrDup[2], tCurrDup[3], tCurrDup[4] = tDupConf.tBorn[1][1], tDupConf.tBorn[1][2], tDupConf.nFace
        end

        -- return oDup:Enter(self.m_oNativeObj, tCurrDup[2], tCurrDup[3], -1, (tCurrDup[4] or 0))
        return goDupMgr:EnterDup(tCurrDup[1], self.m_oNativeObj, 
            tCurrDup[2], tCurrDup[3], -1, (tCurrDup[4] or 0))
    end

    --当前场景已释放,则进入最后场景
    local tLastDup = self:GetLastDup()
    local nDupID, nPosX, nPosY, nFace = tLastDup[1], tLastDup[2], tLastDup[3], tLastDup[4]
    if not ctDupConf[nDupID] then --场景不存在则进入默认场景
        nDupID = 1
        local tDupConf = ctDupConf[1]
        nPosX, nPosY = table.unpack(tDupConf.tBorn[1])
        nFace = tDupConf.nFace
    end
    return goDupMgr:EnterDup(nDupID, self.m_oNativeObj, nPosX, nPosY, -1, nFace)
end

--进入指定场景
function CRole:EnterScene(nDupMixID, nPosX, nPosY, nLine, nFace)
    if not self:SwitchSceneCheck(nDupMixID) then 
        return
    end
    if self:IsRobot() then 
        goDupMgr:EnterDup(nDupMixID, self.m_oNativeObj, nPosX, nPosY, nLine, nFace)
        return 
    end
    local oDupObj = self:GetCurrDupObj()
    if not oDupObj then
        LuaTrace("角色不在场景中???", self:GetID(), self:GetName(), self:GetCurrDup(), nDupMixID, debug.traceback())
        return
    end
    local tCurrDupConf = oDupObj:GetConf()
    local tTarDupConf = ctDupConf[CUtil:GetDupID(nDupMixID)]
    --从副本切换的城镇，要拦截(主要是副本中点击了任务等)
    --副本A切换到副本B在CBattleDupMgr:EnterBattleDupReq做是否离开询问拦截 主要的目的是：询问拦截框比请求进入副本提示框早显示
    --副本A切换到普通场景在此处拦截tTarDupConf.nType == CDupBase.tType.eCity
    if tCurrDupConf.nType == CDupBase.tType.eDup                
        and tTarDupConf.nType == CDupBase.tType.eCity
        and tTarDupConf.nBattleType ~= gtBattleDupType.eFBTransitScene          --副本中转场景不拦截提示
        and tCurrDupConf.nBattleType ~= tTarDupConf.nBattleType
        and not table.InArray(tTarDupConf.nBattleType, tCurrDupConf.tHallBattleType) then
        --策划要求副本中只能通过副本出口离开，此拦截副本中切换场景请求
        -- local tMsg = {sCont="是否确定离开当前副本？", tOption={"取消", "确定"}, nTimeOut=30}
        -- goClientCall:CallWait("ConfirmRet", function(tData)
        --     if tData.nSelIdx == 1 then
        --         return
        --     elseif tData.nSelIdx == 2 then
        --         if not self:SwitchSceneCheck(nDupMixID) then 
        --             return
        --         end
        --         goDupMgr:EnterDup(nDupMixID, self.m_oNativeObj, nPosX, nPosY, nLine, nFace)
        --     end
        -- end, self, tMsg)
        goBattleDupMgr:LeaveBattleDupReq(self)
    else
        goDupMgr:EnterDup(nDupMixID, self.m_oNativeObj, nPosX, nPosY, nLine, nFace)
    end
end

--进入最后城镇
function CRole:EnterLastCity()
    --拦截下，防止通过退出副本接口，跳转到其他场景，绕过场景检查
    local oDupObj = self:GetCurrDupObj()
    if oDupObj then
        local tCurrDupConf = oDupObj:GetConf()
        -- local tTarDupConf = ctDupConf[CUtil:GetDupID(nDupMixID)]
        if tCurrDupConf.nType == CDupBase.tType.eCity then 
            return self:Tips("当前已在主场景中")
        end
        local tLastDup = self:GetLastDup()
        local nDupMixID, nPosX, nPosY, nFace = tLastDup[1], tLastDup[2], tLastDup[3], tLastDup[4]
        if not self:SwitchSceneCheck(nDupMixID) then 
            return
        end
        goDupMgr:EnterDup(nDupMixID, self.m_oNativeObj, nPosX, nPosY, -1, nFace)
    end
end

--离开场景
function CRole:LeaveScene()
    --未进入场景
    if self:GetDupMixID() <= 0 then 
        return
    end
    self:StopRun()
    goDupMgr:LeaveDup(self:GetDupMixID(), self:GetAOIID())
end


--角色进入场景成功事件
function CRole:OnEnterScene(nDupMixID, bReconnect) --这里还没进行观察者和被观察者相关同步
    print("CRole:OnEnterScene***", self:GetName(), nDupMixID)
    --记录当前场景
    local tCurrDup = self:GetCurrDup()
    tCurrDup[1] = nDupMixID
    tCurrDup[2], tCurrDup[3] = self:GetPos()
    tCurrDup[4] = self:GetFace()
    self:MarkDirty(true)
    --通知网关服当前逻辑服
    self:SyncRoleLogic()

    --是否在障碍点
    if CUtil:IsBlockUnit(nDupMixID, tCurrDup[2], tCurrDup[3]) then
        LuaTrace("******不合理的出生点******", self:GetName(), tCurrDup)
        LuaTrace(debug.traceback())
    end

    --进入成功回调
    local oDup = self:GetCurrDupObj()
    oDup:OnObjEnter(self, bReconnect)

    --更新玩家摘要到登录服
    self:UpdateRoleSummary()
    --NPC管理器通知
    goNpcMgr:OnEnterScene(self)
    --通知[W]GLOBAL
    self:GlobalRoleUpdate({m_nDupMixID=nDupMixID})

    --通知客户端
    local nSpeedX, nSpeedY = self:GetSpeed()
    local nTarPosX, nTarPosY = self:GetTarPos()
    local tMsg = {
        nDupMixID = nDupMixID,
        nDupID = CUtil:GetDupID(nDupMixID), 
        nAOIID = self:GetAOIID(),
        nObjID = self:GetID(),
        nPosX = tCurrDup[2],
        nPosY = tCurrDup[3],
        nDir = tCurrDup[4],
        nSpeedX = nSpeedX,
        nSpeedY = nSpeedY,
        nTarPosX = nTarPosX,
        nTarPosY = nTarPosY,
        sModel = self:GetConf().sModel,
        nTeamID = self:GetTeamID(),
        bLeader = self:IsLeader(),
    }
    self:SendMsg("RoleEnterSceneRet", tMsg)
    print(self.m_sName, "RoleEnterSceneRet***", tMsg)
end

--角色进入场景后
function CRole:AfterEnterScene(nDupMixID)
    local oDup = self:GetCurrDupObj()
    if oDup then
        oDup:ObjAfterEnter(self)
    end
    --防止玩家连续切换场景，不触发OnSaveData，导致失效称谓一直存在直到下线
    self.m_oAppellation:CheckExpired()
    --离线数据处理放这里
    self.m_oOfflineData:AfterEnterScene()

    if not self:IsReleasedd() then --防止前面事件调用中, 切换场景逻辑服
        local tDupConf = self:GetDupConf()
        if tDupConf.nType == CDupBase.tType.eCity then 
            local nTargetActFlag, tActParam = self:GetTarActFlag()
            if nTargetActFlag == gtRoleTarActFlag.eArena then 
                if tActParam and tActParam.nEnemyID then 
                    local nEnemyID = tActParam.nEnemyID
                    self:SetTarActFlag(gtRoleTarActFlag.eNormal)
                    --再次重新发起竞技场挑战,走完整检查流程，防止中间出现异常数据
                    local nServer = self:GetServer()
                    local nService = goServerMgr:GetGlobalService(nServer, 20)
                    Network:RMCall("JoinArenaBattleReq", nil, nServer, nService, self:GetSession(), self:GetID(), nEnemyID)
                end
            end
        end
    end
end

--角色离开场景
function CRole:OnLeaveScene(nDupMixID)
    print("CRole:OnLeaveScene***", self:GetID(), self:GetName())
    --离开成功回调
    local oDup = self:GetCurrDupObj()
    if oDup then 
        oDup:OnObjLeave(self, self:GetBattleID())
    else
        print("副本已被移除")
    end

    --更新所在坐标和方向
    local tCurrDup = self:GetCurrDup()
    local nPosX, nPosY = self:GetPos()
    tCurrDup[2], tCurrDup[3], tCurrDup[4] = nPosX, nPosY, self:GetFace()
    self:MarkDirty(true)

    --是否在障碍点
    if CUtil:IsBlockUnit(nDupMixID, tCurrDup[2], tCurrDup[3]) then
        LuaTrace("******不合理的离开点******", self:GetName(), tCurrDup)
    end

    --记录上次所在的城镇
    local nDupID = CUtil:GetDupID(nDupMixID)
    local tDupConf = ctDupConf[nDupID]
    if tDupConf.nType == CDupBase.tType.eCity then
        local tLastDup = self:GetLastDup()
        tLastDup[1], tLastDup[2], tLastDup[3] = nDupMixID, nPosX, nPosY
    end
    self:SendMsg("RoleLeaveSceneRet", {})
end

--场景对象进入视野
function CRole:OnObjEnterObj(tObserved)
    if not self:IsOnline() then
        return
    end
    local nObjPerPacket = 64 --N个对象发1次(以免包过大)

    --先处理非角色对象
    local tRoleList = {}
    local tMonsterList = {}
    for j = 1, #tObserved do
        local oLuaObj = GetLuaObjByNativeObj(tObserved[j])
        local nObjType = oLuaObj:GetObjType()

        if nObjType == gtObjType.eMonster then
            local tViewData = oLuaObj:GetViewData()
            table.insert(tMonsterList, tViewData)
            if #tMonsterList >= nObjPerPacket then
                self:SendMsg("MonsterEnterViewRet", {tList=tMonsterList})
                tMonsterList = {}
            end

        elseif nObjType == gtGDef.tObjType.eRole then
            local tViewData = oLuaObj:GetViewData()
            table.insert(tRoleList, tViewData)
            if #tRoleList >= nObjPerPacket then
                self:SendMsg("RoleEnterViewRet", {tList=tRoleList})
                tRoleList = {}
            end

        else
            assert(false, "不存在对象类型:"..nObjType)

        end
    end
    if #tMonsterList > 0 then
        self:SendMsg("MonsterEnterViewRet", {tList=tMonsterList})
    end
    if #tRoleList > 0 then
        self:SendMsg("RoleEnterViewRet", {tList=tRoleList})
    end
end

--刷新角色自己的场景外观表现
function CRole:FlushRoleView()
    if self:GetAOIID() <= 0 then 
        return 
    end
    local tViewData = self:GetViewData()
    local tFlushMsg = {tList = {tViewData}}
    self:SendMsg("RoleViewFlushRet", tFlushMsg) --给自己也通知下
    local oDup = self:GetCurrDupObj()
    if oDup then
        oDup:BroadcastObserver(self:GetAOIID(), "RoleViewFlushRet", tFlushMsg)
    end
    --同步外观信息到家园
    local nServiceID = goServerMgr:GetGlobalService(gnWorldServerID,111)
    Network:RMCall("GRoleUpdateReq", nil, gnWorldServerID,nServiceID,self:GetSession(),self:GetID(),{m_tShapeData=self:GetShapeData()})
end

--更新角色摘要信息
function CRole:UpdateRoleSummary()
    if self:IsRobot() then 
        return 
    end
    local tSummary = {}
    tSummary.nID = nID
    tSummary.sName = self:GetName()
    tSummary.nLevel = self:GetLevel()
    tSummary.nCurrDup = self:GetCurrDup()[1]
    tSummary.nLastDup = self:GetLastDup()[1]
    tSummary.tEquipment = self:GetEquipment()
    tSummary.nConfID = self:GetConfID()
    Network:RMCall("RoleUpdateSummaryReq", nil, self:GetServer(), goServerMgr:GetLoginService(self:GetServer()), self:GetSession()
        , self:GetAccountID(), self:GetID(), tSummary)
end

--恢复MP,HP
function CRole:RecoverMPHP()
    self.m_nCurrHP = self:GetBattleAttr(gtBAT.eQX)
    self.m_nCurrMP = self:GetBattleAttr(gtBAT.eMF)
    self:MarkDirty(true)
end

--当前气血,魔法
function CRole:GetCurrHP() return self.m_nCurrHP end
function CRole:GetCurrMP() return self.m_nCurrMP end
function CRole:IsResidualHP() return self.m_nCurrHP < self:GetBattleAttr(gtBAT.eQX) end --残血
function CRole:IsResidualMP() return self.m_nCurrMP < self:GetBattleAttr(gtBAT.eMP) end --残蓝

--自动升级请求
function CRole:StuckLevelReq(bStuck)
    if bStuck then
        if self:GetLevel() < 60 then
            return self:Tips("60级以上才能卡等级")
        end
        if self:GetLevel() > goServerMgr:GetServerLevel(self:GetServer()) then
            return self:Tips("人物等级≤服务器等级时才能卡等级")
        end
    end
    self.m_bStuckLevel = bStuck
    self:MarkDirty(true)
    self:SendMsg("RoleStuckLevelRet", {bStuck=bStuck})
end

--获取服务器等级请求
function CRole:RoleServerLvReq()
     local nServerLv = goServerMgr:GetServerLevel(self:GetServer())
     local tMsg = {nServerLv = nServerLv}
     self:SendMsg("RoleServerLvRet", tMsg)
end

--角色属性请求
function CRole:RoleAttrReq()
    local nServerLv, nNextServerLvTime = goServerMgr:GetServerLevel(self:GetServer())
    local tMsg = {
        nID = self:GetID(),
        sName = self:GetName(),
        nLevel = self:GetLevel(),
        nSchool = self:GetSchool(),
        sModel = self:GetConf().sModel,

        nPower = self:GetPower(),
        nHP = self.m_nCurrHP,
        nMaxHP = self:GetBattleAttr(gtBAT.eQX),
        nMP = self.m_nCurrMP,
        nMaxMP = self:GetBattleAttr(gtBAT.eMF),
        nVitality = self:GetVitality(),
        nMaxVitality = self:MaxVitality(),
        nCurrExp = self:GetExp(),
        nNextExp = self:GetNextExp(),
        nStoreExp = self:GetStoreExp(),
        nAtk = self:GetBattleAttr(gtBAT.eGJ),
        eDef = self:GetBattleAttr(gtBAT.eFY),
        nSpeed = self:GetBattleAttr(gtBAT.eSD),
        nMana = self:GetBattleAttr(gtBAT.eLL),
        nPotential = self:GetPotential(),
        tEquipment = self:GetEquipment(),
        nCurrSP = 0,
        nMaxSP = self:GetBattleAttr(gtBAT.eNQ),

        nServerLv = nServerLv,
        nNextServerLvTime = nNextServerLvTime,
        bStuckLevel = self.m_bStuckLevel,
        sGrade = self:GetGrade(),
    }
    self:SendMsg("RoleAttrRet", tMsg)
    -- print("RoleAttrReq***", tMsg)
end

--角色改名请求
function CRole:RoleModNameReq(sName, bProp)
    if sName == "" then
        return
    end
    if self:GetName() == sName then
        return self:Tips("请取不一样的名字")
    end
    if string.len(sName) > gtGDef.tConst.nMaxRoleNameLen then
        return self:Tips("名字长度过长")
    end
    local sData = goDBMgr:GetGameDB(0, "center"):HGet(gtDBDef.sRoleNameDB, sName)
    if sData ~= "" then
        return self:Tips("角色名已被占用")
    end

    local function fnCallback(bRes) 
        bRes = bRes == nil and true or bRes
        if bRes then
            return self:Tips("名字存在非法字")
        end
        local tCostList = {{gtItemType.eProp, nModNameProp, 1}, }
        local fnSubCallback = function(bSucc, nYuanbao) 
            if not bSucc then 
                return 
            end
            local sOldName = self.m_sName
            self.m_sName = sName
            self:MarkDirty(true)
    
            goDBMgr:GetGameDB(0, "center"):HSet(gtDBDef.sRoleNameDB, sName, self:GetID())
            goDBMgr:GetGameDB(0, "center"):HDel(gtDBDef.sRoleNameDB, sOldName)
            self:OnNameChange(sOldName)
            self:SendMsg("RoleModNameRet", {sName=sName})
            goLogger:UpdateRoleLog(self, {rolename=sName})
        end
        self:SubItemByYuanbao(tCostList, "角色改名", fnSubCallback, bProp)
    end
    CUtil:HasBadWord(sName, fnCallback)
end

function CRole:OnNameChange(sOldName)
    self:GlobalRoleUpdate({m_sName=self:GetName()})
    self:FlushRoleView()
end

--角色信息请求
function CRole:RoleInfoReq()
end

--[W]GLOBAL更新角色信息,角色不在线就放到离线数据,上线时处理
function CRole:RoleUpdateReq(nServerID, nRoleID, tData)
    local oRole = goPlayerMgr:GetRoleByID(nRoleID)
    if oRole then
        print("CRole:RoleUpdateReq***在线", nServerID, nRoleID, tData)
        assert(oRole:GetServer() == nServerID, "服务器ID错误")
        oRole:DoRoleUpdate(tData)
    else
        if CUtil:IsRobot(nRoleID) then 
            return 
        end
        print("CRole:RoleUpdateReq***不在线", nServerID, nRoleID, tData)
        local tOffData = COfflineData:LoadKeyData(nServerID, nRoleID, gtOffKeyType.eRoleUpdate) 
        for sKey, xVal in pairs(tData) do
            tOffData[sKey] = xVal
        end
        COfflineData:SaveKeyData(nServerID, nRoleID, gtOffKeyType.eRoleUpdate, tOffData) 
    end
end

--更新角色称谓数据
--tData{nOpType=, nConfID=, tParam=, nSubKey=, sReason=, tExtData=, }
function CRole:AppellationUpdate(tData)
    self.m_oAppellation:Update(tData.nOpType, tData.nConfID, tData.tParam, tData.nSubKey, 
        tData.sReason, tData.tExtData)
end

function CRole:AppellationUpdateReq(nServerID, nRoleID, tData)
    local oRole = goPlayerMgr:GetRoleByID(nRoleID)
    if oRole then
        print("CRole:AppellationUpdate***在线", nServerID, nRoleID, tData)
        assert(oRole:GetServer() == nServerID, "服务器ID错误")
        oRole:AppellationUpdate(tData)
    else
        print("CRole:AppellationUpdate***不在线", nServerID, nRoleID, tData)
        local tOffData = COfflineData:LoadKeyData(nServerID, nRoleID, gtOffKeyType.eAppellation) 
        table.insert(tOffData, tData)
        COfflineData:SaveKeyData(nServerID, nRoleID, gtOffKeyType.eAppellation, tOffData) 
    end
    return true
end


--添加称谓
--sReason和tExtData可以为nil
function CRole:AddAppellation(nConfID, tParam, nSubKey, sReason, tExtData)
    local tAppeData = {}
    tAppeData.nOpType = gtAppellationOpType.eAdd
    tAppeData.nConfID = nConfID
    tAppeData.tParam = tParam or {}
    tAppeData.nSubKey = nSubKey or 0 
    tAppeData.sReason = sReason
    tAppeData.tExtData = tExtData
    self:AppellationUpdate(tAppeData)
    return true
end

--更新称谓属性
function CRole:UpdateAppellation(nConfID, tParam, nSubKey)
    local tAppeData = {}
    tAppeData.nOpType = gtAppellationOpType.eUpdate
    tAppeData.nConfID = nConfID
    tAppeData.tParam = tParam or {}
    tAppeData.nSubKey = nSubKey or 0
    self:AppellationUpdate(tAppeData)
end

--删除称谓
function CRole:RemoveAppellation(nConfID, nSubKey, sReason)
    local tAppeData = {}
    tAppeData.nOpType = gtAppellationOpType.eRemove
    tAppeData.nConfID = nConfID
    tAppeData.tParam = {}
    tAppeData.nSubKey = nSubKey or 0
    tAppeData.sReason = sReason
    self:AppellationUpdate(tAppeData)
end

--请求刷新队伍数据
--bAll 如果在队伍，是否更新整个队伍成员的队伍数据
function CRole:UpdateTeamDataReq(bAll)
    Network:RMCall("WUpdateTeamDataReq", nil, gnWorldServerID, goServerMgr:GetGlobalService(gnWorldServerID, 110), 
        self:GetSession(), self:GetID(), bAll and true or false)
end

--执行角色数据更新
function CRole:DoRoleUpdate(tData)
    local bTeamChange = false
    local bUnionChange = false
    local bFlushSceneView = false
    local bTeamList = false

    for sKey, xVal in pairs(tData) do
        local xOldVal = self[sKey]
        self[sKey] = xVal

        if xOldVal ~= xVal then
            self:MarkDirty(true)
        end

        if sKey == "m_nTeamID" and xOldVal ~= xVal then
            bTeamChange = true
            bFlushSceneView = true
        end

        if sKey == "m_bLeader" and xOldVal ~= xVal then 
            bFlushSceneView = true
        end

        if sKey == "m_nTeamNum" and xOldVal ~= xVal then 
            if tData["m_bLeader"] then 
                bFlushSceneView = true
            end
        end
        
        if sKey == "m_tTeamList" then 
            bTeamList = true
        end

        if sKey == "m_nUnionID" and xOldVal ~= xVal then
            bUnionChange = true
        end

    end

    if bTeamChange then
        self:OnRoleTeamChange()
    end
    if bTeamList then 
        self:OnTeamUpdate()
    end
    if bUnionChange then
        self:OnUnionChange()
    end

    if bFlushSceneView then 
        -- print(string.format("玩家(%d)队伍状态发生变化，刷新外观信息", self:GetID()))
        -- self:Tips(string.format("刷新外观，队伍人数(%d)", self.m_nTeamNum))
        self:FlushRoleView()
    end
end

--队伍列表数据更新
function CRole:OnTeamUpdate()
    self.m_oRoleState:OnTeamUpdate()
end

--帮派发生变化
function CRole:OnUnionChange()
    local oDup = self:GetCurrDupObj()
    if not oDup then return end
    self:FlushRoleView()
end

--队伍发生变化
function CRole:OnRoleTeamChange()
    local oDup = self:GetCurrDupObj()
    if not oDup then return end
    local tConf = oDup:GetConf()
    
    --队伍变化事件(从无队伍变成有队伍,其实就是加入队伍啦)
    if tConf.nBattleType>0 and self:GetTeamID() > 0  then
        oDup:OnTeamChange(self)
    end 

    --退出队伍事件
    if tConf.nBattleType>0 and self:GetTeamID()==0 then
        oDup:OnLeaveTeam(self)
    end
end


--同步主界面人物和宠物信息
function CRole:SyncMainWindowHeadMsg()
    do return end --已屏蔽
    
    local tNewMsg  = {}
    self.m_tHeadMsg = tNewMsg

    tNewMsg.nRoleID = self:GetID()
    tNewMsg.nRoleLv = self:GetLevel()
    tNewMsg.sModule = self:GetConf().sModule
    tNewMsg.nRoleCurrHP = self.m_nCurrHP
    tNewMsg.nRoleMaxHP = self.m_tBattleAttr[gtBAT.eQX]
    tNewMsg.nRoleCurrMP = self.m_nCurrMP
    tNewMsg.nRoleMaxMP = self.m_tBattleAttr[gtBAT.eMF]
    tNewMsg.nRoleCurrSP = 0
    tNewMsg.nRoleMaxSP = self.m_tBattleAttr[gtBAT.eNQ]

    local tPet = self.m_oPet:GetCombatPet()
    if tPet then
        tNewMsg.nPetPos = tPet.nPos
        tNewMsg.nPetID = tPet.nId
        tNewMsg.nPetLv = tPet.nPetLv
        tNewMsg.nPetCurrHP = tPet.nDQBlood
        tNewMsg.nPetMaxHP = tPet.tBaseAttr[gtBAT.eQX]
        tNewMsg.nPetCurrMP = tPet.nDQWorkHard 
        tNewMsg.nPetMaxMP = tPet.tBaseAttr[gtBAT.eMF]
        tNewMsg.nPetCurrExp = tPet.exp
        tNewMsg.nPetNextExp = ctPetLevelConf[tPet.nPetLv].nNeedExp
    end
    self:SendMsg("MainWindowHeadInfoRet", tNewMsg)
end

--角色动作状态变化
function CRole:OnActStateChange(nOldActState)
    -- local nActState = self:GetActState()
    -- if nActState == gtRoleActState.eWedding or
    --     nActState == gtRoleActState.ePalanquinParade or 
    --     nOldActState == gtRoleActState.eWedding or 
    --     nActState == gtRoleActState.ePalanquinParade then
    --     self:FlushRoleView()
    -- end
    self:FlushRoleView()
end

--检测服务器等级变化
function CRole:CheckServerLv()
    if os.Hour(os.time()) == 0 then
        local nCurrServerLv = goServerMgr:GetServerLevel(self:GetServer())
        if nCurrServerLv ~= self.m_nServerLv then
            local nOldServerLv = self.m_nServerLv
            self.m_nServerLv = nCurrServerLv
            self:MarkDirty(true)
            self:OnServerLvChange(nOldServerLv, nCurrServerLv)
        end
    end
end

--服务器等级变化
function CRole:OnServerLvChange(nOldLv, nNewLv)
    self.m_oSysOpen:OnServerLvChange()
end

--整点到时
function CRole:OnHourTimer()
    self:CheckServerLv()
    self.m_oShiMenTask:OnHourTimer()
    self.m_oDailyActivity:OnHourTimer()
    --self.m_oGuaJi:OnHourTimer()
    self.m_oBaoTu:OnHourTimer()
    self.m_oShangJinTask:OnHourTimer()
    self.m_oShiLianTask:OnHourTimer()
    --self.m_oShuangBei:OnHourTimer()
    self.m_oKnapsack:OnHourTimer()
    self.m_oBaHuangHuoZhen:OnHourTimer()
    self.m_oEverydayGift:OnHourTimer()
end

--整分到时
function CRole:OnMinTimer()
    self.m_oDailyActivity:OnMinTimer()
    self.m_oShiZhuang:OnMinTimer()
    self.m_oWGCY:OnMinTimer()
    self.m_oAppellation:OnMinTimer()
    --self.m_oHolidayActMgr:OnMinTimer()
end

function CRole:PushAchieve(sEvent,tData)
    self.m_oAchieve:PushAchieve(sEvent,tData)
end

--人物经验心得使用上限
function CRole:MaxRoleExpProps()
    return 10 --每日最多可使用10次
    -- --20+(服务器等级-40)/5+(服务器等级-人物等级)
    -- local nServerLevel = goServerMgr:GetServerLevel(self:GetServer())
    -- local nMaxNum = math.floor(20+(nServerLevel-40)/5 + math.max(0, nServerLevel-self:GetLevel()))
    -- nMaxNum = math.min(nMaxNum, 50)
    -- return nMaxNum
end

--取人物经验心得已使用个数
function CRole:GetRoleExpProps()
    if not os.IsSameDay(os.time(), self.m_nRoleExpPropTime, 0) then
        self.m_nRoleExpProps = 0
        self.m_nRoleExpPropTime = os.time()
        self:MarkDirty(true)
    end
    return self.m_nRoleExpProps
end

--添加人物经验心得使用个数
function CRole:AddRoleExpProps(nNum)
    if self:GetRoleExpProps() >= self:MaxRoleExpProps() then
        return
    end
    self.m_nRoleExpProps = self.m_nRoleExpProps + nNum
    self:MarkDirty(true)
end

--家园相关
function CRole:GetHouseBattleAttr()
    return self.m_tHouseBattleAttr
end

function CRole:SetHouseBattleAttr(tAttr)
    self:MarkDirty(true)
    self.m_tHouseBattleAttr = tAttr
    self:UpdateAttr()
end

function CRole:CalcHouseScore()
    local nSource = 0
    for nAttrID, nAttrVal in pairs(self.m_tHouseBattleAttr) do
        nSource = nSource + CPropEqu:CalcAttrScore(nAttrID, nAttrVal)
    end
    return nSource
end

function CRole:HouseGiveGiftReq(nRoleID,nPropID,nAmount,bMoneyAdd)
    local nItemID = nPropID
    local nYuanbaoCost = 0
    local nItemCount = nAmount
    local nKeepCount = self:ItemCount(gtItemType.eProp,nItemID)
    if nKeepCount < nItemCount then
        if not bMoneyAdd then
            return self:Tips("礼物不足,无法赠送")
        else
            local nMaterialPrice = math.ceil(ctPropConf[nItemID].nBuyPrice)
            assert(nMaterialPrice > 0, "策划请注意，材料价格不正确，材料ID:"..nItemID)
            nYuanbaoCost = nYuanbaoCost + nMaterialPrice * (nItemCount - nKeepCount)
            nItemCount = nKeepCount
        end
    end

    if nYuanbaoCost > 0 then
        if self:ItemCount(gtItemType.eCurr, gtCurrType.eAllYuanBao) < nYuanbaoCost then
            self:YuanBaoTips()
            return
        end
        self:SubItem(gtItemType.eCurr, gtCurrType.eAllYuanBao, nYuanbaoCost, "家园送礼扣除")
    end

    if nItemCount > 0 then
        self:SubItem(gtItemType.eProp, nItemID, nItemCount, "家园送礼扣除")
    end
    return true
end

function CRole:SetTestMan(nTestMan)
    self.m_nTestMan = nTestMan
end

function CRole:GetTestMan()
    return self.m_nTestMan
end

--更新综合战力到GLOBAL
function CRole:UpdateColligatePower()
    local nColligatePower = self:GetPower()
    nColligatePower = nColligatePower + self.m_oPartner:GetPartnerPowerSum(4) --战力最高的4个仙侣
    nColligatePower = nColligatePower + self.m_oPet:GetPetPowerSum(3) --战力最高的3只宠物
    nColligatePower = math.floor(nColligatePower)
    if self.m_nColligatePower ~= nColligatePower then
        local nOldColligatePower = self.m_nColligatePower
        self.m_nColligatePower = nColligatePower
        self:MarkDirty(true)

        local tData = {}
        tData.nColligatePower = nColligatePower
        CEventHandler:OneColligatePowerChange(self, tData)
        self:GlobalRoleUpdate({m_nColligatePower=nColligatePower})

        print("RoleColligatePowerSyncRet***", nOldColligatePower, nColligatePower)
        self:SendMsg("RoleColligatePowerSyncRet", {nColligatePower=nColligatePower, nDiffVal=nColligatePower-nOldColligatePower})
    end
end


function CRole:GetRoleInfoData()
    local tData = {}   -- itemquery.RoleInfoQueryRet
    tData.nRoleID = self:GetID()
    tData.sName = self:GetName()
    tData.nConfID = self:GetConfID()
    tData.nLevel = self:GetLevel() 
    tData.tEquData = self.m_oKnapsack:GetWearEquData()
    tData.nPower = self:GetPower()
    tData.tShapeData = self:GetShapeData()
    return tData
end


--检测溜掉MarkDirty,很耗性能,只能内网开启
function CRole:CheckDirtySave(sModule, bDirty, tData)
    if not gbDebug or not tData then
        return
    end
    self.m_tLastSaveData = self.m_tLastSaveData or {}
    if bDirty then
        local sData = cjson_raw.encode(tData)
        self.m_tLastSaveData[sModule] = sData
        return
    end
    local sLastData = self.m_tLastSaveData[sModule]
    if not sLastData then
        return
    end
    local sData = cjson_raw.encode(tData)
    local sLastSortedData = CUtil:SortString(sLastData)
    local sSortedData = CUtil:SortString(sData)
    if sSortedData ~= sLastSortedData then
        print(sModule, "=======!!!模块漏了MarkDiry,请通知对应程序排查!!!=======", self:GetID(), self:GetName())
        local sFileName = string.format("../bugsave/%d_%s.log", self:GetID(), sModule)
        io.FilePutContent(sFileName, "last:\n"..sLastData.."\n\ncurrent:\n"..sData, "w")
    end
end

--取各个模块需要在摆摊刷新的道具
--tItemList = {nItemID = nNum}
function CRole:QueryMarketFlushItem()
    local tItemList = {}
    local tList = self.m_oBaHuangHuoZhen:GetCommitItem()
    for nItemID, nNum in pairs(tList) do 
        tItemList[nItemID] = (tItemList[nItemID] or 0) + nNum
    end

    local tList = self.m_oShiLianTask:GetCommitItem()
    for nItemID, nNum in pairs(tList) do 
        tItemList[nItemID] = (tItemList[nItemID] or 0) + nNum
    end

    return tItemList
end

--缓存货币消息
function CRole:CacheCurrMsg(nType, nValue, nValue1, nValue2)
    self.m_tCurrMsgCache[nType] = {nType=nType, nValue=nValue, nValue1=nValue1, nValue2=nValue2}
end

--同步货币消息缓存
function CRole:SyncCurrCachedMsg()
    if not next(self.m_tCurrMsgCache) then
        return
    end
    local tList = {}
    for nType, tSync in pairs(self.m_tCurrMsgCache) do
        table.insert(tList, tSync)
    end
    self:SendMsg("RoleCurrencyRet", {tList=tList})
    self:ClearCurrCachedMsg()
end

--清理货币消息缓存
function CRole:ClearCurrCachedMsg()
    self.m_tCurrMsgCache = {}
end

--设置心跳时间
function CRole:UpdateLastKeepAliveTime(nLastKeepAliveTime)
    self.m_nLastKeepAliveTime = nLastKeepAliveTime
end

--是否活跃角色(战斗中用)
function CRole:IsActiveRole()
    local nLastKeepAliveTime = self.m_nLastKeepAliveTime or os.time()
    if os.time() - nLastKeepAliveTime < 6 then
        self.m_bLastActiveState = true
    else
        self.m_bLastActiveState = false
    end
    return self.m_bLastActiveState
end

--更新开服目标活动数值
function CRole:UpdateGrowthTargetActVal(eActType, nVal)
    if self:IsRobot() or self:IsTempRole() then 
        return 
    end
    local nServer = self:GetServer()
    Network:RMCall("UpdateGrowthTargetActValReq", nil, nServer, goServerMgr:GetGlobalService(nServer, 20), 
        0, self:GetID(), eActType, nVal)
end

--增加开服目标活动数值
function CRole:AddGrowthTargetActVal(eActType, nVal)
    if self:IsRobot() or self:IsTempRole() then 
        return 
    end
    local nServer = self:GetServer()
    Network:RMCall("AddGrowthTargetActValReq", nil, nServer, goServerMgr:GetGlobalService(nServer, 20), 
        0, self:GetID(), eActType, nVal)
end

local tGrowthTargetActTriggerMap = 
{
    [101] = function(oRole) oRole:UpdateActGTEquStrength() end,
    [102] = function(oRole) oRole:UpdateActGTPetPower() end,
    [103] = function(oRole) oRole:UpdateActGTPartnerPowerSum() end,
    [104] = function(oRole) oRole:UpdateActGTFormationLv() end,
    [105] = function(oRole) oRole:UpdateActGTEquGemLv() end,
    [106] = function(oRole) oRole:UpdateActGTMagicEquPower() end,
    [107] = function(oRole) oRole:UpdateActGTDrawSpiritLv() end,
    [108] = function(oRole) oRole:UpdateActGTPetSkillPower() end,
    [109] = function(oRole) oRole:UpdateActGTPricticeLv() end,
    [110] = function(oRole) oRole:UpdateActGTGodEquPower() end,
    [115] = function(oRole) oRole:UpdateActGTDressPower() end,
}

function CRole:TriggerGrowthTargetActData(tActList)   
    for _, nActID in pairs(tActList) do 
        local fnTrigger = tGrowthTargetActTriggerMap[nActID]
        if fnTrigger then 
            fnTrigger(self)
        end
    end
end

--开服目标活动 装备强化
function CRole:UpdateActGTEquStrength() 
	local nWearStrengthLevel = self.m_oKnapsack:GetWearStrengthLevel()
	self:UpdateGrowthTargetActVal(101, nWearStrengthLevel)
end

--开服目标活动 宠物战力
--按自己战力最高的宠物的战力为积分参数计算
function CRole:UpdateActGTPetPower()
    local nPetPower = self.m_oPet:GetMaxPetPower()
    self:UpdateGrowthTargetActVal(102, nPetPower)
end

--开服目标活动 仙侣总战力
function CRole:UpdateActGTPartnerPowerSum()
    local nPowerSum = self.m_oPartner:GetAllPartnerPowerSum()
    self:UpdateGrowthTargetActVal(103, nPowerSum)
end

--开服目标活动 阵法等级
function CRole:UpdateActGTFormationLv()
    local nLvSum = self.m_oFormation:GetLvSum()
    self:UpdateGrowthTargetActVal(104, nLvSum)
end

--开服目标活动 装备宝石总等级
function CRole:UpdateActGTEquGemLv()
    local nGemLv = self.m_oKnapsack:GetWearGemLevel()
    self:UpdateGrowthTargetActVal(105, nGemLv)
end

--开服目标活动 法宝总战力
--按法宝总战力为积分参数计算(不含神器)
function CRole:UpdateActGTMagicEquPower()
    local nPowerSum = self.m_oFaBao:GetSumFaBaoScore()
    self:UpdateGrowthTargetActVal(106, nPowerSum)
end

--开服目标活动 摄魂等级
function CRole:UpdateActGTDrawSpiritLv()
    local nLv = self.m_oDrawSpirit:GetSpiritLevel()
    self:UpdateGrowthTargetActVal(107, nLv)
end

--开服目标活动 宠物技能战力
--按宠物技能（包括护符）的战力为积分参数计算
function CRole:UpdateActGTPetSkillPower()
    local nPower = self.m_oPet:GetMaxPetSkillPower()
    self:UpdateGrowthTargetActVal(108, nPower)
end

--开服目标活动 修炼进阶
function CRole:UpdateActGTPricticeLv()
    local nLv = self.m_oPractice:GetLvSum()
    self:UpdateGrowthTargetActVal(109, nLv)
end

--开服目标活动 神器战力
function CRole:UpdateActGTGodEquPower()
    local nVal = self.m_oArtifact:CalcAttrScore()
    self:UpdateGrowthTargetActVal(110, nVal)
end

--开服目标活动 挖宝积分
function CRole:AddActGTTreasureSearchScore(nVal)
    self:AddGrowthTargetActVal(111, nVal)
end

--开服目标活动 摄魂灵气积分
function CRole:AddActGTDrawSpiritScore(nVal)
    self:AddGrowthTargetActVal(114, nVal)
end

--开服目标活动 时装总战力
function CRole:UpdateActGTDressPower()
    local nVal = self.m_oShiZhuang:CalcAttrScore()
    self:UpdateGrowthTargetActVal(115, nVal)
end
