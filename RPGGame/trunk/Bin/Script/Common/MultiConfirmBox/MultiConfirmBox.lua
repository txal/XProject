--多重确认框
local table, string, math, os, pairs, ipairs, assert = table, string, math, os, pairs, ipairs, assert


gtMultiConfirmBoxRoleState = 
{
	eUnconfirmed = 0;      --未确认
	eConfirmed = 1;        --已确认(包括已关闭已取消，只要收到具体响应，都将设置为这个状态)
}

gnMultiConfirmBoxCancelButtonID = 0
gnMultiConfirmBoxMaxTimeOut = 300

function CRoleConfirm:Ctor(nRoleID)
	self.m_nRoleID = nRoleID
	self.m_nConfirmState = gtMultiConfirmBoxRoleState.eUnconfirmed   --状态，是否已选择，是否可以继续选择
	self.m_tContentList = nil     --文本内容，某些对话框需要对玩家定制化显示内容，如果为nil，则默认读取Box的tContentList
	self.m_nConfirmID = 0         --最近一次选择的buttonID
	self.m_tButtonList = {}       --选项按钮{{nButtonID, sContent, bActive}, ...} --序列，PB打包需要确定顺序，客户端需要根据PB打包顺序确定排列顺序
	self.m_bCanCancel = true      --是否可取消
end

function CRoleConfirm:IsConfirmed()
	if self.m_nConfirmState == gtMultiConfirmBoxRoleState.eConfirmed then
		return true
	end
	return false
end

function CRoleConfirm:SetConfirmState(nState)
	self.m_nConfirmState = nState
end

function CRoleConfirm:ResetConfirmState()
	self:SetConfirmState(gtMultiConfirmBoxRoleState.eUnconfirmed)
end

function CRoleConfirm:CanCancel() return self.m_bCanCancel end
function CRoleConfirm:SetCanCancel(bCanCancel) self.m_bCanCancel = bCanCancel end

--移除指定button
function CRoleConfirm:RemoveButton(nButtonID) 
	--self.m_tButtonList[nButtonID] = nil 
	local nIndex = self:GetButtonIndex(nButtonID)
	if not nIndex or nIndex <= 0 then
		return
	end
	table.remove(self.m_tButtonList, nIndex)
end

function CRoleConfirm:RemoveButtonByIndex(nIndex)
	if nIndex <= 0 then
		return
	end
	if nIndex > #self.m_tButtonList then
		return
	end
	table.remove(self.m_tButtonList, nIndex)
end

function CRoleConfirm:GetButtonIndex(nButtonID)
	local nIndex = 0
	for k, tButton in ipairs(self.m_tButtonList) do
		if tButton.nButtonID == nButtonID then
			nIndex = tButton
			break
		end
	end
	return nIndex
end

