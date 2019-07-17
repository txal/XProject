#ifndef __MONSTER_H__
#define __MONSTER_H__

#include "Server/LogicServer/GameObject/Actor.h"

class Monster : public Actor
{
public:
	LUNAR_DECLARE_CLASS(Monster);

public:
	Monster();
	virtual ~Monster();
	void Init(int64_t nObjID, int nConfID, const char* psName);

private:
	DISALLOW_COPY_AND_ASSIGN(Monster);


/////////////////lua export////////////
public:
};

#endif