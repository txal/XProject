--多重确认框
local table, string, math, os, pairs, ipairs, assert = table, string, math, os, pairs, ipairs, assert



function CMultiConfirmBoxMgr:Ctor(nServiceID)
	self.m_nServiceID = nServiceID
	self.m_nKeySerial = 0
	self.m_tConfirmBoxMap = {}
	self.m_bInit = false
	self.m_nExpiryTimer = nil
end

function CMultiConfirmBoxMgr:Init()
	self.m_bInit = true
	self.m_nExpiryTimer = goTimerMgr:Interval(2, function () self:CheckExpiry() end)
end

function CMultiConfirmBoxMgr:IsInit() return self.m_bInit end

function CMultiConfirmBoxMgr:OnRelease()
	if self.m_nExpiryTimer then
		goTimerMgr:Clear(self.m_nExpiryTimer)
		self.m_nExpiryTimer = nil
	end
end

function CMultiConfirmBoxMgr:GenID()
	-- local nBoxID = self.m_nKeySerial % 0x7fffffff + 1
	-- self.m_nKeySerial = nBoxID
	-- return nBoxID
	if goClientCall then 
		return goClientCall:GenCallID()
	else
		self.m_nKeySerial = self.m_nKeySerial % 0xffff + 1
		local nBoxID = self.m_nServiceID << 16 | self.m_nKeySerial
		return nBoxID
	end
end

function CMultiConfirmBoxMgr:GetConfirmBox(nBoxID) return self.m_tConfirmBoxMap[nBoxID] end

function CMultiConfirmBoxMgr:CreateConfirmBox(sTitle, tContentList, nTimeOut)
	assert(self:IsInit(), "请确保当前服务的main.lua中调用了Init及Release函数")
	local nBoxID = self:GenID()
	if self.m_tConfirmBoxMap[nBoxID] then
		assert(false, "数据错误，出现重复key")
	end
	local oConfirmBox = CMultiConfirmBox:new(nBoxID, sTitle, tContentList, nTimeOut)
	self.m_tConfirmBoxMap[nBoxID] = oConfirmBox
	return oConfirmBox
end

function CMultiConfirmBoxMgr:RemoveConfirmBox(nBoxID)
	local oBox = self:GetConfirmBox(nBoxID)
	if not oBox then
		return
	end
	self.m_tConfirmBoxMap[nBoxID] = nil
end

function CMultiConfirmBoxMgr:CheckExpiry(nTimeStamp)
	nTimeStamp = nTimeStamp or os.time()
	local tRemoveList = {}
	for k, oConfirmBox in pairs(self.m_tConfirmBoxMap) do
		if oConfirmBox:IsTimeOut(nTimeStamp) then
			table.insert(tRemoveList, oConfirmBox)
		end
	end
	for k, oConfirmBox in pairs(tRemoveList) do --移出检查循环，可能其他地方会在TimeOut回调中，主动清理确认框
		oConfirmBox:OnTimeOut()
	end
	for k, oConfirmBox in pairs(tRemoveList) do
		if oConfirmBox:IsTimeOut(nTimeStamp) then --允许timeout回调中，重新设置过期时间，推迟删除
			self:RemoveConfirmBox(oConfirmBox:GetID())
		end
	end
end

function CMultiConfirmBoxMgr:RoleConfirmReactReq(nBoxID, nRoleID, nSerialID, nSelButton)
	assert(nBoxID and nRoleID and nSerialID and nSelButton, "参数错误")
	local oBox = self:GetConfirmBox(nBoxID)
	if not oBox then
		return
	end
	return oBox:RoleConfirmReactReq(nRoleID, nSerialID, nSelButton)
end

goMultiConfirmBoxMgr = goMultiConfirmBoxMgr or CMultiConfirmBoxMgr:new()


