-------------只需要改这里-----------------
local groupID = 1				--跨服组ID
local serverList = {1}  		--服务器列表

local worldServerID =10000 		--世界服ID
local gamePrefix = "mengzhu" 	--Mysql数据库前缀
local innerServer = false 		--内服否

local localLanIP = "127.0.0.1" 		--本地服局域网IP
local worldLanIP = "127.0.0.1" 		--世界服局域网IP
local backLanIP = "127.0.0.1" 		--后台局域网IP 

local backDBName = gamePrefix.."_mgr" 	--后台数据库名字 
local backDBUser = "root" 				--后台数据库账号
local backDBPwd = "123456"				--后台数据库密码
local backDBPort = 3340 				--后台数据库端口

local logDBName = gamePrefix.."_s" 		--日志数据库前缀
local logDBUser = "root" 				--日志数据库账号
local logDBPwd = "123456" 				--日志数据库密码
local logDBPort = 3340 					--日志数据库端口

local dataPath = "../"
local worldPortBegin = 10002
local localPortBegin = 22000
----------------------------------------


local localAssist = 
[[

--取登录服ID
function gtServerConf:GetLoginService(nServer)
	local tService =self.tLoginService[1]
	assert(tService.nServer == nServer)
	return tService.nID
end

--取日志服ID
function gtServerConf:GetLogService(nServer)
	local tService = self.tLogService[1]
	assert(tService.nServer == nServer)
	return tService.nID
end

--取日志服列表
function gtServerConf:GetLogServiceList()
	return self.tLogService
end

--取逻辑服列表
function gtServerConf:GetLogicServiceList()
	local tList = {}
	for _,tConf in pairs(self.tLogicService) do
		table.insert(tList,tConf)
	end
	for _,tConf in pairs(gtWorldConf.tLogicService) do
		table.insert(tList,tConf)
	end
	return tList
end

--取[W]GLOBAL服务ID
function gtServerConf:GetGlobalService(nServer,nServiceID)
	assert(nServer and nServiceID,"参数错误")
	if nServer == gnServerID then
		for _,tConf in pairs(self.tGlobalService) do
			if tConf.nID == nServiceID then
				return tConf.nID
			end
		end
	end

	if nServer == gnWorldServerID then
		for _,tConf in pairs(gtWorldConf.tGlobalService) do
			if tConf.nID == nServiceID then
				return tConf.nID
			end
		end
	end
	assert(false,string.format("服务器:%d 全局服务:%d 不存在",nServer,nServiceID))
end

--取[W]GLOBAL服务列表
function gtServerConf:GetGlobalServiceList()
	local tGlobalServiceList = {}
	for _,tConf in pairs(self.tGlobalService) do
		table.insert(tGlobalServiceList,tConf)
	end
	for _,tConf in pairs(gtWorldConf.tGlobalService) do
		table.insert(tGlobalServiceList,tConf)
	end
	return tGlobalServiceList
end
]]


local worldAssist =
[[

--------------------------------------------辅助函数
--取登录服ID
function gtServerConf:GetLoginService(nServer)
	for _,tConf in pairs(self.tLoginService) do
		if tConf.nServer == nServer then
			return tConf.nID
		end
	end
end

--取日志服ID
function gtServerConf:GetLogService(nServer)
	for _,tConf in pairs(self.tLogService) do
		if tConf.nServer == nServer then
			return tConf.nID
		end
	end
end

--取日志服列表
function gtServerConf:GetLogServiceList()
	return self.tLogService
end

--取[W]GLOBAL服务ID
function gtServerConf:GetGlobalService(nServer,nServiceID)
	assert(nServer and nServiceID,"参数错误")
	for _,tConf in pairs(self.tGlobalService) do
		if tConf.nServer == nServer and tConf.nID == nServiceID then
			return tConf.nID
		end
	end
	assert(false,string.format("服务器:%d 全局服务:%d 不存在",nServer,nServiceID))
end

--取[W]GLOBAL服务列表
function gtServerConf:GetGlobalServiceList()
	return self.tGlobalService
end
]]

