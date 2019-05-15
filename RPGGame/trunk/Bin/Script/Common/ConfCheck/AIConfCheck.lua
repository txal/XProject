--预处理AI配置
local function _AIConfCheck()
	for nID, tConf in pairs(ctAIConf) do
		tConf.tSkillMap	= {}
		for _, tSkill in pairs(tConf.tSkillList) do
			tConf.tSkillMap[tSkill[1]] = 1
		end
	end
end
_AIConfCheck()

local _ctTmpAIConf
function ctAIConf:GetAIByBattleTypeAndSchool(nBattleType, nSchool)
	if not _ctTmpAIConf then
		_ctTmpAIConf = {}
		for nID, tConf in pairs(ctAIConf) do
			if type(tConf) == "table" then
				_ctTmpAIConf[tConf.nBattleType*10+tConf.nSchool] = tConf
			end
		end
	end
	local nIdent = nBattleType*10+nSchool
	return _ctTmpAIConf[nIdent]
end

