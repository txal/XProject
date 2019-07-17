--预处理AI技能配置
_ctAISkillTypeMap = {}
function _AISkillConfCheck()
	for _, tConf in pairs(ctAISkillConf) do
		if not _ctAISkillTypeMap[tConf.nType] then
			_ctAISkillTypeMap[tConf.nType] = {}
		end
		_ctAISkillTypeMap[tConf.nType][tConf.nID] = true
	end
end
_AISkillConfCheck()
