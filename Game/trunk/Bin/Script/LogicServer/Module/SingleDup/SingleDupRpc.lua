function CltPBProc.ChapterInfoReq(nCmd, nSrc, nSession, tData)
	local oPlayer = goLuaPlayerMgr:GetPlayerBySession(nSession)
	if not oPlayer then
		return
	end
	local oModule = oPlayer:GetModule(CSingleDup:GetType())
	oModule:SyncChapterInfo(tData.nChapterID)
end

function CltPBProc.DupBeginReq(nCmd, nSrc, nSession, tData)
	local oPlayer = goLuaPlayerMgr:GetPlayerBySession(nSession)
	if not oPlayer then
		return
	end
	local oModule = oPlayer:GetModule(CSingleDup:GetType())
	oModule:DupBegin(tData.nDupID)
end

function CltPBProc.DupEndReq(nCmd, nSrc, nSession, tData)
	local oPlayer = goLuaPlayerMgr:GetPlayerBySession(nSession)
	if not oPlayer then
		return
	end
	local oModule = oPlayer:GetModule(CSingleDup:GetType())
	oModule:DupEnd(tData.nDupID, tData.nStar)
end

function CltPBProc.SetMopupDupReq(nCmd, nSrc, nSession, tData)
	local oPlayer = goLuaPlayerMgr:GetPlayerBySession(nSession)
	if not oPlayer then
		return
	end
	local oModule = oPlayer:GetModule(CSingleDup:GetType())
	oModule:SetMopupDup(tData.nDupID)
end

function CltPBProc.GetChapterAwardReq(nCmd, nSrc, nSession, tData)
	local oPlayer = goLuaPlayerMgr:GetPlayerBySession(nSession)
	if not oPlayer then
		return
	end
	local oModule = oPlayer:GetModule(CSingleDup:GetType())
	oModule:GetChapterAward(tData.nChapter, tData.nAwardID)
end
