--任务检测
local function _TaskConfCheck()
	for nID, tConf in pairs(ctMainTaskConf) do
		if tConf.nNext > 0 then
			assert(ctMainTaskConf[tConf.nNext], "后继任务不存在:"..tConf.nNext)
		end
	end
end
_TaskConfCheck()