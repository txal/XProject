--帮派类
local table, string, math, os, pairs, ipairs, assert = table, string, math, os, pairs, ipairs, assert

--帮派日志上限
local nMaxLog = 10
--帮派公告上限
local nMaxUnionNotice = 20
--名字长度上限
CUnion.nMaxUnionNameLen = 18
--公告长度上限
CUnion.nMaxUnionDeclLen = 180
--最大申请数
local nMaxApplyNum = 20

--帮派职位
CUnion.tPosition = 
{
	eMengZhu = 1,		--帮主
	eFuMengZhu = 2, 	--副帮主
	eZhangLao = 3, 		--长老
	eTangZhu = 4, 		--堂主
	eJingYing = 5, 		--精英
	eChengYuan = 6, 	--成员
}

--日志类型
CUnion.tLog = 
{
	eCreate = 1,	--创建帮派
	eJoin = 2, 		--加入帮派
	eExit = 3, 		--离开帮派
	eAppoint = 4, 	--任命职位
}

--退出帮派类型
CUnion.tExit = 
{
	eExit = 1,		--主动退出
	eKick = 2,		--被移出
	eDismiss = 3, 	--解散
	eCombind = 4, 	--合并
}

--帮派对象
function CUnion:Ctor()
	self.m_nID = 0  		--公会ID
	self.m_nShowID = 0		--工会客户端显示ID
	self.m_sName = "" 		--公会名字
	self.m_nMembers = 0 	--成员数量
	self.m_nMengZhu = 0  	 --盟主ID
	self.m_tDeclaration = {} --帮派公告

	self.m_nLv = 1 			--等级
	self.m_nExp = 0 		--当前经验
	self.m_nTotalExp = 0 	--总经验
	self.m_nActivity = ctUnionEtcConf[1].nInitActivity --初始活跃度
	self.m_nAutoJoin = ctUnionEtcConf[1].nAutoJoin		--1非审批(自动); 0审批
	self.m_nTotalPower = 0 	--总战力

	self.m_tMemberMap = {} --{[nRoleID]=1}
	self.m_tFuMengZhuMap = {} --{[nRoleID]=1}
	self.m_tZhangLaoMap = {} --{[nRoleID]=1}
	self.m_tTangZhuMap = {} --{[nRoleID]=1}
	self.m_tJingYingMap = {} --{[nRoleID]=1}

	self.m_tLogList = {} --{{nLogType, sName, sName, nValue, nTime},...}
	self.m_tApplyRoleMap = {} --{[nRoleID]=time}

	self.m_tBuildMap = {} 	--建设记录
	self.m_tExchangeMap = {} --兑换记录
	self.m_nDayResetTime = os.time() --每日重置时间

	self.m_tUnionSignMap = {} 	--签到
	self.m_tCustomPosName = {} 	--自定义职务名
	self.m_nOnlineResetTime = 0 --登陆统计重置时间

	self.m_tDaySalaryMap = {} 	--上交的神诏映射{[角色编号]={[天id]=是否领取,...},...}
	self.m_tDayShenZhaoMap = {} --每日神诏{[角色编号]={[天id]={[道具id]=数量,...},...},...}

	self.m_sPurpose = ctUnionEtcConf[1].sUnionPurpose  --帮派宗旨
	self.m_tDecReadedMap = {} 		--已经读了帮派公告标记
	-- self.m_tFightArena = {}		--帮战对战过的列表 --废弃
	self.m_tFightArenaRecord = {}   --帮战对战过的列表 {}

	self.m_bSendActivityWarning = true --是否要发送低活跃公告
	self.m_tGiftBoxCnt = {}				--帮派礼盒获取信息，每周刷新
	self.m_nGiftBoxCnt = 0				--帮派礼盒库存数目
	self.m_nDupMixID = 0
end

--玩家创建帮派时调用
function CUnion:CreateInit(oRole, nID, nShowID, sName)
	local nRoleID = oRole:GetID()
	local oUnionRole = assert(goUnionMgr:GetUnionRole(nRoleID))
	self.m_nID = nID
	self.m_nShowID = nShowID
	self.m_sName = sName
	self.m_nMengZhu = nRoleID

	assert(self:JoinUnion(oRole, nRoleID))
	self:MarkDirty(true)

	goLogger:EventLog(gtEvent.eCreateUnion, oRole, self.m_nID, self.m_sName)
	goLogger:CreateUnionLog(oRole, nID, nShowID, sName, 1, oRole:GetID(), oRole:GetName(), os.time())
	return true
end

--加载帮派数据
function CUnion:LoadData(tData)
	for key, value in pairs(tData) do
		self[key] = value
	end

	--成员列表
	self.m_nMembers = 0
	for nRoleID, nFlag in pairs(self.m_tMemberMap) do
		local oUnionRole = goUnionMgr:GetUnionRole(nRoleID)
		if oUnionRole and oUnionRole:GetUnionID() == self.m_nID then
			self.m_nMembers = self.m_nMembers + 1
		else
			self.m_tMemberMap[nRoleID] = nil
			LuaTrace("帮派:", self.m_nID, "成员错误")
			self:MarkDirty(true)
		end
	end

	--盟主
	local oUnionRole = goUnionMgr:GetUnionRole(self.m_nMengZhu)
	if not oUnionRole or oUnionRole:GetUnionID() ~= self.m_nID then
		self.m_nMengZhu = 0
	end

	--盟主不在了
	if self.m_nMembers == 0 or self.m_nMengZhu == 0 then
		return goUnionMgr:OnUnionDismiss(self)
	end

	--副盟主
	for nRoleID, nFlag in pairs(self.m_tFuMengZhuMap) do
		local oUnionRole = goUnionMgr:GetUnionRole(nRoleID)
		if not oUnionRole or oUnionRole:GetUnionID() ~= self.m_nID then
			self.m_tFuMengZhuMap[nRoleID] = nil
			LuaTrace("帮派:", self.m_nID, "副盟主错误")
			self:MarkDirty(true)
		end
	end

	--长老
	for nRoleID, nFlag in pairs(self.m_tZhangLaoMap) do
		local oUnionRole = goUnionMgr:GetUnionRole(nRoleID)
		if not oUnionRole or oUnionRole:GetUnionID() ~= self.m_nID then
			self.m_tZhangLaoMap[nRoleID] = nil
			LuaTrace("帮派:", self.m_nID, "长老错误")
			self:MarkDirty(true)
		end
	end

	--堂主
	for nRoleID, nFlag in pairs(self.m_tTangZhuMap) do
		local oUnionRole = goUnionMgr:GetUnionRole(nRoleID)
		if not oUnionRole or oUnionRole:GetUnionID() == self.m_nID then
			self.m_tTangZhuMap[nRoleID] = nil
			LuaTrace("帮派:", self.m_nID, "堂主错误")
			self:MarkDirty(true)
		end
	end

	--精英
	for nRoleID, nFlag in pairs(self.m_tJingYingMap) do
		local oUnionRole = goUnionMgr:GetUnionRole(nRoleID)
		if not oUnionRole or oUnionRole:GetUnionID() ~= self.m_nID then
			self.m_tJingYingMap[nRoleID] = nil
			LuaTrace("帮派:", self.m_nID, "精英错误")
			self:MarkDirty(true)
		end
	end


	if self.m_tFightArena then 
		self.m_tFightArena = nil --清理掉无效的旧数据
		self:MarkDirty(true)
	end

	return true
end

--保存帮派数据
function CUnion:SaveData()
	local tData = {}
	tData.m_nID = self.m_nID
	tData.m_nShowID = self.m_nShowID
	tData.m_sName = self.m_sName
	tData.m_nMembers = self.m_nMembers
	tData.m_nMengZhu = self.m_nMengZhu
	tData.m_tDeclaration = self.m_tDeclaration

	tData.m_nLv = self.m_nLv
	tData.m_nExp = self.m_nExp
	tData.m_nTotalExp = self.m_nTotalExp
	tData.m_nActivity = self.m_nActivity
	tData.m_nAutoJoin = self.m_nAutoJoin
	tData.m_nTotalPower = self.m_nTotalPower

	tData.m_tMemberMap = self.m_tMemberMap
	tData.m_tFuMengZhuMap = self.m_tFuMengZhuMap
	tData.m_tZhangLaoMap = self.m_tZhangLaoMap
	tData.m_tTangZhuMap = self.m_tTangZhuMap
	tData.m_tJingYingMap = self.m_tJingYingMap

	tData.m_tLogList = self.m_tLogList
	tData.m_tApplyRoleMap = self.m_tApplyRoleMap

	tData.m_tBuildMap = self.m_tBuildMap
	tData.m_tExchangeMap = self.m_tExchangeMap
	tData.m_nDayResetTime = self.m_nDayResetTime

	tData.m_tUnionSignMap = self.m_tUnionSignMap
	tData.m_tCustomPosName = self.m_tCustomPosName
	tData.m_nOnlineResetTime = self.m_nOnlineResetTime 

	tData.m_tDaySalaryMap = self.m_tDaySalaryMap
	tData.m_tDayShenZhaoMap = self.m_tDayShenZhaoMap

	tData.m_sPurpose = self.m_sPurpose
	tData.m_tDecReadedMap = self.m_tDecReadedMap
	tData.m_tFightArenaRecord = self.m_tFightArenaRecord
	tData.m_bSendActivityWarning = self.m_bSendActivityWarning
	tData.m_tGiftBoxCnt = self.m_tGiftBoxCnt
	tData.m_nGiftBoxCnt = self.m_nGiftBoxCnt
	return tData
