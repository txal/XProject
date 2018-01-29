--请安折(已取消)
local table, string, math, os, pairs, ipairs, assert = table, string, math, os, pairs, ipairs, assert

--请安文本预处理
local _QingAnZheTextsConf = {}                               -- 请安文本表
local function PreProcessTextsConf()
	for _, tConf in ipairs(ctQingAnZheTextConf) do
		_QingAnZheTextsConf[tConf.nType] = _QingAnZheTextsConf[tConf.nType] or {}
		table.insert(_QingAnZheTextsConf[tConf.nType], tConf)
	end
end
-- PreProcessTextsConf()

local nMaxQAZ = 4                    	--折子上限
local nQingAnZheRecoverTime = 3600      --折子恢复所需的时间		
function CQingAnZhe:Ctor(oPlayer)
	self.m_oPlayer = oPlayer
	self.m_nCurrQAZ = 0                   			--当前拥有的折子数
	self.m_nLastQingAnZheRecoverTime = os.time()	--折子恢复时间
	self.m_bOpen = false

	--不用保存
	self.m_tAward = {nType=0, nID=0, nNum=0}             --奖励物品
	self.m_nQingAnZheTick = nil           --定时器 
end

function CQingAnZhe:LoadData(tData)
	if tData then
		self.m_nCurrQAZ = tData.m_nCurrQAZ
		self.m_nLastQingAnZheRecoverTime = tData.m_nLastQingAnZheRecoverTime or self.m_nLastQingAnZheRecoverTime
		self.m_nLastQingAnZheRecoverTime = math.min(self.m_nLastQingAnZheRecoverTime, os.time())
		self.m_bOpen = tData.m_bOpen or self.m_bOpen
	else
		self:MarkDirty(true) --要保存出初数据(新号)
	end
end

function CQingAnZhe:SaveData()
	if not self:IsDirty() then return end
	self:MarkDirty(false)

	local tData = {}
	tData.m_bOpen = self.m_bOpen
	tData.m_nCurrQAZ = self.m_nCurrQAZ
	tData.m_nLastQingAnZheRecoverTime = self.m_nLastQingAnZheRecoverTime
	return tData
end

function CQingAnZhe:GetType()
	return gtModuleDef.tQingAnZhe.nID, gtModuleDef.tQingAnZhe.sName
end 

function CQingAnZhe:Online()
	if not self.m_bOpen then
		return
	end
	self:RecoverZheZiTimer()																									
	self:CheckRedPoint()
end

function CQingAnZhe:Offline()
	if self.m_nQingAnZheTick then
		GlobalExport.CancelTimer(self.m_nQingAnZheTick)
		self.m_nQingAnZheTick = nil
	end
end

--皇子结婚事件
function CQingAnZhe:OnHZMarried()
	if self.m_bOpen then
		return
	end
	self.m_bOpen = true
	self.m_nCurrQAZ = 1
	self.m_nLastQingAnZheRecoverTime = os.time()
	self:RegRecoverTick()
	self:QingAnZheCountReq()
	self:MarkDirty(true)
end

--增/减折子
function CQingAnZhe:AddQingAnZhe(nVal, sReason)
	assert(nVal and sReason, "参数非法")
	local nOrgQAZ = self.m_nCurrQAZ
	self.m_nCurrQAZ = math.min(nMaxQAZ, math.max(0, self.m_nCurrQAZ + nVal))
	self:CheckRedPoint()
	self:MarkDirty(true)
	if nOrgQAZ ~= self.m_nCurrQAZ then
		local nEventID = nVal > 0 and gtEvent.eAddItem or gtEvent.eSubItem
		goLogger:AwardLog(nEventID, sReason, self.m_oPlayer, gtItemType.eCurr, gtCurrType.eQingAnZhe, nVal, self.m_nCurrQAZ)
		self:QingAnZheCountReq()
	end
end

