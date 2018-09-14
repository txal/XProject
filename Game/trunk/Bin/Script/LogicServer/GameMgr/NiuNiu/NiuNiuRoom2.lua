--广东麻将自由房间
local table, string, math, os, pairs, ipairs, assert = table, string, math, os, pairs, ipairs, assert
local tNiuNiuConf = gtNiuNiuConf

function CNiuNiuRoom2:Ctor(oRoomMgr, nRoomID, nDeskType)
	CNiuNiuRoomBase.Ctor(self, oRoomMgr, nRoomID, tNiuNiuConf.tRoomType.eRoom2, nDeskType)
end

function CNiuNiuRoom2:LoadData(tData)
	--fix pd
end

function CNiuNiuRoom2:SaveData()
	--fix pd
end
