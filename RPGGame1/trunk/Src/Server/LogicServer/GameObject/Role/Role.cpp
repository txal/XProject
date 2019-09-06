#include "Server/LogicServer/GameObject/Role/Role.h"	
#include "Common/DataStruct/XMath.h"
#include "Common/DataStruct/XTime.h"
#include "Server/Base/CmdDef.h"
#include "Server/Base/NetAdapter.h"
#include "Server/LogicServer/Component/Battle/BattleUtil.h"
#include "Server/LogicServer/LogicServer.h"
#include "Server/LogicServer/SceneMgr/SceneBase.h"

LUNAR_IMPLEMENT_CLASS(Role)
{
	DECLEAR_OBJECT_METHOD(Role),
	DECLEAR_ACTOR_METHOD(Role),
	{0, 0}
};

Role::Role()
{
	m_nObjType = OBJTYPE::eOT_Role;
}

Role::~Role()
{
}

void Role::Init(int64_t nObjID, int nConfID, const char* psName)
{
	Object::Init(OBJTYPE::eOT_Role, nObjID, nConfID, psName);
}

void Role::RoleStartRunHandler(Packet* poPacket)
{
	if (GetScene() == NULL)
	{
		XLog(LEVEL_INFO, "RoleStartRunHandler: %s role not in scene\n", m_sName);
		return;
	}

	int64_t nObjID= 0;
	uint16_t uPosX = 0;
	uint16_t uPosY = 0;

	uint16_t uTarPosX = 0;
	uint16_t uTarPosY = 0;

	int16_t nSpeedX = 0;
	int16_t nSpeedY = 0;

	int64_t nClientMSTime = 0;
	int8_t nFace = 0;

	goPKReader.SetPacket(poPacket);
	goPKReader >> nObjID >> uPosX >> uPosY >> nSpeedX >> nSpeedY >> uTarPosX >> uTarPosY >> nFace >> nClientMSTime;
	XLog(LEVEL_DEBUG,  "%s start run srv:(%d,%d) clt(%d,%d) speed(%d,%d) tar(%d,%d) face:%d time:%lld\n"
		, m_sName, m_oPos.x, m_oPos.y, uPosX, uPosY, nSpeedX, nSpeedY, uTarPosX, uTarPosY, nFace, nClientMSTime-m_nClientRunStartMSTime);

	//客户端提供的时间值必须大于起始时间值
	if (nClientMSTime < m_nClientRunStartMSTime)
	{
		SyncPosition();
		XLog(LEVEL_INFO,  "%s sync pos for start run client time invalid\n", m_sName);
		return;
	}

	MAPCONF* poMapConf = m_poScene->GetMapConf();
	if (!poMapConf->IsValidPos(uPosX, uPosY))
	{
		SyncPosition();
		XLog(LEVEL_INFO, "%s sync pos for start run pos invalid pos:(%u,%u),block:%d\n", m_sName, uPosX, uPosY, poMapConf->IsBlockUnit(uPosX/gnUnitWidth, uPosY/gnUnitHeight));
		return;
	}

	//正在移动则先更新移动后的新位置
	if (IsRunning())
	{
		UpdateRunState(m_nRunStartMSTime + (nClientMSTime - m_nClientRunStartMSTime));
	}

	//客户端与服务器坐标误差在一定范围内，则以客户端坐标为准
	if (!BattleUtil::IsAcceptablePositionFaultBit(m_oPos.x, m_oPos.y, uPosX, uPosY))
	{
		SyncPosition();
		XLog(LEVEL_INFO, "%s sync pos for start run faultbit srv:(%d,%d) clt:(%d,%d) target:(%d,%d)\n", m_sName, m_oPos.x, m_oPos.y, uPosX, uPosY, uTarPosX, uTarPosY);
		return;
	}
	SetPos(Point(uPosX, uPosY));

	m_bRunCallback = false;
	m_oTargetPos = Point(uTarPosX, uTarPosY);
	m_nClientRunStartMSTime = nClientMSTime;
	StartRun(nSpeedX, nSpeedY, nFace);
}

void Role::RoleStopRunHandler(Packet* poPacket)
{
	if (GetScene() == NULL)
	{
		XLog(LEVEL_INFO, "RoleStopRunHandler: %s role not in scene\n", m_sName);
		return;
	}

	int64_t nObjID = 0;
	uint16_t uPosX = 0;
	uint16_t uPosY = 0;
	int64_t nClientMSTime = 0;

	goPKReader.SetPacket(poPacket);
	goPKReader >> nObjID >> uPosX >> uPosY >> nClientMSTime;
	XLog(LEVEL_DEBUG, "%s stop run srv:(%d,%d), clt:(%d,%d) time:%lld\n", m_sName, m_oPos.x, m_oPos.y, uPosX, uPosY, nClientMSTime-m_nClientRunStartMSTime);

	if (!IsRunning())
	{
		//客户端与服务器坐标误差在一定范围内，则以客户端坐标为准
		if (!BattleUtil::IsAcceptablePositionFaultBit(m_oPos.x, m_oPos.y, uPosX, uPosY))
		{
			SyncPosition();
			XLog(LEVEL_INFO, "%s sync pos for stop run faultbit srv:(%d,%d) clt:(%d,%d) target:(%d,%d) -01\n", m_sName, m_oPos.x, m_oPos.y, uPosX, uPosY, m_oLastTargetPos.x, m_oLastTargetPos.y);
		}
		else
		{
			SetPos(Point(uPosX, uPosY));
		}
		return;
	}

	//客户端提交的时间比起跑时提交的时间小，则视为非法数据，强制使用服务器计算的值
	MAPCONF* poMapConf = m_poScene->GetMapConf();
	if (nClientMSTime < m_nClientRunStartMSTime || !poMapConf->IsValidPos(uPosX, uPosY))
	{
		UpdateRunState(XTime::MSTime());
		StopRun(true, true);
		SyncPosition();
		XLog(LEVEL_INFO, "%s sync pos for stop run pos:(%d,%d) or time:(%d) error -02\n", m_sName, uPosX, uPosY, nClientMSTime-m_nClientRunStartMSTime);
		return;
	}
	//正在移动则先更新移动后的新位置
	if (m_nRunStartMSTime > 0)
	{
		UpdateRunState(m_nRunStartMSTime + (nClientMSTime - m_nClientRunStartMSTime));
	}
	//客户端与服务器坐标误差在一定范围内，则以客户端坐标为准
	if (!BattleUtil::IsAcceptablePositionFaultBit(m_oPos.x, m_oPos.y, uPosX, uPosY))
	{
		SyncPosition();
		XLog(LEVEL_INFO, "%s sync pos for stop run faultbit srv:(%d,%d) clt:(%d,%d) target:(%d,%d) -03\n", m_sName, m_oPos.x, m_oPos.y, uPosX, uPosY, m_oLastTargetPos.x, m_oLastTargetPos.y);
	}
	else
	{
		SetPos(Point(uPosX, uPosY));
	}
	StopRun(true, true);
	m_nClientRunStartMSTime = 0;
}

///////////////////lua export///////////////////