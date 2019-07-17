--随机属性宝箱类
function CPropAttrBx:Ctor(oModule, nSysID, nGrid)
	CPropBase.Ctor(self, nSysID, nGrid)
	self.m_oModule = oModule
end

function CPropAttrBx:LoadData(tData)
	CPropBase.LoadData(self, tData)
end

function CPropAttrBx:SaveData()
	local tData = CPropBase.SaveData(self)
	return tData
end

--使用随机属性宝箱
function CPropAttrBx:Use(nNum)
	assert(nNum > 0, "参数错误")
	local oRole = self.m_oModule.m_oRole
	if self:GetNum() < nNum then
		return oRole:Tips("道具不足")
	end

	local tConf = self:GetConf()
	local tBoxConf = assert(ctBoxConf[tConf.nID], "宝箱找不到:"..tConf.nID)
	self.m_oModule:SubGridItem(self:GetSysID(), self:GetGrid(), nNum, "使用道具")

	local tOrgValMap = {}
	local tAwardMap = {}
	for k = 1, nNum do
		--随机知己成长点
		if tConf.nSubType == gtCurrType.eRandGrow then
			local tMCList = oRole.m_oMingChen:RandObj(1)
			if #tMCList <= 0 then
				return oRole:Tips("没有可随机的知己")
			end
			local nChengZhang = math.random(table.unpack(tBoxConf.tRandAttr[1]))

			--生成唯1KEY
			local nObjType = gtItemType.eMingChen
			local nObjID = tMCList[1]:GetID()
			local nCurrType = gtCurrType.eRandGrow
			local nQuaType = math.random(1, 4)
			local sKey = nObjType..nObjID..nCurrType..nQuaType

			--记录原始值
			if not tOrgValMap[sKey] then
				tOrgValMap[sKey] = tMCList[1]:GetGrowPoint(nQuaType)
			end
			--汇总奖励
			if not tAwardMap[sKey] then
				tAwardMap[sKey] = {nObjType=nObjType, nObjID=nObjID, nCurrType=nCurrType, nQuaType=nQuaType,
					nCurrVal=0, nOrgVal=tOrgValMap[sKey]}
			end
			tAwardMap[sKey].nCurrVal = tAwardMap[sKey].nCurrVal + nChengZhang

		--随机知己的战绩
		elseif tConf.nSubType == gtCurrType.eZhanJi then
			local tMCList = oRole.m_oMingChen:RandObj(1)
			if #tMCList <= 0 then
				return oRole:Tips("没有可随机的知己")
			end
			local nZJ = math.random(table.unpack(tBoxConf.tRandAttr[1]))

			--生成唯1KEY
			local nObjType = gtItemType.eMingChen
			local nObjID = tMCList[1]:GetID()
			local nCurrType = gtCurrType.eZhanJi
			local sKey = nObjType..nObjID..nCurrType

			--记录原始值
			if not tOrgValMap[sKey] then
				tOrgValMap[sKey] = tMCList[1]:GetZhanJi()
			end
			--汇总奖励
			if not tAwardMap[sKey] then
				tAwardMap[sKey] = {nObjType=nObjType, nObjID=nObjID, nCurrType=nCurrType, nCurrVal=0, nOrgVal=tOrgValMap[sKey]}
			end
			tAwardMap[sKey].nCurrVal = tAwardMap[sKey].nCurrVal + nZJ

		--随机知己亲密度
		elseif tConf.nSubType == gtCurrType.eRandQinMi then
			local tMCList = oRole.m_oMingChen:RandObj(1)
			if #tMCList <= 0 then
				return oRole:Tips("没有可随机的知己")
			end
			local nQinMi = math.random(table.unpack(tBoxConf.tRandAttr[1]))

			--生成唯1KEY
			local nObjType = gtItemType.eMingChen
			local nObjID = tMCList[1]:GetID()
			local nCurrType = gtCurrType.eRandQinMi
			local sKey = nObjType..nObjID..nCurrType

			--记录原始值
			if not tOrgValMap[sKey] then
				tOrgValMap[sKey] = tMCList[1]:GetQinMi()
			end
			--汇总奖励
			if not tAwardMap[sKey] then
				tAwardMap[sKey] = {nObjType=nObjType, nObjID=nObjID, nCurrType=nCurrType, nCurrVal=0, nOrgVal=tOrgValMap[sKey]}
			end
			tAwardMap[sKey].nCurrVal = tAwardMap[sKey].nCurrVal + nQinMi


		--随机知己好感
		elseif tConf.nSubType == gtCurrType.eRandHaoGan then
			local tMCList = oRole.m_oMingChen:RandObj(1)
			if #tMCList <= 0 then
				return oRole:Tips("没有可随机的知己")
			end
			local nHaoGan = math.random(table.unpack(tBoxConf.tRandAttr[1]))

			--生成唯1KEY
			local nObjType = gtItemType.eMingChen
			local nObjID = tMCList[1]:GetID()
			local nCurrType = gtCurrType.eRandHaoGan
			local sKey = nObjType..nObjID..nCurrType

			--记录原始值
			if not tOrgValMap[sKey] then
				tOrgValMap[sKey] = tMCList[1]:GetHaoGan()
			end
			--汇总奖励
			if not tAwardMap[sKey] then
				tAwardMap[sKey] = {nObjType=nObjType, nObjID=nObjID, nCurrType=nCurrType, nCurrVal=0, nOrgVal=tOrgValMap[sKey]}
			end
			tAwardMap[sKey].nCurrVal = tAwardMap[sKey].nCurrVal + nHaoGan

		--随机知己技能点
		elseif tConf.nSubType == gtCurrType.eRandSKP then
			local tMCList = oRole.m_oMingChen:RandObj(1)
			if #tMCList <= 0 then
				return oRole:Tips("没有可随机的知己")
			end	
			local nSKP = math.random(table.unpack(tBoxConf.tRandAttr[1]))

			--生成唯1KEY
			local nObjType = gtItemType.eMingChen
			local nObjID = tMCList[1]:GetID()
			local nCurrType = gtCurrType.eRandSKP
			local sKey = nObjType..nObjID..nCurrType

			--记录原始值
			if not tOrgValMap[sKey] then
				tOrgValMap[sKey] = tMCList[1]:GetSKPoint()
			end
			--汇总奖励
			if not tAwardMap[sKey] then
				tAwardMap[sKey] = {nObjType=nObjType, nObjID=nObjID, nCurrType=nCurrType, nCurrVal=0, nOrgVal=tOrgValMap[sKey]}
			end
			tAwardMap[sKey].nCurrVal = tAwardMap[sKey].nCurrVal + nSKP

		end
	end

	local tAwardList = {}
	for _, tItem in pairs(tAwardMap) do
		table.insert(tAwardList, tItem)
		if tItem.nObjType == gtItemType.eMingChen then
			local oMC = oRole.m_oMingChen:GetObj(tItem.nObjID)
			if tItem.nCurrType == gtCurrType.eRandGrow then --随机成长点
				oMC:AddGrowPoint(tItem.nQuaType, tItem.nCurrVal, "使用道具")

			elseif tItem.nCurrType == gtCurrType.eZhanJi then --随机大臣战绩
				oMC:AddZhanJi(tItem.nCurrVal, "使用道具")

			elseif tItem.nCurrType == gtCurrType.eRandQinMi then
				oMC:AddQinMi(tItem.nCurrVal, "使用道具")

			elseif tItem.nCurrType == gtCurrType.eRandHaoGan then
				oMC:AddHaoGan(tItem.nCurrVal, "使用道具")

			elseif tItem.nCurrType == gtCurrType.eRandSKP then
				oMC:AddSKPoint(tItem.nCurrVal, "使用道具")

			else
				assert(false)
			end

		else
			assert(false)
		end
	end
	Network.PBSrv2Clt(oRole:GetSession(), "GuoKuUseAttrBoxRet", {nPropID=tConf.nID, nPropNum=nNum, tAwardList=tAwardList})
	return true
end