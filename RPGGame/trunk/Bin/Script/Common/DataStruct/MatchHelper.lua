--匹配辅助模块
local table, string, math, os, pairs, ipairs, assert = table, string, math, os, pairs, ipairs, assert

--比较函数
local function _fnComp(nBucket1, nBucket2)
	if nBucket1 > nBucket2 then
		return 1
	end
	if nBucket1 < nBucket2 then
		return -1
	end
	return 0
end

--匹配桶粒度 		
function CMatchHelper:Ctor(nBucketUnit)
	self.m_nBucketUnit = nBucketUnit
	self.m_tBucketMap = {} 	--匹配桶映射{[id]={[roleid]=val,...},...}
	self.m_tBucketList = {} --桶列表
	self.m_tValueMap = {}
end

--更新匹配值
function CMatchHelper:UpdateValue(nID, nNewVal)
	self:_MaintainBucket(nID, nNewVal)
end

--匹配目标
--@tExceptID 排除ID表
--@nMinVal nMaxVal 匹配范围
--@nPreferVal 优先匹配值(已废弃)
--@nMinNum 最少匹配数量，如果没匹配到足够数量，自动扩大匹配范围，0不自动扩大匹配范围
--@nMaxNum 最大匹配数量，如果多个结果满足，达到最大即停止匹配，0匹配所有满足匹配范围的数据
--@fnFilter 过滤函数
function CMatchHelper:MatchTarget(tExceptID, nMinVal, nMaxVal, nPreferVal, nMinNum, nMaxNum, fnFilter)
	-- print("CMatchHelper:MatchTarget***", tExceptID, nMinVal, nMaxVal)
	local tExceptIDMap = {}
	for _, nID in pairs(tExceptID) do
		tExceptIDMap[nID] = 1
	end

	nMinVal = math.max(0, nMinVal)
	nMaxVal = math.max(0, nMaxVal)
	assert(nMinVal <= nMaxVal, "匹配值范围错误")

	--为了性能考虑,匹配最大目标数量限制在100以内
	nMinNum = math.min(nMinNum, 100)
	nMaxNum = math.min(nMaxNum, 100)
	assert(nMinNum >= 0 and nMinNum <= nMaxNum,  "匹配数量范围错误")

	local nBucketCount = #self.m_tBucketList
	if nBucketCount <= 0 then
		return {}
	end

	local nMinBucket = math.max(self.m_tBucketList[1], math.ceil(nMinVal/self.m_nBucketUnit))
	local nMaxBucket = math.min(self.m_tBucketList[#self.m_tBucketList], math.ceil(nMaxVal/self.m_nBucketUnit))

	--NearSearch返回的结果需要做一下调整，可能小于当前查找值，也可能大于当前查找值
	--但是我们的匹配，需要的是在最小值和最大值中间的值，可能BucketList上相邻2个Bucket的值相差非常大
	local nMinIndex = CBinarySearch:NearSearch(self.m_tBucketList, _fnComp, nMinBucket)
	local nIndexBucket = self.m_tBucketList[nMinIndex]
	if nIndexBucket > nMinBucket then
		nMinIndex = math.max(1, nMinIndex-1)
	end

	local nMaxIndex = CBinarySearch:NearSearch(self.m_tBucketList, _fnComp, nMaxBucket)
	local nIndexBucket = self.m_tBucketList[nMaxIndex]
	if nIndexBucket < nMaxBucket then
		nMaxIndex = math.min(nBucketCount, nMaxIndex+1)
	end

	local tIDList = {} 	--结果表
	local tIndexMap = {} --已经处理过的
	while nMinIndex >= 1 and nMaxIndex <= nBucketCount do
		for k = nMinIndex, nMaxIndex do
			if not tIndexMap[k] then
				tIndexMap[k] = 1

				local nBucket = self.m_tBucketList[k]
				local tBucket = self.m_tBucketMap[nBucket]
				assert(tBucket, "桶数据错误")
				for nID, nVal in pairs(tBucket) do
					if not tExceptIDMap[nID] and (not fnFilter or fnFilter(nID)) then
						table.insert(tIDList, nID)
						if nMaxNum > 0 and #tIDList >= nMaxNum then --设置了最大数量且满足，则直接返回
							return tIDList
						end
					end
				end

			end
		end
		--匹配到最少目标数量返回
		if #tIDList >= nMinNum then
			break
		end
		--已经是边界
		if nMinIndex == 1 and nMaxIndex == nBucketCount then
			break
		end
		--扩大匹配范围
		nMinIndex = math.max(1, nMinIndex-1)
		nMaxIndex = math.min(nBucketCount, nMaxIndex+1)
	end
	return tIDList
end

--插入到正确位置
function CMatchHelper:_InsertBucket(nBucket)
    local nPos = #self.m_tBucketList + 1
    for k = #self.m_tBucketList, 1, -1 do
        if self.m_tBucketList[k] > nBucket then
            self.m_tBucketList[k+1] = self.m_tBucketList[k]
            nPos = k
        else
            break
        end
    end
    self.m_tBucketList[nPos] = nBucket
end

--维护匹配桶
function CMatchHelper:_MaintainBucket(nID, nNewVal)
	local nOldVal = self.m_tValueMap[nID] or 0
	self.m_tValueMap[nID] = nNewVal

	--从旧桶移除
	local nOldBucket = math.ceil(nOldVal/self.m_nBucketUnit)
	local tOldBucket = self.m_tBucketMap[nOldBucket]
	if tOldBucket and tOldBucket[nID] then
		tOldBucket[nID] = nil

		--维护列表
		if not next(tOldBucket) then
			local nIndex = CBinarySearch:Search(self.m_tBucketList, _fnComp, nOldBucket)
			if nIndex <= 0 then
				assert(false, "数据错误")
			else
				table.remove(self.m_tBucketList, nIndex)
				self.m_tBucketMap[nOldBucket] = nil
			end
		end
	end

	--添加到新桶
	local nBucket = math.ceil(nNewVal/self.m_nBucketUnit)
	if not self.m_tBucketMap[nBucket] then
		self.m_tBucketMap[nBucket] = {}
		self:_InsertBucket(nBucket)
	end
	self.m_tBucketMap[nBucket][nID] = nNewVal
end

--移除匹配对象
function CMatchHelper:Remove(nID)
	local nOldVal = self.m_tValueMap[nID] or 0
	self.m_tValueMap[nID] = nil
	--从旧桶移除
	local nOldBucket = math.ceil(nOldVal/self.m_nBucketUnit)
	local tOldBucket = self.m_tBucketMap[nOldBucket]
	if tOldBucket and tOldBucket[nID] then
		tOldBucket[nID] = nil
		if not next(tOldBucket) then
			local nIndex = CBinarySearch:Search(self.m_tBucketList, _fnComp, nOldBucket)
			if nIndex <= 0 then
				assert(false, "数据错误")
			else
				table.remove(self.m_tBucketList, nIndex)
				self.m_tBucketMap[nOldBucket] = nil
			end
		end
	end
end

function CMatchHelper:IsEmpty()
	if not next(self.m_tValueMap) then 
		return true 
	end
	return false 
end


function _TestMatchHelper() 
	local nUnitVal = math.random(10)
	local nMatchPoolNum = 100000
	local nValRange = 1000
	local oMatcher = CMatchHelper:new(nUnitVal)
	print(">>>>>>>>> MatchHelper <<<<<<<<<")
	print(string.format("nUnitVal(%d), nMatchPoolNum(%d)", nUnitVal, nMatchPoolNum))
	local nBeginTime = os.clock()
	for k = 1, nMatchPoolNum do 
		oMatcher:UpdateValue(k, math.random(nValRange)) --UnitVal和数据分布区间对插入删除性能影响很大
	end
	local nEndTime = os.clock()
	print(string.format("插入(%d)个数据, 耗时(%d)ms", nMatchPoolNum, math.ceil((nEndTime - nBeginTime)*1000)))

	local nMatchNum = 10000
	local nMatchBegin = os.clock()
	assert(nMatchPoolNum > 200)
	for k = 1, nMatchNum do 
		local nMatchMin = math.random(nMatchPoolNum // 2)
		local nMatchMax = nMatchMin + math.random(100, nMatchPoolNum // 2)
		oMatcher:MatchTarget({}, nMatchMin, nMatchMax, (nMatchMin + nMatchMax) // 2, 20, 20, nil)
	end
	local nMatchEnd = os.clock()
	print(string.format("匹配(%d)个数据, 耗时(%d)ms", nMatchNum, math.ceil((nMatchEnd - nMatchBegin)*1000)))


	local nUpdateNum = 10000
	local nUpdateBegin = os.clock()
	for k = 1, nUpdateNum do 
		oMatcher:UpdateValue(k, math.random(nValRange))
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
