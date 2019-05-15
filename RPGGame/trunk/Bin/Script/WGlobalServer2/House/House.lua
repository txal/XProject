--家园系统
local table, string, math, os, pairs, ipairs, assert = table, string, math, os, pairs, ipairs, assert

function CHouse:Ctor(nRoleID)
	self.m_nRoleID = nRoleID
	self.m_nConfID = 0
	self.m_sName = ""
	self.m_nLevel = 0
	self.m_tShapeData = {}
	self.m_bDirty = false
	self.m_tNowVisitList = {}								--当前在家园中的玩家列表
	self.m_tVisitList = {}									--访问列表
	self.m_tGiftList = {}
	self.m_nDonny = 0										--人气
	self.m_nBoxCnt = 0										--宝箱
	self.m_nGiftCnt = 0										--礼物数目
	self.m_tLeaveMessage = {}								--留言
	self.m_nMessageID = 0									--留言ID
	self.m_sPhotoKey = ""									--照片key

	self.m_tFurniture = {}									--家具
	self.m_tBattleAttr = {}									--家具属性加成
	self.m_tSetBattleAttr = {}								--家具套装属性加成
	self.m_tSetFurnitureCnt = {}							--家具套装对应解锁数目	
	self.m_tWieldFurnituer = {}								--装备的家具		

	self.m_oPlant = CPlant:new(nRoleID) 					--植物相关
	self.m_oToday = CToday:new(nRoleID)						--天变量
	self.m_oCircle = CHouseCircle:new(nRoleID)				--动态
end

function CHouse:SaveData()
	local tData = {}
	tData.m_nConfID = self.m_nConfID
	tData.m_sName = self.m_sName
	tData.m_nLevel = self.m_nLevel
	tData.m_tShapeData = self.m_tShapeData
	tData.m_tVisitList = self.m_tVisitList
	tData.m_tGiftList = self.m_tGiftList
	tData.m_nDonny = self.m_nDonny
	tData.m_nBoxCnt = self.m_nBoxCnt
	tData.m_nGiftCnt = self.m_nGiftCnt
	tData.m_tLeaveMessage = self.m_tLeaveMessage
	tData.m_nMessageID = self.m_nMessageID
	tData.m_sPhotoKey = self.m_sPhotoKey

	tData.m_tBattleAttr = self.m_tBattleAttr
	tData.m_tSetBattleAttr = self.m_tSetBattleAttr
	tData.m_tSetFurnitureCnt = self.m_tSetFurnitureCnt

	tData.m_tToday = self.m_oToday:SaveData()
	tData.m_tCircle = self.m_oCircle:SaveData()
	tData.m_tPlant = self.m_oPlant:SaveData()
	local tFurniture = {}
	for nFurnitureID,oFurniture in pairs(self.m_tFurniture) do
		tFurniture[nFurnitureID] = oFurniture:SaveData()
	end
	tData.m_tFurniture = tFurniture
	
	local bRes = pcall(function() goDBMgr:GetSSDB(gnServerID, "global", GF.GetServiceID()):HSet(gtDBDef.sHouseDB, self.m_nRoleID,cjson.encode(tData)) end)
	if bRes then
		self:MarkDirty(false)
	end
end

function CHouse:LoadData()
	local oDB = goDBMgr:GetSSDB(gnServerID, "global", GF.GetServiceID())
	local sData = oDB:HGet(gtDBDef.sHouseDB, self.m_nRoleID)
	local tData
	if sData and sData ~= "" then
	 	tData = cjson.decode(sData)
	 end

	tData = tData or {}
	self.m_nConfID = tData.m_nConfID or self.m_nConfID
	self.m_sName = tData.m_sName or self.m_sName
	self.m_nLevel = tData.m_nLevel or self.m_nLevel
	self.m_tShapeData = tData.m_tShapeData or self.m_tShapeData
	self.m_tVisitList = tData.m_tVisitList or self.m_tVisitList
	self.m_tGiftList = tData.m_tGiftList or self.m_tGiftList
	self.m_nDonny = tData.m_nDonny or self.m_nDonny
	self.m_nBoxCnt = tData.m_nBoxCnt or self.m_nBoxCnt
	self.m_nGiftCnt = tData.m_nGiftCnt or self.m_nGiftCnt
	self.m_tLeaveMessage = tData.m_tLeaveMessage or self.m_tLeaveMessage
	self.m_nMessageID = tData.m_nMessageID or self.m_nMessageID
	self.m_sPhotoKey = tData.m_sPhotoKey or self.m_sPhotoKey

	self.m_tBattleAttr = tData.m_tBattleAttr or self.m_tBattleAttr
	self.m_tSetBattleAttr = tData.m_tSetBattleAttr or self.m_tSetBattleAttr
	self.m_tSetFurnitureCnt = tData.m_tSetFurnitureCnt or self.m_tSetFurnitureCnt
	self.m_oPlant:LoadData(tData.m_tPlant)
	self.m_oToday:LoadData(tData.m_tToday)
	self.m_oCircle:LoadData(tData.m_tCircle)
	local tFurniture = tData.m_tFurniture or {}
	for nFurnitureID,tFurnitureData in pairs(tFurniture) do
		local oFurniture = CFurniture:new(nFurnitureID)
		oFurniture:LoadData(tFurnitureData)
		self.m_tFurniture[nFurnitureID] = oFurniture
		if oFurniture:IsWield() then
			self.m_tWieldFurnituer[nFurnitureID] = oFurniture
		end
	end