end

--取玩家职位
function CUnion:GetPos(nRoleID)
	local nPos = CUnion.tPosition.eChengYuan
	if self:IsMengZhu(nRoleID) then
		nPos = CUnion.tPosition.eMengZhu

	elseif self:IsFuMengZhu(nRoleID) then
		nPos = CUnion.tPosition.eFuMengZhu

	elseif self:IsZhangLao(nRoleID) then
		nPos = CUnion.tPosition.eZhangLao

	elseif self:IsTangZhu(nRoleID) then
		nPos = CUnion.tPosition.eTangZhu

	elseif self:IsJingYing(nRoleID) then
		nPos = CUnion.tPosition.eJingYing

	end
	return nPos
end

function CUnion:GetAppellationByPos(nPos)
	return ctUnionPosConf[nPos].nAppellation
end

--取职位名通过角色ID
function CUnion:GetPosName(nRoleID)
	local nPos = self:GetPos(nRoleID)
	local sPos = self.m_tCustomPosName[nPos] or ctUnionPosConf[nPos].sName
	return sPos
end

--取职位名通过职位ID
function CUnion:GetNameByPos(nPos)
	local sPos = self.m_tCustomPosName[nPos] or ctUnionPosConf[nPos].sName
	return sPos
end

function CUnion:GetID() return self.m_nID end
function CUnion:GetShowID() return self.m_nShowID end
function CUnion:GetName() return self.m_sName end
function CUnion:GetLevel() return self.m_nLv end
function CUnion:MarkDirty(bDirty) goUnionMgr:MarkUnionDirty(self.m_nID, bDirty) end
function CUnion:IsMengZhu(nRoleID) return self.m_nMengZhu == nRoleID end
function CUnion:IsFuMengZhu(nRoleID) return self.m_tFuMengZhuMap[nRoleID] end
function CUnion:IsZhangLao(nRoleID) return self.m_tZhangLaoMap[nRoleID] end
function CUnion:IsTangZhu(nRoleID) return self.m_tTangZhuMap[nRoleID] end
function CUnion:IsJingYing(nRoleID) return self.m_tJingYingMap[nRoleID] end
function CUnion:IsMember(nRoleID)
	return not (self:IsMengZhu(nRoleID) or self:IsFuMengZhu(nRoleID) or self:IsZhangLao(nRoleID) or self:IsTangZhu(nRoleID) or self:IsJingYing(nRoleID))
end
function CUnion:IsFull() return self.m_nMembers >= self:MaxMembers() end
function CUnion:IsAutoJoin() return self.m_nAutoJoin == 1 end
function CUnion:GetActivity() return self.m_nActivity end
function CUnion:GetMembers() return self.m_nMembers end
function CUnion:GetMemberMap() return self.m_tMemberMap end --成员表
function CUnion:GetMengZhu() return self.m_nMengZhu end --盟主ID

function CUnion:SetShowID(nShowID)
	self:MarkDirty(true)
	self.m_nShowID = nShowID
end

--盟主名字
function CUnion:GetMengZhuName()
	local oUnionRole = goUnionMgr:GetUnionRole(self.m_nMengZhu)
	return oUnionRole:GetName()
end

--人数上限
function CUnion:MaxMembers()
	local tConf = ctUnionLevelConf[self.m_nLv]
	return tConf.nMaxMembers
end

--当前副盟主个数
function CUnion:FuMengZhuNum()
	local nCount = 0
	for k, v in pairs(self.m_tFuMengZhuMap) do
		nCount = nCount + 1
	end 
	return nCount
end

--副盟主最大个数
function CUnion:MaxFuMengZhuNum()
	local tConf = ctUnionLevelConf[self.m_nLv]
	return tConf.nFMZNum
end

--当前长老个数
function CUnion:ZhangLaoNum()
	local nCount = 0
	for k, v in pairs(self.m_tZhangLaoMap) do
		nCount = nCount + 1
	end 
	return nCount
end

--长老最大个数
function CUnion:MaxZhangLaoNum()
	local tConf = ctUnionLevelConf[self.m_nLv]
	return tConf.nZLNum
end

--当前堂主个数
function CUnion:TangZhuNum()
	local nCount = 0
	for k, v in pairs(self.m_tTangZhuMap) do
		nCount = nCount + 1
	end 
	return nCount
end

--堂主最大个数
function CUnion:MaxTangZhuNum()
	local tConf = ctUnionLevelConf[self.m_nLv]
	return tConf.nTZNum
end

--当前精英个数
function CUnion:JingYingNum()
	local nCount = 0
	for k, v in pairs(self.m_tJingYingMap) do
		nCount = nCount + 1
	end 
	return nCount
end

--精英上限
function CUnion:MaxJingYingNum()
	local tConf = ctUnionLevelConf[self.m_nLv]
	return tConf.nJYNum
end

--退出帮派
function CUnion:ExitUnion(nRoleID, nExitType)
	if not self.m_tMemberMap[nRoleID] then
		return
	end
	local oUnionRole = goUnionMgr:GetUnionRole(nRoleID)
	if nRoleID == self.m_nMengZhu then
		return self:Dismiss() --盟主退出解散
	end
	oUnionRole:OnExitUnion(nExitType)

	self.m_tMemberMap[nRoleID] = nil
	self.m_tFuMengZhuMap[nRoleID] = nil
	self.m_tZhangLaoMap[nRoleID] = nil
	self.m_tTangZhuMap[nRoleID] = nil
	self.m_tJingYingMap[nRoleID] = nil
	self.m_nMembers = self.m_nMembers - 1
	self:MarkDirty(true)

	self:UpdatePower()
	self:AddLog(CUnion.tLog.eExit, oUnionRole:GetName(), "", 0)
	return true
end

--解散帮派
function CUnion:Dismiss()
	print("CUnion:Dismiss***")
	for nRoleID, v in pairs(self.m_tMemberMap) do
		local oUnionRole = assert(goUnionMgr:GetUnionRole(nRoleID))
		oUnionRole:OnExitUnion(CUnion.tExit.eDismiss)
	end
	goUnionMgr:OnUnionDismiss(self)

	local oRole = goGPlayerMgr:GetRoleByID(self.m_nMengZhu)
	goLogger:EventLog(gtEvent.eDismissUnion, oRole, self.m_nID)
end

--设置帮派名称
function CUnion:SetName(oRole, sName)
	sName = string.Trim(sName)
	assert(sName ~= "")
	local nRoleID = oRole:GetID()
	if not self:IsMengZhu(nRoleID) and not self:IsFuMengZhu(nRoleID) then
		return oRole:Tips("没有权限")
	end
	if string.len(sName) > CUnion.nMaxUnionNameLen then
		return oRole:Tips("名字超长，不能超过6个汉字")
	end
	local function fnCallback(bRes)
		bRes = bRes == nil and true or bRes 
		if bRes then
			return oRole:Tips("名字包含非法字符")
		end
		local sOldName = self.m_sName
		self.m_sName = sName
		self:MarkDirty(true)
		goUnionMgr:OnSetUnionName(self, sOldName)
	end
	CUtil:HasBadWord(sName, fnCallback)
end

--添加帮派公告
function CUnion:AddDeclaration(tDeclaration)
	table.insert(self.m_tDeclaration, tDeclaration)
	if #self.m_tDeclaration > nMaxUnionNotice then
		table.remove(self.m_tDeclaration, 1)
	end
	self:MarkDirty(true)
	self.m_tDecReadedMap = {}
	self:BroadcastUnionMsg("UnionDeclarationRet", {tDeclaration=self.m_tDeclaration, bRedPoint=true})
end

--设置公告
function CUnion:SetDeclarationReq(oRole, sDesc)
	sDesc = string.Trim(sDesc)
	local nRoleID = oRole:GetID()
	if not self:IsMengZhu(nRoleID) and not self:IsFuMengZhu(nRoleID) then
		return oRole:Tips("没有权限")
	end
	if string.len(sDesc) > CUnion.nMaxUnionDeclLen then
		return oRole:Tips("公告超长，不能超过60个汉字")
	end
	local function fnCallback(bRes)
		bRes = bRes == nil and true or bRes 
		if bRes then
			return oRole:Tips("公告包含非法字符")
		end
		local tDeclaration = {sDesc=sDesc, sName=oRole:GetName(), sPos=self:GetPosName(nRoleID), nTime=os.time()}
		self:AddDeclaration(tDeclaration)
		oRole:Tips("发布成功")
	end
	CUtil:HasBadWord(sDesc, fnCallback)
end

--设置宗旨
function CUnion:SetPurposeReq(oRole, sCont)
	do 
		return oRole:Tips("帮派宗旨不能修改")
	end
	sCont = string.Trim(sCont)
	local nRoleID = oRole:GetID()
	if not self:IsMengZhu(nRoleID) and not self:IsFuMengZhu(nRoleID) then
		return oRole:Tips("没有权限")
	end
	if string.len(sCont) > CUnion.nMaxUnionDeclLen then
		return oRole:Tips("宗旨超长，不能超过60个汉字")
	end
	local function fnCallback(bRes)
		bRes = bRes == nil and true or bRes 
		if bRes then
			return oRole:Tips("宗旨包含非法字符")
		end
		self.m_sPurpose = sCont
		self:MarkDirty(true)
		self:SyncDetailInfo(oRole)
		oRole:Tips("设置宗旨成功")
	end
	CUtil:HasBadWord(sCont, fnCallback)
end

