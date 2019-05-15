--排名功能



--fnCmp比较函数，必须填写，-1排前面，0排名相同，1排后面

--fnSecCmp,如果fnCmp比较值相等，即同排名的情况下，使用这个函数，
--比如在限定了同排名人数的最大值时，可以用这个确定排名的顺序，如果不提供，则默认比较key

--nMaxEqualRankCount, 同排名的最大人数，如果某个排名，总数量超过这个数，则自动排到后面的排名位置

--bRankContinuous 排名是否连续
--比如排名1位置上有3个数据，如果连续的，则后面的数据排名从2开始
--如果非连续的，则后续的数据排名从4开始 

--bNotEqual，优化参数用，如果确定不会存在同排名的情况，可以传true，即fnCmp结果必定不会等于0
--内部会根据这个参数，调整实现，同时会忽略fnSecCmp, bRankContinuous, nMaxEqualRankCount
function CRBRank:Ctor(fnCmp, fnSecCmp, bRankContinuous, nMaxEqualRankCount, bNotEqual)
    assert(fnCmp, "参数错误")
    self.m_bNotEqual = bNotEqual and true or false
    if self.m_bNotEqual then 
        self.m_oRankInst = CRBTree:new(fnCmp)
    else
        self.m_oRankInst = CMultiRBTree:new(fnCmp, fnSecCmp, bRankContinuous, nMaxEqualRankCount)
    end
end

--插入元素
--内部没做深拷贝，所以，外部不能继续持有并修改data引用数据
function CRBRank:Insert(key, data)
    return self.m_oRankInst:Insert(key, data)
end

--如果不存在，则插入新数据
--内部没做深拷贝，所以，外部不能继续持有并修改data引用数据
function CRBRank:Update(key, data)
    return self.m_oRankInst:Update(key, data)
end

--移除元素
function CRBRank:Remove(key) 
    return self.m_oRankInst:Remove(key)
end

--获取排名
function CRBRank:GetRank(key) 
    return self.m_oRankInst:GetIndex(key)
end

--获取排名
function CRBRank:GetRankByKey(key) --兼容skiplist接口
    return self:GetRank(key)
end

--获取排名数据
--如果bNotEqual不为true
--获取排名数据的所有值table
--返回值形式{key:data, ...}
--请注意，因为，同排名，如果排名是不连续的，则某些排名，实际是不存在的
--如果该排名无数据，则返回空表{}

--如果构造参数bNotEqual为true
--则表现行为和SkipList一致，直接返回 key, data 

--为了效率，返回的内部源数据的引用，不能修改返回数据，如果需要修改，外部自行深拷贝之后操作
--nRank取值范围 [1, self:MaxRank()]
function CRBRank:GetElementByRank(nRank) --兼容skiplist接口
    return self.m_oRankInst:GetByIndex(nRank) 
end

--获取数据的索引，注意，这个不是排名
--这个接口，只是提供部分数据交互使用的，比如分批有序给前端发送当前排行榜数据
--每个数据，都有一个唯一的排序索引
--即使在同排名的情况下，也方便直接获取指定数据
--为了效率，返回的内部源数据的引用，不能修改返回数据，如果需要修改，外部自行深拷贝之后操作
function CRBRank:GetDataIndex(key)
    return self.m_oRankInst:GetDataRank(key)
end

--获取数据索引获取数据，注意，这个不是排名
--这个接口，只是提供部分数据交互使用的，比如分批有序给前端发送当前排行榜数据
--每个数据，都有一个唯一的排序索引
--即使在同排名的情况下，也方便直接获取指定数据
--返回 key, data
--为了效率，返回的内部源数据的引用，不能修改返回数据，如果需要修改，外部自行深拷贝之后操作
--nIndex取值范围[1, self:Count()]
function CRBRank:GetDataByDataIndex(nIndex)
    return self.m_oRankInst:GetByDataRank(nIndex)
end

--迭代指定排名区间的数据
--fnProc(nRank, key, data)
--fnProc返回true, 则停止迭代
--nMin必须在 [1, self:MaxRank()]之间且 nMin <= nMax
function CRBRank:Traverse(nMin, nMax, fnProc)  --兼容skiplist
    return self.m_oRankInst:Traverse(nMin, nMax, fnProc)
end