end

function CHouse:Online()
	local oRole = self:GetRole()
	if oRole then
		--初始化
		if self.m_nConfID == 0 then
			self:MarkDirty(true)
			self.m_nConfID = oRole:GetConfID()
			self.m_sName = oRole:GetName()
			self.m_nLevel = oRole:GetLevel()
			if self.m_oPlant then
				self.m_oPlant:SetShape(9)
			end
			self.m_tShapeData = oRole:GetShapeData()
		end
	end
	if self.m_tShapeData and table.Count(self.m_tShapeData) <= 0 then
		self:MarkDirty(true)
		self.m_tShapeData = oRole:GetShapeData()
	end
	self.m_oCircle:Online()
end

function CHouse:Offline()
	local oRole = self:GetRole()
	if oRole then
		--
	end
end

function CHouse:UpdateReq(tData)
	self:MarkDirty(true)
	tData = tData or {}
	for k,v in pairs(tData) do
		if k == "m_nLevel" or k == "m_sName" or k == "m_tShapeData" then
			self[k] = v
		end
	end
end

--动态内容,离线时使用
function CHouse:GetConfID() return self:GetRole():GetConfID() end
function CHouse:GetConf() return self:GetRole():GetConf() end
function CHouse:GetSchool() return self:GetConf().nSchool end
function CHouse:GetGender() return self:GetConf().nGender end
function CHouse:GetHeader() return self:GetConf().sHeader end
function CHouse:GetModel() return self:GetConf().sModel end
function CHouse:GetName() return self.m_sName end
function CHouse:GetLevel() return self.m_nLevel end
function CHouse:GetShapeData() return self.m_tShapeData end

--设置脏
function CHouse:MarkDirty(bDirty) goHouseMgr:MarkHouseDirty(self.m_nRoleID, bDirty) end
--是否脏
function CHouse:IsDirty() return goHouseMgr:IsHouseDirty(self.m_nRoleID) end

function CHouse:GetOwner()
	return self.m_nRoleID
end

function CHouse:GetRole()
	local oRole = goGPlayerMgr:GetRoleByID(self.m_nRoleID)
	return oRole
end

function CHouse:GetGiftCnt()
	return self.m_nGiftCnt
end

function CHouse:PackFurniture()
	local tData = {}
	for nPos,oFurniture in pairs(self.m_tWieldFurnituer) do
		table.insert(tData,oFurniture:PackData())
	end
	return tData
end

function CHouse:PackPlant()
	return self.m_oPlant:PackData()
end

function CHouse:GetPhotoKey()
	return self.m_sPhotoKey
end

function CHouse:PackData()
	local tData = {}
	tData.nRoleID = self:GetOwner()
	tData.sName = self:GetName()
	tData.nGender = self:GetGender()
	tData.nSchool = self:GetSchool()
	tData.sModel = self:GetHeader()
	tData.nLevel = self:GetLevel()
	tData.nDony = self:GetDony()
	tData.nBox = self:GetBoxCnt()
	tData.nGift = self:GetGiftCnt()
	tData.nLeaveMessage = true
	tData.tFurniture = self:PackFurniture()
	tData.tPlant = self:PackPlant()
	tData.sPhotoKey = self:GetPhotoKey()
	tData.tSimpleDynamic = self.m_oCircle:PackSimpleDynamic()
	tData.tShapeData = self:GetShapeData()
	return tData
end

function CHouse:EnterHouse(oRole)
	local tData = self:PackData()
	oRole:SendMsg("GS2CEnterHouseRet",tData)

	if oRole:GetID() ~= self:GetOwner() then
		local tData = {
			nRoleID = oRole:GetID(),
			sName = oRole:GetName(),
			sModel = oRole:GetHeader(),
			nLevel = oRole:GetLevel(),
			bIsFriend = false,
			nSchool = oRole:GetSchool(),
		}
		self:AddVisiter(oRole:GetID(),tData)
	end
	local tVisitHouse = oRole.m_oToday:Query("VisitHouse",{})
	if not tVisitHouse[self.m_nRoleID] and oRole:GetID() ~= self.m_nRoleID then
		self:AddDony()
		tVisitHouse[self.m_nRoleID] = 1
		oRole.m_oToday:Set("VisitHouse",tVisitHouse)
		oRole:Tips("访问家园，对方家园人气+1")
	end
	local nHouseBoxCnt = oRole.m_oToday:Query("HouseBoxCnt",0)
	if nHouseBoxCnt < 5 and math.random(10) < 5 and oRole:GetID() ~= self:GetOwner() and self:GetBoxCnt() > 0 then
		self:AddBoxCnt(-1)
		goHouseMgr:AddBoxCnt(oRole:GetID(),1)
		oRole.m_oToday:Add("HouseBoxCnt",1)
		oRole:Tips("你幸运的获得了对方家园的宝箱")
	end
	self.m_tNowVisitList[oRole:GetID()] = 1
