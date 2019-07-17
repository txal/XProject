--权重随机
local table, string, math, os, pairs, ipairs, assert = table, string, math, os, pairs, ipairs, assert

--以数据组的方式返回，不包含tSrc中元素的key, 返回值{index:value, ...}
function CWeightRandom:Random(tSrc, fnGetWeight, nNum, bUniq)
	local tResult = {} --随机的结果
	local nTotalWeight = 0
	local nNodeCount = 0
	local tNodeWeight = {}
	if nNum < 1 then
		return tResult
	end
	for key, tNode in pairs(tSrc) do
		local nNodeWeight = fnGetWeight(tNode)
		if nNodeWeight > 0 then --只处理权重为正的
			tNodeWeight[key] = nNodeWeight
			nTotalWeight = nTotalWeight + nNodeWeight
			nNodeCount = nNodeCount + 1
		end
	end
	if nNodeCount <= 0 or nTotalWeight <= 0 then
		return tResult
	end
	if bUniq and nNodeCount < nNum then 
		LuaTrace("请注意，随机数量少于获取数量", debug.traceback())
		nNum = nNodeCount
	end
	for i = 1, nNum do
		local nTarget = math.random(1, nTotalWeight)
		for key, nNodeWeight in pairs(tNodeWeight) do
			nTarget = nTarget - nNodeWeight
			if nTarget <= 0 then
				table.insert(tResult, tSrc[key])
				if bUniq then
					nTotalWeight = nTotalWeight - nNodeWeight
					tNodeWeight[key] = nil
				end
				break
			end
		end
	end
	return tResult
end

--[[ 
--以数据组的方式返回，不包含tSrc中元素的key, 返回值{index:value, ...}
@param  tSrc 输入数据table
@param  fnGetWeight  用于tbl的元素value中获取权重值的方法
@param  nNum  需要随机的数量
@param  bUniq  是否重复选取元素
@param  fnCheckValid  用于筛选tbl的元素是否参与到权重随机中
@param  tCheckParam  用于fnCheckValid的检查参数，如果fnCheckValid(tSrc[key], tCheckParam)返回true，则该节点有效
]]
function CWeightRandom:CheckNodeRandom(tSrc, fnGetWeight, nNum, bUniq, fnCheckValid, tCheckParam)
	local tResult = {} --随机的结果
	local nTotalWeight = 0
	local nNodeCount = 0
	local tNodeWeight = {}
	if not fnCheckValid then --没提供，为nil
		tResult = self:Random(tSrc, fnGetWeight, nNum, bUniq)
		return tResult
	end
	for key, tNode in pairs(tSrc) do
		if fnCheckValid(tNode, tCheckParam) then
			local nNodeWeight = fnGetWeight(tNode)
			if nNodeWeight > 0 then --只处理权重为正的
				tNodeWeight[key] = nNodeWeight
				nTotalWeight = nTotalWeight + nNodeWeight
				nNodeCount = nNodeCount + 1
			end
		end
	end
	if nNodeCount <= 0 or nTotalWeight <= 0 then
		return tResult
	end
	if bUniq and nNodeCount < nNum then 
		LuaTrace("请注意，随机数量少于获取数量", debug.traceback())
		nNum = nNodeCount
	end
	for i = 1, nNum do
		local nTarget = math.random(1, nTotalWeight)
		for key, nNodeWeight in pairs(tNodeWeight) do
			nTarget = nTarget - nNodeWeight
			if nTarget <= 0 then
				table.insert(tResult, tSrc[key])
				if bUniq then
					nTotalWeight = nTotalWeight - nNodeWeight
					tNodeWeight[key] = nil
				end
				break
			end
		end
	end
	return tResult
end

--返回值，将tSrc的输入包装{index:{key, value}, ...}
function CWeightRandom:RandomRetKey(tSrc, fnGetWeight, nNum, bUniq)
	local tResult = {} --随机的结果
	local nTotalWeight = 0
	local nNodeCount = 0
	local tNodeWeight = {}
	if nNum < 1 then
		return tResult
	end
	for key, tNode in pairs(tSrc) do
		local nNodeWeight = fnGetWeight(tNode)
		if nNodeWeight > 0 then --只处理权重为正的
			tNodeWeight[key] = nNodeWeight
			nTotalWeight = nTotalWeight + nNodeWeight
			nNodeCount = nNodeCount + 1
		end
	end
	if nNodeCount <= 0 or nTotalWeight <= 0 then
		return tResult
	end
	if bUniq and nNodeCount < nNum then 
		LuaTrace("请注意，随机数量少于获取数量", debug.traceback())
		nNum = nNodeCount
	end
	for i = 1, nNum do
		local nTarget = math.random(1, nTotalWeight)
		for key, nNodeWeight in pairs(tNodeWeight) do
			nTarget = nTarget - nNodeWeight
			if nTarget <= 0 then
				local tResultNode = {}
				tResultNode.key = key   --这里会动态构造key, value字段值，外部使用要注意
				tResultNode.value = tSrc[key]
				table.insert(tResult, tResultNode)
				if bUniq then
					nTotalWeight = nTotalWeight - nNodeWeight
					tNodeWeight[key] = nil
				end
				break
			end
		end
	end
	return tResult
