--RBTree
local table, string, math, os, pairs, ipairs, assert = table, string, math, os, pairs, ipairs, assert


local tNodeColor = {eRed = 0, eBlack = 1, }

--小于0，排前面
function CRBTree:Ctor(fnDataCmp) 
    assert(fnDataCmp) 
    --[[
    tNode = 
    {
        tParent = nil, 
        tLeft = nil,
        tRight = nil,
        nColor = Black or Red,
        tData = {nKey= , tData= , }
        nCount = 0,   --子树节点数量
    }
    ]]
    self.m_tNil = --哨兵节点，主要用于删除节点时，简化恢复红黑平衡的逻辑
    {
        tParent = nil, 
        tLeft = nil,
        tRight = nil,
        nColor = tNodeColor.eBlack,
        tData = nil, 
        nCount = 0,  --哨兵节点这个值一定要始终为0，非常重要，否则会引发很多计算错误
    }

    self.m_tRoot = self.m_tNil 
    self.m_fnDataCmp = fnDataCmp

    self.m_fnCmp = function(tDataL, tDataR) 
        --因为树节点旋转，会改变左右分布，所以，不允许出现相等，会导致查找等失败
        local nCmpResult = self.m_fnDataCmp(tDataL.tData, tDataR.tData)
        if 0 ~= nCmpResult then 
            return nCmpResult 
        end
        assert(tDataL.nKey ~= tDataR.nKey, "数据错误")
        return tDataL.nKey < tDataR.nKey and -1 or 1 
    end

    self.m_tDataMap = {}
end

--左旋
function CRBTree:_left_rotate(tNode)
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
    local nNewNodeCount = 1
    if tNode.tLeft ~= self.m_tNil then 
        nNewNodeCount = nNewNodeCount + tNode.tLeft.nCount
    end
    if tNode.tRight ~= self.m_tNil then 
        nNewNodeCount = nNewNodeCount + tNode.tRight.nCount
    end
    tNode.nCount = nNewNodeCount

    local nNewXCount = 1 + nNewNodeCount
    if x.tRight ~= self.m_tNil then 
        nNewXCount = nNewXCount + x.tRight.nCount
    end
    x.nCount = nNewXCount
end

--右旋
function CRBTree:_right_rotate(tNode) 
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
    local nNewNodeCount = 1
    if tNode.tLeft ~= self.m_tNil then 
        nNewNodeCount = nNewNodeCount + tNode.tLeft.nCount
    end
    if tNode.tRight ~= self.m_tNil then 
        nNewNodeCount = nNewNodeCount + tNode.tRight.nCount
    end
    tNode.nCount = nNewNodeCount

    local nNewXCount = 1 + nNewNodeCount
    if x.tLeft ~= self.m_tNil then 
        nNewXCount = nNewXCount + x.tLeft.nCount
    end
    x.nCount = nNewXCount
end

function CRBTree:_insert_fixup(tNode) --内部接口
    while tNode.tParent.nColor == tNodeColor.eRed do 
        --根节点永远是黑色，如果父节点是红色，则父父节点必然存在且为黑色
        if tNode.tParent == tNode.tParent.tParent.tLeft then 
            local x = tNode.tParent.tParent.tRight
            if x.nColor == tNodeColor.eRed then --case 1
                --这个判断分支，主要判断并转换tNode引用，从而将标记的需要进行再平衡的红色节点上移
                --父节点为红色，且父父节点的左节点也是红色，则可以变换父节点和父父节点的左节点的颜色
                --将父父节点标记为新的需要检查再平衡的红色节点，然后再一次在外层进入判断
                tNode.tParent.nColor = tNodeColor.eBlack
                x.nColor = tNodeColor.eBlack --如果x为红色，则x必然不为nil
                tNode.tParent.tParent.nColor = tNodeColor.eRed
                tNode = tNode.tParent.tParent
            else
                if tNode == tNode.tParent.tRight then --case 2
                    --这一步，实际是把红黑状态转变成下一处情况(case 3)
                    tNode = tNode.tParent
                    self:_left_rotate(tNode)
                end 
                --case 3
                --进入这里，则说明tNode父父节点的右子节点是黑色
                --tNode节点为红色, tNode父节点为红色, tNode父父节点为黑色
                tNode.tParent.nColor = tNodeColor.eBlack
                tNode.tParent.tParent.nColor = tNodeColor.eRed
                --因为前面已判定父父节点的右子树为黑色，所以右旋后必定满足红黑树定义
                self:_right_rotate(tNode.tParent.tParent) 
            end
        else --流程和上面父节点为父父节点左子树时类似
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
 
