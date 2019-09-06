--全局函数
local table, string, math, os, pairs, ipairs, assert = table, string, math, os, pairs, ipairs, assert
CUtil = CUtil or class()

--生成唯一ID,全世界唯一,64位
function CUtil:GenUUID()
    return NetworkExport.GenUUID()
end

--通过数据库生成唯一自增ID,全世界唯一,从1开始
function CUtil:GenAutoID(sKey)
    local oDB = GetGModule("DBMgr"):GetGameDB(0, "center")
    local nAutoID = oDB:HIncr(gtDBDef.sAutoIDDB, sKey)
    return nAutoID
end

--生成副本ID,全世界唯一
function CUtil:GenDupID(nConfID)
    assert(nConfID <= 0xFFFFF, "配置ID不能超过:"..(0xFFFFF))
    local nAutoID = (self:GenAutoID() % 0xFFFFFFFF) + 1
    return (nConfID<<32|nAutoID)
end
--生成场景ID,全世界唯一
CUtil.GenSceneID = CUtil.GenDupID

--取副本配置ID
function CUtil:GetDupConfID(nDupID)
    return (nDupID>>32&0x7FFFFFFF)
end
--取场景配置ID
CUtil.GetSceneConfID = CUtil.GetDupConfID

--生成角色显示用ID,全世界唯一
function CUtil:GenRoleShowID(sKey)
    local nAutoID = self:GenAutoID(sKey)
    local nShowID = gtGDef.tConst.nBaseRoleID + nAutoID%(gtGDef.tConst.nMaxRoleID-gtGDef.tConst.nBaseRoleID)+1
    return nShowID
end

--取当前进程服务ID
function CUtil:GetServiceID()
    return GlobalExport.GetServiceID()
end

--取标准时间(毫秒)
function CUtil:GetUnixMSTime()
    return NetworkExport.UnixMSTime()
end

--取系统运行时间(毫秒)
function CUtil:GetClockMSTime()
    return NetworkExport.ClockMSTime()
end

--添加屏蔽字
function CUtil:AddBadWord(sWord)
    GlobalExport.AddWord(sWord)
end

--通过会话ID取网关服务ID
--@nSession: 会话ID
function CUtil:GetGateBySession(nSessionID)
    assert(nSessionID, "参数错误")
    return (nSessionID >> gtGDef.tConst.nServiceShift)
end

--生成弱表
--@sFlag k键; v值; kv键值
function CUtil:WeakTable(sFlag)
    local tTable = {}
    setmetatable(tTable, {__mode=sFlag})
    return tTable
end

--随机坐标
--@nPosX, nPosY: 原点
--@nRad: 半径
function CUtil:RandPos(nPosX, nPosY, nRad)
    local nRndX = math.max(0, math.random(nPosX-nRad, nPosX+nRad))
    local nRndY = math.max(0, math.random(nPosY-nRad, nPosY+nRad))
    return nRndX, nRndY
end

--取两点的距离
function CUtil:Distance(nPosX1, nPosY1, nPosX2, nPosY2)
    local nDistX = nPosX1 - nPosX2
    local nDistY = nPosY1 - nPosY2
    local nDist = math.floor(math.sqrt(nDistX*nDistX + nDistY*nDistY))
    return nDist
end

--是否障碍点
function CUtil:IsBlockUnit(nMapID, nPosX, nPosY)
    return GlobalExport.IsBlockUnit(nMapID, nPosX, nPosY)
end

--通过逻辑服ID取服务器ID
function CUtil:GetServerByLogic(nLogicServiceID)
    local oServerMgr = GetGModule("ServerMgr")
    local nServerID = nLogicServiceID>=100 and oServerMgr:GetWorldServerID() or oServerMgr:GetServerID()
    return nServerID
end

