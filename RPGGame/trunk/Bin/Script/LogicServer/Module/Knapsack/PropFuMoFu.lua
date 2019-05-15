--附魔符使用
local table, string, math, os, pairs, ipairs, assert = table, string, math, os, pairs, ipairs, assert

function CPropFuMoFu:Ctor(oModule, nID, nGrid, bBind, tPropExt)
	CPropBase.Ctor(self,oModule, nID, nGrid, bBind, tPropExt) --调用基类构造函数
end

function CPropFuMoFu:LoadData(tData)
	CPropBase.LoadData(self, tData) --基类数据
end

function CPropFuMoFu:SaveData()
	local tData = CPropBase.SaveData(self) --基类数据
	return tData
end

--使用道具
function CPropFuMoFu:Use(nParam1)
	local oRole = self.m_oModule.m_oRole
	local tConf = self:GetPropConf()	
	local nAttrID = tConf.eParam()
	local nAttrVal = math.floor(tConf.eParam1())
	if nAttrID <= 0 or nAttrVal <= 0 then
		return oRole:Tips(string.format("%s附魔参数配置错误", tConf.sName))
	end

	local oWeapon = self.m_oModule:GetWeapon()
	if not oWeapon then
	 	return oRole:Tips("没有可附魔的武器，请先穿上武器装备")
	end

	local tAttrList = {}
	local tFuMoAttrMap = oWeapon:GetFuMoAttrMap()
	for nAttrID, tAttr in pairs(tFuMoAttrMap) do
		table.insert(tAttrList, {nAttrID, tAttr[1], tAttr[2]}) --属性ID,属性值,过期时间
	end

	table.sort(tAttrList, function(t1, t2) return t1[1]<t2[1] end)
	local _FuMoHandle = function ()
		local _FuMoAddAttrValue = function (nAttrID, nAttrVal)
			oWeapon:AddFuMoAttr(nAttrID, nAttrVal, os.time()+12*3600)
			oRole:SubItem(gtItemType.eProp, tConf.nID, 1, "附魔")
			local sTips = "%s附魔成功，%s+%d"
			local sAttrName = gtBATName[nAttrID] or ""
			oRole:Tips(string.format(sTips, oWeapon:GetName(), sAttrName, nAttrVal))
			if oRole:IsInBattle() then
				return oRole:Tips("属性将在战斗结束后生效")
			end
		end

		if #tAttrList >= 5 and not tFuMoAttrMap[nAttrID] then
			local tOption = {}
			for nIndex, tAttr in ipairs(tAttrList) do
				local nExpireTime = tAttr[3] - os.time()
				local nMin = math.floor(nExpireTime/60)
				local nSec = nExpireTime - nMin*60
				local sStrAttr = string.format("%s+%d，剩余%d分%d秒", gtBATName[tAttr[1]], tAttr[2], nMin, nSec)
				table.insert(tOption, sStrAttr)
			end

			local sCont = "你的武器已经拥有5项附魔属性，需要清除一项才能继续附魔，请选择："
			local tMsg = {sCont=sCont, tOption=tOption, nTimeOut=30}
			local _fnCallBack = function (tData)
				local tAttr = tAttrList[tData.nSelIdx]
				if not tAttr then
					return oRole:Tips("选择错误:"..tData.nSelIdx)
				end
				oWeapon:RemoveFuMoAttr(tAttr[1], true)
				_FuMoAddAttrValue(nAttrID, nAttrVal)
			end
			goClientCall:CallWait("ConfirmRet", _fnCallBack, oRole, tMsg)

		else
			_FuMoAddAttrValue(nAttrID, nAttrVal)
		end
	end

	if oWeapon:GetFuMoAttr(nAttrID) then
		local sCont = "再次附魔会重置附魔效果"
		local sCont2 = "当前符文等级低于已有附魔等级符文，使用当前符文后，会替换高阶等级符文的附魔效果，确定要如此做吗？"
		local tOption = {"取消", "确定"}
		local tMsg = {sCont=sCont, tOption=tOption, nTimeOut=30}
		if oWeapon:GetFuMoAttr(nAttrID)[1] > nAttrVal then
			tMsg.sCont = sCont2
		end
		local _fnReplaceCallBack = function (tData)
			if tData.nSelIdx == 2 then
				_FuMoHandle()
			end
		end
		goClientCall:CallWait("ConfirmRet", _fnReplaceCallBack, oRole, tMsg)
	else
		_FuMoHandle()
	end
end