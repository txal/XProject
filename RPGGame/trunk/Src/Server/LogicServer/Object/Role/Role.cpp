#include "Server/LogicServer/Object/Role/Role.h"	
#include "Common/DataStruct/XMath.h"
#include "Common/DataStruct/XTime.h"
#include "Server/Base/CmdDef.h"
#include "Server/Base/NetAdapter.h"
#include "Server/LogicServer/Component/Battle/BattleUtil.h"
#include "Server/LogicServer/LogicServer.h"
#include "Server/LogicServer/SceneMgr/Scene.h"

LUNAR_IMPLEMENT_CLASS(Role)
{
	DECLEAR_OBJECT_METHOD(Role),
	DECLEAR_ACTOR_METHOD(Role),
	{0, 0}
};

Role::Role()
{
	m_nObjType = eOT_Role;
}

Role::~Role()
{
}

void Role::Init(int nID, int nConfID, const char* psName)
{
	m_nObjID = nID;
	m_nConfID = nConfID;
	strcpy(m_sName, psName);
}

void Role::Update(int64_t nNowMS)
{
	Actor::Update(nNowMS);
}

void Role::OnEnterScene(Scene* poScene, int nAOIID, const Point& oPos)
{
	Actor::OnEnterScene(poScene, nAOIID, oPos);
}

void Role::AfterEnterScene()
{
	Actor::AfterEnterScene();
}

void Role::OnLeaveScene()
{
	Actor::OnLeaveScene();
}

void Role::RoleStartRunHandler(Packet* poPacket)
{
	if (GetScene() == NULL)
	{
		XLog(LEVEL_ERROR, "%s role not in scene\n", m_sName);
		return;
	}

	int nRoleID = 0;
	uint16_t uPosX = 0;
	uint16_t uPosY = 0;

	int16_t nSpeedX = 0;
	int16_t nSpeedY = 0;

	int64_t nClientMSTime = 0;
	double dClientMSTime = 0;
	goPKReader.SetPacket(poPacket);
	goPKReader >> nRoleID >> uPosX >> uPosY >> nSpeedX >> nSpeedY >> dClientMSTime;
	nClientMSTime = (int64_t)dClientMSTime;
	XLog(LEVEL_DEBUG,  "%s start run srv:(%d,%d) clt(%d,%d) speed(%d,%d) time:%lld\n", m_sName, m_oPos.x, m_oPos.y, uPosX, uPosY, nSpeedX, nSpeedY, nClientMSTime-m_nClientRunStartMSTime);

	//客户端提供的时间值必须大于起始时间值
	if (nClientMSTime < m_nClientRunStartMSTime)
	{
		XLog(LEVEL_ERROR,  "%s sync pos for start run client time invalid\n", m_sName);
		Actor::SyncPosition();
		return;
	}

	MapConf* poMapConf = m_poScene->GetMapConf();
	if (uPosX >= poMapConf->nPixelWidth || uPosY >= poMapConf->nPixelHeight || poMapConf->IsBlockUnit(uPosX/gnUnitWidth, uPosY/gnUnitHeight))
	{
		XLog(LEVEL_ERROR, "%s sync pos for start run pos invalid pos:(%u,%u),block:%d\n", m_sName, uPosX, uPosY, poMapConf->IsBlockUnit(uPosX/gnUnitWidth, uPosY/gnUnitHeight));
		Actor::SyncPosition();
		return;
	}

	//正在移动则先更新移动后的新位置
	if (m_nRunStartMSTime > 0)
	{
		Actor::UpdateRunState(m_nRunStartMSTime + (nClientMSTime - m_nClientRunStartMSTime));
	}

	//客户端与服务器坐标误差在一定范围内，则以客户端坐标为准
	if (!BattleUtil::IsAcceptablePositionFaultBit(m_oPos.x, m_oPos.y, uPosX, uPosY))
	{
		XLog(LEVEL_ERROR, "%s sync pos for start run faultbit srv:(%d,%d) clt:(%d,%d)\n", m_sName, m_oPos.x, m_oPos.y, uPosX, uPosY);
		uPosX = (uint16_t)m_oPos.x;
		uPosY = (uint16_t)m_oPos.y;
		Actor::SyncPosition();
	}
	Actor::SetPos(Point(uPosX, uPosY), __FILE__, __LINE__);
	
	m_nClientRunStartMSTime = nClientMSTime;
	Actor::StartRun(nSpeedX, nSpeedY);
}

void Role::RoleStopRunHandler(Packet* poPacket)
{
	if (GetScene() == NULL)
	{
		XLog(LEVEL_ERROR, "%s role not in scene\n", m_sName);
		return;
	}

	int nRoleID = 0;
	uint16_t uPosX = 0;
	uint16_t uPosY = 0;
	int64_t nClientMSTime = 0;
	double dClientMSTime = 0;

	goPKReader.SetPacket(poPacket);
	goPKReader >> nRoleID >> uPosX >> uPosY >> dClientMSTime;
	nClientMSTime = (int64_t)dClientMSTime;

	XLog(LEVEL_DEBUG, "%s stop run srv:(%d,%d), clt:(%d,%d) time:%lld\n", m_sName, m_oPos.x, m_oPos.y, uPosX, uPosY, nClientMSTime-m_nClientRunStartMSTime);
	if (m_nRunStartMSTime == 0)
	{
		//XLog(LEVEL_INFO, "%s server already stop\n", m_sName);
		if (uPosX != m_oPos.x || uPosY != m_oPos.y)
		{
			//XLog(LEVEL_ERROR, "%s sync pos for stop run faultbit srv:(%d,%d) clt:(%d,%d)\n", m_sName, m_oPos.x, m_oPos.y, uPosX, uPosY);
			Actor::SyncPosition();
		}
		return;
	}

	//客户端提交的时间比起跑时提交的时间小，则视为非法数据，强制使用服务器计算的值
	MapConf* poMapConf = m_poScene->GetMapConf();
	if (nClientMSTime < m_nClientRunStartMSTime || uPosX >= poMapConf->nPixelWidth || uPosY >= poMapConf->nPixelHeight || poMapConf->IsBlockUnit(uPosX/gnUnitWidth, uPosY/gnUnitHeight))
	{
		int64_t nNowMS = XTime::MSTime();
		Actor::UpdateRunState(nNowMS);
		Actor::SyncPosition();
		Actor::StopRun(true, true);
		XLog(LEVEL_ERROR, "%s sync pos: stop run pos:(%d,%d) or time:(%d) error\n", m_sName, uPosX, uPosY, nClientMSTime-m_nClientRunStartMSTime);
		return;
	}
	//正在移动则先更新移动后的新位置
	if (m_nRunStartMSTime > 0)
	{
		Actor::UpdateRunState(m_nRunStartMSTime + (nClientMSTime - m_nClientRunStartMSTime));
	}
	//客户端与服务器坐标误差在一定范围内，则以客户端坐标为准
	if (!BattleUtil::IsAcceptablePositionFaultBit(m_oPos.x, m_oPos.y, uPosX, uPosY))
	{
		XLog(LEVEL_ERROR, "%s sync pos for stop run faultbit srv:(%d,%d) clt:(%d,%d)\n", m_sName, m_oPos.x, m_oPos.y, uPosX, uPosY);
		uPosX = (uint16_t)m_oPos.x;
		uPosY = (uint16_t)m_oPos.y;
		Actor::SyncPosition();
	}
	m_nClientRunStartMSTime = 0;
	Actor::SetPos(Point(uPosX, uPosY), __FILE__, __LINE__);
	Actor::StopRun(true, true);
}

///////////////////lua export///////////////////