--取宗旨
function CUnion:GetPurpose()
	return self.m_sPurpose
end

--设置审批否
function CUnion:SetAutoJoinReq(oRole, nAutoJoin)
	assert(nAutoJoin == 0 or nAutoJoin == 1)
	local nRoleID = oRole:GetID()
	if not self:IsMengZhu(nRoleID) and not self:IsFuMengZhu(nRoleID) then
		return oRole:Tips("没有权限")
	end
	self.m_nAutoJoin = nAutoJoin
	self:MarkDirty(true)
	self:ManagerInfoReq(oRole)
	return true
end

--扩展人数
function CUnion:ExtendMembers(oRole)
	print("CUnion:ExtendMembers***")
end

--清除进入帮派的玩家的申请信息
function CUnion:ClearRoleApply(nRoleID)
	local oUnionRole = assert(goUnionMgr:GetUnionRole(nRoleID))
	for nUnionID, nTime in pairs(oUnionRole:Get("m_tApplyUnionMap")) do
		local oUnion = goUnionMgr:GetUnion(nUnionID)
		if oUnion then
			oUnion.m_tApplyRoleMap[nRoleID] = nil
			oUnion:MarkDirty(true)
		end
	end
	oUnionRole:SetApplyUnionMap({})
	self.m_tApplyRoleMap[nRoleID] = nil
	self:MarkDirty(true)
end

--清除玩家对该帮派的申请信息
function CUnion:CancelRoleApply(nRoleID)
	if not self.m_tApplyRoleMap[nRoleID] then
		return
	end
	self.m_tApplyRoleMap[nRoleID] = nil
	local oUnionRole = assert(goUnionMgr:GetUnionRole(nRoleID))
	oUnionRole:GetApplyUnionMap()[self.m_nID] = nil
	self:MarkDirty(true)

	local oRole = goGPlayerMgr:GetRoleByID(nRoleID)
	oRole:Tips(string.format("%s帮派拒绝了您的入帮申请", self:GetName()))
end

--拒绝申请
function CUnion:RefuseApply(oRole, nTarRoleID)
	local nRoleID = oRole:GetID()
	if not self:IsMengZhu(nRoleID) and not self:IsFuMengZhu(nRoleID) then
		return oRole:Tips("没有权限")
	end
	self:CancelRoleApply(nTarRoleID)
	local oTarRole = goGPlayerMgr:GetRoleByID(nTarRoleID)
	if oTarRole then 
		oRole:Tips(string.format("已拒绝了%s的入帮申请", oTarRole:GetName()))
	else
		oRole:Tips("已拒绝了对方的入帮申请")
	end
end

--全部拒绝
function CUnion:RefuseAllApply(oRole)
	local nRoleID = oRole:GetID()
	if not self:IsMengZhu(nRoleID) and not self:IsFuMengZhu(nRoleID) then
		return oRole:Tips("没有权限")
	end
	for nRoleID, v in pairs(self.m_tApplyRoleMap) do
		self:CancelRoleApply(nRoleID)
	end
	oRole:Tips("已清理所有入帮申请")
end

--接受申请
function CUnion:AcceptApply(oRole, nTarRoleID)
	local nRoleID = oRole:GetID()
	if not self:IsMengZhu(nRoleID) and not self:IsFuMengZhu(nRoleID) then
		return oRole:Tips("没有权限")
	end
	return self:JoinUnion(oRole, nTarRoleID)
end

--全部接受
function CUnion:AcceptAllApply(oRole)
	local nRoleID = oRole:GetID()
	if not self:IsMengZhu(nRoleID) and not self:IsFuMengZhu(nRoleID) then
		return oRole:Tips("没有权限")
	end
	local tApplyList = {}
	for nRoleID, nTime in pairs(self.m_tApplyRoleMap) do
		table.insert(tApplyList, {nRoleID, nTime})
	end
	table.sort(tApplyList, function(t1, t2) return t1[2]<t2[2] end)
	for _, v in ipairs(tApplyList) do
		self:JoinUnion(oRole, v[1])
	end
end

--是否已经申请过
function CUnion:IsApplied(nRoleID)
	return (self.m_tApplyRoleMap[nRoleID] and true or false)
end

--申请进入帮派
function CUnion:ApplyJoin(oRole)
	if not goUnionMgr:IsOpen(oRole) then
		return
	end
	local nRoleID = oRole:GetID()
	local oUnionRole = goUnionMgr:GetUnionRole(nRoleID)
	if not oUnionRole then
		oUnionRole = goUnionMgr:CreateUnionRole(oRole)
	end
	if oUnionRole:GetUnionID() > 0 then
		return oRole:Tips("您已经有帮派")
	end
	--冷却
	if goUnionMgr:GetJoinCD(oRole, true) > 0 then
		return
	end
	--人数已满
	if self:IsFull() then
		return oRole:Tips("成员已满，无法加入")
	end

	--自动进入
	if self.m_nAutoJoin == 1 then
		if self:JoinUnion(nil, nRoleID) then
			return oRole:Tips(string.format("已加入%s", self.m_sName))
		end

	elseif self.m_tApplyRoleMap[nRoleID] then
	--已申请过
		return oRole:Tips("已申请过该帮派")

	else
	--增加申请
		self.m_tApplyRoleMap[nRoleID] = os.time()
		oUnionRole:GetApplyUnionMap()[self.m_nID] = os.time()
		self:MarkDirty(true)
		self:CheckApplyFull()
		oRole:Tips("申请加入帮派成功")
		return true
	end
end

--清理多余的申请
function CUnion:CheckApplyFull()
	local tApplyList = {}
	for nRoleID, nTime in pairs(self.m_tApplyRoleMap) do
		table.insert(tApplyList, {nRoleID, nTime})
	end
	if #tApplyList <= nMaxApplyNum then
		return
	end
	table.sort(tApplyList, function(t1, t2) return t1[2]<t2[2] end)
	self:ClearRoleApply(tApplyList[1][1])
end

--玩家加入帮派
function CUnion:JoinUnion(oManager, nTarRoleID)
	if self:IsFull() then
		if oManager then
			oManager:Tips("帮派人数已达到上限")
		end
		return
	end
	local oUnionRole = assert(goUnionMgr:GetUnionRole(nTarRoleID))
	if oUnionRole:GetUnionID() > 0 then
	--玩家已加入其他帮派(理论上不会到这里)
		if oManager then
			oManager:Tips(string.format("%s 已加入其它帮派", oUnionRole:GetName()))
		end
		return
	end
	self.m_tMemberMap[nTarRoleID] = true
	self.m_nMembers = self.m_nMembers + 1
	self:MarkDirty(true)	

	self:ClearRoleApply(nTarRoleID)
	oUnionRole:OnEnterUnion(self)
	self:UpdatePower()

	local nLogType = nTarRoleID == self.m_nMengZhu and CUnion.tLog.eCreate or CUnion.tLog.eJoin
	self:AddLog(nLogType, oUnionRole:GetName(), "", 0)
	local oRole = goGPlayerMgr:GetRoleByID(nTarRoleID)
	if oRole then
		self:SyncRedPointData(oRole)
		Network:RMCall("OnJoinUnion", nil, oRole:GetStayServer(), oRole:GetLogic(), oRole:GetSession(), oRole:GetID(), {})
	end
	goUnionMgr:UpdateUnionAppellation(nTarRoleID)
	return true
end

