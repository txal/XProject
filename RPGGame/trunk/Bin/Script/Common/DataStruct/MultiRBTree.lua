--可重复插入相等数据RBTree，主要用于排名，插入相等数据处理等
local table, string, math, os, pairs, ipairs, assert = table, string, math, os, pairs, ipairs, assert


local tNodeColor = {eRed = 0, eBlack = 1, }

--允许多个相同值存储在同一个节点
--可重复插入相等数据RBTree，主要用于排名，插入相等数据处理等
--因为RBTree数据存储方式存在些许差异，所以不在原RBTree上继承了

--fnDataCmp 数据比较函数，小0排前面

--fnSecCmp 如果需要支持同多个数据同索引的情况，则fnDataCmp比较相等的情况下，即同索引情况下，
--将使用到这个函数再次比较data数据
--如果有限定nMaxIndexDataCount值，如果同索引数据超过限制值，则使用这个函数确定索引先后顺序
--小于0的，索引编号靠前
--如果没提供，则默认比较key值

--bIndexContinuous 索引是否连续的, 比如1索引位置上有3个数据，如果连续的，则后面的数据索引从2开始
--如果非连续的，则后续的数据索引从4开始 
--nMaxIndexDataCount, 每个索引上数据数量，如果为0，则不限制 

function CMultiRBTree:Ctor(fnDataCmp, fnSecCmp, bIndexContinuous, nMaxIndexDataCount)
    assert(fnDataCmp)
    self.m_tRoot = nil 
    self.m_fnDataCmp = fnDataCmp 
    self.m_fnSecCmp = fnSecCmp 

    self.m_fnCmp = function(tDataL, tDataR) 
        return self.m_fnDataCmp(tDataL.tData, tDataR.tData)
    end

    --Node结点，如果存在多个数据，进行比较的函数
    --如果是同一个节点的数据，说明self.m_fnDataCmp比较值是0，即相等
    self.m_fnNodeDataCmp = function(tDataL, tDataR) 
        if self.m_fnSecCmp then 
            return  self.m_fnSecCmp(tDataL, tDataR)
        end 
        return 0 --如果没提供，默认相等
    end

    self.m_bIndexContinuous = bIndexContinuous and true or false 
    self.m_nMaxIndexDataCount = nMaxIndexDataCount or 0 
    assert(type(self.m_nMaxIndexDataCount) == "number", "参数类型错误") 
    self.m_nMaxIndexDataCount = math.ceil(self.m_nMaxIndexDataCount) --防止错误传入一个非整型数据
    assert(self.m_nMaxIndexDataCount >= 0) --暂时不支持负数，虽然现在默认把负数作为0处理，实际为负数，不影响逻辑结果
    assert(self.m_nMaxIndexDataCount <= 200) --暂时不支持超过200的，
    --因为GetByIndex()在查询相关数据时，需要构造一个新table返回，如果数值太大，且操作频繁，会严重影响性能
    --要么为0，不限制，这样内部可以直接返回原引用对象，要么为一个较小数值

    --[[
    tNode = {
        tParent = nil, 
        tLeft = nil,
        tRight = nil,
        nColor = Black or Red,
        tData = {tData = tData, },  
        --数据容器，存放首个插入在该节点数据的深拷贝副本
        --所以，插入排行榜的数据，严禁循环递归引用，或者引用外部其他数据
        --目前实现还是浅拷贝

        oSubTree = CRBTree:new(self.m_fnNodeDataCmp),  
        --防止某个节点上数值过多，并且方便外层取数据，子数据，使用通用RBTree存储，不使用table

        nNodeDataCount = 0,      --当前结点数据数量，其实这个值就等于oSubTree:Count()
        nTotalDataCount = 0,     --当前结点子树，数据总数量
        nNodeIndexCount = 0,     --这个结点，占据的index计数
        nTotalIndexCount = 0,    --以这个结点为根的子树，占据的index计数
    }
    ]]

    self.m_tNil =  --哨兵节点
    {
        tParent = nil, 
        tLeft = nil,
        tRight = nil,
        nColor = tNodeColor.eBlack,
        tData = nil, 

        oSubTree = CRBTree:new(self.m_fnNodeDataCmp), 
        nNodeDataCount = 0, 
        nTotalDataCount = 0, 
        nNodeIndexCount = 0,
        nTotalIndexCount = 0,
    }

    self.m_tRoot = self.m_tNil 
    self.m_tDataMap = {} 
end 


--左旋
function CMultiRBTree:_left_rotate(tNode)
    assert(tNode)
    if tNode.tRight == self.m_tNil then 
        assert(false, "左旋错误，没有右孩子节点")
    end
    local x = tNode.tRight
    tNode.tRight = x.tLeft
    if x.tLeft ~= self.m_tNil then 
        x.tLeft.tParent = tNode
    end
    x.tParent = tNode.tParent
    if tNode.tParent == self.m_tNil then 
        self.m_tRoot = x 
    elseif tNode == tNode.tParent.tLeft then 
        tNode.tParent.tLeft = x 
    else
        tNode.tParent.tRight = x
    end
    x.tLeft = tNode
    tNode.tParent = x 

    --调整子树count数值
    local nNewIndexCount = tNode.nNodeIndexCount
    local nNewDataCount = tNode.nNodeDataCount
    if tNode.tLeft ~= self.m_tNil then 
        nNewIndexCount = nNewIndexCount + tNode.tLeft.nTotalIndexCount
        nNewDataCount = nNewDataCount + tNode.tLeft.nTotalDataCount
    end
    if tNode.tRight ~= self.m_tNil then 
        nNewIndexCount = nNewIndexCount + tNode.tRight.nTotalIndexCount
        nNewDataCount = nNewDataCount + tNode.tRight.nTotalDataCount
    end
    tNode.nTotalIndexCount = nNewIndexCount
    tNode.nTotalDataCount = nNewDataCount

    local nNewXIndexCount = x.nNodeIndexCount + nNewIndexCount
    local nNewXDataCount = x.nNodeDataCount + nNewDataCount
    if x.tRight ~= self.m_tNil then 
        nNewXIndexCount = nNewXIndexCount + x.tRight.nTotalIndexCount
        nNewXDataCount = nNewXDataCount + x.tRight.nTotalDataCount
    end
    x.nTotalIndexCount = nNewXIndexCount
    x.nTotalDataCount = nNewXDataCount
end 

--右旋
function CMultiRBTree:_right_rotate(tNode) 
    assert(tNode)
    if tNode.tLeft == self.m_tNil then 
        assert(false, "右旋错误，没有左孩子节点")
    end
    local x = tNode.tLeft
    tNode.tLeft = x.tRight
    if x.tRight ~= self.m_tNil then 
        x.tRight.tParent = tNode
    end
    x.tParent = tNode.tParent
    if tNode.tParent == self.m_tNil then 
        self.m_tRoot = x 
    elseif tNode == tNode.tParent.tLeft then 
        tNode.tParent.tLeft = x 
    else
        tNode.tParent.tRight = x 
    end
    x.tRight = tNode
    tNode.tParent = x 

    --调整子树count数值
    local nNewIndexCount = tNode.nNodeIndexCount
    local nNewDataCount = tNode.nNodeDataCount
    if tNode.tLeft ~= self.m_tNil then 
        nNewIndexCount = nNewIndexCount + tNode.tLeft.nTotalIndexCount
        nNewDataCount = nNewDataCount + tNode.tLeft.nTotalDataCount
    end
    if tNode.tRight ~= self.m_tNil then 
        nNewIndexCount = nNewIndexCount + tNode.tRight.nTotalIndexCount
        nNewDataCount = nNewDataCount + tNode.tRight.nTotalDataCount
    end
    tNode.nTotalIndexCount = nNewIndexCount
    tNode.nTotalDataCount = nNewDataCount

    local nNewXIndexCount = x.nNodeIndexCount + nNewIndexCount
    local nNewXDataCount = x.nNodeDataCount + nNewDataCount
    if x.tLeft ~= self.m_tNil then 
        nNewXIndexCount = nNewXIndexCount + x.tLeft.nTotalIndexCount
        nNewXDataCount = nNewXDataCount + x.tLeft.nTotalDataCount
    end
    x.nTotalIndexCount = nNewXIndexCount
    x.nTotalDataCount = nNewXDataCount