end

function CHouse:LeaveHouse(oRole)
	self.m_tNowVisitList[oRole:GetID()] = nil
end

function CHouse:AddVisiter(nRoleID,tData)
	local fnCallback = function (bIsFriend)
		tData.bIsFriend = bIsFriend
		self:AddVisiter2(nRoleID,tData)
	end
	goRemoteCall:CallWait("IsFriend",fnCallback,gnWorldServerID,goServerMgr:GetGlobalService(gnWorldServerID, 110),0,self.m_nRoleID,nRoleID)
end

function CHouse:AddVisiter2(nRoleID,tData)
	self:MarkDirty(true)
	tData = tData or {}
	tData.nTime = os.time()
	self.m_tVisitList[nRoleID] = tData
	self:CheckLimitVisiter()
end

function CHouse:CheckLimitVisiter()
	local nCnt = 0
	local nMinTime = os.time()
	local nDeleteVisiter
	for nRoleID,tData in pairs(self.m_tVisitList) do
		nCnt = nCnt + 1
		if tData.nTime < nMinTime then
			nMinTime = tData.nTime
			nDeleteVisiter = nRoleID
		end
	end
	if nCnt <= 10 then
		return
	end
	if not nDeleteVisiter then
		return
	end
	self.MarkDirty(true)
	self.m_tVisitList[nDeleteVisiter] = nil
end

function CHouse:PackVisiter()
	local tRet = {}
	for nRoleID,tData in pairs(self.m_tVisitList) do
		table.insert(tRet,{
			nRoleID = nRoleID,
			sModel = tData.sModel,
			sName = tData.sName,
			nLevel = tData.nLevel,
			bIsFriend = tData.bIsFriend,
		})
	end
	return tRet
end

function CHouse:HouseVisiterReq()
	local oRole = self:GetRole()
	if not oRole then return end
	oRole:SendMsg("GS2CHouseVisiterRet",{tVisiter = self:PackVisiter()})
end

function CHouse:AddGiftData(nRoleID,tData)
	local fnCallback = function (bIsFriend)
		tData.bIsFriend = bIsFriend
		self:AddGiftData2(nRoleID,tData)
	end
	goRemoteCall:CallWait("IsFriend",fnCallback,gnWorldServerID,goServerMgr:GetGlobalService(gnWorldServerID, 110),0,self.m_nRoleID,nRoleID)
end

function CHouse:AddGiftData2(nRoleID,tData)
	self:MarkDirty(true)
	tData = tData or {}
	self.m_tGiftList[nRoleID] = tData
	self:CheckLimitGift()
end

function CHouse:CheckLimitGift()
	local nCnt = 0
	local nMinTime = os.time()
	local nDeleteVisiter
	for nRoleID,tData in pairs(self.m_tGiftList) do
		nCnt = nCnt + 1
		local nTime = tData.nTime or 0
		if nTime < nMinTime then
			nMinTime = nTime
			nDeleteVisiter = nRoleID
		end
	end
	if nCnt <= 10 then
		return
	end
	if not nDeleteVisiter then
		return
	end
	self:MarkDirty(true)
	self.m_tGiftList[nDeleteVisiter] = nil
end

function CHouse:PackGiftData()
	local tRet = {}
	for nRoleID,tData in pairs(self.m_tGiftList) do
		table.insert(tRet,{
			nRoleID = nRoleID,
			sModel = tData.sModel,
			sName = tData.sName,
			nLevel = tData.nLevel,
			bIsFriend = tData.bIsFriend,
			nItemID = tData.nItemID,
			nAmount = tData.nAmount,
			nTime =tData.nTime
		})
	end
	return tRet
end


function CHouse:GiftInfoReq()
	local oRole = self:GetRole()
	if not oRole then return end
	oRole:SendMsg("GS2CHouseGiftInfoRet",{tGift = self:PackGiftData()})
end

function CHouse:ValidGiveGift(oRole,nPropID,nAmount)
	if not table.InArray(nAmount,{1,9,36}) then
		return false
	end
	if not table.InArray(nPropID,{10016,10017,10018,10019}) then
		return false
	end
	return true
end

--送礼物
function CHouse:GiveGiftReq(oRole,nPropID,nAmount,sMsg,bMoneyAdd)
	if not self:ValidGiveGift(oRole,nPropID,nAmount) then
		return
	end
	local nRoleID = oRole:GetID()
	local fnCallback = function (bRet)
		if not bRet then return end
		self:GiveGiftReqSuccess(nRoleID,nPropID,nAmount,sMsg)
	end

	goRemoteCall:CallWait("HouseGiveGiftReq",fnCallback,oRole:GetStayServer(), oRole:GetLogic(), oRole:GetSession(),nRoleID,nPropID,nAmount,bMoneyAdd)
end

function CHouse:GetDonyByProp(nPropID)
	if nPropID == 10016 then
		return 10
	elseif nPropID == 10017 then
		return 30
	elseif nPropID == 10018 then
		return 80
	elseif nPropID == 10019 then
		return 180
	end
	return 10
end

