--伪概率模块
local table, string, math, os, pairs, ipairs, assert = table, string, math, os, pairs, ipairs, assert

function CWGL:Ctor(oPlayer)
	self.m_oPlayer = oPlayer 
	self.m_tWGLMap = {} 	--{[id]=times,...}
end

function CWGL:LoadData(tData)
	if not tData then return end
	for sID, nTimes in pairs(tData.m_tWGLMap) do
		self.m_tWGLMap[tonumber(sID)] = nTimes
	end
end

function CWGL:SaveData()
	if not self:IsDirty() then return end
	self:MarkDirty(false)

	local tData = {}
	tData.m_tWGLMap = self.m_tWGLMap
	return tData
end

function CWGL:GetType()
	return gtModuleDef.tWGL.nID, gtModuleDef.tWGL.sName
end

--检测伪概率奖励,次数先加1再判断
function CWGL:CheckAward(nType)
	local tConf = assert(ctWGLConf[nType], "伪概率配置不存在")
	if tConf.nTimes <= 0 then
		return {}
	end
	--次数先加1
	self.m_tWGLMap[nType] = (self.m_tWGLMap[nType] or 0) + 1

	--触发伪概率判断
	if self.m_tWGLMap[nType] >= tConf.nTimes then
		self.m_tWGLMap[nType] = 0 --重置
		self:MarkDirty(true)
		return tConf.tAward
	end
	return {}
end