end

function CMultiRBTree:_insert_fixup(tNode) 
    while tNode.tParent.nColor == tNodeColor.eRed do 
        if tNode.tParent == tNode.tParent.tParent.tLeft then 
            local x = tNode.tParent.tParent.tRight
            if x.nColor == tNodeColor.eRed then 
                tNode.tParent.nColor = tNodeColor.eBlack
                x.nColor = tNodeColor.eBlack --如果x为红色，则x必然不为nil
                tNode.tParent.tParent.nColor = tNodeColor.eRed
                tNode = tNode.tParent.tParent
            else
                if tNode == tNode.tParent.tRight then 
                    tNode = tNode.tParent
                    self:_left_rotate(tNode)
                end 
                tNode.tParent.nColor = tNodeColor.eBlack
                tNode.tParent.tParent.nColor = tNodeColor.eRed
                self:_right_rotate(tNode.tParent.tParent) 
            end
        else 
            local x = tNode.tParent.tParent.tLeft
            if x.nColor == tNodeColor.eRed then 
                tNode.tParent.nColor = tNodeColor.eBlack
                x.nColor = tNodeColor.eBlack
                tNode.tParent.tParent.nColor = tNodeColor.eRed 
                tNode = tNode.tParent.tParent
            else
                if tNode == tNode.tParent.tLeft then 
                    tNode = tNode.tParent
                    self:_right_rotate(tNode)
                end
                tNode.tParent.nColor = tNodeColor.eBlack
                tNode.tParent.tParent.nColor = tNodeColor.eRed
                self:_left_rotate(tNode.tParent.tParent)
            end
        end
    end
    self.m_tRoot.nColor = tNodeColor.eBlack
end 

function CMultiRBTree:_update_node_count_data(tNode) 
    assert(tNode and tNode ~= self.m_tNil)
    tNode.nNodeDataCount = tNode.oSubTree:Count() 
    tNode.nTotalDataCount = tNode.nNodeDataCount + tNode.tLeft.nTotalDataCount + tNode.tRight.nTotalDataCount 
    if tNode.nNodeDataCount > 0 then 
        if self.m_nMaxIndexDataCount <= 0 then 
            tNode.nNodeIndexCount = 1 
        else
            tNode.nNodeIndexCount = math.ceil(tNode.nNodeDataCount / self.m_nMaxIndexDataCount) 
        end 
    else
        tNode.nNodeIndexCount = 0 
    end 
    tNode.nTotalIndexCount = tNode.nNodeIndexCount + tNode.tLeft.nTotalIndexCount 
        + tNode.tRight.nTotalIndexCount
end

--插入
-- nKey，只要是可以用于table做键值的并且可进行比较大小的数据类型都可以做Key
-- 内部没做深拷贝，所以，外部不能继续持有并修改tData引用数据
function CMultiRBTree:Insert(nKey, tData) 
    assert(nKey and tData)
    assert(not self.m_tDataMap[nKey], "重复插入"..nKey)

    local tContainer = {tData = tData}
    
    local y = self.m_tNil 
    local x = self.m_tRoot 
    local bEqual = false 
    while x ~= self.m_tNil do 
        y = x
        local nCmpResult = self.m_fnCmp(tContainer, x.tData)
        if nCmpResult < 0 then 
            x = x.tLeft
        elseif nCmpResult > 0 then 
            x = x.tRight 
        else 
            bEqual = true 
            break 
        end
    end 

    if bEqual then 
        y.oSubTree:Insert(nKey, tData) 
        self.m_tDataMap[nKey] = tData --操作成功后，才加入到datamap
        self:_update_node_count_data(y)
        self:_count_fixup(y)
        return 
    else
        local tNode = 
        {
            tParent = self.m_tNil,
            tLeft = self.m_tNil,
            tRight = self.m_tNil,
            nColor = tNodeColor.eRed, 
            tData = tContainer,      --暂时不做深拷贝 
            oSubTree = CRBTree:new(self.m_fnNodeDataCmp),
            nNodeDataCount = 1, 
            nTotalDataCount = 1,
            nNodeIndexCount = 1,
            nTotalIndexCount = 1
        }
        tNode.oSubTree:Insert(nKey, tData)

        tNode.tParent = y
        if y == self.m_tNil then 
            self.m_tRoot = tNode
        elseif self.m_fnCmp(tNode.tData, y.tData) < 0 then 
            y.tLeft = tNode
        else
            y.tRight = tNode
        end

        self.m_tDataMap[nKey] = tData --操作成功后，才加入到datamap 
        self:_update_node_count_data(tNode)
        self:_count_fixup(tNode, self.m_tRoot)
        self:_insert_fixup(tNode)
    end 
end

function CMultiRBTree:_minimum(tNode) 
    while tNode.tLeft ~= self.m_tNil do 
        tNode = tNode.tLeft
    end
    return tNode
end

function CMultiRBTree:_maximum(tNode) 
    while tNode.tRight ~= self.m_tNil do 
        tNode = tNode.tRight
    end
    return tNode
end

function CMultiRBTree:_count_fixup(tNode, tEndNode) 
    tEndNode = tEndNode or self.m_tRoot
    while tNode ~= self.m_tRoot do 
        if tNode == tNode.tParent.tLeft then 
            --如果tNode.tParent.tRigth为哨兵节点，相关count是0，不影响 
            local tParent = tNode.tParent 
            local tRight = tNode.tParent.tRight 
            tParent.nTotalIndexCount = tParent.nNodeIndexCount + tNode.nTotalIndexCount 
                + tRight.nTotalIndexCount 
            tParent.nTotalDataCount = tParent.nNodeDataCount + tNode.nTotalDataCount 
                + tRight.nTotalDataCount
        else
            local tParent = tNode.tParent 
            local tLeft = tNode.tParent.tLeft          
            tParent.nTotalIndexCount = tParent.nNodeIndexCount + tNode.nTotalIndexCount 
                + tLeft.nTotalIndexCount 
            tParent.nTotalDataCount = tParent.nNodeDataCount + tNode.nTotalDataCount 
                + tLeft.nTotalDataCount
        end
        tNode = tNode.tParent
        if tNode == tEndNode then 
            break 
        end
    end
end