------------------------------------------------------
--起始端口号
local tmpPort = 0
--中心ID
local centerDB = {0,backLanIP,10001} --服务器ID,ip,端口
--后台
local background = {backLanIP,backDBPort,backDBName,backDBUser,backDBPwd} --ip,端口,名字,账号,密码
--路由服
local routerServer = {
	{1,worldLanIP,tmpPort}--服务ID,ip,端口
}
--世界服配置
local worldServer = {
	["global"]={{worldServerID,110,worldLanIP,tmpPort},{worldServerID,111,worldLanIP,tmpPort}},--服务器ID,服务ID,ip,端口
	["logicservice"]={{worldServerID,100},{worldServerID,101},{worldServerID,102}},--服务器ID,服务ID,
	["globalservice"]={{worldServerID,110,worldLanIP,tmpPort},{worldServerID,111,worldLanIP,tmpPort}}--服务器ID,服务ID,ip,端口
}
--本地服配置
local localServer = {
	["user"]={0,"127.0.0.1",tmpPort},--ip,端口
	["global"]={0,20,"127.0.0.1",tmpPort},--服务器ID,服务ID,ip,端口
	["logdb"]={"127.0.0.1",logDBPort,logDBName,logDBUser,logDBPwd},--ip,端口,名字,账号,密码
	["gateservice"]={{0,10,tmpPort,20000,120,300,60,120}},--服务器ID,服务ID,端口,最大连接数,安全连接/分钟,安全请求/分钟,阻塞秒数,死链秒数
	["globalservice"]={0,20,localLanIP,tmpPort},--服务器ID,服务ID,ip,端口
	["logservice"]={0,30,2},--服务器ID,服务ID,工作线程数
	["loginservice"]={0,40},--服务器ID,服务ID
	["logicservice"]={{0,50},{0,51},{0,52}}--服务器ID,服务ID
}
--本地服内嵌世界服配置
smallWorldServer = {
	["logicservice"]={{worldServerID,100},{worldServerID,101},{worldServerID,102}},--服务器ID,服务ID
	["globalservice"]={{worldServerID,110},{worldServerID,111}},--服务器ID,服务ID
}


----------------------------------------------------------

local function GenRouterServerConf()
	local server = {}
	server["gsDataPath"] = dataPath
	server["gnWorldServerID"] = worldServerID
	server["gtServerConf"] = {}
	server["gtServerConf"]["tRouterService"] = {}
	for k, v in ipairs(routerServer) do
		server["gtServerConf"]["tRouterService"][k] = {["nID"]=v[1],["sIP"]=v[2],["nPort"]=worldPortBegin}
		worldPortBegin = worldPortBegin + 1
	end
	return server
end

