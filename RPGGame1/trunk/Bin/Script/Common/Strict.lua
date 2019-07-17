print(_G._VERSION)
local getinfo, error, rawset, rawget = debug.getinfo, error, rawset, rawget

function AddStrict(tTable)
	assert(type(tTable) == "table")

	local tMeta = getmetatable(tTable)
	if tMeta == nil then
		tMeta = {}
		setmetatable(tTable, tMeta) 
	end

	tMeta.__declared = {}

	local function what()
		local d = getinfo (3, "S")
		return d and d.what or "C" 
	end

	tMeta.__newindex = function(t, n, v)
		if not tMeta.__declared[n] then
			local w = what()
			if w ~= "main" and w ~= "C" then
				error("Assignment to undeclared variable '" .. n .. "'", 2)
			end 
			tMeta.__declared[n] = true
		end 
		rawset(t, n, v)
	end
		
	tMeta.__index = function (t, n)
		if not tMeta.__declared[n] and what() ~= "C" then
			error(string.format("Variable '%s' is not declared", n), 2)
		end 
		return rawget(t, n)
	end
end
