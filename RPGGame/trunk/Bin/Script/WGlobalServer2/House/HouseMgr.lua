--家园管理
local table, string, math, os, pairs, ipairs, assert = table, string, math, os, pairs, ipairs, assert

local nAutoSaveTick = 5*60
function CHouseMgr:Ctor()
	self.m_nSaveTick = nil
	self.m_tHostList = {}
	self.m_nBestPartner = 0
	self.m_tDirtyHouseMap = {}
end

function CHouseMgr:Init()
	self:AutoSave()
	self:Schedule()
end

function CHouseMgr:OnRelease()
	goTimerMgr:Clear(self.m_nSaveTick)
	self.m_nSaveTick = nil
	goTimerMgr:Clear(self.m_nPartnerTick)
	self.m_nPartnerTick = nil
	self:SaveData()
end

function CHouseMgr:AutoSave()
	self.m_nSaveTick = goTimerMgr:Interval(nAutoSaveTick, function() self:SaveData() end)
end

--保存数据
function CHouseMgr:SaveData()
	for nRoleID,_ in pairs(self.m_tDirtyHouseMap) do
		local oHouse = self:GetHouse(nRoleID)
		oHouse:SaveData()
	end
end

--帮派脏
function CHouseMgr:MarkHouseDirty(nRoleID, bDirty)
	bDirty = bDirty or nil
	if GF.IsRobot(nRoleID) then 
		return 
	end
	self.m_tDirtyHouseMap[nRoleID] = bDirty
end

function CHouseMgr:IsHouseDirty(nRoleID)
	return self.m_tDirtyHouseMap[nRoleID]
end

function CHouseMgr:ValidOperateHouse(nRoleID)
	if not nRoleID then
		return false
	end
	local oRole = goGPlayerMgr:GetRoleByID(nRoleID)
	if not oRole then
		return false
	end
	if not oRole:IsSysOpen(69, true) then	--69家园系统开放ID
		return false
	end
	return true
end


function CHouseMgr:GetHouse(nRoleID)
	if not nRoleID then
		return
	end
	local oTargetRole = goGPlayerMgr:GetRoleByID(nRoleID)
	if not oTargetRole then
		return
	end
	local oHouse = self.m_tHostList[nRoleID]
	if not oHouse then
		oHouse = self:LoadHouse(nRoleID)
		oHouse:LoadData()
		self.m_tHostList[nRoleID] = oHouse
	end
	return oHouse
end

function CHouseMgr:LoadHouse(nRoleID)
	if not nRoleID then
		print("CHouseMgr:LoadHouse,err",debug.traceback())
		return
	end
	local oTargetRole = goGPlayerMgr:GetRoleByID(nRoleID)
	if not oTargetRole then
		return
	end
	local oHouse = CHouse:new(nRoleID)
	oHouse:LoadData()
	self.m_tHostList[nRoleID] = oHouse
	return oHouse
end

function CHouseMgr:Schedule()
	local nNowTime = os.time()
    local nNextDayTime = os.MakeDayTime(nNowTime,1,0)
    local nTime = nNextDayTime - nNowTime
    self.m_nPartnerTick = goTimerMgr:Interval(nTime, function() self:CheckPartnerTick() end)
end

function CHouseMgr:CheckPartnerTick()
	goTimerMgr:Clear(self.m_nPartnerTick)
	self.m_nPartnerTick = nil

	self:Schedule()

	self:MakeBestPartner()
end

