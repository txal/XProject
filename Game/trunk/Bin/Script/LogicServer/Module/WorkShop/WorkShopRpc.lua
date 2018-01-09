function CltPBProc.WorkShopInfoReq(nCmd, nSrc, nSession, tData)
	local oPlayer = goLuaPlayerMgr:GetPlayerBySession(nSession)
	if not oPlayer then
		return
	end
	local oModule = oPlayer:GetModule(CWorkShop:GetType())
	oModule:WorkShopInfoReq()
end

function CltPBProc.WorkListReq(nCmd, nSrc, nSession, tData)
	local oPlayer = goLuaPlayerMgr:GetPlayerBySession(nSession)
	if not oPlayer then
		return
	end
	local oModule = oPlayer:GetModule(CWorkShop:GetType())
	oModule:SyncWorkList()
end

function CltPBProc.PutWorkReq(nCmd, nSrc, nSession, tData)
	local oPlayer = goLuaPlayerMgr:GetPlayerBySession(nSession)
	if not oPlayer then
		return
	end
	local oModule = oPlayer:GetModule(CWorkShop:GetType())
	oModule:PutWorkReq(tData.nGridID)
end

function CltPBProc.CancelWorkReq(nCmd, nSrc, nSession, tData)
	local oPlayer = goLuaPlayerMgr:GetPlayerBySession(nSession)
	if not oPlayer then
		return
	end
	local oModule = oPlayer:GetModule(CWorkShop:GetType())
	oModule:CancelWorkReq(tData.nWorkID)
end

function CltPBProc.GainWorkReq(nCmd, nSrc, nSession, tData)
	local oPlayer = goLuaPlayerMgr:GetPlayerBySession(nSession)
	if not oPlayer then
		return
	end
	local oModule = oPlayer:GetModule(CWorkShop:GetType())
	oModule:GainWorkReq(tData.nWorkID)
end

function CltPBProc.OneKeyRepairReq(nCmd, nSrc, nSession, tData)
	local oPlayer = goLuaPlayerMgr:GetPlayerBySession(nSession)
	if not oPlayer then
		return
	end
	local oModule = oPlayer:GetModule(CWorkShop:GetType())
	oModule:OneKeyPutWorkReq()
end
