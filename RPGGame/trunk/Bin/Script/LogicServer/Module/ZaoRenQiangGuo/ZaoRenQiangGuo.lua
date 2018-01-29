--小游戏造人强国
local table, string, math, os, pairs, ipairs, assert = table, string, math, os, pairs, ipairs, assert

function CZaoRenQiangGuo:Ctor(oPlayer)
	self.m_oPlayer = oPlayer
	self:Init()
end

function CZaoRenQiangGuo:Init(nVersion)
	nVersion = nVersion or 0
	self.m_nVersion = nVersion
	self.m_nZTTime = 0            		--使用坐胎药时间开始
	self.m_nDZTime = 0             		--使用多子丹时间开始
	self.m_nLastTime = 0              	--上次关闭活动界面时间
	self.m_nState = 0                	--开启关闭游戏界面状态(0.打开，1.关闭)
	self.m_nSoldiers = 0           		--累积人数
	self.m_nLastReportTime = os.time()	--上次上报时间
end

function CZaoRenQiangGuo:LoadData(tData)
	if tData then
		self.m_nVersion = tData.m_nVersion
		self.m_nZTTime = tData.m_nZTTime
		self.m_nDZTime = tData.m_nDZTime
		self.m_nState = tData.m_nState
		self.m_nSoldiers = tData.m_nSoldiers
		self.m_nLastTime = tData.m_nLastTime
	end
end

function CZaoRenQiangGuo:SaveData()
	if not self:IsDirty() then
		return
	end  
	self:MarkDirty(false)

	local tData = {}
	tData.m_nVersion = self.m_nVersion
	tData.m_nState = self.m_nState
	tData.m_nSoldiers = self.m_nSoldiers
	tData.m_nLastTime = self.m_nLastTime
	tData.m_nDZTime = self.m_nDZTime
	tData.m_nZTTime = self.m_nZTTime
	return tData
end

function CZaoRenQiangGuo:GetType()
	return gtModuleDef.tZaoRenQiangGuo.nID, gtModuleDef.tZaoRenQiangGuo.sName
end

--玩家上线
function CZaoRenQiangGuo:Online()
	self:SyncInfo()
end

--玩家离线
function CZaoRenQiangGuo:Offline()
	self:OffInterfaceReq()
end

--离开界面请求
function CZaoRenQiangGuo:OffInterfaceReq()
	if self.m_nState == 1 then
		self.m_nState = 0
		self.m_nLastTime = os.time()
		self:MarkDirty(true)
	end
end

--活动是否开启
function CZaoRenQiangGuo:IsOpen()
	local oAct = goHDMgr:GetHuoDong(gtHDDef.eZaoRenQiangGuo)
	if oAct and oAct:IsOpen() then
		--活动版本不一致就重置数据
		local nVersion = oAct:GetVersion()
		if nVersion ~= self.m_nVersion then
			self:Init(nVersion)
			self:MarkDirty(true)
		end
		return true
	end
end

--坐胎药效果时间
function CZaoRenQiangGuo:ZTEffTime()
	local nEffectTime = ctUseMedicationConf[1].nEff
	local nRemainCD = math.max(0, self.m_nZTTime+nEffectTime-os.time())
	return nRemainCD
end

--坐胎药CD剩余时间
function CZaoRenQiangGuo:ZTCDTime()
	local nCDTime = ctUseMedicationConf[1].nCD
	local nRemainCD = math.max(0, self.m_nZTTime+nCDTime-os.time())
	return nRemainCD
end

--多子丹效果时间
function CZaoRenQiangGuo:DZEffTime()
	local nEffectTime = ctUseMedicationConf[2].nEff
	local nRemainCD = math.max(0, self.m_nDZTime+nEffectTime-os.time())
	return nRemainCD
end

--多子丹CD剩余时间
function CZaoRenQiangGuo:DZCDTime()
	local nCDTime = ctUseMedicationConf[2].nCD
	local nRemainCD = math.max(0, self.m_nDZTime+nCDTime-os.time())
	return nRemainCD
