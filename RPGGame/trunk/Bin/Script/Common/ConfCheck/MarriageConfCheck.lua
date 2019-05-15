
local function _MarriageNpcConfCheck() 
    local nWeddingCandyNpcID = 42
    local nPalanquinNpcID = 43
    if not ctMonsterConf[nWeddingCandyNpcID] then 
        local sTips = string.format("喜糖NPC ID(%d) MonsterConf 表中不存在", 
            nWeddingCandyNpcID)
        assert(false, sTips)
    end
    if not ctMonsterConf[nPalanquinNpcID] then 
        local sTips = string.format("婚车NPC ID(%d) MonsterConf 表中不存在", 
        nPalanquinNpcID)
        assert(false, sTips)
    end

end

_MarriageNpcConfCheck()

