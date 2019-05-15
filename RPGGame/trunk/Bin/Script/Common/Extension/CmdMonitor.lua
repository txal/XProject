function CCmdMonitor:Ctor()
    self.m_tCmdMap = {}
end

--@nCostTime 秒
function CCmdMonitor:AddCmd(xCmd, nCostTime)
    assert(xCmd and nCostTime)
    if nCostTime * 1000 >= 12 then
        LuaTrace("------slow msg------", xCmd, "time:", nCostTime)
    end
    local tCmdRecord = self.m_tCmdMap[xCmd]
    if not tCmdRecord then
        tCmdRecord = {0, 0}
        self.m_tCmdMap[xCmd] = tCmdRecord
    end
    tCmdRecord[1] = tCmdRecord[1] + 1
    tCmdRecord[2] = tCmdRecord[2] + nCostTime
end

function CCmdMonitor:DupCmd()
    LuaTrace("------dump cmd------")
    local tCmdList = {}
    for k, v in pairs(self.m_tCmdMap) do
        table.insert(tCmdList, {k, v[2]/v[1], v[1]})
    end
    local function _sort(tData1, tData2)
        return tData1[2] > tData2[2]
    end
    table.sort(tCmdList, _sort)
    local oFile = io.open("cmddump.txt", "w")
    for _, v in ipairs(tCmdList) do
        local sRes = string.format("%s\t%f\t%d\n", v[1], v[2], v[3])
        oFile:write(sRes)
    end
    oFile:close()
end

goCmdMonitor = goCmdMonitor or CCmdMonitor:new()
