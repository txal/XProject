local table, string, math, os, pairs, ipairs, assert = table, string, math, os, pairs, ipairs, assert
local nServerID = gnServerID
function CMallMgr:Ctor()
	--不保存数据库
	self.m_bDirty = false
	self.m_tShopMap = {} --[商店类型] =商店对象
	self.m_tShopMap[gtShopType.eChamberCore] = CChamberCore:new(self)   --商会
	self.m_tShopMap[gtShopType.eShop] = CShop:new(self) --商城
	self.m_tShopMap[gtShopType.eCSpecial] = CSpecial:new(self) --特惠
	self.m_tShopMap[gtShopType.eCRecharge] = CSpecial:new(self) --元宝商城
	self.m_tShopMap[gtShopType.eCBuy] = CBuy:new(self) --购买金币银币
	
	self.m_nRoleDataTimer = nil
	self.m_nHourTimer = 0
	self.m_nUpdateTime = os.time()
end

function CMallMgr:LoadData()
	local oDB = goDBMgr:GetSSDB(nServerID, "global", CUtil:GetServiceID())
	--全局数据
	local tData = oDB:HGet(gtDBDef.sShopDB,"data")
	if tData ~= "" then
		local tSData = cjson.decode(tData)
		for nShopType, tShopData in pairs(tSData) do
			if nShopType ~= "m_nUpdateTime" then
				self.m_tShopMap[nShopType]:LoadData(tShopData)
			end
		end
		self.m_nUpdateTime = tSData.m_nUpdateTime or  os.time()
	end
	self:ZeroUpdate()
	self:RegHourTimer()
 end

 --定期保存玩家数据
 function CMallMgr:TickRoleData()
 	self:SaveData()
 end

 function CMallMgr:init()
 	self:LoadData()
 	self.m_nRoleDataTimer = GetGModule("TimerMgr"):Interval(gtGDef.tConst.nAutoSaveTime, function () self:TickRoleData() end)
	if #self.m_tShopMap[gtShopType.eChamberCore].m_tShotList == 0 then
		self.m_tShopMap[gtShopType.eChamberCore]:init()
	end
	self:MarkDirty(true)
 end

function CMallMgr:Release()
	self:SaveData()
	GetGModule("TimerMgr"):Clear(self.m_nRoleDataTimer)
	GetGModule("TimerMgr"):Clear(self.m_nHourTimer)
	self.m_nHourTimer = nil
	self.m_nRoleDataTimer = nil
end

function CMallMgr:SaveData() 
	if not self:IsDirty() then
		return 
	end
	local oDB = goDBMgr:GetSSDB(nServerID, "global", CUtil:GetServiceID())
	local tData = {}
	for nShopType, oShop in pairs(self.m_tShopMap) do
		tData[nShopType] = oShop:SaveData()
	end
	tData.m_nUpdateTime = self.m_nUpdateTime
	oDB:HSet(gtDBDef.sShopDB, "data", cjson.encode(tData))
	self:MarkDirty(false)
end

--获取子商店
function CMallMgr:GetSubShop(nShopType)
	return self.m_tShopMap[nShopType]
end

function CMallMgr:IsDirty()
	 return self.m_bDirty 
end
function CMallMgr:MarkDirty(bDirty)
	 self.m_bDirty = bDirty
end

--零点刷新数据
function CMallMgr:ZeroUpdate(bFlag)
	if not os.IsSameDay(self.m_nUpdateTime, os.time()) then
		for _, tShop in pairs(self.m_tShopMap) do
			tShop:ZeroUpdate()
		end
		self.m_nUpdateTime = os.time()
		self:MarkDirty(true)
	end
	if bFlag then
		self:RegHourTimer()
	end
end

--注册整点计时器
function CMallMgr:RegHourTimer()
  	GetGModule("TimerMgr"):Clear(self.m_nHourTimer)
  	self.m_nHourTimer = nil

    --改用到零点的时间,而不用每小时检查
   	local nNextDayTime  = os.NextDayTime(os.time())
    self.m_nHourTimer = GetGModule("TimerMgr"):Interval(nNextDayTime, function() self:ZeroUpdate(true) end)
end

function CMallMgr:OutMallInfo(nShopType)
	print(self.m_tShopMap)
end

--主要检测一些商会数据有没有修改过,因为这些数据是存DB的
function CMallMgr:InitCfg()
	--商会数据刷新检测
	self.m_tShopMap[gtShopType.eChamberCore]:init()
end
