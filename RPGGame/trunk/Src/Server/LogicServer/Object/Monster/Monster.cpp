#include "Server/LogicServer/Object/Monster/Monster.h"	

#include "Server/Base/CmdDef.h"
#include "Server/Base/NetAdapter.h"
#include "Common/DataStruct/XTime.h"
#include "Common/DataStruct/XMath.h"
#include "Server/LogicServer/ConfMgr/MapConf.h"
#include "Server/LogicServer/SceneMgr/Scene.h"
#include "Server/LogicServer/SceneMgr/SceneMgr.h"

LUNAR_IMPLEMENT_CLASS(Monster)
{
	DECLEAR_OBJECT_METHOD(Monster),
	DECLEAR_ACTOR_METHOD(Monster),
	{0, 0}
};

Monster::Monster()
{
	m_nObjType = eOT_Monster;
}

Monster::~Monster()
{
}

void Monster::Init(int nID, int nConfID, const char* psName)
{
	m_nObjID = nID;
	m_nConfID = nConfID;
	strcpy(m_sName, psName);
}


///////////////////lua export///////////////////