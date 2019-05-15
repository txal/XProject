--KeyList双向链表
--某些需要有序、但是又需要删除性能，但对在队列中的位置不敏感的使用场合
local table, string, math, os, pairs, ipairs, assert = table, string, math, os, pairs, ipairs, assert

function CKeyList:Ctor(nMaxCount, bDeepCopy)
    assert(not nMaxCount or nMaxCount > 0)
    self.m_tHead = nil        --tNode:{tPre, tNext, tData, nKey}
    self.m_tTail = nil
    self.m_nCount = 0
    self.m_nMaxCount = nMaxCount or 0x7fffffff
    self.m_tKeyMap = {}       --{key:tNode, ...}
    setmetatable(self.m_tKeyMap, {__mode = "kv"})
    self.m_bDeepCopy = bDeepCopy or false
end

function CKeyList:Count() return self.m_nCount end
function CKeyList:MaxCount() return self.m_nMaxCount end

function CKeyList:Clean()
    self.m_tHead = nil
    self.m_tTail = nil
    self.m_nCount = 0
    self.m_tKeyMap = {}
end

function CKeyList:IsEmpty() return self.m_nCount <= 0 end
function CKeyList:IsFull() return self.m_nCount >= self.m_nMaxCount end
function CKeyList:Head() return self.m_tHead end
function CKeyList:GetHeadData() return self:Head().tData end
function CKeyList:Tail() return self.m_tTail end
function CKeyList:IsTail(nKey) 
    if not self.m_tTail or not nKey then
        return false
    end
    if self.m_tTail.nKey == nKey then 
        return true 
    end
    return false
end
function CKeyList:IsExist(nKey) 
    if self.m_tKeyMap[nKey] then 
        return true 
    end
    return false
end
--返回的节点
function CKeyList:Find(nKey)
    assert(nKey)
    return self.m_tKeyMap[nKey]
end

function CKeyList:GetData(nKey)
    assert(nKey)
    local tNode = self.m_tKeyMap[nKey]
    if not tNode then 
        return 
    end
    return tNode.tData
end

--会返回原node
function CKeyList:Remove(nKey)
    assert(nKey)
    local tNode = self.m_tKeyMap[nKey]
    if not tNode then 
        return 
    end
    self.m_tKeyMap[nKey] = nil
    if tNode.tPre then --非头结点
        tNode.tPre.tNext = tNode.tNext
    else
        self.m_tHead = tNode.tNext
    end
    if tNode.tNext then --非尾节点 
        tNode.tNext.tPre = tNode.tPre
    else
        self.m_tTail = tNode.tPre
    end
    self.m_nCount = self.m_nCount - 1
    return tNode
end

--弹出首节点并返回
function CKeyList:Pop()
    if not self.m_tHead then 
        return 
    end
    local tNode = self.m_tHead
    self.m_tHead = tNode.tNext
    if tNode.tNext then 
        tNode.tNext.tPre = nil
    else --尾节点
        self.m_tTail = nil
    end
    self.m_tKeyMap[tNode.nKey] = nil
    self.m_nCount = self.m_nCount - 1
    return tNode
end

function CKeyList:PopData()
    local tNode = self:Pop()
    if tNode then 
        return tNode.tData
    end
end

function CKeyList:Update(nKey, tData)
    assert(nKey and tData)
    local tNode = self:Find(nKey)
    if not tNode then 
        return 
    end
    if self.m_bDeepCopy then 
        tNode.tData = table.DeepCopy(tData)
    else
        tNode.tData = tData
    end
end

function CKeyList:Insert(nKey, tData, nIndex)
    assert(nKey and tData)
    self:Remove(nKey)
    nIndex = nIndex or (self.m_nCount + 1)
    nIndex = math.max(math.min(nIndex, self.m_nCount + 1), 1)

    local tNode = {}
    tNode.tPre = nil
    tNode.tNext = nil
    if bDeepCopy then 
        tNode.tData = table.DeepCopy(tData)
    else
        tNode.tData = tData
    end
    tNode.nKey = nKey


    if not self.m_tHead or not self.m_tTail then --空链表
        self.m_tHead = tNode
        self.m_tTail = tNode
        self.m_nCount = self.m_nCount + 1
        self.m_tKeyMap[nKey] = tNode
        nIndex = self.m_nCount
        return tNode, nIndex
    end
    if not nIndex or nIndex > self.m_nCount then --尾部插入
        tNode.tPre = self.m_tTail
        self.m_tTail.tNext = tNode
        self.m_tTail = tNode
        nIndex = self.m_nCount + 1
    else
        local tTempNode = nil
        if nIndex < (self.m_nCount / 2) then  --从首部迭代插入
            tTempNode = self.m_tHead
            for k = 1, nIndex - 1 do  --如果前面没修正，此处nIndex的值需要判断
                tTempNode = tTempNode.tNext
            end
        else --从尾部迭代插入
            tTempNode = self.m_tTail
            for k = 1, (self.m_nCount - nIndex) do 
                tTempNode = tTempNode.tPre
            end
        end
        assert(tTempNode)
        tNode.tPre = tTempNode.tPre
        tNode.tNext = tTempNode
        if tTempNode.tPre then
            tTempNode.tPre.tNext = tNode
        else  --首位置
            self.m_tHead = tNode
        end
        tTempNode.tPre = tNode
    end
    self.m_tKeyMap[nKey] = tNode
    self.m_nCount = self.m_nCount + 1
    return tNode, nIndex
