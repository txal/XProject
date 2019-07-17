--喜糖
local table, string, math, os, pairs, ipairs, assert = table, string, math, os, pairs, ipairs, assert

function CPropWeddingCandy:Ctor(oModule, nID, nGrid, bBind, tPropExt)
    CPropGift.Ctor(self,oModule, nID, nGrid, bBind, tPropExt)
end


function CPropWeddingCandy:LoadData(tData)
	CPropGift.LoadData(self, tData) --基类数据
end

function CPropWeddingCandy:SaveData()
	local tData = CPropGift.SaveData(self) --基类数据
	return tData
end

function CPropWeddingCandy:GetGiftConf()
	return assert(ctGiftConf[self:GetID()])
end

function CPropWeddingCandy:Use(nNum)
    nNum = nNum or 1
    nNum = math.max(nNum, 1)
    if self:GetNum() < nNum then 
        return 
    end
    local oRole = self.m_oModule.m_oRole
    local nNumLimit = 5
    local nCount = self.m_oModule:GetUseCount(self:GetID())
    if nCount >= nNumLimit then 
        oRole:Tips(string.format("你今天已经吃了%d颗%s啦，小心蛀牙哦！", 
            nNumLimit, self:GetName()))
        return
    end
    nMaxUseNum = math.max(nNumLimit - nCount, 0)
    nNum = math.min(nMaxUseNum, nNum)
    if nNum < 0 then 
        return 
    end
    if CPropGift.Use(self, nNum) then 
        self.m_oModule:AddUseCount(self:GetID(), nNum)
    end
    -- for k = 1, nNum do 
    --     if self:TrueUse() then 
    --         self.m_oModule:AddUseCount(self:GetID(), 1)
    --     else
    --         break
    --     end
    -- end
end
