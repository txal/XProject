  --伙伴模块
local table, string, math, os, pairs, ipairs, assert = table, string, math, os, pairs, ipairs, assert


local nCollectTicketPropID = 20005    --灵石采集令ID

function CPartner:Ctor(oRole)
	self.m_oRole = oRole
	self.m_tPartnerMap = {} 	--伙伴ID对象映射{[id]=obj,...}
	self.m_tPlanMap = {}      --{ PlanID : {Pos : PartnerID, ...}, ...}
	for k, v in pairs(gtPartnerPlanID) do
		self.m_tPlanMap[v] = {}  --一共4个上阵位置[1 - 4]
	end
	self.m_nUsePlan = gtPartnerPlanID.eBattle1 		--使用方案

	self.m_nMaterialCollectCount = 0  --灵石采集许可
	self.m_tMaterialStone =     --灵石碎片 {nMaterialID : nNum}
	{
		[gtCurrType.ePartnerStoneGreen] = 0, 
		[gtCurrType.ePartnerStoneBlue] = 0, 
		[gtCurrType.ePartnerStonePurple] = 0, 
		[gtCurrType.ePartnerStoneOrange] = 0, 
	} 

	self.m_nAddSpiritStamp = 0   --灵气操作时间戳


	--招募提示
	local tRecruitTipsData = {}
	tRecruitTipsData.bTips = false
	tRecruitTipsData.tRecruitList = {}   --{nPartnerID:{}, ...} 方便以后扩展
	tRecruitTipsData.tIgnoreList = {}    --{nPartnerID:{}, ...}
	self.m_tRecruitTipsData = tRecruitTipsData

	--升星提示
	self.m_tAddStarTipsList = {}  --{nPartnerID:{}, ...} 方便以后扩展

	self.m_tXianzhenData = {}                   --仙阵数据
	self.m_tXianzhenData.nLevel = 0
	self.m_tXianzhenData.nExp = 0
	self.m_tXianzhenData.tAttrList = {}
end

function CPartner:LoadData(tData)
	if not tData then
		return
	end
	local nRoleLevel = self.m_oRole:GetLevel() -- 此时角色基础数据已经load完成
	for nID, tPartner in pairs(tData.m_tPartnerMap) do
		if ctPartnerConf[nID] then
			local oPartner = self:CreatePartner(tPartner.m_nID, nRoleLevel)
			oPartner:LoadData(tPartner)
			--oPartner:SetLevel(nRoleLevel) -- 修正下等级
			self.m_tPartnerMap[oPartner.m_nID] = oPartner
		end
	end
	--不能直接引用旧table，会导致新增的plandata数据为nil
	for k, v in pairs(tData.m_tPlanMap) do
		if self.m_tPlanMap[k] then --可能有旧类型的PlanData被丢弃不用了
			for _, nPartnerID in ipairs(v) do
				if nPartnerID > 0 and ctPartnerConf[nPartnerID] then
					table.insert(self.m_tPlanMap[k], nPartnerID)
				end
			end
		end
	end
	self.m_nUsePlan = tData.m_nUsePlan
	self.m_nMaterialCollectCount = tData.m_nMaterialCollectCount
	--不能直接引用，可能新版本增加新的类型，这里引用了旧table，导致丢失构造函数中添加的新增类型，在后续取值变nil
	--self.m_tMaterialStone = tData.m_tMaterialStone 
	for k, v in pairs(tData.m_tMaterialStone) do
		self.m_tMaterialStone[k] = v
	end

	self.m_nAddSpiritStamp = tData.m_nAddSpiritStamp or 0

	if tData.m_tRecruitTipsData then 
		self.m_tRecruitTipsData = tData.m_tRecruitTipsData 
	end

	--处理下，可能由于配置表更改删除导致的招募提示数据错误
	local tTipsData = self.m_tRecruitTipsData

	local tTempList = table.DeepCopy(tTipsData.tRecruitList)
	for k, v in pairs(tTempList) do 
		if not ctPartnerConf[k] or self:FindPartner(k) then 
			tTipsData.tRecruitList[k] = nil 
			self:MarkDirty(true)
		end 
	end
	local tTempList = table.DeepCopy(tTipsData.tIgnoreList)
	for k, v in pairs(tTempList) do 
		if not ctPartnerConf[k] or self:FindPartner(k) then 
			tTipsData.tIgnoreList[k] = nil 
			self:MarkDirty(true)
		end 
	end
	if tTipsData.bTips and not next(tTipsData.tRecruitList) then 
		tTipsData.bTips = false 
		self:MarkDirty(true)
	end

	self.m_tXianzhenData = tData.m_tXianzhenData or self.m_tXianzhenData

	self:UpdateAddStarTips()  --切换逻辑服会导致数据丢失，需要重新生成
end

function CPartner:SaveData()
	if not self:IsDirty() then
		return
	end
	self:MarkDirty(false)

	local tData = {}
	tData.m_tPartnerMap = {}
	for nID, oPartner in pairs(self.m_tPartnerMap) do
		tData.m_tPartnerMap[oPartner.m_nID] = oPartner:SaveData()
	end
	tData.m_tPlanMap = self.m_tPlanMap
	tData.m_nUsePlan = self.m_nUsePlan
	tData.m_nMaterialCollectCount = self.m_nMaterialCollectCount
	tData.m_tMaterialStone = self.m_tMaterialStone
	tData.m_nAddSpiritStamp = self.m_nAddSpiritStamp
	tData.m_tRecruitTipsData = self.m_tRecruitTipsData
	tData.m_tXianzhenData = self.m_tXianzhenData
	return tData
end

function CPartner:GetType()
	return gtModuleDef.tPartner.nID, gtModuleDef.tPartner.sName
end

function CPartner:GetObj(nID) return self.m_tPartnerMap[nID] end

--检查伙伴方案ID是否是一个有效ID值
function CPartner:CheckPlanIDValid(nPlanID)
	for k, v in pairs(gtPartnerPlanID) do
		if v == nPlanID then
			return true
		end
	end
	return false
end

--获取指定planID的上阵方案
function CPartner:GetPlan(nPlanID)
	if not self:CheckPlanIDValid(nPlanID) then
		return
	end
	return self.m_tPlanMap[nPlanID]
end

--获取当前使用的上阵方案
function CPartner:GetUsePlan() 
	local tUsePlan = self:GetPlan(self.m_nUsePlan)
	return tUsePlan
end

--取战斗伙伴列表``
function CPartner:GetBattlePartner(bArena)
	local tList = {}
	local tPlan = nil
	if bArena then
		--竞技场，要求如果玩家有设置竞技场方案，则使用竞技场方案，否则使用当前方案
		local tArenaPlan = self:GetPlan(gtPartnerPlanID.eArenaDefense)
		local bExist = false
		for k, v in ipairs(tArenaPlan) do
			if v > 0 then
				bExist = true
				break
			end
		end
		if bExist then
			tPlan = tArenaPlan
		end
	else
		tPlan = self:GetUsePlan() or {}
	end
	for k, v in ipairs(tPlan) do
		if v > 0 then
			local oObj = self:GetObj(v)
			if oObj then
				table.insert(tList, oObj)
			end
		end
	end
	return tList
end

