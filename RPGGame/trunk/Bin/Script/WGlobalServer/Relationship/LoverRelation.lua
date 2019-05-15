--情缘系统
local table, string, math, os, pairs, ipairs, assert = table, string, math, os, pairs, ipairs, assert

--和夫妻关系冲突，如果存在夫妻关系，则无法结成情缘
--反之，如果当前是情缘关系，则允许结成夫妻关系


function CLover:Ctor(nRoleID, nTimeStamp, nSerialID)
    self.m_nRoleID = nRoleID
    self.m_nTimeStamp = nTimeStamp or os.time()
    self.m_nSerialID = nSerialID or 0
end

function CLover:LoadData(tData)
    if not tData then 
        return 
    end
    self.m_nTimeStamp = tData.nTimeStamp
    self.m_nSerialID = tData.nSerialID or self.m_nSerialID
end

function CLover:SaveData()
    local tData = {}
    tData.nRoleID = self.m_nRoleID
    tData.nTimeStamp = self.m_nTimeStamp
    tData.nSerialID = self.m_nSerialID
    return tData
end

function CLover:GetLoverID() return self.m_nRoleID end
function CLover:GetID() return self:GetLoverID() end
function CLover:GetSerialID() return self.m_nSerialID end
function CLover:SetSerialID(nSerialID) 
    assert(nSerialID > 0)
    self.m_nSerialID = nSerialID 
end

-------------------------------------------------------------
function CRoleLover:Ctor(nRoleID)
    self.m_nRoleID = nRoleID
    self.m_tLoverList = {}       -- {nRoleID:CLover, ...}
    self.m_nLastRemoveStamp = 0
    self.m_bDirty = false
end

function CRoleLover:LoadData(tData)
    if not tData then 
        return 
    end
    for k, v in pairs(tData.tLoverList) do
        local oLover = CLover:new(k, 0)
        oLover:LoadData(v)
        if oLover:GetSerialID() <= 0 then --兼容下旧数据
            oLover:SetSerialID(goLoverRelationMgr:GenID())
            self:MarkDirty(true)
        end
        self.m_tLoverList[k] = oLover
    end
    self.m_nLastRemoveStamp = tData.nLastRemoveStamp
end

function CRoleLover:SaveData()
    local tData = {}
    tData.nRoleID = self.m_nRoleID
    tData.tLoverList = {}
    for k, v in pairs(self.m_tLoverList) do 
        local tTempData = v:SaveData()
        tData.tLoverList[k] = tTempData
    end
    tData.nLastRemoveStamp = self.m_nLastRemoveStamp
    return tData
end

function CRoleLover:MarkDirty(bDirty) 
    self.m_bDirty = bDirty
    if self.m_bDirty then
        goLoverRelationMgr.m_tDirtyQueue:Push(self.m_nRoleID, self)
    end
end
function CRoleLover:IsDirty() return self.m_bDirty end
function CRoleLover:GetID() return self.m_nRoleID end
function CRoleLover:GetLover(nTarID) return self.m_tLoverList[nTarID] end
function CRoleLover:AddLover(nTarID, nTimeStamp, nSerialID)
    assert(nTarID > 0 and nTarID ~= self.m_nRoleID, "参数错误")
    if self:GetLover(nTarID) then
        assert(false, "情缘已经存在")
    end
    local oRole = goGPlayerMgr:GetRoleByID(self:GetID())
    local oTarRole = goGPlayerMgr:GetRoleByID(nTarID)
    assert(oRole and oTarRole)

    local oLover = CLover:new(nTarID, nTimeStamp, nSerialID)
    self.m_tLoverList[nTarID] = oLover
    self:MarkDirty(true)

    local nAppeID = gtAppellationIDDef.eLover
    oRole:AddAppellation(nAppeID, {tNameParam={oTarRole:GetName()}}, oTarRole:GetID())

    goLoverRelationMgr:SyncLogicCache(self:GetID())
    return oLover
end
function CRoleLover:RemoveLover(nTarID, bActive)
    if not self:GetLover(nTarID) then
        return
    end
    self.m_tLoverList[nTarID] = nil 
    if bActive then
        self.m_nLastRemoveStamp = os.time()
    end
    self:MarkDirty(true)

    local oRole = goGPlayerMgr:GetRoleByID(self:GetID())
    assert(oRole)
	local nAppeID = gtAppellationIDDef.eLover
    oRole:RemoveAppellation(nAppeID, nTarID)
    goLoverRelationMgr:SyncLogicCache(self:GetID())