--插入
-- nKey，只要是可以用于table做键值的并且可进行比较大小的数据类型都可以做Key
-- 内部没做深拷贝，所以，外部不能继续持有并修改tData引用数据
function CRBTree:Insert(nKey, tData) 
    assert(nKey and tData)
    assert(not self.m_tDataMap[nKey], "重复插入"..nKey)

    local tContainer = {tData = tData, nKey = nKey}
    local tNode = 
        {
            tParent = self.m_tNil,
            tLeft = self.m_tNil,
            tRight = self.m_tNil,
            nColor = tNodeColor.eRed, 
            tData = tContainer, 
            nCount = 1,
        }
    
    local y = self.m_tNil 
    local x = self.m_tRoot
    while x ~= self.m_tNil do 
        y = x
        -- x.nCount = x.nCount + 1 --直接在插入时，修改父节点的树节点数量，可以提高效率
        if self.m_fnCmp(tContainer, x.tData) < 0 then 
            x = x.tLeft
        else
            x = x.tRight
        end
    end
    tNode.tParent = y
    if y == self.m_tNil then 
        self.m_tRoot = tNode
    elseif self.m_fnCmp(tContainer, y.tData) < 0 then 
        y.tLeft = tNode
    else
        y.tRight = tNode
    end 

    self.m_tDataMap[nKey] = tData --操作成功后，才加入到datamap
    --回溯修改父节点的树节点数量
    self:_count_fixup(tNode, self.m_tRoot) --开销稍微大一点点点，逻辑统一
    self:_insert_fixup(tNode)
end

function CRBTree:_minimum(tNode) 
    while tNode.tLeft ~= self.m_tNil do 
        tNode = tNode.tLeft
    end
    return tNode
end

function CRBTree:_maximum(tNode) 
    while tNode.tRight ~= self.m_tNil do 
        tNode = tNode.tRight
    end
    return tNode
end

function CRBTree:_count_fixup(tNode, tEndNode) 
    tEndNode = tEndNode or self.m_tRoot
    while tNode ~= self.m_tRoot do 
        if tNode == tNode.tParent.tLeft then 
            --如果tNode.tParent.tRigth为哨兵节点，nCount是0，不影响 
            tNode.tParent.nCount = 1 + tNode.nCount + tNode.tParent.tRight.nCount 
        else
            tNode.tParent.nCount = 1 + tNode.nCount + tNode.tParent.tLeft.nCount
        end
        tNode = tNode.tParent
        if tNode == tEndNode then 
            break 
        end
    end
end

function CRBTree:_trans_plant(tNode, tTarNode) 
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

function CRBTree:_search(nKey) 
    local tData = self.m_tDataMap[nKey]
    if not tData then 
        return 
    end
    local tContainer = {tData = tData, nKey = nKey}
    local x = self.m_tRoot
    while x ~= self.m_tNil and x.tData.nKey ~= nKey do 
        if self.m_fnCmp(tContainer, x.tData) < 0 then 
            x = x.tLeft 
        else
            x = x.tRight
        end
    end
    if x == self.m_tNil or x.tData.nKey ~= nKey then --不存在
        assert(false, "数据错误")
    end
    return x
end

