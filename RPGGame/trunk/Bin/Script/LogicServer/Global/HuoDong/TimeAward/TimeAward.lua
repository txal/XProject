--限时奖励
local table, string, math, os, pairs, ipairs, assert = table, string, math, os, pairs, ipairs, assert

function CTimeAward:Ctor(nID)
	CHDBase.Ctor(self, nID)     	--继承基类
	self.m_tSubActMap = {} 			--子活动ID映射{[id]=obj, ...}
	self.m_tTypeActMap = {} 		--子活动类型映射{[type]={id,...}, ...}
end

function CTimeAward:LoadData()
	local oSSDB = goDBMgr:GetSSDB("Player")
	local tKeys = oSSDB:HKeys(gtDBDef.sTimeAwardDB)
	print("加载限时活动数据:", #tKeys)
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
	local oSSDB = goDBMgr:GetSSDB("Player")
	for nID, oAct in pairs(self.m_tSubActMap) do
		local tData = oAct:SaveData()
		if tData and next(tData) then
			oSSDB:HSet(gtDBDef.sTimeAwardDB, nID, cjson.encode(tData))
		end
	end
end

--取子活动
function CTimeAward:GetObj(nActID)
	return self.m_tSubActMap[nActID]
end

--开启活动
function CTimeAward:OpenAct(nActID, nStartTime, nEndTime, nAwardTime)
	local tConf = ctTimeAwardConf[nActID]
	if not tConf then
		return LuaTrace("限时奖励子活动:", nActID, " 不存在")
	end
	local nAwardTime = nAwardTime or tConf.nAwardTime
	if self.m_tSubActMap[nActID] then
		self.m_tSubActMap[nActID]:OpenAct(nStartTime, nEndTime, nAwardTime)

	else
		local Class = gtTAClass[tConf.nType]
		if not Class then
			return LuaTrace("限时奖励子活动:"..nActID.." 未实现")
		end
		local oAct = Class:new(self, nActID)
		self.m_tSubActMap[nActID] = oAct
		if not self.m_tTypeActMap[tConf.nType] then
			self.m_tTypeActMap[tConf.nType] = {}
		end
		table.insert(self.m_tTypeActMap[tConf.nType], nActID)
		oAct:OpenAct(nStartTime, nEndTime, nAwardTime)

	end
end

--玩家上线
function CTimeAward:Online(oPlayer)
	self:SyncState(oPlayer)
end

--更新状态
function CTimeAward:UpdateState()
	for nID, oAct in pairs(self.m_tSubActMap) do
		oAct:UpdateState()
	end
end

--更新记录
function CTimeAward:UpdateVal(nCharID, nType, nVal)
	if not self.m_tTypeActMap[nType] then
		return
	end
	for _, nID in ipairs(self.m_tTypeActMap[nType]) do
		self.m_tSubActMap[nID]:UpdateVal(nCharID, nVal)
	end
end

function CTimeAward:MakeMsg(oPlayer)
	local tList = {}
	for nID, oAct in pairs(self.m_tSubActMap) do
		local nState = oAct:GetState()
		if nState == CHDBase.tState.eStart or nState == CHDBase.tState.eAward then
			local nStateTime = oAct:GetStateTime()
			local nBeginTime, nEndTime, nAwardTime = oAct:GetActTime()
			local tInfo = {
				nID = nID,
				nState = nState,
				nStateTime = nStateTime,
				nBeginTime = nBeginTime,
				nEndTime = nEndTime,
				nAwardTime = nAwardTime,
				nOpenTimes = oAct:GetOpenTimes(),
				bCanGetAward = oAct:CanGetAward(oPlayer),
			}
			table.insert(tList, tInfo)
		end
	end
	return {tList=tList}
end

--同步活动状态
function CTimeAward:SyncState(oPlayer)
	--同步给指定玩家
	if oPlayer then
		local tMsg = self:MakeMsg(oPlayer)
		CmdNet.PBSrv2Clt(oPlayer:GetSession(), "TimeAwardStateRet", tMsg)
	--全服广播
	else
		local tSessionMap = goPlayerMgr:GetSessionMap()
		for nSession, oTmpPlayer in pairs(tSessionMap) do
			local tMsg = self:MakeMsg(oTmpPlayer)
			CmdNet.PBSrv2Clt(oTmpPlayer:GetSession(), "TimeAwardStateRet", tMsg)
		end
	end
end
