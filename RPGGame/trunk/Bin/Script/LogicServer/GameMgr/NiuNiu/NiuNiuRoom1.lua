--牛牛熟人房间
local table, string, math, os, pairs, ipairs, assert = table, string, math, os, pairs, ipairs, assert
local tNiuNiuConf = gtNiuNiuConf

function CNiuNiuRoom1:Ctor(oRoomMgr, nRoomID)
	CNiuNiuRoomBase.Ctor(self, oRoomMgr, nRoomID, tNiuNiuConf.tRoomType.eRoom1, 0)
	self.m_tOption = nil
	self:CheckOption(self.m_tOption)--检测选项

end

function CNiuNiuRoom1:LoadData(tData)
	--fix pd
end

function CNiuNiuRoom1:SaveData()
	--fix pd
end

--检测选项
function CNiuNiuRoom1:CheckOption(tOption)
end
