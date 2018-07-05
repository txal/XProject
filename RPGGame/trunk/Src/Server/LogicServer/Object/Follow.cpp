#include "Server/LogicServer/Object/Follow.h"

Follow::Follow()
{

}

Follow::~Follow()
{
}

void Follow::Update(int64_t nNowMS)
{
}

Follow::FollowVec* Follow::GetFollowList(int nObjType, int nObjID)
{
	FOLLOW oFollow(nObjType, nObjID);
	FollowIter iter = m_oFollowMap.find(oFollow.ToInt64());
	if (iter != m_oFollowMap.end())
		return iter->second;
	return NULL;
}

Follow::FollowVec* Follow::CreateFollowList(int nObjType, int nObjID)
{
	FollowVec* pVec = GetFollowList(nObjType, nObjID);
	if (pVec != NULL)
		return pVec;

	pVec = new FollowVec;
	FOLLOW oFollow(nObjType, nObjID);
	m_oFollowMap[oFollow.ToInt64()] = pVec;
	return pVec;
}

void Follow::RemoveateFollowList(int nObjType, int nObjID)
{
	FollowVec* pVec = GetFollowList(nObjType, nObjID);
	if (pVec == NULL)
		return;

	SAFE_DELETE(pVec);
	FOLLOW oFollow(nObjType, nObjID);
	m_oFollowMap.erase(oFollow.ToInt64());
}
