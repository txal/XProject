--全局函数
local table, string, math, os, pairs, ipairs, assert = table, string, math, os, pairs, ipairs, assert
GF = GF or {}

--名字库随机名字
function GF.GenNameByPool()
	local nIndex = math.random(1, #ctRoleNamePoolConf)
	local tPoolConf = ctRoleNamePoolConf[nIndex]
	local nRndXing = math.random(1, #tPoolConf.tXing)
	local nRndMing = math.random(1, #tPoolConf.tMing)
	local sXing = tPoolConf.tXing[nRndXing][1]
	local sMing = tPoolConf.tMing[nRndMing][1]
	return (sXing..sMing)
end

--检测长度
function GF.CheckNameLen(sName, nMaxLen)
	assert(string.len(sName) <= nMaxLen, "长度超出范围:"..nMaxLen)
end

--检测非法字不区分大小写(只有WGlobalServer,LoginServer导出)--屏蔽字库占太多内存
function GF.HasBadWord(sCont, fnCallback)
    assert(sCont, "参数错误")
    if sCont == "" then
        return false
    end
    if GlobalExport.HasWord then
    	local sLowerCont = string.lower(sCont)
        return GlobalExport.HasWord(sLowerCont)
    else
        assert(fnCallback, "缺少回调函数")
        goRemoteCall:CallWait("HasBadWordReq", fnCallback, gnWorldServerID, 110, 0, sCont)
    end
end

--过滤非法字不区分大小写(只有WGlobalServer,LoginServer导出对应接口)--屏蔽字库占太多内存
function GF.FilterBadWord(sCont, fnCallback)
    assert(sCont, "参数错误")
    if sCont == "" then
        return sCont
    end
    if GlobalExport.HasWord then
    	local sLowerCont = string.lower(sCont)
        if GlobalExport.HasWord(sLowerCont) then
        	sCont = GlobalExport.ReplaceWord(sLowerCont, "*")
        end
        return sCont
    else
        assert(fnCallback, "缺少回调函数")
        goRemoteCall:CallWait("FilterBadWordReq", fnCallback, gnWorldServerID, 110, 0, sCont)
    end
end

--过滤特殊字符(可以用来判断字符串中是否包含特殊字符)
function GF.FilterSpecChars(sCont)  
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

--通过副本唯一ID取副本ID
--@nDupMixID: 副本唯一ID, 城镇:配置ID 副本:autoid<<16|配置ID
function GF.GetDupID(nDupMixID)
    assert(nDupMixID, "参数错误")
    return (nDupMixID & 0xFFFF)
end

--通过会话ID取网关服务ID
--@nSession: 会话ID
function GF.GetGateServiceBySession(nSession)
    assert(nSession, "参数错误")
    return (nSession >> gnServiceShift)
end

--取当前进程服务ID
function GF.GetServiceID()
    if GlobalExport.GetServiceID then
        return GlobalExport.GetServiceID()
    end
    return 0
end

--取系统运行时间(毫秒)
function GF.GetClockMSTime()
    return NetworkExport.ClockMSTime()
end

--取标准时间(毫秒)
function GF.GetUnixMSTime()
    return NetworkExport.UnixMSTime()
end

--通过逻辑服ID取服务器ID
function GF.GetServerByLogic(nLogic)
    local nServerID = nLogic>=100 and gnWorldServerID or gnServerID
    return nServerID
end

--随机坐标
--@nPosX, nPosY: 原点
--@nRad: 半径
function GF.RandPos(nPosX, nPosY, nRad)
    local nRndX = math.max(0, math.random(nPosX-nRad, nPosX+nRad))
    local nRndY = math.max(0, math.random(nPosY-nRad, nPosY+nRad))
    return nRndX, nRndY
end

--取两点的距离
function GF.Distance(nPosX1, nPosY1, nPosX2, nPosY2)
    local nDistX = nPosX1 - nPosX2
    local nDistY = nPosY1 - nPosY2
    local nDist = math.floor(math.sqrt(nDistX*nDistX + nDistY*nDistY))
    return nDist
end

--是否障碍点
function GF.IsBlockUnit(nDupMixID, nPosX, nPosY)
    local nDupID = GF.GetDupID(nDupMixID)
    local tDupConf = ctDupConf[nDupID]
    if not tDupConf then
        return 
    end
    return GlobalExport.IsBlockUnit(tDupConf.nMapID, nPosX, nPosY)
end

--生成弱表
--@sFlag k键; v值; kv键值
function GF.WeakTable(sFlag)
    local tTable = {}
    setmetatable(tTable, {__mode=sFlag})
    return tTable
end

--发送邮件
--@nTarServer 玩家所属服务器(oRole:GetServer())
--@sTitle 标题
--@sContent 内容
--@tItemList 物品列表{{type,id,num,bind,propext}, Prop:SaveData(), ...}
--@nTarRoleID 目标玩家ID
function GF.SendMail(nTarServer, sTitle, sContent, tItemList, nTarRoleID)
    assert(nTarServer and sTitle and sContent and tItemList and nTarRoleID, "参数错误")
    local nTarService = goServerMgr:GetGlobalService(nTarServer, 20)
    if gnServerID == nTarServer and nTarService == GF.GetServiceID() then
        goMailMgr:SendMail(sTitle, sContent, tItemList, nTarRoleID)
    else
       goRemoteCall:Call("SendMailReq", nTarServer, nTarService, 0, sTitle, sContent, tItemList, nTarRoleID)
    end
end

--发送滚动公告(跑马灯)
--@nTarServer 玩家所属服务器(oRole:GetServer())，如果nTarServer为0，则为全区广播
--@sContent 内容
function GF.SendNotice(nTarServer, sContent)
    assert(nTarServer and sContent, "参数错误")
    if nTarServer > 0 then 
        local nTarService = goServerMgr:GetGlobalService(nTarServer, 20)
        if gnServerID == nTarServer and nTarService == GF.GetServiceID() then
            goNoticeMgr:SendNoticeReq(sContent)
        else
            goRemoteCall:Call("SendNoticeReq", nTarServer, nTarService, 0, sContent)
        end
    else
        local nTarService = goServerMgr:GetGlobalService(gnWorldServerID, 111)
        if GF.GetServiceID() == nTarService and gnServerID == gnWorldServerID then 
            Srv2Srv.SendNoticeAllReq(nTarServer, nTarService, 0, sContent)
        else
            goRemoteCall:Call("SendNoticeAllReq", gnWorldServerID, nTarService, 0, sContent)
        end
    end
end

--发送系统频道聊天
--@sTitle  标题(系统,传闻,...)
--@sContent 内容
function GF.SendSystemTalk(sTitle, sContent)
    local nGlobalService = goServerMgr:GetGlobalService(gnWorldServerID, 110)
    if gnServerID == gnWorldServerID and nGlobalService == GF.GetServiceID() then
        goTalk:SendSystemMsg(sContent, sTitle)
    else
        goRemoteCall:Call("SendSystemTalkReq", gnWorldServerID, nGlobalService, 0, sTitle, sContent)
    end
end

--发送队伍频道聊天
--@nRoleID 角色ID
--@sContent 内容
--@bSys 是否系统信息(系统信息不带角色信息)
function GF.SendTeamTalk(nRoleID, sContent, bSys)
    local nGlobalService = goServerMgr:GetGlobalService(gnWorldServerID, 110)
    if gnServerID == gnWorldServerID and nGlobalService == GF.GetServiceID() then
        local oRole = goGPlayerMgr:GetRoleByID(nRoleID)
        goTalk:SendTeamMsg(oRole, sContent, bSys)
    else
        goRemoteCall:Call("SendTeamTalkReq", gnWorldServerID, nGlobalService, 0, nRoleID, sContent, bSys)
    end
end

--发送世界频道聊天信息
function GF.SendWorldTalk(nRoleID, sContent, bSys)
    local nGlobalService = goServerMgr:GetGlobalService(gnWorldServerID, 110)
    if gnServerID == gnWorldServerID and nGlobalService == GF.GetServiceID() then
        local oRole = goGPlayerMgr:GetRoleByID(nRoleID)
        goTalk:SendWorldMsg(oRole, sContent, bSys)
    else
        goRemoteCall:Call("SendWorldTalkReq", gnWorldServerID, nGlobalService, 0, nRoleID, sContent, bSys)
    end
end

--发送个人获得物品系统频道提示信息
--@bNotSync true:不同步
local nCacheIndex = 0
local tItemTalkCache = {}
local function _GenItemTalk(sKey, tParams)
    local tConf = ctTalkConf[sKey]
    local tHead = {sName="个人"}
    local sCont = string.format(tConf.sContent, table.unpack(tParams))
    local tTalk = {
        tHead = tHead,
        nChannel = 1,
        sCont = sCont,
        nTime = os.time(),
    }
    return tTalk
end
function GF.SendItemTalk(oRole, sKey, tParams, bNotSync)
    local tConf = ctTalkConf[sKey]
    if not tConf then
        return
    end

    if bNotSync then
        nCacheIndex = nCacheIndex + 1
        table.insert(tItemTalkCache, {sKey, tParams, nCacheIndex})
    else
        local tTalk = _GenItemTalk(sKey, tParams)
        oRole:SendMsg("TalkRet", {tList={tTalk}})
    end
end

--获得物品缓存
function GF.SyncItemTalkCachedMsg(oRole)
    if #tItemTalkCache <= 0 then
        return
    end
    local tTmpList = {}
    local tTmpMap = {}
    for _, tSync in ipairs(tItemTalkCache) do
        local sKey = tSync[1]
        if sKey == "getitem" or sKey == "subitem" then
            local nItemID = tSync[2][1]
            local nItemNum = tSync[2][2]
            local nCacheIndex = tSync[3]
            tTmpMap[sKey] = tTmpMap[sKey] or {}
            tTmpMap[sKey][nItemID] = tTmpMap[sKey][nItemID] or {0, nCacheIndex}
            tTmpMap[sKey][nItemID][1] = tTmpMap[sKey][nItemID][1] + nItemNum
            tTmpMap[sKey][nItemID][2] = math.min(tTmpMap[sKey][nItemID][2], nCacheIndex)

        else
            local tTalk = _GenItemTalk(sKey, tSync[2])
            table.insert(tTmpList, {tTalk, tSync[3]})
        end
    end
    for sKey, tItem in pairs(tTmpMap) do
        for nItemID, tItemInfo in pairs(tItem) do
            local tTalk = _GenItemTalk(sKey, {nItemID, tItemInfo[1]})
            table.insert(tTmpList, {tTalk, tItemInfo[2]})
        end
    end
    table.sort(tTmpList, function(t1, t2) return t1[2] < t2[2] end)

    local tList = {}
    for _, tItem in ipairs(tTmpList) do
        table.insert(tList, tItem[1])
    end
    oRole:SendMsg("TalkRet", {tList=tList})

    nCacheIndex = 0
    tItemTalkCache = {}
end

--发送传闻频道信息
function GF.SendHearsayMsg(sCont)
    local nGlobalService = goServerMgr:GetGlobalService(gnWorldServerID, 110)
    if gnServerID == gnWorldServerID and nGlobalService == GF.GetServiceID() then
        goTalk:SendHearsayMsg(sCont)
    else
        goRemoteCall:Call("SendHearsayTalkReq", gnWorldServerID, nGlobalService, 0, sCont)
    end
end

--根据品质格式化道具颜色
function GF.FormatPropQualityString(nQuality, sSrc)
    local sField = gtQualityStringColor[nQuality]
    if not sField then 
        return sSrc
    end
    local tConf = ctTalkConf[sField]
    if not tConf then 
        return sSrc
    end
    return string.format(tConf.sContent, sSrc)
end

function GF.IsRobot(nRoleID)
    if nRoleID <= gnRobotIDMax and nRoleID > 0 then 
        return true 
    end
    return false
end

function GF.SortString(sStr)
    if sStr == "" then
        return sStr
    end

    local tCharList = {}
    for k=1, #sStr do
        table.insert(tCharList, string.sub(sStr, k, k))
    end
    table.sort(tCharList, function(c1, c2) return c1<c2 end)

    sStr = ""
    for _, sChar in ipairs(tCharList) do
        sStr = sStr .. sChar
    end
    return sStr
end

-- [nMin, nMax]区间，随机nNum个不同数值
-- nMin和nMax可以为负数
-- 返回值1  {[1]=nVal1, [2]=nVal2, ...}
-- 返回值2  {nVal1:(第X次随机到), nVal2:(第X次随机到), ...}
function GF.RandDiffNum(nMin, nMax, nNum)
    assert(nMin <= nMax and nNum > 0, "参数错误")
    local nRandRange = nMax - nMin + 1
    assert(nRandRange >= nNum, "参数错误")

    local tRandResult = {}

    local tCacheList = {}
    local tSwapList = {}  --交换列表，用于缓存交换的nMin值
    for k = 1, nNum do 
        local nRand = math.random(nRandRange) + nMin - 1
        local nResultVal = nRand
        if tCacheList[nRand] then 
            nResultVal = tSwapList[nRand]  
        end
        tCacheList[nResultVal] = k
        table.insert(tRandResult, nResultVal)
        
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
        nRandRange = nRandRange - 1
        nMin = nMin + 1
    end

    return tRandResult, tCacheList
end

--随机数迭代
--用于生成[nMin, nMax]之间的随机数且和之前的生成结果不重复
--nMin, nMax可以为负数
--[[
示例用法
for nRandNum in GF.RandDiffIterator(1, 100) do 
    --do something
end
]]
function GF.RandDiffIterator(nMin, nMax)
    assert(nMin <= nMax, "参数错误")
    local nMaxIteration = 0xfffff  --1M个数据
    --因为存在缓存列表，如果单次迭代太多，会导致内存占用过大，而且还会阻塞其他服务
    --超过1M个数据，基本都是逻辑存在问题了

    local nMin = nMin
    local nRandRange = nMax - nMin + 1
    local nRandCount = 0
    local tCacheList = {} 
    local tSwapList = {}
    local fnIterator = function(tParam, nRandVal) 
        if nRandRange <= 0 then 
            return 
        end
        if nRandCount >= nMaxIteration then 
            LuaTrace("GF.RandDiffIterator请检查逻辑!!!!单次迭代大量数据!!!!")
            LuaTrace(debug.traceback())
            return 
        end

        local nRand = math.random(nRandRange) + nMin - 1
        local nResultVal = nRand
        if tCacheList[nRand] then 
            nResultVal = tSwapList[nRand]  
        end
        tCacheList[nResultVal] = true
        
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

        nRandRange = nRandRange - 1
        nMin = nMin + 1
        nRandCount = nRandCount + 1
        return nResultVal
    end
    return fnIterator, nil, nil
end

function GF.GetMaxRoleLevelByServer(nServer)
    assert(nServer > 0 and nServer ~= gnWorldServerID)
    return math.min(goServerMgr:GetServerLevel(nServer) + 8, #ctRoleLevelConf)
end

function GF.CalcAttrScore(nAttrID, nAttrVal)
	local nConvertRate = gtEquAttrConvertRate[nAttrID]
	if not nConvertRate then 
		return 0
	end
	return math.floor(nAttrVal * nConvertRate)
end

--是否是PVE活动场景
function GF.IsPVEActDup(nDupID)
    local tDupConf = ctDupConf[nDupID]
    if not tDupConf then 
        return false
    end
    if tDupConf.nBattleType == gtBattleDupType.ePVEPrepare 
    or tDupConf.nBattleType == gtBattleDupType.eJueZhanJiuXiao
    or tDupConf.nBattleType == gtBattleDupType.eHunDunShiLian
    or tDupConf.nBattleType == gtBattleDupType.eMengZhuWuShuang then 
        return true 
    end

    return false
end


--获取道具补足价格
--当前只支持道具
--tItemList {nItemType, nItemID, nCurrType} --nCurrType是需要转换的目标货币类型
--bCeil查询价格，发生货币单位转换, 是否向上取整，false则向下取整
--正常，如果是查询补足价格，都向上取整
--fnCallback(bSucc, tPriceList) --tPriceList = {{nItemType, nItemID, nCurrType, nPrice}, ...}
function GF.QueryItemPrice(nServer, tItemList, bCeil, fnCallback)
    assert(nServer > 0 and nServer < 10000, "参数错误")
    bCeil = bCeil and true or false
    local fnInnerCallback = function(bSucc, tPriceList) 
        if not bSucc then 
            print("QueryItemPrice 查询价格失败")
            tPriceList = {}
        end
        if fnCallback then 
            fnCallback(bSucc, tPriceList)
        end
    end
    if #tItemList <= 0 or #tItemList > 100 then 
        fnInnerCallback(false, {})
    end

    local nServerID = nServer
    local nServiceID = goServerMgr:GetGlobalService(nServerID, 20)

    local tQueryShopMap = {}
    local tQueryMarketMap = {}
    local tQueryPropConfMap = {}
    for _, tItem in ipairs(tItemList) do 
        local nItemID = tItem.nItemID
        assert(nItemID > 0, "参数错误")
        if tItem.nItemType == gtItemType.eProp then 
            assert(ctPropConf[nItemID], "道具配置不存在")
            if ctCommerceItem[nItemID] then 
                tQueryShopMap[nItemID] = tItem
            elseif ctBourseItem[nItemID] then 
                tQueryMarketMap[nItemID] = tItem
            else
                tQueryPropConfMap[nItemID] = nItemID
            end
        else
            --暂时只支持道具
            assert(false, string.format("物品(%d)不是道具", nItemID))
        end
    end

    local tQueryShopList = {}
    for nItemID, _ in pairs(tQueryShopMap) do 
        table.insert(tQueryShopList, nItemID)
    end
    local tQueryMarketList = {}
    for nItemID, _ in pairs(tQueryMarketMap) do 
        table.insert(tQueryMarketList, nItemID)
    end

    local fnShopCallback = function(tShopResult) 
		if not tShopResult then 
			fnInnerCallback(false)
			return 
		end
		local fnMarketCallback = function(tMarketResult) 
			if not tMarketResult then 
				fnInnerCallback(false)
				return 
            end

            local fnGetBasePrice = function(nPropID, nCurrType) 
                local tPropConf = ctPropConf[nPropID]
                assert(tPropConf, "道具不存在")
                if nCurrType == gtCurrType.eYuanBao 
                    or nCurrType == gtCurrType.eBYuanBao 
                    or nCurrType == gtCurrType.eAllYuanBao then 
                    return tPropConf.nBuyPrice
                elseif nCurrType == gtCurrType.eJinBi then 
                    return tPropConf.nGoldPrice 
                elseif nCurrType == gtCurrType.eYinBi then 
                    return tPropConf.nSilverPrice
                else
                    assert(false, "不支持的货币类型")
                end
            end

            local fnCurrencyExchange = function(nSrcType, nTarType, nNum, bCeil) 
                assert(nSrcType and nTarType and nNum and nNum >= 0, "参数错误")
                if nSrcType == nTarType then 
                    return nNum
                end
                local nSrcRatio = gtCurrYuanbaoExchangeRatio[nSrcType]
                assert(nSrcRatio and nSrcRatio > 0, "不受支持的兑换")
                local nTarRatio = gtCurrYuanbaoExchangeRatio[nTarType]
                assert(nTarRatio and nTarRatio > 0, "不受支持的兑换")

                local nRatio = nTarRatio / nSrcRatio
                if bCeil then 
                    return math.ceil(nNum * nRatio)
                else
                    return math.floor(nNum * nRatio)
                end
            end

			local tPriceList = {}  --{nItemType, nItemID, nCurrType, nPrice}
			for _, tItem in ipairs(tItemList) do 
                local nItemType = tItem.nItemType
                local nItemID = tItem.nItemID
                local nCurrType = tItem.nCurrType
                local tPriceData = {nItemType = nItemType, nItemID = nItemID, 
                    nCurrType = nCurrType}
                local nPrice
                if nItemType == gtItemType.eProp then 
                    if ctCommerceItem[nItemID] then 
                        nPrice = fnCurrencyExchange(gtCurrType.eJinBi, nCurrType, 
                            tShopResult[nItemID], bCeil)
                    elseif ctBourseItem[nItemID] then 
                        nPrice = fnCurrencyExchange(gtCurrType.eYinBi, nCurrType, 
                            tMarketResult[nItemID], bCeil)
                    elseif tQueryPropConfMap[nItemID] then 
                        nPrice = fnGetBasePrice(nItemID, nCurrType)
                    else
                        assert(false)
                    end
                end
				tPriceData.nPrice = nPrice
				table.insert(tPriceList, tPriceData)
			end
			fnInnerCallback(true, tPriceList)
		end

        if #tQueryMarketList > 0 then 
            if gnServerID == nServerID and GF.GetServiceID() == nServiceID then
                local tResult = Srv2Srv.GetMarketBasePriceTblReq(nServerID, 
                    nServiceID, 0, tQueryMarketList)
                fnMarketCallback(tResult) 
            else
                goRemoteCall:CallWait("GetMarketBasePriceTblReq", fnMarketCallback, 
                    nServerID, nServiceID, 0, tQueryMarketList)
            end
		else
			fnMarketCallback({})
		end
	end
    if #tQueryShopList > 0 then 
        if gnServerID == nServerID and GF.GetServiceID() == nServiceID then 
            local tResult = Srv2Srv.QueryCommercePriceTblReq(nServerID, 
                nServiceID, 0, tQueryShopList)
            fnShopCallback(tResult)
        else
            goRemoteCall:CallWait("QueryCommercePriceTblReq", fnShopCallback, 
                nServerID, nServiceID, 0, tQueryShopList)
        end
	else
		fnShopCallback({})
	end
end