function CMultiRBTree:_trans_plant(tNode, tTarNode) 
    if tNode.tParent == self.m_tNil then 
        self.m_tRoot = tTarNode
    elseif tNode == tNode.tParent.tLeft then 
        tNode.tParent.tLeft = tTarNode
    else 
        tNode.tParent.tRight = tTarNode
    end
    tTarNode.tParent = tNode.tParent  --即使是哨兵节点，也需要设置，count_fixup和delete_fixup都依赖这里
    self:_count_fixup(tTarNode, self.m_tRoot)
end

function CMultiRBTree:_search(nKey) 
    local tData = self.m_tDataMap[nKey]
    if not tData then 
        return 
    end
    local tContainer = {tData = tData}
    local x = self.m_tRoot 
    while x ~= self.m_tNil and not x.oSubTree:IsExist(nKey) do 
        if self.m_fnCmp(tContainer, x.tData) < 0 then 
            x = x.tLeft
        else
            x = x.tRight
        end
    end
    if x == self.m_tNil or not x.oSubTree:IsExist(nKey) then 
        assert(false, "数据错误") 
    end
    return x 
end

function CMultiRBTree:_delete_fixup(tNode) 
    while tNode ~= self.m_tRoot and tNode.nColor == tNodeColor.eBlack do 
        if tNode == tNode.tParent.tLeft then 
            local x = tNode.tParent.tRight  
            if x.nColor == tNodeColor.eRed then 
                x.nColor = tNodeColor.eBlack
                tNode.tParent.nColor = tNodeColor.eRed
                self:_left_rotate(tNode.tParent)
                x = tNode.tParent.tRight 
            end 
            if x.tLeft.nColor == tNodeColor.eBlack and x.tRight.nColor == tNodeColor.eBlack then --case 2，左右皆黑
                x.nColor = tNodeColor.eRed
                tNode = tNode.tParent 
            else
                if x.tRight.nColor == tNodeColor.eBlack then 
                    x.tLeft.nColor = tNodeColor.eBlack
                    x.nColor = tNodeColor.eRed
                    self:_right_rotate(x) 
                    x = tNode.tParent.tRight 
                end

                x.nColor = tNode.tParent.nColor
                tNode.tParent.nColor = tNodeColor.eBlack
                x.tRight.nColor = tNodeColor.eBlack
                self:_left_rotate(tNode.tParent) 
                tNode = self.m_tRoot  
            end
        else 
            local x = tNode.tParent.tLeft 
            if x.nColor == tNodeColor.eRed then 
                x.nColor = tNodeColor.eBlack
                tNode.tParent.nColor = tNodeColor.eRed
                self:_right_rotate(tNode.tParent)
                x = tNode.tParent.tLeft
            end
            if x.tLeft.nColor == tNodeColor.eBlack and x.tRight.nColor == tNodeColor.eBlack then 
                x.nColor = tNodeColor.eRed
                tNode = tNode.tParent
            else
                if x.tLeft.nColor == tNodeColor.eBlack then 
                    x.tRight.nColor = tNodeColor.eBlack
                    x.nColor = tNodeColor.eRed
                    self:_left_rotate(x)
                    x = tNode.tParent.tLeft
                end
                x.nColor = tNode.tParent.nColor
                tNode.tParent.nColor = tNodeColor.eBlack
                x.tLeft.nColor = tNodeColor.eBlack 
                self:_right_rotate(tNode.tParent)
                tNode = self.m_tRoot
            end
        end
    end
    tNode.nColor = tNodeColor.eBlack
end

--删除
function CMultiRBTree:Remove(nKey) 
    assert(nKey)
    if not self.m_tDataMap[nKey] then return end
    local tNode = self:_search(nKey)  --待删除节点
    assert(tNode, "数据错误") 

    tNode.oSubTree:Remove(nKey) 
    self.m_tDataMap[nKey] = nil 
    self:_update_node_count_data(tNode) 
    self:_count_fixup(tNode, self.m_tRoot) 

    --检查当前节点是否还有数据，如果没有数据，则移除 
    if tNode.nNodeDataCount <= 0 then 
        local tNextNode = nil  --被移除节点的后继占位节点，可能为self.m_tNil
        --[[
            (移除某个节点，如果某个节点存在2个子节点，
            则总是被转换成使用改节点右子树的最小值节点去替换待删除的节点,
            然后使用该最小值节点的右子树拼接到 该最小值节点的原位置，
            即该最小值子节点的右子树, 占据原该最小值子节点位置
            该最小值子节点的颜色替换为被删除的颜色，实际删除的节点相当于是该最小值子节点
            所以从该最小值子节点的右子树开始向上检查恢复红黑性质即可)
        ]]
        local nDelColor = tNode.nColor --被移除节点的颜色
        if tNode.tLeft == self.m_tNil then 
            tNextNode = tNode.tRight
            self:_trans_plant(tNode, tNode.tRight)
        elseif tNode.tRight == self.m_tNil then 
            tNextNode = tNode.tLeft
            self:_trans_plant(tNode, tNode.tLeft)
        else 
            local x = self:_minimum(tNode.tRight) 
            nDelColor = x.nColor
            tNextNode = x.tRight
            if x.tParent == tNode then 
                tNextNode.tParent = x 
                --防止x.tRight==self.m_tNil，即tNode只有一个右子节点时
                --即x.tRight指向self.m_tNil, 没有设置self.m_tNil的父节点,delete_fixup中需要使用到这个参数
            else
                self:_trans_plant(x, x.tRight)
                x.tRight = tNode.tRight
                x.tRight.tParent = x 
                self:_update_node_count_data(x)
                --x.tParent在后续_trans_plant中会先被设置，所以也不影响后续的_count_finxup处理
            end
            self:_trans_plant(tNode, x)
            x.tLeft = tNode.tLeft
            x.tLeft.tParent = x
            x.nColor = tNode.nColor
            self:_update_node_count_data(x)
            self:_count_fixup(x.tLeft, self.m_tRoot)
        end

        if nDelColor == tNodeColor.eBlack then 
            self:_delete_fixup(tNextNode)
        end
    end
end

--更新, 如果不存在，则插入
--内部没做深拷贝，所以，外部不能继续持有并修改tData引用数据
function CMultiRBTree:Update(nKey, tData) 
    assert(nKey and tData)
    self:Delete(nKey) 
    self:Insert(nKey, tData)
end

function CMultiRBTree:Count()
    return self.m_tRoot.nTotalDataCount
end 

function CMultiRBTree:IsEmpty() 
    return self.m_tRoot == self.m_tNil 
end

function CMultiRBTree:MaxIndex() 
    if self:IsEmpty() then 
        return 0
    end
    if self.m_bIndexContinuous then 
        return self.m_tRoot.nTotalIndexCount 
    else 
        local tNode = self:_maximum(self.m_tRoot) 
        if tNode.nNodeIndexCount <= 1 then 
            return self.m_tRoot.nTotalDataCount - tNode.nNodeDataCount + 1
        else --这种情况，说明self.m_nMaxIndexDataCount >= 1
            return self.m_tRoot.nTotalDataCount - 
                (tNode.nNodeDataCount - (tNode.nNodeIndexCount - 1) * self.m_nMaxIndexDataCount)  + 1
        end
    end
end

--返回所有数据的table, {key:data, ...} 
--为了避免大量数据时的开销，这个是内部数据的直接引用
--外层获取到该数据后，不能修改此数据值
--用于给外部进行存储等操作时使用的
function CMultiRBTree:GetAllData()
    return self.m_tDataMap 
end