function CRBTree:_delete_fixup(tNode) 
    while tNode ~= self.m_tRoot and tNode.nColor == tNodeColor.eBlack do 
        --因为tNode当前所占据位置为其原来的父节点所在位置，其原父节点确定为黑色才会进入此调用
        --故，其原来的父父节点(即现在的父节点)的另一子节点，必然存在且不为空，且子树中存在黑色节点
        --否则将不满足红黑性质，所以，下面的x对象必然存在，且不为空
        --因为tNode本身为黑色，为了满足红黑性质，其又继承了其原来的父节点的黑色，
        --所以一开始的tNode具有双重黑色，后续通过变换,tNode指向的对象，永远具有双重黑色或者红黑色
        --因为tNode为非根节点，故在循环中，其父节点，永远存在
        if tNode == tNode.tParent.tLeft then 
            local x = tNode.tParent.tRight  
            if x.nColor == tNodeColor.eRed then --case1 执行转换后，变成case 2、3、4的情况
                --根据前面的分析，如果x为红色，则x必然存在2个子树，且子树中分别存在至少一个黑色节点
                x.nColor = tNodeColor.eBlack
                tNode.tParent.nColor = tNodeColor.eRed
                self:_left_rotate(tNode.tParent)
                x = tNode.tParent.tRight --新的x为原x的左子节点，原x为红色，故新的x必然为黑色
            end 
            if x.tLeft.nColor == tNodeColor.eBlack and x.tRight.nColor == tNodeColor.eBlack then --case 2，左右皆黑
                x.nColor = tNodeColor.eRed
                tNode = tNode.tParent  --将tNode标识上移，新的tNode节点将具有红黑色或者双重黑色，
                                       --如果为红黑色外层跳出，直接改为黑色，调整红黑平衡结束
            else
                if x.tRight.nColor == tNodeColor.eBlack then --case 3, 左红右黑
                    x.tLeft.nColor = tNodeColor.eBlack
                    x.nColor = tNodeColor.eRed
                    self:_right_rotate(x) --变换颜色，右旋后，变为了case4的情况
                    x = tNode.tParent.tRight --新的x即原来的x的左节点，因为原来x的左节点是红色，故必然不为空
                    --因为原来的x的左节点为红色，故其左节点的子节点必然为黑色
                    --所以变换后，新的x节点为黑色，右节点为红色，左节点为黑色
                end
                --case 4，右节点红色，左节点颜色不确定
                --当前tNode的父节点，及x的左节点，颜色不确定
                x.nColor = tNode.tParent.nColor
                tNode.tParent.nColor = tNodeColor.eBlack
                x.tRight.nColor = tNodeColor.eBlack
                self:_left_rotate(tNode.tParent) --转换后，tNode的父节点部分比原来多出一个黑色，tNode原父节点的其他节点红黑色不变
                                               --故补偿了tNode节点继承的多出来的那个黑色，从而红黑平衡
                tNode = self.m_tRoot  --转换后，可能改变新的根节点，从而根节点颜色变化，tNode指向根节点，外层直接置黑即可
            end
        else --流程和上面类似
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
                x.tLeft.nColor = tNodeColor.eBlack  --[○･｀Д´･ ○]谁说动态语言省时间，我要打死他,这里写成tNode.eBlack，查了一整天BUG
                self:_right_rotate(tNode.tParent)
                tNode = self.m_tRoot
            end
        end
    end
    tNode.nColor = tNodeColor.eBlack
end

--删除
function CRBTree:Remove(nKey) 
    assert(nKey)
    if not self.m_tDataMap[nKey] then return end
    local tNode = self:_search(nKey)  --待删除节点
    assert(tNode, "数据错误") 

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
            x.nCount = 1 + x.tRight.nCount --这个值在_trans_plant中已被正确设置
            x.nCount = x.nCount + x.tLeft.nCount --x.tLeft == self.m_tNil, 这一步可以不处理的
            --x.tParent在后续_trans_plant中会先被设置，所以也不影响后续的_count_finxup处理
        end
        self:_trans_plant(tNode, x)
        x.tLeft = tNode.tLeft
        x.tLeft.tParent = x
        x.nColor = tNode.nColor
        self:_count_fixup(x.tLeft, self.m_tRoot)
    end

    self.m_tDataMap[nKey] = nil 
    if nDelColor == tNodeColor.eBlack then 
        self:_delete_fixup(tNextNode)
    end
end

--更新, 如果不存在，则插入
--内部没做深拷贝，所以，外部不能继续持有并修改tData引用数据
function CRBTree:Update(nKey, tData) 
    assert(nKey and tData)
    self:Remove(nKey) 
    self:Insert(nKey, tData)
end

function CRBTree:Count()
    return self.m_tRoot.nCount 
end

function CRBTree:IsEmpty() 
    return self.m_tRoot == self.m_tNil 
end

function CRBTree:MaxIndex() 
    return self:Count()
end

--返回所有数据的table, {key:data, ...} 
--为了避免大量数据时的开销，这个是内部数据的直接引用
--外层获取到该数据后，不能修改此数据值
--用于给外部进行存储等操作时使用的
function CRBTree:GetAllData()
    return self.m_tDataMap 
end

function CRBTree:IsExist(nKey) 
    return self.m_tDataMap[nKey] and true or false 
end

function CRBTree:GetDataByKey(nKey)
    return self.m_tDataMap[nKey] 
end

