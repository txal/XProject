--修改属性请求
function CGMMgr:OnModUserReq(nBsrSession, tData)
	print("CGMMgr:OnModUserReq***", nBsrSession, tData)
	local bRes = false
	local nCharID = tonumber(tData.charid)
	local oPlayer = goPlayerMgr:GetPlayerByCharID(nCharID)
	if oPlayer then 
		local nYuanBao = oPlayer:GetYuanBao()
		if nYuanBao ~= tData.yuanbao then
			local nAddVal = tData.yuanbao - nYuanBao
			oPlayer:AddItem(gtItemType.eCurr, gtCurrType.eYuanBao, nAddVal, "GM")
		end

		local nYinLiang = oPlayer:GetYinLiang()
		if nYinLiang ~= tData.yinliang then
			local nAddVal = tData.yinliang - nYinLiang
			oPlayer:AddItem(gtItemType.eCurr, gtCurrType.eYinLiang, nAddVal, "GM")
		end

		local nWeiWang = oPlayer:GetWeiWang()
		if nWeiWang ~= tData.weiwang then
			local nAddVal = tData.weiwang - nWeiWang 
			oPlayer:AddItem(gtItemType.eCurr, gtCurrType.eWeiWang, nAddVal, "GM")
		end

		local nWaiJiao = oPlayer:GetWaiJiao()
		if nWaiJiao ~= tData.waijiao then
			local nAddVal = tData.waijiao - nWaiJiao
			oPlayer:AddItem(gtItemType.eCurr, gtCurrType.eWaiJiao, nAddVal, "GM")
		end

		if oPlayer:GetVIP() ~= tData.vip then
			oPlayer:SetVIP(tData.vip, "GM")
		end
		oPlayer:SaveData()
		bRes = true
	end
	Srv2Srv.GMModUserRet(gtNetConf:GlobalService(), 0, nBsrSession, bRes)
end

--取排行榜
function CGMMgr:OnRankingReq(nSrc, nSession, nBsrSession, nRankID, nPageIndex, nPageSize)
	print("CGMMgr:OnRankingReq***", nBsrSession, nRankID, nPageIndex, nPageSize)
	local tList = {}
	if nRankID == 2 then 		--国力
	elseif nRankID == 5 then	--亲密度
	elseif nRankID == 8 then	--威望(宫斗)
	end
	Srv2Srv.GMRankingRet(nSrc, nSession, nBsrSession, tList)
end