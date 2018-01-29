--兴圣宫(私信)
local table, string, math, os, pairs, ipairs, assert = table, string, math, os, pairs, ipairs, assert

-- 事件配置预处理
local _ZouZhangEventsConf = {}                               -- 私信事件表
local function PreProcessEventsConf()
	for _, tConf in ipairs(ctZouZhangConf) do
		_ZouZhangEventsConf[tConf.nType] = _ZouZhangEventsConf[tConf.nType] or {}
		table.insert(_ZouZhangEventsConf[tConf.nType], tConf)
	end
end
PreProcessEventsConf()

local nInitZouZhang = 3 --初始私信数
local nZouZhangRecoverTime = 1800 --恢复时间30分钟
function CZouZhang:Ctor(oPlayer)	
	self.m_oPlayer = oPlayer
	self.m_nCurrZZ = nInitZouZhang							--当前拥有私信
	self.m_nLastZouZhangRecoverTime = os.time() 			--恢复时间

	--不需要保存
	self.m_nEventID = 0 	                                --事件ID
	self.m_sDiQuName = "" 									--地区名字(已取消)

	self.m_nMCID1 = 0 										--事件知己ID
	self.m_nMCID2 = 0 										--赴约知己名字

	self.m_sMCName1 = "" 									--事件知己名字 	
	self.m_sMCName2 = "" 									--赴约知己名字

	--奖励类型,奖励数量,知己ID,属性ID
	self.m_tAward = {{0,0,0,0},{0,0,0,0}} 					--奖励
	self.m_nZouZhangTick = nil 								--定时器
end

--私信上限
function CZouZhang:MaxZZ(nVal, bUseProp)
	local nLevel = self.m_oPlayer:GetLevel()
	return ctLevelConf[nLevel].nMaxZZ
end

function CZouZhang:LoadData(tData)
	if tData then
		self.m_nEventID = tData.m_nEventID
		self.m_nCurrZZ = tData.m_nCurrZZ or 0
		self.m_nLastZouZhangRecoverTime = tData.m_nLastZouZhangRecoverTime or self.m_nLastZouZhangRecoverTime
		self.m_nLastZouZhangRecoverTime = math.min(self.m_nLastZouZhangRecoverTime, os.time()) --处理往前调时间的情况
	else
		self:MarkDirty(true) --要保存出初数据(新号)
	end
end

function CZouZhang:SaveData()
	if not self:IsDirty() then
		return
	end
	self:MarkDirty(false)

	local tData = {}
	tData.m_nCurrZZ = self.m_nCurrZZ
	tData.m_nEventID = self.m_nEventID
	tData.m_nLastZouZhangRecoverTime = self.m_nLastZouZhangRecoverTime
	return tData
end

function CZouZhang:GetType()
	return gtModuleDef.tZouZhang.nID, gtModuleDef.tZouZhang.sName
end 

--离线
function CZouZhang:Offline()
	goTimerMgr:Clear(self.m_nZouZhangTick) 	--回收定时器
   	self.m_nZouZhangTick = nil --置空
end

function CZouZhang:Online()                                       --上线
	self:CheckZZRecover()
	self:CheckRedPoint()										  --检测小红点
end

--增加私信/扣除私信
function CZouZhang:AddZouZhang(nVal, sReason, bUseProp)
	local nOrgZZ = self.m_nCurrZZ
	if bUseProp then --使用道具可以超过上限
		self.m_nCurrZZ = math.max(0, self.m_nCurrZZ+nVal)
	else
		self.m_nCurrZZ = math.min(self:MaxZZ(), math.max(0, self.m_nCurrZZ+nVal))
	end
	self:MarkDirty(true)

	if nOrgZZ ~= self.m_nCurrZZ then
		local nEventID = nVal > 0 and gtEvent.eAddItem or gtEvent.eSubItem  --日志系统事件ID
		goLogger:AwardLog(nEventID, sReason, self.m_oPlayer, gtItemType.eCurr, gtCurrType.eZouZhang, nVal, self.m_nCurrZZ) --日志事件列表，反馈到mysql
		self:ZouZhangCountReq()
	end
	self:CheckRedPoint() --检测小红点
end

--注册计时器
function CZouZhang:CheckZZRecover()
	goTimerMgr:Clear(self.m_nZouZhangTick)
	self.m_nZouZhangTick = nil

	local nZouZhangTime = os.time() - self.m_nLastZouZhangRecoverTime             -- 时间差
	local nZouZhangAdd = math.floor(nZouZhangTime / nZouZhangRecoverTime)        -- 增加私信数
	if nZouZhangAdd > 0 then                                                                                                        
		self.m_nLastZouZhangRecoverTime = self.m_nLastZouZhangRecoverTime + nZouZhangAdd*nZouZhangRecoverTime
		self:MarkDirty(true)                                                     -- 保存
		self:AddZouZhang(nZouZhangAdd, "定时恢复")
	end
	local nRemainTimeSec = self.m_nLastZouZhangRecoverTime + nZouZhangRecoverTime - os.time()
	assert(nRemainTimeSec > 0, "时间错误:"..nRemainTimeSec)

    self.m_nZouZhangTick = goTimerMgr:Interval(nRemainTimeSec, function() self:CheckZZRecover() end)