--WGLOBAL队伍取伙伴信息
function CPartner:WGlobalTeamPartnerReq()
	local nFmtID, nFmtLv = self.m_oRole.m_oFormation:GetUseFmt()
	local tPartnerInfo = {nFmtID=nFmtID, nFmtLv=nFmtLv, tPartner={}}

	local function _GetPartnerInfo(oObj)
		local tInfo = {}
		tInfo.nID = oObj:GetID()
		tInfo.nType = oObj:GetType()
		tInfo.sName = oObj:GetName()
		tInfo.sHeader = oObj:GetHeader()
		tInfo.nGender = oObj:GetGender()
		tInfo.nLevel = oObj:GetLevel()
		tInfo.nSchool = oObj:GetSchool()
		return tInfo
	end

	local tPartnerList = self:GetBattlePartner()
	for k, v in pairs(tPartnerList) do
		table.insert(tPartnerInfo.tPartner, _GetPartnerInfo(v))
	end
	return tPartnerInfo
end

--WGLOBAL家园取伙伴信息
function CPartner:WGlobalHousePartnerReq()
	print("CPartner:WGlobalTeamPartnerReq***")

	local tData = {}
	for nPartnerID,oPartnerObj in pairs(self.m_tPartnerMap) do
		table.insert(tData,{
			nPartnerID = nPartnerID,
			nIntimacy = oPartnerObj:GetIntimacy(),
			sName = oPartnerObj:GetName()
		})
	end
	return tData
end

--获取灵石数量
function CPartner:GetPartnerStoneNum(nStoneID)
	return self.m_tMaterialStone[nStoneID]
end

--添加灵石数量
function CPartner:AddPartnerStoneNum(nStoneID, nNum)
    if nStoneID ~= gtCurrType.ePartnerStoneGreen 
        and nStoneID ~= gtCurrType.ePartnerStoneBlue 
        and nStoneID ~= gtCurrType.ePartnerStonePurple 
        and nStoneID ~= gtCurrType.ePartnerStoneOrange then
        return
    end
    self.m_tMaterialStone[nStoneID] = math.max(0, math.min(self.m_tMaterialStone[nStoneID] + nNum, gtGDef.tConst.nMaxInteger))
    self.m_oRole:SyncCurrency(nStoneID, self:GetPartnerStoneNum(nStoneID))
	self:MarkDirty(true)
	self:UpdateAddStarTips(true)
    return self.m_tMaterialStone[nStoneID]
end

--创建伙伴
function CPartner:CreatePartner(nPartnerID, nLevel)
	if nLevel and nLevel < 0 then
		nLevel = 0
	end
	local oPartner = CPartnerObj:new(self, nPartnerID, nLevel)
	return oPartner
end

function CPartner:AutoBattleActive(nPartnerID)
	local oPartner = self:FindPartner(nPartnerID)
	assert(oPartner)
	--自动上阵
	for nPlanID, tPlanData in pairs(self.m_tPlanMap) do 
		if not self:IsBattleActive(nPlanID, nPartnerID) then 
			if #tPlanData < 4 then 
				self:BattleActiveReq(nPlanID, nPartnerID)
			end
		end
	end
end

function CPartner:OnPartnerAdd(nPartnerID)
	if not nPartnerID or nPartnerID <= 0 then return end
	-- local bFirst = false --是否是第一个伙伴
	-- if not next(self.m_tPartnerMap) then
	-- 	bFirst = true
	-- end
	self:AutoBattleActive(nPartnerID)
	self:UpdateRecruitTips()
	self:OnPartnerPowerChange() --主动调用一下，否则不会触发自动更新
	self:UpdateAddStarTips(true)
	self.m_oRole:UpdateActGTPartnerPowerSum()
end

--添加伙伴
function CPartner:AddPartner(nPartnerID, sReason)
	if(nPartnerID <= 0) then
		return false
	end
	local oPartner = self:FindPartner(nPartnerID)
	if oPartner then
		--self.m_oRole:Tips("该伙伴当前已招募！")
		return false
	end
	local tConf = ctPartnerConf[nPartnerID]
	if not tConf then
		return false
	end
	oPartner = self:CreatePartner(nPartnerID, self.m_oRole:GetLevel())
	if not oPartner then
		return false
	end
	--走一遍save、load流程，进行一些必要的初始化操作
	local tData = oPartner:SaveData()
	oPartner:LoadData(tData)

	self.m_tPartnerMap[nPartnerID] = oPartner
	self:MarkDirty(true)
	oPartner:UpdateProperty()  --更新战力等信息
	if sReason then --某些情况，不需要记log，比如机器人或者临时角色对象等等添加伙伴
		goLogger:AwardLog(gtEvent.eAddItem, sReason, self.m_oRole, gtItemType.ePartner, nPartnerID, 1, true)
	end
	local tRetData = {}
	tRetData.tPartner = oPartner:GetDetailData()
	self.m_oRole:SendMsg("PartnerRecruitRet", tRetData)

	self:OnPartnerAdd(nPartnerID)
	self.m_oRole:PushAchieve("仙侣数量",{nValue=1})
	return true
end

--查找伙伴
function CPartner:FindPartner(nPartnerID)
	return self.m_tPartnerMap[nPartnerID]
end

--检查该伙伴招募状态，true已招募，false未招募
function CPartner:CheckRecruitState(nPartnerID)
	if nPartnerID <= 0 then
		return false
	end
	local oPartner = self:FindPartner(nPartnerID)
	if oPartner then
		return true
	end
	return false
end

--获取招募伙伴需要的材料
function CPartner:RecruitMaterial(nPartnerID)
	local tRecruitCost = ctPartnerConf[nPartnerID].nRecruitCost[1]
	return tRecruitCost[1], tRecruitCost[2]
end

-- function CPartner:AddPartnerWithRsp(nPartnerID)
-- 	if self:FindPartner(nPartnerID) then  --伙伴是唯一的，不可重复获取，已存在的，直接返回true
-- 		return true
-- 	end
-- 	local oPartner = self:AddPartner(nPartnerID)
-- 	if oPartner then
-- 		--[[
-- 		local tData = {}
-- 		tData.tPartner = oPartner:GetDetailData()
-- 		self.m_oRole:SendMsg("PartnerRecruitRet", tData)
-- 		self:MarkDirty(true)
-- 		]]
-- 		return true
-- 	end
-- 	return false
-- end

--招募伙伴
function CPartner:RecruitPartnerReq(nPartnerID)
	if nPartnerID <= 0 then
		return
	end
	local tConf = ctPartnerConf[nPartnerID]
	if not tConf then
		return
	end

	local oPartner = self:FindPartner(nPartnerID)
	if oPartner ~= nil then
		self.m_oRole:Tips("该伙伴当前已招募")
		return
	end

	if self.m_oRole:GetLevel() < tConf.nRecruitLevel then
		self.m_oRole:Tips(string.format("招募%s需角色等级达到%d级", tConf.sName, tConf.nRecruitLevel))
		return
	end

	local nMaterialID, nMaterialCount = self:RecruitMaterial(nPartnerID)
	-- if nMaterialID <= 0 or nMaterialCount < 0 then
	-- 	self.m_oRole:Tips("不消耗材料")
	-- end

	if nMaterialCount > 0 then --为0，不消耗
		if not self.m_oRole:CheckSubItem(gtItemType.eProp, nMaterialID, nMaterialCount, "招募伙伴") then
			self.m_oRole:Tips(string.format("%s不足，无法招募", ctPropConf[nMaterialID].sName))
			return
		end
	end
	self:AddPartner(nPartnerID, "招募请求")
end

--添加灵石采集许可次数
function CPartner:AddMaterialCollectCount(nCount)
	self.m_nMaterialCollectCount = math.max(0, math.min(self.m_nMaterialCollectCount + nCount, gtGDef.tConst.nMaxInteger))
    self.m_oRole:SyncCurrency(gtCurrType.ePartnerStoneCollect, self.m_nMaterialCollectCount)
    self:MarkDirty(true)
    return self.m_nMaterialCollectCount 
