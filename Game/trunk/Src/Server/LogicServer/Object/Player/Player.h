#ifndef __PLAYER_H__
#define __PLAYER_H__

#include "Server/LogicServer/Object/Actor.h"

class Player : public Actor
{
public:
	LUNAR_DECLARE_CLASS(Player);

public:
	Player();
	virtual ~Player();

public:
	void Init(int64_t nObjID, int nConfID, const char* psName, int8_t nCamp);

public:
	virtual void Update(int64_t nNowMS);
	virtual void OnEnterScene(Scene* poScene, const Point& oPos, int nAOIID);
	virtual void AfterEnterScene();
	virtual void OnLeaveScene();

public:
	void PlayerRunHandler(Packet* poPakcet);
	void PlayerStopRunHandler(Packet* poPacket);
	void PlayerStartAttackHandler(Packet* poPacket);
	void PlayerStopAttackHandler(Packet* poPacket);
	void PlayerHurtedHandler(Packet* poPacketro);
	void PlayerDamageHandler(Packet* poPacket);
	void EveHurtedHandler(Packet* poPacket);

private:
	DISALLOW_COPY_AND_ASSIGN(Player);


//////////////lua export////////////
};

#endif