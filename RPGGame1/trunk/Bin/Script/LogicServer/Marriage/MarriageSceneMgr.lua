--结婚场景管理
local table, string, math, os, pairs, ipairs, assert = table, string, math, os, pairs, ipairs, assert


function CMarriageSceneMgr:Ctor(nSceneID)
	self.m_nSceneMixID = nSceneID

	self.m_oWedding = CWedding:new()
	self.m_oOldManItem = COldManItem:new(self)
	--花轿管理相关
	-- self.m_nPalanquinState = 0       --花轿状态  --Normal, Prepare, Busy
	-- self.m_nStateStamp = 0           --花轿状态时间戳
	self.m_tPalanquinMap = {}        --{PalanquinID:oPalanquin, ...}
	self.m_tRolePalanquinMap = {}    --{nRoleID, nID, ...}
	self.m_nPalanquinKey = 0

	self.m_nGiftTimer = nil          --TODO

	print("创建<结婚场景管理器>成功")
end

--放在场景创建函数后面，等场景创建函数创建场景后再调用
--必须要在场景管理器的init后面调用，否则会找不到场景，导致初始化错误
function CMarriageSceneMgr:Inst()  
	local nSceneID = 20  --TODO
	local tSceneConf = ctDupConf[nSceneID]
	assert(tSceneConf, "结婚场景不存在, 场景ID:"..nSceneID)
	assert(tSceneConf.nType == CDupBase.tType.eCity, "结婚场景类型配置错误")
	local oScene = goDupMgr:GetDup(nSceneID)
	if not oScene then  --如果不存在，说明，策划配置没有存放在当前逻辑服
		return
	end
	goMarriageSceneMgr = goMarriageSceneMgr or CMarriageSceneMgr:new(oScene:GetMixID())
	return goMarriageSceneMgr
end

function CMarriageSceneMgr:GetWeddingInst() return self.m_oWedding end
function CMarriageSceneMgr:GetOldManItemInst() return self.m_oOldManItem end
function CMarriageSceneMgr:GetSceneMixID() return self.m_nSceneMixID end
function CMarriageSceneMgr:GetScene() return goDupMgr:GetDup(self:GetSceneMixID()) end
function CMarriageSceneMgr:GetPalanquin(nPalanquinID) return self.m_tPalanquinMap[nPalanquinID] end
function CMarriageSceneMgr:GetPalanquinID(nRoleID) return self.m_tRolePalanquinMap[nRoleID] end
function CMarriageSceneMgr:GetPalanquinByRoleID(nRoleID)
	local nID = self:GetPalanquinID(nRoleID)
	if not nID then
		return
	end
	return self:GetPalanquin(nID)
end

function CMarriageSceneMgr:OnGiftTimer()

end

function CMarriageSceneMgr:Release() 
	self.m_oWedding:Release()
	self.m_oOldManItem:Release()
	local tPalanquinIDList = {}
	for nPalanquinID, _ in pairs(self.m_tPalanquinMap) do 
		table.insert(tPalanquinIDList, nPalanquinID)
	end
	for _, nPalanquinID in ipairs(tPalanquinIDList) do 
		self:RemovePlanquin(nPalanquinID)
	end
end

--举办婚礼请求
function CMarriageSceneMgr:WeddingReq(oRole, nTarRoleID)
	local oWedding = self:GetWeddingInst()
	oWedding:WeddingReq(oRole, nTarRoleID)
end

--婚礼级别选择
function CMarriageSceneMgr:ChoosWeddingLevelReactReq(oRole, nLevel)
	local oWedding = self:GetWeddingInst()
	oWedding:WeddingLevelChoose(oRole:GetID(), nLevel)
end

--拾取喜糖
function CMarriageSceneMgr:PickWeddingCandyReq(oRole, nAOIID, nMonsterID)
	local oDup = goMarriageSceneMgr:GetScene()
	if not oDup then
		return
	end
	local oLuaObj = self:PickCheck(oRole, nAOIID, nMonsterID, oDup)
	if oLuaObj then
		oLuaObj:PickReq(oRole, nAOIID)
	end
end

