--房间管理器
local sRoomDataDB = "RoomDataDB"	--房间数据管理(Roomx)
local sRoomLogicDB = "RoomLogicDB"	--房间LOGIC管理(Center)
local nAutoSaveTime = 3*60*1000
local tGDMJConf = gtGDMJConf

function CGDMJRoomMgr:Ctor()
	self.m_tRoomMap = {}
	self.m_tDirtyRoom = {}
	self.m_nAutoSaveTimer = nil
end

function CGDMJRoomMgr:GetConf()
	return tGDMJConf
end

function CGDMJRoomMgr:OnRelease()
	if self.m_nAutoSaveTimer then
		GlobalExport.CancelTimer(self.m_nAutoSaveTimer)
		self.m_nAutoSaveTimer = nil
	end
end

--加载数据
function CGDMJRoomMgr:LoadData()
	local nService = GlobalExport.GetServiceID()
	local oCenterDB = goDBMgr:GetSSDBByName("Center")	
	local tKeys = oCenterDB:HKeys(sRoomLogicDB)
	for _, sRoomID in ipairs(tKeys) do
		local sLogicData = oCenterDB:HGet(sRoomLogicDB, sRoomID)
		local tLogicData = cjson.decode(sLogicData)
		if tLogicData.nLogic and not gtNetConf:LogicService(tLogicData.nLogic) then
			LuaTrace("房间找不到对应的逻辑服:"..sRoomID.."->"..tLogicData.nLogic)
			oCenterDB:HDel(sRoomLogicDB, sRoomID)

		elseif nService == tLogicData.nLogic then
			local nRoomID = tonumber(sRoomID)
			local oRoomDB = goDBMgr:GetSSDBByRoomID(nRoomID)
			local sData = oRoomDB:HGet(sRoomDataDB, sRoomID)	
			if sData ~= "" then
				local tData = cjson.decode(sData)
				--fix pd
			end
		end
	end
	self.m_nAutoSaveTimer = GlobalExport.RegisterTimer(nAutoSaveTime, function(nTimerID) self:SaveData() end)
end

--保存数据
function CGDMJRoomMgr:SaveData()
	-- for _, nRoomID in pairs(self.m_tDirtyRoom) do
	-- 	local oRoom = self.m_tRoomMap[nRoomID]
	-- 	if oRoom then	
	-- 		local tData = oRoom:SaveData()
	-- 		if tData then
	-- 			local sData = cjson.encode(tData)
	-- 			local oRoomDB = goDBMgr:GetSSDBByRoomID(nRoomID)
	-- 			oRoomDB:HSet(sRoomLogicDB, nRoomID, sData)
	-- 		end
	-- 	end
	-- end
	-- self.m_tDirtyRoom = {}
end

--设置脏数据
function CGDMJRoomMgr:MarkDirty(nRoomID, bDirty)
	bDirty = bDirty and true or nil
	self.m_tDirtyRoom[nRoomID] = bDirty
end

function CGDMJRoomMgr:GetRoom(nRoomID)
	return self.m_tRoomMap[nRoomID]
end

--删除房间数据
function CGDMJRoomMgr:RemoveData(nRoomID)
	local oRoomDB = goDBMgr:GetSSDBByRoomID(nRoomID)
	oRoomDB:HDel(sRoomDataDB, nRoomID)
end

--删除房间
function CGDMJRoomMgr:RemoveRoom(nRoomID)
	local oRoom = self:GetRoom(nRoomID)
	if not oRoom then
		return
	end
	oRoom:OnRelease()
	self.m_tRoomMap[nRoomID] = nil
	self:MarkDirty(nRoomID, false)

	--删除LOGIC
	goGameMgr:DelRoomLogic(nRoomID)
	--删除DATA
	self:RemoveData(nRoomID)
end

