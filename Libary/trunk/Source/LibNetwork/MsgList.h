#ifndef __MSGLIST_H__
#define __MSGLIST_H__

#include "Include/Network/Packet.h"
#include "Common/DataStruct/PureList.h"

class MsgList
{
public:
	MsgList() {}
	~MsgList()
	{
		Release();
	}

	void PushFront(Packet* poPacket)
	{
		m_PacketList.PushFront(poPacket);
	}

	void PushBack(Packet* poPacket)
	{
		m_PacketList.PushBack(poPacket);
	}

	Packet* Front()
	{
		return m_PacketList.Front();
	}

	Packet* Back()
	{
		return m_PacketList.Back();
	}

	void PopFront()
	{
		m_PacketList.PopFront();
	}

	void Release()
	{
		while (m_PacketList.Size() > 0)
		{
			Packet* poPacket = m_PacketList.Front();
			m_PacketList.PopFront();
			poPacket->Release(__FILE__, __LINE__);
		}
	}

	int Size()
	{
		return m_PacketList.Size();
	}

private:
	PureList<Packet*> m_PacketList;
	DISALLOW_COPY_AND_ASSIGN(MsgList);
};

#endif
