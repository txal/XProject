--妖兽突袭管理器
local table, string, math, os, pairs, ipairs, assert = table, string, math, os, pairs, ipairs, assert

function CYaoShouTuXiMgr:Ctor()
	self.m_tYaoShouNpcMap = {} --活的怪物{[怪物对象ID]={[NPC编号]=id,[场景ID]=id}}
end

function CYaoShouTuXiMgr:Init()
	for _, tYaoShou in pairs(ctYaoShouTuXi) do
		local oYaoShou = CPublicYaoShou:new(tYaoShou.nYaoShouID)
		if oYaoShou then
			self.m_tYaoShouNpcMap[oYaoShou:GetID()] = oYaoShou
		end
	end
end

function CYaoShouTuXiMgr:CreateYaoShou()

end
function CYaoShouTuXiMgr:LoadData()
end

function CYaoShouTuXiMgr:SaveData()
end

function CYaoShouTuXiMgr:Release()
end

function CYaoShouTuXiMgr:GetYaoShou(nYaoShouID)
	return self.m_tYaoShouNpcMap[nYaoShouID]
end

--获取妖兽战斗状态
function CYaoShouTuXiMgr:GetYaoShouBattleStatus(nYaoShouID)
	local oYaoShou = self.m_tYaoShouNpcMap[nYaoShouID]
	if not oYaoShou then return end
	return oYaoShou:GetBattleStatus()
end

--角色进入场景事件
function CYaoShouTuXiMgr:OnEnterScene(oRole)
	local nDupMixID = oRole:GetDupMixID()
	local nDupID = CUtil:GetDupID(nDupMixID)
	if not nDupID then return end
	local tYaoShouInfo = {}
	local nFlag = false
	for nYaoShouID, oYaoShou in pairs(self.m_tYaoShouNpcMap) do
		if oYaoShou:GetDupID() == nDupID then
			tYaoShouInfo[#tYaoShouInfo+1] = oYaoShou:GetViewData()
			nFlag =true
		end
	end
	local tMsg = {}
	if nFlag then
		tMsg.tDupListInfo = tYaoShouInfo
		tMsg.nType = 2
		oRole:SendMsg("yaoshoutuxiInitInfoRet", tMsg)
	end
end

function CYaoShouTuXiMgr:GetRewardType()
	for _, tConf in pairs(ctYaoShouTuXi) do
		return tConf.nType
	end
end


function CYaoShouTuXiMgr:GetDupInfo()
	-- local nRandPosType = self:GetRewardType()
	-- local tRetRand = {}
	--随机坐标点
    -- local function GetPosWeight(tNode)
    --     return 1
    -- end
    --策划改需求,跟之前玩法不同,暂时保留
 	-- local tPosPool = ctRandomPoint.GetPool(nRandPosType, 999)
	-- local tPosConf = CWeightRandom:Random(tPosPool, GetPosWeight, 9, true)
	-- local tYaoShouList = {}
	-- local nPos = 1
	-- for nYaoShouID, tYaoShou in pairs(ctYaoShouTuXi) do
	-- 	tRetRand[#tRetRand+1] = {nYaoShouID = tYaoShou.nYaoShouID, nPosID = tPosConf[nPos].nID}
	-- 	nPos =  nPos + 1
	-- end
	--return tRetRand
end

--更新怪物
function CYaoShouTuXiMgr:UpdateMonster(nYaoShouID, oRole)
	local oYaoShou = self.m_tYaoShouNpcMap[nYaoShouID]
	if not oYaoShou then return end
	local nPosID = self:GetMonsterInfo()
	if not nPosID then return end
	local nMonsterID = nYaoShouID
	local nDupID = oYaoShou:GetDupID()
	oYaoShou:SetPosID(nPosID)
	oYaoShou:SetBattleStatus(false)
	--广播场景

	local tYaoShouInfo = {}
	local tMsg = {}
	for _, oYaoShou in pairs(self.m_tYaoShouNpcMap) do
		if oYaoShou:GetDupID() == nDupID then
			tYaoShouInfo[#tYaoShouInfo+1] = oYaoShou:GetViewData()
		end
	end
	return nDupID, tYaoShouInfo
end

function CYaoShouTuXiMgr:GetMonsterInfo()
	 local function GetPosWeight(tNode)
        return 1
    end
    local tTaskID = {}
    local tItemList = {}
	local nRandPosType =self:GetRewardType()
	local tPosPool = ctRandomPoint.GetPool(nRandPosType, 999)
	for _, tConf in ipairs(tPosPool) do
		if not self.m_tYaoShouNpcMap[tConf.nID] then
			table.insert(tItemList, tConf)
		end
	end
	local tPosConf = CWeightRandom:Random(tItemList, GetPosWeight, 1, false)
	return  tPosConf[1].nID
end

function CYaoShouTuXiMgr:GetYaoShouInfo()
	local tYaoShouList = {}
	for nYaoShouID, oYaoShou in pairs(self.m_tYaoShouNpcMap) do
		tYaoShouList[#tYaoShouList+1] =  oYaoShou:GetViewData()
	end
	return tYaoShouList
end