end

--获取灵石采集许可次数
function CPartner:GetMaterialCollectCount()
	return self.m_nMaterialCollectCount
end

--获取灵石采集许可次数购买价格
function CPartner:GetMaterialCollectPrice()
	local tConf = ctPropConf[nCollectTicketPropID]
	return tConf.nYuanBaoType, tConf.nBuyPrice
end

--购买灵石采集许可次数
function CPartner:AddMaterialCollectCountReq(nCount)	
	if nCount <= 0 then
		return
	end
	print("购买灵石采集许可令数量:"..nCount)
	local nCurrType, nPrice = self.GetMaterialCollectPrice()
	local nCost = nPrice * nCount
	if not self.m_oRole:CheckSubItem(gtItemType.eCurr, nCurrType, nCost, "购买灵石采集许可令") then
		self.m_oRole:YuanBaoTips()
		return
	end
	self.m_oRole:AddItem(gtItemType.eCurr, gtCurrType.ePartnerStoneCollect, nCount, "购买灵石采集许可令")
	local tData = {}
	tData.nAddCount = nCount
	tData.nTotalCount = self.m_nMaterialCollectCount
	self.m_oRole:SendMsg("PartnerAddMaterialCollectCountRet", tData)
end

--采集一次需要消耗的采集许可次数、必定最大消耗的元宝次数
function CPartner:GetCollectStoneCost(nPropID) --灵石对应的道具ID，非灵石货币类型ID
	local tConf = ctPartnerStoneCollectCostConf[nPropID]
	assert(tConf, "配置不存在")
	return tConf.nCollectCountCost, tConf.nMaxCost
end

