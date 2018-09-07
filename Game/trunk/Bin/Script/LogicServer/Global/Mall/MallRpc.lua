function CltPBProc.MallGoodsListReq(nCmd, nSrc, nSession, tData)
	local oPlayer = goLuaPlayerMgr:GetPlayerBySession(nSession)
	if not oPlayer then
		return
	end
	goMall:GoodsListReq(oPlayer, tData.nMallType, tData.nPageType, tData.nPageIndex, tData.nPageSize)
end

function CltPBProc.MallBuyGoodsReq(nCmd, nSrc, nSession, tData)
	local oPlayer = goLuaPlayerMgr:GetPlayerBySession(nSession)
	if not oPlayer then
		return
	end
	goMall:BuyGoodsReq(oPlayer, tData.nGoodsID, tData.nBuyTimes)
end

function CltPBProc.MallBuyGoldReq(nCmd, nSrc, nSession, tData)
	local oPlayer = goLuaPlayerMgr:GetPlayerBySession(nSession)
	if not oPlayer then
		return
	end
	goMall:BuyGoldReq(oPlayer, tData.nID)
end
