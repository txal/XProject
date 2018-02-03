
#include "MsgBalancer.h"

#define MAX_CONN_NUM 102400

MsgBalancer::MsgBalancer() : m_oConnQueue(MAX_CONN_NUM)
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

CONNECTION* MsgBalancer::GetConn(int nSession)
{
	ConnIter iter = m_oConnMap.find(nSession);
	if (iter != m_oConnMap.end())
	{
		return iter->second;
	}
	CONNECTION* poConn = XNEW(CONNECTION);
	m_oConnMap[nSession] = poConn;
	return poConn;
}

void MsgBalancer::RemoveConn(int nSession)
{
	ConnIter iter = m_oConnMap.find(nSession);
	if (iter != m_oConnMap.end())
	{
		assert(iter->second->oEventList.Size() <= 0);
		SAFE_DELETE(iter->second);
		m_oConnMap.erase(iter);
	}
}

bool MsgBalancer::GetEvent(NSNetEvent::EVENT& oEvent, uint32_t uWaitMS)
{
	int nSession = 0;
	INNER_HEADER oHeader;
	int* pSessionArray = NULL;
	while (m_poEventHandler->RecvEvent(oEvent, 0))
	{
		nSession = 0;
		if (oEvent.uEventType == NSNetEvent::eEVT_ON_RECV)
		{
			if (oEvent.U.oRecv.poPacket->GetInnerHeader(oHeader, &pSessionArray, false) &&oHeader.uSessionNum> 0)
			{
				nSession = pSessionArray[0];
			}
		}
		else if (oEvent.uEventType == NSNetEvent::eEVT_ON_CONNECT)
		{
			nSession = oEvent.U.oConnect.nSessionID;
		}
		else if (oEvent.uEventType == NSNetEvent::eEVT_ON_CLOSE)
		{
			nSession = oEvent.U.oClose.nSessionID;
		}
		else
		{
			XLog(LEVEL_ERROR, "Msg type invalid:%d\n", oEvent.uEventType);
		}
		CONNECTION* poConn = GetConn(nSession);
		poConn->oEventList.PushBack(oEvent);
		if (poConn->oEventList.Size() == 1)
		{
			m_oConnQueue.Push(nSession);
		}
	}
	if (m_oConnQueue.Size() > 0)
	{
		nSession = m_oConnQueue.Pop();
		CONNECTION* poConn = GetConn(nSession);
		assert(poConn->oEventList.Size() > 0);
		oEvent = poConn->oEventList.Front();
		poConn->oEventList.PopFront();
		if (poConn->oEventList.Size() > 0)
		{
			m_oConnQueue.Push(nSession);
		}
		return true;
	}
	if (m_poEventHandler->RecvEvent(oEvent, uWaitMS))
	{
		assert(m_oConnQueue.Size() == 0);
		return true;
	}
	return false;
}