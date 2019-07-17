#ifndef __ROLE_H__
#define __ROLE_H__

#include "Server/LogicServer/GameObject/Actor.h"

class Role : public Actor
{
public:
	LUNAR_DECLARE_CLASS(Role);

public:
	Role();
	virtual ~Role();

public:
	void Init(int64_t nObjID, int nConfID, const char* psName);

public:
	void RoleStartRunHandler(Packet* poPakcet);
	void RoleStopRunHandler(Packet* poPacket);

private:
	DISALLOW_COPY_AND_ASSIGN(Role);


//////////////lua export////////////
};

#endif