--采集灵石
function CPartner:CollectPartnerStone(nPropID, nGridID, nCount, bMax) --采集灵石道具ID，选择的格子ID，采集次数
	print("CollectPartnerStone: PropID:"..nPropID.." nCount:"..nCount)
	if not nPropID or not nGridID or not nCount or nCount > 10 then  --不允许10次以上，防止恶意参数，占用cpu
		self.m_oRole:Tips("参数不正确")
		return 
	end
	local tCostConf = ctPartnerStoneCollectCostConf[nPropID]
	if not tCostConf then
		self.m_oRole:Tips("道具ID错误，无法采集")
		return
	end
    local tPropConf = ctPropConf[nPropID]
    if not tPropConf or tPropConf.nType ~= gtPropType.eCurr then
    	print("采集的道具类型不正确，道具ID:"..nPropID)
    	return -- 不是灵石道具，可能策划配置错误
    end

    local nStoneID = tPropConf.nSubType
    if nStoneID ~= gtCurrType.ePartnerStoneGreen 
        and nStoneID ~= gtCurrType.ePartnerStoneBlue 
        and nStoneID ~= gtCurrType.ePartnerStonePurple 
        and nStoneID ~= gtCurrType.ePartnerStoneOrange 
        then
        return
    end
    if nCount <= 0 then
    	self.m_oRole:Tips("采集数量不正确")
    	return
    end

	if self.m_oRole:GetLevel() < tCostConf.nLevelLimit then
    	self.m_oRole:Tips(
			string.format("采集%s需要角色等级达到%d级", tPropConf.sName, tCostConf.nLevelLimit))
		return
	end

    --计算需要消耗的道具
    local nCollectCountCost, nYuanbaoCost = self:GetCollectStoneCost(nPropID)
    print("-------- 灵石采集 DEBUG ----------")
    print("nPropID:", nPropID)
    print("nCollectCountCost:", nCollectCountCost)
    print("nYuanbaoCost:", nYuanbaoCost)
    print("nCount:", nCount)
    print("nGridID:", nGridID)
    print("bMax:", bMax)
    print("-------- 灵石采集 DEBUG ----------")
    nCollectCountCost = nCollectCountCost * nCount
    nYuanbaoCost = nYuanbaoCost * nCount
    if not bMax then
    	nYuanbaoCost = 0
    end
    local tCost = {{gtItemType.eCurr, gtCurrType.ePartnerStoneCollect, nCollectCountCost}, {gtItemType.eCurr, gtCurrType.eAllYuanBao, nYuanbaoCost}, }
    if self.m_oRole:ItemCount(gtItemType.eCurr, gtCurrType.ePartnerStoneCollect) < nCollectCountCost then
    	self.m_oRole:Tips("灵石采集许可令不足")
    	return
    end
    if nYuanbaoCost > 0 then
    	if self.m_oRole:ItemCount(gtItemType.eCurr, gtCurrType.eAllYuanBao) < nYuanbaoCost then
	    	self.m_oRole:YuanBaoTips()
	    	return
    	end
    end

    --计算每个格子的奖励
    local nTotalGrid = 5  --总共5个格子
    if nGridID < 1 or nGridID > 5 then --错误参数
    	self.m_oRole:Tips("不正确的采集格子")
    	return
    end
	local tGridReward = {0, 0, 0, 0, 0}
	
	local tStoneConfColorID = {
		[gtCurrType.ePartnerStoneGreen] = 1,
		[gtCurrType.ePartnerStoneBlue] = 2,
		[gtCurrType.ePartnerStonePurple] = 3,
		[gtCurrType.ePartnerStoneOrange] = 4,
	}

	local nStoneColorID = tStoneConfColorID[nStoneID]
	assert(nStoneColorID)

    local fnGetCollectConfWeight = function (tConfNode)
    	return tConfNode.nWeight
	end

	local tCheckParam = {}
	local nMaxLevelConfID = 0
	if bMax then 
		for k, tTempConf in pairs(ctPartnerStoneCollectConf) do 
			if tTempConf.nColor == nStoneColorID then 
				if 0 == nMaxLevelConfID then 
					nMaxLevelConfID = tTempConf.nRewardID
				elseif tTempConf.nRewardNum[1][2] > ctPartnerStoneCollectConf[nMaxLevelConfID].nRewardNum[1][2] then 
					nMaxLevelConfID = tTempConf.nRewardID
				end
			end
		end
	end
	tCheckParam.nMaxLevelConfID = nMaxLevelConfID


	local fnCheckRandValid = function(tConfNode, tCheckParam)
		if tConfNode.nColor ~= nStoneColorID or tConfNode.nRewardID == tCheckParam.nMaxLevelConfID then 
			return false
		end
		return true
	end

    for i = 1, nCount do
    	if bMax then
    		for j = 1, nTotalGrid do --每个格子都是独立抽取的，所以多次迭代
    			local nRandNum = 0
    			local tConf = nil
				if j == nGridID then
					assert(nMaxLevelConfID > 0)
					tConf = ctPartnerStoneCollectConf[nMaxLevelConfID] 
		    	else
		    		--剩余非抽取到的格子，填充二三档奖励
		    		local tRandResult = CWeightRandom:CheckNodeRandom(ctPartnerStoneCollectConf, fnGetCollectConfWeight, 1, false, fnCheckRandValid, tCheckParam)
		    		if not tRandResult or #tRandResult < 1 then --计算结果出错
						return
		    		end
		    		for _, tValue in pairs(tRandResult) do --正常只有一个元素tRandResult[1]
		    			tConf = tValue
    					break
		    		end
				end
				assert(tConf)
    			nRandNum = math.random(tConf.nRewardNum[1][1], tConf.nRewardNum[1][2])
		    	tGridReward[j] = tGridReward[j] + nRandNum
	    	end
    	else
    		for j = 1, nTotalGrid do
    			local nRandNum = 0
    			local tConf = nil
    			local tRandResult = CWeightRandom:CheckNodeRandom(ctPartnerStoneCollectConf, fnGetCollectConfWeight, 1, false, fnCheckRandValid, tCheckParam)
    			if not tRandResult or #tRandResult < 1 then --计算结果出错
    				return
    			end
	    		for _, tValue in pairs(tRandResult) do --正常只有一个元素tRandResult[1]
	    			tConf = tValue
	    			break
				end
				assert(tConf)
	    		nRandNum = math.random(tConf.nRewardNum[1][1], tConf.nRewardNum[1][2])
		    	tGridReward[j] = tGridReward[j] + nRandNum
	    	end
		end
		CEventHandler:OnExcavateStone(self.m_oRole, {})
    end

	local nRewardNum = tGridReward[nGridID]
    if nRewardNum <= 0 then
    	LuaTrace("灵石采集数量错误, nRewardNum:"..nRewardNum)
    	return
    end

    --奖励计算完成再消耗玩家道具，防止配置表出现错误或者计算错误，提前结束，导致扣除了玩家道具但没给奖励
    if not self.m_oRole:CheckSubItemList(tCost, "灵石采集") then
    	self.m_oRole:Tips("材料不足，无法采集")
    	return
    end

    --添加奖励
    self.m_oRole:AddItem(gtItemType.eProp, nPropID, nRewardNum, "灵石采集")
	--[[
	message PartnerStoneCollectRet
	{
		required int32 nPropID = 1;       // 灵石道具ID
		required int32 nStoneID =  2;     // 灵石ID(货币类型)
		required int32 nGridID = 3;      // 选择的格子ID[1-5]
		required int32 nCount = 4;       // 请求的采集次数
		required bool bMax = 5;          // 请求是否必定最大
		required int32 nRewardNum = 6;   // 获得的奖励的数量
		repeated KeyValue tGridRewardList = 7; // 所有的格子奖品列表
	}
	]]
    local tData = {}
    tData.nPropID = nPropID
    tData.nStoneID = nStoneID
    tData.nGridID = nGridID
    tData.nCount = nCount
    tData.bMax = bMax
    tData.nRewardNum = nRewardNum
    tData.tGridRewardList = {}
    for k, v in ipairs(tGridReward) do
    	tData.tGridRewardList[#tData.tGridRewardList + 1] = {nKey = k, nValue = v}
    end
	self.m_oRole:SendMsg("PartnerStoneCollectRet", tData)
end

-- 获取CS协议用的PlanData
function CPartner:GetCSPlanData(nPlanID)
	if not self:CheckPlanIDValid(nPlanID) then
		assert(false, "无效的属性方案ID")
	end
	local tPlan = self:GetPlan(nPlanID) 
	--[[
	message PartnerPlanData
	{
		required int32 nPlanID = 1;
		repeated int32 tPartnerIDList = 2;  // 上阵伙伴列表 4个元素
	}
	]]
	local tData = {}
	tData.nPlanID = nPlanID
	tData.tPartnerIDList = {}
	for k, v in ipairs(tPlan) do --{pos : partnerID} pos[1 - 4]
		tData.tPartnerIDList[k] = v
	end
	return tData
end

function CPartner:IsBattleActive(nPlanID, nPartnerID)
	assert(nPlanID and nPartnerID, "参数错误")
	local tTargetPlan = self:GetPlan(nPlanID)
	assert(tTargetPlan)

	for k, v in  pairs(tTargetPlan) do
		if v == nPartnerID then
			return true 
		end
	end
	return false
end

--伙伴上阵请求
function CPartner:BattleActiveReq(nPlanID, nPartnerID)
	local tTargetPlan = self:GetPlan(nPlanID)
	if not tTargetPlan then
		self.m_oRole:Tips("非法的上阵方案")
		return
	end
	if nPartnerID <= 0 or not self:CheckRecruitState(nPartnerID) then
		self.m_oRole:Tips("当前伙伴未招募！")
		return
	end

	if self:IsBattleActive(nPlanID, nPartnerID) then 
		self.m_oRole:Tips("该伙伴当前已上阵")
		return 
	end

	if #tTargetPlan >= 4 then
		self.m_oRole:Tips("当前上阵位置已满，请先将其他伙伴下阵")
		return
	end
	local nPos = #tTargetPlan + 1
	--tTargetPlan[nPos] = nPartnerID	
	table.insert(tTargetPlan, nPartnerID)
	self:MarkDirty(true)

	local tData = {}
	tData.nPlanID = nPlanID
	tData.tPlanData = self:GetCSPlanData(nPlanID)
	tData.nPos = nPos

	self.m_oRole:SendMsg("PartnerBattleActiveRet", tData)
end

--伙伴下阵请求
function CPartner:BattleRestReq(nPlanID, nPos)
	local tTargetPlan = self:GetPlan(nPlanID)
	if not tTargetPlan then
		self.m_oRole:Tips("非法的上阵方案")
		return
	end
	if nPos < 1 or nPos > 4 then
		self.m_oRole:Tips("非法上阵位置!")
		return
	end
	if #tTargetPlan <= 0 then
		self.m_oRole:Tips("当前上阵方案没有伙伴上阵哦")
		return
	end
	if nPos > #tTargetPlan then
		self.m_oRole:Tips("当前位置没有上阵伙伴")
		return
	end

	local nPartnerID = tTargetPlan[nPos]
	local nRestPartnerID = tTargetPlan[nPos]
	--tTargetPlan[nPos] = 0
	table.remove(tTargetPlan, nPos)

	local tData = {}
	tData.nPlanID = nPlanID
	tData.tPlanData = self:GetCSPlanData(nPlanID)
	tData.nPos = nPos
	tData.nRestPartnerID = nRestPartnerID
	self.m_oRole:SendMsg("PartnerBattleRestRet", tData)
end

--伙伴上阵方案切换请求
function CPartner:SwitchPlanReq(nPlanID)
	if not self:CheckPlanIDValid(nPlanID) then
		self.m_oRole:Tips("非法的上阵方案")
		return
	end
	--竞技防御方案，不可设置为当前使用方案
	if nPlanID == gtPartnerPlanID.eArenaDefense then
		self.m_oRole:Tips("非法的上阵方案")
		return
	end
	if self.m_nUsePlan == nPlanID then --无需处理，不响应
		return
	end

	local nOldPlanID = self.m_nUsePlan
	self.m_nUsePlan = nPlanID
	self:MarkDirty(true)

	local tData = {}
	tData.nOldPlanID = nOldPlanID
	tData.nCurPlanID = self.m_nUsePlan
	self.m_oRole:SendMsg("PartnerSwitchPlanRet", tData)
end

--交换上阵伙伴位置请求
function CPartner:PlanSwapPosReq(nPlanID, nPos1, nPos2)
	assert(nPlanID and nPos1 and nPos2)
	if not self:CheckPlanIDValid(nPlanID) then
		self.m_oRole:Tips("非法的上阵方案")
		return
	end
	if (nPos1 < 1 or nPos1 > 4) or (nPos2 < 1 or nPos2 > 4) or nPos1 == nPos2 then 
		self.m_oRole:Tips("不正确的交换位置")
		return 
	end
	local tPlan = self:GetPlan(nPlanID)
	if not tPlan then 
		return 
	end
	local nPartner1 = tPlan[nPos1]
	local nPartner2 = tPlan[nPos2]
	if (not nPartner1 or nPartner1 < 1) or (not nPartner2 or nPartner2 < 1) then 
		self.m_oRole:Tips("目标位置没有上阵伙伴")
		return
	end
	tPlan[nPos1] = nPartner2
	tPlan[nPos2] = nPartner1
	self:MarkDirty(true)
	
	local tMsg = {}
	tMsg.nPlanID = nPlanID
	tMsg.nPos1 = nPos1
	tMsg.nPos2 = nPos2
	tMsg.tPlanData = self:GetCSPlanData(nPlanID)
	self.m_oRole:SendMsg("PartnerPlanSwapPosRet", tMsg)
end

--获取伙伴详细数据 --同步客户端用
function CPartner:GetPartnerDetailData(nPartnerID)
	local oPartner = self:FindPartner(nPartnerID)
	assert(oPartner, "ID:"..nPartnerID.."伙伴未招募")
	local tData = oPartner:GetDetailData()
	return tData
end

--同步伙伴模块数据
function CPartner:SyncPartnerBlockData()
	local tData = {}
	tData.tPartnerList = {}
	-- for k, oPartner in pairs(self.m_tPartnerMap) do
	-- 	local tPartnerBriefData = oPartner:GetBriefData()
	-- 	table.insert(tData.tPartnerList, tPartnerBriefData)
	-- end
	for k, oPartner in pairs(self.m_tPartnerMap) do
		local tPartnerDetailData = oPartner:GetDetailData()
		table.insert(tData.tPartnerList, tPartnerDetailData)
	end
	tData.tPlanDataList = {}
	for nPlanDataID, tPlanPartnerData in pairs(self.m_tPlanMap) do
		local tPlanData = self:GetCSPlanData(nPlanDataID)
		table.insert(tData.tPlanDataList, tPlanData)
	end
	tData.nUsePlanID = self.m_nUsePlan
	tData.nMaterialCollectCount = self.m_nMaterialCollectCount
	tData.tStoneDataList = {}
	for nStoneID, nNum in pairs(self.m_tMaterialStone) do
		table.insert(tData.tStoneDataList, {nPartnerStoneID = nStoneID, nPartnerStoneNum = nNum})
	end
	tData.bDailyAddSpiritOp = (not self:CheckAddSpiritStamp())
	self.m_oRole:SendMsg("PartnerBlockDataRet", tData)
end

--获取伙伴详细数据
function CPartner:SyncPartnerDetailData(nPartnerID)
	if not self:CheckRecruitState(nPartnerID) then
		self.m_oRole:Tips("该伙伴未招募！")
		return
	end
	local tData = {}
	tData.tPartnerDetail = self:GetPartnerDetailData(nPartnerID)
	self.m_oRole:SendMsg("PartnerDetailRet", tData)
end

--获取所有伙伴详细数据
function CPartner:SyncPartnerListDetailData(nPartnerID)
	local tData = {}
	tData.tPartnerList = {}
	for k, oPartner in pairs(self.m_tPartnerMap) do
		local tPartnerDetail = oPartner:GetDetailData()
		tData.tPartnerList[#tData.tPartnerList + 1] = tPartnerDetail
	end
	self.m_oRole:SendMsg("PartnerListRet", tData)
end

--点亮伙伴星级星星
function CPartner:AddStarCountReq(nPartnerID)
	local oPartner = self:FindPartner(nPartnerID)
	if not oPartner then
		self.m_oRole:Tips("当前未招募该仙侣！")
		return
	end

	--暂时不允许升到5级后继续学习
	if oPartner:IsMaxStarLevel() then
		self.m_oRole:Tips("当前仙侣已达最高星级")
		return
	end
	if oPartner:IsMaxStarCount() then 
		self.m_oRole:Tips("仙侣已点亮当前星级所有属性")
		return 
	end

	local nLimitLevel = 30
	if self.m_oRole:GetLevel() < nLimitLevel then 
		self.m_oRole:Tips(string.format("%d级开放仙侣升星功能", nLimitLevel))
		return 
	end

	local nMaterialID, nMaterialNum = oPartner:GetStarLevelMaterial()
	if nMaterialID == nil or nMaterialNum == nil then
		return
	end
	if nMaterialID > 0 and nMaterialNum > 0 then
		if not self.m_oRole:CheckSubItem(gtItemType.eProp, nMaterialID, nMaterialNum, "伙伴星级点亮星星") then
			self.m_oRole:Tips(string.format("%s不足", ctPropConf[nMaterialID].sName))		
			return
		end
	end
	local nOldStarLevel, nOldStarCount = oPartner:GetStarLevel()
	oPartner:AddStarCount()
	oPartner:UpdateProperty()
	self:SyncPartnerDetailData(nPartnerID)
	self:MarkDirty(true)
	self.m_oRole:UpdateActGTPartnerPowerSum()
	--[[
	message PartnerAddStarCountRet
	{
		required int32 nPartnerID = 1;        // 伙伴ID
		required int32 nOldStarLevel = 2;
		required int32 nOldStarCount = 3;
		required int32 nNewStarLevel = 4;
		required int32 nNewStarCount = 5;
		//required PartnerDetailData tPartner = 6; // 伙伴数据
	}
	]]
	local tData = {}
	tData.nPartnerID = nPartnerID
	tData.nOldStarLevel = nOldStarLevel
	tData.nOldStarCount = nOldStarCount
	tData.nNewStarLevel, tData.nNewStarCount = oPartner:GetStarLevel()
	self.m_oRole:SendMsg("PartnerAddStarCountRet", tData)
end

function CPartner:StarLevelUpReq(nPartnerID)
	local oPartner = self:FindPartner(nPartnerID)
	if not oPartner then
		self.m_oRole:Tips("当前未招募该伙伴！")
		return
	end
	if oPartner:IsMaxStarLevel() then
		self.m_oRole:Tips("该仙侣当前已达到最大星级")
		return
	end
	if not oPartner:IsMaxStarCount() then 
		self.m_oRole:Tips("升级需要点亮当前星级所有属性")
		return 
	end
	local nNewStar, sPasSkillName = oPartner:StarLevelUp()
	self:SyncPartnerDetailData(nPartnerID)
	local tRetMsg = {}
	tRetMsg.nPartnerID = nPartnerID
	tRetMsg.nStarLevel = oPartner:GetStarLevel()
	self.m_oRole:SendMsg("PartnerStarLevelUpRet", tRetMsg)

	--传闻
	if nNewStar and sPasSkillName and ctHearsayConf["partnerstarup"] then
		CUtil:SendHearsayMsg(string.format(ctHearsayConf["partnerstarup"].sHearsay, self.m_oRole:GetName(), oPartner:GetName(), nNewStar, sPasSkillName))
	end
	self.m_oRole:UpdateActGTPartnerPowerSum()
end

function CPartner:GetPartnerGiftConf() return ctPartnerGiftConf end  --伙伴礼物配置
--检查是否是伙伴礼物道具
function CPartner:CheckIsPartnerGiftProp(nPropID)
	if nPropID <= 0 then
		return false
	end
	--暂时不根据类型，直接查伙伴配置表，存在配置表，则返回true
	local tConfTbl = CPartner:GetPartnerGiftConf()
	if tConfTbl[nPropID] then 
		return true 
	end
	return false
end


--给伙伴送礼
function CPartner:SendGiftReq(nPartnerID, tProp)  -- tProp = {propID : propNum, }
	if not self:CheckRecruitState(nPartnerID) then
		self.m_oRole:Tips("该伙伴当前未招募")
		return
	end
	local oPartner = self:FindPartner(nPartnerID)
	if not oPartner then
		return
	end
	local nOldIntimacy = oPartner:GetIntimacy()
	print("SendGifgReq PartnerID:"..nPartnerID)

	local tAddData = {}
	local bLimitNumTips = false
	for nPropID, nPropNum in pairs(tProp) do
		print("Sec2 PropID:"..nPropID.." Num:"..nPropNum)
		if nPropID <= 0 or nPropNum <= 0 then --非法数据，直接退出
			return
		end
		if not CPartner:CheckIsPartnerGiftProp(nPropID) then
			self.m_oRole:Tips("不能给伙伴赠送该道具")
			return
		end
		local bCanAdd, nAddLimitNum = oPartner:CheckCanSendGiftProp(nPropID)
		if bCanAdd and nAddLimitNum > 0 then
			if nPropNum > nAddLimitNum then
				nPropNum = nAddLimitNum
			end
			--检查背包道具是否足够
			local nKeepNum = self.m_oRole:ItemCount(gtItemType.eProp, nPropID)
			if nKeepNum < nPropNum then
				nPropNum = nKeepNum  --如果数量不够，修正到当前实际持有数量
			end
			if nPropNum > 0 then
				tAddData[nPropID] = nPropNum
			else
				self.m_oRole:Tips(string.format("%s不足", ctPropConf[nPropID].sName))
				--这里不需要退出，继续迭代下一组物品
			end
		else
			bLimitNumTips = true
		end
	end

	local bAddFlag = false
	for nPropID, nAddNum in pairs(tAddData) do
		local tConf = ctPartnerGiftConf[nPropID]
		if not tConf then			
			print("Sec3 ConfigError")
			return
		end
		if not oPartner.m_tAttr[tConf.nAttrType] then --属性类型必须是合法存在的
			assert(false, "属性类型错误")
			return
		end
		--在assert后面，避免错误扣除玩家道具	
		if not self.m_oRole:CheckSubItem(gtItemType.eProp, nPropID, nAddNum, "伙伴赠送礼物") then
			print("Sec4 PropNum not enough")
			return
		end
		local tGiftData = {}
		tGiftData[nPropID] = nAddNum
		oPartner:SendGift(tGiftData)
		bAddFlag = true
		self:MarkDirty(true)

		local tData = {}
		tData.nAddNum = nAddNum
		CEventHandler:OnGiveSthToPartner(self.m_oRole, tData)
		self.m_oRole:UpdateActGTPartnerPowerSum()
	end
	if bAddFlag then
		-- oPartner:UpdateProperty()
		self:SyncPartnerDetailData(oPartner.m_nID)
	elseif bLimitNumTips then --没有实际送礼物，并且bLimitNumTips触发，则提示。如果一次送出多种礼物，只要存在1种成功送礼，则不提示
		self.m_oRole:Tips("伙伴可收礼物已达上限，请提升自身等级来增加可收礼物上限")
		return
	else
		return
	end

	--[[
	message PropIDNum
	{
		required int32 nPropID = 1;   // 道具ID
		required int32 nPropNum = 2;  // 道具数量
	}
	message PartnerSeedGiftRet
	{
		required int32 nPartnerID = 1;       // 伙伴ID
		repeated PropIDNum tPropList = 2;    // 实际送出的礼物列表
	}
	]]
	local tData = {}
	tData.nPartnerID = nPartnerID
	tData.tPropList = {}
	for k, v in pairs(tAddData) do
		tData.tPropList[#tData.tPropList + 1] = {nPropID = k, nPropNum = v}
	end
	tData.nIntimacyAdd = math.max(0, oPartner:GetIntimacy() - nOldIntimacy)
	self.m_oRole:SendMsg("PartnerSendGiftRet", tData)
end

function CPartner:CheckAddSpiritStamp()
	nTimeStamp = nTimeStamp or os.time()
	if os.IsSameDay(self.m_nAddSpiritStamp, nTimeStamp, 0) then 
		return false 
	end
	return true 
end

function CPartner:SetSpiritOpStamp(nTimeStamp)
	nTimeStamp = nTimeStamp or os.time()
	self.m_nAddSpiritStamp = nTimeStamp
	self:MarkDirty(true)
end

--增加灵气
function CPartner:AddSpiritReq(nPartnerID, nConfID)
	if true then  
		self.m_oRole:Tips("此功能未开放")
		return 
	end
	if not (nPartnerID and nPartnerID > 0 and nConfID and nConfID > 0) then 
		return self.m_oRole:Tips("请求数据错误")
	end
	local oPartner = self:FindPartner(nPartnerID)
	if not oPartner then
		self.m_oRole:Tips("指定伙伴未招募")
		return
	end
	local tSpiritConf = ctPartnerSpiritConf[nConfID]
	if not tSpiritConf then 
		print("参数不正确:", nConfID)
		return
	end
	if not self:CheckAddSpiritStamp() then 
		return false, "今日已服用"
	end
	local bCanAdd, sTipsContent = oPartner:CheckCanAddSpirit()
	if not bCanAdd then 
		if sReason then 
			self.m_oRole:Tips(sTipsContent)
		end
		return
	end
	local tCost = {}
	for k, v in ipairs(tSpiritConf.tMoneyCost) do 
		if v[1] > 0 and v[2] > 0 then 
			table.insert(tCost, {gtItemType.eProp, v[1], v[2]})
		end
	end
	for k, v in ipairs(tSpiritConf.tMaterialCost) do 
		if v[1] > 0 and v[2] > 0 then 
			table.insert(tCost, {gtItemType.eProp, v[1], v[2]})
		end
	end
	if #tCost > 0 then 
		if not self.m_oRole:CheckSubShowNotEnoughTips(tCost, "伙伴增加灵气") then 
			return 
		end
	end
	local nOldSpirit = oPartner:GetSpirit()
	local nOldGrade = oPartner:GetGrade()
	oPartner:AddSpirit(tSpiritConf.nAddSpirit)
	-- oPartner:SetSpiritOpStamp()
	self:SetSpiritOpStamp()
	self:MarkDirty(true)
	local nNewSpirit = oPartner:GetSpirit()
	local nNewGrade = oPartner:GetGrade()
	local tRetData = {}
	tRetData.nPartnerID = nPartnerID
	tRetData.nConfID = nConfID
	tRetData.nOldSpirit = nOldSpirit
	tRetData.nNewSpirit = nNewSpirit
	tRetData.bGradeLevelUp = (nOldGrade ~= nNewGrade)
	self.m_oRole:SendMsg("PartnerAddSpiritRet", tRetData)
	self.m_oRole:UpdateActGTPartnerPowerSum()
end

--更新可招募伙伴提示
function CPartner:UpdateRecruitTips()
	local nLevel = self.m_oRole:GetLevel()
	local tTipsData = self.m_tRecruitTipsData

	local bChange = false
	for nPartnerID, tConf in pairs(ctPartnerConf) do 
		local oPartner = self:FindPartner(nPartnerID)
		if not oPartner and tConf.nRecruitLevel > 0 then 
			if (tConf.nRecruitLevel <= nLevel) and (not tTipsData.tIgnoreList[nPartnerID]) then
				tTipsData.bTips = true
				if not tTipsData.tRecruitList[nPartnerID] then 
					tTipsData.tRecruitList[nPartnerID] = {}
					bChange = true
				end
			end
		else 
			if tTipsData.tRecruitList[nPartnerID] then 
				tTipsData.tRecruitList[nPartnerID] = nil 
				bChange = true
			end
			if tTipsData.tIgnoreList[nPartnerID] then 
				tTipsData.tIgnoreList[nPartnerID] = nil
				self:MarkDirty(true) --前端不需要关注
			end 
		end
	end

	if tTipsData.bTips and not next(tTipsData.tRecruitList) then 
		tTipsData.bTips = false 
		bChange = true 
	end
	if bChange then 
		self:MarkDirty(true)
		self:SyncRecruitTips()
	end
end

function CPartner:CloseRecruitTips()
	local tTipsData = self.m_tRecruitTipsData
	tTipsData.bTips = false
	for nPartnerID, tPartnerData in pairs(tTipsData.tRecruitList) do 
		tTipsData.tIgnoreList[nPartnerID] = {}
	end
	tTipsData.tRecruitList = {}

	self:MarkDirty(true)
	self:SyncRecruitTips()
end

function CPartner:SyncRecruitTips()

	local tTipsData = self.m_tRecruitTipsData
	local tMsg = {}
	tMsg.bTips = tTipsData.bTips
	tMsg.tPartnerList = {}
	for nPartnerID, tPartnerData in pairs(tTipsData.tRecruitList) do 
		table.insert(tMsg.tPartnerList, nPartnerID)
	end
	self.m_oRole:SendMsg("PartnerRecruitTipsRet", tMsg)
end

function CPartner:UpdateAddStarTips(bSync)
	local oRole = self.m_oRole
	local bChange = false
	for nPartnerID, oPartner in pairs(self.m_tPartnerMap) do 
		local bTips = false 
		if not (oPartner:IsMaxStarLevel() or oPartner:IsMaxStarCount()) then 
			local nMaterialID, nMaterialNum = oPartner:GetStarLevelMaterial()
			if nMaterialID and nMaterialNum > 0 then 
				if oRole:ItemCount(gtItemType.eProp, nMaterialID) >= nMaterialNum then 
					bTips = true 
				end
			end
		end

		if bTips then 
			if not self.m_tAddStarTipsList[nPartnerID] then 
				self.m_tAddStarTipsList[nPartnerID] = {}
				bChange = true
			end
		else
			if self.m_tAddStarTipsList[nPartnerID] then 
				self.m_tAddStarTipsList[nPartnerID] = nil
				bChange = true
			end
		end
	end

	if bChange and bSync then 
		self:SyncAddStarTips()
	end
end

function CPartner:SyncAddStarTips()
	local tMsg = {}
	local tData = {}
	for nPartnerID, _ in pairs(self.m_tAddStarTipsList) do 
		table.insert(tData, nPartnerID)
	end
	tMsg.tPartnerList = tData
	self.m_oRole:SendMsg("PartnerAddStarTipsRet", tMsg)
end

function CPartner:OnRoleLevelChange(nNewLevel)
	for k, oPartner in pairs(self.m_tPartnerMap) do
		oPartner:SetLevel(nNewLevel)
	end
	self:UpdateRecruitTips()
	self:MarkDirty(true)
	self.m_oRole:UpdateActGTPartnerPowerSum()
	return
end

function CPartner:Online() 
	for k, oPartnerObj in pairs(self.m_tPartnerMap) do 
		oPartnerObj:Online()
	end

	-- local tSyncStone = {
	-- 	gtCurrType.ePartnerStoneGreen, 
	-- 	gtCurrType.ePartnerStoneBlue,
	-- 	gtCurrType.ePartnerStonePurple,
	-- 	gtCurrType.ePartnerStoneOrange,
	-- }
	-- for _, nStoneID in ipairs(tSyncStone) do 
	-- 	self.m_oRole:SyncCurrency(nStoneID, self:GetPartnerStoneNum(nStoneID))
	-- end
	self:SyncPartnerBlockData()

	self:UpdateRecruitTips()
	self:SyncRecruitTips()
	self:UpdateAddStarTips()
	self:SyncAddStarTips()
end

--有伙伴战力发生变化
function CPartner:OnPartnerPowerChange()
	self.m_nTmpPartnerPowerSum = 0
	self.m_oRole:UpdateColligatePower()
end

--取最高的N个伙伴战力和
function CPartner:GetPartnerPowerSum(nNum)
	self.m_nTmpPartnerPowerSum = self.m_nTmpPartnerPowerSum or 0
	if self.m_nTmpPartnerPowerSum > 0 then
		return self.m_nTmpPartnerPowerSum
	end

	local tList = {}
	for k, oPartner in pairs(self.m_tPartnerMap) do
		table.insert(tList, oPartner)
	end
	table.sort(tList, function(o1, o2) return o1:GetFightAbility()>o2:GetFightAbility() end)

	for k = 1, nNum do
		local oPartner = tList[k]
		if oPartner then
			self.m_nTmpPartnerPowerSum = self.m_nTmpPartnerPowerSum + oPartner:GetFightAbility()
		end
 	end
 	return self.m_nTmpPartnerPowerSum
end

function CPartner:GetAllPartnerPowerSum()
	local nSum = 0
	for k, oPartner in pairs(self.m_tPartnerMap) do
		nSum = nSum + oPartner:GetFightAbility()
	end
	return nSum
end

function CPartner:GetXianzhenGrowthID()
	return 5
end

function CPartner:IsXianzhenSysOpen(bTips)
	return self.m_oRole:IsSysOpen(94, bTips)
end

function CPartner:GetXianzhenLevel()
	return self.m_tXianzhenData and self.m_tXianzhenData.nLevel or 0
end

function CPartner:GetXianzhenLimitLevel()
	local nID = self:GetXianzhenGrowthID()
	return math.min(self.m_oRole:GetLevel() * 8, ctRoleGrowthConf.GetConfMaxLevel(nID))
end

function CPartner:SetXianzhenLevel(nLevel)
	local nID = self:GetXianzhenGrowthID()
	assert(nLevel > 0 and nLevel <= ctRoleGrowthConf.GetConfMaxLevel(nID))
	self.m_tXianzhenData.nLevel = nLevel
	self:MarkDirty(true)
end

function CPartner:GetXianzhenExp()
	return self.m_tXianzhenData and self.m_tXianzhenData.nExp or 0
end

function CPartner:GetXianzhenAttr()
	if not self:IsXianzhenSysOpen() then 
		return {}
	end
	return self.m_tXianzhenData.tAttrList
end

function CPartner:GetXianzhenAttrRatio()
	local nID = self:GetXianzhenGrowthID()
	local tConf = ctRoleGrowthConf[nID]
	return tConf.nRatio or 1
end

function CPartner:GetXianzhenScore()
	if not self:IsXianzhenSysOpen() then 
		return 0
	end
	return math.floor(self:GetXianzhenLevel()*1000*self:GetXianzhenAttrRatio())
end

function CPartner:UpdateXianzhenAttr()
	local nParam = self:GetXianzhenScore()
	self.m_tXianzhenData.tAttrList = self.m_oRole:CalcModuleGrowthAttr(nParam) or {}
end

function CPartner:OnXianzhenLevelChange()
	self:UpdateXianzhenAttr()
	self.m_oRole:UpdateAttr()
end

function CPartner:AddXianzhenExp(nAddExp)
	local nID = self:GetXianzhenGrowthID()
	local nCurLevel = self:GetXianzhenLevel()
	local nLimitLevel = self:GetXianzhenLimitLevel()
	local nCurExp = self:GetXianzhenExp()
	local nTarLevel, nTarExp = ctRoleGrowthConf.AddExp(nID, nCurLevel, nLimitLevel, nCurExp, nAddExp)
	self:SetXianzhenLevel(nTarLevel)
	self.m_tXianzhenData.nExp = nTarExp
	self:MarkDirty(true)
	if nCurLevel ~= nTarLevel then 
		self:OnXianzhenLevelChange()
	end
end

function CPartner:SyncXianzhenData()
	local tMsg = {}
	tMsg.nLevel = self.m_tXianzhenData.nLevel
	tMsg.nExp = self.m_tXianzhenData.nExp
	tMsg.tAttrList = {}
	for nAttrID, nAttrVal in pairs(self.m_tXianzhenData.tAttrList) do 
		table.insert(tMsg.tAttrList, {nAttrID = nAttrID, nAttrVal = nAttrVal})
	end
	tMsg.nScore = self:GetXianzhenScore()
	self.m_oRole:SendMsg("PartnerXianzhenInfoRet", tMsg)
end

function CPartner:XianzhenLevelUpReq()
	if not self:IsXianzhenSysOpen(true) then 
		return 
	end
	local oRole = self.m_oRole
	local nGrowthID = self:GetXianzhenGrowthID()
	local nCurLevel = self:GetXianzhenLevel()
	local nLimitLevel = self:GetXianzhenLimitLevel()
	local nCurExp = self:GetXianzhenExp()
	if nCurLevel >= ctRoleGrowthConf.GetConfMaxLevel(nGrowthID) then 
		oRole:Tips("当前已达最高等级")
		return 
	end
	if nCurLevel >= nLimitLevel then 
		oRole:Tips("已达到当前限制等级，请先提升角色等级")
		return 
	end

	local nMaxAddExp = ctRoleGrowthConf.GetMaxAddExp(nGrowthID, nCurLevel, nLimitLevel, nCurExp)
	if nMaxAddExp <= 0 then 
		oRole:Tips("当前已达最高等级")
		return 
	end
	local tCost = ctRoleGrowthConf.GetExpItemCost(nGrowthID, nMaxAddExp)
	assert(next(tCost))
	local nItemType = tCost[1]
	local nItemID = tCost[2]
	local nMaxItemNum = tCost[3]
	assert(nItemType > 0 and nItemID > 0 and nMaxItemNum > 0)
	local nKeepNum = oRole:ItemCount(nItemType, nItemID)
	if nKeepNum <= 0 then 
		oRole:Tips("材料不足，无法升级")
		return 
	end
	local nCostNum = math.min(nKeepNum, nMaxItemNum)
	local nAddExp = ctRoleGrowthConf.GetItemExp(nGrowthID, nItemType, nItemID, nCostNum)
	assert(nAddExp and nAddExp > 0)

	local tCost = {{nItemType, nItemID, nCostNum}, }
	if not oRole:CheckSubShowNotEnoughTips(tCost, "仙侣仙阵升级", true) then 
		return 
	end
	self:AddXianzhenExp(nAddExp)
	self:SyncXianzhenData()

	local nResultLevel = self:GetXianzhenLevel()
	local sContent = nil 
	local sModuleName = "仙阵"
	local sPropName = ctPropConf:GetFormattedName(nItemID) --暂时只支持道具
	if nResultLevel > nCurLevel then 
		local sTemplate = "消耗%d个%s, %s等级提升到%d级"
		sContent = string.format(sTemplate, nCostNum, sPropName, sModuleName, nResultLevel)
	else
		local sTemplate = "消耗%d个%s, %s增加%d经验"
		sContent = string.format(sTemplate, nCostNum, sPropName, sModuleName, nAddExp)
	end
	if sContent then 
		oRole:Tips(sContent)
	end

	local tMsg = {}
	tMsg.nOldLevel = nCurLevel
	tMsg.nCurLevel = self:GetXianzhenLevel()
	oRole:SendMsg("PartnerXianzhenLevelUpRet", tMsg)
end

---------------------------------------
--仙侣觉醒
function CPartner:GetReviveGrowthID()
	return 9
end

function CPartner:IsReviveSysOpen(bTips)
	return self.m_oRole:IsSysOpen(98, bTips)
end

function CPartner:GetReviveLimitLevel()
	local nID = self:GetReviveGrowthID()
	return ctRoleGrowthConf.GetConfMaxLevel(nID)
end

function CPartner:ReviveLevelUpReq(nPartnerID, nPropID, nPropNum)
	if nPartnerID <= 0 or nPropID <= 0 or nPropNum <= 0 then 
		self.m_oRole:Tips("参数不合法")
		return 
	end
	if not self:IsReviveSysOpen(true) then 
		return
	end
	local oRole = self.m_oRole
	local oPartner = self:FindPartner(nPartnerID)
	if not oPartner then 
		oRole:Tips("伙伴不存在")
		return 
	end
	if nPropNum <= 0 then 
		oRole:Tips("参数错误")
		return
	end
	local nGrowthID = self:GetReviveGrowthID()
	local tGrowthConf = ctRoleGrowthConf[nGrowthID]
	assert(tGrowthConf)
	local bItemValid = false
	local nSingleExp = 0
	for _, tItem in ipairs(tGrowthConf.tExpProp) do 
		local nItemType = tItem[1]
		local nItemID = tItem[2]
		local nAddExp  = tItem[3]
		if nItemType > 0 and nPropID > 0 and nPropID == nItemID then 
			bItemValid = true
			nSingleExp = nAddExp
			break
		end
	end
	if not bItemValid then 
		oRole:Tips("道具不合法")
		return 
	end
	assert(nSingleExp > 0, "配置错误")

	local nCurLevel = oPartner:GetReviveLevel()
	local nLimitLevel = self:GetReviveLimitLevel()
	local nCurExp = oPartner:GetReviveExp()
	local tOldData = {}
	tOldData.nLevel = nCurLevel
	tOldData.nExp = nCurExp

	if nCurLevel >= ctRoleGrowthConf.GetConfMaxLevel(nGrowthID) then 
		oRole:Tips("当前已达最高等级")
		return 
	end
	-- if nCurLevel >= nLimitLevel then 
	-- 	oRole:Tips("已达到当前限制等级，请先提升角色等级")
	-- 	return 
	-- end

	local nTotalAddExp = nPropNum * nSingleExp
	local nTotalExp = nTotalAddExp + nCurExp

	local nMaxAddExp = 0
	local tLevelConfList = ctRoleGrowthConf.GetLevelConfList(nGrowthID)
	for k = nCurLevel + 1, nLimitLevel do 
		local tLevelConf = tLevelConfList[k]
		assert(tLevelConf)
		nMaxAddExp = nMaxAddExp + tLevelConf.nExp
		if nTotalExp <= nMaxAddExp then 
			break
		end
	end
	if nMaxAddExp < nTotalExp then 
		local nAllowed = nMaxAddExp - nCurExp
		nPropNum = math.min(math.ceil(nAllowed/nSingleExp), nPropNum) --经验溢出, 修正下数量
	end
	assert(nPropNum > 0)

	local tCost = {gtItemType.eProp, nPropID, nPropNum}
	local tCostList = {}
	table.insert(tCostList, tCost)
	if not oRole:CheckSubShowNotEnoughTips(tCostList, "仙侣觉醒", true) then 
		return 
	end
	local nTotalAddExp = nPropNum * nSingleExp
	oPartner:AddReviveExp(nTotalAddExp)
	self:SyncPartnerDetailData(nPartnerID)

	local tMsg = {}
	tMsg.nPartnerID = nPartnerID
	tMsg.nPropID = nPropID
	tMsg.nPropNum = nPropNum

	tMsg.tOldData = tOldData
	local tCurData = {}
	tCurData.nLevel = oPartner:GetReviveLevel()
	tCurData.nExp = oPartner:GetReviveExp()
	tMsg.tCurData = tCurData
	self.m_oRole:SendMsg("PartnerReviveLevelUpRet", tMsg)
end