--任命职位
function CUnion:AppointPosition(oRole, nTarRoleID, nTarPos)
	local nRoleID = oRole:GetID()
	if nRoleID == nTarRoleID then
		return oRole:Tips("不能任命自己")
	end
	if not self.m_tMemberMap[nTarRoleID] then
		return oRole:Tips("目标成员不存在")
	end
	if not (self:IsMengZhu(nRoleID) or self:IsFuMengZhu(nRoleID)) then
		return oRole:Tips("您没有足够权限进行这项操作")
	end

	local sSrcPos = self:GetPosName(nRoleID)
	local nCurrPos = self:GetPos(nTarRoleID)
	local sCurrPos = self:GetPosName(nTarRoleID)
	if nCurrPos == nTarPos then
		return oRole:Tips("当前已是该职务")
	end
	if self:IsFuMengZhu(nRoleID) and (nCurrPos <= CUnion.tPosition.eFuMengZhu or nTarPos <= CUnion.tPosition.eFuMengZhu) then
		return oRole:Tips("只能任命比自己低的职位")
	end
	
	if nTarPos == CUnion.tPosition.eFuMengZhu and self:FuMengZhuNum()>=self:MaxFuMengZhuNum() then
		return oRole:Tips("这个职位的人数已经满了哦")
	end
	if nTarPos == CUnion.tPosition.eZhangLao and self:ZhangLaoNum()>=self:MaxZhangLaoNum() then
		return oRole:Tips("这个职位的人数已经满了哦")
	end
	if nTarPos == CUnion.tPosition.eTangZhu and self:TangZhuNum()>=self:MaxTangZhuNum() then
		return oRole:Tips("这个职位的人数已经满了哦")
	end
	if nTarPos == CUnion.tPosition.eJingYing and self:JingYingNum()>=self:MaxJingYingNum() then
		return oRole:Tips("这个职位的人数已经满了哦")
	end

	local oUnionRole = goUnionMgr:GetUnionRole(nTarRoleID)
	if os.time()-oUnionRole.m_nJoinTime < 3*24*3600 then
		return oRole:Tips("只有加入帮派超过三天的人才可以任命更高职务哦")
	end

	local oTarRole = goGPlayerMgr:GetRoleByID(nTarRoleID)
	if nTarPos == self.tPosition.eMengZhu then
	--转让帮主
		if not self:IsMengZhu(nRoleID) then
			return
		end
		local sCont = string.format("是否将帮主职务让给 %s（当前职务：%s）？您的职务将与对方对调。", oTarRole:GetName(), sCurrPos)
		local tMsg = {sCont=sCont, tOption={"取消", "确定"}, nTimeOut=30}
		goClientCall:CallWait("ConfirmRet", function(tData)
			if tData.nSelIdx == 1 then --取消
				return
			end
			if tData.nSelIdx == 2 then --确定
				self.m_nMengZhu = nTarRoleID
				
				if nCurrPos == CUnion.tPosition.eFuMengZhu then
					self.m_tFuMengZhuMap[nRoleID] = 1
					self.m_tFuMengZhuMap[nTarRoleID] = nil

				elseif nCurrPos == CUnion.tPosition.eZhangLao then
					self.m_tZhangLaoMap[nRoleID] = 1
					self.m_tZhangLaoMap[nTarRoleID] = nil

				elseif nCurrPos == CUnion.tPosition.eTangZhu then
					self.m_tTangZhuMap[nRoleID] = 1
					self.m_tTangZhuMap[nTarRoleID] = nil

				elseif nCurrPos == CUnion.tPosition.eJingYing then
					self.m_tJingYingMap[nRoleID] = 1
					self.m_tJingYingMap[nTarRoleID] = nil

				end
				self:MarkDirty(true)
				self:BroadcastUnionTalk(string.format("%s%s 把帮主之位转让给 %s%s", sSrcPos, oRole:GetName(), sCurrPos, oTarRole:GetName()))
				self:BroadcastUnionMsg("UnionPosChangeRet", {nRoleID=nTarRoleID, nPos=nTarPos})
				self:BroadcastUnionMsg("UnionPosChangeRet", {nRoleID=nRoleID, nPos=self:GetPos(nRoleID)})

				goUnionMgr:UpdateUnionAppellation(nTarRoleID)
				self:AddLog(CUnion.tLog.eAppoint, oRole:GetName(), oTarRole:GetName(), nCurrPos, nTarPos)

				--日志
				goLogger:EventLog(gtEvent.eAppointPos, oRole, self.m_nID, nTarRoleID, nTarPos)
				goLogger:UpdateUnionMemberLog(gnServerID, nRoleID, {position=self:GetPos(nRoleID)})
				goLogger:UpdateUnionMemberLog(gnServerID, nTarRoleID, {position=self:GetPos(nTarRoleID)})
				goLogger:UpdateUnionLog(gnServerID, self:GetID(), {leaderid=nTarRoleID, leadername=oTarRole:GetName()})
			end
		end, oRole, tMsg)

	else
	--任命其他
		if nTarPos == CUnion.tPosition.eFuMengZhu then
			self.m_tFuMengZhuMap[nTarRoleID] = 1

		elseif nTarPos == CUnion.tPosition.eZhangLao then
			self.m_tZhangLaoMap[nTarRoleID] = 1

		elseif nTarPos == CUnion.tPosition.eTangZhu then
			self.m_tTangZhuMap[nTarRoleID] = 1

		elseif nTarPos == CUnion.tPosition.eJingYing then
			self.m_tJingYingMap[nTarRoleID] = 1

		end

		if nCurrPos == CUnion.tPosition.eFuMengZhu then
			self.m_tFuMengZhuMap[nTarRoleID] = nil

		elseif nCurrPos == CUnion.tPosition.eZhangLao then
			self.m_tZhangLaoMap[nTarRoleID] = nil

		elseif nCurrPos == CUnion.tPosition.eTangZhu then
			self.m_tTangZhuMap[nTarRoleID] = nil

		elseif nCurrPos == CUnion.tPosition.eJingYing then
			self.m_tJingYingMap[nTarRoleID] = nil

		end
		self:MarkDirty(true)

		local sTarPosName = self:GetNameByPos(nTarPos)
		self:BroadcastUnionTalk(string.format("%s%s 将 %s%s 任命为 %s", sSrcPos, oRole:GetName(), sCurrPos, oTarRole:GetName(), sTarPosName))
		self:BroadcastUnionMsg("UnionPosChangeRet", {nRoleID=nTarRoleID, nPos=nTarPos})

		goUnionMgr:UpdateUnionAppellation(nTarRoleID)
		self:AddLog(CUnion.tLog.eAppoint, oRole:GetName(), oTarRole:GetName(), nCurrPos, nTarPos)

		--日志
		goLogger:EventLog(gtEvent.eAppointPos, oRole, self.m_nID, nTarRoleID, nTarPos)
		goLogger:UpdateUnionMemberLog(gnServerID, nRoleID, {position=self:GetPos(nRoleID)})
		goLogger:UpdateUnionMemberLog(gnServerID, nTarRoleID, {position=self:GetPos(nTarRoleID)})
	end
end

--剔除队员
function CUnion:KickMember(oRole, nTarRoleID)
	if not self.m_tMemberMap[nTarRoleID] then
		return print("目标队员不存在")
	end
	local nRoleID = oRole:GetID()
	if not self:IsMengZhu(nRoleID) then
		return oRole:Tips("没有权限")
	end
	if nRoleID == nTarRoleID then
		return oRole:Tips("不能移除自己")
	end
	self:ExitUnion(nTarRoleID, CUnion.tExit.eKick)
	
	local tRetMsg = {}
	tRetMsg.nRoleID = nTarRoleID
	oRole:SendMsg("UnionKickMemberRet", tRetMsg)
end

--添加帮派日志
function CUnion:AddLog(nType, sName1, sName2, nValue)
	assert(nType and sName1 and sName2 and nValue)
	local tLog = {nType, sName1, sName2, nValue, os.time()}
	table.insert(self.m_tLogList, 1, tLog)
	if #self.m_tLogList > nMaxLog then
		table.remove(self.m_tLogList)
	end
	self:MarkDirty(true)
end

--取句柄列表
function CUnion:GetSessionList()
	local tSessionList = {}
	for nRoleID, v in pairs(self.m_tMemberMap) do
		local oRole = goGPlayerMgr:GetRoleByID(nRoleID)
		if oRole:IsOnline() then
			table.insert(tSessionList, oRole:GetServer())
			table.insert(tSessionList, oRole:GetSession())
		end
	end
	return tSessionList
end

--广播帮派聊天频道
function CUnion:BroadcastUnionTalk(sCont)
	local tTalkIdent = {sName=sTitle or "系统"}
	local tTalk = {
		tHead = tTalkIdent,
		nChannel = 3,
		sCont = sCont,
		nTime = os.time(),
	}
	self:BroadcastUnionMsg("TalkRet", {tList={tTalk}})
	print("CUnion:BroadcastUnionTalk***", tTalk)
end

--广播帮派消息
function CUnion:BroadcastUnionMsg(sCmd, tMsg)
	local tSessionList = self:GetSessionList()
	Network.PBBroadcastExter(sCmd, tSessionList, tMsg)
end

--更新战力
function CUnion:UpdatePower()
	local nOldTotalPower = self.m_nTotalPower

	local nTotalPower = 0
	for nRoleID, v in pairs(self.m_tMemberMap) do
		local oRole = goGPlayerMgr:GetRoleByID(nRoleID)
		nTotalPower = nTotalPower + oRole:GetPower()
	end
	self.m_nTotalPower = nTotalPower
	self:MarkDirty(true)

	if nOldTotalPower ~= self.m_nTotalPower then
		goUnionMgr:OnUnionPowerChange(self)
	end
end

--取总战力
function CUnion:GetPower()
	return self.m_nTotalPower
end

--取帮派详细信息
function CUnion:GetDetailMsg(nRoleID)
	local oUnionRole = goUnionMgr:GetUnionRole(nRoleID)

	local nSignTime = 0
	local oRole = goGPlayerMgr:GetRoleByID(nRoleID)
	if oRole then
		nSignTime = oRole.m_oToday:Query("UnionSignTime",0)
	end
	local bSigned = os.IsSameDay(nSignTime, os.time(), 0)

	local tMsg = {}
	tMsg.nID = self.m_nID
	tMsg.sName = self.m_sName
	tMsg.nLevel = self.m_nLv
	tMsg.nExp = self.m_nExp
	tMsg.nNextExp = ctUnionLevelConf[self.m_nLv].nExp
	tMsg.nActivity = self.m_nActivity
	tMsg.nMembers = self:GetMembers()
	tMsg.nMaxMembers = self:MaxMembers()
	tMsg.nPos = self:GetPos(nRoleID)
	tMsg.sPos = self:GetPosName(nRoleID)
	tMsg.tDeclaration = self.m_tDeclaration
	tMsg.nUnionContri = oUnionRole:GetUnionContri()
	tMsg.nAutoJoin = self.m_nAutoJoin
	tMsg.sMengZhu = self:GetMengZhuName()
	tMsg.bSigned = bSigned
	tMsg.sPurpose = self.m_sPurpose
	tMsg.nShowID = self:GetShowID()
	return tMsg
end

--同步帮派详细信息
function CUnion:SyncDetailInfo(oRole)
	local nRoleID = oRole:GetID()
	local tMsg = self:GetDetailMsg(nRoleID)
	oRole:SendMsg("UnionDetailRet", tMsg)
	print("CUnion:SyncDetailInfo***", tMsg)
end

