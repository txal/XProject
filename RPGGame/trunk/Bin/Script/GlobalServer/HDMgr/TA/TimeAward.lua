--限时奖励
local table, string, math, os, pairs, ipairs, assert = table, string, math, os, pairs, ipairs, assert

function CTimeAward:Ctor(nID)
	CHDBase.Ctor(self, nID)    	--继承基类
	self.m_tSubActMap = {} 		--子活动ID映射{[id]=obj, ...}
	self.m_tTypeActMap = {} 	--子活动类型映射{[type]={id,...}, ...}
end

function CTimeAward:LoadData()
	local oSSDB = goDBMgr:GetSSDB(gnServerID, "global", GF.GetServiceID())
	local tKeys = oSSDB:HKeys(gtDBDef.sTimeAwardDB)
	print("加载活动数据", self:GetName(), #tKeys)
	
	for _, sID in ipairs(tKeys) do
		local nID = tonumber(sID)
		local tConf = ctTimeAwardConf[nID]
		if tConf then
			local Class = gtTAClass[tConf.nType]
			if Class then
				self.m_tSubActMap[nID] = Class:new(self, nID)
				if not self.m_tTypeActMap[tConf.nType] then
					self.m_tTypeActMap[tConf.nType] = {}
				end
				table.insert(self.m_tTypeActMap[tConf.nType], nID)

				local sData = oSSDB:HGet(gtDBDef.sTimeAwardDB, sID)
				self.m_tSubActMap[nID]:LoadData(cjson.decode(sData))
			end
		end
	end
end

function CTimeAward:SaveData()
	local oSSDB = goDBMgr:GetSSDB(gnServerID, "global", GF.GetServiceID())
	for nID, oAct in pairs(self.m_tSubActMap) do
		if oAct:IsDirty() then
			local tData = oAct:SaveData()
			if tData and next(tData) then
				oSSDB:HSet(gtDBDef.sTimeAwardDB, nID, cjson.encode(tData))
				oAct:MarkDirty(false)
			end
		end
	end
end

--取子活动
function CTimeAward:GetAct(nActID)
	return self.m_tSubActMap[nActID]
end

--开启活动
function CTimeAward:OpenAct(nActID, nStartTime, nEndTime, nAwardTime)
	local tConf = ctTimeAwardConf[nActID]
	if not tConf then
		return LuaTrace("限时奖励子活动不存在:", nActID)
	end
	nAwardTime = nAwardTime or tConf.nAwardTime
	nAwardTime = math.min(nAwardTime, tConf.nAwardTime)

	if self.m_tSubActMap[nActID] then
		self.m_tSubActMap[nActID]:OpenAct(nStartTime, nEndTime, nAwardTime)

	else
		local Class = gtTAClass[tConf.nType]
		if not Class then
			return LuaTrace("限时奖励子活动未实现:", nActID)
		end
		local oAct = Class:new(self, nActID)
		self.m_tSubActMap[nActID] = oAct
		if not self.m_tTypeActMap[tConf.nType] then
			self.m_tTypeActMap[tConf.nType] = {}
		end
		table.insert(self.m_tTypeActMap[tConf.nType], nActID)
		oAct:OpenAct(nStartTime, nEndTime, nAwardTime)

	end
	return self.m_tSubActMap[nActID]
end

--玩家上线
function CTimeAward:Online(oRole)
	self:SyncState(oRole)
end

--更新状态
function CTimeAward:UpdateState()
	for nID, oAct in pairs(self.m_tSubActMap) do
		oAct:UpdateState()
	end
end

--更新记录
function CTimeAward:UpdateVal(nRoleID, nType, nVal)
	assert(type(nRoleID) == "number", "参数错误")
	if not self.m_tTypeActMap[nType] then
		return
	end
	for _, nID in ipairs(self.m_tTypeActMap[nType]) do
		self.m_tSubActMap[nID]:UpdateVal(nRoleID, nVal)
	end
end

function CTimeAward:MakeMsg(oRole)
	local tMsg = {tList={}}
	for nID, oAct in pairs(self.m_tSubActMap) do
		local nState = oAct:GetState()
		local nBeginTime, nEndTime, nStateTime = oAct:GetStateTime()
		if nState == CHDBase.tState.eClose then
			nBeginTime, nEndTime = goHDCircle:GetActNextOpenTime(self:GetID(), nID)
			if nBeginTime > 0 and nBeginTime > os.time() then
				assert(nEndTime>nBeginTime, "下次开启时间错误")
				nState = CHDBase.tState.eInit
				nStateTime = nEndTime - nBeginTime
			end
		end

		if nState ~= CHDBase.tState.eClose then
			local tInfo = {
				nID = nID,
				nState = nState,
				nStateTime = nStateTime,
				nBeginTime = nBeginTime,
				nEndTime = nEndTime,
				nOpenTimes = oAct:GetOpenTimes(),
				bCanGetAward = oAct:CanGetAward(oRole),
			}
			table.insert(tMsg.tList, tInfo)
		end
	end
	return tMsg
end

--同步活动状态
function CTimeAward:SyncState(oRole)
	--同步给指定玩家
	if oRole then
		local tMsg = self:MakeMsg(oRole)
		oRole:SendMsg("TimeAwardStateRet", tMsg)
	--全服广播
	else
		local tSessionMap = goGPlayerMgr:GetRoleSSMap()
		for nSession, oTmpRole in pairs(tSessionMap) do
			local tMsg = self:MakeMsg(oTmpRole)
			oTmpRole:SendMsg("TimeAwardStateRet", tMsg)
		end
	end
end
