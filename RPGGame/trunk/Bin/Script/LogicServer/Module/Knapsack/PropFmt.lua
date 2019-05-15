--阵法道具
local table, string, math, os, pairs, ipairs, assert = table, string, math, os, pairs, ipairs, assert

function CPropFmt:Ctor(oModule, nID, nGrid, bBind, tPropExt)
	CPropBase.Ctor(self, oModule, nID, nGrid, bBind, tPropExt) --调用基类构造函数
end

function CPropFmt:LoadData(tData)
	CPropBase.LoadData(self, tData) --基类数据
end

function CPropFmt:SaveData()
	local tData = CPropBase.SaveData(self) --基类数据
	return tData
end

--使用道具
function CPropFmt:Use()
	local nFmtID = self:GetID()
	local oRole = self.m_oModule.m_oRole
	local oFmt = self.m_oModule.m_oRole.m_oFormation

	--是否已拥有
	if oFmt:GetFmt(nFmtID) then
		return oRole:Tips(string.format("已拥有%s，不需要学习", CKnapsack:PropName(nFmtID)))
	end

	--已达上限
	if oFmt:FmtNum() >= oFmt:MaxFmt() then
		return oRole:Tips("已达到阵法数量上限，开启失败")
		-- local sCont = string.format("你当前最多可掌握%d种阵法，现在学习%s阵会随机覆盖已掌握的阵法，你确定要学习这个阵法吗？", oFmt:MaxFmt(), CKnapsack:PropName(nFmtID))
		-- local tMsg = {sCont=sCont, tOption={"继续学习", string.format("%d元宝", oFmt._nGridPrice), "还是算了"}, nTimeOut=30}

		-- goClientCall:CallWait("ConfirmRet", function(tData)
		-- 	if tData.nSelIdx == 3 then --还是算了
		-- 		return
		-- 	end
		-- 	if tData.nSelIdx == 2 then --购买阵格
		-- 		if not oFmt:FmtBuyReq() then
		-- 			return
		-- 		end
		-- 	end
		-- 	oRole:SubItem(gtItemType.eProp, nFmtID, 1, "使用阵法道具")
		-- 	local nReplaceFmt = oFmt:AddFmt(nFmtID)
		-- 	if nReplaceFmt == 0 then
		-- 		oRole:Tips(string.format("消耗了%d元宝，你学会了%s", oFmt._nGridPrice, CKnapsack:PropName(nFmtID)))
		-- 	else
		-- 		oRole:Tips(string.format("你学会了%s，但遗忘了%s", CKnapsack:PropName(nFmtID), CKnapsack:PropName(nReplaceFmt)))
		-- 	end
		-- end, oRole, tMsg)

	--未达上限
	else
		oFmt:AddFmt(nFmtID)
		oRole:SubItem(gtItemType.eProp, nFmtID, 1, "使用阵法道具")
		oRole:Tips(string.format("恭喜少侠学会了<color=#30a93e>%s</color>", CKnapsack:PropName(nFmtID)))

		-- local sCont = string.format("确定使用八阵图，学习上面记录的%s阵吗？\n（使用后八阵图将会消失）", CKnapsack:PropName(nFmtID))
		-- local tMsg = {sCont=sCont, tOption={"取消", "确认"}, nTimeOut=30}

		-- goClientCall:CallWait("ConfirmRet", function(tData)
		-- 	if tData.nSelIdx == 1 then return end

		-- 	oRole:SubItem(gtItemType.eProp, nFmtID, 1, "使用阵法道具")
		-- 	oFmt:AddFmt(nFmtID)
		-- 	oRole:Tips(string.format("你学会了<color=#30a93e>%s</color>", CKnapsack:PropName(nFmtID)))
		-- end, oRole, tMsg)
	end
end