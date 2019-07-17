--赏金任务
local _ctShangJinTaskConf = {}

local function _ShangJinTaskConfCheck()
    for nID, tConf in pairs(ctShangJinTaskConf) do
        if not _ctShangJinTaskConf[tConf.nStart] then
            _ctShangJinTaskConf[tConf.nStart] = {}
        end
        if tConf.nStart > 0 then
            assert(ctMonsterConf[tConf.nMonsterID], "赏金任务怪物配置错误，任务ID: "..nID)
        end
        table.insert(_ctShangJinTaskConf[tConf.nStart], tConf)
    end
end
_ShangJinTaskConfCheck()

--按星数获取所有该星数的任务
function ctShangJinTaskConf:GetPool(nStart)
    assert(nStart, "参数错误")
    local tConfList = assert(_ctShangJinTaskConf[nStart], "星数不存在" .. nStart)
    return tConfList
end