--迭代指定数据索引区间的数据
--fnProc(nDataIndex, nRank, key, data)
--fnProc返回true, 则停止迭代
--nMin必须在 [1, self:Count()]之间且 nMin <= nMax
function CRBRank:TraverseByDataIndex(nMin, nMax, fnProc) 
    return self.m_oRankInst:TraverseByDataRank(nMin, nMax, fnProc)
end

--获取当前排行榜的最大排名数值
function CRBRank:MaxRank()
    return self.m_oRankInst:MaxIndex()
end

--获取当前排行榜的数据数量
function CRBRank:Count() 
    return self.m_oRankInst:Count()
end

function CRBRank:GetCount() --兼容SkipList接口 
    return self:Count()
end

function CRBRank:IsEmpty() 
    return self.m_oRankInst:IsEmpty()
end

--key值是否已存在排行榜中
function CRBRank:IsExist(key) 
    return self.m_oRankInst:IsExist(key)
end

--获取存储在排行榜中的数据
--返回的内部数据，外层获取到该数据后，不能修改此数据值
function CRBRank:GetDataByKey(key)
    return self.m_oRankInst:GetDataByKey(key)
end

--返回该排行榜的所有数据 {key:data, ...}
--为了避免大量数据时的开销，这个是内部数据的直接引用
--外层获取到该数据后，不能修改此数据值
function CRBRank:GetAllData() 
    return self.m_oRankInst:GetAllData()
end

--测试用，检查数据正确性，实际业务代码中，请勿使用
function CRBRank:DebugTravel(bPrint) 
    return self.m_oRankInst:DebugTravel(bPrint)
end


function _RBRankTest() 
	local fnCmp = function(tDataL, tDataR) 
		if tDataL.nVal > tDataR.nVal then 
			return -1
		elseif tDataL.nVal == tDataR.nVal then 
			return 0
		else
			return 1
		end
	end

    print(">>>>>>>>> RBRank <<<<<<<<<<<")
    local bNotEqual = false
	local oRBRank = CRBRank:new(fnCmp, nil, false, 3, bNotEqual) 

	for k = 300000, 399999 do 
		local tData = {nVal = math.random(math.ceil(100000/2))}
		oRBRank:Insert(k, tData)
	end
	
	local nBeginTime = os.clock()
	local nInsertNum = 10000
	for k = 1, nInsertNum do 
		local tData = {nVal = math.random(math.ceil(100000/2))}
		oRBRank:Insert(k, tData)
    end
    print(">>>>>>>> 插入完毕 <<<<<<<<<")
	local nInsertEndTime = os.clock()
	print(string.format("插入(%d)个素，用时(%d)ms", 
		nInsertNum, math.ceil((nInsertEndTime - nBeginTime)*1000)))
    
    -- for k = 1, 100 do 
    --     print(oRBRank:GetElementByRank(k))
    -- end
	
	print(">>>>>>> 开始遍历检查 <<<<<<<<")
    oRBRank:DebugTravel()
    for k = 1, nInsertNum do 
        local nIndex = oRBRank:GetRank(k)
        if bNotEqual then 
            local nKey = oRBRank:GetElementByRank(nIndex)
            assert(nKey == k, "索引数据计算错误")
        else
            local tRankData = oRBRank:GetElementByRank(nIndex) 
            assert(tRankData[k], "索引数据计算错误")
            local nDataIndex = oRBRank:GetDataIndex(k)
            local nKey = oRBRank:GetDataByDataIndex(nDataIndex)
            assert(nKey == k, "索引数据计算错误")
        end
	end

	print(">>>>>>> 开始查找Index <<<<<<<")
	local nIndexBeginTime = os.clock()
	for k = 1, nInsertNum do 
		local nIndex = oRBRank:GetRank(k)
	end
	local nIndexEndTime = os.clock() 
	print(string.format("索引(%d)个素，用时(%d)ms", 
		nInsertNum, math.ceil((nIndexEndTime - nIndexBeginTime)*1000)))

	print(">>>>>>>> 开始删除 <<<<<<<<<")
	local nRemoveBeginTime = os.clock()
	for k = 1, nInsertNum do 
		oRBRank:Remove(k) 
	end
	print(">>>>>>>> 删除完毕 <<<<<<<<<")
	local nRemoveEndTime = os.clock()
	print(string.format("删除(%d)个元素，用时(%d)ms", 
		nInsertNum, math.ceil((nRemoveEndTime - nRemoveBeginTime)*1000)))
end

