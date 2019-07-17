

local tRoleGrowthLevelExpMap = {}  --{nID:{nLevel:tConf, ...}, ...}
local tRoleGrowthLevelConfCount = {}
for nIndex, tConf in pairs(ctRoleGrowthLevelExpConf) do 
    if tConf.nID > 0 then 
        local tIDList = tRoleGrowthLevelExpMap[tConf.nID] or {}
        tIDList[tConf.nLevel] = tConf
        tRoleGrowthLevelExpMap[tConf.nID] = tIDList
        
        tRoleGrowthLevelConfCount[tConf.nID] = (tRoleGrowthLevelConfCount[tConf.nID] or 0) + 1
    end
end

for nID, nLevelCount in pairs(tRoleGrowthLevelConfCount) do 
    local tIDList = tRoleGrowthLevelExpMap[nID]
    if tIDList[0] then  --防止策划配置从0开始
        assert((nLevelCount - 1) == #tIDList, "配置错误，等级不连续")
    else
        assert(nLevelCount == #tIDList, "配置错误，等级不连续")
    end
end

function ctRoleGrowthConf.GetLevelConfList(nID)
    return tRoleGrowthLevelExpMap[nID]
end

function ctRoleGrowthConf.GetConfMaxLevel(nID)
    return #tRoleGrowthLevelExpMap[nID]
end

--返回升到目标等级需要消耗的材料
function ctRoleGrowthConf.GetLevelUpCost(nID, nCurLevel, nTarLevel, nExp)
    assert(nID > 0 and nCurLevel >= 0 and nCurLevel < nTarLevel and nExp >= 0)
    if nCurLevel >= nTarLevel then 
        return {}, 0
    end

    local nCostExp = 0
    local tLevelConfList = tRoleGrowthLevelExpMap[nID]
    for k = nCurLevel + 1, nTarLevel do 
        local tLevelConf = tLevelConfList[k]
        assert(tLevelConf)
        nCostExp = nCostExp + tLevelConf.nExp
    end

    local nCurExp = nExp
    nCostExp = nCostExp - nCurExp
    if nCostExp <= 0 then 
        return {}, 0
    end
    local tIDConf = ctRoleGrowthConf[nID]
    assert(tIDConf)
    local tCost = {}
    local nTotalAddExp = 0
    for _, tExpConf in ipairs(tIDConf.tExpProp) do 
        local nItemType = tExpConf[1]
        local nItemID = tExpConf[2]
        local nAddExp = tExpConf[3]
        if nItemType > 0 and nItemID > 0 and nAddExp > 0 then    
            --只根据第一个配置的有效数据计算，不考虑多组材料组合情况
            local nItemNum = math.ceil(nCostExp / nAddExp)
            nTotalAddExp = nTotalAddExp + nItemNum*nAddExp
            table.insert(tCost, {nItemType, nItemID, nItemNum})
            break
        end
    end
    return tCost, nTotalAddExp
end

--返回等级，经验
function ctRoleGrowthConf.AddExp(nID, nCurLevel, nLimitLevel, nCurExp, nAddExp)
    assert(nID > 0 and nCurLevel >= 0 and nLimitLevel >= 0 and nCurExp >= 0 and nAddExp >= 0, "参数错误")
    if nCurLevel >= nLimitLevel then 
        return nCurLevel, nCurLevel+nAddExp
    end

    local nTotalExp = nAddExp + nCurExp
    local tLevelConfList = tRoleGrowthLevelExpMap[nID]
    local nTarLevel = nCurLevel
    for k = nCurLevel + 1, nLimitLevel do 
        local tLevelConf = tLevelConfList[k]
        assert(tLevelConf)
        local nTempExp = nTotalExp - tLevelConf.nExp
        if nTempExp < 0 then
            break 
        end
        nTarLevel = k
        nTotalExp = nTempExp
    end
    return nTarLevel, nTotalExp
end

--当前可添加的最大经验值
function ctRoleGrowthConf.GetMaxAddExp(nID, nCurLevel, nLimitLevel, nCurExp)
    assert(nID > 0 and nCurLevel >= 0 and nLimitLevel >= 0 and nCurExp >= 0, "参数错误")
    if nCurLevel >= nLimitLevel then 
        return 0
    end

    local tLevelConfList = ctRoleGrowthConf.GetLevelConfList(nID)
    assert(tLevelConfList)
    local nTotalExp = 0
    for k = nCurLevel + 1, nLimitLevel do 
        local tLevelConf = tLevelConfList[k]
        assert(tLevelConf)
        nTotalExp = nTotalExp + tLevelConf.nExp
    end
    return math.max((nTotalExp - nCurExp), 0)
end

--返回实际消耗的物品，以及添加的经验值
function ctRoleGrowthConf.GetExpItemCost(nID, nAddExp)
    local tIDConf = ctRoleGrowthConf[nID]
    assert(tIDConf)
    if nAddExp <= 0 then 
        return {}, 0
    end

    local tCost = {}
    local nTotalAddExp = 0
    for _, tExpConf in ipairs(tIDConf.tExpProp) do 
        local nItemType = tExpConf[1]
        local nItemID = tExpConf[2]
        local nSingleExp = tExpConf[3]
        if nItemType > 0 and nItemID > 0 and nSingleExp > 0 then 
            --只根据第一个配置的有效数据计算，不考虑多组材料组合情况
            local nItemNum = math.ceil(nAddExp / nSingleExp)
            nTotalAddExp = nItemNum*nAddExp
            -- table.insert(tCost, {nItemType, nItemID, nItemNum})
            tCost = {nItemType, nItemID, nItemNum}
            break
        end
    end
    return tCost, nTotalAddExp
end

function ctRoleGrowthConf.GetItemExp(nID, nItemType, nItemID, nNum)
    print("nID, nItemType, nItemID, nNum", nID, nItemType, nItemID, nNum)
    nNum = nNum or 1
    assert(nNum > 0)
    local tGrowthConf = ctRoleGrowthConf[nID]
    assert(tGrowthConf)
    for _, tItem in ipairs(tGrowthConf.tExpProp) do 
		local nType = tItem[1]
		local nID = tItem[2]
		local nSingleExp  = tItem[3]
        if nType > 0 and nID > 0 and nSingleExp > 0 and 
            nType == nItemType and nID == nItemID then 
            return nSingleExp*nNum
		end
    end
    -- return 0
end

