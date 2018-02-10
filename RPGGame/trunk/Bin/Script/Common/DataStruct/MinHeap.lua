--最小堆(10W级别)
local table, string, math, os, pairs, ipairs, assert = table, string, math, os, pairs, ipairs, assert

function CMinHeap:Ctor(fnCmp)
	self.m_fnCmp = fnCmp
	self.m_tHeap = {}
	self.m_nCount = 0
end

function CMinHeap:GetCount()
	return self.m_nCount
end

function CMinHeap:FilterUp(nIndex)
	if nIndex < 1 or nIndex > self.m_nCount then
		return
	end
	local i = nIndex
	local j = math.floor(i/2)
	local tmp = self.m_tHeap[i]
	while i > 1 do
		if self.m_fnCmp(self.m_tHeap[j], tmp) <= 0 then
			break
		end
		self.m_tHeap[i] = self.m_tHeap[j]
		i = j
		j = math.floor(j/2)
	end
	self.m_tHeap[i] = tmp
end

function CMinHeap:FilterDown(nIndex)
	if nIndex < 1 or nIndex > self.m_nCount then
		return
	end
	local i = nIndex
	local j = 2 * i
	local tmp = self.m_tHeap[i]
	while j <= self.m_nCount do
		if j < self.m_nCount and self.m_fnCmp(self.m_tHeap[j], self.m_tHeap[j+1]) > 0 then
			j = j + 1
		end
		if self.m_fnCmp(self.m_tHeap[j], tmp) >= 0 then
			break
		end
		self.m_tHeap[i] = self.m_tHeap[j];
		i = j
		j = 2 * j
	end
	self.m_tHeap[i] = tmp
end

function CMinHeap:Push(value)
	self.m_nCount = self.m_nCount + 1
    self.m_tHeap[self.m_nCount] = value
    self:FilterUp(self.m_nCount)
end

function CMinHeap:Min()
	if self.m_nCount <= 0 then
		return
	end
	return self.m_tHeap[1]
end

--假定通常只移除最小的
function CMinHeap:RemoveByValue(value)
	local nIndex = 0
	for i = 1, self.m_nCount do
		if self.m_tHeap[i] == value then
			nIndex = i
			break
		end
	end
	return self:RemoveByIndex(nIndex)
end

function CMinHeap:RemoveByIndex(nIndex)
    if nIndex < 1 or nIndex > self.m_nCount then
        return false
    end
    self.m_tHeap[nIndex] = self.m_tHeap[self.m_nCount]
    table.remove(self.m_tHeap)
    self.m_nCount = self.m_nCount - 1
    self:FilterUp(nIndex)
    self:FilterDown(nIndex)
	return true
end

function CMinHeap:BuildHeap()
    for i = math.floor(self.m_Count/2), 1, -1 do
        self:FilterDown(i)
    end
end
