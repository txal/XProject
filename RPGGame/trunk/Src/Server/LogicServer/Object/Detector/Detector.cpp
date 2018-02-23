#include "Detector.h"	
#include "Server/LogicServer/Component/Battle/BattleDef.h"
#include "Server/LogicServer/Object/ObjectDef.h"
#include "Server/LogicServer/SceneMgr/Scene.h"

LUNAR_IMPLEMENT_CLASS(Detector)
{
	DECLEAR_OBJECT_METHOD(Detector),
	{0, 0}
};

Detector::Detector()
{
	m_nObjType = eOT_Detector;
}

Detector::~Detector()
{
}

void Detector::Init(int nID, int nConfID, const char* psName)
{
	//m_nCamp = (int8_t)eBC_Neutral;
	m_nObjID = nID;
	m_nConfID = nConfID;
	strcpy(m_sName, psName);
}

void Detector::Update(int64_t nNowMS)
{
	Object::Update(nNowMS);
}




///////////////////lua export///////////////////