--设置指定nButtonID的按钮的状态
--已存在，则更新，不存在，则插入，默认插入尾部
function CRoleConfirm:UpdateButton(nButtonID, sContent, bActive, nIndex)
	--self.m_tButtonList[nButtonID] = {nButtonID = nButtonID, sContent = sContent, bActive = bActive}
	local tButton = self:GetButton(nButtonID)
	if tButton then
		tButton.sContent = sContent
		tButton.bActive = bActive
		if nIndex and nIndex > 0 then
			local nOldIndex = self:GetButtonIndex(nButtonID)
			assert(nOldIndex > 0, "计算错误")
			if nOldIndex ~= nIndex then
				self:RemoveButtonByIndex(nOldIndex)
				nIndex = math.min(nIndex, #self.m_tButtonList + 1)
				table.insert(self.m_tButtonList, nIndex, tButton)
			end
		end
	else
		local nInsertIndex = #self.m_tButtonList + 1
		if nIndex and nIndex > 0 then
			nInsertIndex = math.min(nIndex, #self.m_tButtonList + 1)
		end
		table.insert(self.m_tButtonList, nInsertIndex, {nButtonID = nButtonID, sContent = sContent, bActive = bActive})
	end
end

function CRoleConfirm:GetButton(nButtonID) 
	--return self.m_tButtonList[nButtonID] 
	local tRetButton = nil
	for k, tButton in ipairs(self.m_tButtonList) do
		if tButton.nButtonID == nButtonID then
			tRetButton = tButton
			break
		end
	end
	return tRetButton
end

function CRoleConfirm:GetButtonList() return self.m_tButtonList end

--获取定制化的对话框文本内容
function CRoleConfirm:GetContentList() return self.m_tContentList end
--设置定制化的对话框文本显示内容
function CRoleConfirm:SetContentList(tContentList) self.m_tContentList = tContentList end
--必须是已确认状态，返回值才是一个有效值
function CRoleConfirm:GetConfirmID() return self.m_nConfirmID end


--------------------------------------------------
function CMultiConfirmBox:Ctor(nBoxID, sTitle, tContentList, nTimeOut)
	assert(nBoxID and nBoxID > 0, "参数错误")
	self.m_nConfirmBoxID = nBoxID
	self.m_tSerialIDCache = {}
	-- self.m_nSerialID = self:GenSerialID()
	self.m_nSerialID = 1

	self.m_sTitle = sTitle                    --可选的，可以为nil
	self.m_tContentList = tContentList or {}  --{sContent, ...}
	self.m_tRoleList = {}                     --{nRoleID:CRoleConfirm, ...}

	self.m_nTimeStamp = os.time()
	nTimeOut = nTimeOut or 30
	self.m_nTimeOutStamp = self.m_nTimeStamp + nTimeOut

	self.m_fnOnRoleConfirm = nil
	self.m_fnOnRoleCancel = nil
	self.m_fnOnTimeOut = nil
end

function CMultiConfirmBox:GetID() return self.m_nConfirmBoxID end
function CMultiConfirmBox:GetSerialID() return self.m_nSerialID end
function CMultiConfirmBox:GetTitle() return self.m_sTitle end
function CMultiConfirmBox:SetTitle(sTitle) self.m_sTitle = sTitle end
function CMultiConfirmBox:GetContentList() return self.m_tContentList end
function CMultiConfirmBox:SetContentList(tContentList) self.m_tContentList = tContentList end
function CMultiConfirmBox:GetTimeOutStamp() return self.m_nTimeOutStamp end

function CMultiConfirmBox:GenSerialID()
	-- local nID = math.random(1, 0x7fffffff)  --完全随机一个
	-- local nMaxCacheNum = 20  --20个够用了，单次随机出现重复概率不到一亿分之一
	-- for i = 0, nMaxCacheNum do
	-- 	nID = nID % 0x7fffffff + 1  --如果存在重复，就+1，nMaxCacheNum+1个元素，必然存在一个缓存中不存在的
	-- 	local bExist = false
	-- 	for k, v in ipairs(self.m_tSerialIDCache or {}) do
	-- 		if nID == v then
	-- 			bExist = true
	-- 			break
	-- 		end
	-- 	end
	-- 	if not bExist then
	-- 		break
	-- 	end
	-- end
	local nID = self.m_nSerialID + 1
	return nID
end

--如果某个玩家的提交，影响到其他玩家的表现，需要更新此ID并同步最新的确认框数据,以确保其他玩家的提交是一个正确的状态的提交
function CMultiConfirmBox:UpdateSerialID()
	self.m_nSerialID = self:GenSerialID()
	-- if #self.m_tRoleList >= nMaxCacheNum then
	-- 	table.remove(self.m_tSerialIDCache, 1)
	-- end
	-- table.insert(self.m_tSerialIDCache, self.m_nSerialID)
	return self.m_nSerialID
end

--fnCallback(nRoleID, nSelButton), nSelIndex必然不为0，如果某个button id为0，则进入取消回调
function CMultiConfirmBox:SetRoleConfirmCallback(fnCallback)
	self.m_fnOnRoleConfirm = fnCallback
end

--fnCallback(nRoleID)
--回调函数中需要注意，比如逻辑服，回调函数被调用时，可能玩家已经切换了服务器或者已经离线了
function CMultiConfirmBox:SetRoleCancelCallback(fnCallback)
	self.m_fnOnRoleCancel = fnCallback
end

--如果没有手动删除此confirmbox，则到时间后，会进入此回调，回调结束会自动删除
function CMultiConfirmBox:SetTimeOutCallback(fnCallback)
	self.m_fnOnTimeOut = fnCallback
end

--会重新开始计时
function CMultiConfirmBox:SetTimeOut(nTimeOut)
	assert(nTimeOut > gnMultiConfirmBoxMaxTimeOut, string.format("MultiConfirmBox超时时间最长<%d>秒", gnMultiConfirmBoxMaxTimeOut))
	self.m_nTimeStamp = os.time()
	self.m_nTimeOutStamp = self.m_nTimeStamp + nTimeOut
end

function CMultiConfirmBox:IsTimeOut(nTimeStamp)
	nTimeStamp = nTimeStamp or os.time()
	--加个保护检查，防止测试过程中，修改时间，导致一直保留
	if nTimeStamp >= self.m_nTimeOutStamp or math.abs(nTimeStamp - self.m_nTimeStamp) >= gnMultiConfirmBoxMaxTimeOut then 
		return true
	end
	return false
end

function CMultiConfirmBox:OnTimeOut()
	if self.m_fnOnTimeOut then
		self.m_fnOnTimeOut()
	end
end

function CMultiConfirmBox:GetRoleConfirmData(nRoleID) return self.m_tRoleList[nRoleID] end
function CMultiConfirmBox:InsertRoleConfirmData(nRoleID)
	if self.m_tRoleList[nRoleID] then
		return self.m_tRoleList[nRoleID]
	end
	local oRoleConfirm = CRoleConfirm:new(nRoleID)
	self.m_tRoleList[nRoleID] = oRoleConfirm
	return oRoleConfirm
end
function CMultiConfirmBox:RemoveRoleConfirmData(nRoleID) self.m_tRoleList[nRoleID] = nil end

function CMultiConfirmBox:IsAllConfirmed()
	local bAllConfirmed = true
	for k, oRoleConfirm in pairs(self.m_tRoleList) do
		if not oRoleConfirm:IsConfirmed() then
			bAllConfirmed = false
			break
		end
	end
	return bAllConfirmed
end

function CMultiConfirmBox:GetRoleList() return self.m_tRoleList end

--返回值{oRoleConfirmData, ...}, 已确认的数据引用序列，方便外层直接处理
function CMultiConfirmBox:GetAllRoleConfirmData()
	local tList = {}
	for k, oRoleConfirm in pairs(self.m_tRoleList) do
		table.insert(tList, oRoleConfirm)
	end
	return tList
end

--返回值{oRoleConfirmData, ...}, 未确认的数据引用序列
function CMultiConfirmBox:GetUnconfirmedRoleList()
	local tList = {}
	for k, oRoleConfirm in pairs(self.m_tRoleList) do
		if not oRoleConfirm:IsConfirmed() then
			table.insert(tList, oRoleConfirm)
		end
	end
	return tList
end

--返回值{oRoleConfirmData, ...}, 确认数据引用序列，方便外层直接处理
function CMultiConfirmBox:GetConfirmedRoleList()
	local tList = {}
	for k, oRoleConfirm in pairs(self.m_tRoleList) do
		if oRoleConfirm:IsConfirmed() then
			table.insert(tList, oRoleConfirm)
		end
	end
	return tList
end

--通知指定玩家的确认框信息 --客户端已存在此确认框，则更新，不存在，则创建
function CMultiConfirmBox:SyncRoleConfirmBox(nRoleID)
	local oRole = nil
	if goGPlayerMgr then
		oRole = goGPlayerMgr:GetRoleByID(nRoleID)
	else
		oRole = goPlayerMgr:GetRoleByID(nRoleID)
	end
	if not oRole then 
		return 
	end

	local oRoleConfirm = self:GetRoleConfirmData(nRoleID)
	if not oRoleConfirm then
		return
	end
	--[[
	message ConfirmButton
	{
		required int32 nID = 1;         //Button ID
		optional string sContent = 2;   //Button文本
		required bool bActive = 3;      //是否可操作
	}
	message MultiConfirmBoxRet  
	{
		required int32 nService = 1;       //服务ID
		required int32 nConfirmBoxID = 2;
		required int32 nSerialID = 3;
		optional string sTitle = 4;
		repeated string tContentList = 5;
		repeated ConfirmButton tButtonList = 6;
		required int32 nTimeOut = 7;
		required bool bCanCancel = 8;       //是否可取消，false不可取消，不显示关闭按钮，则必须等待服务器通知或者超时自动销毁
		optional bool bConfirmDestroy = 9;  //选择后，是否马上销毁，false，仍然停留，等待超时或服务器通知销毁
	}
	]]
	local nTimeStamp = os.time()
	if self:IsTimeOut(nTimeStamp) then  --已过期，不发送
		return
	end
	local tRetData = {}
	tRetData.nService = GF.GetServiceID()
	tRetData.nConfirmBoxID = self:GetID()
	tRetData.nSerialID = self:GetSerialID()
	tRetData.sTitle = self:GetTitle()
	local tPersonalContentList = oRoleConfirm:GetContentList()  --玩家私有定制化内容文本
	local tCommonContentList = self:GetContentList()  --通用内容文本
	if tPersonalContentList then
		tRetData.tContentList = tPersonalContentList
	elseif tCommonContentList then
		tRetData.tContentList = tCommonContentList
	else
		tRetData.tContentList = {}
	end
	local tButtonList = {}
	for k, tButton in ipairs(oRoleConfirm:GetButtonList()) do
		local tConfirmButton = {}
		tConfirmButton.nID = tButton.nButtonID
		tConfirmButton.sContent = tButton.sContent
		tConfirmButton.bActive = tButton.bActive
		table.insert(tButtonList, tConfirmButton)
	end
	tRetData.tButtonList = tButtonList
	tRetData.nTimeOut = math.max(self:GetTimeOutStamp() - nTimeStamp, 0)
	tRetData.bCanCancel = oRoleConfirm:CanCancel()
	oRole:SendMsg("MultiConfirmBoxRet", tRetData)
end

--将当前的确认框状态同步给所有玩家
function CMultiConfirmBox:SyncAllConfirmBox()
	for nRoleID, oRoleConfirm in pairs(self.m_tRoleList) do
		self:SyncRoleConfirmBox(nRoleID)
	end
end

--通知指定玩家销毁确认框
function CMultiConfirmBox:NotifyDestroyConfirmBox(nRoleID)
	local oRole = nil
	if goGPlayerMgr then
		oRole = goGPlayerMgr:GetRoleByID(nRoleID)
	else
		oRole = goPlayerMgr:GetRoleByID(nRoleID)
	end
	if not oRole then 
		return 
	end

	local oRoleConfirm = self:GetRoleConfirmData(nRoleID)
	if not oRoleConfirm then
		return
	end
	--[[
	message MultiConfirmBoxDestroyRet
	{
		required int32 nService = 1;
		required int32 nConfirmBoxID = 2;
	}
	]]
	local tRetData = {}
	tRetData.nService = GF.GetServiceID()
	tRetData.nConfirmBoxID = self:GetID()
	oRole:SendMsg("MultiConfirmBoxDestroyRet", tRetData)
end

--通知所有客户端销毁对话框
function CMultiConfirmBox:NotifyDestroyAllConfirmBox()
	for nRoleID, oRoleConfirm in pairs(self.m_tRoleList) do
		self:NotifyDestroyConfirmBox(nRoleID)
	end
end

function CMultiConfirmBox:RoleConfirmReactReq(nRoleID, nSerialID, nSelButtonID)
	local oRoleConfirm = self:GetRoleConfirmData(nRoleID)
	if not oRoleConfirm then
		print(string.format("玩家对话框不存在, 对话框ID <%d>, RoleID <%d>", self.m_nConfirmBoxID, nRoleID))
		return
	end
	if nSerialID ~= self.m_nSerialID then  --已过期的对话框提交请求，不处理，绝大部分都是因为网络延迟导致的
		return
	end
	if oRoleConfirm:IsConfirmed() then  --当前已完成了提交，不可重复提交
		return
	end

	local nCancelButtonID = gnMultiConfirmBoxCancelButtonID
	if nSelButtonID == nCancelButtonID then  --对话框取消
		local tButton = oRoleConfirm:GetButton(nSelButtonID)
		--不可取消，并且也(没有id为nCancelButtonID的button或id为nCancelButtonID的button不可操作)
		if not oRoleConfirm:CanCancel() and (not tButton or not tButton.bActive) then
			return
		end
		oRoleConfirm:SetConfirmState(gtMultiConfirmBoxRoleState.eConfirmed)
		oRoleConfirm.m_nConfirmID = nSelButtonID
		if self.m_fnOnRoleCancel then
			self.m_fnOnRoleCancel(nRoleID)
		end
		return
	else
		--检查玩家当前是否存在此按钮，并且此按钮是激活状态
		local tButton = oRoleConfirm:GetButton(nSelButtonID)
		if not tButton or not tButton.bActive then
			return
		end
		oRoleConfirm:SetConfirmState(gtMultiConfirmBoxRoleState.eConfirmed)
		oRoleConfirm.m_nConfirmID = nSelButtonID
		if self.m_fnOnRoleConfirm then
			self.m_fnOnRoleConfirm(nRoleID, nSelButtonID)
		end
		return
	end
end