end

function CRoleLover:GetLoverCount()
    local nCount = 0
    for k, v in pairs(self.m_tLoverList) do
        nCount = nCount + 1
    end 
    return nCount
end

function CRoleLover:GetLoverList()
    local tData = {}
    if self:GetLoverCount() > 0 then 
        for k, v in pairs(self.m_tLoverList) do 
            table.insert(tData, v)
        end
        local fnCmp = function(tL, tR) 
            if tL.m_nTimeStamp <= tR.m_nTimeStamp then 
                return false
            else
                return true 
            end
        end
        table.sort(tData, fnCmp) --按情缘时间排序
    end
    return tData
end

function CRoleLover:GetTimeLimitCountdown(nTimeStamp)
    if self.m_nLastRemoveStamp == 0 then
        return 0
    end
    nTimeStamp = nTimeStamp or os.time()
    local nCountdown = 0
    local nExpiryTime = self.m_nLastRemoveStamp + 24*36000

    if nTimeStamp < nExpiryTime then
        nCountdown = nExpiryTime - nTimeStamp
    end
    return nCountdown
end

function CRoleLover:IsTimeLimit(nTimeStamp)
    nTimeStamp = nTimeStamp or os.time()
    if math.abs(nTimeStamp - self.m_nLastRemoveStamp) >= 24*3600 then 
        return false 
    end
    return true 
end

function CRoleLover:GetPBData()
    local tRetData = {}
--[[     //情缘对象数据
    message LoverData
    {
        required int32 nRoleID = 1;          //玩家ID
        required string sName = 2;           //名字
        required string sHeader = 3;         //头像
        required int32 nGender = 4;          //性别
        required int32 nSchool = 5;          //门派
        required int32 nLevel = 6;           //等级
        required int32 nTimeStamp = 7;       //情缘时间戳
    }
    
    //玩家情缘数据响应
    message LoverInfoRet
    {
        repeated BrotherData tLoverList = 1;     //情缘列表
        optional int32 nLimitTimeCountdown = 2;  //情缘限制倒计时
    } ]]
    tRetData.tLoverList = {}
    for k, oLover in pairs(self.m_tLoverList) do
        local oTarRole = goGPlayerMgr:GetRoleByID(k)
        if oTarRole then  
            local tLoverData = {}
            tLoverData.nRoleID = k 
            tLoverData.sName = oTarRole:GetName()
            tLoverData.sHeader = oTarRole:GetHeader()
            tLoverData.nGender = oTarRole:GetGender()
            tLoverData.nSchool = oTarRole:GetSchool()
            tLoverData.nLevel = oTarRole:GetLevel()
            tLoverData.nTimeStamp = oLover.m_nTimeStamp
            table.insert(tRetData.tLoverList, tLoverData)
        end
    end
    tRetData.nLimitTimeCountdown = self:GetTimeLimitCountdown()
    return tRetData
end

-------------------------------------------------------------
function CLoverRelationMgr:Ctor()
    self.m_nSerialNum = 0
    self.m_tRoleMap = {}    -- {nRoleID:RoleLoverData, ...}
    self.m_tDirtyQueue = CUniqCircleQueue:new()
    self.m_nSaveTimer = nil
    self.m_bDirty = false
end

function CLoverRelationMgr:Init()
    self.m_nSaveTimer = goTimerMgr:Interval(60, function ()  self:SaveData() end) 
    self:LoadData()
end

function CLoverRelationMgr:OnRelease()
    goTimerMgr:Clear(self.m_nSaveTimer)
    self.m_nSaveTimer = nil
    self:SaveData()
end

function CLoverRelationMgr:IsDirty()
    return self.m_bDirty
end

function CLoverRelationMgr:MarkDirty(bDirty)
    self.m_bDirty = bDirty and true or false
end

function CLoverRelationMgr:LoadSysData() 
    local oDB = goDBMgr:GetSSDB(gnServerID, "global", GF.GetServiceID())
	local sData = oDB:HGet(gtDBDef.sLoverSysDB, "loversysdata")
	if sData ~= "" then
		local tData = cjson.decode(sData)
		self.m_nSerialNum = tData.nSerialNum or self.m_nSerialNum
	end
