--结拜系统
local table, string, math, os, pairs, ipairs, assert = table, string, math, os, pairs, ipairs, assert

--必须是同性别玩家，才可以结拜

-------------------------------------------------------------
function CBrother:Ctor(nRoleID, nSerialNum, nTimeStamp)
    self.m_nRoleID = nRoleID
    self.m_nSerialNum = nSerialNum or 0             --结拜编号
    self.m_nTimeStamp = nTimeStamp or os.time()
end

function CBrother:LoadData(tData)
    if not tData then 
        return 
    end
    self.m_nSerialNum = tData.nSerialNum
    self.m_nTimeStamp = tData.nTimeStamp
end

function CBrother:SaveData()
    local tData = {}
    tData.nRoleID = self.m_nRoleID
    tData.nSerialNum = self.m_nSerialNum
    tData.nTimeStamp = self.m_nTimeStamp
    return tData
end

function CBrother:GetBrotherID() return self.m_nRoleID end
function CBrother:GetID() return self:GetBrotherID() end

-------------------------------------------------------------
function CRoleBrother:Ctor(nRoleID)
    self.m_nRoleID = nRoleID
    self.m_tBrotherMap = {}      --{nRoleID:BrotherData, ...}
    self.m_nLastRemoveStamp = 0  --最后一次解除结拜的时间戳
    self.m_bDirty = false

    self.m_tInviteSilenceMap = {}    --不存DB，该次登录下，邀请默认拒绝
end

function CRoleBrother:LoadData(tData)
    if not tData then 
        return 
    end
    for k, v in pairs(tData.tBrotherMap) do 
        local oBrother = CBrother:new(k, 0, 0)
        oBrother:LoadData(v)
        self.m_tBrotherMap[k] = oBrother
    end
    self.m_nLastRemoveStamp = tData.nLastRemoveStamp
end

function CRoleBrother:SaveData()
    local tData = {}
    tData.nRoleID = self.m_nRoleID
    tData.tBrotherMap = {}
    for k, v in pairs(self.m_tBrotherMap) do 
        local tBrotherData = v:SaveData()
        tData.tBrotherMap[k] = tBrotherData
    end
    tData.nLastRemoveStamp = self.m_nLastRemoveStamp
    return tData
end

function CRoleBrother:MarkDirty(bDirty) 
    self.m_bDirty = bDirty
    if self.m_bDirty then
        goBrotherRelationMgr.m_tDirtyQueue:Push(self.m_nRoleID, self)
    end
end
function CRoleBrother:GetID() return self.m_nRoleID end
function CRoleBrother:IsDirty() return self.m_bDirty end
function CRoleBrother:GetBrother(nRoleID) return self.m_tBrotherMap[nRoleID] end
function CRoleBrother:AddBrother(nTarID, nSerialNum, nTimeStamp)
    assert(nTarID > 0, "参数错误")
    local oRole = goGPlayerMgr:GetRoleByID(self:GetID())
    local oTarRole = goGPlayerMgr:GetRoleByID(nTarID)
    assert(oRole and oTarRole)

    local oBrother = CBrother:new(nTarID, nSerialNum, nTimeStamp)
    self.m_tBrotherMap[nTarID] = oBrother
    self:MarkDirty(true)

    local nAppeID = gtAppellationIDDef.eBrother
    if oRole:GetGender() == gtGenderDef.eFemale then 
        nAppeID = gtAppellationIDDef.eSister
    end
    oRole:AddAppellation(nAppeID, {tNameParam={oTarRole:GetName()}}, oTarRole:GetID())

    goBrotherRelationMgr:SyncLogicCache(self:GetID())
    return oBrother
end
function CRoleBrother:GetBrotherCount()
    local nCount = 0
    for k, v in pairs(self.m_tBrotherMap) do
        nCount = nCount + 1
    end
    return nCount
end

function CRoleBrother:GetBrotherList()
    local tData = {}
    if self:GetBrotherCount() > 0 then 
        for k, v in pairs(self.m_tBrotherMap) do 
            table.insert(tData, v)
        end
        local fnCmp = function(tL, tR) 
            if tL.m_nTimeStamp <= tR.m_nTimeStamp then 
                return false
            else
                return true 
            end
        end
        table.sort(tData, fnCmp) --按结拜时间排序
    end
    return tData
