function CGPlayer:Ctor(tPlayer)
	self.m_nSession = tPlayer.nSession 
	self.m_sName = tPlayer.sName
	self.m_nCharID = tPlayer.nCharID
	self.m_sAccount = tPlayer.sAccount
	self.m_nSource = tPlayer.nSource
	self.m_nLogicService = tPlayer.nLogicService
end

function CGPlayer:GetCharID() return self.m_nCharID end
function CGPlayer:GetName() return self.m_sName end
function CGPlayer:GetSession() return self.m_nSession end
function CGPlayer:GetAccount() return self.m_sAccount end
function CGPlayer:GetLogicService() return self.m_nLogicService end
function CGPlayer:GetSource() return self.m_nSource end
function CGPlayer:IsOnline() return self.m_nSession > 0 end

function CGPlayer:Tips(sCont, nSession)
    nSession = nSession or self.m_nSession
    CmdNet.PBSrv2Clt(nSession, "TipsMsgRet", {sCont=sCont})
end