--帮派详细信息请求
function CUnion:UnionDetailReq(oRole)
	self:SyncDetailInfo(oRole)
end

function CUnion:UnionApplyReq(oRole)
	if self:ApplyJoin(oRole) then
		oRole:SendMsg("UnionApplyRet", {nUnionID=self.m_nID})
	end
end

function CUnion:UnionExitReq(oRole)
	print("CUnion:UnionExitReq***")
	local tDupConf = oRole:GetDupConf()
	if tDupConf.nID == 13 then
		oRole:Tips("帮战场景不能退出帮派")
		return
	end
	local bSucc = self:ExitUnion(oRole:GetID(), CUnion.tExit.eExit)
	if bSucc then
		goUnionMgr:UnionListReq(oRole,"",1)
	end
end

function CUnion:UpgradeReq(oRole)
	-- local nRoleID = oRole:GetID()
	-- if not self:IsMengZhu(nRoleID) and not self:IsFuMengZhu(nRoleID) then
	-- 	return oRole:Tips("没有权限")
	-- end
	-- if self.m_nLv >= #ctUnionLevelConf then
	-- 	return oRole:Tips("帮派已达等级上限")
	-- end
	-- local nNextExp = ctUnionLevelConf[self.m_nLv].nExp
	-- if self.m_nExp >= nNextExp then
	-- 	self.m_nLv = self.m_nLv + 1
	-- 	self:AddExp(-nNextExp, "帮派升级", oRole)
	-- 	self:MarkDirty(true)
	-- end
	-- self:SyncDetailInfo(oRole)
end

function CUnion:ApplyListReq(oRole)
	local tApplyList = {}
	for nTmpRoleID, nTime in pairs(self.m_tApplyRoleMap) do
		local oTmpRole = goGPlayerMgr:GetRoleByID(nTmpRoleID)
		local tInfo = {}
		tInfo.nID = nTmpRoleID
		tInfo.sName = oTmpRole:GetName()
		tInfo.sHeader = oTmpRole:GetHeader()
		tInfo.nGender = oTmpRole:GetGender()
		tInfo.nLevel = oTmpRole:GetLevel()
		tInfo.nSchool = oTmpRole:GetSchool()
		tInfo.nTime = nTime
		table.insert(tApplyList, tInfo)
	end
	local tMsg = {tApplyList=tApplyList, nMembers=self:GetMembers(), nMaxMembers=self:MaxMembers()}
	oRole:SendMsg("UnionApplyListRet", tMsg)
end

function CUnion:AcceptApplyReq(oRole, nTarRoleID)
	if nTarRoleID == 0 then
		self:AcceptAllApply(oRole)
	else
		self:AcceptApply(oRole, nTarRoleID)
	end
	self:ApplyListReq(oRole)
end

function CUnion:RefuseApplyReq(oRole, nTarRoleID)
	if nTarRoleID == 0 then --拒绝所有
		self:RefuseAllApply(oRole)
	else
		self:RefuseApply(oRole, nTarRoleID)
	end
	self:ApplyListReq(oRole)
end

function CUnion:MemberListReq(oRole)
	local tMemberList = {}
	for nRoleID, v in pairs(self.m_tMemberMap) do
		local oTmpRole = goGPlayerMgr:GetRoleByID(nRoleID)
		local oUnionRole = goUnionMgr:GetUnionRole(nRoleID)
		local tItem = {}
		tItem.nID = nRoleID
		tItem.sName = oTmpRole:GetName()
		tItem.nPos = self:GetPos(nRoleID)
		tItem.sPos = self:GetPosName(nRoleID)
		tItem.nPower = oTmpRole:GetPower()
		tItem.nContri = oUnionRole:GetUnionContri()
		tItem.nTotalContri = oUnionRole:GetTotalContri()
		tItem.bOnline = oTmpRole:IsOnline() 
		tItem.nOnlineTime = oTmpRole:GetOnlineTime()
		tItem.nSchool = oTmpRole:GetSchool()
		tItem.nLevel = oTmpRole:GetLevel()
		table.insert(tMemberList, tItem)
	end
	local tMsg = {tMemberList=tMemberList, nMembers=self:GetMembers(), nMaxMembers=self:MaxMembers(), nPower=self:GetPower()}
	oRole:SendMsg("UnionMemberListRet", tMsg)
	print("MemberListReq***", tMsg)
end

--成员详细信息请求(离线也可以看，所以只能保存到离线数据里面)
function CUnion:MemberDetailReq(oRole, nTarRoleID)
	-- local oUnionRole = goUnionMgr:GetUnionRole(nTarRoleID)
	-- local oOfflineData = goOfflineDataMgr:GetRole(nTarRoleID)

	-- local tMsg = {}
	-- tMsg.nRoleID = nTarRoleID
	-- tMsg.sName = oOfflineData.m_sName
	-- tMsg.nVIP = oOfflineData.m_nVIP 
	-- tMsg.nGuoLi = goRankingMgr.m_oGLRanking:GetRoleGuoLi(nTarRoleID)
	-- tMsg.tAttr = goRankingMgr.m_oGLRanking:GetRoleAttr(nTarRoleID)
	-- tMsg.nQinMi = goRankingMgr.m_oQMRanking:GetRoleQinMi(nTarRoleID)
	-- tMsg.nChildNum = oOfflineData.m_nChildNum
	-- tMsg.nWeiWang = goRankingMgr.m_oWWRanking:GetRoleWW(nTarRoleID)
	-- tMsg.nChapter = oOfflineData.m_nChapter

	--oRole:SendMsg("MemberDetailRet", tMsg))
end

--踢出玩家请求
function CUnion:KickMemberReq(oRole, nRoleID)
	self:KickMember(oRole, nRoleID)
end

--任命请求
function CUnion:AppointReq(oRole, nTarRoleID, nTarPos)
	self:AppointPosition(oRole, nTarRoleID, nTarPos)
end

--日志列表请求
function CUnion:LogListReq(oRole)
	local tLogList = {}
	for _, tLog in ipairs(self.m_tLogList) do
		local tItem = {}
		tItem.nType = tLog[1]
		tItem.sName1 = tLog[2]
		tItem.sName2 = tLog[3]
		tItem.nValue = tLog[4]
		tItem.nTime = tLog[5]
		table.insert(tLogList, tItem)
	end
	oRole:SendMsg("LogListRet", {tLogList=tLogList})
end

--增加活跃度
function CUnion:AddActivity(nVal, sReason, oRole)
	if nVal == 0 then return end
	self.m_nActivity = math.max(0, math.min(ctUnionEtcConf[1].nMaxActivity, self.m_nActivity+nVal))
	self:MarkDirty(true)

	local nEventID = nVal > 0 and gtEvent.eAddItem or gtEvent.eSubItem
	goLogger:AwardLog(nEventID, sReason, oRole, gtItemType.eCurr, gtCurrType.eUnionActivity, nVal, self.m_nActivity, self.m_nID)

	if self.m_nActivity < 10000 then
		if self.m_bSendActivityWarning then
			self.m_bSendActivityWarning = false
			self:MarkDirty(true)

			goUnionMgr:AddCombindUnion(self:GetID())
			local sNotice = "我帮活跃度低于10，如果不能将活跃维持在30以上，则3天后将会进入自动合并名单。(帮众每天登陆即可获得活跃度)"
			local tDeclaration = {sDesc=sNotice, sName="", sPos="", nTime=os.time()}
			self:AddDeclaration(tDeclaration)
		end
		print("帮派进入合并列表", self:GetID(), self:GetName())

	elseif self.m_nActivity >= 30000 then	
		goUnionMgr:RemoveCombindUnion(self:GetID())
		self.m_bSendActivityWarning = true
		self:MarkDirty(true)
		print("帮派移出合并列表", self:GetID(), self:GetName())

	end
end

--增加经验
function CUnion:AddExp(nVal, sReason, oRole)
	if nVal == 0 then return end
	self.m_nExp = math.max(0, math.min(gtGDef.tConst.nMaxInteger, self.m_nExp + nVal))
	self:MarkDirty(true)

	local nEventID = nVal > 0 and gtEvent.eAddItem or gtEvent.eSubItem
	goLogger:AwardLog(nEventID, sReason, oRole, gtItemType.eCurr, gtCurrType.eUnionExp, nVal, self.m_nExp, self.m_nID)

	if nVal > 0 then --总经验
		local nOldTotalExp = self.m_nTotalExp
		self.m_nTotalExp = math.max(0, math.min(gtGDef.tConst.nMaxInteger, self.m_nTotalExp+nVal))

		local nDiffValue = self.m_nTotalExp - nOldTotalExp
		if nDiffValue ~= 0 then
			goHDMgr:GetActivity(gtHDDef.eUnionExpCB):UpdateValue(self:GetID(), nDiffValue)
		end
	end

	self:CheckUpgrade()
end

--检测升级
function CUnion:CheckUpgrade()
	if self.m_nLv >= #ctUnionLevelConf then
		return
	end
	local nNextExp = ctUnionLevelConf[self.m_nLv].nExp
	if self.m_nExp < nNextExp then
		return
	end
	self.m_nLv = self.m_nLv + 1
	self.m_nExp = self.m_nExp - nNextExp
	self:MarkDirty(true)

	for nRoleID, v in pairs(self.m_tMemberMap) do
		local oRole= goGPlayerMgr:GetRoleByID(nRoleID)
		if oRole:IsOnline() then
			oRole:SendMsg("UnionDetailRet", self:GetDetailMsg(nRoleID))
		end
	end

	--日志
	goLogger:EventLog(gtEvent.eUnionUpgrade, nil, self.m_nID, self.m_nLv, self.m_nExp)
	goLogger:UpdateUnionLog(gnServerID, self:GetID(), {unionlevel=self.m_nLv})
