#ifndef __PROTO_H__
#define __PROTO_H__
#pragma  pack (push,1) 

namespace Proto
{
	struct ClientRunCS
	{
		short nPosX;
		short nPosY;
		short nSpeedX;
		short nSpeedY;
		uint32_t uClientMS;
		static int Size() { return sizeof(ClientRunCS); }
	};

	struct ClientRunSC
	{
		int64_t llObjID;
		short nPosX;
		short nPosY;
		short nSpeedX;
		short nSpeedY;
		static int Size() { return sizeof(ClientRunSC); }
	};
}

#pragma pack(pop)
#endif