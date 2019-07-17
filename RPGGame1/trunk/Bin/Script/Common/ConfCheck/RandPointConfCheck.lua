--随机点预处理
local _ctRandPointConf = {}
local function _RandPointConfCheck()
    for nID, tConf in pairs(ctRandomPoint) do
        if not _ctRandPointConf[tConf.nType] then
            _ctRandPointConf[tConf.nType] = {}
        end
        local tDupConf = ctDupConf[tConf.nDupID]
        assert(tDupConf, "场景配置错误,场景ID:"..tConf.nDupID)
        assert(100 <= tConf.tPos[1][1] and tConf.tPos[1][1] <= tDupConf.nWidth-100, "随机坐标X错误，坐标ID："..nID)
        assert(100 <= tConf.tPos[1][2] and tConf.tPos[1][2] < tDupConf.nHeight-100, "随机坐标Y错误，坐标ID："..nID)
        table.insert(_ctRandPointConf[tConf.nType], tConf)
    end
end
_RandPointConfCheck()

function ctRandomPoint.GetPool(nType, nLevel)
    assert(nType and nLevel, "参数错误")
    local tConfList = assert(_ctRandPointConf[nType], "坐标用途类型不存在: "..nType)
    local tLevelConfList = {}
    for _, tConf in pairs(tConfList) do
        if nLevel >= tConf.nMinGrade and nLevel <= tConf.nMaxGrade then
            table.insert(tLevelConfList, tConf)
        end
    end
    return tLevelConfList
end