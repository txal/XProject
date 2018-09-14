CLogger = class()

local _time = os.time
local nLogServiceID = next(gtNetConf.tLogService)

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
	local nCharID, sCharName, nLevel, nVIP = "", "", 0, 0
	if oPlayer then
		nCharID, sCharName, nLevel, nVIP = oPlayer:GetCharID(), oPlayer:GetName(), oPlayer:GetLevel(), oPlayer:GetVIP()
	end
	Field1 = Field1 or ""
	Field2 = Field2 or ""
	Field3 = Field3 or ""
	Field4 = Field4 or ""
	Field5 = Field5 or ""
	Field6 = Field6 or ""
	Srv2Srv.EventLog(nLogServiceID, 0, nEventID, nReason, nCharID, sCharName, nLevel, nVIP, Field1, Field2, Field3, Field4, Field5, Field6, _time())
end

function CLogger:CreateAccountLog(sAccount, nCharID, sCharName, nRoleID)
	nRoleID = nRoleID or 0
	Srv2Srv.CreateAccountLog(nLogServiceID, 0, sAccount, nCharID, sCharName, nRoleID, _time())
end

goLogger = CLogger:new()