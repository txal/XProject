--RBMatch 通用数据匹配功能
--这个功能，正常使用情况下，性能不如MatchHelper，如果需要返回随机结果，可以使用这个
local table, string, math, os, pairs, ipairs, assert = table, string, math, os, pairs, ipairs, assert


function CRBMatch:Ctor(fnCmp)
    assert(fnCmp, "参数错误")
    self.m_fnCmp = fnCmp
    self.m_oRBTree = CRBTree:new(fnCmp)
end

function CRBMatch:Insert(key, data)
    --TODO 优化，功能改写
    self.m_oRBTree:Insert(key, data)
end

function CRBMatch:Update(key, data)
    self.m_oRBTree:Update(key, data)
end

function CRBMatch:Remove(key)
    self.m_oRBTree:Remove(key)
end

function CRBMatch:Count()
    return self.m_oRBTree:Count()
end

--min和max是按照fnCmp定义的规则做比较的数据
--fnFilter(key, data) 返回true, 有效数据, false, 无效的需要过滤的数据
--nMatchNum 需要小于等于100
--最多返回nMatchNum个数据
--返回数据，都是在min,max之间独立随机的，这部分逻辑对性能影响比较大
function CRBMatch:Match(min, max, nMatchNum, tExceptList, fnFilter) 
    assert(min and max and nMatchNum > 0)
    assert(self.m_fnCmp(min, max) <= 0, "数据错误")
    nMatchNum = math.min(nMatchNum, 100) --避免产生大区间内大量数据的全区间数据扫描，限定最大匹配数量100

    tExceptList = tExceptList or {}
    local tExceptMap = {}
    for _, key in ipairs(tExceptList) do 
        tExceptMap[key] = true
    end

    local nTotalCount = self:Count()
    if nTotalCount <= 0 then 
        return {} 
    end

    local nBeginIndex = self.m_oRBTree:GetNotLessIndex(min)
    local nEndIndex = self.m_oRBTree:GetNotGreaterIndex(max)
    if nBeginIndex <= 0 or nEndIndex <= 0 then --超出范围，当前没有满足的元素
        return 
    end
    -- nEndIndex = math.min(nEndIndex, nTotalCount)
    assert(nBeginIndex <= nEndIndex)
    local nRandRange =nEndIndex - nBeginIndex + 1
    local nSelectNum = math.min(nMatchNum, nRandRange)
    local nMaxMatchNum = math.min(nMatchNum + (#tExceptList), nRandRange)
    if nMaxMatchNum <= 0 then 
        return {} 
    end

    local tMatchResult = {}
    if not fnFilter then
        local tRandResultList, tRandResultTbl = CUtil:RandDiffNum(nBeginIndex, nEndIndex, nMaxMatchNum) 
        --nMatchNum前面已判定大于0
        local nFindMode = (nMaxMatchNum <= 20 or (nRandRange / nMaxMatchNum) > math.log(nRandRange, 2)) and 1 or 2 
        if 1 == nFindMode then 
            for k, nMatchIndex in ipairs(tRandResultList) do 
                local key = self.m_oRBTree:GetByIndex(nMatchIndex)
                if not tExceptMap[key] then 
                    table.insert(tMatchResult, key)
                    if #tMatchResult >= nSelectNum then 
                        break
                    end
                end
            end
        elseif 2 == nFindMode then 
            local tTempList = {}
            local fnSelect = function(nIndex, key, data) 
                if tRandResultTbl[nIndex] and not tExceptMap[key] then 
                    table.insert(tTempList, key)
                end
            end
            self.m_oRBTree:Traverse(nBeginIndex, nEndIndex, fnSelect)
            if #tTempList > nSelectNum then 
                local nRemoveNum = #tTempList - nSelectNum
                if nSelectNum > nRemoveNum then 
                    local tRemoveList, tRemoveMap = CUtil:RandDiffNum(1, #tTempList, nRemoveNum)
                    for nIndex, key in ipairs(tTempList) do 
                        if not tRemoveMap[nIndex] then 
                            table.insert(tMatchResult, key)
                        end
                    end
                else
                    local tSelectList, tSelectMap = CUtil:RandDiffNum(1, #tTempList, nSelectNum)
                    for nIndex, key in ipairs(tTempList) do 
                        if tSelectMap[nIndex] then 
                            table.insert(tMatchResult, key)
                        end
                    end
                end
            else
                tMatchResult = tTempList
            end
        else
            assert(false)
        end
    else
        local nFindMode = (nSelectNum <= 20 or (nRandRange / nSelectNum) > math.log(nRandRange, 2)) and 1 or 2 
        if 1 == nFindMode then --尽量避免去扫描整个区间
            for nRandIndex in CUtil:RandDiffIterator(nBeginIndex, nEndIndex) do 
                local key, data = self.m_oRBTree:GetByIndex(nMatchIndex)
                if not tExceptMap[key] and fnFilter(key, data) then 
                    table.insert(tMatchResult, key)
                    if #tMatchResult >= nSelectNum then 
                        break
                    end
                end
            end
        elseif 2 == nFindMode then 
            local tTempList = {}
            local fnSelect = function(nIndex, key, data) 
                if not tExceptMap[key] and fnFilter(key, data) then 
                    table.insert(tTempList, key)
                end
            end
            self.m_oRBTree:Traverse(nBeginIndex, nEndIndex, fnSelect)
            if #tTempList > nSelectNum then 
                local nRemoveNum = #tTempList - nSelectNum
                if nSelectNum > nRemoveNum then 
                    local tRemoveList, tRemoveMap = CUtil:RandDiffNum(1, #tTempList, nRemoveNum)
                    for nIndex, key in ipairs(tTempList) do 
                        if not tRemoveMap[nIndex] then 
                            table.insert(tMatchResult, key)
                        end
                    end
                else
                    local tSelectList, tSelectMap = CUtil:RandDiffNum(1, #tTempList, nSelectNum)
                    for nIndex, key in ipairs(tTempList) do 
                        if tSelectMap[nIndex] then 
                            table.insert(tMatchResult, key)
                        end
                    end
                end
            else
                tMatchResult = tTempList
            end
        else
            assert(false)
        end
    end
    return tMatchResult
end

function _TestRBMatch() 
	local fnCmp = function(tDataL, tDataR)
		if tDataL < tDataR then 
			return -1
		elseif tDataL >  tDataR then 
			return 1
		else
			return 0
		end
    end

    local nMatchPoolNum = 100000
    local nValRange = 1000
	local oMatcher = CRBMatch:new(fnCmp)
	print(">>>>>>>>> RBMatch <<<<<<<<<")
    print(string.format("nMatchPoolNum(%d)",  nMatchPoolNum))
    
	local nBeginTime = os.clock()
	for k = 1, nMatchPoolNum do 
		oMatcher:Update(k, math.random(nValRange))
	end
	local nEndTime = os.clock()
	print(string.format("插入(%d)个数据, 耗时(%d)ms", nMatchPoolNum, math.ceil((nEndTime - nBeginTime)*1000)))

	local nMatchNum = 10000
	local nMatchBegin = os.clock()
	assert(nMatchPoolNum > 200)
	for k = 1, nMatchNum do 
		local nMatchMin = math.random(nMatchPoolNum // 2)
		local nMatchMax = nMatchMin + math.random(100, nMatchPoolNum // 2)
		local tMatchResult = oMatcher:Match(nMatchMin, nMatchMax, 20)
	end
	local nMatchEnd = os.clock()
	print(string.format("匹配(%d)个数据, 耗时(%d)ms", nMatchNum, math.ceil((nMatchEnd - nMatchBegin)*1000)))


	local nUpdateNum = 10000
	local nUpdateBegin = os.clock()
	for k = 1, nUpdateNum do 
		oMatcher:Update(k, math.random(nValRange))
	end
	local nUpdateEnd = os.clock()
	print(string.format("Update(%d)个数据, 耗时(%d)ms", nUpdateNum, math.ceil((nUpdateEnd - nUpdateBegin)*1000)))

	local nRemoveNum = 10000
	local nRemoveBegin = os.clock()
	for k = 1, nRemoveNum do 
		oMatcher:Remove(k)
	end
	local nRemoveEnd = os.clock()
	print(string.format("删除(%d)个数据, 耗时(%d)ms", nRemoveNum, math.ceil((nRemoveEnd - nRemoveBegin)*1000)))
	print(">>>>>>>>>>>  END  <<<<<<<<<<<<")
end