function CHouse:GiveGiftReqSuccess(nRoleID,nPropID,nAmount,sMsg)
	local oRole = goGPlayerMgr:GetRoleByID(nRoleID)
	if not oRole then return end

	local sName = oRole:GetName()
	local nDony = self:GetDonyByProp(nPropID) * nAmount
	local tPropData = ctPropConf[nPropID]
	local sPropName = tPropData["sName"]
	local sTip = string.format("向%s赠送礼物，对方空间人气增加%s",sName,nDony)
	oRole:Tips(sTip)
	local oHouseRole = self:GetRole()
	if oHouseRole then
		sTip = string.format("%s向你赠送礼物，收到%s*%s",oRole:GetName(),sPropName,nAmount)
		oHouseRole:Tips(sTip)
	end
	self:AddGiftCnt(nAmount)
	self:AddDony(nDony)
	local tMsg = {}
	tMsg.nRoleID = nRoleID
	tMsg.nDony = self:GetDony()
	tMsg.nGift = self:GetGiftCnt()
	oRole:SendMsg("GS2CHouseGiveGiftRet",tMsg)
	local tData = {
		nRoleID = oRole:GetID(),
		sModel = oRole:GetHeader(),
		sName = oRole:GetName(),
		nLevel = oRole:GetLevel(),
		bIsFriend = false,
		nItemID = nPropID,
		nAmount = nAmount,
		nTime = os.time()
	}
	self:AddGiftData(nRoleID,tData)
	if nAmount >= 36 then
		GF.SendNotice(oRole:GetServer(), sMsg)
	end
end


function CHouse:AddDony(nDony)
	local nOldDony = self.m_nDonny
	nDony = nDony or 1
	self.m_nDonny = self.m_nDonny + nDony
	self:MarkDirty(true)

	local oRole = self:GetRole()
	if oRole then
		local nServerID = oRole:GetServer()
		local nServiceID = goServerMgr:GetGlobalService(nServerID,20)
		goRemoteCall:Call("PopularityChangeReq", nServerID, nServiceID, 0, oRole:GetID(), self.m_nDonny)
		goRemoteCall:Call("OnCBPopularityReq", nServerID, nServiceID, 0, oRole:GetID(), self.m_nDonny-nOldDony)
	end
end

function CHouse:GetDony()
	return self.m_nDonny
end

function CHouse:AddGiftCnt(nCnt)
	self:MarkDirty(true)
	self.m_nGiftCnt = self.m_nGiftCnt + nCnt
end

function CHouse:GetGiftCnt()
	return self.m_nGiftCnt
end

function CHouse:AddBoxCnt(nCnt)
	self:MarkDirty(true)
	self.m_nBoxCnt = self.m_nBoxCnt + nCnt
	self.m_nBoxCnt = math.min(self.m_nBoxCnt,20)
	local oRole = self:GetRole()
	if oRole then
		oRole:SendMsg("GS2CBuyHouseBoxRet",{nBoxCnt = self.m_nBoxCnt})
	end
end

function CHouse:GetBoxCnt()
	return self.m_nBoxCnt
end

function CHouse:GetMaxBoxCnt()
	return 20
end

function CHouse:ValidBuyBox(nBuyCnt)
	if nBuyCnt <= 0 then
		return
	end
	local nHaveCnt = self:GetBoxCnt()
	if nHaveCnt + nBuyCnt > self:GetMaxBoxCnt() then
		return false
	end
	return true
end

function CHouse:BuyBox(nBuyCnt)
	if not self:ValidBuyBox(nBuyCnt) then
		return 
	end
	local nCostGold = nBuyCnt * 100
	local oRole = goGPlayerMgr:GetRoleByID(self.m_nRoleID)
	if not oRole then
		return
	end
	local tCost = {nType = gtItemType.eCurr, nID = gtCurrType.eJinBi, nNum = nCostGold}
	local fnSubCallback = function (bRet)
		if not bRet then
			return
		end
		if not self:ValidBuyBox(nBuyCnt) then
			oRole:AddItem(tCost, "家园购买宝箱回滚")
			return
		end
		self:AddBoxCnt(nBuyCnt)
	end
	oRole:SubItemShowNotEnoughTips({tCost}, "家园购买宝箱", true, false, fnSubCallback)
end

function CHouse:HouseMessageReq(nPage)
	local tData = {}
	local bDirty
	local tNoList = table.Keys(self.m_tLeaveMessage)
	local fnSort = function (a,b)
		if a > b then
			return true
		end
		return false
	end
	table.sort(tNoList,fnSort)
	local nStartNo = (nPage-1) * 10
	local nEndNo = nPage * 10
	local nCnt = 0
	for nID,nMessageID in ipairs(tNoList) do
		if nID > nStartNo and nID <= nEndNo then
			local tMessageData = self.m_tLeaveMessage[nMessageID]
			if tMessageData then
				if tMessageData.nState == 0 then
					tMessageData.nState = 1
					bDirty = true
				end
				table.insert(tData,{
					nRoleID = tMessageData.nRoleID,
					nMessageID = nMessageID,
					sModel = tMessageData.sModel,
					nLevel = tMessageData.nLevel,
					sName = tMessageData.sName,
					nGender = tMessageData.nGender,
					nSchool = tMessageData.nSchool,
					sMsg = tMessageData.sMsg,
					nTime = tMessageData.nTime,
					nState = 1,
				})
			end
		end
	end
	if bDirty then
		self:MarkDirty(true)
	end
	local oRole = self:GetRole()
	oRole:SendMsg("GS2CHouseMessageRet",{tMessage = tData})