end

function CLoverRelationMgr:LoadData()
    self:LoadSysData()
    local oDB = goDBMgr:GetSSDB(gnServerID, "global", GF.GetServiceID())
	local tKeys = oDB:HKeys(gtDBDef.sRoleLoverDB)
	for _, sRoleID in ipairs(tKeys) do
		local sData = oDB:HGet(gtDBDef.sRoleLoverDB, sRoleID)
		local tData = cjson.decode(sData)
		local nRoleID = tData.nRoleID
        local oLoverData = CRoleLover:new(nRoleID)
		oLoverData:LoadData(tData)
		self.m_tRoleMap[nRoleID] = oLoverData
	end
end

function CLoverRelationMgr:SaveSysData() 
    if not self:IsDirty() then 
        return 
    end
    local tData = {}
    tData.nSerialNum = self.m_nSerialNum
    local oDB = goDBMgr:GetSSDB(gnServerID, "global", GF.GetServiceID())
    oDB:HSet(gtDBDef.sLoverSysDB, "loversysdata", cjson.encode(tData))
    
    self:MarkDirty(false)
end

function CLoverRelationMgr:SaveData()
    self:SaveSysData()
    local nDirtyNum = self.m_tDirtyQueue:Count()
	if nDirtyNum < 1 then
		return
	end
	local oDB = goDBMgr:GetSSDB(gnServerID, "global", GF.GetServiceID())
	for i = 1, nDirtyNum do
		local oLoverData = self.m_tDirtyQueue:Head()
		if oLoverData then
			local tData = oLoverData:SaveData()
			oDB:HSet(gtDBDef.sRoleLoverDB, oLoverData:GetID(), cjson.encode(tData))
			oLoverData:MarkDirty(false)
        end
        self.m_tDirtyQueue:Pop()
	end
end

function CLoverRelationMgr:GenID()
    self.m_nSerialNum = self.m_nSerialNum % 0x7fffffff + 1
    self:MarkDirty(true)
    return self.m_nSerialNum
end

function CLoverRelationMgr:GetRoleLoverData(nRoleID) return self.m_tRoleMap[nRoleID] end

--是否情缘关系
function CLoverRelationMgr:IsLover(nRoleID, nTarID)
    local oLover = self:GetLoverByRole(nRoleID, nTarID)
    local oTarLover = self:GetLoverByRole(nTarID, nRoleID)
    if oLover or oTarLover then 
        return true
    end
    return false
end

--获取玩家之间的情缘关系
function CLoverRelationMgr:GetLoverByRole(nRoleID, nTarID)
    assert(nRoleID and nTarID and nRoleID ~= nTarID, "参数错误")
    local oRoleLoverData = self:GetRoleLoverData(nRoleID)
    if not oRoleLoverData then 
        return 
    end
    return oRoleLoverData:GetLover(nTarID)
end

function CLoverRelationMgr:OnRoleOnline(oRole)
    if oRole:IsRobot() then 
        return 
    end
    local nRoleID = oRole:GetID()
    local oRoleLoverData = self:GetRoleLoverData(nRoleID)
    if not oRoleLoverData then 
        local oRoleLoverData = CRoleLover:new(nRoleID)
        self.m_tRoleMap[nRoleID] = oRoleLoverData
        oRoleLoverData:MarkDirty(true)
    end
    self:SyncLogicCache(nRoleID)
end

function CLoverRelationMgr:OnRoleOffline(oRole) 
    local oRoleLoverData = self:GetRoleLoverData(oRole:GetID())
    if not oRoleLoverData then 
        return 
    end
    -- do something
end

