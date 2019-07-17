#ifndef __NETEVENTHANDLER_H__
#define __NETEVENTHANDLER_H__

#include "Include/Logger/Logger.h"
#include "Include/Network/Packet.h"
#include "Include/Network/MailBox.h"
#include "Include/Network/NetEventDef.h"

class NetEventHandler
{
public:
	NetEventHandler() {}
	~NetEventHandler()
	{
		NSNetEvent::EVENT oEvent;
		while (m_oMailBox.Recv(&oEvent, 0))
		{
			if (oEvent.uEventType == NSNetEvent::eEVT_ON_RECV)
			{
				if (oEvent.U.oRecv.poPacket != NULL)
				{
					oEvent.U.oRecv.poPacket->Release(__FILE__, __LINE__);
				}
			}
		}
	}

	void SendEvent(const NSNetEvent::EVENT& oEvent)
	{
		if (!m_oMailBox.Send(oEvent))
		{
			XLog(LEVEL_ERROR, "NetEventHandler::SendEvent fail\n");
		}
	}

	bool RecvEvent(NSNetEvent::EVENT& oEvent, uint32_t nMSTime)
	{
		return m_oMailBox.Recv(&oEvent, nMSTime);
	}

	MailBox<NSNetEvent::EVENT>& GetMailBox() { return m_oMailBox; }
	
private:
	MailBox<NSNetEvent::EVENT> m_oMailBox;
    DISALLOW_COPY_AND_ASSIGN(NetEventHandler);

};

#endif