end

function CRoleBrother:GetTimeLimitCountdown(nTimeStamp)
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

function CRoleBrother:IsTimeLimit(nTimeStamp)
    nTimeStamp = nTimeStamp or os.time()
    if math.abs(nTimeStamp - self.m_nLastRemoveStamp) >= 24*3600 then 
        return false 
    end
    return true 
end

--bActive是否主动解除
function CRoleBrother:RemoveBrother(nTarID, bActive)  
    local oTarBrother = self:GetBrother(nTarID)
    if not oTarBrother then
        return
    end
    self.m_tBrotherMap[nTarID] = nil
    if bActive then
        self.m_nLastRemoveStamp = os.time()
    end
    self:MarkDirty(true)

    local oRole = goGPlayerMgr:GetRoleByID(self:GetID())
    assert(oRole)
    local nAppeID = gtAppellationIDDef.eBrother
    if oRole:GetGender() == gtGenderDef.eFemale then 
        nAppeID = gtAppellationIDDef.eSister
    end
    oRole:RemoveAppellation(nAppeID, nTarID)

    goBrotherRelationMgr:SyncLogicCache(self:GetID())
end

function CRoleBrother:GetPBData()
    local tRetData = {}
--[[     //结拜的对象数据
    message BrotherData
    {
        required int32 nRoleID = 1;          //玩家ID
        required string sName = 2;           //名字
        required string sHeader = 3;         //头像
        required int32 nGender = 4;          //性别
        required int32 nSchool = 5;          //门派
        required int32 nLevel = 6;           //等级
        required int32 nTimeStamp = 7;       //结拜时间戳
    }
    
    //玩家结拜数据响应
    message BrotherInfoRet
    {
        repeated BrotherData tBrotherList = 1;   //结拜列表
        optional int32 nLimitTimeCountdown = 2;  //结拜限制倒计时
    } ]]
    tRetData.tBrotherList = {}
    for k, oBrother in pairs(self.m_tBrotherMap) do
        local oTarRole = goGPlayerMgr:GetRoleByID(k)
        if oTarRole then  
            local tBrotherData = {}
            tBrotherData.nRoleID = k 
            tBrotherData.sName = oTarRole:GetName()
            tBrotherData.sHeader = oTarRole:GetHeader()
            tBrotherData.nGender = oTarRole:GetGender()
            tBrotherData.nSchool = oTarRole:GetSchool()
            tBrotherData.nLevel = oTarRole:GetLevel()
            tBrotherData.nTimeStamp = oBrother.m_nTimeStamp
            table.insert(tRetData.tBrotherList, tBrotherData)
        end
    end
    tRetData.nLimitTimeCountdown = self:GetTimeLimitCountdown()
    return tRetData
end

--插入邀请屏蔽列表
function CRoleBrother:InsertInviteSilenceMap(nRoleID)
	self.m_tInviteSilenceMap[nRoleID] = os.time()
end

function CRoleBrother:IsInInviteSilenceMap(nRoleID)
	if not nRoleID then 
		return false 
	end
	return self.m_tInviteSilenceMap[nRoleID] and true or false
end

function CRoleBrother:CleanInviteSilenceMap()
	self.m_tInviteSilenceMap = {}
end


-------------------------------------------------------------
function CBrotherRelationMgr:Ctor()
    self.m_nSerialNum = 0
    self.m_tRoleMap = {}         --{nRoleID:RoleBrotherData, ...}
    self.m_tDirtyQueue = CUniqCircleQueue:new()
    self.m_nSaveTimer = nil
    self.m_bDirty = false
end

function CBrotherRelationMgr:Init()
    self.m_nSaveTimer = GetGModule("TimerMgr"):Interval(60, function ()  self:SaveData() end) 
	self:LoadData()
end

function CBrotherRelationMgr:Release()
    GetGModule("TimerMgr"):Clear(self.m_nSaveTimer)
    self.m_nSaveTimer = nil
    self:SaveData()