function CHouseMgr:MakeBestPartner()
	local nMinServerLevel = goServerMgr:GetServerMinLevel()
	local tPartner = {}
	for nParterID,tData in pairs(ctPartnerConf) do
		if tData.nRecruitLevel < nMinServerLevel then
			table.insert(tPartner,nParterID)
		end
	end
	if #tPartner < 0 then
		tPartner = {20001}
	end
	self.m_nBestPartner = tPartner[math.random(#tPartner)]
end

function CHouseMgr:GetBestPartner()
	return self.m_nBestPartner
end

function CHouseMgr:Online(nRoleID)
	local oHouse = self:GetHouse(nRoleID)
	if not oHouse then
		oHouse = self:LoadHouse(nRoleID)
	end
	if oHouse then
		oHouse:Online()
	end
end

function CHouseMgr:Offline(nRoleID)
	local oHouse = self:GetHouse(nRoleID)
	if oHouse then
		oHouse:Offline(nRoleID)
	end
end

function CHouseMgr:UpdateReq(nRoleID,tData)
	local oHouse = self:GetHouse(nRoleID)
	if oHouse then
		oHouse:UpdateReq(tData)
	end
end

function CHouseMgr:EnterHouse(oRole,tData)
	local nTargetRoleID = tData.nRoleID
	if not self:ValidOperateHouse(nTargetRoleID) then
		return
	end
	local oHouse = self:GetHouse(nTargetRoleID)
	if not oHouse then
		oHouse = self:LoadHouse(nTargetRoleID)
	end
	if not oHouse then
		return
	end
	oHouse:EnterHouse(oRole)
end

function CHouseMgr:LeaveHouse(oRole,tData)
	local nTargetRoleID = tData.nRoleID
	if not self:ValidOperateHouse(nTargetRoleID) then
		return
	end
	local oHouse = self:GetHouse(nTargetRoleID)
	if not oHouse then
		return
	end
	oHouse:LeaveHouse(oRole)
end

function CHouseMgr:AddBoxCnt(nRoleID,nBoxCnt)
	local oHouse = self:GetHouse(nRoleID)
	if not oHouse then
		oHouse = self:LoadHouse(nTargetRoleID)
	end
	if not oHouse then
		return
	end
	oHouse:AddBoxCnt(nBoxCnt)
end

function CHouseMgr:DynamicPublicCommentReq(oRole,nTargetRoleID,nDynamicID,nTargetCommentID,sMsg)
	local oHouse = self:GetHouse(nTargetRoleID)
	if not oHouse then
		oHouse = self:LoadHouse(nTargetRoleID)
	end
	if not oHouse then
		return
	end
	oHouse:DynamicPublicCommentReq(oRole,nDynamicID,nTargetCommentID,sMsg)
end

function CHouseMgr:DynamicUpVoteReq(oRole,nTargetRoleID,nDynamicID)
	local oHouse = self:GetHouse(nTargetRoleID)
	if not oHouse then
		oHouse = self:LoadHouse(nTargetRoleID)
	end
	if not oHouse then
		return
	end
	oHouse:DynamicUpVoteReq(oRole,nDynamicID)
end

function CHouseMgr:HouseWaterPlantReq(oRole,tData)
	local nTargetRoleID = tData.nRoleID
	local oHouse = self:GetHouse(nTargetRoleID)
	if not oHouse then
		oHouse = self:LoadHouse(nTargetRoleID)
	end
	if not oHouse then
		return
	end
	oHouse:WaterPlant(oRole)
end

function CHouseMgr:DynamicRefresh(nRoleID,nDynamicID,tDynamic)
	local fnCallback = function (tFriendList)
		self:_DynamicRefresh(nRoleID,nDynamicID,tDynamic,tFriendList)
	end
	goRemoteCall:CallWait("GetFriendList",fnCallback,gnWorldServerID,goServerMgr:GetGlobalService(gnWorldServerID, 110),0,nRoleID)
end

function CHouseMgr:_DynamicRefresh(nRoleID,nDynamicID,tDynamic,tFriendList)
	for _,nFriendID in pairs(tFriendList) do
		local oFriendRole = goGPlayerMgr:GetRoleByID(nFriendID)
		if oFriendRole and oFriendRole:IsOnline() then
			local oHouse = self:GetHouse(nFriendID)
			if oHouse then
				oHouse:UpdateFriendDynamic(nRoleID,nDynamicID,tDynamic)
			end
		end
	end
end

--好友信息发生变更
function CHouseMgr:FriendChange(nRoleID,nTargetRoleID)
	local oHouse = goHouseMgr:GetHouse(nRoleID)
	oHouse:FriendChange(nTargetRoleID)

	local oTarRole = goGPlayerMgr:GetRoleByID(nTargetRoleID)
	if oTarRole and oTarRole:IsOnline() then
		local oHouse = goHouseMgr:GetHouse(nTargetRoleID)
		oHouse:FriendChange(nRoleID)
	end
end



goHouseMgr = goHouseMgr or CHouseMgr:new()