function CMultiRBTree:IsExist(nKey) 
    return self.m_tDataMap[nKey] and true or false 
end

function CMultiRBTree:GetDataByKey(nKey)
    return self.m_tDataMap[nKey] 
end

function CMultiRBTree:_get_sub_index(tNode, nKey) 
    assert(tNode and nKey)
    assert(tNode.oSubTree:IsExist(nKey)) 

    if tNode.nNodeIndexCount <= 1 then 
        return 1 
    else --这种情况，说明self.m_nMaxIndexDataCount >= 1
        local nSubIndex = tNode.oSubTree:GetIndex(nKey) 
        if self.m_bIndexContinuous then 
            return math.ceil(nSubIndex / self.m_nMaxIndexDataCount)
        else 
            return (math.ceil(nSubIndex / self.m_nMaxIndexDataCount) - 1) * self.m_nMaxIndexDataCount + 1
        end
    end
end

--获取节点索引 --中序遍历顺序
--索引从1开始，如果不存在，返回0
function CMultiRBTree:GetIndex(nKey) 
    local tData = self.m_tDataMap[nKey]
    if not tData then 
        return 0
    end

    local x = self.m_tRoot 
    local tContainer = {tData = tData}
    if self.m_bIndexContinuous then 
        local nIndex = 0
        local nIndexBegin = x.tLeft.nTotalIndexCount + 1
        while x ~= self.m_tNil do 
            local nCmpResult = self.m_fnCmp(tContainer, x.tData)
            if nCmpResult < 0 then 
                x = x.tLeft --除非出现数据逻辑错误，新的x必然不为nil
                nIndexBegin = nIndexBegin - x.nNodeIndexCount - x.tRight.nTotalIndexCount  
            elseif nCmpResult > 0 then 
                x = x.tRight  --同上
                nIndexBegin = nIndexBegin + x.tParent.nNodeIndexCount + x.tLeft.nTotalIndexCount
            else 
                local nSubIndex = self:_get_sub_index(x, nKey)
                nIndex = nIndexBegin + nSubIndex - 1 
                break 
            end
        end
        if x == self.m_tNil or not x.oSubTree:IsExist(nKey) then --不存在
            assert(false, "数据错误")
        end
        return nIndex 
    else 
        local nIndex = 0
        local nIndexBegin = x.tLeft.nTotalDataCount + 1 
        while x ~= self.m_tNil do 
            local nCmpResult = self.m_fnCmp(tContainer, x.tData)
            if nCmpResult < 0 then 
                x = x.tLeft --除非出现数据逻辑错误，新的x必然不为nil
                nIndexBegin = nIndexBegin - x.nNodeDataCount - x.tRight.nTotalDataCount 
            elseif nCmpResult > 0 then 
                x = x.tRight  --同上
                nIndexBegin = nIndexBegin + x.tParent.nNodeDataCount + x.tLeft.nTotalDataCount
            else 
                local nSubIndex = self:_get_sub_index(x, nKey)
                nIndex = nIndexBegin + nSubIndex - 1 
                break 
            end
        end
        if x == self.m_tNil or not x.oSubTree:IsExist(nKey) then --不存在
            assert(false, "数据错误")
        end
        return nIndex 
    end
end

--返回 tNode, nIndexBegin, nIndexEnd, bExist
--bExist，如果索引非连续的，指定的索引可能不存在，返回这个索引分布区间的所属的tNode
function CMultiRBTree:_get_node_by_index(nIndex) 
    if nIndex <= 0 or nIndex > self:MaxIndex() or self.m_tRoot == self.m_tNil then 
        return 
    end

    local tNode = self.m_tRoot
    if self.m_bIndexContinuous then 
        local nIndexBegin = tNode.tLeft.nTotalIndexCount + 1
        local nIndexEnd = nIndexBegin + tNode.nNodeIndexCount - 1
        while tNode ~= self.m_tNil do 
            if nIndex < nIndexBegin then 
                tNode = tNode.tLeft 
                nIndexBegin = nIndexBegin - tNode.nNodeIndexCount - tNode.tRight.nTotalIndexCount 
                nIndexEnd = nIndexBegin + tNode.nNodeIndexCount - 1
            elseif nIndex > nIndexEnd then 
                tNode = tNode.tRight 
                nIndexBegin = nIndexBegin + tNode.tParent.nNodeIndexCount + tNode.tLeft.nTotalIndexCount
                nIndexEnd = nIndexBegin + tNode.nNodeIndexCount - 1
            else
                return tNode, nIndexBegin, nIndexEnd, true
            end
        end
        assert(false, "计算错误")
    else
        local nIndexBegin = tNode.tLeft.nTotalDataCount + 1
        local nIndexEnd = nIndexBegin + tNode.nNodeDataCount - 1
        while tNode ~= self.m_tNil do 
            if nIndex < nIndexBegin then 
                tNode = tNode.tLeft 
                nIndexBegin = nIndexBegin - tNode.nNodeDataCount - tNode.tRight.nTotalDataCount 
                nIndexEnd = nIndexBegin + tNode.nNodeDataCount - 1
            elseif nIndex > nIndexEnd then 
                tNode = tNode.tRight 
                nIndexBegin = nIndexBegin + tNode.tParent.nNodeDataCount + tNode.tLeft.nTotalDataCount
                nIndexEnd = nIndexBegin + tNode.nNodeDataCount - 1
            else
                --需要注意，如果索引非连续的，某些索引是不存在的 
                if tNode.nNodeIndexCount <= 1 then 
                    return tNode, nIndexBegin, nIndexEnd, true
                else --这种情况，self.m_nMaxIndexDataCount 必然 >= 1 
                    if ((nIndex - nIndexBegin) % self.m_nMaxIndexDataCount) ~= 0 then --不存在的索引
                        return tNode, nIndexBegin, nIndexEnd, false
                    end
                    return tNode, nIndexBegin, nIndexEnd, true
                end
            end
        end
        assert(false, "计算错误")
    end 
end

