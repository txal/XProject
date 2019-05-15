--后台定制配置表管理器
local table, string, math, os, pairs, ipairs, assert = table, string, math, os, pairs, ipairs, assert

function CBackstage:Ctor()
end

--@nServer 服务器ID,不支持世界服
--@nFuncID 功能ID BackstageDef.lua
function CBackstage:GetConf(nServer, nFuncID)
	--assert(nServer < gnWorldServerID, "目前不支持世界服配置")
	local tAct = gtBackstageDef[nFuncID]
	assert(tAct, "活动不存在:"..nFuncID)

	local oDB = goDBMgr:GetSSDB(0, "center")
	local nGroupID = goServerMgr:GetGroupID()
	local sKey = string.format("%s_%s_%s",nGroupID,nServer,nFuncID)
	local sData = oDB:HGet(gtDBDef.sBackstageDB,sKey)
	if sData == "" then
		return _G[tAct.sConf]
	end
	return cjson_raw.decode(sData)
end

function CBackstage:SetConf(nServer, nFuncID, tConf)
	--assert(nServer < gnWorldServerID, "目前不支持世界服配置")
	assert(gtBackstageDef[nFuncID], "活动不存在:"..nFuncID)
	local oDB = goDBMgr:GetSSDB(0, "center")
	local nGroupID = goServerMgr:GetGroupID()
	local sKey = string.format("%s_%s_%s",nGroupID,nServer,nFuncID)
	if not tConf then
		oDB:HDel(gtDBDef.sBackstageDB, sKey)
	else
		oDB:HSet(gtDBDef.sBackstageDB, sKey, cjson_raw.encode(tConf))
	end
end

goBackstage = goBackstage or CBackstage:new()