end

function CHouse:AddMessage(oRole,sMessage)
	if self.m_nRoleID == oRole:GetID() then
		return
	end
	local nRoleID = oRole:GetID()
	local nNo = self:GenerateMessageID()
	local tData = {
		nRoleID = nRoleID,
		nTime = os.time(),
		sModel = oRole:GetHeader(),
		sName = oRole:GetName(),
		nGender = oRole:GetGender(),
		nSchool = oRole:GetSchool(),
		nLevel = oRole:GetLevel(),
		sMsg = sMessage,
		nState = 0,
	}
	self:MarkDirty(true)
	self.m_tLeaveMessage[nNo] = tData
	self:CheckLimitMessage()
end

function CHouse:DeleteMessage(nSeq)
	if #self.m_tLeaveMessage < nSeq then
		return
	end
	self:MarkDirty(true)
	self.m_tLeaveMessage[nSeq] = nil
	local oRole = self:GetRole()
	if oRole then
		oRole:SendMsg("GS2CHouseDeleteMessageRet",{nMessageID = nSeq})
	end
end

function CHouse:GenerateMessageID()
	self.m_nMessageID = self.m_nMessageID + 1
	if self.m_nMessageID >= 1000000000 then
		self.m_nMessageID = 1
	end
	return self.m_nMessageID
end

function CHouse:CheckLimitMessage()
	local nMinTime
	local nDeleteSeq
	local nCnt = 0
	for iNo,tData in pairs(self.m_tLeaveMessage) do
		nCnt = nCnt + 1
		if not nMinTime or (tData.nTime < nMinTime) then
			nMinTime = tData.nTime
			nDeleteSeq = iNo
		end
	end
	if nCnt <= 50 then
		return
	end
	self:MarkDirty(true)
	self.m_tLeaveMessage[nDeleteSeq] = nil
end

function CHouse:SetPhotoKey(sPhotoKey)
	self:MarkDirty(true)
	self.m_sPhotoKey = sPhotoKey
end
-----------------------------------家具----------------------------------------------
function CHouse:AddFurniture(nFurnitureID)
	self:MarkDirty(true)
	if self.m_tFurniture[nFurnitureID] then
		return
	end
	local oFurniture = CFurniture:new(nFurnitureID)
	self.m_tFurniture[nFurnitureID] = oFurniture
	return oFurniture
end

function CHouse:GetFurniture(nFurnitureID)
	return self.m_tFurniture[nFurnitureID]
end

function CHouse:IsFurnituerLock(nFurnitureID)
	local oFurniture = self:GetFurniture(nFurnitureID)
	if not oFurniture then
		return true
	end
	if oFurniture:IsLock() then
		return true
	end
	return false
end

function CHouse:IsFurnituerUnLock(nFurnitureID)
	local oFurniture = self:GetFurniture(nFurnitureID)
	if not oFurniture then
		return false
	end
	if oFurniture:IsUnLock() then
		return true
	end
	return false
end

function CHouse:GetFurnitureAssetScore()
	local nAssetScore = 0
	for nFurnitureID,oFurniture in pairs(self.m_tFurniture) do
		if oFurniture:IsUnLock() then
			nAssetScore = nAssetScore + oFurniture:GetAssetScore()
		end
	end
	return nAssetScore
end

function CHouse:UnLockFurniture(nFurnitureID)
	local oFurniture = self:GetFurniture(nFurnitureID)
	if not oFurniture then
		oFurniture = self:AddFurniture(nFurnitureID)
	end
	if self:IsFurnituerUnLock(nFurnitureID) then
		return
	end
	self:MarkDirty(true)
	oFurniture:UnLock()
	self:AddFurnitureBattleAttr(oFurniture)
	self:CheckFurnitureSet(oFurniture)
	self:SyncHouseAttrToLogic()
	local nAssetScore = self:GetFurnitureAssetScore()
	local oRole = self:GetRole()
	if oRole then
		local nServerID = oRole:GetServer()
		local nServiceID = goServerMgr:GetGlobalService(nServerID,20)
		goRemoteCall:Call("HouseAssetsChangeReq", nServerID, nServiceID, 0, oRole:GetID(), nAssetScore)
	end
end

function CHouse:GetFurnitureSetConfigData(nSetID)
	return ctHouseFurnitureSetConf[nSetID]
end

function CHouse:AddFurnitureBattleAttr(oFurniture)
	local tAttr = oFurniture:GetBattleAttr()
	for nAttr,nAdd in pairs(tAttr) do
		if not self.m_tBattleAttr[nAttr] then
			self.m_tBattleAttr[nAttr] = 0
		end
		self.m_tBattleAttr[nAttr] = self.m_tBattleAttr[nAttr] + nAdd
	end
end