--检查结成情缘关系条件
function CLoverRelationMgr:CheckBeLover(oRole, nTarID)
    assert(nTarID and nTarID > 0, "数据错误")
	local oTarRole = goGPlayerMgr:GetRoleByID(nTarID)
    assert(oTarRole, "数据错误")
    
    local nRoleID = oRole:GetID()
    local bResult = false 
    local tCheckList = 
    {
        bOnline = true,      --两人同时在线
        bLevel = true,       --等级>=40级
        bLover = true,       --双方之间没有结成情缘关系，且24小时内没有解除过情缘关系
        bFriend = true,      --双方互为好友，且亲密度>=700
        --bMoney = true,       --队长持有1万金币
        bLoverMax = true,    --双方情缘对象数量没有达到3人
        bGender = true,      --双方是异性别角色，且双方不是夫妻
    }

	if not oRole:IsOnline() or not oTarRole:IsOnline() then 
		tCheckList.bOnline = false
	end

    --检查ID
	if nRoleID == nTarID then
		oRole:Tips("不能和自己情缘")
		for k, v in pairs(tCheckList) do
			tCheckList[k] = false
        end
		return bResult, tCheckList
    end

    --检查等级
	if not (oRole:GetLevel() >= 40 and oTarRole:GetLevel() >= 40) then
		tCheckList.bLevel = false
    end
    
    if GF.IsRobot(nRoleID) or GF.IsRobot(nTarID) then 
        tCheckList.bFriend = false
        tCheckList.bLover = false 
        tCheckList.bLoverMax = false
    else
        --检查好友关系及亲密度
        local oRoleFriend = goFriendMgr:GetFriend(nRoleID, nTarID)
        local oTarFriend = goFriendMgr:GetFriend(nTarID, nRoleID)
        if not oRoleFriend or not oTarFriend then
            tCheckList.bFriend = false	
        else
            if oRoleFriend:GetDegrees() < 700 or oTarFriend:GetDegrees() < 700 then
                tCheckList.bFriend = false
            end
        end
        
        --检查情缘关系
        if self:IsLover(nRoleID, nTarID) then 
            tCheckList.bLover = false 
        end
        local oRoleLoverData = self:GetRoleLoverData(nRoleID)
        local oTarLoverData = self:GetRoleLoverData(nTarID)
        assert(oRoleLoverData and oTarLoverData, "数据错误")
        if oRoleLoverData:IsTimeLimit() or oTarLoverData:IsTimeLimit() then
            tCheckList.bLover = false 
        end

        if oRoleLoverData:GetLoverCount() >= 3 
            or oTarLoverData:GetLoverCount() >= 3 then
            tCheckList.bLoverMax = false
        end 
    end
    
    --检查性别
	local tRoleConf = oRole:GetConf()
	local tTarConf = oTarRole:GetConf()
	if tRoleConf.nGender == tTarConf.nGender then
		tCheckList.bGender = false
    end

    --检查是否是夫妻关系
    if goMarriageMgr:IsCouple(nRoleID, nTarID) then 
        tCheckList.bGender = false
    end

    bResult = true
	for k, v in pairs(tCheckList) do
		if v == false then
			bResult = false
			break
		end
    end
    
    return bResult, tCheckList
end

function CLoverRelationMgr:LoverTogetherCheckReq(oRole, nTarRoleID)
    if not nTarRoleID or nTarRoleID <= 0 then 
        return 
    end
    local oTarRole = goGPlayerMgr:GetRoleByID(nTarRoleID)
    if not oTarRole then 
        return 
    end
    local bResult, tCheckList = self:CheckBeLover(oRole, nTarRoleID)
    local tRetData = {}
    tRetData.nTarRoleID = nTarRoleID
    tRetData.bOnline = tCheckList.bOnline
    tRetData.bLevel = tCheckList.bLevel
    tRetData.bLover = tCheckList.bLover
    tRetData.bFriend = tCheckList.bFriend
    tRetData.bLoverMax = tCheckList.bLoverMax
    tRetData.bGender = tCheckList.bGender
    oRole:SendMsg("LoverTogetherCheckRet", tRetData)
end

--结成情缘
function CLoverRelationMgr:BeLover(nRoleID, nTarID, nSerialID) 
    if nRoleID == nTarID then
        return 
    end
    local oRoleData = self:GetRoleLoverData(nRoleID)
    local oTarData = self:GetRoleLoverData(nTarID)
    if not oRoleData or not oTarData then 
        return 
    end
    local nTimeStamp = os.time()
    oRoleData:AddLover(nTarID, nTimeStamp, nSerialID)
    oTarData:AddLover(nRoleID, nTimeStamp, nSerialID)
    return true
end

function CLoverRelationMgr:IsSysOpen(oRole, bTips)
    if not oRole then 
        return false 
    end
    return oRole:IsSysOpen(60, bTips)
end

