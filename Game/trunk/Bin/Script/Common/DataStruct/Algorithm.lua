gtAlg = {}

function gtAlg.BinaryFind(t, v)
	assert(t and v)
	local min, max = 1, #t
	while true do
		local i = math.floor((min + max) / 2)
		if min >= max then
			local tmp = {}
			for k = i - 1, i + 1 do
				if t[k] then
					table.insert(tmp, {k, math.abs(v - t[k])})
				end
			end
			table.sort(tmp, function(t1, t2) return t1[2] < t2[2] end )
			return #tmp > 0 and tmp[1][1] or 0

		elseif t[i] <= v then
			min = i + 1

		elseif t[i] > v then                                                                                                                                                               
			max = i - 1    

		end 
	end
end