--检查套装属性加成
function CHouse:CheckFurnitureSet(oFurniture)
	local nSetID = oFurniture:GetSetID()
	if nSetID <= 0 then
		return
	end
	local nSetCnt = 0
	for nFurnitureID,oFurniture in pairs(self.m_tFurniture) do
		if oFurniture:GetSetID() == nSetID then
			nSetCnt = nSetCnt + 1
		end
	end
	self:MarkDirty(true)
	self.m_tSetFurnitureCnt[nSetID] = nSetCnt
	self:ResetSetFurnituerAttr(nSetID)
end

--重新计算对应套装属性加成
function CHouse:ResetSetFurnituerAttr(nSetID)
	local nSetCnt = self.m_tSetFurnitureCnt[nSetID] or 0
	self.m_tSetBattleAttr[nSetID] = {}
	local tFurnituerSetConfigData = self:GetFurnitureSetConfigData(nSetID)
	if nSetCnt < 2 then
		return
	end

	for nCnt = 2,nSetCnt do
		local tAddAttr
		if nCnt == 2 then
			tAddAttr = tFurnituerSetConfigData["tTwoFurnitureSetAttr"]
		elseif nCnt == 3 then
			tAddAttr = tFurnituerSetConfigData["tThreeFurnitureSetAttr"]
		elseif nCnt == 4 then
			tAddAttr = tFurnituerSetConfigData["tFourFurnitureSetAttr"]
		end
		if tAddAttr then
			for _,tAttr in pairs(tAddAttr) do
				local nAttrID,nAdd = table.unpack(tAttr)
				if not self.m_tSetBattleAttr[nSetID][nAttrID] then
					self.m_tSetBattleAttr[nSetID][nAttrID] = 0
				end
				self.m_tSetBattleAttr[nSetID][nAttrID] = self.m_tSetBattleAttr[nSetID][nAttrID] + nAdd
			end
		end
	end
end

function CHouse:SyncHouseAttrToLogic()
	local tAttr = {}
	for nSetID,tData in pairs(self.m_tSetBattleAttr) do
		for nAttrID,nAdd in pairs(tData) do
			if not tAttr[nAttrID] then
				tAttr[nAttrID] = 0
			end
			tAttr[nAttrID] = tAttr[nAttrID] + nAdd
		end
	end
	for nAttrID,nAdd in pairs(self.m_tBattleAttr) do
		if not tAttr[nAttrID] then
			tAttr[nAttrID] = 0
		end
		tAttr[nAttrID] = tAttr[nAttrID] + nAdd
	end
	local oRole = self:GetRole()
	goRemoteCall:Call("SyncHouseBattleAttr", oRole:GetStayServer(), oRole:GetLogic(), oRole:GetSession(), oRole:GetID(),tAttr)
end

function CHouse:WieldFurniture(nFurnitureID)
	local oFurniture = self:GetFurniture(nFurnitureID)
	if not oFurniture then
		return
	end
	if not oFurniture:IsUnLock() then
		return
	end
	self:MarkDirty(true)
	local nType = oFurniture:GetFurnitureType()
	local oWieldFurnituer = self.m_tWieldFurnituer[nType]
	if oWieldFurnituer then
		oWieldFurnituer:UnWield()
	end
	self.m_tWieldFurnituer[nType] = oFurniture
	oFurniture:Wield()
	local tData = {}
	table.insert(tData,oFurniture:PackData())
	local oRole = self:GetRole()
	oRole:SendMsg("GS2CHouseWieldFurnitureRet",{tFurniture = tData})
end

function CHouse:PosFurnitureReq()
	local tData = {}
	for _,oFurniture in pairs(self.m_tFurniture) do
		table.insert(tData,oFurniture:PackData())
	end
	local tSuitData = {}
	for nSuitID,nCnt in pairs(self.m_tSetFurnitureCnt) do
		table.insert(tSuitData,{nSuitID = nSuitID,nCnt = nCnt})
	end
	local oRole = self:GetRole()
	local tMsg = {}
	tMsg.tFurniture = tData
	tMsg.tSuit = tSuitData
	oRole:SendMsg("GS2CHousePosFurnituerRet",tMsg)
end

----------------------------------------------植物------------------------------------------------

function CHouse:GetPlant()
	return self.m_oPlant
end

function CHouse:ValidWater(oRole)
	local tWaterPlant = oRole.m_oToday:Query("HouseWater",{})
	local nOwner = self:GetOwner()
	if tWaterPlant[nOwner] then
		oRole:Tips("你今天已经给它浇过水了哦")
		return false
	end
	local oPlant = self:GetPlant()
	if oPlant:IsFull() then
		oRole:Tips("这个植物已经喝得饱饱哒，不用再浇水啦")
		return false
	end
	if table.Count(tWaterPlant) >= 5 then
		oRole:Tips("你今天浇水已经满5次了哦，请明天再浇吧")
		return false
	end
	if self.m_oToday:Query("HouseWater",0) >= 9 then
		oRole:Tips("这个植物今天已经没办法再浇水啦，再浇就淹死啦")
		return false
	end
	return true