--根据结点index返回该索引下的所有key和data值{nKey:tData, ...}, --中序遍历顺序
--如果不存在，则返回空表{} 
--为了效率，返回的内部源数据的引用，不能修改返回数据，如果需要修改，外部自行深拷贝之后操作
function CMultiRBTree:GetByIndex(nIndex) 
    if nIndex <= 0 or nIndex > self:MaxIndex() or self.m_tRoot == self.m_tNil then 
        return {}
    end

    local tNode = self.m_tRoot
    
    if self.m_bIndexContinuous then 
        local nIndexBegin = tNode.tLeft.nTotalIndexCount + 1
        local nIndexEnd = nIndexBegin + tNode.nNodeIndexCount - 1
        while tNode ~= self.m_tNil do 
            if nIndex < nIndexBegin then 
                tNode = tNode.tLeft 
                nIndexBegin = nIndexBegin - tNode.nNodeIndexCount - tNode.tRight.nTotalIndexCount 
                nIndexEnd = nIndexBegin + tNode.nNodeIndexCount - 1
            elseif nIndex > nIndexEnd then 
                tNode = tNode.tRight 
                nIndexBegin = nIndexBegin + tNode.tParent.nNodeIndexCount + tNode.tLeft.nTotalIndexCount
                nIndexEnd = nIndexBegin + tNode.nNodeIndexCount - 1
            else
                if tNode.nNodeIndexCount <= 1 then 
                    return tNode.oSubTree:GetAllData()
                else --这种情况，self.m_nMaxIndexDataCount 必然 >= 1
                    local nTarSubIndex = nIndex - nIndexBegin + 1 
                    local nBeginSubIndex = (nTarSubIndex - 1)*self.m_nMaxIndexDataCount + 1
                    local nEndSubIndex = math.min(nBeginSubIndex + self.m_nMaxIndexDataCount - 1, 
                        tNode.oSubTree:MaxIndex())
                    --需要重新构造一个data返回
                    local tDataTbl = {} 
                    local oSubTree = tNode.oSubTree
                    for k = nBeginSubIndex, nEndSubIndex do 
                        local nKey, tData = oSubTree:GetByIndex(k) 
                        tDataTbl[nKey] = tData
                    end
                    return tDataTbl
                end
            end
        end
        -- return {}
        assert(false, "计算错误")
    else
        local nIndexBegin = tNode.tLeft.nTotalDataCount + 1
        local nIndexEnd = nIndexBegin + tNode.nNodeDataCount - 1
        while tNode ~= self.m_tNil do 
            if nIndex < nIndexBegin then 
                tNode = tNode.tLeft 
                nIndexBegin = nIndexBegin - tNode.nNodeDataCount - tNode.tRight.nTotalDataCount 
                nIndexEnd = nIndexBegin + tNode.nNodeDataCount - 1
            elseif nIndex > nIndexEnd then 
                tNode = tNode.tRight 
                nIndexBegin = nIndexBegin + tNode.tParent.nNodeDataCount + tNode.tLeft.nTotalDataCount
                nIndexEnd = nIndexBegin + tNode.nNodeDataCount - 1
            else
                --需要注意，如果索引非连续的，某些索引是不存在的 
                if tNode.nNodeIndexCount <= 1 then 
                    if nIndexBegin ~= nIndex then --不存在的索引
                        return {} 
                    end
                    return tNode.oSubTree:GetAllData()
                else --这种情况，self.m_nMaxIndexDataCount 必然 >= 1 

                    if ((nIndex - nIndexBegin) % self.m_nMaxIndexDataCount) ~= 0 then --不存在的索引
                        return {} 
                    end
                    --前驱的subGroup数量，即有多少个
                    local nPreSubIndexGroup = (math.ceil((nIndex - nIndexBegin + 1)/self.m_nMaxIndexDataCount) - 1)
                    local nBeginSubIndex = nPreSubIndexGroup*self.m_nMaxIndexDataCount + 1
                    local nEndSubIndex = math.min(nBeginSubIndex + self.m_nMaxIndexDataCount - 1, 
                        tNode.oSubTree:Count())
                    --需要重新构造一个data返回
                    local tDataTbl = {} 
                    local oSubTree = tNode.oSubTree
                    for k = nBeginSubIndex, nEndSubIndex do 
                        local nKey, tData = oSubTree:GetByIndex(k) 
                        tDataTbl[nKey] = tData
                    end
                    return tDataTbl
                end
            end
        end
        -- return {}
        assert(false, "计算错误")
    end 
end

--获取数据排序索引
--(如果获取排名，请使用GetIndex接口)
--这个接口，只是提供部分数据交互使用的，比如分批有序给前端发送当前排行榜数据
--每个数据，都有一个唯一的排序索引
--索引从1开始，如果不存在，返回0
function CMultiRBTree:GetDataRank(nKey) 
    local tData = self.m_tDataMap[nKey]
    if not tData then 
        return 0
    end

    local tContainer = {tData = tData} 
    local x = self.m_tRoot
    local nIndex = 0
    local nIndexBegin = x.tLeft.nTotalDataCount + 1 
    while x ~= self.m_tNil do 
        local nCmpResult = self.m_fnCmp(tContainer, x.tData)
        if nCmpResult < 0 then 
            x = x.tLeft --除非出现数据逻辑错误，新的x必然不为nil
            nIndexBegin = nIndexBegin - x.nNodeDataCount - x.tRight.nTotalDataCount 
        elseif nCmpResult > 0 then 
            x = x.tRight  --同上
            nIndexBegin = nIndexBegin + x.tParent.nNodeDataCount + x.tLeft.nTotalDataCount
        else 
            local nSubIndex = x.oSubTree:GetIndex(nKey) 
            nIndex = nIndexBegin + nSubIndex - 1 
            break 
        end
    end
    if x == self.m_tNil or not x.oSubTree:IsExist(nKey) then --不存在
        assert(false, "数据错误")
    end
    return nIndex 
end 

function CMultiRBTree:_get_node_by_data_rank(nRank) 
    if nRank <= 0 or nRank > self:Count() or self.m_tRoot == self.m_tNil then 
        return 
    end

    local tNode = self.m_tRoot

    if self.m_bIndexContinuous then 
        local nDataRankBegin = tNode.tLeft.nTotalDataCount + 1
        local nDataRankEnd = nDataRankBegin + tNode.nNodeDataCount - 1
        local nIndexBegin = tNode.tLeft.nTotalIndexCount + 1
        while tNode ~= self.m_tNil do 
            if nRank < nDataRankBegin then 
                tNode = tNode.tLeft 
                nDataRankBegin = nDataRankBegin - tNode.nNodeDataCount - tNode.tRight.nTotalDataCount 
                nDataRankEnd = nDataRankBegin + tNode.nNodeDataCount - 1
                nIndexBegin = nIndexBegin - tNode.nNodeIndexCount - tNode.tRight.nTotalIndexCount
            elseif nRank > nDataRankEnd then 
                tNode = tNode.tRight 
                nDataRankBegin = nDataRankBegin + tNode.tParent.nNodeDataCount + tNode.tLeft.nTotalDataCount
                nDataRankEnd = nDataRankBegin + tNode.nNodeDataCount - 1
                nIndexBegin = nIndexBegin + tNode.tParent.nNodeIndexCount + tNode.tLeft.nTotalIndexCount
            else
                return tNode, nDataRankBegin, nIndexBegin
            end
        end
    else
        local nDataRankBegin = tNode.tLeft.nTotalDataCount + 1
        local nDataRankEnd = nDataRankBegin + tNode.nNodeDataCount - 1
        local nIndexBegin = tNode.nDataRankBegin
        while tNode ~= self.m_tNil do 
            if nRank < nDataRankBegin then 
                tNode = tNode.tLeft 
                nDataRankBegin = nDataRankBegin - tNode.nNodeDataCount - tNode.tRight.nTotalDataCount 
                nDataRankEnd = nDataRankBegin + tNode.nNodeDataCount - 1
                nIndexBegin = nDataRankBegin
            elseif nRank > nDataRankEnd then 
                tNode = tNode.tRight 
                nDataRankBegin = nDataRankBegin + tNode.tParent.nNodeDataCount + tNode.tLeft.nTotalDataCount
                nDataRankEnd = nDataRankBegin + tNode.nNodeDataCount - 1
                nIndexBegin = nDataRankBegin
            else
                return tNode, nDataRankBegin, nIndexBegin
            end
        end
    end
end

--获取排名，请使用GetIndex接口
--这个接口，只是提供部分数据交互使用的，比如分批有序给前端发送当前排行榜数据
--根据数据排序索引，获取数据 nKey, tData
function CMultiRBTree:GetByDataRank(nRank) 
    if nRank <= 0 or nRank > self:Count() or self.m_tRoot == self.m_tNil then 
        return 
    end
    local tNode, nRankBegin = self:_get_node_by_data_rank(nRank)
    assert(tNode, "数据错误")
    local nTarSubIndex = nRank - nRankBegin + 1
    return tNode.oSubTree:GetByIndex(nTarSubIndex)