end

-- 取下次私信恢复剩余时间
function CZouZhang:GetZouZhangRecoverTime()
	local nRemainTimeSec = math.max(0, self.m_nLastZouZhangRecoverTime + nZouZhangRecoverTime - os.time())
	return nRemainTimeSec
end

function CZouZhang:CheckOpen(bTips)
	local nChapter = ctJLDEtcConf[1].nZZChapter
	local bOpen = self.m_oPlayer.m_oDup:IsChapterPass(nChapter)
	if not bOpen then
		if bTips then
			self.m_oPlayer:Tips(string.format("通关第%d章：%s开启", nChapter, CDup:ChapterName(nChapter)))
		end
		return
	end
	return true
end

--当前私信数量
function CZouZhang:ZouZhangCountReq()
	print("CZouZhang:ZouZhangCountReq***", self.m_nCurrZZ)
	local tMsg = {
		nZZCount = self.m_nCurrZZ,
		nZZRecoverTime = self:GetZouZhangRecoverTime(),
		bOpen = self:CheckOpen()
	}
	CmdNet.PBSrv2Clt(self.m_oPlayer:GetSession(), "ZZZouZhangRet", tMsg)
end

--生成地区奖励
function CZouZhang:GenDiQuAward(nAwardType, tMCQua, nMCLv)
	--奖励类型,奖励数量,知己ID,属性ID
	local tAward = {nAwardType, 0, 0, 0}

	local function _CalcAward(nAttr, nLv)
		return math.floor(10+nAttr*2+(1+nLv)*nLv*nAttr/10)*10+3000
	end

	if nAwardType == 1 then --银两
		local nRnd = math.random(1, 100)
		if nRnd <= 75 then
			tAward[2] = _CalcAward(tMCQua[1], nMCLv)
		else
			tAward[2] = _CalcAward(tMCQua[4], nMCLv)
		end

	elseif nAwardType == 2 then --文化
		local nRnd = math.random(1, 100)
		if nRnd <= 75 then
			tAward[2] = _CalcAward(tMCQua[2], nMCLv)
		else
			tAward[2] = _CalcAward(tMCQua[4], nMCLv)
		end

	elseif nAwardType == 3 then --兵力
		local nRnd = math.random(1, 100)
		if nRnd <= 75 then
			tAward[2] = _CalcAward(tMCQua[3], nMCLv)
		else
			tAward[2] = _CalcAward(tMCQua[4], nMCLv)
		end

	end
	return tAward
end