end

--有效的返回值以1开始
function CKeyList:GetIndex(nKey)
    assert(nKey)
    local tNode = self.m_tKeyMap[nKey]
    if not tNode then 
        return 0
    end

    local tTempNode = self.m_tHead
    local nIndex = 0
    for k = 1, self.m_nCount do 
        if tTempNode.nKey == nKey then
            nIndex = k 
            break
        end
        tTempNode = tTempNode.tNext   --假设不存在，最后一轮迭代，会变成nil
    end
    assert(nIndex > 0)  --数据出错了才会找不到
    return nIndex
end

--fnCallback(tNode, nRank)
--从node开始，做callback，如果没提供，则从首节点开始
--nRank如果没提供，会从列表中查找当前的Rank，如果提供，后续会在此自增，登录排队功能使用
function CKeyList:NodeCallback(fnCallback, tNode, nRank)
    assert(fnCallback)
    if not tNode then 
        tNode = self:Head()
    end
    if not tNode then 
        return 
    end
    if not nRank or nRank < 1 then 
        nRank = self:GetIndex(tNode.nKey)
    end
    if nRank < 1 then --根据node.nKey找不到，说明找个node不是这个链表中的合法node
        return 
    end
    for k = 1, self.m_nCount do  --防止死循环
        fnCallback(tNode, nRank)
        tNode = tNode.tNext
        nRank = nRank + 1
        if not tNode then --到达链表尾部
            break
        end
    end
end

--这个允许删除当前迭代中的节点，迭代过程中，插入操作不受支持
--fnCallback(nKey, tData)
function CKeyList:InteratorCallback(fnCallback)
    local tNode = self:Head()
    if not tNode then 
        return 
    end
    for k = 1, self.m_nCount do  --防止死循环
        fnCallback(tNode.nKey, tNode.tData)
        tNode = tNode.tNext
        if not tNode then --到达链表尾部
            break
        end
    end
end

function CKeyList:GetDataByNode(tNode)
    if tNode then 
        return tNode.tData, tNode.nKey
    end
end

function CKeyList:GetNextNode(tNode)
    if tNode then 
        return tNode.tNext
    end
end

function CKeyList:IteratorGetNext(nKey) --内部接口
    local tNode = nil
    if not nKey then 
        if self.m_tHead then 
            tNode = self:Head()
        end
    else
        local tPreNode = self:Find(nKey)
        if not tPreNode then 
            LuaTrace("请注意，可能迭代过程中删除了元素或者key不存在")
            -- LuaTrace(debug.traceback())
            assert(false)
            return 
        end
        tNode = tPreNode.tNext
    end
    if not tNode then 
        return 
    end
    return tNode.nKey, tNode.tData
end

--示例用法 
-- local tList = CKeyList:new()
-- for k, data in tList:Iterator() do 
--     --k,data 分别为insert的 key值和data值
--     --do something
-- end
-- 不能在迭代过程中删除当前元素

--如果提供了nKey，则从nKey后面的那个开始迭代
function CKeyList:Iterator(nKey)
    return CKeyList.IteratorGetNext, self, nKey
end

--功能同Iterator
-- function CKeyList:Next(nKey)
--     return self:Iterator(nKey)
-- end

function CKeyList:DebugPrint()
    local tNode = self:Head()
    local nIndex = 1
    print("================ 当前链表数据 ================")
    for k, tData in self:Iterator() do 
        print("索引:"..nIndex, "key&data:", k, tData)
        nIndex = nIndex + 1
    end
    print(string.format("总节点数(%d), 打印数(%d)", self.m_nCount, nIndex - 1))
    print("================ 当前链表数据 ================")
end


