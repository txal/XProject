--GM指令
local table, string, math, os, pairs, ipairs, assert = table, string, math, os, pairs, ipairs, assert

local nServerID = gnServerID
function CGMMgr:Ctor()
end

--收到GM指令
function CGMMgr:OnGMCmdReq(nServer, nService, nSession, sCmd)
	local tArgs = string.Split(sCmd, ' ')
	local sCmdName = assert(tArgs[1])

	local oRole = goGPlayerMgr:GetRoleBySS(nServer, nSession)
	local nRoleID, sRoleName, sAccount = 0, "", ""
	if oRole then
		nRoleID, sRoleName, sAccount = oRole:GetID(), oRole:GetName(), oRole:GetAccountName()
	end

	local sInfo = string.format("执行指令:%s [roleid:%d,rolename:%s,account:%s]", sCmd, nRoleID, sRoleName, sAccount)
	LuaTrace(sInfo)

	local oFunc = CGMMgr[sCmdName]
	local oFunc = assert(CGMMgr[sCmdName], "找不到指令:["..sCmdName.."]")
	table.remove(tArgs, 1)
	return oFunc(self, nServer, nService, nSession, tArgs)
end

-----------------指令列表-----------------
-- 测试逻辑
CGMMgr["test"] = function(self, nServer, nService, nSession, tArgs)
	local oRole = goGPlayerMgr:GetRoleBySS(nServer, nSession)
	if not oRole then return end
end

--重载脚本
CGMMgr["reload"] = function(self, nServer, nService, nSession, tArgs, nExtData)
	local sScript = tArgs[1] or ""
	local bRes, sTips = false, ""
	if sScript == "" then
		bRes = gfReloadAll("WGlobalServer2")
		sTips = "重载所有脚本 "..(bRes and "成功!" or "失败!")
	else
		bRes = gfReloadScript(sScript, "WGlobalServer2")
		sTips = "重载 '"..sScript.."' ".. (bRes and "成功!" or "失败!")
	end
	LuaTrace(sTips)
	CGRole:Tips("世界全局2 "..sTips, nExtData or 0, nSession)
	return bRes
end

--添加友好度
CGMMgr["addfriendhoney"] = function(self, nServer, nService, nSession, tArgs)
	local oRole = goGPlayerMgr:GetRoleBySS(nServer, nSession)
	if not oRole then return end
	local nTarRoleID, nDegrees = tonumber(tArgs[1]), tonumber(tArgs[2])
	goFriendMgr:GMAddDegrees(oRole, nTarRoleID, nDegrees)
end

--赠送
CGMMgr["Gift"] = function(self, nServer, nService, nSession, tArgs)
	-- local oRole = goGPlayerMgr:GetRoleBySS(nServer, nSession)
	-- if not oRole then return end
	-- local nTarRoleID = tonumber(tArgs[1])
	-- local nPropID = tonumber(tArgs[2])
	-- local nGriID = tonumber(tArgs[3])
	-- local nNum =  tonumber(tArgs[4])
	-- local nType = tonumber(tArgs[5])
	-- goCGiftMgr:GiftPropReq(oRole,nTarRoleID, nPropID, nGriID, nNum, nType)
end