end

function CBrotherRelationMgr:MarkDirty(bDirty) self.m_bDirty = bDirty end
function CBrotherRelationMgr:IsDirty() return self.m_bDirty end

function CBrotherRelationMgr:LoadSysData()
    local oDB = goDBMgr:GetSSDB(gnServerID, "global", CUtil:GetServiceID())
	local sData = oDB:HGet(gtDBDef.sBrotherSysDB, "brothersysdata")
	if sData ~= "" then
		local tData = cjson.decode(sData)
		self.m_nSerialNum = tData.nSerialNum
	end
end

function CBrotherRelationMgr:SaveSysData()
    if not self:IsDirty() then 
        return 
    end
    local tData = {}
    tData.nSerialNum = self.m_nSerialNum
    local oDB = goDBMgr:GetSSDB(gnServerID, "global", CUtil:GetServiceID())
    oDB:HSet(gtDBDef.sBrotherSysDB, "brothersysdata", cjson.encode(tData))
    
    self:MarkDirty(false)
end

function CBrotherRelationMgr:LoadData()
    self:LoadSysData()
    local oDB = goDBMgr:GetSSDB(gnServerID, "global", CUtil:GetServiceID())
	local tKeys = oDB:HKeys(gtDBDef.sRoleBrotherDB)
	for _, sRoleID in ipairs(tKeys) do
		local sData = oDB:HGet(gtDBDef.sRoleBrotherDB, sRoleID)
		local tData = cjson.decode(sData)
		local nRoleID = tData.nRoleID
		local oBrotherData = CRoleBrother:new(nRoleID)
		oBrotherData:LoadData(tData)
		self.m_tRoleMap[nRoleID] = oBrotherData
	end
end

function CBrotherRelationMgr:SaveData()
    self:SaveSysData()
    local nDirtyNum = self.m_tDirtyQueue:Count()
	if nDirtyNum < 1 then
		return
	end
	local oDB = goDBMgr:GetSSDB(gnServerID, "global", CUtil:GetServiceID())
	for i = 1, nDirtyNum do
		local oBrotherData = self.m_tDirtyQueue:Head()
		if oBrotherData then
			local tData = oBrotherData:SaveData()
			oDB:HSet(gtDBDef.sRoleBrotherDB, oBrotherData:GetID(), cjson.encode(tData))
			oBrotherData:MarkDirty(false)
        end
        self.m_tDirtyQueue:Pop()
	end
end

function CBrotherRelationMgr:GenID()
    self.m_nSerialNum = self.m_nSerialNum % 0x7fffffff + 1
    self:MarkDirty(true)
    return self.m_nSerialNum
end

function CBrotherRelationMgr:GetRoleBrotherData(nRoleID) return self.m_tRoleMap[nRoleID] end

--检查是否结拜
function CBrotherRelationMgr:IsBrother(nRoleID, nTarID)
    local oBrother = self:GetBrotherByRole(nRoleID, nTarID)
    if oBrother then
        return true
    else
        return false
    end
end

--根据玩家获取结拜关系
function CBrotherRelationMgr:GetBrotherByRole(nRoleID, nTarID)
    assert(nRoleID and nTarID and nRoleID ~= nTarID, "参数错误")
    local oRoleBrother = self:GetRoleBrotherData(nRoleID)
    assert(oRoleBrother)
    return oRoleBrother:GetBrother(nTarID)
end

function CBrotherRelationMgr:OnRoleOnline(oRole)
    if oRole:IsRobot() then 
        return 
    end
    local nRoleID = oRole:GetID()
    local oRoleBrother = self:GetRoleBrotherData(nRoleID)
    if not oRoleBrother then 
        local oBrotherData = CRoleBrother:new(nRoleID)
        self.m_tRoleMap[nRoleID] = oBrotherData
        oBrotherData:MarkDirty(true)
        oRoleBrother = oBrotherData
    end
    oRoleBrother:CleanInviteSilenceMap()
    self:SyncLogicCache(nRoleID)
end

