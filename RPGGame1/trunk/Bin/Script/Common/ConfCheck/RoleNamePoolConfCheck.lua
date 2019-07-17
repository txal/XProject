

local function _RoleNamePoolConf() 
    local nBeginTime = os.clock()
    local tFirstRecord = {}
    local tLastRecord = {}

    local fnCheckFirst = function(sFirst) 
        for _, tLast in pairs(tFirstRecord) do 
            if tLast[sFirst] then 
                return true 
            end
        end
        return false
    end

    local fnCheckLast = function(sLast)
        for _, tLast in pairs(tLastRecord) do 
            if tLast[sLast] then 
                return true 
            end
        end
        return false
    end


    for nID, tConf in pairs(ctRoleNamePoolConf) do 
        local nFirstCount = 0
        local nLastCount = 0
        for k, v in pairs(tConf.tXing) do
            if fnCheckLast(v) then 
                print(string.format("请注意，ID(%d)姓(%s)存在重复", nID, v)) 
            end
            nLastCount = nLastCount + 1
        end
        table.insert(tLastRecord, tConf.tXing)

        for k, v in pairs(tConf.tMing) do 
            if fnCheckFirst(v) then 
                print(string.format("请注意，ID(%d)名(%s)存在重复", nID, v)) 
            end
            nFirstCount = nFirstCount + 1
        end
        table.insert(tFirstRecord, tConf.tMing)

        print(string.format("名字库(%d), 姓(%d), 名(%d)", nID, nLastCount, nFirstCount)) 
    end
    local nEndTime = os.clock()
    print(string.format("检查名字库完成，耗时(%d)ms", 
        math.ceil((nEndTime - nBeginTime)*1000)))
end

if gbInnerServer then 
    _RoleNamePoolConf()
end