end

--重置检查
function CUnion:CheckReset()
	if not os.IsSameDay(self.m_nDayResetTime, os.time(), 5*3600) then
		self.m_tBuildMap = {}
		self.m_tExchangeMap = {}
		self.m_nDayResetTime = os.time()
		self:MarkDirty(true)
	end

end

--建设情况请求
function CUnion:BuildInfoReq(oRole)
	-- self:CheckReset()
	-- local nBuildID = self.m_tBuildMap[oRole:GetID()] or 0
	--oRole:SendMsg("UnionBuildInfoRet", {nBuildID=nBuildID}))
end

--建设
function CUnion:BuildReq(oRole, nBuildID)
	-- self:CheckReset()
	-- --每天只能建设一次
	-- local nRoleID = oRole:GetID()
	-- if self.m_tBuildMap[nRoleID] then
	-- 	return oRole:Tips("今天已经进行过建设，明天再来吧")
	-- end
	-- local oUnionRole = assert(goUnionMgr:GetUnionRole(nRoleID))

	-- --消耗
	-- local tConf = ctUnionBuildConf[nBuildID]
	-- local tCost = tConf.tCost[1]
	-- if oRole:GetItemCount(tCost[1], tCost[2]) < tCost[3] then
	-- 	return oRole:Tips(string.format("%s 不足", CGuoKu:PropName(tCost[2])))
	-- end
	-- oRole:SubItem(tCost[1], tCost[2], tCost[3], "帮派每日建设")

	-- --奖励
	-- if tConf.nContri > 0 then	
	-- 	oUnionRole:AddUnionContri(tConf.nContri, "帮派建设获得", oRole)
	-- 	oRole:Tips(string.format("贡献 +%d", tConf.nContri))
	-- end
	-- if tConf.nExp > 0 then
	-- 	self:AddExp(tConf.nExp, "帮派建设获得", oRole)
	-- 	oRole:Tips(string.format("帮派经验 +%d", tConf.nExp))
	-- end
	-- if tConf.nActivity > 0 then
	-- 	self:AddActivity(tConf.nActivity, "帮派建设获得", oRole)
	-- 	oRole:Tips(string.format("活跃点 +%d", tConf.nActivity))
	-- end
	-- self.m_tBuildMap[nRoleID] = nBuildID
	-- self:MarkDirty(true)

	-- self:BuildInfoReq(oRole)
	-- self:SyncDetailInfo(oRole)

	-- --任务
	-- oRole.m_oDailyTask:Progress(gtDailyTaskType.eCond16, 1)
	-- --成就
	-- oRole.m_oAchievements:SetAchievement(gtAchieDef.eCond18, 1)
end

--兑换列表请求
function CUnion:ExchangeListReq(oRole)
	-- self:CheckReset()
	-- local nRoleID = oRole:GetID()

	-- local oUnionRole = assert(goUnionMgr:GetUnionRole(oRole:GetID()))
	-- local tMsg = {nLv=self.m_nLv, nContri=oUnionRole:GetUnionContri(), tList={}}
	-- local tItemMap = self.m_tExchangeMap[nRoleID] or {}
	-- for nID, nNum in pairs(tItemMap) do
	-- 	local nRemain = ctUnionExchangeConf[nID].nDayExchange - nNum
	-- 	local tItem = {nID=nID, nRemain=nRemain}
	-- 	table.insert(tMsg.tList, tItem)
	-- end
	--oRole:SendMsg("UnionExchangeListRet", tMsg))
end

--兑换请求
function CUnion:ExchangeReq(oRole, nID)
	-- self:CheckReset()

	-- local oUnionRole = assert(goUnionMgr:GetUnionRole(oRole:GetID()))
	-- local tConf = ctUnionExchangeConf[nID]
	-- if tConf.nUnionLv > self.m_nLv then
	-- 	return oRole:Tips("物品未解锁")
	-- end
	-- local nRoleID = oRole:GetID()
	-- local tItemMap = self.m_tExchangeMap[nRoleID] or {}
	-- local nNum = tItemMap[nID] or 0
	-- if nNum >= tConf.nDayExchange then
	-- 	return oRole:Tips("物品已经售罄")
	-- end
	
	-- if oUnionRole:GetUnionContri() < tConf.nContri then
	-- 	return oRole:Tips("帮派贡献不足")
	-- end
	-- oUnionRole:AddUnionContri(-tConf.nContri, "帮派兑换消耗", oRole)

	-- local tItem = tConf.tItem[1]
	-- oRole:AddItem(tItem[1], tItem[2], tItem[3], "帮派兑换获得")

	-- tItemMap[nID] = (tItemMap[nID] or 0) + 1
	-- self.m_tExchangeMap[nRoleID] = tItemMap
	--oRole:SendMsg("UnionExchangeSuccRet", {nType=tItem[1], nID=tItem[2], nNum=tItem[3]})
	-- self:MarkDirty(true)
end

--玩家上线
function CUnion:Online(oRole)
	self:CheckActivity(oRole)
	self:SyncUnionDeclaration(oRole)
	self:SyncRedPointData(oRole)
	if self:IsMengZhu(oRole:GetID()) then 
		self:UnionOpenGiftBoxReq(oRole)
	end
end

--检测活跃度增加
function CUnion:CheckActivity(oRole)
	--[[
	if os.IsSameDay(self.m_nOnlineResetTime, os.time(), 0) then
		return
	end
	local nTodayOnlineCount = 0
	for nRoleID, v in pairs(self.m_tMemberMap) do
		local oTmpRole = goGPlayerMgr:GetRoleByID(nRoleID)
		if oTmpRole:IsOnline() or os.IsSameDay(oTmpRole:GetOnlineTime(), os.time(), 0) then
			nTodayOnlineCount = nTodayOnlineCount + 1
		end
	end
	if nTodayOnlineCount >= self.m_nMembers then
		self:AddActivity(1000, "全部帮派成员登陆完成")
		self.m_nOnlineResetTime = os.time()
		self:MarkDirty(true)
	end
	]]
	--帮派成员登录，活跃度加1000
	if oRole.m_oToday:Query("unionLogin",0) <= 0 then
		oRole.m_oToday:Add("unionLogin",1)
		self:AddActivity(1000,"帮派成员登录", oRole)
	end
end

--帮派签到
function CUnion:SignReq(oRole)
	local nRoleID = oRole:GetID() 
	local nSignTime = oRole.m_oToday:Query("UnionSignTime",0)
	if os.IsSameDay(nSignTime, os.time(), 0) then
		return oRole:Tips("今日已签到，请明日再来")
	end
	self.m_tUnionSignMap[nRoleID] = os.time()
	oRole.m_oToday:Set("UnionSignTime",os.time())
	self:MarkDirty(true)

	local tConf = ctUnionEtcConf[1]
	self:AddExp(tConf.nSignExp, "帮派签到", oRole)
	oRole:SyncCurrency(gtCurrType.eUnionExp, self.m_nExp)

	local tItemList = {{nType=gtItemType.eCurr, nID=gtCurrType.eYinBi, nNum=tConf.nSignSilver}}
	oRole:AddItem(tItemList, "帮派签到")
	self:SyncDetailInfo(oRole)
	Network:RMCall("OnUnionSignIn", nil, oRole:GetStayServer(), oRole:GetLogic(), oRole:GetSession(), oRole:GetID(), {})
	self:SyncRedPointData(oRole)
end

--改职位名
function CUnion:ModPosNameReq(oRole, nPos, sPos)
	local nRoleID = oRole:GetID()
	if not self:IsMengZhu(nRoleID) and not self:IsFuMengZhu(nRoleID) then
		return oRole:Tips("没有权限")
	end
	if not ctUnionPosConf[nPos] then
		return
	end
	if self.m_tCustomPosName[nPos] == sPos then
		return
	end
	local function fnCallback(bRes)
		bRes = bRes == nil and true or bRes 
		if bRes then
			return oRole:Tips("名称包含非法字符")
		end
		self.m_tCustomPosName[nPos] = sPos
		self:MarkDirty(true)
		self:ManagerInfoReq(oRole)
		oRole:Tips("职位名修改成功")
	end
	CUtil:HasBadWord(sPos, fnCallback)
end

--同步管理信息
function CUnion:ManagerInfoReq(oRole)
	local tMsg = {sUnionName=self.m_sName, nMembers=self.m_nMembers, nMaxMembers=self:MaxMembers(), nAutoJoin=self.m_nAutoJoin, tPos={}}
	for _, nPos in pairs(CUnion.tPosition) do
		local sPos = self.m_tCustomPosName[nPos] or ctUnionPosConf[nPos].sName
		table.insert(tMsg.tPos, {nPos=nPos, sPos=sPos})
	end
	oRole:SendMsg("UnionManagerInfoRet", tMsg)
end