--注册计时器
function CQingAnZhe:RegRecoverTick()
	if self.m_nQingAnZheTick then
		GlobalExport.CancelTimer(self.m_nQingAnZheTick)
		self.m_nQingAnZheTick = nil
	end

	local nRemainTimeSec = self.m_nLastQingAnZheRecoverTime + nQingAnZheRecoverTime - os.time()
	assert(nRemainTimeSec > 0)
    self.m_nQingAnZheTick = GlobalExport.RegisterTimer(nRemainTimeSec*1000, function()
    	self.m_nLastQingAnZheRecoverTime = os.time()
		self:AddQingAnZhe(1, "定时恢复")
    	self:RegRecoverTick()
    	self:MarkDirty(true)
    end)
end

--折子恢复处理
function CQingAnZhe:RecoverZheZiTimer()
	local nNowTime = os.time()
	local nQingAnZheTime = nNowTime - self.m_nLastQingAnZheRecoverTime
	local nQingAnZheAdd = math.floor(nQingAnZheTime / nQingAnZheRecoverTime)

	if nQingAnZheAdd > 0 then
		self.m_nLastQingAnZheRecoverTime = self.m_nLastQingAnZheRecoverTime + nQingAnZheAdd * nQingAnZheRecoverTime
		self:AddQingAnZhe(nQingAnZheAdd, "上线恢复")
		self:MarkDirty(true)
	end
	
	self:RegRecoverTick()
end

-- 取下次请安折恢复剩余时间
function CQingAnZhe:GetQingAnZheRecoverTime()
	local nRemainTimeSec = math.max(0, self.m_nLastQingAnZheRecoverTime + nQingAnZheRecoverTime - os.time())
	return nRemainTimeSec
end


--当前请安折数量
function CQingAnZhe:QingAnZheCountReq()
	local tMsg = {nQAZCount = 0, nQAZRecoverTime = 0, bOpen = self.m_bOpen}
	if self.m_bOpen then
		tMsg.nQAZCount = self.m_nCurrQAZ
		tMsg.nQAZRecoverTime = self:GetQingAnZheRecoverTime()
	end
	CmdNet.PBSrv2Clt(self.m_oPlayer:GetSession(), "QingAnZheRet", tMsg)
end

