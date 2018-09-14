local table, string, math, os, pairs, ipairs, assert = table, string, math, os, pairs, ipairs, assert
local tGDMJConf = gtGDMJConf

local sPlayerDB = "RobotDB"             --机器人数据管理(GameX)
local nAutoSaveTime = 5*60*1000         --自动保存数据时间

function CRobot:Ctor(nID, sName)
    self.m_nObjType = gtObjType.eRobot
    self.m_nID = nID
    self.m_sName = sName
    self.m_bRobot = true
    self.m_sImgURL = ""
    self.m_nGold = 0

    self.m_oGDMJ = self
    self.m_oGame = self

	self.m_tCurrGame = {nGameType=0, nRoomID=0, nDeskType=0}

    self.m_nOutMJTick = nil
    self.m_nOperTick = nil
end

function CRobot:OnRelease()
	print("CRobot:OnRelease***", self.m_nID)
	self:CancelOutMJTimer()
	self:CancelOperTimer()
end

--加数据
function CRobot:LoadData()
end

--保存数据
function CRobot:SaveData()
end

function CRobot:GetObjType() return self.m_nObjType end
function CRobot:GetSession() return 0 end
function CRobot:GetCharID() return self.m_nID end
function CRobot:GetName() return self.m_sName end
function CRobot:GetImgURL() return self.m_sImgURL end

function CRobot:GetCurrGame() return self.m_tCurrGame end
function CRobot:SetCurrGame(nGameType, nRoomID, nDeskType)
	 self.m_tCurrGame.nGameType = nGameType
	 self.m_tCurrGame.nRoomID = nRoomID
	 self.m_tCurrGame.nDeskType = nDeskType
end

function CRobot:GetGold() return self.m_nGold end
function CRobot:GetRounds() return 0 end
function CRobot:SetRounds(nRounds) end
function CRobot:GetWinCnt() return 0 end
function CRobot:SetWinCnt(nWinCnt) end
function CRobot:AddDayRound(bWin)  end
function CRobot:GetDayRound() return 0 end
function CRobot:AddExp(nExp) end
function CRobot:IsOnline() return true end
function CRobot:GetTili() return 0 end
function CRobot:SetTili(nTili) end
function CRobot:AddItem() end

---AI---
function CRobot:GetRoom()
	local oGameMgr = goGameMgr:GetGame(self.m_tCurrGame.nGameType)
	if not oGameMgr then
		return
	end
	local oRoom = oGameMgr:GetRoom(self.m_tCurrGame.nRoomID)
	return assert(oRoom , "房间不存在:"..self.m_tCurrGame.nRoomID)
end

function CRobot:RegisterOutMJTimer(nTimeSec)
	self:CancelOutMJTimer()
	self.m_nOutMJTick = GlobalExport.RegisterTimer(nTimeSec*1000, function() self:OnOutMJTimeOut() end)
end

function CRobot:RegisterOperTimer(nTimeSec)
	self:CancelOperTimer()
	self.m_nOperTick = GlobalExport.RegisterTimer(nTimeSec*1000, function() self:OnOperTimeOut() end)
end

function CRobot:CancelOutMJTimer()
	if self.m_nOutMJTick then
		GlobalExport.CancelTimer(self.m_nOutMJTick)
		self.m_nOutMJTick = nil
	end
end

function CRobot:CancelOperTimer()
	if self.m_nOperTick then
		GlobalExport.CancelTimer(self.m_nOperTick)
		self.m_nOperTick = nil
	end
end

function CRobot:OnOutMJTimeOut()
	print(self.m_nID, "CRobot:OnOutMJTimeOut***")
    self:CancelOutMJTimer()
	local oRoom = self:GetRoom()
	local tPlayer = assert(oRoom:GetPlayer(self.m_nID), "机器人数据不存在")
	local nOutMJ = tPlayer.tHandMJ[tGDMJConf.tEtc.nMaxHandMJ]
	if nOutMJ <= 0 then
		return LuaTrace(self.m_nID, "手牌非法")
	end
	oRoom:OnUserOutMJ(self, nOutMJ)
end

function CRobot:SwitchPlayerRet(nTurnTime)
	print(self.m_nID, "CRobot:SwitchPlayerRet***")
	if nTurnTime == 0 then
		self:OnOutMJTimeOut()
	else
		nTurnTime = 4 --fix pd
		local nTimeSec = math.random(1, nTurnTime)
		self:RegisterOutMJTimer(nTimeSec)
	end
end

function CRobot:OnOperTimeOut()
	print(self.m_nID, "CRobot:OnOperTimeOut***")
	self:CancelOperTimer()
	local oRoom = self:GetRoom()
	local tPlayer = assert(oRoom:GetPlayer(self.m_nID), "机器人数据不存在")
	if tPlayer.nActionRight > 0 then
		oRoom:OnUserGiveUp(self)
	end
end

function CRobot:OperationRet(nOperTime)
	print(self.m_nID, "CRobot:OperationRet***")
	nOperTime = nOperTime or 0
	if nOperTime == 0 then
		self:OnOperTimeOut()
	else
		nOperTime = 4 --fix pd
		local nTimeSec = math.random(1, nOperTime)
		self:RegisterOperTimer(nTimeSec)
	end
end

function CRobot:OnRoundEnd()
	print(self.m_nID, "CRobot:OnRoundEnd***")
	self:CancelOutMJTimer()
	self:CancelOperTimer()
end