local function GenLocalServerConf(serverID, routerServerConf)
	local server = {}
	server["gsDataPath"] = dataPath
	server["gnGoupID"]=groupID
	server["gnServerID"]=serverID
	server["gnWorldServerID"]=worldServerID
	server["gsGamePrefix"]=gamePrefix
	server["gbInnerServer"]=innerServer
	server["gtServerConf"]={}
	server["gtServerConf"]["tRouterService"] = {}
	for k, v in ipairs(routerServerConf["gtServerConf"]["tRouterService"]) do
		server["gtServerConf"]["tRouterService"][k] = v
	end

	server["gtServerConf"]["tGameDB"] = {}
	server["gtServerConf"]["tGameDB"]["center"] = {["nServer"]=0,["sIP"]=centerDB[2],["nPort"]=centerDB[3]}

	userdb = localServer["user"]
	server["gtServerConf"]["tGameDB"]["user"] = {}
	server["gtServerConf"]["tGameDB"]["user"][1] = {["nServer"]=serverID,["sIP"]=userdb[2],["nPort"]=localPortBegin}
	localPortBegin = localPortBegin + 1

	globaldb = localServer["global"]
	server["gtServerConf"]["tGameDB"]["global"] = {}
	server["gtServerConf"]["tGameDB"]["global"][globaldb[2]] = {["nServer"]=serverID,["sIP"]=globaldb[3],["nPort"]=localPortBegin}
	localPortBegin = localPortBegin + 1

	logdb = localServer["logdb"]
	server["gtServerConf"]["tLogDB"] = {["sIP"]=logdb[1],["nPort"]=logdb[2],["sDBName"]=logdb[3]..serverID,["sUserName"]=logdb[4],["sPassword"]=logdb[5]}

	gatesv = localServer["gateservice"]
	server["gtServerConf"]["tGateService"] = {}
	for k, v in ipairs(gatesv) do
		server["gtServerConf"]["tGateService"][k] = {["nServer"]=serverID,["nID"]=v[2],["nPort"]=localPortBegin,["nMaxConns"]=v[4],nSecureCPM=v[5],["nSecureQPM"]=v[6],["nSecureBlock"]=v[7],["nDeadLinkTime"]=v[8]}
		localPortBegin = localPortBegin + 1
	end

	globalsv = localServer["globalservice"]
	server["gtServerConf"]["tGlobalService"] = {}
	server["gtServerConf"]["tGlobalService"][1] = {["nServer"]=serverID,["nID"]=globalsv[2],["sIP"]=globalsv[3],["nPort"]=localPortBegin}
	localPortBegin = localPortBegin + 1
	logsv = localServer["logservice"] 
	server["gtServerConf"]["tLogService"] = {}
	server["gtServerConf"]["tLogService"][1] = {["nServer"]=serverID,["nID"]=logsv[2],["nWorkers"]=logsv[3]}
	loginsv = localServer["loginservice"] 
	server["gtServerConf"]["tLoginService"] = {}
	server["gtServerConf"]["tLoginService"][1] = {["nServer"]=serverID,["nID"]=loginsv[2]}
	logicsv = localServer["logicservice"]
	server["gtServerConf"]["tLogicService"] = {}
	for k, v in ipairs(logicsv) do
		server["gtServerConf"]["tLogicService"][k] = {["nServer"]=serverID,["nID"]=v[2]}
	end

	server["gtWorldConf"] = {}
	server["gtWorldConf"]["tLogicService"] = {}

	wlogicsv = smallWorldServer["logicservice"]
	for k, v in ipairs(wlogicsv) do
		server["gtWorldConf"]["tLogicService"][k]={["nServer"]=worldServerID,["nID"]=v[2]}
	end
	server["gtWorldConf"]["tGlobalService"] = {}
	wglobalsv = smallWorldServer["globalservice"]
	for k, v in ipairs(wglobalsv) do
		server["gtWorldConf"]["tGlobalService"][k] = {["nServer"]=worldServerID,["nID"]=v[2]}
	end

	server["gtMgrMysqlConf"] = {["sIP"]=background[1],["nPort"]=background[2],["sDBName"]=background[3],["sUserName"]=background[4],["sPassword"]=background[5]}
	return server
end

local function GenWorldServerConf(localServerList, routerServerConf)
	local server = {}
	server["gsDataPath"] = dataPath
	server["gnGoupID"]=groupID
	server["gnServerID"]=worldServerID
	server["gnWorldServerID"]=worldServerID
	server["gsGamePrefix"]=gamePrefix
	server["gbInnerServer"]=innerServer

	server["gtServerConf"]={}
	server["gtServerConf"]["tRouterService"]={}
	for k, v in ipairs(routerServerConf["gtServerConf"]["tRouterService"]) do
		server["gtServerConf"]["tRouterService"][k] = v
	end

	server["gtServerConf"]["tGameDB"] = {}
	server["gtServerConf"]["tGameDB"]["center"] = {["nServer"]=0,["sIP"]=centerDB[2],["nPort"]=centerDB[3]}

	wglobaldb = worldServer["global"]
	server["gtServerConf"]["tGameDB"]["global"] = {}
	for _, v in pairs(wglobaldb) do
		server["gtServerConf"]["tGameDB"]["global"][v[2]] = {["nServer"]=worldServerID,["sIP"]=v[3],["nPort"]=worldPortBegin}
		worldPortBegin = worldPortBegin + 1
	end

	server["gtServerConf"]["tGameDB"]["user"] = {}
	for _, v1 in pairs(localServerList) do
		for _, v2 in ipairs(v1["gtServerConf"]["tGameDB"]["user"]) do
			table.insert(server["gtServerConf"]["tGameDB"]["user"], v2)
		end
	end

	wlogicsv = worldServer["logicservice"]
	server["gtServerConf"]["tLogicService"] = {}
	for k, v in ipairs(wlogicsv) do
		server["gtServerConf"]["tLogicService"][k] = {["nServer"]=v[1],["nID"]=v[2]}
	end

	wglobalsv = worldServer["globalservice"]
	server["gtServerConf"]["tGlobalService"] = {}
	for k, v in ipairs(wglobalsv) do
		server["gtServerConf"]["tGlobalService"][k] = {["nServer"]=v[1],["nID"]=v[2]}
	end

	for _, v1 in pairs(localServerList) do
		for _, v2 in ipairs(v1["gtServerConf"]["tGlobalService"]) do
			table.insert(server["gtServerConf"]["tGlobalService"], v2)
		end
	end

	server["gtServerConf"]["tGateService"] = {}
	server["gtServerConf"]["tLogService"] = {}
	server["gtServerConf"]["tLoginService"] = {}
	for _, v1 in pairs(localServerList) do
		for _, v2 in ipairs(v1["gtServerConf"]["tGateService"]) do
			table.insert(server["gtServerConf"]["tGateService"], v2)
		end
		for _, v2 in ipairs(v1["gtServerConf"]["tLogService"]) do
			table.insert(server["gtServerConf"]["tLogService"], v2)
		end
		for _, v2 in ipairs(v1["gtServerConf"]["tLoginService"]) do
			table.insert(server["gtServerConf"]["tLoginService"], v2)
		end
	end
	server["gtMgrMysqlConf"] = {["sIP"]=background[1],["nPort"]=background[2],["sDBName"]=background[3],["sUserName"]=background[4],["sPassword"]=background[5]}
	return server
