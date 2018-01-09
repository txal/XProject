--聊天系统

--频道
CTalk.tChannel = 
{
	eWorld = 1,		--世界
	eTeam = 2,		--队伍
	eSystem = 3,	--系统
}

function CTalk:Ctor()
end

function CTalk:_SendTalkMsg(sSrcCharID, sSrcCharName, nChannel, sCont, tTarSessionList)
	local tMsg = {nCharID=sSrcCharID, sCharName=sSrcCharName, nChannel=nChannel, sCont=sCont}
	if tTarSessionList then
		CmdNet.PBBroadcastExter(tTarSessionList, "TalkMsgRet", tMsg)
	else
		CmdNet.PBSrv2All("TalkMsgRet", tMsg) 
	end
end

--世界消息
function CTalk:SendWorldMsg(oPlayer, sCont)
	local nCharID, sCharName = "", ""
	if oPlayer then
		nCharID, sCharName = oPlayer:GetCharID(), oPlayer:GetName()
	end
	self:_SendTalkMsg(nCharID, sCharName, self.tChannel.eWorld, sCont)	
end

--队伍消息
function CTalk:SendTeamMsg(oPlayer, sCont, bSkipName)
	local tSessionList = goTeamMgr:GetSessionListByPlayer(oPlayer)
	if not tSessionList or #tSessionList <= 0 then
		return oPlayer:Tips(ctLang[19])
	end
	local nCharID, sCharName = "", ""
	if not bSkipName then
		nCharID, sCharName = oPlayer:GetCharID(), oPlayer:GetName()
	end
	self:_SendTalkMsg(nCharID, sCharName, self.tChannel.eTeam, sCont, tSessionList)	
end

--系统消息
function CTalk:SendSystemMsg(sCont)
	local nCharID, sCharName = "0", ctLang[26]	--系统
	self:_SendTalkMsg(nCharID, sCharName, self.tChannel.eSystem, sCont)	
end

--聊天请求
function CTalk:TalkReq(oPlayer, nChannel, sCont)
	if nChannel == self.tChannel.eWorld then
		self:SendWorldMsg(oPlayer, sCont)

	elseif nChannel == self.tChannel.eTeam then
		self:SendTeamMsg(oPlayer, sCont)

	else
		assert(false, "不支持频道:"..nChannel)
	end
end

goTalk = goTalk or CTalk:new()