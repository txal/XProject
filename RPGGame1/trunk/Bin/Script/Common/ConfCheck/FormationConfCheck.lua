--预处理表
_ctFormationLevelConf = {}
local function _ProcessConf()
	for _, tConf in ipairs(ctFormationLevelConf) do
		_ctFormationLevelConf[tConf.nID] = _ctFormationLevelConf[tConf.nID] or {}
		table.insert(_ctFormationLevelConf[tConf.nID], tConf)
	end
end
_ProcessConf()
