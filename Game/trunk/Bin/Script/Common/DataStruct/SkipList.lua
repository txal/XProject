local nRAND_MAX = 0x7FFF
local nZSKIPLIST_MAXLEVEL = 32   --Redis 32
local nZSKIPLIST_P = 0.25        --Skiplist P = 1/4

--比较函数例子: function compare(data1, data2) return 0/-1/1 end
function CSkipList:Ctor(_fncompare)
    self._fncompare = assert(_fncompare, "需要设置比较函数")
    self.level = 1
    self.length = 0
    self.header = self:_create_node()
    for k = 1, nZSKIPLIST_MAXLEVEL do
        self.header.level[k] = {}
        self.header.level[k].forward = nil
        self.header.level[k].span= 0
    end
    self.header.backward = nil
    self.tail = nil
    self.tkeymap = {}
end

function CSkipList:_create_node(data)
    local node = {}
    node.data = data 
    node.backward = nil
    node.level = {}
    return node
end

--这里会耗时点
function CSkipList:_random_level()
    local level = 1
    local nFlag = nZSKIPLIST_P * 0xFFFF
    while ((math.random(0, nRAND_MAX) & 0xFFFF) < nFlag) do
        level = level + 1
    end
    return ((level < nZSKIPLIST_MAXLEVEL) and level or nZSKIPLIST_MAXLEVEL)
end

function CSkipList:GetCount()
    return self.length
end

function CSkipList:Insert(key, data)
    assert(not self.tkeymap[key], "key已经存在")
    assert(type(data)=="table", "排序数据必须是个table")
    data._key_ = key
    self.tkeymap[key] = data

    local update = {}
    local rank = {}
    local node = self.header

    for i = self.level, 1, -1 do
    --store rank that is crossed to reach the insert position
        rank[i] = i == self.level and 0 or rank[i+1]
        while node.level[i].forward do
            local ncmp = self._fncompare(node.level[i].forward.data, data)
            if ncmp < 0 or (ncmp == 0 and node.level[i].forward.data._key_ < data._key_) then
                rank[i] = rank[i] + node.level[i].span
                node = node.level[i].forward
            else
                break
            end
        end
        update[i] = node
    end

    --we assume the key is not already inside, since we allow duplicated
    --scores, and the re-insertion of score and redis object should never
    --happen since the caller of zslInsert() should test in the hash table
    --if the element is already inside or not.
    local level = self:_random_level()
    if level > self.level then
        for i = self.level + 1, level do
            rank[i] = 0;
            update[i] = self.header
            update[i].level[i].span = self.length
        end
        self.level = level
    end
    node = self:_create_node(data)
    for i = 1, level do
        node.level[i] = {}
        node.level[i].forward = update[i].level[i].forward
        update[i].level[i].forward = node;

        --update span covered by update[i] as x is inserted here
        node.level[i].span = update[i].level[i].span - (rank[1] - rank[i])
        update[i].level[i].span = (rank[1] - rank[i]) + 1
    end

    -- increment span for untouched levels
    for i = level + 1, self.level do
        update[i].level[i].span = update[i].level[i].span + 1
    end

    node.backward = (update[1] ~= self.header) and update[1] or nil
    if node.level[1].forward then
        node.level[1].forward.backward = node
    else
        self.tail = node
    end
    self.length = self.length + 1
    return node
end


--Internal function used by zslDelete, zslDeleteByScore and zslDeleteByRank
function CSkipList:_delete_node(node, update)
    for i = 1, self.level do
        if update[i].level[i].forward == node then
            update[i].level[i].span = update[i].level[i].span + node.level[i].span - 1
            update[i].level[i].forward = node.level[i].forward
        else
            update[i].level[i].span = update[i].level[i].span - 1
        end
    end
    if node.level[1].forward then
        node.level[1].forward.backward = node.backward
    else
        self.tail = node.backward
    end
    while self.level > 1  and (not self.header.level[self.level].forward) do
        self.level = self.level - 1
    end
    self.length = self.length - 1
end

--Delete an element with matching score/object from the skiplist.
function CSkipList:Remove(key)
    local data = self.tkeymap[key]
    if not data then
        return false --not exist
    end
    local update = {}
    local node = self.header
    for i = self.level, 1, -1 do
        while node.level[i].forward do
            local ncmp = self._fncompare(node.level[i].forward.data, data)
            if ncmp < 0 or (ncmp == 0 and node.level[i].forward.data._key_ < data._key_) then
                node = node.level[i].forward
            else
                break
            end
        end
        update[i] = node
    end
    --We may have multiple elements with the same score, what we need
    --is to find the element with both the right score and object.
    node = node.level[1].forward
    if node and self._fncompare(data, node.data) == 0 and node.data._key_ == data._key_ then
        self:_delete_node(node, update)
        self.tkeymap[key] = nil
        return true
    end
    return false --not found
end

--Find the rank for an element by both score and key.
--Returns 0 when the element cannot be found, rank otherwise.
--Note that the rank is 1-based due to the span of zsl->header to the
--first element.
function CSkipList:GetRankByKey(key)
    local data = self.tkeymap[key]
    if not data then
        return 0    --not exist
    end
    local rank = 0 
    local node = self.header
    for i = self.level, 1, -1 do
        while node.level[i].forward do
            local ncmp = self._fncompare(node.level[i].forward.data, data)
            if ncmp < 0 or (ncmp == 0 and node.level[i].forward.data._key_ <= data._key_) then
                rank = rank + node.level[i].span
                node = node.level[i].forward
            else
                break
            end
        end
        --node might be equal to zsl->header, so test if obj is non-NULL
        if node.data and (node.data._key_ == data._key_) then
            return rank
        end
    end
    return 0
end

function CSkipList:GetDataByKey(key)
    return self.tkeymap[key]
end

--Finds an element by its rank. The rank argument needs to be 1-based.
function CSkipList:GetElementByRank(rank)
    if rank <= 0 or rank > self.length then
        return
    end
    local traversed = 0
    local node = self.header
    for i = self.level, 1, -1 do
        while node.level[i].forward and (traversed + node.level[i].span) <= rank do
            traversed = traversed + node.level[i].span
            node = node.level[i].forward
        end
        if traversed == rank then
            return node.data._key_, node.data
        end
    end
end

--Traverse all the elements with rank between start and end from the skiplist.
--Start and end are inclusive. Note that start and end need to be 1-based
--回调函数例子: function traverse(rank, key, data)
function CSkipList:Traverse(min, max, _fntraverse)
    assert(_fntraverse, "需要回调函数")
    if min <= 0 or max <= 0 or min > max then
        return
    end
    local traversed = 0
    local node = self.header
    for i = self.level, 1, -1 do
        while node.level[i].forward and (traversed + node.level[i].span) < min do
            traversed = traversed + node.level[i].span
            node = node.level[i].forward
        end
    end
    traversed = traversed + 1
    node = node.level[1].forward
    while node and traversed <= max do
        _fntraverse(traversed, node.data._key_, node.data) 
        node = node.level[1].forward
        traversed = traversed + 1
    end
end