--创建房间
function CGDMJRoomMgr:CreateRoom(oPlayer, nRoomType, nDeskType)
	print("CGDMJRoomMgr:CreateRoom***", nRoomType)
	nDeskType = nDeskType or 0

	--已有房间,创建房间失败
	local tCurrGame = oPlayer.m_oGame:GetCurrGame()
	if tCurrGame.nRoomID > 0 then
		return oPlayer:Tips(ctLang[8])
	end

	local nRoomID = goGameMgr:_GenRoomID()
	assert(not self.m_tRoomMap[nRoomID], "房间已存在:"..nRoomID)
	local CRoom
	if nRoomType == tGDMJConf.tRoomType.eRoom1 then
		CRoom = CGDMJRoom1
	elseif nRoomType == tGDMJConf.tRoomType.eRoom2 then
		CRoom = CGDMJRoom2
		assert(nDeskType > 0)
	else
		assert(false, "不支持房间类型:"..nRoomType)
	end

	local oRoom = CRoom:new(self, nRoomID, nDeskType)
	self.m_tRoomMap[nRoomID] = oRoom
	self:JoinRoom(oPlayer, nRoomID)

	--记录LOGIC
	goGameMgr:SetRoomLogic(nRoomID, gtGameType.eGDMJ, nDeskType)
	return oRoom
end

--加入房间
function CGDMJRoomMgr:JoinRoom(oPlayer, nRoomID)
	print("CGDMJRoomMgr:JoinRoom***", nRoomID)
	if not goGameMgr:CheckLogic(oPlayer, nRoomID) then
		return
	end
	local oRoom = self:GetRoom(nRoomID)
	if not oRoom then
	--房间不存在
		oPlayer:Tips(ctLang[1])
		oPlayer.m_oGame:SetCurrGame(0, 0, 0)
		return
	end
	--加入房间
	if not oRoom:Join(oPlayer) then
		--CmdNet.PBSrv2Clt(oPlayer:GetSession(), "JoinRoomRet", {bSuccess=false, nRoomID=oRoom:RoomID(), nRoomType=oRoom:RoomType()})	
	end
end

--离开房间
function CGDMJRoomMgr:LeaveRoom(oPlayer)
	local oRoom = oPlayer.m_oGame:GetRoom()
	if not oRoom then
		return oPlayer:Tips(ctLang[1])
	end
	oRoom:Leave(oPlayer)
end

--玩家准备
function CGDMJRoomMgr:PlayerReady(oPlayer)
	local oRoom = oPlayer.m_oGame:GetRoom()
	if not oRoom then
		return oPlayer:Tips(ctLang[1])
	end
	oRoom:PlayerReady(oPlayer)
end

--好友房创建房间请求
function CGDMJRoomMgr:CreateRoomReq(oPlayer, nRoomType)
	if nRoomType == tGDMJConf.tRoomType.eRoom2 then
		return oPlayer:Tips(ctLang[10])
	end
	local nCardCost = 1 --fix pd 局数决定
	local nCard = oPlayer:GetCard()
	if nCard <= nCardCost then
		return oPlayer:Tips(ctLang[9])
	end
	self:CreateRoom(oPlayer, nRoomType)
end

--好友房进入房间请求
function CGDMJRoomMgr:JoinRoomReq(oPlayer, nRoomID)
	local oRoom = self:GetRoom(nRoomID)
	if oRoom and oRoom:RoomType() == tGDMJConf.tRoomType.eRoom2 then 
		local nCurrRoomID = oPlayer.m_oGame:GetCurrGame().nRoomID
		if nCurrRoomID ~= nRoomID then
			return oPlayer:Tips(ctLang[10])
		end
	end
	self:JoinRoom(oPlayer, nRoomID)
end

--好友房离开房间请求
function CGDMJRoomMgr:LeaveRoomReq(oPlayer)
	local oRoom = oPlayer.m_oGame:GetRoom()
	if not oRoom then
		return oPlayer:Tips(ctLang[1])
	end
	if oRoom:RoomType() == tGDMJConf.tRoomType.eRoom2 then
		return self:FreeRoomLeaveReq(oPlayer)
	end
	self:LeaveRoom(oPlayer)
end

--好友房玩家准备请求
function CGDMJRoomMgr:PlayerReadyReq(oPlayer)
	print("CGDMJRoomMgr:PlayerReadyReq***")
	local oRoom = oPlayer.m_oGame:GetRoom()
	if not oRoom then
		return oPlayer:Tips(ctLang[1])
	end
	if oRoom:RoomType() == tGDMJConf.tRoomType.eRoom2 then
		if not self:FreeRoomCheckTili(oPlayer, oRoom:DeskType()) then
			return
		end
	end
	self:PlayerReady(oPlayer)
end