end

--使用丹药请求
function CZaoRenQiangGuo:UseDYReq(nType)
	assert(nType==1 or nType==2, "丹药类型错误")
	if not self:IsOpen() then
		return 
	end
	
	local oAct = goHDMgr:GetHuoDong(gtHDDef.eZaoRenQiangGuo)
	if oAct:GetState() ~= CHDBase.tState.eStart then					   --是否在活动时间内
		return self.m_oPlayer:Tips("活动暂未开始，请皇上稍待几日") 
	end
	if nType == 1 then			--坐胎药
		if self:ZTCDTime() > 0 then
			return self.m_oPlayer:Tips("坐胎药冷却中，不能使用")
		end

	elseif nType == 2 then		--多子丹
		if self:DZCDTime() > 0 then
			return self.m_oPlayer:Tips("多子丹冷却中，不能使用")
		end
	end
	
	--不能同时使用	
	if self:ZTEffTime() > 0 or self:DZEffTime() > 0 then
		return self.m_oPlayer:Tips("不能同时使用坐胎药和多子丹")
	end
	if nType == 1 then 
		self.m_nZTTime = os.time()
	elseif nType == 2 then
		self.m_nDZTime = os.time()
	end	
	self:MarkDirty(true)
	self:SyncInfo()
end

--添加造人数量
function CZaoRenQiangGuo:AddSoldiers(nSoldiers, sReason)
	if self.m_nSoldiers >= ctMaxSoldiersEtcConf[1].nMaxSoldiers then 
		return 
	else
		local nLastSoldiers = self.m_nSoldiers
		self.m_nSoldiers = math.min(self.m_nSoldiers+nSoldiers, ctMaxSoldiersEtcConf[1].nMaxSoldiers)
		local nRealSoldiers = self.m_nSoldiers - nLastSoldiers
		if nRealSoldiers > 0 then
			self.m_oPlayer:AddItem(gtItemType.eCurr, gtCurrType.eBingLi, nRealSoldiers, sReason)
		end
	end 
	self:MarkDirty(true)
	return nRealSoldiers
end

--造人校验
function CZaoRenQiangGuo:ReportSoldierReq(nSoldiers, nType)
	assert(nSoldiers >= 0)
	assert(nType==0 or nType==1 or nType==2, "丹药类型错误")
	
	if not self:IsOpen() then
		return self.m_oPlayer:Tips("今天没有活动哦，请皇上稍待几日")
	end
	local oAct = goHDMgr:GetHuoDong(gtHDDef.eZaoRenQiangGuo)
	if oAct:GetState() ~= CHDBase.tState.eStart then					--是否在活动时间内
		return  
	end
	if self.m_nSoldiers < ctMaxSoldiersEtcConf[1].nMaxSoldiers then 
		local nMaxnSoldiers = 0												--可接受最大点击造人数
		local nMaxClickPerSec = 20  										--每秒最大可接受点击数
		local nPassSecond = os.time() - self.m_nLastReportTime				--上一次到现在的时间段
		self.m_nLastReportTime = os.time()

		if nType == 0 then 
			nMaxnSoldiers = (nPassSecond * nMaxClickPerSec * ctUseMedicationConf[0].nYL)
		elseif nType == 1 then 
			nMaxnSoldiers = (nPassSecond * nMaxClickPerSec * ctUseMedicationConf[1].nYL)
		elseif nType == 2 then 
			nMaxnSoldiers = (nPassSecond * nMaxClickPerSec * ctUseMedicationConf[2].nYL)  
		end
		
		if nSoldiers > nMaxnSoldiers then 
	    	self.m_oPlayer:Tips("已超生，请不要点太快!")
	    	LuaTrace("造人超出最大值，有作弊嫌疑:", self.m_oPlayer:GetName(), nSoldiers, nType, nMaxnSoldiers, nPassSecond)
	    else
	    	self:AddSoldiers(nSoldiers, "点击造人获得士兵数:"..nSoldiers..":"..nType)
	    end
	else
		self.m_oPlayer:Tips("皇上, 造人数量已达上限")
	end
	self:SyncInfo()
