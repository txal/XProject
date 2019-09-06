--排行榜基类
local table, string, math, os, pairs, ipairs, assert = table, string, math, os, pairs, ipairs, assert


CRankingBase.nMaxViewNum = 50

--比较函数
local function _fnDescSort(t1, t2)
	if t1[1] == t2[1] then
		return 0
	end
	if t1[1] > t2[1] then
		return -1
	end
	return 1
end

function CRankingBase:Ctor(nID)
	self.m_nID = nID --排行榜ID
	self.m_oRanking = CSkipList:new(_fnDescSort) --{roleid={val1,val2,...}, ...}
	self.m_tDirtyMap = {}
end

function CRankingBase:GetID()
	return self.m_nID
end

function CRankingBase:GetDBName()
	local sDBName = gtDBDef.sRankingDB.."_"..self.m_nID
	return sDBName
end

function CRankingBase:LoadData()
	local oSSDB = goDBMgr:GetGameDB(gnServerID, "global", CUtil:GetServiceID())
	local sDBName = self:GetDBName()

	local tKeys = oSSDB:HKeys(sDBName)
	print("加载排行榜:", self.m_nID, #tKeys)

	for _, sKey in ipairs(tKeys) do
		local sData = oSSDB:HGet(sDBName, sKey)
		local nKey = tonumber(sKey)
		self.m_oRanking:Insert(nKey, cseri.decode(sData))
	end
end

function CRankingBase:SaveData()
	local oSSDB = goDBMgr:GetGameDB(gnServerID, "global", CUtil:GetServiceID())
	local sDBName = self:GetDBName()

	for nKey, v in pairs(self.m_tDirtyMap) do
		local tData = self.m_oRanking:GetDataByKey(nKey)
		if tData then
			oSSDB:HSet(sDBName, nKey, cseri.encode(tData))
		end
	end
	self.m_tDirtyMap = {}
end

function CRankingBase:Release()
	self:SaveData()
end

--重置清理数据库
function CRankingBase:ResetRanking()
	goDBMgr:GetGameDB(gnServerID, "global", CUtil:GetServiceID()):HClear(self:GetDBName())
	self.m_oRanking = CSkipList:new(_fnDescSort)
	self.m_tDirtyMap = {}
end

--设置脏数据
function CRankingBase:MarkDirty(nKey, bDirty)
	bDirty = bDirty and true or nil
	self.m_tDirtyMap[nKey] = bDirty
end

function CRankingBase:GetCount()
	return self.m_oRanking:GetCount()
end

--删除某个Key排名
function CRankingBase:RemoveKey(nKey)
	self.m_oRanking:Remove(nKey)
	self:MarkDirty(nKey, false)
end

--取某个Key排名
function CRankingBase:GetKeyRank(nKey)
	local nRank = self.m_oRanking:GetRankByKey(nKey)
	return nRank
end

function CRankingBase:GetElementByRank(nRank)
	return self.m_oRanking:GetElementByRank(nRank)
end

--取某个Key的值
function CRankingBase:GetKeyData(nKey)
	local tData = self.m_oRanking:GetDataByKey(nKey)
	return tData
end

--更新数据,特殊需求派生类实现
function CRankingBase:Update(nKey, nValue)
	assert(type(nKey)=="number", "只支持数字类键")
	if nValue == 0 then
		return
	end

	local tData = self.m_oRanking:GetDataByKey(nKey)
	if tData then
		if tData[1]	== nValue then
			return
		end
		self.m_oRanking:Remove(nKey)
		tData[1]  = nValue 
	else
		tData = {nValue}
	end
	self.m_oRanking:Insert(nKey, tData)
	self:MarkDirty(nKey, true)
end

--排行榜请求,特殊需求派生类实现
function CRankingBase:RankingReq(oRole, nRankNum)
	local nRoleID = oRole:GetID()
	nRankNum = math.max(1, math.min(CRankingBase.nMaxViewNum, nRankNum))

	--我的排名
	local nMyRank = self:GetKeyRank(nRoleID)
	local tMyData = self:GetKeyData(nRoleID)
	local nMyValue = tMyData and tMyData[1] or 0

	--前nRankNum名
	local tRanking = {}
	local function _fnTraverse(nRank, nRoleID, tData)
		local oRole = goGPlayerMgr:GetRoleByID(nRoleID)
		local tRank = {nRank=nRank, nValue=tData[1], nRoleID=nRoleID, sRoleName=oRole:GetName(), nSchool=oRole:GetSchool()}
		table.insert(tRanking, tRank)
	end
	self.m_oRanking:Traverse(1, nRankNum, _fnTraverse)
	local tMsg = {
		nRankID = self:GetID(),
		tRanking = tRanking,
		nMyRank = nMyRank,
		nMyValue = nMyValue,
	}
	oRole:SendMsg("RankingListRet", tMsg)
	return tMsg
end

--角色上线
function CRankingBase:Online(oRole)
end

function CRankingBase:CheckSysOpen(oRole, bTips)
	if oRole:GetLevel() < ctSysOpenConf[51].nLevel then
		if bTips then
			return oRole:Tips("排行榜系统未开启")
		end
		return
	end
	return true
end

function CRankingBase:GetAppeIDConf()
	local tConf = ctRankingConf[self.m_nID]
	if not tConf then
		return
	end
	return tConf["tAppeID"]
end

function CRankingBase:NewDay()
	self:RewardAppeID()
end

--排序人数，当前排名
function CRankingBase:GetRankAppeID(nRankNum,nRank)
	local tAppeIDConf = self:GetAppeIDConf()
	if not tAppeIDConf then
		return
	end

	local tAppeID
	if nRankNum == 1 then
		tAppeID = tAppeIDConf[nRank] or {}
		return tAppeID[1]
	elseif nRankNum == 10 then
		if nRank <= 1 then
			tAppeID = tAppeIDConf[1]
		elseif nRank <= 3 then
			tAppeID = tAppeIDConf[2]
		elseif nRank <= 10 then
			tAppeID = tAppeIDConf[3]
		end
		if tAppeID then
			return tAppeID[1]
		end
	end
end

function CRankingBase:GetRankAppleConf()
	local tParam = {}
	if self.m_nID >= gtRankingDef.eGWPowerRanking and self.m_nID <= gtRankingDef.eTYPowerRanking then
		local tConf = ctRankingConf[self.m_nID]
		tParam.tNameParam = {tConf.sName,}
	end
	local nNowTime = os.time()
	tParam.nExpiryTime = os.NextDayTime(nNowTime,0,0,0) + nNowTime
	return tParam
end

function CRankingBase:RewardAppeID()
	--科举排行榜,暂时屏蔽
	if self.m_nID == 1 then
		return
	end
	local tAppeID = self:GetAppeIDConf()
	if not tAppeID then
		return
	end
	--门派排行榜
	local nRankNum
	if self.m_nID >= gtRankingDef.eGWPowerRanking and self.m_nID <= gtRankingDef.eTYPowerRanking then
		nRankNum = 1
	end
	--综合实力榜
	if self.m_nID == gtRankingDef.eColligatePowerRanking then
		nRankNum = 1
	end
	--人物等级榜:1,2-3,4-10
	--宠物排行榜:1,2-3,4-10
	--竞技场积分榜:1,2-3,4-10
	if table.InArray(self.m_nID,{gtRankingDef.eRoleLevelRanking,gtRankingDef.ePetScoreRanking}) then
		nRankNum = 10
	end

	if not nRankNum then
		return
	end
	--前nRankNum名玩家
	local tRanking = {}
	local function _fnTraverse(nRank, nRoleID, tData)
		tRanking[nRank] = {nRoleID = nRoleID,nValue = tData[1]}
	end
	self.m_oRanking:Traverse(1, nRankNum, _fnTraverse)
	local tParam = self:GetRankAppleConf()
	for nRank,tData in ipairs(tRanking) do
		local nRoleID = tData["nRoleID"]
		local nAppeID = self:GetRankAppeID(nRankNum,nRank)
		if nAppeID then
			local oRole = goGPlayerMgr:GetRoleByID(nRoleID)
			if oRole then
				oRole:AddAppellation(nAppeID,tParam, 0)
			end
		end
	end
end