end

--返回nil说明当前已经是这颗树最后一个节点
--返回下一个tNode, nIndexBegin
function CMultiRBTree:_get_next_node(tNode, nIndexBegin) 
    if tNode == self.m_tNil then 
        return 
    end
    if tNode.tRight ~= self.m_tNil then 
        tNode = tNode.tRight
        if self.m_bIndexContinuous then 
            nIndexBegin = nIndexBegin + tNode.tParent.nNodeIndexCount + tNode.tLeft.nTotalIndexCount
        else
            nIndexBegin = nIndexBegin + tNode.tParent.nNodeDataCount + tNode.tLeft.nTotalDataCount
        end

        while tNode.tLeft ~= self.m_tNil do 
            tNode = tNode.tLeft 
            if self.m_bIndexContinuous then 
                nIndexBegin = nIndexBegin - tNode.nNodeIndexCount - tNode.tRight.nTotalIndexCount
            else
                nIndexBegin = nIndexBegin - tNode.nNodeDataCount - tNode.tRight.nTotalDataCount
            end
        end
        return tNode, nIndexBegin
    end

    while tNode ~= self.m_tRoot do 
        if tNode == tNode.tParent.tRight then 
            tNode = tNode.tParent 
            if self.m_bIndexContinuous then 
                nIndexBegin = nIndexBegin - tNode.tRight.tLeft.nTotalIndexCount - tNode.nNodeIndexCount
            else
                nIndexBegin = nIndexBegin - tNode.tRight.tLeft.nTotalDataCount - tNode.nNodeDataCount
            end
        else
            if self.m_bIndexContinuous then 
                nIndexBegin = nIndexBegin + tNode.nNodeIndexCount + tNode.tRight.nTotalIndexCount
            else
                nIndexBegin = nIndexBegin + tNode.nNodeDataCount + tNode.tRight.nTotalDataCount
            end
            return tNode.tParent, nIndexBegin
        end
    end
    return 
end

