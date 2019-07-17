#include "Detector.h"	
#include "Server/LogicServer/Component/Battle/BattleDef.h"
#include "Server/LogicServer/GameObject/ObjectDef.h"
#include "Server/LogicServer/SceneMgr/SceneBase.h"

LUNAR_IMPLEMENT_CLASS(Detector)
{
	DECLEAR_OBJECT_METHOD(Detector),
	{0, 0}
};

Detector::Detector()
{
	m_nObjType = OBJTYPE::eOT_Detector;
}

Detector::~Detector()
{
}

bool Detector::Init(int64_t nObjID, int nConfID, const char* psName)
{
	Object::Init(OBJTYPE::eOT_Detector, nObjID, nConfID, psName);
	return true;
}



///////////////////lua export///////////////////