end


--------------------------------------------------------
local function ToString(root)
	if not(type(root)=="table") then
		local sErr = "What you input is not a table: "..root
		return sErr
	else
		local paths = {}
		local type = type
		local pairs = pairs
		local print = print
		local srep = string.rep
		local tostring = tostring
		local tconcat = table.concat
		local tinsert = table.insert

		local name = "root"
		local space = bNotExpend and 0 or 2
		local newline = bNotExpend and "" or "\n"
		local function ttos(tb, indent, name)
			paths[tb] = name
			local chgs = {"{"}
			local comma = name == "root" and "" or ","
			for k,v in pairs(tb) do
				local key = tostring(k)
				--local head = "["..(type(k)=="string" and "\""..key.."\"" or key).."]="
				local head = (type(k)=="string" and key or ("["..key.."]")).."="
				if paths[v] then
					tinsert(chgs, head..paths[v]..comma)
				elseif type(v)=="table" then
					tinsert(chgs, head..ttos(v, indent+space, name..(type(k)=="string" and "."..key or "["..key.."]"))..comma)
				elseif type(v)=="string" then
					tinsert(chgs, head.."\""..v.."\""..comma)
				else
					tinsert(chgs, head..tostring(v)..comma)
				end
			end
			return tconcat(chgs, newline..srep(" ", indent+space))..newline..srep(" ", indent).."}"
		end
		local sTable = ttos(root, 0, name)
		return sTable
	end
end
function GenServerConf()
	if io.FileExist("window.txt") then
		os.execute("del /Q .\\serverconf\\*.lua")
		os.execute("mkdir .\\serverconf\\")
	else
		os.execute("rm -rf ./serverconf/*.lua")
		os.execute("mkdir -p ./serverconf/")
	end

	local routerServerConf = GenRouterServerConf()
	local file = io.open("./serverconf/ServerConf-router.lua", "w")	
	file:write(string.sub(ToString(routerServerConf), 2, -3))
	file:flush()
	file:close()

	local localServerList = {}
	for _, v in pairs(serverList) do
		localServerList[v] = GenLocalServerConf(v, routerServerConf)

		local file = io.open("./serverconf/ServerConf-local"..v..".lua", "w")	
		file:write(string.sub(ToString(localServerList[v]), 2, -3))
		file:write(localAssist)
		file:flush()
		file:close()
	end
	local worldServerConf = GenWorldServerConf(localServerList, routerServerConf)
	local file = io.open("./serverconf/ServerConf-world.lua", "w")	
	file:write(string.sub(ToString(worldServerConf), 2, -3))
	file:write(worldAssist)
	file:flush()
	file:close()
	LuaTrace("配置生成成功:", "./serverconf")
end
