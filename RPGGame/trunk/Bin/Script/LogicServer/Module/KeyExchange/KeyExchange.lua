--兑换码兑换
local table, string, math, os, pairs, ipairs, assert = table, string, math, os, pairs, ipairs, assert

function CKeyExchange:Ctor(oPlayer)	
	self.m_oPlayer = oPlayer
end

function CKeyExchange:LoadData(tData)
	if not tData then return end
end

function CKeyExchange:SaveData()
	if not self:IsDirty() then return end
	self:MarkDirty(false)
end

function CKeyExchange:GetType()
	return gtModuleDef.tKeyExchange.nID, gtModuleDef.tKeyExchange.sName
end 

function CKeyExchange:KeyExchangeReq(nType, sCDKey, tAward)
	local tList = {}
	for _, tItem in ipairs(tAward) do
		self.m_oPlayer:AddItem(tItem[1], tItem[2], tItem[3], "兑换码兑换")
		table.insert(tList, {nType=tItem[1], nID=tItem[2], nNum=tItem[3]})
	end
	CmdNet.PBSrv2Clt(self.m_oPlayer:GetSession(), "KeyExchangeRet", {tList=tList})
	goLogger:EventLog(gtEvent.eKeyExchange, self.m_oPlayer, nType, sCDKey)
	Srv2Srv.OnExchangeRet(gtNetConf:GlobalService(), self.m_oPlayer:GetSession(), nType, sCDKey)
end