function CMarriageSceneMgr:PickCheck(oRole, nAOIID, nMonsterID, oDup)
	local tPickCfg = ctMonsterPickConf[nMonsterID]
	assert(tPickCfg, "拾取道具配置错误".. nMonsterID)
	local oNativeObj = oDup:GetObj(nAOIID)
	local sTips = gtPickItemTips[tPickCfg.nPickType]
	sTips = sTips and sTips or "手太慢了，没抢到"
	if not oNativeObj then
		oRole:Tips(sTips)
		return
	end

	local oLuaObj = GetLuaObjByNativeObj(oNativeObj)
	if not oLuaObj then
		oRole:Tips(sTips)
		return
	end

	if not oLuaObj.PickReq then
		oRole:Tips("对象不能拾取哦")
		return 
	end
	return oLuaObj
end

function CMarriageSceneMgr:GenPalanquinID()
	self.m_nPalanquinKey = self.m_nPalanquinKey % 0x7fffffff + 1
	return self.m_nPalanquinKey
end

function CMarriageSceneMgr:CreatePalanquin(nRoleID, tCouple)
	local nID = self:GenPalanquinID()
	local oPalanquin = CPalanquin:new(nID, tCouple.nHusband, tCouple.nWife)
	self.m_tPalanquinMap[nID] = oPalanquin
	self.m_tRolePalanquinMap[tCouple.nHusband] = nID
	self.m_tRolePalanquinMap[tCouple.nWife] = nID
	return oPalanquin
end

function CMarriageSceneMgr:RemovePlanquin(nID)
	local oPalanquin = self:GetPalanquin(nID)
	if oPalanquin then
		self.m_tRolePalanquinMap[oPalanquin:GetHusbandID()] = nil
		self.m_tRolePalanquinMap[oPalanquin:GetWifeID()] = nil
		self.m_tPalanquinMap[nID] = nil
		oPalanquin:Release()
	end
end

function CMarriageSceneMgr:PalanquinRentReq(oRole)
	if true then --策划要求屏蔽此功能 
		return 
	end
	assert(oRole, "参数错误")
	if oRole:GetTeamID() <= 0 then 
		oRole:Tips("请和你的伴侣组队来申请")
		return
	end
	if not oRole:IsLeader() then
		oRole:Tips("请让队长发起申请")
		return
	end
	local nRoleID = oRole:GetID()
	local nSceneMixID = oRole:GetDupMixID()
	if nSceneMixID ~= goMarriageSceneMgr:GetSceneMixID() then
		oRole:Tips("非法请求，不在相关场景")
		return
	end
	local fnCheckCallback = function (bRet, sContent, tCouple)
		if not bRet then
			-- local tRetData = {}
			-- tRetData.bPermit = false
			-- tRetData.sContent = sContent
			-- oRole:SendMsg("MarriagePalanquinRentRet", tRetData)
			if sContent then 
				oRole:Tips(sContent)
			end
			print("花轿请求失败", bRet, sContent, tCouple)
			return
		end
		--当前策划要求支持同时存在多组花轿
		local oHusband = goPlayerMgr:GetRoleByID(tCouple.nHusband)
		local oWife = goPlayerMgr:GetRoleByID(tCouple.nWife)
		if not oHusband or not oWife then
			print("丈夫或妻子不存在")
			return
		end
		if self:GetPalanquinID(tCouple.nHusband) or self:GetPalanquinID(tCouple.nWife) then
			--可能是利用bug在花轿行进途中，继续发起请求
			return
		end
		--检查当前场景是否有花轿
		--当前限制只允许存在一个花轿，前端表示目前只能处理一组花轿，等策划后续确认具体需求
		local _, oPalanquin = next(self.m_tPalanquinMap)
		if oPalanquin then 
			if oPalanquin:IsRunning() then 
				local nRemainTime = oPalanquin:GetRunRemainTime()
				if nRemainTime and nRemainTime > 0 then 
					if nRemainTime >= 60 then 
						local nMinu = math.floor(nRemainTime / 60)
						local nSec = nRemainTime % 60
						oRole:Tips(string.format("我的花轿已经租出去了，请等待%d分%d秒后再来申请", nMinu, nSec))
					else
						oRole:Tips(string.format("我的花轿已经租出去了，请等待%d秒后再来申请", nRemainTime))
					end
				else
					oRole:Tips("我的花轿已经租出去了，请稍后再来申请")
				end
			else
				oRole:Tips("现在有玩家正在申请租赁，请稍后再来申请")
			end
			return
		end

		local oPalanquin = self:CreatePalanquin(nRoleID, tCouple)
		if oPalanquin then
			oPalanquin:Start()
		end
	end	
	Network:RMCall("MarriageCheckPalanquinRentReq", fnCheckCallback, gnWorldServerID, 
		goServerMgr:GetGlobalService(gnWorldServerID, 110), 0, nRoleID)
end