--请安文本处理
function CQingAnZhe:QingAnZheText()
	--安人ID、头像、名字，配偶ID、头像、配偶名字，文本ID，性别
	local tQingAnItem = {0, 0, 0, 0, 0, 0, 0, 0}                         
	local nTyped = 0 -- 文本类型

	local tHZList = self.m_oPlayer.m_oZongRenFu:RandMarriedObj(1)
	if #tHZList <= 0 then
		return self.m_oPlayer:Tips("没有已婚皇子")
	end

	local nAnRenID = 0                                      
	local oAnRen = tHZList[1]                                  --随机已婚安人
	local sAnRenIcon = oAnRen:GetIcon() 						--取安人头像
	local sAnRenName = oAnRen:GetName()	                --获取安人名字
	local nGender = oAnRen:GetGender()                   --获取性别

	local tPeiOu = oAnRen:GetPO()                        --获取配偶
	assert(tPeiOu.nID > 0, "没有配偶")

	local nPeiOuID = 0
	local oPeiOu = tPeiOu
	local sPeiOuIcon = oPeiOu.sIcon                      --获取配偶头像
	local sPeiOuName = oPeiOu.sName                      --获取配偶名字

	local nRnd = math.random(1, 100)
	if nRnd >= 1 and nRnd <= 25 then                            --阿哥、格格
		if nGender == 1 then
			nTyped = 1
		else
			nTyped = 2
		end 
		tQingAnItem[1] = oAnRen:GetID()                     --获取安人ID
		tQingAnItem[2] = sAnRenIcon
		tQingAnItem[3] = sAnRenName

	elseif nRnd >= 26 and nRnd <= 50 then                       --福晋、驸马
		if nGender == 1 then 
			nTyped = 3
		else
			nTyped = 4
		end
		tQingAnItem[4] = oPeiOu.nID
		tQingAnItem[5] = sPeiOuIcon
		tQingAnItem[6] = sPeiOuName

	elseif nRnd >= 51 and nRnd <= 100 then                     --双人出席
		nTyped = 5
		tQingAnItem[1] = oAnRen:GetID()                     --获取安人ID
		tQingAnItem[4] = oPeiOu.nID
		tQingAnItem[2] = sAnRenIcon
		tQingAnItem[3] = sAnRenName
		tQingAnItem[5] = sPeiOuIcon
		tQingAnItem[6] = sPeiOuName
	end

	local tConf = _QingAnZheTextsConf[nTyped]
	local nRnd = math.random(#tConf)
	tQingAnItem[7] = tConf[nRnd].nID

	if nTyped == 1 or nTyped == 2 or nTyped == 5 then
		nJueWei = oAnRen:GetJueWei()
	end
	if nTyped == 3 or nTyped == 4 then
		nJueWei = oPeiOu.nJueWei
	end

	tQingAnItem[8] = nGender
	local tItem = goQAZDropMgr:GetItem(nJueWei)
	local tTmp = {nAnRenID=tQingAnItem[1], sAnRenIcon=tQingAnItem[2], sAnRenName=tQingAnItem[3], nPeiOuID=tQingAnItem[4], sPeiOuIcon=tQingAnItem[5], sPeiOuName=tQingAnItem[6], nTextID=tQingAnItem[7], nGender=tQingAnItem[8], nType=tItem[1], nID=tItem[2], nNum=tItem[3]}
	self.m_tAward = {nType=tItem[1], nID=tItem[2], nNum=tItem[3]}

	return tTmp
end

--界面显示
function CQingAnZhe:InfoReq()
	if self.m_nCurrQAZ <= 0 then 
		return self.m_oPlayer:Tips("当前没有请安折")
	end
	local tMsg = self:QingAnZheText()
	if not tMsg then
		return
	end
  	CmdNet.PBSrv2Clt(self.m_oPlayer:GetSession(), "QAZInfoRet", tMsg)
  	self:SendAward()
end

-- 发放奖励
function CQingAnZhe:SendAward()
	if self.m_nCurrQAZ <= 0 then 
		return self.m_oPlayer:Tips("当前没有请安折")
	end
	self:AddQingAnZhe(-1, "扣除请安折")
	local tAward = self.m_tAward
    if tAward.nType == gtItemType.eProp then
		self.m_oPlayer:AddItem(tAward.nType, tAward.nID, tAward.nNum, "请按折使用")
	end
	--任务
	-- ----self.m_oPlayer.m_oMainTask:Progress(gtMainTaskType.eCond43, 1)
end

--检测小红点
function CQingAnZhe:CheckRedPoint()
	if self.m_nCurrQAZ > 0 then
		return self.m_oPlayer.m_oRedPoint:MarkRedPoint(gtRPDef.eQingAnZhe, 1)
	end
	self.m_oPlayer.m_oRedPoint:MarkRedPoint(gtRPDef.eQingAnZhe, 0)
end  

--使用道具增加请安折
-- function CQingAnZhe:UsePropReq(nNum)
-- 	if self.m_nCurrQAZ == 0 then 
-- 		return self.m_oPlayer:Tips("当前有请安折不能使用")
-- 	end

-- 	local tProp = 
-- 	if self.m_oPlayer:GetItemCount(gtItemType.eProp, tProp[2]) < tProp[3] then 
-- 		return self.m_oPlayer:Tips(string.format("%s不足", CGuoKu:PropName(tProp[2])))
-- 	end
-- 	self.m_oPlayer:SubItem(gtItemType.eProp, tProp[2], nNum, "使用物品")
-- 	self:AddQingAnZhe(nNum, "使用物品")
-- 	self.m_oPlayer:Tips("请安折+"..nNum)
-- 	self:QingAnZheCountReq()
-- end