function CMultiRBTree:_traverse_node(tNode, nBegin, nEnd, nIndexBase, fnProc) 
    local oSubTree = tNode.oSubTree 
    if self.m_bIndexContinuous then  --索引连续的情况下
        local tSubNode = oSubTree:_get_node_by_index(nBegin)
        assert(tSubNode)
        local nIndex = nIndexBase
        for k = nBegin, nEnd do 
            if tNode.nNodeIndexCount > 1 then 
                nIndex = nIndexBase + (k - 1) // self.m_nMaxIndexDataCount
            end
            if fnProc(nIndex, tSubNode.tData.nKey, tSubNode.tData.nKey) then 
                return true 
            end

            tSubNode = oSubTree:_get_next_node(tSubNode)
            if not tSubNode then 
                return 
            end
        end 

    else 
        local tSubNode = oSubTree:_get_node_by_index(nBegin)
        assert(tSubNode)

        local nIndex = nIndexBase
        for k = nBegin, nEnd do 
            if tNode.nNodeIndexCount > 1 then 
                nIndex = nIndexBase + ((k - 1) // self.m_nMaxIndexDataCount) * self.m_nMaxIndexDataCount
            end
            if fnProc(nIndex, tSubNode.tData.nKey, tSubNode.tData.nKey) then 
                return true 
            end

            tSubNode = oSubTree:_get_next_node(tSubNode) 
            if not tSubNode then 
                return 
            end
        end 
    end
end

--fnProc(nIndex, nKey, tData)
--fnProc返回true则停止迭代(保持和RBTree接口特性一致, 兼容SkipList接口)
--因为增加了支持中途跳出逻辑，会牺牲一点点执行效率(大约10%)
--测试了下，10W左右的数据量下，和递归执行速度差不多，
--这个更容易直观理解些，而且不用在通用RBTree中强行加私有接口
function CMultiRBTree:Traverse(nMin, nMax, fnProc) 
    assert(nMin and nMax and fnProc, "参数错误") 
    nMin = math.max(nMin, 1)
    if self:IsEmpty() or nMin > self:Count() then 
        return 
    end
    assert(nMin <= nMax)
    local nStartIndex = nMin
    local nTailIndex = nMax

    if self.m_bIndexContinuous then 
        local tNode, nIndexBegin = self:_get_node_by_index(nStartIndex)
        assert(tNode)
        while tNode and nIndexBegin <= nTailIndex do 
            local nIndexEnd = nIndexBegin + tNode.nNodeIndexCount - 1
            if nIndexBegin <= nStartIndex then 
                if tNode.nNodeIndexCount <= 1 then 
                    if self:_traverse_node(tNode, 1, tNode.oSubTree:MaxIndex(), nIndexBegin, fnProc) then 
                        return true 
                    end
                else -- self.m_nMaxIndexDataCount >= 1 
                    if nIndexBegin <= nStartIndex then 
                        --因为是连续的，所以实际不会存在 nStartIndex > nIndexEnd
                        if nStartIndex <= nIndexEnd then 
                            local nSubIndex = (nStartIndex - nIndexBegin) * self.m_nMaxIndexDataCount + 1 
                            --需要检查，是否在这个节点，就直接结束了
                            if nIndexEnd > nTailIndex then 
                                local nSubEndIndex = math.min((nTailIndex - nIndexBegin + 1) * self.m_nMaxIndexDataCount, 
                                    tNode.oSubTree:MaxIndex())
                                if self:_traverse_node(tNode, nSubIndex, nSubEndIndex, nIndexBegin, fnProc) then 
                                    return true 
                                end
                                -- return --直接退出
                            else
                                if self:_traverse_node(tNode, nSubIndex, tNode.oSubTree:MaxIndex(), nIndexBegin, fnProc) then 
                                    return true
                                end
                            end
                        end
                    end
                end 
            elseif nIndexEnd >= nTailIndex then 
                local nSubEndIndex = 0
                if tNode.nNodeIndexCount <= 1 then 
                    nSubEndIndex = tNode.oSubTree:MaxIndex()
                else
                    nSubEndIndex = math.min((nTailIndex - nIndexBegin + 1) * self.m_nMaxIndexDataCount, 
                    tNode.oSubTree:MaxIndex())
                end
                if self:_traverse_node(tNode, 1, nSubEndIndex, nIndexBegin, fnProc) then 
                    return true 
                end
                -- return  --退出
            else
                if self:_traverse_node(tNode, 1, tNode.oSubTree:MaxIndex(), nIndexBegin, fnProc) then 
                    return true 
                end
            end
            -- print(string.format("nIndexBegin(%d), nEnd(%d)", nIndexBegin, nIndexEnd))
            tNode, nIndexBegin = self:_get_next_node(tNode, nIndexBegin)
        end

    else 
        local tNode, nIndexBegin = self:_get_node_by_index(nStartIndex)
        assert(tNode)
        while tNode and nIndexBegin <= nTailIndex do 
            local nIndexMax = nIndexBegin + tNode.nNodeDataCount - 1  --节点所可能达到的最大索引值(占据的索引区间最大值)
            local nIndexEnd = nil
            if tNode.nNodeIndexCount <= 1 then 
                nIndexEnd = nIndexBegin 
            else  --self.m_nMaxIndexDataCount > 1
                nIndexEnd = nIndexBegin + (tNode.nNodeIndexCount - 1)*self.m_nMaxIndexDataCount 
            end
            --需要注意，索引不存在的情况
            if nIndexBegin <= nStartIndex then 
                if nStartIndex <= nIndexEnd then --大于则说明，迭代的第一个节点，尾部不存在该索引
                    if tNode.nNodeIndexCount <= 1 then 
                        if self:_traverse_node(tNode, 1, tNode.oSubTree:MaxIndex(), nIndexBegin, fnProc) then 
                            return true 
                        end
                    else -- self.m_nMaxIndexDataCount >= 1 
                        local nSubIndex = (nStartIndex - nIndexBegin) * self.m_nMaxIndexDataCount + 1 
                        --需要检查，是否在这个节点，就直接结束了
                        if nIndexEnd > nTailIndex then 
                            local nSubEndIndex = math.min(math.ceil((nTailIndex - nIndexBegin + 1) / self.m_nMaxIndexDataCount) * self.m_nMaxIndexDataCount, 
                                tNode.oSubTree:MaxIndex())
                            if self:_traverse_node(tNode, nSubIndex, nSubEndIndex, nIndexBegin, fnProc) then 
                                return true 
                            end
                        else
                            if self:_traverse_node(tNode, nSubIndex, tNode.oSubTree:MaxIndex(), nIndexBegin, fnProc) then 
                                return true 
                            end
                        end
                    end
                end
            elseif nIndexEnd >= nTailIndex then 
                if tNode.nNodeIndexCount <= 1 then 
                    if self:_traverse_node(tNode, 1, tNode.oSubTree:MaxIndex(), nIndexBegin, fnProc) then 
                        return true 
                    end
                else -- self.m_nMaxIndexDataCount >= 1 
                    local nSubEndIndex = math.min(math.ceil((nTailIndex - nIndexBegin + 1) / self.m_nMaxIndexDataCount) * self.m_nMaxIndexDataCount, 
                            tNode.oSubTree:MaxIndex())
                    if self:_traverse_node(tNode, 1, nSubEndIndex, nIndexBegin, fnProc) then 
                        return true 
                    end
                end
            else
                if self:_traverse_node(tNode, 1, tNode.oSubTree:MaxIndex(), nIndexBegin, fnProc) then 
                    return true
                end
            end

            tNode, nIndexBegin = self:_get_next_node(tNode, nIndexBegin)
        end
    end
end

function CMultiRBTree:_get_next_node_by_data_rank(tNode, nDataRankBegin, nIndexBegin) 
    if tNode == self.m_tNil then 
        return 
    end

    if tNode.tRight ~= self.m_tNil then 
        local tNext = tNode.tRight
        nDataRankBegin = nDataRankBegin + tNode.nNodeDataCount + tNext.tLeft.nTotalDataCount 
        if self.m_bIndexContinuous then 
            nIndexBegin = nIndexBegin + tNode.nNodeIndexCount + tNext.tLeft.nTotalIndexCount
        else
            nIndexBegin = nDataRankBegin
        end
        tNode = tNext

        while tNode.tLeft ~= self.m_tNil do 
            tNode = tNode.tLeft 
            nDataRankBegin = nDataRankBegin - tNode.nNodeDataCount - tNode.tRight.nTotalDataCount
            if self.m_bIndexContinuous then 
                nIndexBegin = nIndexBegin - tNode.nNodeIndexCount - tNode.tRight.nTotalIndexCount
            else
                nIndexBegin = nDataRankBegin
            end
        end
        return tNode, nDataRankBegin, nIndexBegin
    end

    while tNode ~= self.m_tRoot do 
        if tNode == tNode.tParent.tRight then 
            local tNext = tNode.tParent 
            nDataRankBegin = nDataRankBegin - tNode.tLeft.nTotalDataCount - tNext.nNodeDataCount
            if self.m_bIndexContinuous then 
                nIndexBegin = nIndexBegin - tNode.tLeft.nTotalIndexCount - tNext.nNodeIndexCount
            else
                nIndexBegin = nDataRankBegin
            end
            tNode = tNext
        else
            nDataRankBegin = nDataRankBegin + tNode.nNodeDataCount + tNode.tRight.nTotalDataCount
            if self.m_bIndexContinuous then 
                nIndexBegin = nIndexBegin + tNode.nNodeIndexCount + tNode.tRight.nTotalIndexCount
            else
                nIndexBegin = nDataRankBegin
            end
            return tNode.tParent, nDataRankBegin, nIndexBegin
        end
    end
    return 
end

function CMultiRBTree:_traverse_node_by_data_rank(tNode, nBegin, nEnd, nRankBase, nIndexBase, fnProc) 
    local oSubTree = tNode.oSubTree
    local tSubNode = oSubTree:_get_node_by_index(nBegin)
    assert(tSubNode)

    for k = nBegin, nEnd do 
        local nRank = nRankBase + k - 1 
        local nIndex = nIndexBase  

        if tNode.nNodeIndexCount >= 2 then 
            if self.m_bIndexContinuous then 
                nIndex = nIndexBase + ((k - 1)//self.m_nMaxIndexDataCount)
            else
                nIndex = nIndexBase + ((k - 1)//self.m_nMaxIndexDataCount)*self.m_nMaxIndexDataCount
            end
        end

        if fnProc(nRank, nIndex, tSubNode.tData.nKey, tSubNode.tData.nKey) then 
            return true 
        end

        tSubNode = oSubTree:_get_next_node(tSubNode) 
        if not tSubNode then 
            return 
        end
    end 
end

--fnProc(nDataRank, nDataIndex, nKey, tData)
--fnProc返回true, 则停止迭代
function CMultiRBTree:TraverseByDataRank(nMin, nMax, fnProc) 
    assert(nMin and nMax and fnProc, "参数错误") 
    nMin = math.max(nMin, 1)
    if self:IsEmpty() or nMin > self:Count() then 
        return 
    end
    assert(nMin <= nMax)

    local nStartRank = nMin
    local nTailRank = nMax

    local tNode, nRankBegin, nIndexBegin = self:_get_node_by_data_rank(nStartRank)
    assert(tNode)
    while tNode and nRankBegin <= nTailRank do 
        local nRankEnd = nRankBegin + tNode.nNodeDataCount - 1 
        -- print(string.format("nRankBegin(%d), nRankEnd(%d)", nRankBegin, nRankEnd))
        if nRankBegin <= nStartRank then 
            local nSubRank = nStartRank - nRankBegin + 1
            local nSubRankEnd = math.min(tNode.oSubTree:Count(), nTailRank - nRankBegin + 1)
            if self:_traverse_node_by_data_rank(tNode, nSubRank, nSubRankEnd, nRankBegin, nIndexBegin, fnProc) then 
                return true 
            end
        elseif nRankEnd >= nTailRank then 
            local nSubRankEnd = math.min(tNode.oSubTree:Count(), nTailRank - nRankBegin + 1)
            if self:_traverse_node_by_data_rank(tNode, 1, nSubRankEnd, nRankBegin, nIndexBegin, fnProc) then 
                return true 
            end
        else
            if self:_traverse_node_by_data_rank(tNode, 1, tNode.oSubTree:Count(), nRankBegin, nIndexBegin, fnProc) then 
                return true 
            end
        end
        -- print(string.format("nRankBegin(%d),nRankEnd(%d),nIndexBegin(%d)", nRankBegin, nRankEnd, nIndexBegin))
        tNode, nRankBegin, nIndexBegin = self:_get_next_node_by_data_rank(tNode, nRankBegin, nIndexBegin)
    end
end

function CMultiRBTree:_debug_travel(tNode, nBlackCount, bPrint)
    tNode = tNode or self.m_tRoot
    nBlackCount = nBlackCount or 0
    if tNode.nColor == tNodeColor.eBlack then 
        nBlackCount = nBlackCount + 1 
    end
    if tNode ~= self.m_tNil then 
        assert(tNode.tLeft)
        self:_debug_travel(tNode.tLeft, nBlackCount) 

        local tLeft = tNode.tLeft
        local tRight = tNode.tRight
        local tParent = tNode.tParent

        assert(tNode.nColor, "结点颜色不存在")
        assert(tLeft.nColor, "左子节点颜色不存在")
        assert(tRight.nColor, "左子节点颜色不存在")
        assert(tParent.nColor, "父节点颜色不存在")
        if tNode.nColor == tNodeColor.eRed then 
            assert(tLeft.nColor == tNodeColor.eBlack, "左子节点颜色错误")
            assert(tRight.nColor == tNodeColor.eBlack, "右子节点颜色错误")
            assert(tParent.nColor == tNodeColor.eBlack, "父节点颜色错误")
        end
        assert(tNode ~= tLeft)
        assert(tNode ~= tRight)
        assert(tNode ~= tParent)
        if tLeft ~= self.m_tNil then 
            assert(tLeft ~= tRight)
            assert(tLeft ~= tParent)
        end
        if tRight ~= self.m_tNil then 
            assert(tRight ~= tLeft)
            assert(tRight ~= tParent)
        end
        if tParent ~= self.m_tNil then 
            assert(tParent ~= tLeft)
            assert(tParent ~= tRight)
        end 

        assert(tNode.nNodeDataCount > 0)
        assert(tNode.nTotalDataCount > 0)
        assert(tNode.nNodeIndexCount > 0)
        assert(tNode.nTotalIndexCount > 0)

        assert(tNode.nNodeDataCount == tNode.oSubTree:Count()) 
        assert(tNode.nTotalDataCount == 
            (tLeft.nTotalDataCount + tRight.nTotalDataCount + tNode.nNodeDataCount), "数据错误")
        assert(tNode.nTotalIndexCount == 
            (tLeft.nTotalIndexCount + tRight.nTotalIndexCount + tNode.nNodeIndexCount), "数据错误")

        if bPrint and (tLeft == self.m_tNil or tRight == self.m_tNil) then 
            print(string.format("当前路径黑色节点数量 %d", nBlackCount))
        end
        assert(tNode.tRight) 
        self:_debug_travel(tNode.tRight, nBlackCount)  
    end
end

function CMultiRBTree:DebugTravel(bPrint) 
    self:_debug_travel(nil, nil, bPrint)
end


function _MultiRBTreeTest() 
	local fnCmp = function(tDataL, tDataR) 
		if tDataL.nVal > tDataR.nVal then 
			return -1
		elseif tDataL.nVal == tDataR.nVal then 
			return 0
		else
			return 1
		end
	end

    print(">>>>>>>> MultiRBTree <<<<<<<<<")
    local oRBTree = CMultiRBTree:new(fnCmp, nil, false, 0)

    local nPreInsertNum = 100000
	for k = 300000, 300000 + nPreInsertNum - 1 do 
		local tData = {nVal = math.random(math.ceil(nPreInsertNum/2))}
		oRBTree:Insert(k, tData)
	end
	
	local nBeginTime = os.clock()
	local nInsertNum = 10000
	for k = 1, nInsertNum do 
		local tData = {nVal = math.random(math.ceil(nPreInsertNum/2))}
		oRBTree:Insert(k, tData)
		-- oRBTree:DebugTravel()
	end
	print(">>>>>>>> 插入完毕 <<<<<<<<<")
	local nInsertEndTime = os.clock()
	print(string.format("插入(%d)个元素，用时(%d)ms", 
		nInsertNum, math.ceil((nInsertEndTime - nBeginTime)*1000)))
	
	print(">>>>>>> 开始遍历检查 <<<<<<<<")
    oRBTree:DebugTravel()
    for k = 1, nInsertNum do 
		local nIndex = oRBTree:GetDataRank(k)
		local nKey = oRBTree:GetByDataRank(nIndex)
		assert(nKey == k, "索引数据计算错误")
    end
    
    print(">>>>>>> 开始迭代 <<<<<<<<")
    local nTraverseNum = oRBTree:MaxIndex()
    print("迭代Index值:", nTraverseNum)
    local nTraverseCount = 0
    local fnTraverse = function(nRank, nKey, tData) 
        -- print(nRank, nKey, tData)
        nTraverseCount = nTraverseCount + 1
        if nRank == nTraverseNum then 
            print(string.format("WOW!迭代最后一个Index, 共迭代(%d)个元素", nTraverseCount)) 
        end
    end
    local nTraverseBegin = os.clock()
    oRBTree:Traverse(1, nTraverseNum, fnTraverse)
    local nTraverseEnd = os.clock() 
    print(string.format("Traverse(%d)个元素，用时(%d)ms", 
        nTraverseCount, math.ceil((nTraverseEnd - nTraverseBegin)*1000)))
    
    print(">>>>>>> 开始按照数据索引迭代 <<<<<<<<")
    local nTraverseDataNum = oRBTree:Count()
    print("迭代Data值:", nTraverseDataNum)
    local nTraverseDataCount = 0
    local fnTraverseData = function(nRank, nIndex, nKey, tData) 
        -- print(nRank, nKey, tData)
        nTraverseDataCount = nTraverseDataCount + 1
        if nRank == nTraverseDataNum then 
            print(string.format("最后一个元素，索引(%d), 共迭代(%d)个元素", nIndex, nTraverseDataCount)) 
        end
    end

    local nTraverseDataBegin = os.clock()
    oRBTree:TraverseByDataRank(1, nTraverseDataNum, fnTraverseData)
    local nTraverseDataEnd = os.clock()
    print(string.format("迭代(%d)个元素，用时(%d)ms", 
        nTraverseDataCount, math.ceil((nTraverseDataEnd - nTraverseDataBegin)*1000)))

	print(">>>>>>> 开始查找Index <<<<<<<")
	local nIndexBeginTime = os.clock()
	for k = 1, nInsertNum do 
		local nIndex = oRBTree:GetDataRank(k)
	end
	local nIndexEndTime = os.clock() 
	print(string.format("索引(%d)个元素，用时(%d)ms", 
        nInsertNum, math.ceil((nIndexEndTime - nIndexBeginTime)*1000)))

	print(">>>>>>>> 开始删除 <<<<<<<<<")
	local nRemoveBeginTime = os.clock()
	for k = 1, nInsertNum do 
		oRBTree:Remove(k) 
	end
	print(">>>>>>>> 删除完毕 <<<<<<<<<")
	local nRemoveEndTime = os.clock()
	print(string.format("删除(%d)个元素，用时(%d)ms", 
		nInsertNum, math.ceil((nRemoveEndTime - nRemoveBeginTime)*1000)))
end

