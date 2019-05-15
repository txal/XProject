--对话NPC
local table, string, math, os, pairs, ipairs, assert = table, string, math, os, pairs, ipairs, assert

--调用对话NPC的模块类型
CNpcTalk.tNpcType = 
{
	eTaskSystem = 1,
	eShiMenTask = 2,
}

function CNpcTalk:Ctor(nID)
	CNpcBase.Ctor(self, nID)

	self.m_tTrigger = {}
	self:RegisterTrigger()
end

--触发NPC
--@nType 任务类型
--@nID 任务ID
function CNpcTalk:Trigger(oRole, nType, tData)
	if not self:IsPositionValid(oRole) then
		return oRole:Tips("坐标非法")
	end
	local fnFuncTrigger = self.m_tTrigger[nType]
	fnFuncTrigger(self, oRole, tData)
end

--注册调用模块与触发函数
function CNpcTalk:RegisterTrigger()
	local tTrigger = self:GetTriggetList()

	for k, v in pairs(tTrigger) do 
		self.m_tTrigger[v[1]] = v[2]
	end
end

--调用模块类型与触发函数绑定
function CNpcTalk:GetTriggetList()
	return {
		{CNpcTalk.tNpcType.eTaskSystem, self.TaskSystemTrigger},
		{CNpcTalk.tNpcType.eShiMenTask, self.ShiMenTrigger},
	}
end

function CNpcTalk:TaskSystemTrigger(oRole, tData)
	--必须检查任务是否存在
	assert(ctTaskSystemConf[tData.nTaskID], "任务不存在,npcID:"..tData.nNpcID.."任务ID:"..tData.nTaskID)

	local nTaskTargetType = ctTaskSystemConf[tData.nTaskID].nTargetType
	oRole.m_oTaskSystem:TaskOpera(tData.nTaskID, tData.nTaskType, nTaskTargetType, self.m_nID, tData.nTaskStatus)
end

function CNpcTalk:ShiMenTrigger(oRole, tData)
	if tData.nOperaType == CShiMenTask.tReqType.eAcceptShiMenTask then
		oRole.m_oShiMenTask:AccepteTask()

	elseif tData.nOperaType == CShiMenTask.tReqType.eCommitShiMenTask then
		oRole.m_oShiMenTask:TaskOpera(self.m_nID, tData.nItemID, tData.nGatherStatus)
	end
end
