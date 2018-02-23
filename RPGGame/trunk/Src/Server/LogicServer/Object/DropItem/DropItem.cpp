#include "DropItem.h"	
#include "Server/LogicServer/SceneMgr/Scene.h"

LUNAR_IMPLEMENT_CLASS(DropItem)
{
	DECLEAR_OBJECT_METHOD(DropItem),
	{0, 0}
};

DropItem::DropItem()
{
	m_nObjType = eOT_SceneDrop;
	m_nDisappearTime = (int)time(0) + 180;
}

DropItem::~DropItem()
{
}

void DropItem::Init(int nID, int nConfID, const char* psName, int nAliveTime, int nCamp)
{
	//m_nCamp = (int8_t)nCamp;
	m_nObjID = nID;
	m_nConfID = nConfID;
	strcpy(m_sName, psName);
	m_nDisappearTime = (int)time(0) + nAliveTime;
}

void DropItem::Update(int64_t nNowMS)
{
	Object::Update(nNowMS);

	if (time(0) >= m_nDisappearTime)
	{
		Scene* poScene = GetScene();
		if (poScene != NULL && m_nAOIID > 0)
		{
			poScene->LeaveScene(m_nAOIID);
		}
	}
}




///////////////////lua export///////////////////