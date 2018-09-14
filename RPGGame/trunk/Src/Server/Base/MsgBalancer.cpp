
#include "MsgBalancer.h"
#include "Service.h"

static const int nMAX_ELEM = 102400;

MsgBalancer::MsgBalancer():m_oConnQueue(nMAX_ELEM)
{
	m_poEventHandler = NULL;
}

MsgBalancer::~MsgBalancer()
{
	ConnIter iter = m_oConnMap.begin();
	ConnIter iter_end = m_oConnMap.end();
	for (; iter != iter_end; iter++)
	{
		SAFE_DELETE(iter->second);
	}
}

CONNECTION* MsgBalancer::GetConn(int64_t nKey)
{
	ConnIter iter = m_oConnMap.find(nKey);
	if (iter != m_oConnMap.end())
	{
		return iter->second;
	}
	CONNECTION* poConn = XNEW(CONNECTION);
	m_oConnMap[nKey] = poConn;
	return poConn;
}

void MsgBalancer::RemoveConn(uint16_t uServer, int8_t nService, int nSession)
{
	int64_t nKey = GenKey(uServer, nService, nSession);
	ConnIter iter = m_oConnMap.find(nKey);
	if (iter != m_oConnMap.end())
	{
		iter->second->bRelease = true;
		m_oConnQueue.Push(nKey);
	}
}

bool MsgBalancer::QueueEvent(NSNetEvent::EVENT& oEvent)
{
	if (m_oConnQueue.Size() <= 0)
		return false;

	uint16_t uServer = 0;
	int8_t nService = 0;
	int nSession = 0;

	while (m_oConnQueue.Size() > 0)
	{
		int64_t nKey = m_oConnQueue.Pop();
		CONNECTION* poConn = GetConn(nKey);

		if (poConn->bRelease)
		{
			if (poConn->oEventList.Size() > 0)
			{
				uServer = nService = nSession = 0;
				DecKey(nKey, uServer, nService, nSession);
				XLog(LEVEL_ERROR, "Connection server:%d service:%d session:%d is released!\n", uServer, nService, nSession);
			}

			SAFE_DELETE(poConn);
			m_oConnMap.erase(nKey);
			continue;
		}
		else
		{
			if (poConn->oEventList.Size() == 0)
			{
				uServer = nService = nSession = 0;
				DecKey(nKey, uServer, nService, nSession);
				XLog(LEVEL_ERROR, "Connection server:%d service:%d session:%d released before!\n", uServer, nService, nSession);
				continue;
			}

			oEvent = poConn->oEventList.Front();
			poConn->oEventList.PopFront();

			if (poConn->oEventList.Size() > 0)
				m_oConnQueue.Push(nKey);
			return true;
		}

	}
	return false;
}

bool MsgBalancer::GetEvent(NSNetEvent::EVENT& oEvent, uint32_t uWaitMS)
{
	if (m_poEventHandler->GetMailBox().Size() <= 0 && QueueEvent(oEvent))
		return true;

	uint16_t uServer = 0;
	int8_t nService = 0;
	int nSession = 0;

	INNER_HEADER oInnHeader;
	EXTER_HEADER oExtHeader;
	int* pSessionArray = NULL;

	while (m_poEventHandler->RecvEvent(oEvent, uWaitMS))
	{
		uWaitMS = 0; //注意: 这里要把等待时间置为0, 否则下一循环没消息的情况下, 会阻塞等待
		uServer = 0;
		nService = 0;
		nSession = 0;

		switch (oEvent.uEventType)
		{
			case NSNetEvent::eEVT_ON_RECV:
			{
				if (oEvent.pNet->NetType() == NET_TYPE_INTERNAL)
				{
					oEvent.U.oRecv.poPacket->GetInnerHeader(oInnHeader, &pSessionArray, false);
					uServer = oInnHeader.uSrcServer;
					nService = oInnHeader.nSrcService;
					nSession = oInnHeader.uSessionNum > 0 ? pSessionArray[0] : 0;
					if (uServer == 0 || nService == 0)
					{
						XLog(LEVEL_ERROR, "Source server or service error cmd:%d server:%d service:%d\n", oInnHeader.uCmd, oInnHeader.uSrcServer, oInnHeader.nSrcService);
					}
					int nSessionService = nSession >> SERVICE_SHIFT;
					if (nSessionService != nService) //是否网关发过来的玩家消息
					{
						return true;
					}
				}
				else
				{
					oEvent.U.oRecv.poPacket->GetExterHeader(oExtHeader, false);
					nService = oExtHeader.nSrcService;
					nSession = oEvent.U.oRecv.nSessionID;
				}
				break;
			}
			case NSNetEvent::eEVT_ON_CONNECT:
			case NSNetEvent::eEVT_HANDSHAKE:
			case NSNetEvent::eEVT_ON_LISTEN:
			case NSNetEvent::eEVT_ON_ACCEPT:
			case NSNetEvent::eEVT_ON_CLOSE:
			case NSNetEvent::eEVT_ADD_DATASOCK:
			case NSNetEvent::eEVT_REMAINPACKETS:
			{
				return true;
			}
			default:
			{
				XLog(LEVEL_ERROR, "Msg type invalid:%d\n", oEvent.uEventType);
				break;
			}
		}

		int64_t nKey = GenKey(uServer, nService, nSession);
		CONNECTION* poConn = GetConn(nKey);
		poConn->oEventList.PushBack(oEvent);
		if (poConn->oEventList.Size() == 1)
		{
			m_oConnQueue.Push(nKey);
		}
	}

	return QueueEvent(oEvent);
}