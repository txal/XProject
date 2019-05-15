function CltPBProc.KnapsackUseItemReq(nCmd, nServer, nService, nSession, tData)
	local oRole = goPlayerMgr:GetRoleBySS(nServer, nSession)
	if not oRole then return end
	oRole.m_oKnapsack:PropUseReq(tData.nGrid, tData.nParam1)
end

function CltPBProc.KnapsackArrangeReq(nCmd, nServer, nService, nSession, tData)
	local oRole = goPlayerMgr:GetRoleBySS(nServer, nSession)
	if not oRole then return end
	oRole.m_oKnapsack:ArrangeReq(tData.nType)
end

function CltPBProc.KnapsackBuyGridReq(nCmd, nServer, nService, nSession, tData)
	local oRole = goPlayerMgr:GetRoleBySS(nServer, nSession)
	if not oRole then return end
	oRole.m_oKnapsack:BuyGridReq(tData.nType, tData.nCurrType)
end

function CltPBProc.KnapsackPutStorageReq(nCmd, nServer, nService, nSession, tData)
	local oRole = goPlayerMgr:GetRoleBySS(nServer, nSession)
	if not oRole then return end
	oRole.m_oKnapsack:PutStorageReq(tData.nGrid)
end

function CltPBProc.KnapsackGetStorageReq(nCmd, nServer, nService, nSession, tData)
	local oRole = goPlayerMgr:GetRoleBySS(nServer, nSession)
	if not oRole then return end
	oRole.m_oKnapsack:GetStorageReq(tData.nGrid)
end

function CltPBProc.KnapsacWearEquReq(nCmd, nServer, nService, nSession, tData)
	local oRole = goPlayerMgr:GetRoleBySS(nServer, nSession)
	if not oRole then return end
	oRole.m_oKnapsack:WearEquReq(tData.nGrid)
end

function CltPBProc.KnapsacQuickWearEquReq(nCmd, nServer, nService, nSession, tData)
	local oRole = goPlayerMgr:GetRoleBySS(nServer, nSession)
	if not oRole then return end
	oRole.m_oKnapsack:QuickWearEquReq()
end

function CltPBProc.KnapsacTakeOffEquReq(nCmd, nServer, nService, nSession, tData)
	local oRole = goPlayerMgr:GetRoleBySS(nServer, nSession)
	if not oRole then return end
	oRole.m_oKnapsack:TakeOffEquReq(tData.nEquipPartType)
end

function CltPBProc.KnapsacFixEquReq(nCmd, nServer, nService, nSession)
	local oRole = goPlayerMgr:GetRoleBySS(nServer, nSession)
	if not oRole then return end
	oRole.m_oKnapsack:FixEquReq()
end

function CltPBProc.KnapsacFixSingleEquReq(nCmd, nServer, nService, nSession, tData)
	local oRole = goPlayerMgr:GetRoleBySS(nServer, nSession)
	if not oRole then return end
	oRole.m_oKnapsack:FixSingleEquReq(tData.nGrid, tData.nPartType)
end

function CltPBProc.KnapsacMakeEquReq(nCmd, nServer, nService, nSession, tData)
	local oRole = goPlayerMgr:GetRoleBySS(nServer, nSession)
	if not oRole then return end
	oRole.m_oKnapsack:MakeEquReq(tData.nID, tData.bMoneyAdd)
end

function CltPBProc.KnapsacGemReq(nCmd, nServer, nService, nSession, tData)
	local oRole = goPlayerMgr:GetRoleBySS(nServer, nSession)
	if not oRole then return end
	oRole.m_oKnapsack:GemReq(tData.nBoxType, tData.nBoxParam, tData.nPosID, tData.nGemID, tData.bMoneyAdd)
end

function CltPBProc.KnapsacRemoveGemReq(nCmd, nServer, nService, nSession, tData)
	local oRole = goPlayerMgr:GetRoleBySS(nServer, nSession)
	if not oRole then return end
	oRole.m_oKnapsack:RemoveGemReq(tData.nBoxType, tData.nBoxParam, tData.nPosID)
end

function CltPBProc.KnapsacStrengthenEquReq(nCmd, nServer, nService, nSession, tData)
	local oRole = goPlayerMgr:GetRoleBySS(nServer, nSession)
	if not oRole then return end
	oRole.m_oKnapsack:StrengthenEquReq(tData.nBoxType, tData.nBoxParam, tData.bStorageMode, 
		tData.nQilingzhu, tData.nZhenlingshi, tData.nLuckyStone, tData.bMoneyAdd)
end

function CltPBProc.KnapsacWearEquListReq(nCmd, nServer, nService, nSession, tData)
	local oRole = goPlayerMgr:GetRoleBySS(nServer, nSession)
	if not oRole then return end
	oRole.m_oKnapsack:WearEquListReq()
end

function CltPBProc.KnapsacPropDetailReq(nCmd, nServer, nService, nSession, tData)
	local oRole = goPlayerMgr:GetRoleBySS(nServer, nSession)
	if not oRole then return end
	oRole.m_oKnapsack:PropDetailReq(tData.nBoxType, tData.nBoxParam,tData.nOtherType)
end

function CltPBProc.KnapsackSellItemReq(nCmd, nServer, nService, nSession, tData)
	local oRole = goPlayerMgr:GetRoleBySS(nServer, nSession)
	if not oRole then return end
	oRole.m_oKnapsack:PropSellReq(tData.nGrid, tData.nNum, tData.nType)
end

