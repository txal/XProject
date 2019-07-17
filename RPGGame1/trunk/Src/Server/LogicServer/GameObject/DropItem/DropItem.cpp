#include "Server/LogicServer/GameObject/DropItem/DropItem.h"	

#include "Server/LogicServer/SceneMgr/SceneBase.h"

LUNAR_IMPLEMENT_CLASS(DropItem)
{
	DECLEAR_OBJECT_METHOD(DropItem),
	{0, 0}
};

DropItem::DropItem()
{
	m_nObjType = OBJTYPE::eOT_Drop;
	m_nDisappearTime = (int)time(0) + 180;
}

DropItem::~DropItem()
{
}

void DropItem::Init(int64_t nObjID, int nConfID, const char* psName, int nAliveTime, int nCamp)
{
	Object::Init(OBJTYPE::eOT_Drop, nObjID, nConfID, psName);
	m_nDisappearTime = (int)time(0) + nAliveTime;
}

void DropItem::Update(int64_t nNowMS)
{
	Object::Update(nNowMS);

	if (time(0) >= m_nDisappearTime)
	{
		SceneBase* poScene = GetScene();
		if (poScene != NULL)
		{
			poScene->LeaveScene(GetAOIID(), false);
		}
	}
}




///////////////////lua export///////////////////