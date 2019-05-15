
function _PalanquinWayConfCheck()
    local tDupConf = ctDupConf[20]
    assert(tDupConf, "三生殿场景(20)不存在")
    for _, tConf in pairs(ctPalanquinWayConf) do 
        for k, tPos in ipairs(tConf.tTargetPos) do 
            if tPos[1] > tDupConf.nWidth or tPos[2] > tDupConf.nHeight then 
                assert(false, string.format("花轿路径配置(PalanquinWayConf.xml) (%s)移动坐标超过地图边界范围", tConf.sName))
            end
        end
    end
end

_PalanquinWayConfCheck()
