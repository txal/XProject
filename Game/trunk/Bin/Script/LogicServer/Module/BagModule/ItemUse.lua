gtPropUse = {}
gtPropUse[2000] = function(oPlayer)
	local oModule = oPlayer:GetModule(CSingleDup:GetType())
	oModule:UseProp(2000)
	return true
end

gtPropUse[2001] = function(oPlayer)
	local oModule = oPlayer:GetModule(CSingleDup:GetType())
	oModule:UseProp(2001)
	return true
end

--使用礼包
function gtPropUse:UseGift(oPlayer, nPropID)
	local tGiftConf = assert(ctGiftConf[nPropID])
	local tConsume = tGiftConf.tConsume	
	for _, tItem in ipairs(tConsume) do
		local nType, nID, nNum = table.unpack(tItem)
		if nID > 0  then
			local nCurrCount = oPlayer.m_oBagModule:GetItemCount(nType, nID)
			if nCurrCount < nNum then
				local tPropConf = ctPropConf[nID]
				if tPropConf then
					oPlayer:ScrollMsg(string.format(ctLang[6], tPropConf.sName))
				end
				return
			end
		end
	end
	for _, tItem in ipairs(tConsume) do
		local nType, nID, nNum = table.unpack(tItem)
		if nID > 0 then
			oPlayer.m_oBagModule:SubItem(nType, nID, nNum, gtReason.eUseProp)
		end
	end
	local tItemList = {}
	local tDropItem = DropMgr:GenDropItem(tGiftConf.nDropID)
	for _, tItem in ipairs(tDropItem) do
		local nType, nID, nNum = table.unpack(tItem)
		if nID > 0 then		
			local tList = oPlayer:AddItem(nType, nID, nNum, gtReason.eUseProp)
			local oArm 
			if nType == gtObjType.eArm then
				oArm = tList and #tList > 0 and tList[1][2]
			end
			local nColor = GF.GetItemColor(nType, nID, oArm)	
			table.insert(tItemList, {nType=nType, nID=nID, nNum=nNum, nColor=nColor})
		end
	end
	if #tItemList > 0 then
		CmdNet.PBSrv2Clt(oPlayer:GetSession(), "UsePropRet", {tItemList=tItemList})
	end
	oPlayer:ScrollMsg(ctLang[30])
	return true
end