function CBrotherRelationMgr:OnRoleOffline(oRole)
    local oRoleBrother = self:GetRoleBrotherData(oRole:GetID())
    if not oRoleBrother then 
        return 
    end
    oRoleBrother:CleanInviteSilenceMap()
end

--检查结拜
function CBrotherRelationMgr:CheckBrotherSwear(oRole, nTarID)
    local nRoleID = oRole:GetID()
    assert(nTarID and nTarID > 0, "数据错误")
	local oTarRole = goGPlayerMgr:GetRoleByID(nTarID)
    assert(oTarRole, "数据错误")
    
    local bCanSwear = false
    local tCheckList = 
    {
        bOnline = true,      --同时在线
        bLevel = true,       --等级>=40级
        bBrother = true,     --双方之间没有结成结拜关系，且24小时内没有解除过结拜关系
        bFriend = true,      --双方互为好友，且亲密度>=700
        --bMoney = true,       --队长持有1万金币
        bBrotherMax = true,  --双方结义对象数量没有达到3人
        bGender = true,      --双方是同性别玩家
    }

    --检查ID
	if nRoleID == nTarID then
		oRole:Tips("不能和自己结拜")
		for k, v in pairs(tCheckList) do
			tCheckList[k] = false
        end
		return bCanSwear, tCheckList
    end

    if not oRole:IsOnline() or not oTarRole:IsOnline() then 
        tCheckList.bOnline = false
    end

    --检查等级
	if not (oRole:GetLevel() >= 40 and oTarRole:GetLevel() >= 40) then
		tCheckList.bLevel = false
    end
    
    --检查结拜关系
    if CUtil:IsRobot(nRoleID) or CUtil:IsRobot(nTarID) then 
        tCheckList.bBrother = false 
        tCheckList.bBrotherMax = false
        tCheckList.bFriend = false
    else
        if self:IsBrother(nRoleID, nTarID) then 
            tCheckList.bBrother = false 
        end
        local oRoleBrotherData = self:GetRoleBrotherData(nRoleID)
        local oTarBrotherData = self:GetRoleBrotherData(nTarID)
        assert(oRoleBrotherData and oTarBrotherData, "数据错误")
        if oRoleBrotherData:IsTimeLimit() or oTarBrotherData:IsTimeLimit() then
            tCheckList.bBrother = false 
        end

        if oRoleBrotherData:GetBrotherCount() >= 3 
            or oTarBrotherData:GetBrotherCount() >= 3 then
            tCheckList.bBrotherMax = false
        end 

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
    end
    
    --检查性别
	local tRoleConf = oRole:GetConf()
	local tTarConf = oTarRole:GetConf()
	if tRoleConf.nGender ~= tTarConf.nGender then
		tCheckList.bGender = false
    end

    bCanSwear = true
	for k, v in pairs(tCheckList) do
		if v == false then
			bCanSwear = false
			break
		end
    end
    
    return bCanSwear, tCheckList
end

function CBrotherRelationMgr:BrotherSwearCheckReq(oRole, nTarRoleID)
    if not nTarRoleID or nTarRoleID <= 0 then 
        return 
    end
    local bCanSwear, tCheckList = self:CheckBrotherSwear(oRole, nTarRoleID)
    local tRetData = {}
    tRetData.nTarRoleID = tCheckList.nTarRoleID
    tRetData.bOnline = tCheckList.bOnline
    tRetData.bLevel = tCheckList.bLevel
    tRetData.bBrother = tCheckList.bBrother
    tRetData.bFriend = tCheckList.bFriend
    tRetData.bBrotherMax = tCheckList.bBrotherMax
    tRetData.bGender = tCheckList.bGender
    oRole:SendMsg("BrotherSwearCheckRet", tRetData)
end

