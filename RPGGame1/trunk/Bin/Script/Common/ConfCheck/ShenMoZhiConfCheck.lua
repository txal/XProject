--神魔志配置检查
local function _ShenMoZhiConfCheck()
    for _, tConf in pairs(ctShenMoZhiConf) do
        local tMonster = ctMonsterConf[tConf.nFightID]
        assert(tMonster, string.format("神魔志怪物配置错误(%d)", tConf.nFightID))
    end
end

_ShenMoZhiConfCheck()