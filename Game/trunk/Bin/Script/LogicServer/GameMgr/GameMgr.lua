local table, string, math, os, pairs, ipairs, assert = table, string, math, os, pairs, ipairs, assert

--游戏管理器
local sRoomIDDB = "RoomIDDB"		--房间ID自增管理(Center)
local sRoomLogicDB = "RoomLogicDB"	--房间LOGIC管理(Center)
local nMaxRoomID = 999999			--房间号上限
local nBaseRoomID = 100000			--房间号起始
local nSelfLogic = GlobalExport.GetServiceID()

function CGameMgr:Ctor()
	self.m_tGameMap = {}
end

function CGameMgr:Init()
	for k, v in pairs(gtGameType) do
		self:RegGame(v)
	end
end

--注册游戏
function CGameMgr:RegGame(nGameType)
	assert(not self.m_tGameMap[nGameType])	
	if nGameType == gtGameType.eGDMJ then
		self.m_tGameMap[nGameType] = CGDMJRoomMgr:new()
		self.m_tGameMap[nGameType]:LoadData()

	elseif nGameType == gtGameType.eNN then
		self.m_tGameMap[nGameType] = CNiuNiuRoomMgr:new()
		self.m_tGameMap[nGameType]:LoadData()

	elseif nGameType == gtGameType.eDZPK then

	elseif nGameType == gtGameType.eDDZ then
		
	end
end

--取得游戏管理器
function CGameMgr:GetGame(nGameType)
	return self.m_tGameMap[nGameType]
end

--生产房间ID
function CGameMgr:_GenRoomID()
	local oCenterDB = goDBMgr:GetSSDBByName("Center")	
	local nIncr = oCenterDB:HIncr(sRoomIDDB, "IDIncr")
	local nRoomID = (nBaseRoomID + nIncr) % nMaxRoomID + 1

	local sData = oCenterDB:HGet(sRoomLogicDB, nRoomID)
	assert(sData == "", "房间ID冲突:"..nRoomID)
	return nRoomID
end

--取房间所在逻辑服
function CGameMgr:GetRoomLogic(nRoomID)
	if nRoomID <= 0 then
		return nSelfLogic, 0
	end
	local oCenterDB = goDBMgr:GetSSDBByName("Center")	
	local sData = oCenterDB:HGet(sRoomLogicDB, nRoomID)
	if sData ~= "" then
		local tData = cjson.decode(sData)
		return tData.nLogic, tData.nGameType, tData.nDeskType
	end
	return nSelfLogic, 0, 0
end

--设置房间所在逻辑服
function CGameMgr:SetRoomLogic(nRoomID, nGameType, nDeskType)
	assert(nRoomID and nGameType and nDeskType)
	local nSelfLogic = GlobalExport.GetServiceID()
	local oCenterDB= goDBMgr:GetSSDBByName("Center")	
	local tData = {nLogic=nSelfLogic, nGameType=nGameType, nDeskType=nDeskType}
	oCenterDB:HSet(sRoomLogicDB, nRoomID, cjson.encode(tData))
end

--删除房间逻辑服信息
function CGameMgr:DelRoomLogic(nRoomID)
	local oCenterDB= goDBMgr:GetSSDBByName("Center")	
	oCenterDB:HDel(sRoomLogicDB, nRoomID)
end

--离线事件
function CGameMgr:Offline(oPlayer)
	local nGameType = oPlayer.m_oGame:GetCurrGame().nGameType
	local oGameMgr = self:GetGame(nGameType)
	if oGameMgr then
		oGameMgr:Offline(oPlayer)
	end
end

--逻辑服检测
function CGameMgr:CheckLogic(oPlayer, nRoomID)
	--切换逻辑服
	local nTarLogic, nGameType, nDeskType = self:GetRoomLogic(nRoomID)
	if nTarLogic ~= nSelfLogic then
		local tAccount = 
		{
			sAccount = oPlayer:GetAccount()
			, nCharID = oPlayer:GetCharID()
			, sCharName = oPlayer:GetName()
			, sPassword = oPlayer:GetPassword()
		}
		oPlayer.m_oGame:SetCurrGame(nGameType, nRoomID, nDeskType)
		goPlayerMgr:SwitchLogicServer(nTarLogic, oPlayer:GetSession(), tAccount)
		return false
	end
	return true
end

--大厅好友房创建房间
function CGameMgr:HallCreateRoomReq(oPlayer, nGameType)
	local tCurrGame = oPlayer.m_oGame:GetCurrGame()
	--已有房间,创建房间失败
	if tCurrGame.nRoomID > 0 then
		return oPlayer:Tips(ctLang[8])
	end
	--开发中，敬请期待
	local oGameMgr = self:GetGame(nGameType)
	if not oGameMgr then
		return oPlayer:Tips(ctLang[11])
	end
	oGameMgr:CreateRoomReq(oPlayer, oGameMgr:GetConf().tRoomType.eRoom1)
end

--大厅好友房加入房间
function CGameMgr:HallJoinRoomReq(oPlayer, nRoomID)
	local nTarLogic, nGameType, nDeskType = self:GetRoomLogic(nRoomID)
	--房间号不存在
	if nGameType == 0 then
		return oPlayer:Tips(ctLang[1])
	end
	--如果当前已有房间则进入当前房间
	local tCurrGame = oPlayer.m_oGame:GetCurrGame()
	if tCurrGame.nRoomID > 0 then
		nRoomID = tCurrGame.nRoomID
		nGameType = tCurrGame.nGameType
	end
	--开发中，敬请期待
	local oGameMgr = self:GetGame(nGameType)
	if not oGameMgr then
		return oPlayer:Tips(ctLang[11])
	end
	oGameMgr:JoinRoomReq(oPlayer, nRoomID)
end

--大厅点击游戏(自由房)
function CGameMgr:HallClickGameReq(oPlayer, nGameType)
	local tCurrGame = oPlayer.m_oGame:GetCurrGame()
	--请先退出游戏XX
	if tCurrGame.nGameType > 0 then
		return oPlayer:Tips(string.format(ctLang[12], tCurrGame.nGameType))
	end
	--开发中，敬请期待
	local oGameMgr = self:GetGame(nGameType)
	if not oGameMgr then
		return oPlayer:Tips(ctLang[11])
	end
	oGameMgr:FreeRoomEnterReq(oPlayer)
end

--大厅杂项请求
function CGameMgr:HallEtcReq(oPlayer)
	local nNowSec = os.time()
	local nRoleExistTime = math.max(0, nNowSec - oPlayer:GetCreateTime())
	CmdNet.PBSrv2Clt(oPlayer:GetSession(), "HallEtcRet", {nRoleExistTime=nRoleExistTime})
end


goGameMgr = goGameMgr or CGameMgr:new()
