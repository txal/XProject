--广东麻将自由房匹配管理器
--玩家上限
local nMaxPlayer = 4

function CRoomMgr:Ctor()
	self.m_tRoomMap = {}
	for k, v in pairs(ctGDMJDeskConf) do
		self.m_tRoomMap[k] = {}
	end
	self.m_tDirtyMap = {}
end

function CRoomMgr:LoadData()
	--fix pd
end

function CRoomMgr:SaveData()
	--fix pd
end

--设置脏字段
function CRoomMgr:MarkDirty(nRoomID, nDeskType, bDirty)
	assert(nRoomID and nDeskType and bDirty)
	if bDirty then
		self.m_tDirtyMap[nRoomID] = nDeskType
	else
		self.m_tDirtyMap[nRoomID] = nil
	end
end

--创建房间事件
function CRoomMgr:OnCreateRoom(nRoomID, nDeskType, nLogic)
	print("CRoomMgr:OnCreateRoom***", nRoomID, nDeskType, nLogic)
	local tRoomMap = assert(self.m_tRoomMap[nDeskType])
	tRoomMap[nRoomID] = 
	{
		nLogic = nLogic,		--逻辑服ID
		nDeskType = nDeskType, 	--桌子类型
		tPlayerList = {},		--玩家列表
	}
	tRoomMap.nCount = (tRoomMap.nCount or 0) + 1
end

--解散房间事件
function CRoomMgr:OnDismissRoom(nRoomID, nDeskType)
	print("CRoomMgr:OnDismissRoom***", nRoomID, nDeskType)
	local tRoomMap = self.m_tRoomMap[nDeskType]
	if tRoomMap[nRoomID] then
		tRoomMap[nRoomID] = nil
		tRoomMap.nCount = tRoomMap.nCount - 1
	end
end

--玩家进入事件
function CRoomMgr:OnPlayerEnter(nRoomID, nDeskType, nCharID)
	print("CRoomMgr:OnPlayerEnter***", nRoomID, nDeskType, nCharID)
	local tRoomMap = self.m_tRoomMap[nDeskType]
	local tRoom = assert(tRoomMap[nRoomID])
	if table.InArray(nCharID, tRoom.tPlayerList) then
		print(nCharID, "已经在房间里面")
		return
	end
	assert(#tRoom.tPlayerList < nMaxPlayer)
	table.insert(tRoom.tPlayerList, nCharID)
end

--玩家离开事件
function CRoomMgr:OnPlayerLeave(nRoomID, nDeskType, nCharID)
	print("CRoomMgr:OnPlayerLeave***", nRoomID, nDeskType, nCharID)
	local tRoomMap = assert(self.m_tRoomMap[nDeskType])
	local tRoom = assert(tRoomMap[nRoomID])
	for k, nTmpCharID in ipairs(tRoom.tPlayerList) do
		if nCharID == nTmpCharID then
			table.remove(tRoom.tPlayerList, k)
			break
		end
	end
end

--匹配请求
function CRoomMgr:FreeRoomMatch(nDeskType, nCharID, nSrcLogic)
	print("CRoomMgr:MatchRoom***", nDeskType, nCharID, nSrcLogic)
	local nTarRoomID, nTmpPlayerCount = 0, 0
	local tRoomMap = self.m_tRoomMap[nDeskType]
	for nRoomID, tRoom in pairs(tRoomMap) do
		if type(nRoomID) == "number" then
			local nPlayerCount = #tRoom.tPlayerList
			if nPlayerCount < nMaxPlayer then
				if nTmpPlayerCount == 0 or nPlayerCount > nTmpPlayerCount then
					nTarRoomID = nRoomID
					nTmpPlayerCount = nPlayerCount
					if nTmpPlayerCount == 3 then
						break
					end
				end
			end
		end
	end
	Srv2Srv.FreeRoomMatchRet(nSrcLogic, 0, nTarRoomID, nDeskType, nCharID)
end


goRoomMgr = goRoomMgr or CRoomMgr:new()