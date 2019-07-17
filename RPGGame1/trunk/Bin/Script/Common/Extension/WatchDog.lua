function CWatchDog:Ctor()
	self:Reset()
	self.m_filter = {}
end

function CWatchDog:Reset()
	self.m_tbmap = {}
	self.m_tbnode = {}
	setmetatable(self.m_tbmap, {__mode="k"})
    collectgarbage("collect")
end

function CWatchDog:Traverse(key, value, parent)
	if type(value) ~= "table" then
		return
	end
	if value == self.m_tbmap then
		return
	end
	if value == self.m_tbnode then
		return
	end
	if self.m_filter[value] then
		return
	end
	if string.find(key, "ct.*", 1) then
		return
	end
	if self.m_tbmap[value] then
		return
	end
	parent = parent or "root"
	self.m_tbmap[value] = true

	local mt = getmetatable(value)
	if mt then
		local name = string.format("%s.%s._mt_", parent, key)
		self:Traverse("_mt_", mt, name)
	end
	self.m_tbnode[parent] = (self.m_tbnode[parent] or 0) + 1

	for k, v in pairs(value) do
		if type(k) == "table" or type(k) == "function" then
		--情况很少,不处理
		end

		local stype = type(v)
		if stype == "table" then
			local name = string.format("%s.%s", parent, key)
			self:Traverse(k, v, name)

		elseif stype == "function" then
			local index = 1
			while true do
				local name,value = debug.getupvalue(v, index)
				if not name then
					break
				end

				index = index + 1
			    if not self.m_filter[name] then
    				if type(value) == "table" then
    					local name = string.format("%s.%s.upvalue(%s)", parent, key, k)
    					self:Traverse(name, value, name)
    				end
    			end
			end

		end
	end
end

function CWatchDog:DumpTable()
	LuaTrace("------dump table------")
	self:Reset()

	self:Traverse("_G", _G, nil)
	local tblist = {}
	for k, v in pairs(self.m_tbnode) do
		if v > 16 then
			table.insert(tblist, {k, v})
		end
	end
	local sfile = string.format("tabledump%d.txt", os.time())
	local ofile = io.open(sfile, "w")
	table.sort(tblist, function(t1, t2) return t1[2] > t2[2] end)
	for _, v in ipairs(tblist) do
		local str = string.format("%s\t%d\n", v[1], v[2])
		ofile:write(str)
	end
	ofile:close()

	self:Reset()
end
