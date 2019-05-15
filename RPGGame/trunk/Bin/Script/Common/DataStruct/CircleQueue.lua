--模拟循环队列
local table, string, math, os, pairs, ipairs, assert = table, string, math, os, pairs, ipairs, assert


function CCircleQueue:Ctor(nMaxCount, bDeepCopy)
	self.m_nHead = 1
	self.m_nTail = 1   --指向的下一个 空 元素索引
	self.m_nCount = 0
	self.m_nMaxCount = nMaxCount or 0x7fffffff --可以近似当做一个普通队列用，直到内存耗尽
	self.m_tDataMap = {} --{index:tData, ...}
	self.m_bDeepCopy = bDeepCopy and true or false
end


function CCircleQueue:Push(tData) --返回插入的数据索引
	if self.m_nCount >= self.m_nMaxCount then
		--assert(false, "队列已满")
		return
	end
	local tRefData = tData
	if self.m_bDeepCopy then
		tRefData = table.DeepCopy(tData)
	end
	local nIndex  = self.m_nTail
	self.m_nTail = (self.m_nTail < self.m_nMaxCount and (self.m_nTail + 1) or 1)
	self.m_tDataMap[nIndex] = tRefData
	self.m_nCount = self.m_nCount + 1
	return nIndex
end

function CCircleQueue:Pop()
	if self.m_nCount <= 0 then
		return
	end
	local tData = self.m_tDataMap[self.m_nHead]
	self.m_tDataMap[self.m_nHead] = nil
	self.m_nHead = (self.m_nHead < self.m_nMaxCount and (self.m_nHead + 1) or 1)
	self.m_nCount = self.m_nCount - 1
	return tData
end

function CCircleQueue:Head()
	if self.m_nCount <= 0 then
		return
	end
	return self.m_tDataMap[self.m_nHead]
end

function CCircleQueue:Count() return self.m_nCount end
function CCircleQueue:MaxCount() return self.m_nMaxCount end
function CCircleQueue:IsFull()	return self.m_nCount >= self.m_nMaxCount end
function CCircleQueue:IsEmpty() return self.m_nCount <= 0 end

function CCircleQueue:GetByIndex(nIndex)
	assert(nIndex > 0 and nIndex <= self.m_nMaxCount, "参数错误")
	if self.m_nCount <= 0 then
		return
	end
	if self.m_nTail > self.m_nHead then
		if nIndex < self.m_nHead or nIndex >= self.m_nTail then --错误的索引，元素不存在
			return
		end
	else -- self.m_nTail <= self.m_nHead
		if nIndex >= self.m_nTail and nIndex < self.m_nHead then --错误的索引，元素不存在
			return
		end
	end
	return self.m_tDataMap[nIndex]
end

function CCircleQueue:Clean()
	self.m_nHead = 1
	self.m_nTail = 1 
	self.m_nCount = 0
	self.m_tDataMap = {} --{index:tData, ...}
end


------------------------------------------------------
function CUniqCircleQueue:Ctor(nMaxCount, bDeepCopy)
	CCircleQueue.Ctor(self, nMaxCount, bDeepCopy)
	self.m_tKeyMap = {}  --{key:index, ...}  --建2个map，方便互相索引，快速查找
	self.m_tIndexMap = {}  --{index:key, ...}
end

function CUniqCircleQueue:Push(nKey, tData) --返回插入的数据索引，请注意，这个不一定为尾元素索引
	assert(nKey and tData, "参数错误")
	if self.m_nCount >= self.m_nMaxCount then
		--assert(false, "队列已满")
		return
	end
	local tRefData = tData
	if self.m_bDeepCopy then
		tRefData = table.DeepCopy(tData)
	end
	assert(tRefData, "数据错误")

	local nOldIndex = self.m_tKeyMap[nKey]
	if nOldIndex then --存在旧的，则只做旧数据更新
		if self:GetByIndex(nOldIndex) then
			self.m_tDataMap[nOldIndex] = tRefData
		else
			assert(false, "数据错误")
		end
		return nOldIndex
	end

	local nIndex  = self.m_nTail
	self.m_tDataMap[nIndex] = tRefData
	self.m_tKeyMap[nKey] = nIndex
	self.m_tIndexMap[nIndex] = nKey

	self.m_nTail = (self.m_nTail < self.m_nMaxCount and (self.m_nTail + 1) or 1)
	self.m_nCount = self.m_nCount + 1
	return nIndex
end

function CUniqCircleQueue:Pop()
	if self.m_nCount <= 0 then
		return
	end
	local tData = self.m_tDataMap[self.m_nHead]
	local nKey = self.m_tIndexMap[self.m_nHead]
	self.m_tDataMap[self.m_nHead] = nil
	self.m_tKeyMap[nKey] = nil
	self.m_tIndexMap[self.m_nHead] = nil

	self.m_nHead = (self.m_nHead < self.m_nMaxCount and (self.m_nHead + 1) or 1)
	self.m_nCount = self.m_nCount - 1
	return tData, nKey
end

function CUniqCircleQueue:GetByKey(nKey)
	local nIndex = self.m_tKeyMap[nKey]
	if not nIndex then
		return
	end
	return self:GetByIndex(nIndex)
end

--获取在队列中的排名
function CUniqCircleQueue:GetRank(nKey)
	local nIndex = self.m_tKeyMap[nKey]
	if not nIndex then
		return
	end
	if nIndex >= self.m_nHead then 
		return nIndex - self.m_nHead + 1
	else
		return nIndex + self.m_nMaxCount - self.m_nHead + 1
	end
end

function CUniqCircleQueue:Clean()
	CCircleQueue.Clean(self)
	self.m_tKeyMap = {}
	self.m_tIndexMap = {}
end


