--客户端->服务器

function CltPBProc.C2GSEnterHouseReq(nCmd, nServer, nService, nSession, tData)
	local oRole = goGPlayerMgr:GetRoleBySS(nServer, nSession)
    if not oRole then return end
    goHouseMgr:EnterHouse(oRole,tData)
end

function CltPBProc:C2GSLeaveHouseReq(nCmd,nServer,nService,nSession,tData)
	local oRole = goGPlayerMgr:GetRoleBySS(nServer,nSession)
	if not oRole then return end
	goHouseMgr:LeaveHouse(oRole,tData)
end

function CltPBProc.C2GSBuyHouseBoxReq(nCmd,nServer,nService,nSession,tData)
	local oRole = goGPlayerMgr:GetRoleBySS(nServer,nSession)
	if not oRole then return end
	local nRoleID = oRole:GetID()
	local oHouse = goHouseMgr:GetHouse(nRoleID)
	local nBoxCnt = tData.nBuyBoxCnt
	oHouse:BuyBox(nBoxCnt)
end

function CltPBProc.C2GSHouseVisiterReq(nCmd,nServer,nService,nSession,tData)
	local oRole = goGPlayerMgr:GetRoleBySS(nServer,nSession)
	if not oRole then return end
	local nRoleID = oRole:GetID()
	local oHouse = goHouseMgr:GetHouse(nRoleID)
	oHouse:HouseVisiterReq()
end

function CltPBProc.C2GSHouseGiveGiftReq(nCmd,nServer,nService,nSession,tData)
	local oRole = goGPlayerMgr:GetRoleBySS(nServer,nSession)
	if not oRole then return end
	local nTargetRoleID = tData.nRoleID
	local nPropID = tData.nPropID
	local nAmount = tData.nAmount
	local sMsg = tData.sMsg
	local bMoneyAdd = tData.bMoneyAdd
	local oHouse = goHouseMgr:GetHouse(nTargetRoleID)
	if not oHouse then
		return
	end
	oHouse:GiveGiftReq(oRole,nPropID,nAmount,sMsg,bMoneyAdd)
end

function CltPBProc.C2GSHouseGiftInfoReq(nCmd,nServer,nService,nSession,tData)
	local oRole = goGPlayerMgr:GetRoleBySS(nServer,nSession)
	if not oRole then return end
	local nRoleID = oRole:GetID()
	local oHouse = goHouseMgr:GetHouse(nRoleID)
	oHouse:GiftInfoReq()
end

function CltPBProc.C2GSHousePosFurnitureReq(nCmd,nServer,nService,nSession,tData)
	local oRole = goGPlayerMgr:GetRoleBySS(nServer,nSession)
	if not oRole then return end
	local nRoleID = oRole:GetID()
	local oHouse = goHouseMgr:GetHouse(nRoleID)
	oHouse:PosFurnitureReq()
end

function CltPBProc.C2GSHouseWieldFurnitureReq(nCmd,nServer,nService,nSession,tData)
	local oRole = goGPlayerMgr:GetRoleBySS(nServer,nSession)
	if not oRole then return end
	local nRoleID = oRole:GetID()
	local oHouse = goHouseMgr:GetHouse(nRoleID)
	local nFurnitureID = tData.nFurnitureID
	oHouse:WieldFurniture(nFurnitureID) 
end

function CltPBProc.C2GSHouseMessageReq(nCmd,nServer,nService,nSession,tData)
	local oRole = goGPlayerMgr:GetRoleBySS(nServer,nSession)
	if not oRole then return end
	local nRoleID = oRole:GetID()
	local oHouse = goHouseMgr:GetHouse(nRoleID)
	local nPage = tData.nPage
	oHouse:HouseMessageReq(nPage)
end

function CltPBProc.C2GSHouseMakeMessageReq(nCmd,nServer,nService,nSession,tData)
	local oRole = goGPlayerMgr:GetRoleBySS(nServer,nSession)
	if not oRole then return end
	local nTargetRoleID = tData.nRoleID
	local sMsg = tData.sMsg
	local oHouse = goHouseMgr:GetHouse(nTargetRoleID)
	if oHouse then
		oHouse:AddMessage(oRole,sMsg)
	end
end

function CltPBProc.C2GSHouseDeleteMessageReq(nCmd,nServer,nService,nSession,tData)
	local oRole = goGPlayerMgr:GetRoleBySS(nServer,nSession)
	if not oRole then return end
	local nRoleID = oRole:GetID()
	local oHouse = goHouseMgr:GetHouse(nRoleID)
	local nMessageID = tData.nMessageID
	oHouse:DeleteMessage(nMessageID)
end

function CltPBProc.C2GSSetPhotoKeyReq(nCmd,nServer,nService,nSession,tData)
	local oRole = goGPlayerMgr:GetRoleBySS(nServer,nSession)
	if not oRole then return end
	local nRoleID = oRole:GetID()
	local oHouse = goHouseMgr:GetHouse(nRoleID)
	local sPhotoKey = tData.sPhotoKey
	oHouse:SetPhotoKey(sPhotoKey)
end

function CltPBProc.C2GSHouseWaterPlantReq(nCmd,nServer,nService,nSession,tData)
	local oRole = goGPlayerMgr:GetRoleBySS(nServer,nSession)
	if not oRole then return end
	local nRoleID = oRole:GetID()
	goHouseMgr:HouseWaterPlantReq(oRole,tData)
end