function CBrotherRelationMgr:DealBrotherSwear(nRoleID, nTarID)
    if nRoleID == nTarID then
        return 
    end
    local oRoleBrother = self:GetRoleBrotherData(nRoleID)
    local oTarBrother = self:GetRoleBrotherData(nTarID)
    if not oRoleBrother or not oTarBrother then 
        return
    end
    if self:GetBrotherByRole(nRoleID, nTarID) then --已经结拜了的，加一层保护
        return 
    end
    local nSerialNum = self:GenID()
    local nTimeStamp = os.time()
    oRoleBrother:AddBrother(nTarID, nSerialNum, nTimeStamp)
    oTarBrother:AddBrother(nRoleID, nSerialNum, nTimeStamp)

    local oRole = goGPlayerMgr:GetRoleByID(nRoleID)
    local oTarRole = goGPlayerMgr:GetRoleByID(nTarID)
    local sRelation = (oRole:GetGender() == gtGenderDef.eMale) and "兄弟" or "姐妹"
    local sContent = string.format("%s和%s结为本区第%d对异姓%s，但求肝胆相照，祸福与共!", 
        oRole:GetName(), oTarRole:GetName(), nSerialNum, sRelation)
    -- CUtil:SendSystemTalk("系统", sContent)
    CUtil:SendNotice(0, sContent)
    return true
end

function CBrotherRelationMgr:IsSysOpen(oRole, bTips)
    if not oRole then 
        return false 
    end
    return oRole:IsSysOpen(59, bTips)
end

--结拜请求
function CBrotherRelationMgr:BrotherSwearReq(oRole, nTarID)
    if oRole:GetID() == nTarID then 
        oRole:Tips("不能和自己结拜")
        return 
    end
    local oTarRole = goGPlayerMgr:GetRoleByID(nTarID)
    if not oTarRole then
        print("目标玩家不存在,玩家ID:"..nTarID)
        return
    end
    if oTarRole:IsRobot() then 
        oRole:Tips("对方婉拒了你的请求")
        return 
    end

    local nRoleID = oRole:GetID()
    local bValid, tCheckList = self:CheckBrotherSwear(oRole, nTarID)
    if not bValid then 
        return oRole:Tips("结拜条件不满足")
    end
    if not self:IsSysOpen(oRole, true) then 
        oTarRole:Tips("对方功能未开启")
        return 
    end
    if not self:IsSysOpen(oTarRole, true) then 
        oRole:Tips("对方功能未开启")
        return 
    end

    if not oTarRole:IsOnline() then
        return oRole:Tips("对方已经离线，无法结拜")
    end

    local oTarBrotherData = self:GetRoleBrotherData(nTarID)
    assert(oTarBrotherData, "数据错误")
    if oTarBrotherData:IsInInviteSilenceMap(oRole:GetID()) then 
        oRole:Tips("对方婉拒了你的请求")
        return 
    end

    local fnConfirmCallback = function (tData)
        if tData.nSelIdx == 1 then  --拒绝
            oRole:Tips("对方婉拒了你的请求")
            if tData.nTypeParam and tData.nTypeParam > 0 then 
                oTarBrotherData:InsertInviteSilenceMap(oRole:GetID())
            end
			return
        elseif tData.nSelIdx == 2 then  --确定
            local tCost = {nType = gtItemType.eCurr, nID = gtCurrType.eJinBi, nNum = 10000}
            local fnSubCallback = function (bRet)
                if not bRet then
                    return
                end
                --已经结拜了的，加一层保护 可能连续重复点击导致
                if self:GetBrotherByRole(nRoleID, nTarID) then 
                    oRole:AddItem(tCost, "结拜回滚")
                    return oRole:Tips(string.format("你和%s已经结拜了，不可重复申请", 
                        oTarRole:GetName()))
                end
                if not self:DealBrotherSwear(nRoleID, nTarID) then
                    return 
                end
                oRole:Tips(string.format("和%s结拜成功", oTarRole:GetName()))
                oTarRole:Tips(string.format("和%s结拜成功", oRole:GetName()))
                self:SyncBrotherData(oRole)
                self:SyncBrotherData(oTarRole)
            end
            oRole:SubItemShowNotEnoughTips({tCost}, "结拜", true, false, fnSubCallback)
        end
    end

    local sRelation = (oRole:GetGender() == gtGenderDef.eMale) and "兄弟" or "姐妹"
    local sCont = string.format("%s想与你结拜为%s，是否同意？", oRole:GetName(), sRelation)
	local tMsg = {sCont=sCont, tOption={"拒绝", "确定"}, nTimeOut=30, nType=4, nTypeParam=nRoleID}
    goClientCall:CallWait("ConfirmRet", fnConfirmCallback, oTarRole, tMsg)
    oRole:Tips(string.format("已请求与%s结拜，正在等待回复", oTarRole:GetName()))