--请求成为情缘
function CLoverRelationMgr:BeLoverReq(oRole, nTarID)
    local nRoleID = oRole:GetID()
    local oTarRole = goGPlayerMgr:GetRoleByID(nTarID)
    if not oTarRole then
        print("目标玩家不存在,玩家ID:"..nTarID)
        return
    end

    local bValid, tCheckList = self:CheckBeLover(oRole, nTarID)
    if not bValid then 
        return oRole:Tips("结成情缘条件不满足")
    end
    if not self:IsSysOpen(oRole,true) then 
        oTarRole:Tips("对方功能未开启")
        return 
    end
    if not self:IsSysOpen(oTarRole, true) then 
        oRole:Tips("对方功能未开启")
        return 
    end
    if not oTarRole:IsOnline() then
        return oRole:Tips("对方已经离线，无法结成情缘")
    end

    local fnConfirmCallback = function (tData)
        if not tData then 
            oRole:Tips("对方婉拒了你的请求")
			return
        end
        if tData.nSelIdx == 1 then  --拒绝
            oRole:Tips("对方婉拒了你的请求")
			return
        elseif tData.nSelIdx == 2 then  --确定
            local tCost = {nType = gtItemType.eCurr, nID = gtCurrType.eJinBi, nNum = 10000}
            local fnSubCallback = function (bRet)
                if not bRet then
                    return
                end
                --已经结为情缘了的，加一层保护 可能连续重复点击导致
                if self:GetLoverByRole(nRoleID, nTarID) then 
                    oRole:AddItem(tCost, "情缘回滚")
                    return oRole:Tips(string.format("你和%s已经结为情缘了，不可重复申请", 
                        oTarRole:GetName()))
                end
                local nSerialNum = self:GenID()
                if not self:BeLover(nRoleID, nTarID, nSerialNum) then
                    return 
                end
                oRole:Tips(string.format("和%s结成情缘成功", oTarRole:GetName()))
                oTarRole:Tips(string.format("和%s结成情缘成功", oRole:GetName()))
                self:SyncLoverData(oRole)
                self:SyncLoverData(oTarRole)

                -- local sContent = string.format("%s和%s结为本区第%d对情缘，祝愿他们一直亲密无间!", 
                --     oRole:GetName(), oTarRole:GetName(), nSerialNum)
                -- GF.SendNotice(0, sContent)
            end
            oRole:SubItemShowNotEnoughTips({tCost}, "情缘", true, false, fnSubCallback)
        end
    end

    local sCont = string.format("%s想与你结为情缘，是否同意？", oRole:GetName())
	local tMsg = {sCont=sCont, tOption={"拒绝", "确定"}, nTimeOut=30}
    goClientCall:CallWait("ConfirmRet", fnConfirmCallback, oTarRole, tMsg)
    oRole:Tips(string.format("已请求与%s结为情缘，正在等待回复", oTarRole:GetName()))
end

--同步情缘数据
function CLoverRelationMgr:SyncLoverData(oRole)
    local nRoleID = oRole:GetID()
    local oRoleLoverData = self:GetRoleLoverData(nRoleID)
    local tMsg = oRoleLoverData:GetPBData()
    oRole:SendMsg("LoverInfoRet", tMsg)
end

--删除情缘
function CLoverRelationMgr:DeleteLoverRelation(nRoleID, nTarID)
    if not (nRoleID and nTarID and nRoleID ~= nTarID) then
        print("删除情缘，参数错误", nRoleID, nTarID)
        return
    end
    local oLover = self:GetLoverByRole(nRoleID, nTarID)
    if not oLover then
        return oRole:Tips("当前并未和对方结成情缘")
    end
    local oLoverData = self:GetRoleLoverData(nRoleID)
    oLoverData:RemoveLover(nTarID, true)

    local oTarLoverData = self:GetRoleLoverData(nTarID)
    if oTarLoverData then  --对方角色可能已删除
        oTarLoverData:RemoveLover(nRoleID, false)
    else
        LuaTrace("请注意，目标玩家的情缘数据不存在, ID:"..nTarID)
    end
    --处理朋友关系
    local oRoleFriend = goFriendMgr:GetFriend(nRoleID, nTarID)
    if oRoleFriend then
        oRoleFriend:AddDegrees(-700, "解除情缘")
    end
    local oTarFriend =  goFriendMgr:GetFriend(nTarID, nRoleID)
    if oTarFriend then 
        oTarFriend:AddDegrees(-700, "解除情缘")
    end
    return true
end