CGMMgr["house"] = function (self,nServer,nService,nSession,tArgs)
	print("----------hcdebug*----------------",tArgs)
	local oRole = goGPlayerMgr:GetRoleBySS(nServer, nSession)
	if not oRole then return end
	local nOperate = tonumber(tArgs[1])
	local nRoleID = oRole:GetID()
	if nOperate == 1 then
		if #tArgs > 1 then
			nRoleID = tonumber(tArgs[2])
		end
		local tData = {
			nRoleID = nRoleID
		}
		goHouseMgr:EnterHouse(oRole,tData)
	elseif nOperate == 2 then
		if #tArgs > 0 then
			nRoleID = tArgs[1]
		end
		local tData = {
			nRoleID = nRoleID
		}
		goHouseMgr:LeaveHouse(oRole,tData)
	elseif nOperate ==3 then
		local oHouse = goHouseMgr:GetHouse(nRoleID)
		local nBoxCnt = tArgs[2] or 1
		oHouse:BuyBox(nBoxCnt)
	elseif nOperate == 4 then
		local oHouse = goHouseMgr:GetHouse(nRoleID)
		oHouse:HouseVisiterReq()
	elseif nOperate == 5 then
		local oHouse = goHouseMgr:GetHouse(nRoleID)
		oHouse:GiftInfoReq()
	elseif nOperate == 6 then
		local nRoleID = tonumber(tArgs[2])
		local oHouse = goHouseMgr:GetHouse(nRoleID)
		local nPropID = tonumber(tArgs[3])
		local nAmount = tonumber(tArgs[4])
		local sMsg = tonumber(tArgs[5])
		local bMoneyAdd = true
		local oHouse = goHouseMgr:GetHouse(nRoleID)
		oHouse:GiveGiftReq(oRole,nPropID,nAmount,sMsg,bMoneyAdd)
	elseif nOperate == 10 then
		local oHouse = goHouseMgr:GetHouse(nRoleID)
		local nPos = tonumber(tArgs[2])
		oHouse:PosFurnitureReq(nPos)
	elseif nOperate == 11 then
		local oHouse = goHouseMgr:GetHouse(nRoleID)
		local nFurnitureID = tonumber(tArgs[2])
		oHouse:UnLockFurniture(nFurnitureID)
	elseif nOperate == 12 then
		local oHouse = goHouseMgr:GetHouse(nRoleID)
		local nPos = tonumber(tArgs[2])
		local nFurnitureID = tonumber(tArgs[3])
		oHouse:WieldFurniture(nPos,nFurnitureID)
	elseif nOperate == 13 then
		local oHouse = goHouseMgr:GetHouse(nRoleID)
		local nPage = 1
		if #tArgs > 1 then
			nPage = tArgs[2]
		end
		oHouse:HouseMessageReq(nPage)
	elseif nOperate == 14 then
		local sMsg = "aaaaaaaaaaaa-bbbbbbbbbb"
		if #tArgs > 1 then
			nRoleID = tonumber(tArgs[2])
		end
		local oHouse = goHouseMgr:GetHouse(nRoleID)
		oHouse:AddMessage(oRole,sMsg)
	elseif nOperate == 15 then
		local oHouse = goHouseMgr:GetHouse(nRoleID)
		local nMessageID = tonumber(tArgs[2])
		oHouse:DeleteMessage(nMessageID)

	elseif nOperate == 16 then
		local oHouse = goHouseMgr:GetHouse(nRoleID)
		local sPhotoKey = "asdfasdfasdfasdfasdf"
		oHouse:SetPhotoKey(sPhotoKey)

	elseif nOperate == 20 then
		local tData = {
			nRoleID = tonumber(tArgs[2])
		}
		goHouseMgr:HouseWaterPlantReq(oRole,tData)
	elseif nOperate == 21 then
		local oHouse = goHouseMgr:GetHouse(nRoleID)
		oHouse:OpenPlantGiftInterface(oRole)
	elseif nOperate == 22 then
		local oHouse = goHouseMgr:GetHouse(nRoleID)
		oHouse:PlantChangePartner(oRole)
	elseif nOperate == 23 then
		local oHouse = goHouseMgr:GetHouse(nRoleID)
		oHouse:PlantGiveGift(oRole)
	elseif nOperate == 24 then
		local oHouse = goHouseMgr:GetHouse(nRoleID)
		oHouse:PlantReceiveReward(oRole)

	elseif nOperate == 100 then
		local nPage = tonumber(tArgs[2])
		local oHouse = goHouseMgr:GetHouse(nTargetRoleID)
		oHouse:DymaicDataReq(oRole,nPage)
	elseif nOperate == 101 then
		local tData = {
			sMsg = tArgs[2],
			tPhotoKey = tArgs[3] or {}
		}
		local oHouse = goHouseMgr:GetHouse(oRole:GetID())
		oHouse:AddDynamic(oRole,tData)
	elseif nOperate == 102 then
		local nTargetRoleID = tonumber(tArgs[2])
		local nDynamicID = tonumber(tArgs[3])
		local nTargetCommentID = tonumber(tArgs[4] or 0)
		local sMsg = tArgs[5]
		goHouseMgr:DynamicPublicCommentReq(oRole,nTargetRoleID,nDynamicID,nTargetCommentID,sMsg)
	elseif nOperate == 103 then
		local nTargetRoleID = tonumber(tArgs[2])
		local nDynamicID = tonumber(tArgs[3])
		goHouseMgr:DynamicUpVoteReq(oRole,nTargetRoleID,nDynamicID)
	elseif nOperate == 104 then
		local nDynamicID = tonumber(tArgs[2])
		local oHouse = goHouseMgr:GetHouse(nRoleID)
		oHouse:DeleteDynamic(oRole,nDynamicID)
	elseif nOperate == 105 then
		local nRoleID = tonumber(tArgs[2])
		local nDynamicID = tonumber(tArgs[3])
		local nCommentID = tonumber(tArgs[4])
		local oHouse = goHouseMgr:GetHouse(nRoleID)
		oHouse:DeleteComment(oRole,nDynamicID,nCommentID)
	elseif nOperate == 201 then
		local oHouse = goHouseMgr:GetHouse(nRoleID)
		local nCnt = 0
		local tRoleID = goGPlayerMgr.m_tRoleIDMap
		for nVisiterRoleID,_ in pairs(tRoleID) do
			nCnt = nCnt + 1
			if nCnt <= 70 then
				local oVisiter = goGPlayerMgr:GetRoleByID(nVisiterRoleID)
				if oVisiter then
					local sMsg = string.format("aaaaaaaa%s",oVisiter:GetName())
					oHouse:AddMessage(oVisiter,sMsg)
				end
			end
		end
	elseif nOperate == 202 then
		if #tArgs > 1 then
			nRoleID = tonumber(tArgs[2])
		end
		local oHouse = goHouseMgr:GetHouse(nRoleID)
		local nCnt = 0
		local tRoleID = goGPlayerMgr.m_tRoleIDMap
		for nVisiterRoleID,_ in pairs(tRoleID) do
			nCnt = nCnt + 1
			if nCnt <= 20 then
				local oVisiter = goGPlayerMgr:GetRoleByID(nVisiterRoleID)
				if oVisiter then
					local tData = {
						nRoleID = nVisiterRoleID,
						sName = oVisiter:GetName(),
						sModel = oVisiter:GetHeader(),
						nLevel = oVisiter:GetLevel(),
						bIsFriend = false,
						nSchool = oVisiter:GetSchool(),
					}
					oHouse:AddVisiter(nVisiterRoleID,tData)
				end
			end
		end
	elseif nOperate == 203 then
		local tRoleID = goGPlayerMgr.m_tRoleIDMap
		local nCnt = 0
		for nRoleID,tData in pairs(tRoleID) do
			nCnt = nCnt + 1
			if nCnt <= 50 then
				local oRole = goGPlayerMgr:GetRoleByID(nRoleID)
				local nServerID = oRole:GetServer()
				local nServiceID = goServerMgr:GetGlobalService(nServerID,20)
				goRemoteCall:Call("PopularityChangeReq", nServerID, nServiceID, 0, nRoleID, math.random(50,500))
			end
		end
	elseif nOperate == 204 then
		local tRoleID = goGPlayerMgr.m_tRoleIDMap
		local nCnt = 0
		for nRoleID,tData in pairs(tRoleID) do
			nCnt = nCnt + 1
			if nCnt <= 50 then
				local oRole = goGPlayerMgr:GetRoleByID(nRoleID)
				local nServerID = oRole:GetServer()
				local nServiceID = goServerMgr:GetGlobalService(nServerID,20)
				goRemoteCall:Call("HouseAssetsChangeReq", nServerID, nServiceID, 0, nRoleID, math.random(50,500))
			end
		end
	elseif nOperate == 205 then
		local tRoleID = goGPlayerMgr.m_tRoleIDMap
		local oHouse = goHouseMgr:GetHouse(nRoleID)
		for nVisiterRoleID,_ in pairs(tRoleID) do
			local oVisiter = goGPlayerMgr:GetRoleByID(nVisiterRoleID)
			if oVisiter then
				local tData = {
					nRoleID = nVisiterRoleID,
					sModel = oVisiter:GetHeader(),
					sName = oVisiter:GetName(),
					nLevel = oVisiter:GetLevel(),
					bIsFriend = false,
					nItemID = 10016,
					nAmount = 1,
					nTime = os.time()
				}
				oHouse:AddGiftData(nVisiterRoleID,tData)
			end
		end
	elseif nOperate == 206 then
		local oHouse = goHouseMgr:GetHouse(nRoleID)
		local oPlant = oHouse:GetPlant()
		oPlant:Water()
		oPlant:Water()
		oPlant:Water()
	elseif nOperate == 207 then
		local oHouse = goHouseMgr:GetHouse(nRoleID)
		local oPlant = oHouse:GetPlant()
		local nTime = os.time() - 60*30
		oPlant:ChangeGiftTime(nTime)
	elseif nOperate == 208 then
	elseif nOperate == 110 then
		--家园资产
		local tData = {
			nRankID = 17,
			nRankNum = 20,
		}
		local nServerID = oRole:GetServer()
		local nServiceID = goServerMgr:GetGlobalService(nServerID,20)
		goRemoteCall:Call("KejuRankingTest",nServerID, nServiceID, 0,nRoleID,4,tData)
	elseif nOperate == 111 then
		--周人气
		local tData = {
			nRankID = 41,
			nRankNum = 20,
		}
		local nServerID = oRole:GetServer()
		local nServiceID = goServerMgr:GetGlobalService(nServerID,20)
		goRemoteCall:Call("KejuRankingTest",nServerID, nServiceID, 0,nRoleID,4,tData)
	elseif nOperate == 112 then
		--总人气
		local tData = {
			nRankID = 42,
			nRankNum = 20,
		}
		local nServerID = oRole:GetServer()
		local nServiceID = goServerMgr:GetGlobalService(nServerID,20)
		goRemoteCall:Call("KejuRankingTest",nServerID, nServiceID, 0,nRoleID,4,tData)
	elseif nOperate == 113 then
		oRole.m_oToday:ClearData()
	elseif nOperate == 114 then
		local oHouse = goHouseMgr:GetHouse(nRoleID)
		oHouse.m_tFurniture = {}
	elseif nOperate == 115 then
		local oHouse = goHouseMgr:GetHouse(nRoleID)
		oHouse:SaveData()
	end
end

--道具查询
CGMMgr["itemquery"] = function(self, nServer, nService, nSession, tArgs)
	local oRole = goGPlayerMgr:GetRoleBySS(nServer, nSession)
	if not oRole then return end
	local nTarRoleID, nItemType, nItemID = tonumber(tArgs[1]), tonumber(tArgs[2]), tonumber(tArgs[3]) 
	goItemQueryMgr:QueryReq(oRole:GetID(), nTarRoleID, nItemType, nItemID, os.time() - 10)
end


goGMMgr = goGMMgr or CGMMgr:new()