end

--同步结拜数据
function CBrotherRelationMgr:SyncBrotherData(oRole)
    local nRoleID = oRole:GetID()
    local oRoleBrotherData = self:GetRoleBrotherData(nRoleID)
    local tMsg = oRoleBrotherData:GetPBData()
    oRole:SendMsg("BrotherInfoRet", tMsg)
    -- print("SyncBrotherData:", tMsg)
end

--删除结拜
function CBrotherRelationMgr:DeleteBrotherRelation(nRoleID, nTarID)
    if not (nRoleID and nTarID and nRoleID ~= nTarID) then
        print("删除结拜，参数错误", nRoleID, nTarID)
        return
    end
    local oBrother = self:GetBrotherByRole(nRoleID, nTarID)
    if not oBrother then
        return oRole:Tips("当前并未和对方结拜")
    end
    local oBrotherData = self:GetRoleBrotherData(nRoleID)
    oBrotherData:RemoveBrother(nTarID, true)
    local oTarBrotherData = self:GetRoleBrotherData(nTarID)
    if oTarBrotherData then  --对方角色可能已删除
        oTarBrotherData:RemoveBrother(nRoleID, false)
    else
        LuaTrace("请注意，目标玩家的结拜数据不存在, ID:"..nTarID)
    end
    --处理朋友关系
    local oRoleFriend = goFriendMgr:GetFriend(nRoleID, nTarID)
    if oRoleFriend then
        oRoleFriend:AddDegrees(-700, "解除结拜")
    end
    local oTarFriend =  goFriendMgr:GetFriend(nTarID, nRoleID)
    if oTarFriend then 
        oTarFriend:AddDegrees(-700, "解除结拜")
    end
    --处理称谓
    local oRole = goGPlayerMgr:GetRoleByID(nRoleID)
    local oTarRole = goGPlayerMgr:GetRoleByID(nTarID)
    local nAppeID = gtAppellationIDDef.eBrother
    if oRole:GetGender() == gtGenderDef.eFemale then 
        nAppeID = gtAppellationIDDef.eSister
    end
    if oRole then
        oRole:RemoveAppellation(nAppeID,0)
    end
    if oTarRole then
        oTarRole:RemoveAppellation(nAppeID,0)
    end
    return true
end

--删除结拜请求
function CBrotherRelationMgr:DeleteBrotherReq(oRole, nTarID)
    if not nTarID or nTarID <= 0 then
        return oRole:Tips("非法请求")
    end
    local nRoleID = oRole:GetID()
    if nRoleID == nTarID then
        return oRole:Tips("非法请求")
    end
    local oBrother = self:GetBrotherByRole(nRoleID, nTarID)
    if not oBrother then
        return oRole:Tips("和对方不是结拜关系")
    end 
    self:DeleteBrotherRelation(nRoleID, nTarID)
    local oTarRole = goGPlayerMgr:GetRoleByID(nTarID)
    if oTarRole then 
        oRole:Tips(string.format("你已经解除与%s的结拜关系", oTarRole:GetName()))
        if oTarRole:IsOnline() then 
            oTarRole:Tips(string.format("你已经解除与%s的结拜关系", oRole:GetName()))
        end 
    else
        oRole:Tips("解除结拜关系成功")
    end
end

