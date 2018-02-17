--数据库管理模块
function CDBMgr:Ctor()
	self.m_tSSDBMap = {}	--{[serverid]={[name]=ssdb, ...}, ...}
end

function CDBMgr:Init()
	--清除旧数据
	self.m_tSSDBMap = {}

	--连接SSDB
	for sName, tConf in pairs(gtServerConf.tGameDB) do
		local oSSDB = SSDBDriver:new()
		local bRes = oSSDB:Connect(tConf.sIP, tConf.nPort)
		assert(bRes, "连接SSDB失败:", tConf)
	    LuaTrace("连接SSDB成功:", tConf)
	    if not self.m_tSSDBMap[tConf.nServer] then
	    	self.m_tSSDBMap[tConf.nServer] = {}
	    end
	    self.m_tSSDBMap[tConf.nServer][sName] = oSSDB
	end
end

--通过SSDB名字取SSDB: 如果是玩家数据库，必须要传AccountID
function CDBMgr:GetSSDB(nServer, sDBName, nAccountID)
	assert(nServer and sDBName, "参数错误")
	if string.find(sDBName, "user") then
		assert(nAccountID, "参数错误")
	end
	local tServerMap = assert(self.m_tSSDBMap[nServer], "服务器ID错误:"..nServer)
	return assert(tServerMap[sDBName], "找不到SSDB:"..nServer..":"..sDBName)
end

goDBMgr = goDBMgr or CDBMgr:new()
