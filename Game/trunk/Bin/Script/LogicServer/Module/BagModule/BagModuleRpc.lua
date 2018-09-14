function CltPBProc.BagInfoReq(nCmd, nSrc, nSession, tData)
	local oPlayer = goLuaPlayerMgr:GetPlayerBySession(nSession)
	if not oPlayer then
		return
	end
	local oModule = oPlayer:GetModule(CBagModule:GetType())
	oModule:OnBagInfoReq()
end

function CltPBProc.ItemDetailReq(nCmd, nSrc, nSession, tData)
	local oPlayer = goLuaPlayerMgr:GetPlayerBySession(nSession)
	if not oPlayer then
		return
	end
	local oModule = oPlayer:GetModule(CBagModule:GetType())
	oModule:OnItemDetailReq(tData.nPosType, tData.nPosID)
end

function CltPBProc.PutOnArmReq(nCmd, nSrc, nSession, tData)
	local oPlayer = goLuaPlayerMgr:GetPlayerBySession(nSession)
	if not oPlayer then
		return
	end
	local oModule = oPlayer:GetModule(CBagModule:GetType())
	oModule:OnPutOnArmReq(tData.nGridID)
end

function CltPBProc.PutOffArmReq(nCmd, nSrc, nSession, tData)
	local oPlayer = goLuaPlayerMgr:GetPlayerBySession(nSession)
	if not oPlayer then
		return
	end
	local oModule = oPlayer:GetModule(CBagModule:GetType())
	oModule:OnPutOffArmReq(tData.nSlotID)
end

function CltPBProc.DecomposeArmReq(nCmd, nSrc, nSession, tData)
	local oPlayer = goLuaPlayerMgr:GetPlayerBySession(nSession)
	if not oPlayer then
		return
	end
	local oModule = oPlayer:GetModule(CBagModule:GetType())
	oModule:OnDecomposeArmReq(tData.nGridID)
end

function CltPBProc.UpgradeArmReq(nCmd, nSrc, nSession, tData)
	local oPlayer = goLuaPlayerMgr:GetPlayerBySession(nSession)
	if not oPlayer then
		return
	end
	local oModule = oPlayer:GetModule(CBagModule:GetType())
	oModule:OnUpgradeArmReq(tData.nPosID, tData.nPosType, tData.nUpgradeType)
end

function CltPBProc.ComposeArmReq(nCmd, nSrc, nSession, tData)
	local oPlayer = goLuaPlayerMgr:GetPlayerBySession(nSession)
	if not oPlayer then
		return
	end
	local oModule = oPlayer:GetModule(CBagModule:GetType())
	oModule:ComposeArm(tData.nPosType, tData.nPosID, tData.nGridID, tData.bUseProp)
end

function CltPBProc.StrengthenArmReq(nCmd, nSrc, nSession, tData)
	local oPlayer = goLuaPlayerMgr:GetPlayerBySession(nSession)
	if not oPlayer then
		return
	end
	local oModule = oPlayer:GetModule(CBagModule:GetType())
	oModule:StrengthenArm(tData.nPosType, tData.nPosID, tData.nGridID)
end

function CltPBProc.ArmMasterReq(nCmd, nSrc, nSession, tData)
	local oPlayer = goLuaPlayerMgr:GetPlayerBySession(nSession)
	if not oPlayer then
		return
	end
	local oModule = oPlayer:GetModule(CBagModule:GetType())
	oModule:GetMasterInfo()
end

function CltPBProc.UsePropReq(nCmd, nSrc, nSession, tData)
	local oPlayer = goLuaPlayerMgr:GetPlayerBySession(nSession)
	if not oPlayer then
		return
	end
	local oModule = oPlayer:GetModule(CBagModule:GetType())
	oModule:UseProp(tData.nGridID)
end

function CltPBProc.SellPropReq(nCmd, nSrc, nSession, tData)
	local oPlayer = goLuaPlayerMgr:GetPlayerBySession(nSession)
	if not oPlayer then
		return
	end
	local oModule = oPlayer:GetModule(CBagModule:GetType())
	oModule:SellProp(tData.nGridID, tData.nNum)
end

function CltPBProc.BuyBagGridReq(nCmd, nSrc, nSession, tData)
	local oPlayer = goLuaPlayerMgr:GetPlayerBySession(nSession)
	if not oPlayer then
		return
	end
	local oModule = oPlayer:GetModule(CBagModule:GetType())
	oModule:BuyGridReq()
end

function CltPBProc.ArmReformReq(nCmd, nSrc, nSession, tData)
	local oPlayer = goLuaPlayerMgr:GetPlayerBySession(nSession)
	if not oPlayer then
		return
	end
	local oModule = oPlayer:GetModule(CBagModule:GetType())
	oModule:ArmReformReq(tData.nPosType, tData.nPosID, tData.nGridID, tData.nLockFeatureID)
end

function CltPBProc.FeaturePropListReq(nCmd, nSrc, nSession, tData)
	local oPlayer = goLuaPlayerMgr:GetPlayerBySession(nSession)
	if not oPlayer then
		return
	end
	local oModule = oPlayer:GetModule(CBagModule:GetType())
	oModule:FeaturePropListReq(tData.nPosType, tData.nPosID)
end

function CltPBProc.ComposeSubArmReq(nCmd, nSrc, nSession, tData)
	local oPlayer = goLuaPlayerMgr:GetPlayerBySession(nSession)
	if not oPlayer then
		return
	end
	local oModule = oPlayer:GetModule(CBagModule:GetType())
	oModule:ComposeSubArmReq(tData.nPosType, tData.nPosID)
end

function CltPBProc.StrengthenSubArmReq(nCmd, nSrc, nSession, tData)
	local oPlayer = goLuaPlayerMgr:GetPlayerBySession(nSession)
	if not oPlayer then
		return
	end
	local oModule = oPlayer:GetModule(CBagModule:GetType())
	oModule:StrengthenSubArmReq(tData.nPosType, tData.nPosID)
end

function CltPBProc.ArmPolishInfoReq(nCmd, nSrc, nSession, tData)
	local oPlayer = goLuaPlayerMgr:GetPlayerBySession(nSession)
	if not oPlayer then
		return
	end
	local oModule = oPlayer:GetModule(CBagModule:GetType())
	oModule:ArmPolishInfoReq(tData.nPosType, tData.nPosID)
end

function CltPBProc.ArmPolishReq(nCmd, nSrc, nSession, tData)
	local oPlayer = goLuaPlayerMgr:GetPlayerBySession(nSession)
	if not oPlayer then
		return
	end
	local oModule = oPlayer:GetModule(CBagModule:GetType())
	oModule:ArmPolishReq(tData.nPosType, tData.nPosID)
end

function CltPBProc.OneKeyUpgradeArmReq(cmd, nSrc, nSession, tData)
	local oPlayer = goLuaPlayerMgr:GetPlayerBySession(nSession)
	if not oPlayer then
		return
	end
	local oModule = oPlayer:GetModule(CBagModule:GetType())
	oModule:OneKeyUpgradeArmReq()
end