function CltPBProc.KnapsackSellItemListReq(nCmd, nServer, nService, nSession, tData)
	local oRole = goPlayerMgr:GetRoleBySS(nServer, nSession)
	if not oRole then return end
	oRole.m_oKnapsack:PropListSellReq(tData.tItemList)
end

function CltPBProc.KnapsackItemSalePriceReq(nCmd, nServer, nService, nSession, tData)
	local oRole = goPlayerMgr:GetRoleBySS(nServer, nSession)
	if not oRole then return end
	oRole.m_oKnapsack:ItemSalePriceReq(tData.tItemList)
end

function CltPBProc.PropEquipReMakeReq(nCmd,nServer,nService,nSession,tData)
	local oRole = goPlayerMgr:GetRoleBySS(nServer,nSession)
	if not oRole then return end
	oRole.m_oKnapsack:PropEquipReMake(tData.nBoxType,tData.nBoxParam,tData.nType,tData.bMoneyAdd, tData.nAttrID, tData.nTarAttrID)
end

function CltPBProc.KnapsacGetPetEquReq(nCmd,nServer,nService,nSession,tData)
	local oRole = goPlayerMgr:GetRoleBySS(nServer,nSession)
	if not oRole then return end
	oRole.m_oKnapsack:KnapsacGetPetEquReq(tData.tItemGrid)
end

function CltPBProc.KnapsacLegendEquExchangeReq(nCmd,nServer,nService,nSession,tData)
	local oRole = goPlayerMgr:GetRoleBySS(nServer,nSession)
	if not oRole then return end
	oRole.m_oKnapsack:ExchangeLegendEquReq(tData.nEquID)
end

function CltPBProc.KnapsacLegendEquExchangeInfoReq(nCmd,nServer,nService,nSession,tData)
	local oRole = goPlayerMgr:GetRoleBySS(nServer,nSession)
	if not oRole then return end
	oRole.m_oKnapsack:LegendEquExchangeInfoReq()
end

function CltPBProc.KnapsackEquTriggerAttrReq(nCmd,nServer,nService,nSession,tData)
	local oRole = goPlayerMgr:GetRoleBySS(nServer,nSession)
	if not oRole then return end
	oRole.m_oKnapsack:SyncEquTriggerAttr()
end

function CltPBProc.KnapsackRecastSellReq(nCmd,nServer,nService,nSession,tData)
	local oRole = goPlayerMgr:GetRoleBySS(nServer,nSession)
	if not oRole then return end
	oRole.m_oKnapsack:RecastSellReq(tData.nBoxType, tData.nBoxParam)
end

function CltPBProc.KnapsackTransferReq(nCmd,nServer,nService,nSession,tData)
	local oRole = goPlayerMgr:GetRoleBySS(nServer,nSession)
	if not oRole then return end
	oRole.m_oKnapsack:TransferDataReq(tData.nPartType)
end


------------服务器内部
--取格子道具数据[W]GLOBAL
function Srv2Srv.KnapsackItemDataReq(nSrcServer, nSrcService, nTarSession, nRoleID, nGrid)
	local oRole = goPlayerMgr:GetRoleByID(nRoleID)
	if not oRole then return end
	return oRole.m_oKnapsack:GetItemData(nGrid)
end

--取多个道具数据[W]GLOBAL
function Srv2Srv.KnapsackItemListDataReq(nSrcServer, nSrcService, nTarSession, nRoleID, tList)
	local oRole = goPlayerMgr:GetRoleByID(nRoleID)
	if not oRole then return end
	local tItemList = {}
	return oRole.m_oKnapsack:GetItemDataList(tList)
end

--取背包空闲格子数[W]GLOBAL
function Srv2Srv.KnapsackFreeGridCountReq(nSrcServer, nSrcService, nTarSession, nRoleID)
	local oRole = goPlayerMgr:GetRoleByID(nRoleID)
	if not oRole then return end
	return oRole.m_oKnapsack:GetFreeGridCount()
end

--通过道具ID取所有道具数据[W]GLOBAL
function Srv2Srv.KnapsackPropListDataReq(nSrcServer, nSrcService, nTarSession, nRoleID, nPropID)
	local oRole = goPlayerMgr:GetRoleByID(nRoleID)
	if not oRole then return end
	return oRole.m_oKnapsack:GetPropDataList(nPropID)
end

--通过道具ID取所有道具数据[W]GLOBAL
function Srv2Srv.KnapsackAddSaleYuanbaoRecordReq(nSrcServer, nSrcService, nTarSession, nRoleID, nAddNum)
	local oRole = goPlayerMgr:GetRoleByID(nRoleID)
	if not oRole then return end
	return oRole.m_oKnapsack:AddDailySaleYuanbaoRecord(nAddNum)
end

--通过道具ID取所有道具数据[W]GLOBAL
function Srv2Srv.KnapsackGetSaleYuanbaoRemainNumReq(nSrcServer, nSrcService, nTarSession, nRoleID)
	local oRole = goPlayerMgr:GetRoleByID(nRoleID)
	if not oRole then return end
	return oRole.m_oKnapsack:GetDailySaleYuanbaoRemainNum()
end

--手动同步背包
function Srv2Srv.KnapsackSyncCachedMsgReq(nSrcServer, nSrcService, nTarSession, nRoleID)
	local oRole = goPlayerMgr:GetRoleByID(nRoleID)
	if not oRole then return end
	return oRole.m_oKnapsack:SyncCachedMsg()
end
