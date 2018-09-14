function CGPlayer:Ctor(nSession, nCharID, sCharName, nLogicService, sPlatform, sChannel)
	self.m_nSession = nSession 
	
	self.m_nCharID = nCharID
	self.m_sCharName = sCharName
	self.m_nLogicService = nLogicService

	self.m_sPlatform = sPlatform
	self.m_sChannel = sChannel
end

function CGPlayer:GetCharID() return self.m_nCharID end
function CGPlayer:SetCharID(nCharID) self.m_nCharID = nCharID end

function CGPlayer:GetCharName() return self.m_sCharName end
function CGPlayer:SetCharName(sCharName) self.m_sCharName = sCharName end

function CGPlayer:GetSession() return self.m_nSession end
function CGPlayer:SetSession(nSession) self.m_nSession = nSession end

function CGPlayer:GetLogicService() return self.m_nLogicService end
function CGPlayer:SetLogicService(nLogicService) self.m_nLogicService = nLogicService end

function CGPlayer:GetPlatform() return self.m_sPlatform end
function CGPlayer:GetChannel() return self.m_sChannel end