--名字库随机名字
function CUtil:GenNameByPool()
    local nIndex = math.random(1, #ctRoleNamePoolConf)
    local tPoolConf = ctRoleNamePoolConf[nIndex]
    local nRndXing = math.random(1, #tPoolConf.tXing)
    local nRndMing = math.random(1, #tPoolConf.tMing)
    local sXing = tPoolConf.tXing[nRndXing][1]
    local sMing = tPoolConf.tMing[nRndMing][1]
    return (sXing..sMing)
end

--发送邮件
--@nTarServer 玩家所属服务器(oRole:GetServerID())
--@sTitle 标题
--@sContent 内容
--@tItemList 物品列表{{id,num,itemext}, Prop:SaveData(), ...}
--@nTarRoleID 目标玩家ID
function CUtil:SendMail(nTarServer, sTitle, sContent, tItemList, nTarRoleID)
    assert(nTarServer and sTitle and sContent and tItemList and nTarRoleID, "参数错误")
    local oServerMgr = GetGModule("ServerMgr")
    assert(nTarServer < oServerMgr:GetWorldServerID(), "目标服务器不能是世界服")

    local nTarService = oServerMgr:GetGlobalService(nTarServer)
    if oServerMgr:GetServerID() == nTarServer and nTarService == CUtil:GetServiceID() then
        GetGModule("MailMgr"):SendMail(sTitle, sContent, tItemList, nTarRoleID)
    else
       Network:RMCall("SendMailReq", nil, nTarServer, nTarService, 0, sTitle, sContent, tItemList, nTarRoleID)
    end
end

--发送滚动公告(跑马灯)
--@nTarServer 玩家所属服务器(oRole:GetServerID())，如果nTarServer为0，则为全区广播
--@sContent 内容
function CUtil:SendNotice(nTarServer, sContent)
    assert(nTarServer and sContent, "参数错误")
    local oServerMgr = GetGModule("ServerMgr")
    if nTarServer > 0 then 
        assert(nTarServer < oServerMgr:GetWorldServerID(), "目标服务器不能是世界服")
        local nTarService = oServerMgr:GetGlobalService(nTarServer)
        if oServerMgr:GetServerID() == nTarServer and nTarService == CUtil:GetServiceID() then
            GetGModule("NoticeMgr"):SendNoticeReq(sContent)
        else
            Network:RMCall("SendNoticeReq", nil, nTarServer, nTarService, 0, sContent)
        end
    else
        local nWorldServerID = oServerMgr:GetWorldServerID()
        local nTarService = goServerMgr:GetGlobalService(nWorldServerID)
        if nTarService == CUtil:GetServiceID() and oServerMgr:GetServerID() == nWorldServerID then 
            Network.RpcSrv2Srv.SendNoticeAllReq(nTarServer, nTarService, 0, sContent)
        else
            Network:RMCall("SendNoticeAllReq", nil, nWorldServerID, nTarService, 0, sContent)
        end
    end
end

--发送系统频道聊天
--@sTitle  标题(系统,传闻,...)
--@sContent 内容
function CUtil:SendSystemTalk(sTitle, sContent)
    local oServerMgr = GetGModule("ServerMgr")
    local nWorldServerID = oServerMgr:GetWorldServerID()
    local nTarService = oServerMgr:GetGlobalService(nWorldServerID)
    if oServerMgr:GetServerID() == nWorldServerID and nTarService == CUtil:GetServiceID() then
        GetGModule("Talk"):SendSystemMsg(sContent, sTitle)
    else
        Network:RMCall("SendSystemTalkReq", nil, nWorldServerID, nTarService, 0, sTitle, sContent)
    end
end

--发送队伍频道聊天
--@nRoleID 角色ID
--@sContent 内容
--@bSys 是否系统信息(系统信息不带角色信息)
function CUtil:SendTeamTalk(nRoleID, sContent, bSys)
    local oServerMgr = GetGModule("ServerMgr")
    local nWorldServerID = oServerMgr:GetWorldServerID()
    local nTarService = oServerMgr:GetGlobalService(nWorldServerID)
    if oServerMgr:GetServerID() == nWorldServerID and nTarService == CUtil:GetServiceID() then
        local oRole = GetGModule("GRoleMgr"):GetRoleByID(nRoleID)
        GetGModule("Talk"):SendTeamMsg(oRole, sContent, bSys)
    else
        Network:RMCall("SendTeamTalkReq", nil, nWorldServerID, nTarService, 0, nRoleID, sContent, bSys)
    end
end

--发送世界频道聊天信息
function CUtil:SendWorldTalk(nRoleID, sContent, bSys)
    local oServerMgr = GetGModule("ServerMgr")
    local nWorldServerID = oServerMgr:GetWorldServerID()
    local nTarService = oServerMgr:GetGlobalService(nWorldServerID)
    if oServerMgr:GetServerID() == nWorldServerID and nTarService == CUtil:GetServiceID() then
        local oRole = GetGModule("GRoleMgr"):GetRoleByID(nRoleID)
        GetGModule("Talk"):SendWorldMsg(oRole, sContent, bSys)
    else
        Network:RMCall("SendWorldTalkReq", nil, nWorldServerID, nTarService, 0, nRoleID, sContent, bSys)
    end
end

--发送传闻频道信息
function CUtil:SendHearsayMsg(sCont)
    local oServerMgr = GetGModule("ServerMgr")
    local nWorldServerID = oServerMgr:GetWorldServerID()
    local nTarService = oServerMgr:GetGlobalService(nWorldServerID)
    if oServerMgr:GetServerID() == nWorldServerID and nTarService == CUtil:GetServiceID() then
        GetModule("Talk"):SendHearsayMsg(sCont)
    else
        Network:RMCall("SendHearsayTalkReq", nil, nWorldServerID, nTarService, 0, sCont)
    end
end

function CUtil:IsRobot(nRoleID)
    if nRoleID <= gtGDef.tConst.nRobotIDMax and nRoleID > 0 then 
        return true 
    end
    return false
end

function CUtil:SortString(sStr)
    if sStr == "" then
        return sStr
    end

    local tCharList = {}
    for k=1, #sStr do
        table.insert(tCharList, string.sub(sStr, k, k))
    end
    table.sort(tCharList, function(c1, c2) return c1<c2 end)

    local sStr = table.concat(tCharList)
    return sStr
end

--生成nNum个[nMin, nMax]之间的随机数且结果不重复(by panda)
function GF.RandDiff(nMin, nMax, nNum)
    assert(nMin <= nMax, "范围参数错误")
    assert(nNum <= nMax-nMin+1, "随机个数错误")

    local nRandRange = nMax - nMin + 1
    local nRandCount = 0
    local tSwapList = {}
    local tResultList = {} 

    for k = 1, nNum do
        if nRandRange <= 0 then 
            break
        end
        local nRand = math.random(nRandRange) + nMin - 1
        local nResultVal = nRand
        if tSwapList[nRand] then 
            nResultVal = tSwapList[nRand]
        end
        table.insert(tResultList, nResultVal)

        if nRand ~= nMin then 
            if not tSwapList[nMin] then 
                tSwapList[nRand] = nMin
            else
                tSwapList[nRand] = tSwapList[nMin]
                tSwapList[nMin] = nil
            end
        else
            tSwapList[nMin] = nil
        end

        nMin = nMin + 1
        nRandRange = nRandRange - 1
    end
    return tResultList
end

--随机数迭代
--用于生成[nMin, nMax]之间的随机数且和之前的生成结果不重复
--nMin, nMax可以为负数
--[[
示例用法
for nRandNum in CUtil:RandDiffIterator(1, 100) do 
    --do something
end
]]
function CUtil:RandDiffIterator(nMin, nMax)
    assert(nMin <= nMax, "参数错误")
    local nMaxIteration = 0xFFFFF  --1M个数据
    --超过1M个数据，基本都是逻辑存在问题了

    local nMin = nMin
    local nRandRange = nMax - nMin + 1
    local nRandCount = 0
    local tSwapList = {}
    local fnIterator = function() 
        if nRandRange <= 0 then 
            return 
        end
        if nRandCount >= nMaxIteration then 
            LuaTrace("CUtil:RandDiffIterator请检查逻辑,单次迭代大量数据!", debug.traceback())
            return 
        end

        local nRand = math.random(nRandRange) + nMin - 1
        local nResultVal = nRand
        if tSwapList[nRand] then 
            nResultVal = tSwapList[nRand]  
        end
        
        if nRand ~= nMin then 
            if not tSwapList[nMin] then 
                tSwapList[nRand] = nMin
            else
                tSwapList[nRand] = tSwapList[nMin]
                tSwapList[nMin] = nil
            end
        else
            tSwapList[nMin] = nil
        end

        nMin = nMin + 1
        nRandRange = nRandRange - 1
        nRandCount = nRandCount + 1
        return nResultVal
    end
    return fnIterator
end

--检测非法字不区分大小写(只有WGlobalServer,GlobalServer导出)--屏蔽字库占太多内存
function CUtil:HasBadWord(sCont, fnCallback)
    assert(sCont and fnCallback, "参数错误")
    if sCont == "" then
        fnCallback(false)
        return
    end
    if GlobalExport.HasWord then
        local sLowerCont = string.lower(sCont)
        local bHasBadWord = GlobalExport.HasWord(sLowerCont)
        fnCallback(bHasBadWord)
    else
        local oServerMgr = GetGModule("ServerMgr")
        local nWorldServerID = oServerMgr:GetWorldServerID()
        local nWGlobalServiceID = oServerMgr:GetGlobalService(nWorldServerID)
        Network:RMCall("HasBadWordReq", fnCallback, nWorldServerID, nWGlobalServiceID, 0, sCont)
    end
end

--过滤非法字不区分大小写(只有WGlobalServer,GlobalServer导出对应接口)--屏蔽字库占太多内存
function CUtil:FilterBadWord(sCont, fnCallback)
    assert(sCont and fnCallback, "参数错误")
    if sCont == "" then
        fnCallback(sCont)
        return
    end
    if GlobalExport.HasWord then
        local sLowerCont = string.lower(sCont)
        if GlobalExport.HasWord(sLowerCont) then
            sCont = GlobalExport.ReplaceWord(sLowerCont, "*")
        end
        fnCallback(sCont)
        return
    else
        local oServerMgr = GetGModule("ServerMgr")
        local nWorldServerID = oServerMgr:GetWorldServerID()
        local nWGlobalServiceID = oServerMgr:GetGlobalService(nWorldServerID)
        Network:RMCall("FilterBadWordReq", fnCallback, nWorldServerID, nWGlobalServiceID, 0, sCont)
    end
end

--过滤特殊字符(可以用来判断字符串中是否包含特殊字符)
function CUtil:FilterSpecChars(sCont)  
    local ss = {}  
    for k = 1, #sCont do 
        local c = string.byte(sCont,k)  
        if not c then break end  
        -- if (c>=48 and c<=57) or (c>= 65 and c<=90) or (c>=97 and c<=122) or c == 183 or c == 95 or c == 45 then
        if (c>=48 and c<=57) or (c>= 65 and c<=90) or (c>=97 and c<=122) then    
            table.insert(ss, string.char(c))  
        elseif c>=228 and c<=233 then  
            local c1 = string.byte(sCont,k+1)  
            local c2 = string.byte(sCont,k+2)  
            if c1 and c2 then  
                local a1,a2,a3,a4 = 128,191,128,191 
                if c == 228 then a1 = 184 
                elseif c == 233 then a2,a4 = 190,c1 ~= 190 and 191 or 165 
                end  
                if c1>=a1 and c1<=a2 and c2>=a3 and c2<=a4 then  
                    k = k + 2 
                    table.insert(ss, string.char(c,c1,c2))  
                end  
            end  
        end  
    end  
    return table.concat(ss)  
end
