
#include "MsgBalancer.h"

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
	uint16_t uServer = 0;
	int8_t nService = 0;
	int nSession = 0;

	INNER_HEADER oInnHeader;
	EXTER_HEADER oExtHeader;
	int* pSessionArray = NULL;

	while (m_poEventHandler->RecvEvent(oEvent, uWaitMS))
	{
		uWaitMS = 0; //注意:设置为0,避免下一循环没消息等待
		uServer = 0;
		nService = 0;
		nSession = 0;

		bool bInvalid = false;
		switch (oEvent.uEventType)
		{
			case NSNetEvent::eEVT_ON_RECV:
			{
				if (oEvent.pNet->NetType() == NET_TYPE_INTERNAL)
				{
					if (oEvent.U.oRecv.poPacket->GetInnerHeader(oInnHeader, &pSessionArray, false))
					{
						uServer = oInnHeader.uSrcServer;
						nService = oInnHeader.nSrcService;
						assert(uServer > 0 && nService > 0);
						nSession = oInnHeader.uSessionNum > 0 ? pSessionArray[0] : 0;
					}
					else
						bInvalid = true;
				}
				else
				{
					if (oEvent.U.oRecv.poPacket->GetExterHeader(oExtHeader, false))
					{
						nService = oExtHeader.nSrcService;
						nSession = oEvent.U.oRecv.nSessionID;
					}
					else
						bInvalid = true;
				}
				break;
			}
			case NSNetEvent::eEVT_ON_CONNECT:
			{
				nService = oEvent.pNet->NetType() == NET_TYPE_INTERNAL ? 0 : -1;
				nSession = oEvent.U.oConnect.nSessionID;
				break;
			}
			case NSNetEvent::eEVT_ON_CLOSE:
			{
				nService = oEvent.pNet->NetType() == NET_TYPE_INTERNAL ? 0 : -1;
				nSession = oEvent.U.oClose.nSessionID;
				break;
			}
			case NSNetEvent::eEVT_ON_ACCEPT:
			{
				nService = oEvent.pNet->NetType() == NET_TYPE_INTERNAL ? 0 : -1;
				nSession = oEvent.U.oAccept.nSessionID;
				break;
			}
			case NSNetEvent::eEVT_ADD_DATASOCK:
			{
				nSession = oEvent.U.oDataSock.nSessionID;
				break;
			}
			case NSNetEvent::eEVT_HANDSHAKE:
			{
				nSession = oEvent.U.oHandShake.nSessionID;
				break;
			}
			case NSNetEvent::eEVT_REMAINPACKETS:
			{
				break;
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
			m_oConnQueue.Push(nKey);
	}
	return QueueEvent(oEvent);
}