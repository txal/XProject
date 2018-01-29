local table, string, math, os, pairs, ipairs, assert = table, string, math, os, pairs, ipairs, assert

local nLogService = gtNetConf:LogService()
function CLogger:Ctor()
end

function CLogger:EventLog(nEventID, oPlayer, Field1, Field2, Field3, Field4, Field5, Field6)
	self:_normal_log(nEventID, 0, oPlayer, Field1, Field2, Field3, Field4, Field5, Field6)
end

function CLogger:AwardLog(nEventID, nReason, oPlayer, nItemType, nItemID, nItemNum, Field1, Field2, Field3)
	assert(nItemType and nItemID and nItemNum)
	self:_normal_log(nEventID, nReason, oPlayer, nItemType, nItemID, nItemNum, Field1, Field2, Field3)
end

function CLogger:_normal_log(nEventID, nReason, oPlayer, Field1, Field2, Field3, Field4, Field5, Field6)
	assert(nEventID and nReason)
	local sCurrGame, nCharID, sCharName, nLevel, nVIP = "", "", "", 0, 0
	if oPlayer then
		nCharID, sCharName, nLevel, nVIP = oPlayer:GetCharID(), oPlayer:GetName(), oPlayer:GetLevel(), oPlayer:GetVIP()
	end
	Field1 = Field1 or ""
	Field2 = Field2 or ""
	Field3 = Field3 or ""
	Field4 = Field4 or ""
	Field5 = Field5 or ""
	Field6 = Field6 or ""
	Srv2Srv.EventLog(nLogService, 0, nEventID, nReason, nCharID, sCharName, nLevel, nVIP, Field1, Field2, Field3, Field4, Field5, Field6, os.time())
end

function CLogger:CreateAccountLog(sAccount, nCharID, sCharName, nSource)
	assert(sAccount and nCharID and sCharName and nSource)
	Srv2Srv.CreateAccountLog(nLogService, 0, sAccount, nCharID, sCharName, nSource, os.time())
end

function CLogger:UpdateAccountLog(oPlayer, tParam) 
	assert(oPlayer and next(tParam))
	local nCharID = oPlayer:GetCharID()
	Srv2Srv.UpdateAccountLog(nLogService, 0, nCharID, tParam)
end

function CLogger:RankingLog(oPlayer, nRankID, nRankVal, nRecharge) 
	assert(oPlayer and nRankID and nRankVal and nRecharge)
	local nCharID = oPlayer:GetCharID()
	local sCharName = oPlayer:GetName()
	local nVIP = oPlayer:GetVIP()
	Srv2Srv.RankingLog(nLogService, 0, nCharID, sCharName, nVIP, nRankID, nRankVal, nRecharge)
end

goLogger = CLogger:new()