--自动退位
function CUnion:CheckAutoRetire()
	print("CUnion:CheckAutoRetire****")
	local function _ExchangePos(oRole, nPos)
		local nRoleID = oRole:GetID()

		local tMemberList = {}
		for nTmpRoleID, v in pairs(self.m_tMemberMap) do
			local nTmpPos = self:GetPos(nTmpRoleID)
			local oTmpRole = goGPlayerMgr:GetRoleByID(nTmpRoleID)
			if nTmpPos>nPos and oTmpRole:GetOfflineKeepTime()<3*24*3600 then
				table.insert(tMemberList, {oTmpRole, nTmpPos})
			end
		end
		if #tMemberList <= 0 then
			print(self:GetName(), "没有可继位的帮派成员")
			return
		end
		table.sort(tMemberList, function(t1, t2) return t1[2]<t2[2] end)

		local oTarRole, nTarPos
		if nPos == CUnion.tPosition.eMengZhu then
			local tMember = tMemberList[1]
			local nTmpRoleID = tMember[1]:GetID()
			self.m_nMengZhu = nTmpRoleID

			local tPosMap
			if tMember[2] == CUnion.tPosition.eFuMengZhu then
				tPosMap = self.m_tFuMengZhuMap
			elseif tMember[2] == CUnion.tPosition.eZhangLao then
				tPosMap = self.m_tZhangLaoMap
			elseif tMember[2] == CUnion.tPosition.eTangZhu then
				tPosMap = self.m_tTangZhuMap
			elseif tMember[2] == CUnion.tPosition.eJingYing then
				tPosMap = self.m_tJingYingMap
			end
			if tPosMap then
				tPosMap[nTmpRoleID] = nil
				tPosMap[nRoleID] = 1
			end

			oTarRole = tMember[1]
			nTarPos = tMember[2]

		elseif nPos == CUnion.tPosition.eFuMengZhu then
			local tMember = tMemberList[1]
			local nTmpRoleID = tMember[1]:GetID()
			self.m_tFuMengZhuMap[nTmpRoleID] = 1
			local tPosMap

			if tMember[2] == CUnion.tPosition.eZhangLao then
				tPosMap = self.m_tZhangLaoMap
			elseif tMember[2] == CUnion.tPosition.eTangZhu then
				tPosMap = self.m_tTangZhuMap
			elseif tMember[2] == CUnion.tPosition.eJingYing then
				tPosMap = self.m_tJingYingMap
			end
			if tPosMap then
				tPosMap[nTmpRoleID] = nil
				tPosMap[nRoleID] = 1
			end

			oTarRole = tMember[1]
			nTarPos = tMember[2]
		end

		if oTarRole and nTarPos then
			local sSrcPosName = self:GetNameByPos(nPos)
			local sTarPosName = self:GetNameByPos(nTarPos)
			local sNotice = "%s%s 由于三天未能处理帮派事务，暂时退位为%s。已由%s%s 接任帮主职务。"
			sNotice = string.format(sNotice, sSrcPosName, oRole:GetName(), sTarPosName, sTarPosName, oTarRole:GetName())
			local tDeclaration = {sDesc=sNotice, sName="", sPos="", nTime=os.time()}
			self:AddDeclaration(tDeclaration)
			self:MarkDirty(true)
			goLogger:EventLog(gtEvent.eUniontAutoRetire, nil, self:GetID(), oRole:GetID(),nPos,oTarRole:GetID(), nTarPos)
		    LuaTrace("帮派自动让位事件", self:GetName(), oRole:GetName(), sSrcPosName, oTarRole:GetName(), sTarPosName)
		end
	end

	local oMengZhuRole = goGPlayerMgr:GetRoleByID(self.m_nMengZhu)	
	if oMengZhuRole:GetOfflineKeepTime()>=3*24*3600 then
		_ExchangePos(oMengZhuRole, CUnion.tPosition.eMengZhu)
	end

	for nTmpRoleID, v in pairs(self.m_tFuMengZhuMap) do
		local oTmpRole = goGPlayerMgr:GetRoleByID(nTmpRoleID)
		if oTmpRole:GetOfflineKeepTime()>=3*24*3600 then
			_ExchangePos(oTmpRole, CUnion.tPosition.eFuMengZhu)
		end
	end
end

--整点到时
function CUnion:OnHourTimer()
	self:CheckAutoRetire()
	if os.Hour() == 0 then
		self:AddActivity(-ctUnionEtcConf[1].nDailyActivity, "每天降低活跃度")
		--刷周
		if os.WDay(os.time()) == 1 then
			self:ResetBoxData()
		end
	end
end

--是否可以领取俸禄
function CUnion:ValidGetSalary(oRole)
	local nRoleID = oRole:GetID()
	local oUnionRole = goUnionMgr:GetUnionRole(nRoleID)
	if os.time()-oUnionRole:GetJoinTime() < 24*3600 then
		return false
	end
	local tDayRecord = self.m_tDaySalaryMap[nRoleID] or {}
	local nDayNo = os.DayNo(os.time())
	if tDayRecord[nDayNo] then
		return false
	end

	--前一天提交的神诏数	
	local tDayShenZhaoMap = self.m_tDayShenZhaoMap[nRoleID] or {}
	local tPreDayCommit = tDayShenZhaoMap[nDayNo-1] or {}
	local nPreDayCommit = 0
	for nPropID, nNum in pairs(tPreDayCommit) do
		nPreDayCommit = nPreDayCommit + nNum
	end
	if nPreDayCommit == 0 then
		return false
	end

	return true
end