--删除情缘请求
function CLoverRelationMgr:DeleteLoverReq(oRole, nTarID)
    if not nTarID or nTarID <= 0 then
        return oRole:Tips("非法请求")
    end
    local nRoleID = oRole:GetID()
    if nRoleID == nTarID then
        return oRole:Tips("非法请求")
    end
    local oLover = self:GetLoverByRole(nRoleID, nTarID)
    if not oLover then
        return oRole:Tips("和对方不是情缘关系，无法解除")
    end
    self:DeleteLoverRelation(nRoleID, nTarID)
    local oTarRole = goGPlayerMgr:GetRoleByID(nTarID)
    if oTarRole then 
        oRole:Tips(string.format("你已经解除与%s的情缘关系", oTarRole:GetName()))
        if oTarRole:IsOnline() then 
            oTarRole:Tips(string.format("你已经解除与%s的情缘关系", oRole:GetName()))
        end 
    else
        oRole:Tips("解除情缘关系成功")
    end
end

--情缘邀请
function CLoverRelationMgr:InviteTalkReq(oRole)
    if not oRole then return end
    if not self:IsSysOpen(oRole, true) then 
		return 
    end
    local oRoleLoverData = self:GetRoleLoverData(oRole:GetID())
    assert(oRoleLoverData)
    local nCurTime = os.time()
    local nPasTime = nCurTime - (oRoleLoverData.m_nLastInviteTalkStamp or 0)
    if nPasTime < 60 then 
        oRole:Tips(string.format("操作频繁，请%s秒后再试", 60 - nPasTime))
        return
    end
    
    local fnQueryCallback = function(sPreStr)
        if not sPreStr then 
			return 
		end
        local tTalkConf = ctTalkConf["loverinvite"]
        assert(tTalkConf)
        local sContentTemplate = tTalkConf.tContentList[math.random(#tTalkConf.tContentList)][1]
        local nTeamID = goTeamMgr:GetRoleTeamID(oRole:GetID())
        local sContent = string.format(sContentTemplate, oRole:GetID())

        oRoleLoverData.m_nLastInviteTalkStamp = nCurTime
        local sMsgContent = sPreStr..sContent
        GF.SendWorldTalk(oRole:GetID(), sMsgContent, true)
        oRole:Tips("消息发布成功")
    end
    oRole:QueryRelationshipInvitePreStr(fnQueryCallback)
end

function CLoverRelationMgr:SyncLogicCache(nRoleID, nSrcServer, nSrcService, nTarSession)
    assert(nRoleID and nRoleID >  0)
    local oRole = goGPlayerMgr:GetRoleByID(nRoleID)
    if not oRole then 
        return 
    end
    nSrcServer = nSrcServer or oRole:GetStayServer()
    nSrcService = nSrcService or oRole:GetLogic()
    nTarSession = nTarSession or oRole:GetSession()

    local oRoleLover = self:GetRoleLoverData(nRoleID)
    if not oRoleLover then
        return
    end
    local tData = {}
    tData.tLoverList = {}
    local tLoverList = oRoleLover:GetLoverList()
    for k, v in pairs(tLoverList) do 
        local nTempRoleID = v:GetID()
        local tLoverData = {}
        local oTempRole = goGPlayerMgr:GetRoleByID(nTempRoleID)
        if oTempRole then 
            tLoverData.sName = oTempRole:GetName()
        end
        tData.tLoverList[nTempRoleID] = tLoverData
    end
    goRemoteCall:Call("RoleLoverUpdateReq", nSrcServer, nSrcService, nTarSession, nRoleID, tData)
end

function CLoverRelationMgr:OnNameChange(oRole)
    local nRoleID = oRole:GetID()
    local oRoleLover = self:GetRoleLoverData(nRoleID)
    if not oRoleLover then
        return
    end
    local tLoverList = oRoleLover:GetLoverList() or {}
    for k, v in pairs(tLoverList) do 
        local nTempRoleID = v:GetID()
        local oTempRole = goGPlayerMgr:GetRoleByID(nTempRoleID)
        if oTempRole then --更新情缘的称谓
            local nAppeID = gtAppellationIDDef.eLover
            oTempRole:UpdateAppellation(nAppeID, {tNameParam={oRole:GetName()}}, nRoleID)
        end
    end
end

goLoverRelationMgr = goLoverRelationMgr or CLoverRelationMgr:new()


