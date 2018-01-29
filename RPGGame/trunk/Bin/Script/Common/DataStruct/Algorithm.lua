CAlg = {}

--二分查找
function CAlg:BinarySearch(tbl, fncomp, param)
	local low, high = 1, #tbl
	while low <= high do
		local mid = math.floor((low+high)/2)
		local res = fncomp(tbl[mid], param)
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