function CltPBProc.C2GSHousePlantGiftDataReq(nCmd,nServer,nService,nSession,tData)
	local oRole = goGPlayerMgr:GetRoleBySS(nServer,nSession)
	if not oRole then return end
	local nRoleID = oRole:GetID()
	local oHouse = goHouseMgr:GetHouse(nRoleID)
	oHouse:OpenPlantGiftInterface(oRole)
end

function CltPBProc.C2GSHousePlantChangePartner(nCmd,nServer,nService,nSession,tData)
	local oRole = goGPlayerMgr:GetRoleBySS(nServer,nSession)
	if not oRole then return end
	local nRoleID = oRole:GetID()
	local oHouse = goHouseMgr:GetHouse(nRoleID)
	oHouse:PlantChangePartner(oRole)
end

function CltPBProc.C2GSHousePlantGiveGiftReq(nCmd,nServer,nService,nSession,tData)
	local oRole = goGPlayerMgr:GetRoleBySS(nServer,nSession)
	if not oRole then return end
	local nRoleID = oRole:GetID()
	local oHouse = goHouseMgr:GetHouse(nRoleID)
	oHouse:PlantGiveGift(oRole)
end

function CltPBProc.C2GSHousePlantReceiveReward(nCmd,nServer,nService,nSession,tData)
	local oRole = goGPlayerMgr:GetRoleBySS(nServer,nSession)
	if not oRole then return end
	local nRoleID = oRole:GetID()
	local oHouse = goHouseMgr:GetHouse(nRoleID)
	oHouse:PlantReceiveReward(oRole)
end

function CltPBProc.C2GSHouseDynamicDataReq(nCmd,nServer,nService,nSession,tData)
	local oRole = goGPlayerMgr:GetRoleBySS(nServer,nSession)
	if not oRole then return end
	local nTargetRoleID = tData.nRoleID
	local oTargetRole = goGPlayerMgr:GetRoleByID(nTargetRoleID)
	if not oTargetRole then return end
	local nPage = tData.nPage
	local oHouse = goHouseMgr:GetHouse(nTargetRoleID)
	oHouse:DymaicDataReq(oRole,nPage)
end

function CltPBProc.C2GSHouseDynamicPublicReq(nCmd,nServer,nService,nSession,tData)
	local oRole = goGPlayerMgr:GetRoleBySS(nServer,nSession)
	if not oRole then return end
	local nRoleID = oRole:GetID()
	local oHouse = goHouseMgr:GetHouse(nRoleID)
	oHouse:AddDynamic(oRole,tData)
end

function CltPBProc.C2GSHouseDynamicPublicCommentReq(nCmd,nServer,nService,nSession,tData)
	local oRole = goGPlayerMgr:GetRoleBySS(nServer,nSession)
	if not oRole then return end
	local nTargetRoleID = tData.nRoleID
	local nDynamicID = tData.nDynamicID
	local nTargetCommentID = tData.nCommentID
	local sMsg = tData.sMsg
	goHouseMgr:DynamicPublicCommentReq(oRole,nTargetRoleID,nDynamicID,nTargetCommentID,sMsg)
end

function CltPBProc.C2GSHouseDynamicUpVoteReq(nCmd,nServer,nService,nSession,tData)
	local oRole = goGPlayerMgr:GetRoleBySS(nServer,nSession)
	if not oRole then return end
	local nTargetRoleID = tData.nRoleID
	local nDynamicID = tData.nDynamicID
	goHouseMgr:DynamicUpVoteReq(oRole,nTargetRoleID,nDynamicID)
end

function CltPBProc.C2GSHouseDeleteDynamicReq(nCmd,nServer,nService,nSession,tData)
	local oRole = goGPlayerMgr:GetRoleBySS(nServer,nSession)
	if not oRole then return end
	local nRoleID = oRole:GetID()
	local nDynamicID = tData.nDynamicID
	local oHouse = goHouseMgr:GetHouse(nRoleID)
	if oHouse then
		oHouse:DeleteDynamic(oRole,nDynamicID)
	end
end

function CltPBProc.C2GSHouseDynamicDeleteCommentReq(nCmd,nServer,nService,nSession,tData)
	local oRole = goGPlayerMgr:GetRoleBySS(nServer,nSession)
	if not oRole then return end
	local nRoleID = tData.nRoleID
	local nDynamicID = tData.nDynamicID
	local nCommentID = tData.nCommentID
	local oHouse = goHouseMgr:GetHouse(nRoleID)
	oHouse:DeleteComment(oRole,nDynamicID,nCommentID)
end

---------------服务器内部----------------
function Srv2Srv.HouseUnLockFurniture(nSrcServer,nSrcService,nTarSession,nRoleID,nFurnitureID)
	local oRole = goGPlayerMgr:GetRoleByID(nRoleID)
	if not oRole then return end
	local oHouse = goHouseMgr:GetHouse(nRoleID)
	oHouse:UnLockFurniture(nFurnitureID)
	return true
end

function Srv2Srv.HouseFurnitureIsLock(nSrcServer,nSrcService,nTarSession,nRoleID,nFurnitureID)
	local oRole = goGPlayerMgr:GetRoleByID(nRoleID)
	if not oRole then return end
	local oHouse = goHouseMgr:GetHouse(nRoleID)
	return oHouse:IsFurnituerLock(nFurnitureID)
end

function Srv2Srv.FriendChange(nSrcServer,nSrcService,nTarSession,nRoleID,nFriendID)
	local oRole = goGPlayerMgr:GetRoleByID(nRoleID)
	if not oRole then return end
	goHouseMgr:FriendChange(nRoleID,nFriendID)
end