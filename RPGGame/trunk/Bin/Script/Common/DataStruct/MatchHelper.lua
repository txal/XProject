--匹配辅助模块
local table, string, math, os, pairs, ipairs, assert = table, string, math, os, pairs, ipairs, assert

--匹配桶粒度 		
local nBucketUnit = 100

function CMatchHelper:Ctor()
	self.m_tBucketMap = {} 	--匹配桶映射{[id]={[roleid]=val,...},...}
	self.m_tBucketList = {} --桶列表
end

--更新匹配值
function CMatchHelper:UpdateValue(nID, nOldVal, nNewVal)
	self:MaintainBucket(nID, nOldVal, nNewVal)
end

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

--插入到正确位置
function CMatchHelper:InsertBucket(nBucket)
    local nPos = #self.m_tBucketList + 1
    for k = #self.m_tBucketList, 1, -1 do
        if self.m_tBucketList[k] > nBucket then
            self.m_tBucketList[k+1] = self.m_tBucketList[k]
            nPos = k
        else
            nPos = k + 1
            break
        end
    end
    self.m_tBucketList[nPos] = nBucket
end

--维护匹配桶
function CMatchHelper:MaintainBucket(nID, nOldVal, nNewVal)
	--从旧桶移除
	local nOldBucket = math.ceil(nOldVal / nBucketUnit)
	local tOldBucket = self.m_tBucketMap[nOldBucket]
	if tOldBucket then
		if tOldBucket[nID] then
			tOldBucket[nID] = nil

			--维护列表
			if not next(tOldBucket) then
				local nIndex = CBinarySearch:Search(self.m_tBucketList, _fnComp, nOldBucket)
				assert(nIndex > 0, "数据错误")
				table.remove(self.m_tBucketList, nIndex)
			end
		end
	end

	--添加到新桶
	local nBucket = math.ceil(nNewVal / nBucketUnit)
	if not self.m_tBucketMap[nBucket] then
		self.m_tBucketMap[nBucket] = {}
		self:InsertBucket(nBucket)
	end
	self.m_tBucketMap[nBucket][nID] = nNewVal
end

--匹配目标
function CMatchHelper:MatchTarget(nExceptID, nMinVal, nMaxVal)
	print("CMatchHelper:MatchTarge***", nExceptID, nMinVal, nMaxVal)
	assert(nMinVal <= nMaxVal, "匹配值范围错误")
	if #self.m_tBucketList <= 0 then
		return
	end

	local nMinBucket = math.max(self.m_tBucketList[1], math.ceil(nMinVal/nBucketUnit))
	local nMaxBucket = math.min(self.m_tBucketList[#self.m_tBucketList], math.ceil(nMaxVal/nBucketUnit))

	local nMinIndex = CBinarySearch:NearSearch(self.m_tBucketList, _fnComp, nMinBucket)
	local nMaxIndex = CBinarySearch:NearSearch(self.m_tBucketList, _fnComp, nMaxBucket)

	while nMinIndex >= 1 and nMaxIndex <= #self.m_tBucketList do
		local tIDList = {}
		for k = nMinIndex, nMaxIndex do
			local nBucket = self.m_tBucketList[k]
			local tBucket = self.m_tBucketMap[nBucket]
			assert(tBucket, "数据错误")
			for nID, nVal in pairs(tBucket) do
				if nID ~= nExceptID then
					table.insert(tIDList, nID)
				end
			end
		end
		--匹配到目标
		if #tIDList > 0 then
			return tIDList[math.random(#tIDList)]
		end
		--已经是边界
		if nMinIndex == 1 and nMaxIndex == #self.m_tBucketList then
			return
		end
		--扩大匹配范围
		nMinIndex = math.max(1, nMinIndex-1)
		nMaxIndex = math.min(#self.m_tBucketList, nMaxIndex+1)
	end
end