--领取帮派俸禄
function CUnion:GetSalaryReq(oRole)
	local nRoleID = oRole:GetID()
	local oUnionRole = goUnionMgr:GetUnionRole(nRoleID)
	if os.time()-oUnionRole:GetJoinTime() < 24*3600 then
		return oRole:Tips("加入帮派一天后才可领取帮派俸禄")
	end

	local tDaySalary= self.m_tDaySalaryMap[nRoleID] or {}
	local nDayNo = os.DayNo(os.time())
	if tDaySalary[nDayNo] then
		return oRole:Tips("您今日已领取过帮派俸禄了，请明日再来")
	end

	--前一天提交的神诏数	
	local tDayShenZhaoMap = self.m_tDayShenZhaoMap[nRoleID] or {}
	local tPreDayCommit = tDayShenZhaoMap[nDayNo-1] or {}
	local nPreDayCommit = 0
	for nPropID, nNum in pairs(tPreDayCommit) do
		nPreDayCommit = nPreDayCommit + nNum
	end
	if nPreDayCommit <= 0 then
		return oRole:Tips("您昨日没有上交帮派神诏，没有俸禄可领取")
	end

	--发奖
	local nGoldNum = math.min(3000, math.max(1000, math.floor(3000*(nPreDayCommit/30))))
	local tItemList = {{nType=gtItemType.eCurr, nID=gtCurrType.eJinBi, nNum=nGoldNum}}
	oRole:AddItem(tItemList, "领取帮派俸禄")

	tDaySalary[nDayNo] = 1
	self.m_tDaySalaryMap[nRoleID] = tDaySalary
	self:MarkDirty(true)

	local tTalkList = {
		"%s将帮主%s按倒在地使劲摩擦，然后从兜里掏出%d金币的工资",
		"%s抱起帮主%s一阵猛亲。然后擦了擦口水，心满意足的拿起%d金币的工资",
		"%s飞起一脚“屁屁向后平沙落雁式”将帮主%s踢飞，然后捡起%d金币的工资",
		"%s抱住帮主%s肉麻的说道：你是风儿我是沙，你是藤条我是瓜。然后捡起%d金币的工资",
	}
	local sTalk = tTalkList[math.random(#tTalkList)]
	sTalk = string.format(sTalk, oRole:GetName(), self:GetMengZhuName(), nGoldNum)	
	self:BroadcastUnionTalk(sTalk)

	oRole:Tips(string.format("昨日共上交%d个帮派神诏，获得%d金币的帮派工资", nPreDayCommit, nGoldNum))
	self:SyncRedPointData(oRole)
end

--使用神诏事件
function CUnion:OnUseShenZhao(oRole, nPropID, nPropNum, nMaxNum)
	local nRoleID = oRole:GetID()
	self.m_tDayShenZhaoMap[nRoleID] = self.m_tDayShenZhaoMap[nRoleID] or {}

	local nDayNo = os.DayNo(os.time())
	local tDayShenZhaoMap = self.m_tDayShenZhaoMap[nRoleID][nDayNo] or {}
	tDayShenZhaoMap[nPropID] = (tDayShenZhaoMap[nPropID] or 0) + nPropNum
	self.m_tDayShenZhaoMap[nRoleID][nDayNo] = tDayShenZhaoMap

	self:MarkDirty(true)
	return true
end

--取今日已使用神诏数量
function CUnion:GetUsedShenZhaoNum(oRole, nPropID)
	local nRoleID = oRole:GetID()
	self.m_tDayShenZhaoMap[nRoleID] = self.m_tDayShenZhaoMap[nRoleID] or {}

	local nDayNo = os.DayNo(os.time())
	local tDayShenZhaoMap = self.m_tDayShenZhaoMap[nRoleID][nDayNo] or {}
	return tDayShenZhaoMap[nPropID] or 0
end

--同步联盟公告
function CUnion:SyncUnionDeclaration(oRole)
	local nRoleID = oRole:GetID()

	local bRedPoint = false
	if #self.m_tDeclaration > 0 and not self.m_tDecReadedMap[nRoleID] then
		bRedPoint = true
	end
	
	oRole:SendMsg("UnionDeclarationRet", {tDeclaration=self.m_tDeclaration, bRedPoint=bRedPoint})
	-- print("CUnion:SyncUnionDeclarationRet****", bRedPoint, self.m_tDeclaration)
end

--联盟公告已读标记
function CUnion:UnionDeclarationReadedReq(oRole)
	self.m_tDecReadedMap[oRole:GetID()] = 1
	self:MarkDirty(true)
	self:SyncUnionDeclaration(oRole)
end

function CUnion:SyncRedPointData(oRole)
	local tMsg = {}
	local nRoleID = oRole:GetID()
	local nSignTime = oRole.m_oToday:Query("UnionSignTime",0)
	local bSigned = os.IsSameDay(nSignTime, os.time(), 0)
	tMsg.bSigned = bSigned
	tMsg.bSalary = self:ValidGetSalary(oRole)
	oRole:SendMsg("UnionLoginRet",tMsg)
end

function CUnion:PackUnionArenaData()
	local tRet = {}
	tRet.nUnionID = self.m_nID
	tRet.tFightArenaRecord = {}
	for k, tRecord in ipairs(self.m_tFightArenaRecord) do 
		tRet.tFightArenaRecord[tRecord.nUnionID] = tRecord.nTimeStamp
	end
	tRet.nLevel = self:GetLevel()
	tRet.nActivity = self:GetActivity()
	tRet.sName = self:GetName()
	return tRet
end

function CUnion:AddMatchArean(nEnemyUnion)
	self:MarkDirty(true)
	local nLimitNum = 5
	while #self.m_tFightArenaRecord >= nLimitNum do  
		table.remove(self.m_tFightArenaRecord, 1) 
	end
	table.insert(self.m_tFightArenaRecord, {nUnionID = nEnemyUnion, nTimeStamp = os.time()})
end

--帮战轮空
function CUnion:ArenaLunKong()
	--在线玩家发放奖励
	local sMailTitle = "跨服帮战轮空通知"
	local sMailContent = "本帮派在本轮跨服帮战活动中轮空，默认取得胜利。"
	local tRewardPoolList = goRankRewardCfg:GetRankReward(ctPVPActivityConf[1004].nRankAward, 1) or {}
	for nRoleID, v in pairs(self.m_tMemberMap) do
		local oRole= goGPlayerMgr:GetRoleByID(nRoleID)
		if oRole:IsOnline() then
			if #tRewardPoolList > 0 then 
				goRewardLaunch:MailLaunch(nRoleID, gnServerID, tRewardPoolList, 
							oRole:GetLevel(), oRole:GetConfID(), "帮战轮空奖励",
							sMailTitle, sMailContent)
			else
				CUtil:SendMail(gnServerID, sMailTitle, sMailContent, {}, nRoleID)
			end
		end
	end
end

--八荒装箱公告
function CUnion:UnionDeclarationReq()
	print("八荒装箱公告---")
end

--刷周重置数据
function CUnion:ResetBoxData()
	self:MarkDirty(true)
	self.m_tGiftBoxCnt = {}
end

function CUnion:GetBoxLimitCnt()
	return ctUnionEtcConf[1].nLimitGiftBoxCnt
end

function CUnion:AddGiftBoxCnt(nType,nBoxCnt)
	local nLimitGiftBoxCnt = self:GetBoxLimitCnt()
	local nLeftBoxCnt = self:GetLeftGiftBoxCnt()
	if nLeftBoxCnt >= nLimitGiftBoxCnt then
		return
	end
	local nAddBoxCnt = math.min(nLimitGiftBoxCnt-nLeftBoxCnt,nBoxCnt)
	if nAddBoxCnt <= 0 then
		return
	end
	self:MarkDirty(true)
	if not self.m_tGiftBoxCnt[nType] then
		self.m_tGiftBoxCnt[nType] = 0
	end
	self.m_tGiftBoxCnt[nType] = self.m_tGiftBoxCnt[nType] + nAddBoxCnt
	self.m_nGiftBoxCnt = self.m_nGiftBoxCnt + nAddBoxCnt 

	local nLeaderID = self:GetMengZhu()
	local oLeader = goGPlayerMgr:GetRoleByID(nLeaderID) 
	if oLeader and oLeader:IsOnline() then 
		self:UnionOpenGiftBoxReq(oLeader)
	end
end

function CUnion:ValidGiveGiftBox(nBoxCnt)
 	nBoxCnt = nBoxCnt or 1
 	if self.m_nGiftBoxCnt < nBoxCnt then
 		return false
 	end
 	return true
end

function CUnion:DeleteGiftBoxCnt(nCnt)
 	self:MarkDirty(true)
 	self.m_nGiftBoxCnt = math.max(self.m_nGiftBoxCnt - nCnt,0)
end

function CUnion:PackMemberGiftBoxData()
 	local tData = {}
 	for nRoleID, v in pairs(self.m_tMemberMap) do
		local oRole = goGPlayerMgr:GetRoleByID(nRoleID)
		local oUnionRole = goUnionMgr:GetUnionRole(nRoleID)
		table.insert(tData,{
			nRoleID = nRoleID,
			sName = oRole:GetName(),
			nLevel = oRole:GetLevel(),
			nPos = self:GetPos(nRoleID),
			nContri = oUnionRole:GetUnionContri(),
			nState = oUnionRole:GetGiftBoxState()
		})
	end
	return tData
end

function CUnion:GetGiftBoxReason(nType)
 	if nType == gtUnionGiftBoxReason.eUnionArena then
		return "帮派竞赛"
	elseif nType == gtUnionGiftBoxReason.eUnionExpCB then 
		return "帮派冲榜"
 	end
 	return ""
end

function CUnion:PackGiftBoxData()
 	local tData = {}
 	for nType,nCnt in pairs(self.m_tGiftBoxCnt) do
 		table.insert(tData,{sType =self:GetGiftBoxReason(nType),nCnt = nCnt})
 	end
 	return tData
end

function CUnion:GetLeftGiftBoxCnt()
 	return self.m_nGiftBoxCnt or 0
end

function CUnion:UnionOpenGiftBoxReq(oRole)
 	local tMsg = {}
 	tMsg.tMemGiftData = self:PackMemberGiftBoxData()
 	tMsg.tUnionGiftData = self:PackGiftBoxData()
	tMsg.nGiftBoxCnt = self:GetLeftGiftBoxCnt()
	tMsg.bCanDispatch = false 
	if self:GetLeftGiftBoxCnt() > 0 and self:IsMengZhu(oRole:GetID()) then 
		tMsg.bCanDispatch = true 
	end
 	oRole:SendMsg("UnionOpenGiftBoxRet",tMsg)
end

function CUnion:UnionDispatchGiftReq(oRole,tRoleID)
 	tRoleID = tRoleID or {}
 	if not self:IsMengZhu(oRole:GetID()) then
 		oRole:Tips("只有帮主可以发放礼盒")
 		return
 	end
 	for _,nRoleID in pairs(tRoleID) do
 		local oUnionRole = goUnionMgr:GetUnionRole(nRoleID)
 		if oUnionRole:GetGiftBoxState() ~= 0 then
 			oRole:Tips("数据错误")
 			return
 		end
 	end
 	local nBoxCnt = table.Count(tRoleID)
 	if nBoxCnt <= 0 then
 		oRole:Tips("请选择接收礼盒的玩家")
 		return
 	end
 	if not self:ValidGiveGiftBox(nBoxCnt) then
 		oRole:Tips("礼盒数目不足，无法发放")
 		return
 	end
 	self:DeleteGiftBoxCnt(nBoxCnt)
 	--发送奖励
 	local sTitle = "获得帮派礼盒"
 	local sMailContent = "由于你本周表现活跃，现给你发放帮派礼盒，望以后继续加油！"
 	for _,nRoleID in pairs(tRoleID) do
 		local oUnionRole = goUnionMgr:GetUnionRole(nRoleID)
 		if oUnionRole then
 			oUnionRole:SetDispatchGiftBoxTime()
 			local tMailItemList = {
				{gtItemType.eProp,11342,1}
			}
			goMailMgr:SendMail(sTitle, sMailContent, tMailItemList, nRoleID)
 		end
 	end
 	self:UnionOpenGiftBoxReq(oRole)
 	oRole:Tips("帮派礼盒发放成功")
end

function CUnion:GetDupMixID()
 	return self.m_nDupMixID or 0
end

function CUnion:SetDupMixID(nDupMixID)
 	self.m_nDupMixID = nDupMixID
end

function CUnion:CreateUnionScene()
 	local nUnionID = self:GetID()
 	local fnCallback = function (nDupMixID)
 		local oUnion = goUnionMgr:GetUnion(nUnionID)
 		if oUnion then
 			oUnion:SetDupMixID(nDupMixID)
 		end
 	end
 	local nDupID = 12
 	local tDupConf = ctDupConf[nDupID]
 	local tParam = {
 		nNoAutoCollected = 1
 	}
 	Network:RMCall("CreateDup", fnCallback, gnServerID, tDupConf.nLogic, 0, nDupID,tParam)
end

function CUnion:UnionEnterSceneReq(oRole)
 	if not self.m_nDupMixID or self.m_nDupMixID == 0 then
 		return
 	end
	local nRoleID = oRole:GetID()
 	local nDupMixID = self:GetDupMixID()
 	Network:RMCall("RoleEnterDup", nil,oRole:GetServer(),oRole:GetLogic(),0,nRoleID,nDupMixID,{nPosX=0,nPosY=0})
end

function CUnion:RemoveDup()
 	local nDupMixID = self:GetDupMixID()
 	if nDupMixID == 0 then
 		return
 	end
 	local nDupID = 12
 	local tDupConf = ctDupConf[nDupID]
 	local nServiceID = tDupConf.nLogic
 	Network:RMCall("RemoveUnionDup", nil, gnServerID,nServiceID,0, nDupMixID)
end