--结拜邀请
function CBrotherRelationMgr:InviteTalkReq(oRole)
    if not oRole then return end
    if not self:IsSysOpen(oRole, true) then 
		return 
	end
    local oRoleData = self:GetRoleBrotherData(oRole:GetID())
    assert(oRoleData)
    local nCurTime = os.time()
    local nPasTime = nCurTime - (oRoleData.m_nLastInviteTalkStamp or 0)
    if nPasTime < 60 then 
        oRole:Tips(string.format("操作频繁，请%s秒后再试", 60 - nPasTime))
        return
    end

    local fnQueryCallback = function(sPreStr)
        if not sPreStr then 
			return 
		end
        local tTalkConf = ctTalkConf["brotherinvite"]
        assert(tTalkConf)
        local sContentTemplate = tTalkConf.tContentList[math.random(#tTalkConf.tContentList)][1]
        local nTeamID = goTeamMgr:GetRoleTeamID(oRole:GetID())
        local sContent = string.format(sContentTemplate, oRole:GetID())

        oRoleData.m_nLastInviteTalkStamp = nCurTime
        local sMsgContent = sPreStr..sContent
        CUtil:SendWorldTalk(oRole:GetID(), sMsgContent, true)
        oRole:Tips("消息发布成功")
    end
    oRole:QueryRelationshipInvitePreStr(fnQueryCallback)
end

--同步结拜数据到逻辑服
function CBrotherRelationMgr:SyncLogicCache(nRoleID, nSrcServer, nSrcService, nTarSession)
    assert(nRoleID and nRoleID >  0)
    local oRole = goGPlayerMgr:GetRoleByID(nRoleID)
    if not oRole then 
        return 
    end
    nSrcServer = nSrcServer or oRole:GetStayServer()
    nSrcService = nSrcService or oRole:GetLogic()
    nTarSession = nTarSession or oRole:GetSession()

    local oRoleBrother = self:GetRoleBrotherData(nRoleID)
    if not oRoleBrother then
        return
    end
    local tData = {}
    tData.tBrotherList = {}
    local tBrotherList = oRoleBrother:GetBrotherList()
    for k, v in ipairs(tBrotherList) do 
        local nTempRoleID = v:GetID()
        local tBrotherData = {}
        local oTempRole = goGPlayerMgr:GetRoleByID(nTempRoleID)
        if oTempRole then 
            tBrotherData.sName = oTempRole:GetName()
        end
        tData.tBrotherList[nTempRoleID] = tBrotherData
    end
    Network.oRemoteCall:Call("RoleBrotherUpdateReq", nSrcServer, nSrcService, nTarSession, nRoleID, tData)
end

function CBrotherRelationMgr:OnNameChange(oRole)
    local nRoleID = oRole:GetID()
    local oRoleBrother = self:GetRoleBrotherData(nRoleID)
    if not oRoleBrother then
        return
    end
    local tBrotherList = oRoleBrother:GetBrotherList() or {}
    for k, v in pairs(tBrotherList) do 
        local nTempRoleID = v:GetID()
        local oTempRole = goGPlayerMgr:GetRoleByID(nTempRoleID)
        if oTempRole then --更新结拜对象的称谓
            local nAppeID = gtAppellationIDDef.eBrother
            if oRole:GetGender() == gtGenderDef.eFemale then 
                nAppeID = gtAppellationIDDef.eSister
            end
            oTempRole:UpdateAppellation(nAppeID, {tNameParam={oRole:GetName()}}, nRoleID)
        end
    end
end

function CBrotherRelationMgr:GetRoleInfoBrotherInfo(nRoleID)
    local tBrotherInfo = {}
    local oRoleBrotherData = self:GetRoleBrotherData(nRoleID)
    local tBrotherList = {}
    if oRoleBrotherData then 
        for k, oBrother in pairs(oRoleBrotherData.m_tBrotherMap) do
            local oTarRole = goGPlayerMgr:GetRoleByID(k)
            if oTarRole then  
                local tBrotherData = {}
                tBrotherData.nID = k 
                tBrotherData.sName = oTarRole:GetName()
                tBrotherData.sModel = oTarRole:GetModel()
                tBrotherData.sHeader = oTarRole:GetHeader()
                tBrotherData.nLevel = oTarRole:GetLevel()
                tBrotherData.nGender = oTarRole:GetGender()
                tBrotherData.nSchool = oTarRole:GetSchool()
                table.insert(tBrotherList, tBrotherData)
            end
        end
    end
    tBrotherInfo.tBrotherList = tBrotherList
    return tBrotherInfo
end