--获取索引(从1开始) --中序遍历顺序
--如果不存在，返回0
function CRBTree:GetIndex(nKey) 
    local tData = self.m_tDataMap[nKey]
    if not tData then 
        return 0
    end
    local tContainer = {tData = tData, nKey = nKey}
    local x = self.m_tRoot
    local nIndex = x.nCount - x.tRight.nCount
    while x ~= self.m_tNil and x.tData.nKey ~= nKey do 
        local nCmpResult = self.m_fnCmp(tContainer, x.tData)
        if nCmpResult < 0 then
            x = x.tLeft --除非出现数据逻辑错误，新的x必然不为nil
            nIndex = nIndex - 1 - x.tRight.nCount
        else
            x = x.tRight  --同上
            nIndex = nIndex + 1 + x.tLeft.nCount
        end
    end
    if x == self.m_tNil or x.tData.nKey ~= nKey then --不存在
        assert(false, "数据错误")
    end
    return nIndex
end

function CRBTree:_get_node_by_index(nIndex) 
    if nIndex <= 0 or nIndex > self:MaxIndex() or self.m_tRoot == self.m_tNil then 
        return 
    end
    local tNode = self.m_tRoot
    local nCurIndex = tNode.nCount - tNode.tRight.nCount
    
    while nCurIndex ~= nIndex and tNode ~= self.m_tNil do 
        if nIndex < nCurIndex then 
            tNode = tNode.tLeft
            nCurIndex = nCurIndex - 1 - tNode.tRight.nCount
        else
            tNode = tNode.tRight
            nCurIndex = nCurIndex + 1 + tNode.tLeft.nCount
        end
    end
    return tNode
end

--根据index返回nKey, tData, --中序遍历顺序
function CRBTree:GetByIndex(nIndex) 
    if nIndex <= 0 or nIndex > self:MaxIndex() or self.m_tRoot == self.m_tNil then 
        return 
    end
    local tNode = self:_get_node_by_index(nIndex)
    return tNode.tData.nKey, tNode.tData.tData
end

--获取排名，请使用GetIndex接口
--这个接口，只是提供部分数据交互使用的，比如分批有序给前端发送当前排行榜数据
function CRBTree:GetDataRank(nKey) --接口兼容
    return self:GetIndex(nKey)
end 

--获取排名，请使用GetIndex接口
--这个接口，只是提供部分数据交互使用的，比如分批有序给前端发送当前排行榜数据
--根据数据排序索引，获取数据 nKey, tData
function CRBTree:GetByDataRank(nRank) --接口兼容
    return self:GetByIndex(nRank)
end

--返回nil说明当前已经是这颗树最后一个节点
function CRBTree:_get_next_node(tNode) 
    if tNode == self.m_tNil then 
        return 
    end
    if tNode.tRight ~= self.m_tNil then 
        return self:_minimum(tNode.tRight) 
    end

    while tNode ~= self.m_tRoot do 
        if tNode == tNode.tParent.tRight then 
            tNode = tNode.tParent 
        else
            return tNode.tParent
        end
    end
    return 
end

--fnProc(nIndex, nKey, tData) 
--fnProc返回true则停止迭代(为了兼容SkipList特性)
function CRBTree:Traverse(nMin, nMax, fnProc) 
    assert(nMin and nMax and fnProc, "参数错误") 
    nMin = math.max(nMin, 1)
    if self:IsEmpty() or nMin > self:MaxIndex() then 
        return
    end
    assert(nMin <= nMax)
    local tNode = self:_get_node_by_index(nMin)
    assert(tNode)
    if fnProc(nMin, tNode.tData.nKey, tNode.tData.tData) then 
        return true
    end
    for k = 1, nMax - nMin do 
        tNode = self:_get_next_node(tNode)
        if tNode then 
            if fnProc(nMin + k, tNode.tData.nKey, tNode.tData.tData) then 
                return true
            end
        else
            break
        end
    end
end

--fnProc(nDataRank, nDataIndex, nKey, tData)
--fnProc返回true则停止迭代(行为和Traverse保持一致)
function CRBTree:TraverseByDataRank(nMin, nMax, fnProc) 
    assert(nMin and nMax and fnProc, "参数错误") 
    nMin = math.max(nMin, 1)
    if self:IsEmpty() or nMin > self:Count() then 
        return 
    end
    assert(nMin <= nMax)
    -- self:Traverse(nMin, nMax, fnProc)
    local tNode = self:_get_node_by_index(nMin)
    assert(tNode)
    if fnProc(nMin, nMin, tNode.tData.nKey, tNode.tData.tData) then 
        return true 
    end
    for k = 1, nMax - nMin do 
        tNode = self:_get_next_node(tNode)
        if tNode then 
            local nRank = nMin + k
            if fnProc(nRank, nRank, tNode.tData.nKey, tNode.tData.tData) then 
                return true 
            end
        else
            break
        end
    end
