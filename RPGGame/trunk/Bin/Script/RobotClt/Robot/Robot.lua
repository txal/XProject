function CRobot:Ctor(nSessionID, sRobotName)
    self.m_nLastKeepAlive = os.time()
	self.m_nSessionID = nSessionID
    self.m_sName = sRobotName

    self.m_bLogged = false
    self.m_bEnterScene = false
    self.m_bStartRun = false

    self.m_nLoginTime = 0
    self.m_nLastSendTime = 0
    self.m_nMsgInterval = math.random(3, 9)

    self.m_nStartRunTime = 0
    self.m_nStopRunTime = 0
end

function CRobot:GetSession()
	return self.m_nSessionID
end

function CRobot:GenPacketIdx()
    local oCppRobot = goCppRobotMgr:GetRobot(self.m_nSessionID)
    if oCppRobot then
        return oCppRobot:GenPacketIdx()
    end
end

function CRobot:GetPos()
    local oCppRobot = goCppRobotMgr:GetRobot(self.m_nSessionID)
    if oCppRobot then
        return oCppRobot:GetPos()
    end
    return 0, 0
end

function CRobot:GetName()
    return self.m_sName
end

function CRobot:IsLogged()
    return self.m_bLogged
end

function CRobot:Release()
    self.m_bLogged = false
	if self.m_nTimer then
		GlobalExport.CancelTimer(self.m_nTimer)
        self.m_nTimer = nil
	end
end

function CRobot:Update()
    self:KeepAlive()
    self:RandomMsg()
end

function CRobot:CheckRun()
    if not self.m_bLogged or not self.m_bEnterScene then
        return
    end
    local oCppRobot = goCppRobotMgr:GetRobot(self.m_nSessionID)
    if not oCppRobot then
        return
    end
    if not self.m_bStartRun then
        return oCppRobot:StopRun()
    end
    local nTimeNow = os.time()
    if nTimeNow - self.m_nStartRunTime > 6 then
        self.m_nStartRunTime = nTimeNow
        local nDir = math.random(0, 7)
        oCppRobot:StartRun(nDir)
    end
end

function CRobot:KeepAlive()
    local nTimeNow = os.time()
    if nTimeNow - self.m_nLastKeepAlive >= 10 then
        self.m_nLastKeepAlive = nTimeNow
        CmdNet.Clt2Srv(self:GenPacketIdx(), self.m_nSessionID, "KeepAlive", nTimeNow)
    end
end

function CRobot:Login()
    self.m_nLoginTime = os.clock()
    CmdNet.PBClt2Srv(self:GenPacketIdx(), self.m_nSessionID, "LoginReq", {sAccount=self.m_sName, sPassword="11", nSource=0})
end

function CRobot:OnLoginRet(nRes)
    if nRes == -1 then
        CmdNet.PBClt2Srv(self:GenPacketIdx(), self.m_nSessionID, "CreateRoleReq", {sAccount=self.m_sName, sPassword="11", sCharName=self.m_sName, nSource=0})

    --登陆成功
    elseif nRes == 0 then
        goRobotMgr:OnLoginSucc(self.m_sName, os.clock() - self.m_nLoginTime)
        self.m_nTimer = GlobalExport.RegisterTimer(1000, function() self:Update() end)
        self.m_bLogged = true
        self.m_nLoginTime = os.time()
        self.m_nLastSendTime = 0
    end
end

function CRobot:OnCreateRoleRet(nRes)
    print("CRobot:OnCreateRoleRet***", nRes)
    if nRes == -1 then
        print("角色名重复:", self.m_sName)
    elseif nRes == -2 then
        print("角色已存在:", self.m_sName)
    elseif nRes == 0 then
        print("CRobot:", self.m_sName.." 创建角色成功")
        self:Login()
    end
end

function CRobot:OnEnterScene(tData)
    local oCppRobot = goCppRobotMgr:GetRobot(self.m_nSessionID)
    local nPosX, nPosY = tData.nPosX, tData.nPosY 
    local tSceneConf = ctSceneConf[tData.nSceneID]
    oCppRobot:SetMapID(tSceneConf.nMapID)
    oCppRobot:SetName(self.m_sName)
    oCppRobot:SetPos(nPosX, nPosY)
    self.m_bEnterScene = true
    print(self.m_sName, " enter scene")
end

function CRobot:StartRun()
    self.m_bStartRun = not self.m_bStartRun
end