--打开界面
function CZouZhang:InfoReq()
	if not self:CheckOpen(true) then
		return
	end

	if self.m_nCurrZZ <= 0 then
		return self.m_oPlayer:Tips("当前没有私信")   -- Tips通用飘字信息
	end

	local nType = 0
	local nRnd = math.random(1, 100)
	if nRnd <= 28 then 
		nType = 2 --知己事件
	else
		nType = 1 --地区事件
	end

	local tConfList = _ZouZhangEventsConf[nType]
	local nRnd = math.random(#tConfList)
	local tConf = assert(tConfList[nRnd])
	self.m_nEventID = tConf.nID

	if nType == 1 then -- 地区事件
		-- local nRnd = math.random(#ctZouZhangDiQuConf)      	--随机地区
		-- self.m_sDiQuName = ctZouZhangDiQuConf[nRnd].sName 	--获取地区名字(策划说去掉地区)
		local oMC = self.m_oPlayer.m_oMingChen:RandObj(1)[1]  	--随机知己
		self.m_nMCID1 = oMC:GetID()                           	--获取知己ID
		self.m_sMCName1 = oMC:GetName() 

		local nMCLv, tMCQua = oMC:GetLevel(), oMC:GetQua() 	--获取知己等级
		self.m_tAward[1] = self:GenDiQuAward(tConf.nAward1, tMCQua, nMCLv)
		self.m_tAward[2] = self:GenDiQuAward(tConf.nAward2, tMCQua, nMCLv)

	elseif nType == 2 then --知己事件
		local tMCList = self.m_oPlayer.m_oMingChen:RandObj(2)                              
		local oMC1 = tMCList[1] --邀请知己
		local oMC2 = tMCList[2] --已和知己有约的知己
		self.m_sMCName1 = oMC1:GetName() 
		self.m_sMCName2 = oMC2:GetName()

		self.m_nMCID1 = oMC1:GetID()
		self.m_nMCID2 = oMC2:GetID()

		local nAttrID = math.random(1, 4) 	--随机属性 
		local nAttrVal = math.random(2, 4) 	--随机获取奖励点数
		self.m_tAward[1] = {tConf.nAward1, nAttrVal, self.m_nMCID1, nAttrID}
		self.m_tAward[2] = {tConf.nAward2, nAttrVal, self.m_nMCID2, nAttrID}
	end

	--奖励列表
	local tAwardList = {}
	for _, tAward in ipairs(self.m_tAward) do
		local tTmp = {nType=tAward[1], nNum=tAward[2], nMCID=tAward[3], nAttrID=tAward[4]}
		table.insert(tAwardList, tTmp)
	end
   
   	--国家经验
  	local nLevel = self.m_oPlayer:GetLevel()
	local nZZExp = ctLevelConf[nLevel].nZZExp
    local tMsg = {
	    nEventID = self.m_nEventID,
	    nMCID1 = self.m_nMCID1,
	    nMCID2 = self.m_nMCID2,
	    sMCName1 = self.m_sMCName1,
	    sMCName2 = self.m_sMCName2,
	    sDiQuName = self.m_sDiQuName,
	    tAwardList = tAwardList,
	    nZZExp = nZZExp,
	} 
    CmdNet.PBSrv2Clt(self.m_oPlayer:GetSession(), "ZZInfoRet", tMsg)
    self:MarkDirty(true)
end

--盖章请求
function CZouZhang:AwardReq(nSelect)
	assert(nSelect == 1 or nSelect == 2, "盖章选项错误")
	if self.m_nCurrZZ <= 0 then --判断是否有私信
		return self.m_oPlayer:Tips("当前没有私信")
	end
	if self.m_nEventID == 0 then
		return self.m_oPlayer:Tips("当前没有事件") --判断是否有事件
	end

	--扣除私信
	self:AddZouZhang(-1, "盖章消耗")

	--发放奖励
	local tAward = self.m_tAward[nSelect]
	if tAward[1] == 1 then --银两
	    self.m_oPlayer:AddItem(gtItemType.eCurr, gtCurrType.eYinLiang, tAward[2], "私信奖励银两")

	elseif tAward[1] == 2 then --文化
	    self.m_oPlayer:AddItem(gtItemType.eCurr, gtCurrType.eWenHua, tAward[2], "私信奖励文化")

	elseif tAward[1] == 3 then --兵力
	    self.m_oPlayer:AddItem(gtItemType.eCurr, gtCurrType.eBingLi, tAward[2], "私信奖励兵力")
	end
	if tAward[1] == 4 or tAward[1] == 5 then --上奏/被举报知己奖励
		local nAttrID = tAward[4]
		local nAttrVal = tAward[2]
		local nMCID = tAward[3]
		local oMC = self.m_oPlayer.m_oMingChen:GetObj(nMCID)
		oMC:AddZouZheAttr(nAttrID, nAttrVal)
	end

	--增加国家经验
	local nLevel = self.m_oPlayer:GetLevel()
	local nZZExp = ctLevelConf[nLevel].nZZExp
	self.m_oPlayer:AddItem(gtItemType.eCurr, gtCurrType.eCountryExp, nZZExp, "私信")

	self.m_nEventID = 0 
	self:MarkDirty(true)

	CmdNet.PBSrv2Clt(self.m_oPlayer:GetSession(), "ZZAwardRet", {nSelect=nSelect})

	--增加国家经验
	local nLevel = self.m_oPlayer:GetLevel()
	local nZZExp = ctLevelConf[nLevel].nZZExp
	self.m_oPlayer:AddItem(gtItemType.eCurr, gtCurrType.eCountryExp, nZZExp, "奏章获得国家经验")

	--任务
	self.m_oPlayer.m_oMainTask:Progress(gtMainTaskType.eCond5, 1)
	self.m_oPlayer.m_oDailyTask:Progress(gtDailyTaskType.eCond7, 1)
	--成就
	self.m_oPlayer.m_oAchievements:SetAchievement(gtAchieDef.eCond9, 1)
	--活动
    goHDMgr:GetHuoDong(gtHDDef.eTimeAward):UpdateVal(self.m_oPlayer:GetCharID(), gtTAType.eSX, 1)
end

--增加私信数
function CZouZhang:AddZouZhangTimesReq(nNum)
	if self.m_nCurrZZ > 0 then 
		return self.m_oPlayer:Tips("当前有次数不能增加")
	end

	local nZWLProp = ctZouZhangEtcConf[1].nZWLProp
	local nCurrNum = self.m_oPlayer:GetItemCount(gtItemType.eProp, nZWLProp)
	if nCurrNum < nNum then 
		return self.m_oPlayer:Tips(string.format("%s不足", CGuoKu:PropName(nZWLProp)))
	end
	self.m_oPlayer:SubItem(gtItemType.eProp, nZWLProp, nNum, "使用政务令")

	self:AddZouZhang(nNum, "政务令恢复次数", true)
	self:ZouZhangCountReq()
	self.m_oPlayer:Tips("私信次数+"..nNum)
end

--检测小红点
function CZouZhang:CheckRedPoint()
	if not self:CheckOpen() then
		return self.m_oPlayer.m_oRedPoint:MarkRedPoint(gtRPDef.eZouZhang, 0)
	end
	if self.m_nCurrZZ > 0 then  
		return self.m_oPlayer.m_oRedPoint:MarkRedPoint(gtRPDef.eZouZhang, 1)
	end
	self.m_oPlayer.m_oRedPoint:MarkRedPoint(gtRPDef.eZouZhang, 0)
end

