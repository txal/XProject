--数据库管理模块
function CDBMgr:Ctor()
	self.m_tSSDBMap = {}	--{[serverid]={[name]=ssdb, ...}, ...}
end

function CDBMgr:Init()
	--清除旧数据
	self.m_tSSDBMap = {}

	--连接SSDB
	for sName, tConf in pairs(gtServerConf.tGameDB) do
		if sName == "user" then
			for _, tUserConf in ipairs(tConf) do
			    if not self.m_tSSDBMap[tUserConf.nServer] then
			    	self.m_tSSDBMap[tUserConf.nServer] = {}
			    end
			    if not self.m_tSSDBMap[tUserConf.nServer][sName] then
			    	self.m_tSSDBMap[tUserConf.nServer][sName] = {}
			    end

				local oSSDB = SSDBDriver:new()
				local bRes = oSSDB:Connect(tUserConf.sIP, tUserConf.nPort)
				assert(bRes, "连接SSDB失败:", tUserConf)
			    LuaTrace("连接SSDB成功:", tUserConf)

			    table.insert(self.m_tSSDBMap[tUserConf.nServer][sName], oSSDB)
			end

		else
		    if not self.m_tSSDBMap[tConf.nServer] then
		    	self.m_tSSDBMap[tConf.nServer] = {}
		    end

			local oSSDB = SSDBDriver:new()
			local bRes = oSSDB:Connect(tConf.sIP, tConf.nPort)
			assert(bRes, "连接SSDB失败:", tConf)
		    LuaTrace("连接SSDB成功:", tConf)

		    self.m_tSSDBMap[tConf.nServer][sName] = oSSDB
		end
	end
end

--通过SSDB名字取SSDB: 如果是玩家数据库，必须要传AccountID
function CDBMgr:GetSSDB(nServer, sDBName, nAccountID)
	assert(nServer and sDBName, "参数错误")
	if sDBName == "user" then
		assert(nAccountID, "参数错误")
		local tSSDBMap = assert(self.m_tSSDBMap[nServer], "服务器ID错误:"..nServer)
		return assert(tSSDBMap[sDBName][1], "找不到SSDB:"..nServer..":"..sDBName)

	else
		local tSSDBMap = assert(self.m_tSSDBMap[nServer], "服务器ID错误:"..nServer)
		return assert(tSSDBMap[sDBName], "找不到SSDB:"..nServer..":"..sDBName)
	end
end

goDBMgr = goDBMgr or CDBMgr:new()
