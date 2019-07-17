#include "Server/LogicServer/GameObject/Monster/Monster.h"	

#include "Server/Base/CmdDef.h"
#include "Server/Base/NetAdapter.h"
#include "Common/DataStruct/XTime.h"
#include "Common/DataStruct/XMath.h"
#include "Server/LogicServer/ConfMgr/MAPCONF.h"
#include "Server/LogicServer/SceneMgr/SceneBase.h"
#include "Server/LogicServer/SceneMgr/SceneMgr.h"

LUNAR_IMPLEMENT_CLASS(Monster)
{
	DECLEAR_OBJECT_METHOD(Monster),
	DECLEAR_ACTOR_METHOD(Monster),
	{0, 0}
};

Monster::Monster()
{
	m_nObjType = OBJTYPE::eOT_Monster;
}

Monster::~Monster()
{
}

void Monster::Init(int64_t nObjID, int nConfID, const char* psName)
{
	Object::Init(OBJTYPE::eOT_Monster, nObjID, nConfID, psName);
}


///////////////////lua export///////////////////