end
--植物浇水
function CHouse:WaterPlant(oRole)
	if not self:ValidWater(oRole) then
		return
	end
	local nOwner = self:GetOwner()
	local tWaterPlant = oRole.m_oToday:Query("HouseWater",{})
	tWaterPlant[nOwner] = 1
	oRole.m_oToday:Set("HouseWater",tWaterPlant)
	self.m_oToday:Add("HouseWater",1)
	self:MarkDirty(true)
	local oPlant = self:GetPlant()
	oPlant:Water()
	local nJinBi = math.random(300,600)
	local tItemList = {{nType = gtItemType.eCurr,nID = gtCurrType.eJinBi,nNum = nJinBi}}
	oRole:AddItem(tItemList,"家园植物浇水")
	local tData = oPlant:PackData()
	oRole:SendMsg("GS2CHousePlantRet",{nRoleID = self.m_nRoleID,tPlant = tData})
end

function CHouse:ValidPlantGift(oRole)
	local oPlant = self:GetPlant()
	if not oPlant then
		return false
	end
	if not oPlant:IsFull() then
		return false
	end
	return true
end

function CHouse:OpenPlantGiftInterface(oRole)
	if not self:ValidPlantGift(oRole) then
		return
	end
	local nMinServerLevel = goServerMgr:GetServerMinLevel()
	local nCnt = oRole.m_oToday:Query("HousePlantGift",0)
	local nRoleID = oRole:GetID()
	local oPlant = self:GetPlant()
	local tPartnerInfo = oPlant:GetPartnerData()
	if nCnt == 0 or table.Count(tPartnerInfo) <= 0 then
		oRole.m_oToday:Set("HousePlantGift",1)
		local fCallback = function (tPartnerInfo)
			self:OpenPlantGiftInterface2(nRoleID,tPartnerInfo)
		end
		goRemoteCall:CallWait("WGlobalHousePartnerReq",fCallback,oRole:GetStayServer(), oRole:GetLogic(), oRole:GetSession(), oRole:GetID())
	else
		self:SendPlantGift(nRoleID)
	end
end

