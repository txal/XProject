--请求天赋信息
function CltPBProc.TalentInfoReq(nCmd, nSrc, nSession, tData)
	local oPlayer = goLuaPlayerMgr:GetPlayerBySession(nSession)
	if not oPlayer then
		return
	end
	oPlayer.m_oTalent:SyncInfo()
end

--保存天赋点
function CltPBProc.SaveTalentReq(nCmd, nSrc, nSession, tData)
	local oPlayer = goLuaPlayerMgr:GetPlayerBySession(nSession)
	if not oPlayer then
		return
	end
	oPlayer.m_oTalent:SaveTalent(tData)
end

--重置天赋点
function CltPBProc.ResetTalentReq(nCmd, nSrc, nSession, tData)
	local oPlayer = goLuaPlayerMgr:GetPlayerBySession(nSession)
	if not oPlayer then
		return
	end
	oPlayer.m_oTalent:ResetTalent()
end