end

--查找满足不小于tData的节点数据索引最小值(即按照索引顺序第一个不小于tData的节点的索引)
--如果所有节点都小于tData，则返回0
function CRBTree:GetNotLessIndex(tData) 
    if self:Count() <= 0 then 
        return 0
    end
    local tTarNode = nil
    local nTarIndex = nil

    local x = self.m_tRoot
    local nIndex = x.nCount - x.tRight.nCount
    while x ~= self.m_tNil do 
        local nCmpResult = self.m_fnDataCmp(tData, x.tData.tData)
        if nCmpResult <= 0 then
            tTarNode = x
            nTarIndex = nIndex

            x = x.tLeft
            if x == self.m_tNil then 
                break 
            end 
            nIndex = nIndex - 1 - x.tRight.nCount
        else
            x = x.tRight 
            if x == self.m_tNil then 
                break 
            end 
            nIndex = nIndex + 1 + x.tLeft.nCount
        end
    end

    return nTarIndex or 0
end

--查找满足不大于tData的节点数据索引最大值(即按照索引顺序最后一个不大于tData的节点索引)
--如果所有节点都大于tData，则返回0
function CRBTree:GetNotGreaterIndex(tData) 
    if self:Count() <= 0 then 
        return 0
    end
    local tTarNode = nil
    local nTarIndex = nil

    local x = self.m_tRoot
    local nIndex = x.nCount - x.tRight.nCount
    while x ~= self.m_tNil do 
        local nCmpResult = self.m_fnDataCmp(tData, x.tData.tData)
        if nCmpResult < 0 then
            x = x.tLeft 
            if x == self.m_tNil then 
                break 
            end 
            nIndex = nIndex - 1 - x.tRight.nCount
        else
            tTarNode = x
            nTarIndex = nIndex

            x = x.tRight 
            if x == self.m_tNil then 
                break 
            end 
            nIndex = nIndex + 1 + x.tLeft.nCount
        end
    end

    return nTarIndex or 0
end

function CRBTree:_debug_travel(tNode, nBlackCount, bPrint)
    tNode = tNode or self.m_tRoot
    nBlackCount = nBlackCount or 0
    if tNode.nColor == tNodeColor.eBlack then 
        nBlackCount = nBlackCount + 1 
    end
    if tNode ~= self.m_tNil then 
        assert(tNode.tLeft)
        self:_debug_travel(tNode.tLeft, nBlackCount, bPrint) 

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

        if bPrint and (tLeft == self.m_tNil or tRight == self.m_tNil) then 
            print(string.format("当前路径黑色节点数量 %d", nBlackCount))
        end
        assert(tNode.tRight)
        self:_debug_travel(tNode.tRight, nBlackCount, bPrint) 
    end
end

function CRBTree:DebugTravel(bPrint) 
    self:_debug_travel(nil, nil, bPrint)
end

function _RBTreeTest() 
	local fnCmp = function(tDataL, tDataR) 
		if tDataL.nVal > tDataR.nVal then 
			return -1
		elseif tDataL.nVal == tDataR.nVal then 
			return 0
		else
			return 1
		end
	end

	print(">>>>>>>>> RBTree <<<<<<<<<<<")
	local oRBTree = CRBTree:new(fnCmp) 

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
		local nIndex = oRBTree:GetIndex(k)
		local nKey = oRBTree:GetByIndex(nIndex)
        assert(nKey == k, "索引数据计算错误")
    end
    
    print(">>>>>>> 开始迭代 <<<<<<<<")
    local nTraverseNum = oRBTree:MaxIndex()
    local nTraverseCount = 0
    local fnTraverse = function(nRank, nKey, tData) 
        -- print(nRank, nKey, tData)
        nTraverseCount = nTraverseCount + 1
        if nRank == nTraverseNum then 
            print(string.format("WOW!迭代结束, 共迭代(%d)个元素", nTraverseCount)) 
        end
    end
    local nTraverseBegin = os.clock()
    oRBTree:Traverse(1, nTraverseNum, fnTraverse)
    local nTraverseEnd = os.clock()
    print(string.format("Traverse(%d)个元素，用时(%d)ms", 
        nTraverseNum, math.ceil((nTraverseEnd - nTraverseBegin)*1000)))

	print(">>>>>>> 开始查找Index <<<<<<<")
	local nIndexBeginTime = os.clock()
	for k = 1, nInsertNum do 
		local nIndex = oRBTree:GetIndex(k)
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