end

--[[ 
返回值，将tSrc的输入包装{index:{key, value}, ...}
@param  tSrc 输入数据table
@param  fnGetWeight  用于tbl的元素value中获取权重值的方法
@param  nNum  需要随机的数量
@param  bUniq  是否重复选取元素
@param  fnCheckValid  用于筛选tbl的元素是否参与到权重随机中
@param  tCheckParam  用于fnCheckValid的检查参数，如果fnCheckValid(tSrc[key], tCheckParam)返回true，则该节点有效
]]
function CWeightRandom:CheckNodeRandomRetKey(tSrc, fnGetWeight, nNum, bUniq, fnCheckValid, tCheckParam)
	local tResult = {} --随机的结果
	local nTotalWeight = 0
	local nNodeCount = 0
	local tNodeWeight = {}
	if not fnCheckValid then --没提供，为nil
		tResult = self:Random(tSrc, fnGetWeight, nNum, bUniq)
		return tResult
	end
	for key, tNode in pairs(tSrc) do
		if fnCheckValid(tNode, tCheckParam) then
			local nNodeWeight = fnGetWeight(tNode)
			if nNodeWeight > 0 then  --只处理权重为正的
				tNodeWeight[key] = nNodeWeight
				nTotalWeight = nTotalWeight + nNodeWeight
				nNodeCount = nNodeCount + 1
			end
		end
	end
	if nNodeCount <= 0 or nTotalWeight <= 0 then
		return tResult
	end
	if bUniq and nNodeCount < nNum then 
		LuaTrace("请注意，随机数量少于获取数量", debug.traceback())
		nNum = nNodeCount
	end
	for i = 1, nNum do
		local nTarget = math.random(1, nTotalWeight)
		for key, nNodeWeight in pairs(tNodeWeight) do
			nTarget = nTarget - nNodeWeight
			if nTarget <= 0 then
				local tResultNode = {}
				tResultNode.key = key   --这里会动态构造key, value字段值，外部使用要注意
				tResultNode.value = tSrc[key]
				table.insert(tResult, tResultNode)
				if bUniq then
					nTotalWeight = nTotalWeight - nNodeWeight
					tNodeWeight[key] = nil
				end
				break
			end
		end
	end
	return tResult
end

--根据权重分割nTotalNum数值
--tKeyWeight {key:tNode, ...}
--返回值 {key:num, ...}  --只会返回划分数值大于0的key及划分数值
--这个函数会存在一个问题，单次随机，如果nTotalNum足够大，会出现浮动比较大的情况
--理论上,nTotalNum足够大时，随机结果分布应当和权重比例趋于一致
--所以，需要控制循环颗粒度划分
--允许的最大循环次数nMaxLoop(499)，即math.floor(nTotalNum/nSplitNum) <= nMaxLoop
--相对小细粒度分割大数值，多递归情况下，性能开销会比较大，尽量使主循环次数控制在200以内
function CWeightRandom:WeightSplit(tSrc, fnGetWeight, nTotalNum, nSplitNum)
	nSplitNum = nSplitNum or 1
	nSplitNum = math.floor(nSplitNum)
	assert(nSplitNum > 0)

	local nMaxLoop = 499
	local nMaxRemainLoop = 101
	
	local tResult = {}
	if nTotalNum <= 0 then 
		LuaTrace("请注意，nTotalNum小于1", debug.traceback())
		return tResult 
	end
	if nSplitNum > nTotalNum then 
		nSplitNum = nTotalNum
	end
	
	local nLoop = math.floor(nTotalNum / nSplitNum)
	if nLoop > nMaxLoop then 
		nSplitNum = math.ceil(nTotalNum / nMaxLoop)
		nLoop = math.floor(nTotalNum / nSplitNum)
	end

	local nRemain = nTotalNum - nLoop * nSplitNum
	for k = 1, nLoop do 
		local tTemp = CWeightRandom:RandomRetKey(tSrc, fnGetWeight, 1, false)
		if not tTemp or #tTemp < 1 then 
			return tResult
		end
		tResult[tTemp[1].key] = (tResult[tTemp[1].key] or 0) + 1
	end
	for k, nNum in pairs(tResult) do 
		tResult[k] = nNum * nSplitNum
	end

	if nRemain <= nMaxRemainLoop then 
		for k = 1, nRemain do 
			local tTemp = CWeightRandom:RandomRetKey(tSrc, fnGetWeight, 1, false)
			if not tTemp or #tTemp < 1 then 
				return tResult
			end
			tResult[tTemp[1].key] = (tResult[tTemp[1].key] or 0) + 1
		end
	else 
		--防止nSplitNum数值过大，导致nRemain数量非常大，递归处理下
		local nNestSplitNum = math.ceil(nRemain / nMaxRemainLoop)
		if nRemain > 10000 then 
			nNestSplitNum = nNestSplitNum * 10  --递归深度增加，迭代次数降低，测试可以有效提高计算速度
		end
		local tTempResult = CWeightRandom:WeightSplit(tSrc, fnGetWeight, nRemain, nNestSplitNum)
		for k, v in pairs(tTempResult) do 
			tResult[k] = (tResult[k] or 0) + v
		end
	end

	return tResult
end