end

--取当前最大造人等级
function CZaoRenQiangGuo:LevelSoldiers()
	local LevelSoldiers = 0
	for nID, tConf in ipairs(ctSoldiersConf) do 
		LevelSoldiers = tConf.nSoldiers
		if LevelSoldiers > self.m_nSoldiers then 
			break
		end
	end
	return LevelSoldiers
end

--同步界面
function CZaoRenQiangGuo:SyncInfo(nGetSoldiers)
	local nGetSoldiers = nGetSoldiers or 0 
	if not self:IsOpen() then
		return 
	end
	local oAct = goHDMgr:GetHuoDong(gtHDDef.eZaoRenQiangGuo)
	if oAct:GetState() ~= CHDBase.tState.eStart then					   --是否在活动时间内
		return 
	end
	local nSoldiers = self.m_nSoldiers
	local nLevelSoldiers = self:LevelSoldiers()
	if nSoldiers > 0 then
		goRankingMgr.m_oZRQGRanking:Update(self.m_oPlayer, nSoldiers)  	   --更新排行榜
	end

	local nBeginTime, nEndTime, nAwardTime = oAct:GetActTime()
	local nStateTime = oAct:GetStateTime()
	local nZTCDTime = self:ZTCDTime()
	local nDZCDTime = self:DZCDTime()
	local nZTEffTime = self:ZTEffTime()
	local nDZEffTime = self:DZEffTime()
	
	local tMsg = {
		nState = oAct:GetState(),		--活动状态
		nBeginTime = nBeginTime ,		--活动开始时间
		nEndTime   = nEndTime,			--活动结束时间
		nStateTime = nStateTime,		--活动剩余状态
		nZTCDTime  = nZTCDTime,			--坐胎药CD时间
		nZTEffTime = nZTEffTime,		--坐胎药效果时间
		nDZCDTime  = nDZCDTime,			--多子丹CD时间
		nDZEffTime = nDZEffTime,		--多子丹效果时间
		nSoldiers  = nSoldiers,			--当前造人累积士兵数
		nGetSoldiers = nGetSoldiers,	--上次退出再登奖励的士兵数
		nLevelSoldiers = nLevelSoldiers, 	--当前阶段最大士兵数
		nMaxSoldiers = ctMaxSoldiersEtcConf[1].nMaxSoldiers 	--活动最大上限造人数量
	}
	CmdNet.PBSrv2Clt(self.m_oPlayer:GetSession(), "ZRQGInfoRet", tMsg)
end

--界面显示
function CZaoRenQiangGuo:InfoReq()
	if not self:IsOpen() then
		return self.m_oPlayer:Tips("今天没有活动哦，请皇上稍待几日")
	end
	local oAct = goHDMgr:GetHuoDong(gtHDDef.eZaoRenQiangGuo)
	if oAct:GetState() ~= CHDBase.tState.eStart then						  --是否在活动时间内
		return 
	end
	self.m_nState = 1 														  --进入游戏界面设为1状态
	self.m_nLastReportTime = os.time()
 	self:MarkDirty(true)

	local nGetSoldiers = 0
	local nStartTime = oAct:GetActTime()
	local tConf = ctMaxSoldiersEtcConf[1]
	local nDouble = tConf.nDouble
	if self.m_nLastTime <= 0 then                     		           		  --第一次进入活动 
		nGetSoldiers = (os.time()-nStartTime)*nDouble
	else
		local tRange = tConf.tRange[1]
		local nPassTime = math.max(0, (os.time() - self.m_nLastTime))
		nGetSoldiers = math.max(1, math.floor(math.random(tRange[1], tRange[2])/100*nPassTime*nDouble))		  --距离上次关闭活动界面获得的赔款
	end
	self:AddSoldiers(nGetSoldiers,	"进造人强国获得士兵数")
	self:SyncInfo(nGetSoldiers)
end