function CHouse:OpenPlantGiftInterface2(nRoleID,tPartnerInfo)
	if #tPartnerInfo <= 0 then
		return
	end
	local tPartnerInfo = tPartnerInfo[math.random(#tPartnerInfo)]
	local oPlant = self:GetPlant()
	self:MarkDirty(true)
	oPlant:SetPartnerData(tPartnerInfo)
	self:SendPlantGift(nRoleID)
end

function CHouse:SendPlantGift(nRoleID)
	local oRole = goGPlayerMgr:GetRoleByID(nRoleID)
	if not oRole then
		return
	end
	local oPlant = self:GetPlant()
	local tPartnerInfo = oPlant:GetPartnerData()
	if table.Count(tPartnerInfo) <= 0 then
		oRole:Tips("没有仙侣无法赠送")
		return
	end
	oRole:SendMsg("GS2CHousePlantGiftDataRet",tPartnerInfo)
end

function CHouse:PlantChangePartner(oRole)
	local nCnt = oRole.m_oToday:Query("PlantChangePartnerCnt",0)
	local nCostJinBi = (nCnt + 1) * 100

	local sCont = string.format("是否花费%d金币更换要赠送的仙侣？", nCostJinBi)
	local tMsg = {sCont=sCont, tOption={"取消", "确定"}, nTimeOut=30}
	local nRoleID = oRole:GetID()
	goClientCall:CallWait("ConfirmRet", function(tData)
		if tData.nSelIdx == 1 then return end
		self:PlantChangePartner2(nRoleID,nCostJinBi)
	end, oRole, tMsg)
end

function CHouse:PlantChangePartner2(nRoleID,nCostJinBi)
	local oRole = goGPlayerMgr:GetRoleByID(nRoleID)
	local fnCallback = function (nJinBi)
		if nJinBi < nCostJinBi then
			oRole:JinBiTips()
    		oRole:SendMsg("JinBiNotEnoughtRet", {})
			return
		end
		self:PlantChangePartner3(nRoleID,nCostJinBi)
	end
	oRole:ItemCount(gtItemType.eCurr, gtCurrType.eJinBi,fnCallback)
	
end

function CHouse:PlantChangePartner3(nRoleID,nCostJinBi)
	local oRole = goGPlayerMgr:GetRoleByID(nRoleID)
	if not oRole then return end

	local tCost = {nType = gtItemType.eCurr, nID = gtCurrType.eJinBi, nNum = nCostJinBi}
	local fnSubCallback = function (bRet)
		if not bRet then
			return
		end
		self:PlantChangePartner4(nRoleID)
	end
	oRole:SubItemShowNotEnoughTips({tCost}, "家园礼物更新仙侣", true, false, fnSubCallback)
end

function CHouse:PlantChangePartner4(nRoleID)
	local oRole = goGPlayerMgr:GetRoleByID(nRoleID)
	if not oRole then return end

	local fnCallback = function (tPartnerInfo)
		self:OpenPlantGiftInterface2(nRoleID,tPartnerInfo)
	end
	goRemoteCall:CallWait("WGlobalHousePartnerReq",fnCallback,oRole:GetStayServer(), oRole:GetLogic(), oRole:GetSession(), oRole:GetID())
end

function CHouse:PlantGiveGift(oRole)
	local oPlant = self:GetPlant()
	if not oPlant:IsFull() then
		return
	end
	if oPlant:GetState() ~= 1 then
		return
	end
	local nParnterType = oPlant:GetPartnerType()
	local nBestPartnerType = goHouseMgr:GetBestPartner()
	if nParnterType == nBestPartnerType then
		local sMsg = "【最佳仙侣】哇！我正想要这个！太感谢你了！你等我一会，我要给你一个大大的惊喜！"
		oRole:Tips(sMsg)
	else
		local sMsg = "啊……这是送给我的吗？好漂亮，谢谢你。请等我一会，收下我的回礼吧"
		oRole:Tips(sMsg)
	end
	self:MarkDirty(true)
	oPlant:SetGiftTime()
	local tData = oPlant:PackData()
	oRole:SendMsg("GS2CHousePlantGiveGiftRet",{tPlant = tData})
end

function CHouse:PlantReceiveReward(oRole)
	local oPlant = self:GetPlant()
	if oPlant:GetState() ~= 3 then
		return
	end
	local nParnterType = oPlant:GetPartnerType()
	local nBestPartnerType = goHouseMgr:GetBestPartner()
	local bBestPartner = false
	if nParnterType == nBestPartnerType then
		bBestPartner = true
		oRole:Tips("呐，这是送给你的~（每日送花给最佳仙侣，以及仙侣亲密度会影响礼物质量哦）")
	else
		oRole:Tips("这是回礼，请收下吧（每日送花给最佳仙侣，以及仙侣亲密度会影响礼物质量哦）")
	end
	
	self:MarkDirty(true)
	oPlant:ResetGrow()
	local tData = oPlant:PackData()
	oRole:SendMsg("GS2CHousePlantGiveGiftRet",{tPlant = tData})
	
	local nRoleID = oRole:GetID()

	local fnCallback = function (nIntimacy)
		self:PlantReceiveReward2(nRoleID,nIntimacy,bBestPartner)
	end
	goRemoteCall:CallWait("WGlobalHousePartnerIntimacyReq",fnCallback,oRole:GetStayServer(), oRole:GetLogic(), oRole:GetSession(), oRole:GetID(),nParnterType)
end

function CHouse:PlantReceiveReward2(nRoleID,nIntimacy,bBestPartner)
	local oRole = goGPlayerMgr:GetRoleByID(nRoleID)
	if not oRole then return end
	local nRewardPlantID
	for nID,tData in ipairs(ctHousePlantRewardConf) do
		local nRewardIntimacy = tData.nIntimacy
		if nIntimacy < nRewardIntimacy then
			nRewardPlantID = nID
		end
	end
	local nMaxRewardID = 9
	if not nRewardPlantID then
		nRewardPlantID = nMaxRewardID
	end
	if bBestPartner then
		nRewardPlantID = nRewardPlantID + 1
	end
	nRewardPlantID = math.min(nRewardPlantID,nMaxRewardID)
	local nRewardID = ctHousePlantRewardConf[nRewardPlantID].nRewardID

	local nRoleLevel = oRole:GetLevel()
	local tRewardItemList = ctAwardPoolConf.GetPool(nRewardID, nRoleLevel, oRole:GetConfID())

	local function GetItemWeight(tNode)
		return tNode.nWeight
	end
	local tRewardItem = CWeightRandom:Random(tRewardItemList, GetItemWeight, 1, false)
	local tItem = {{nType = gtItemType.eProp,nID = tRewardItem[1].nItemID, nNum=tRewardItem[1].nItemNum}}
	oRole:AddItem(tItem, "家园植物送礼")
end

function CHouse:DymaicDataReq(oRole,nPage)
	self.m_oCircle:DymaicDataReq(oRole,nPage)
end

function CHouse:DynamicPublicCommentReq(oRole,nDynamicID,nCommentID,sMsg)
	self.m_oCircle:DynamicPublicCommentReq(oRole,nDynamicID,nCommentID,sMsg)
end

function CHouse:DynamicUpVoteReq(oRole,nDynamicID)
	self.m_oCircle:DynamicUpVoteReq(oRole,nDynamicID)
end

function CHouse:AddDynamic(oRole,tData)
	local sMsg = tData.sMsg or ""
	local tPictureKey = tData.tPictureKey or {}
	self.m_oCircle:AddDynamic(oRole,sMsg,tPictureKey)
end

function CHouse:DeleteDynamic(oRole,nDynamicID)
	self.m_oCircle:DeleteDynamic(oRole,nDynamicID)
end

function CHouse:DeleteComment(oRole,nDynamicID,nCommentID)
	self.m_oCircle:DeleteComment(oRole,nDynamicID,nCommentID)
end

function CHouse:GetCircleDynamic()
	local oCircle = self.m_oCircle
	return oCircle:GetNewDynamic()
end

function CHouse:UpdateFriendDynamic(nFriendID,nDynamicID,tDynamic)
	self.m_oCircle:UpdateFriendDynamic(nFriendID,nDynamicID,tDynamic)
end

function CHouse:FriendChange(nTargetRole)
	self.m_oCircle:FriendChange(nTargetRole)
end

function CHouse:GetDynamic(nDynamicID)
	return self.m_oCircle:GetDynamic(nDynamicID)
end