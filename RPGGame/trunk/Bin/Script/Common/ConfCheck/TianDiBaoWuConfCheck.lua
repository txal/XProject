--天帝宝物配置检查
local table, string, math, os, pairs, ipairs, assert = table, string, math, os, pairs, ipairs, assert

local function _TianDiBaoWuConfCheck()
    for nSeq, tConf in pairs(ctTianDiBaoWuConf) do
        for nIndex, tShiZhuang in pairs(tConf.tShiZhuangIDList) do
            if tShiZhuang[1] == gtItemType.eProp then
                assert(ctPropConf[tShiZhuang[2]], "天帝宝物配置错误，配置ID: "..nSeq)
            end
        end
        assert(ctPropConf[tConf.nItemID], "天帝宝物配置错误，配置ID: "..nSeq)
        assert(tConf.nOnceNum >= 0, "天帝宝物配置错误，配置ID: "..nSeq)
        assert(tConf.nTemNum >= 0, "天帝宝物配置错误，配置ID: "..nSeq)
        assert(tConf.nCostOnce >= 0, "天帝宝物配置错误，配置ID: "..nSeq)
        assert(tConf.nCostTen >= 0, "天帝宝物配置错误，配置ID: "..nSeq)
        assert(tConf.nGetFuYuan >= 0, "天帝宝物配置错误，配置ID: "..nSeq)
        for nIndex, tAward in pairs(tConf.tAwardPoolID) do
            if tAward[1] == 2 then      --2为奖励池
                assert(ctAwardPoolConf.IsPoolExist(tAward[2]), "天帝宝物配置错误，配置ID: "..nSeq)
            end
        end
        for nIndex, tPos in pairs(tConf.tPosList) do
            local nWidth = ctDupConf[tPos[1]].nWidth
            local nHeight = ctDupConf[tPos[1]].nHeight
            assert(tPos[2] < nWidth and tPos[3] < nHeight, "天帝宝物配置错误，配置ID: "..nSeq.."X: "..nWidth.."Y: "..nHeight)
        end
    end
end

_TianDiBaoWuConfCheck()