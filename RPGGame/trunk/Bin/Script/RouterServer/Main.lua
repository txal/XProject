cjson_raw.encode_sparse_array(true, 1, 1) --稀疏表转换成对象

--Common script
require = gfRawRequire or require  --恢复原生require
require("Config/Main")
require("Common/CommonInc")

--LogServer script
gfRawRequire = require 	--hook require
require = function(sScript)
	gfRawRequire("RouterServer/"..sScript)
end
require("GMMgr/GMMgrInc")
require("MainRpc")

function Main()
    collectgarbage("setpause", 150)
    collectgarbage("setstepmul", 300)
    collectgarbage()
    LuaTrace("启动 RouterServer 完成******")
    -- http.Request("POST", "http://watcher.hoodinn.com/api/sign")
end

--是否开放汇报
local bOpenReport = false

--服务名字
local tServiceType = 
{
	[1] = "gate",
	[2] = "login",
	[3] = "log",
	[4] = "logic",
	[5] = "global",
}

local project = "梦幻诛仙"
local system = "centos6.5"
local service = "%d服-%s%d"
gtTokenMap = gtTokenMap or {}

--注册
local sSigntURL = "http://watcher.hoodinn.com/api/sign?project=%s&system=%s&service=%s" 
function OnServiceReg(nServer, nService, nServiceType)
	if not bOpenReport then
		return
	end

	local sService = string.format(service, nServer, tServiceType[nServiceType], nService)
	local sSign = string.format(sSigntURL, project, system, sService)

	LuaTrace("sign:", sSign)
	http.Request("GET", sSign, nil, function(sRet)
		local tRet = sRet=="" and "" or cjson_raw.decode(sRet)
		LuaTrace("sign ret:", tRet)
		if tRet["code"] == 1 then
			local token = tRet["data"]["token"]
			gtTokenMap[nServer.."_"..nService] = token
		end
	end)
end

--汇报
local sReportURL = "http://watcher.hoodinn.com/api/report?token=%s&status=%d"
function OnServiceReport(nServer, nService, nServiceType, nStatus)
	if not bOpenReport then
		return
	end

	local sToken = gtTokenMap[nServer.."_"..nService]
	if not sToken then
		return LuaTrace(nServer.."_"..nService, "token is nil")
	end

	nStatus = nStatus or 1
	local sReport = string.format(sReportURL, sToken, nStatus)
	LuaTrace("report:", sReport)

	http.Request("GET", sReport, nil, function(sRet)
		LuaTrace("report ret:", sRet=="" and "" or cjson_raw.decode(sRet))
	end)
end

--退出
local sSignOutURL = "http://watcher.hoodinn.com/api/signOut?token=%s"
function OnServiceClose(nServer, nService, nServiceType, bNormal)
	if not bOpenReport then
		return
	end
	
	local sSignOut = string.format(sSignOutURL, gtTokenMap[nServer.."_"..nService])
	if bNormal then
		LuaTrace("signout:", sSignOut)
		http.Request("GET", sSignOut, nil, function(sRet)
			LuaTrace("signout ret:", sRet=="" and "" or cjson_raw.decode(sRet))
		end)
	else
		OnServiceReport(nServer, nService, nServiceType, 2)
	end
end
