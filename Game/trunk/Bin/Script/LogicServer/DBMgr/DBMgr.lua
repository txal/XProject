--数据库管理模块--
local sPlayerDBMap = "PlayerDBMap" --玩家SSDB管理(Center)

function CDBMgr:Ctor()
	self.m_tSSDBMap = {}	--{[name]=ssdb, ...}
	self.m_tGameSSDBList = {}
	self.m_tRoomSSDBList = {}
end

function CDBMgr:Init()
	--清除旧数据
	self.m_tSSDBMap = {}
	self.m_tGameSSDBList = {}
	self.m_tRoomSSDBList = {}

	--连接SSDB
	for _, db in pairs(gtSSDBConf) do

		local oSSDB = SSDBDriver:new()
		local bRes = oSSDB:Connect(db.sIP, db.nPort)
		assert(bRes, "连接SSDB:"..table.ToString(db, true).."失败")
	    LuaTrace("连接SSDB:"..table.ToString(db, true).."成功")

	    self.m_tSSDBMap[db.sName] = oSSDB
	    if db.bPlayer then
		    table.insert(self.m_tGameSSDBList, {db.sName, oSSDB})
		elseif db.bRoom then
		    table.insert(self.m_tRoomSSDBList, {db.sName, oSSDB})
		end
	end
	assert(#self.m_tGameSSDBList > 0, "至少需要1个玩家SSDB")
end

--通过SSDB名字取SSDB
function CDBMgr:GetSSDBByName(sDBName)
	return assert(self.m_tSSDBMap[sDBName], "找不到SSDB:"..sDBName)
end

--通过角色ID取SSDB
function CDBMgr:GetSSDBByCharID(nCharID)
	local oCenterDB = self:GetSSDBByName("Center")
	local sData = oCenterDB:HGet(sPlayerDBMap, nCharID)
	if sData ~= "" then
		local sDBName = cjson.decode(sData).sDBName
		return self.m_tSSDBMap[sDBName], sDBName
	end
	local sDBName = self:_RandomGameSSDB()
	local sData = cjson.encode({sDBName=sDBName})
	oCenterDB:HSet(sPlayerDBMap, nCharID, sData)
	return self.m_tSSDBMap[sDBName], sDBName
end

--通过房间号取SSDB
function CDBMgr:GetSSDBByRoomID(nRoomID)
	return self.m_tSSDBMap["Room1"]
end

--随意玩家SSDB
function CDBMgr:_RandomGameSSDB()
	assert(#self.m_tGameSSDBList > 0, "数据库管理器没有初始化")
	local nRnd = math.random(1, #self.m_tGameSSDBList)
	local tDB = self.m_tGameSSDBList[nRnd]
	return tDB[1]
end


goDBMgr = goDBMgr or CDBMgr:new()