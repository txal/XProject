--二分查找
local table, string, math, os, pairs, ipairs, assert = table, string, math, os, pairs, ipairs, assert

--精确查找,找不到返回0
function CBinarySearch:Search(tbl, fnComp, param)
	local low, high = 1, #tbl
	local mid = 0
	while low <= high do
		mid = math.floor((low+high)/2)
		local res = fnComp(tbl[mid], param)
		if res > 0 then --tbl[mid] > param 
		    high = mid - 1

		elseif res < 0 then --tbl[mid] < param
			low = mid + 1

		else --tbl[mid] == param
		    return mid
		end
	end
	return 0
end

--模糊查找,找不到返回最后二分位置
function CBinarySearch:NearSearch(tbl, fnComp, param)
	local low, high = 1, #tbl
	local mid = 0
	while low <= high do
		mid = math.floor((low+high)/2)
		local res = fnComp(tbl[mid], param)
		if res > 0 then --tbl[mid] > param 
		    high = mid - 1

		elseif res < 0 then --tbl[mid] < param
			low = mid + 1

		else --tbl[mid] == param
		    return mid
		end
	end
	return mid
end