--好友房解散请求
function CGDMJRoomMgr:DismissReq(oPlayer)
	local oRoom = oPlayer.m_oGame:GetRoom()	
	if not oRoom then
		return oPlayer:Tips(ctLang[1])
	end
	if oRoom:RoomType() == tGDMJConf.tRoomType.eRoom2 then
		return oPlayer:Tips(ctLang[10])
	end
	oRoom:DismissReq(oPlayer)
end

--好友房解散请求反馈
function CGDMJRoomMgr:AgreeDismissReq(oPlayer, bAgree)
	local oRoom = oPlayer.m_oGame:GetRoom()	
	if not oRoom then
		return oPlayer:Tips(ctLang[1])
	end
	if oRoom:RoomType() == tGDMJConf.tRoomType.eRoom2 then
		return oPlayer:Tips(ctLang[10])
	end
	oRoom:AgreeDismiss(oPlayer, bAgree)
end

--自由场兑换体力
function CGDMJRoomMgr:FreeRoomExchangeTili(oPlayer, nDeskType)
	local tConf = assert(ctGDMJDeskConf[nDeskType])
	if tConf.nGoldLimit > 0 then
		oPlayer:SubGold(tConf.nGoldLimit, gtReason.eFreeRoomExchange, true)
	end
	oPlayer.m_oGDMJ:SetTili(tConf.nTili)
end

--自由场金币检测
function CGDMJRoomMgr:FreeRoomCheckGold(oPlayer, nDeskType)
	local tConf = assert(ctGDMJDeskConf[nDeskType])
	local nGold = oPlayer:GetGold()
	local nGoldLimit = tConf.nGoldLimit
	if nGold < nGoldLimit then
		oPlayer:Tips(ctLang[5])
		return
	end
	return true
end

--自由场体力检测
function CGDMJRoomMgr:FreeRoomCheckTili(oPlayer, nDeskType, bNotSend)
	local tConf = assert(ctGDMJDeskConf[nDeskType])
	local nTiliLimit = tConf.nTili
	local nCurTili = oPlayer.m_oGDMJ:GetTili()
	local nMinTili = math.floor(0.6 * nTiliLimit)
	if nCurTili < nMinTili then
		local nNeedTili = nMinTili - nCurTili
		if not bNotSend then
			CmdNet.PBSrv2Clt(oPlayer:GetSession(), "FreeRoomTiliLimitRet", {nNeedTili=nNeedTili})
		end
		return false, nNeedTili
	end
	return true, 0
end

--离线事件
function CGDMJRoomMgr:Offline(oPlayer)
	print("CGDMJRoomMgr:Offline***")
	local tCurrGame = oPlayer.m_oGame:GetCurrGame()
	if tCurrGame.nDeskType > 0 and tCurrGame.nRoomID == 0 then
		self:FreeRoomLeaveReq(oPlayer)
	end
end

--自由场进场请求
function CGDMJRoomMgr:FreeRoomEnterReq(oPlayer, nDeskType)
	print("CGDMJRoomMgr:FreeRoomEnterReq***", nDeskType)
	nDeskType = nDeskType or 0
	if nDeskType > 0 then
	--进入自由场子类型
		assert(ctGDMJDeskConf[nDeskType], "自由场桌子类型错误")
		local nOldDeskType = oPlayer.m_oGame:GetCurrGame().nDeskType
		if nOldDeskType > 0 then
			return LuaTrace("重复进入自由场")
		end
		if not self:FreeRoomCheckGold(oPlayer, nDeskType) then
			return
		end
		self:FreeRoomExchangeTili(oPlayer, nDeskType)
		oPlayer.m_oGame:SetCurrGame(gtGameType.eGDMJ, 0, nDeskType)
	end

	local nDayRound, nDayWin = oPlayer.m_oGDMJ:GetDayRound()
	local tMsg = {nDayRound=nDayRound, nWinRound=nDayWin}
	CmdNet.PBSrv2Clt(oPlayer:GetSession(), "FreeRoomEnterRet", tMsg)
end

--自由场匹配请求
function CGDMJRoomMgr:FreeRoomMatchReq(oPlayer, nDeskType)
	print("CGDMJRoomMgr:FreeRooRMatchReq***", nDeskType)
	local tConf = assert(ctGDMJDeskConf[nDeskType], "自由场桌子类型非法")
	if not self:FreeRoomCheckTili(oPlayer, nDeskType) then
		return
	end
	--已有房间
	local nRoomID = oPlayer.m_oGame:GetCurrGame().nRoomID
	if nRoomID > 0 then
		return oPlayer:Tips(ctLang[7])
	end
	--请求匹配
	local nCharID = oPlayer:GetCharID()
	Srv2Srv.FreeRoomMatchReq(gtNetConf:GlobalService(), 0, nDeskType, nCharID)
