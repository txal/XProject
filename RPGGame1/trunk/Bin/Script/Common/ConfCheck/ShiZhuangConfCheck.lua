--时装配置检查
local table, string, math, os, pairs, ipairs, assert = table, string, math, os, pairs, ipairs, assert

local function _ShiZhuangConfCheck()
    for nShiZhuangID, tConf in pairs(ctShiZhuangConf) do
        assert(1 <= tConf.nPosType and tConf.nPosType <= 3, "时装配置错误，时装ID: "..nShiZhuangID)
        for nIndex, tAttr in pairs(tConf.tAttrList) do
            assert(gtBAD.eMinRAT <= tAttr[1] and tAttr[1] <= gtBAD.eMaxRAT, "时装配置错误，时装ID: "..nShiZhuangID)
        end
        assert(tConf.bIsSuit == false or tConf.bIsSuit == true, "时装配置错误，时装ID: "..nShiZhuangID)
        if tConf.bIsSuit == 1 then
            assert(ctSuitConf[tConf.nSuitIndex], "时装配置错误，时装ID: "..nShiZhuangID)
        end
        for nIndex, tCost in pairs(tConf.tCostProp) do
            assert(ctPropConf[tCost[1]], "时装配置错误，时装ID: "..nShiZhuangID)
        end
        for _, tWash in pairs(tConf.tWashCost) do
            assert(ctPropConf[tWash[1]], "时装配置错误，时装ID: "..nShiZhuangID)
        end
        assert(tConf.nGoldCost >= 0, "时装配置错误，时装ID: "..nShiZhuangID)
    end
end

_ShiZhuangConfCheck()

--套装配置检查
local function _SuitConfCheck()
    for nSuitIndex, tConf in pairs(ctSuitConf) do
        for nIndex, tSuit in pairs(tConf.tSuitIDList) do
            assert(ctShiZhuangConf[tSuit[1]], "套装配置错误，时装ID: "..nSuitIndex)
        end
        for nIndex, tAttr in pairs(tConf.tAttrActTwo) do
            assert(gtBAD.eMinRAT <= tAttr[1] and tAttr[1] <= gtBAD.eMaxRAT, "套装配置错误，时装ID: "..nSuitIndex)
        end
        for nIndex, tAttr in pairs(tConf.tAttrActThree) do
            assert(gtBAD.eMinRAT <= tAttr[1] and tAttr[1] <= gtBAD.eMaxRAT, "套装配置错误，时装ID: "..nSuitIndex)
        end
    end
end
_SuitConfCheck()