local tProtoList = {
    {"PlayerInfoReq", {}},
    {"PlayerModNameReq", {}},
    {"MCUpgradeReq", {nID=10001}},
    {"MCAdvanceReq", {nID=10001, bYuanBao=false}},
    {"SKUpgradeReq", {nMCID=10001, nSKID=1}},
    {"SKOneKeyUpgradeReq", {nMCID=10001, nSKID=1}},
    {"SKAdvanceReq", {nMCID=10001, nSKID=1}},
    {"GiveTreasureReq", {nID=10001, nPropID=31000, nPropNum=1}},
    {"MCTrainReq", {nID=10001}},
    {"QuaBreachReq", {nMCID=10001, nQuaID=1}},
    {"MCRecruitReq", {nID=10001}},
    {"MCRecruitListReq", {}},
    {"GLRankingReq", {nRankNum=100}},
    {"GLRankingMoBaiReq", {}},
    {"MCFengGuanReq", {nMCID=10001}},
    {"FZRuGongReq", {nID=50004}},
    {"FZModNameReq", {nID=50004, sName="FZRobot"}},
    {"FZModDescReq", {nID=50004, sDesc="FZRobot"}},
    {"FZUpgradeStarReq", {nID=50004}},
    {"FZLearnReq", {nID=50004}},
    {"FZUpFeiWeiReq", {nID=50004}},
    {"FZNaShaReq", {nID=50004,nTimes=1,bUseProp=false}},
    {"FZGiveTreasureReq", {nID=50004, nPropID=32000, nPropNum=1}},
    {"JZListReq", {}},
    {"JZUpgradeReq", {nID=1}},
    {"JZRankingReq", {nRankNum=100}},
    {"FZQingAnReq", {bUseProp=false}},
    {"JSFInfoReq", {}},
    {"JSFOpenGridReq", {nGridID=2}},
    {"JSFOpenCardReq", {nGridID=1}},
    {"JSFFinishReq", {nGridID=1}},
    {"LGInfoReq", {}},
    {"LGOpenGridReq", {}},
    {"LGPutFZReq", {nFZID=50004}},
    {"LGCallFZReq", {nFZID=50004}},
    {"CXGInfoReq", {}},
    {"CXGDrawReq", {nDrawType=1, bUseProp=false}},
    {"CXGShiFengReq", {nGNID=50200, nFZID=50004}},
    {"GuoKuSellItemReq", {nGrid=1, nNum=1}},
    {"GuoKuUseItemReq", {nGrid=1, nNum=2}},
    {"GuoKuComposeReq", {nID=30511}},
    {"ChapterInfoReq", {}},
    {"DupInfoReq", {}},
    {"BattleReq", {}},
    {"DupRankingReq", {nRankNum=100}},
    {"NeiGeInfoReq", {}},
    {"NeiGeUpgradeReq", {nType=1, bProp=false}},
    {"NeiGeCollectReq", {nType=1}},
    {"NeiGeOneKeyCollectReq", {}},
    {"NeiGeCancelCDReq", {nType=1}},
    {"NeiGeRecruitingReq", {}},
    {"LFYInfoReq", {}},
    {"LFYUpgradeReq", {}},
    {"LFYOneKeyUpgradeReq", {}},
    {"HZListReq", {}},
    {"HZModNameReq", {nID=1, sName="HZRobot"}},
    {"HZSpeedGrowUpReq", {nID=1, nPropID=33000, nPropNum=1}},
    {"HZUpLearnEffReq", {nID=1}},
    {"HZLearnReq", {nID=1, bUseProp=false}},
    {"HZFengJueReq", {nID=1}},
    {"HZUnmarriedListReq", {}},
    {"HZMarriedListReq", {}},
    {"LYListReq", {}},
    {"LYPlayerSendReq", {nHZID=1, nTarCharID=1, nCostType=2}},
    {"LYServerSendReq", {nHZID=1, nCostType=2}},
    {"LYCancelReq", {nHZID=1}},
    {"LYRejectReq", {nTarCharID=1, nTarHZID=2}},
    {"LYAgreeReq", {nSrcHZID=1, nTarCharID=1, nTarHZID=1, nCostType2}},
    {"LYHZMatchListReq", {nTarCharID=1, nTarHZID=1}},
    {"HZRankingReq", {nRankNum=100}},
    {"HZOpenGridReq", {}},
    {"ZZZouZhangReq", {}},
    {"ZZInfoReq", {}},
    {"ZZAwardReq", {nSelect=1}},
    {"MailListReq", {}},
    {"MailBodyReq", {nMailID=1}},
    {"DelMailReq", {nMailID=1}},
    {"MailItemsReq", {nMailID=1}},
    -- {"TalkReq", {nChannel=2, sCont="呵呵呵呵呵"}},
    {"SLRankingReq", {nRankNum=100}},
    {"QMRankingReq", {nRankNum=100}},
    {"NLRankingReq", {nRankNum=100}},
    {"CDRankingReq", {nRankNum=100}},
    {"QingAnZheReq", {}},
    {"QAZInfoReq", {}},
    {"WFSFInfoReq", {}},
    {"XXunFangReq", {bUseProp=false}},
    {"XXunFangAwardReq", {nSelect=1}},
    {"XXunBaoReq", {}},
    {"MainTaskListReq", {}},
    {"DailyTaskListReq", {}},
    {"MainTaskAwardReq", {nID=1}},
    {"DailyTaskAwardReq", {nID=1}},
    {"CompleteTaskReq", {nID=1}},
    {"UnionDetailReq", {}},
    {"UnionListReq", {}},
    {"ApplyUnionReq", {}},
    {"CreateUnionReq", {}},
    {"ExitUnionReq", {}},
    {"SetAutoJoinReq", {}},
    {"SetUnionDeclReq", {}},
    {"ApplyListReq", {}},
    {"AcceptApplyReq", {}},
    {"RefuseApplyReq", {}},
    {"MemberListReq", {}},
    {"KickUnionMemberReq", {}},
    {"AppointReq", {}},
    {"UnionUpgradeReq", {}},
    {"MemberDetailReq", {}},
    {"JoinRandUnionReq", {}},
    {"UnionBuildInfoReq", {}},
    {"UnionBuildReq", {}},
    {"UnionExchangeListReq", {}},
    {"UnionExchangeReq", {}},
    {"UnionPartyListReq", {}},
    {"UnionPartyRankingReq", {}},
    {"UnionPartyOpenReq", {}},
    {"UnionPartyFZListReq", {}},
    {"UnionPartyAddFZReq", {}},
    {"UnionPartyRemoveFZReq", {}},
    {"UnionPartyStartBattleReq", {}},
    {"UnionMiracleListReq", {}},
    {"UnionMiracleDonateReq", {}},
    {"UnionDonateDetailReq", {}},
    {"UGLRankingReq", {}},
    {"JJCInfoReq", {}},
    {"JJCAddMCReq", {}},
    {"JJCRemoveMCReq", {}},
    {"JJCSendReq", {}},
    {"JJCExtraRobReq", {}},
    {"JJCZhaoJianListReq", {}},
    {"JJCChouHenListReq", {}},
    {"JJCAttackReq", {}},
    {"JJCTongJiListReq", {}},
    {"JJCRankTongJiListReq", {}},
    {"JJCPlayerTongJiReq", {}},
    {"WWRankingReq", {}},
    {"ZJRankingReq", {}},
    {"JJCNoticeListReq", {}},
    {"QDInfoReq", {}},
    {"QDAwardReq", {}},
    {"CZDQInfoReq", {}},
    {"CZDQUseXFReq", {}},
    {"CZDQReportYinLiangReq", {}},
    {"CZDQRankingReq", {}},
    {"CZDQOffInterfaceReq", {}},
    {"VIPAwardListReq", {}},
    {"VIPAwardReq", {}},
    {"RechargeListReq", {}},
    {"HBInfoReq", {}},
    {"HBInActivityReq", {}},
    {"HBRankingReq", {}},
    {"HBGetAwardReq", {}},
    {"DayRechargeStateReq", {}},
    {"DayRechargeInfoReq", {}},
    {"DayRechargeAwardReq", {}},
    {"WeekRechargeInfoReq", {}},
    {"WeekRechargeAwardReq", {}},
    {"TimeMallInfoReq", {}},
    {"TimeMallBuyReq", {}},
    {"TimeGiftStateReq", {}},
    {"TimeGiftBuyReq", {}},
    {"LeiDengStateReq", {}},
    {"LeiDengInfoReq", {}},
    {"LeiDengAwardReq", {}},
    {"TimeAwardStateReq", {}},
    {"TimeAwardProgressReq", {}},
    {"TimeAwardRankingReq", {}},
    {"TimeAwardAwardReq", {}},
    {"WaBaoStateReq", {}},
    {"WaBaoPropListReq", {}},
    {"WaBaoBuyPropReq", {}},
    {"WaBaoUsePropReq", {}},
    {"WaBaoAwardInfoReq", {}},
    {"WaBaoAwardReq", {}},
    {"WaBaoExchangeListReq", {}},
    {"WaBaoExchangeReq", {}},
    {"WaBaoRankingReq", {}},
    {"WaBaoRankAwardInfoReq", {}},
    {"WaBaoRankAwardReq", {}},
}
function CRobot:RandomMsg()
    if not self.m_bStartRun then
        return
    end
    if os.time() - self.m_nLastSendTime < self.m_nMsgInterval then
        return
    end
    self.m_nLastSendTime = os.time()

    local tProto = tProtoList[math.random(#tProtoList)]
    CmdNet.PBClt2Srv(self:GenPacketIdx(), self.m_nSessionID, tProto[1], tProto[2])
end