end

--自由场匹配返回
function CGDMJRoomMgr:FreeRoomMatchRet(nRoomID, nDeskType, nCharID)
	print("CGDMJRoomMgr:MatchRoomRet***", nRoomID, nDeskType, nCharID)
	local oPlayer = goPlayerMgr:GetPlayerByCharID(nCharID)
	--已有房间
	local nRoomID = oPlayer.m_oGame:GetCurrGame().nRoomID
	if nRoomID > 0 then
		return oPlayer:Tips(ctLang[7])
	end
	--已经离线
	if not (oPlayer and oPlayer:IsOnline()) then
		return
	end
	--加入或者创建房间
	if nRoomID > 0 then
		self:JoinRoom(oPlayer, nRoomID)
	else
		self:CreateRoom(oPlayer, tGDMJConf.tRoomType.eRoom2, nDeskType)
	end
end

--自由场继续请求
function CGDMJRoomMgr:FreeRoomContinueReq(oPlayer)
	print("CGDMJRoomMgr:FreeRoomContinueReq***")
	local oRoom = oPlayer.m_oGame:GetRoom()
	if not oRoom then
		return oPlayer:Tips(ctLang[1])
	end
	if not self:FreeRoomCheckTili(oPlayer, oRoom:DeskType()) then
		return
	end
	oRoom:PlayerReady(oPlayer)
end

--自由场换桌请求
function CGDMJRoomMgr:FreeRoomSwitchReq(oPlayer)
	print("CGDMJRoomMgr:FreeRoomSwitchReq***")
	local oRoom = oPlayer.m_oGame:GetRoom()
	if not oRoom then
		return oPlayer:Tips(ctLang[1])
	end
	if not self:FreeRoomCheckTili(oPlayer, oRoom:DeskType()) then
		return
	end
	oRoom:Leave(oPlayer)
	self:FreeRoomMatchReq(oPlayer, oRoom:DeskType())
end

--自由场离开请求
function CGDMJRoomMgr:FreeRoomLeaveReq(oPlayer)
	print("CGDMJRoomMgr:FreeRoomLeaveReq***")
	local nDeskType = oPlayer.m_oGame:GetCurrGame().nDeskType
	if nDeskType == 0 then
		return
	end

	--结算金币(新手场不结算)
	if nDeskType ~= 1 then
		local nCurTili = oPlayer.m_oGDMJ:GetTili()
		oPlayer:AddItem(gtItemType.eCurr, gtCurrType.eGold, nCurTili, gtReason.eFreeRoomExchange, true)
		oPlayer.m_oGDMJ:SetTili(0) 		--重置体力
		oPlayer.m_oGDMJ:SetRounds(0) 	--重置对局
		oPlayer.m_oGDMJ:SetWinCnt(0) 	--重置连胜
	end
	CmdNet.PBSrv2Clt(oPlayer:GetSession(), "FreeRoomLeaveRet", {})

	local oRoom = oPlayer.m_oGame:GetRoom()
	if oRoom then
		oRoom:Leave(oPlayer)
	end
	oPlayer.m_oGame:SetCurrGame(0, 0, 0)
end

function CGDMJRoomMgr:FreeRoomFullTiliReq(oPlayer)
	print("CGDMJRoomMgr:FreeRoomFullTiliReq***")
	local oRoom = oPlayer.m_oGame:GetRoom()
	if not oRoom then
		return oPlayer:Tips(ctLang[1])
	end
	local _, nNeedTili = self:FreeRoomCheckTili(oPlayer, oRoom:DeskType())
	if nNeedTili > 0 then
		if oPlayer:GetGold() < nNeedTili then
			return oPlayer:Tips(ctLang[5])
		end
		oPlayer:SubGold(nNeedTili, gtReason.eFreeRoomExchange, true)
		oPlayer.m_oGDMJ:SetTili(oPlayer.m_oGDMJ:GetTili()+nNeedTili)
	end
	CmdNet.PBSrv2Clt(oPlayer:GetSession(), "FreeRoomFullTiliRet", {nCurTili=oPlayer.m_oGDMJ:GetTili()})
end
