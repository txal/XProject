#ifndef __OBJDEF_H__
#define __OBJDEF_H__

#include "Common/DataStruct/ObjID.h"

//游戏对象类型
enum GAMEOBJ_TYPE
{
	eOT_None = 0,
	eOT_Role = 1,		//角色
	eOT_Child = 2,		//子女
	eOT_Partner = 3,	//伙伴
	eOT_Pet = 4,		//宠物
	eOT_Monster = 5,	//怪物
	eOT_Robot = 6,		//机器人
	eOT_Drop = 7,		//掉落物
	eOT_Detector = 8,	//探测器
};

//方向
enum DIR
{
	eDT_None = -1,
	eDT_Top = 0,
	eDT_RightTop = 1,
	eDT_Right = 2,
	eDT_RightBottom  = 3,
	eDT_Bottom = 4,
	eDT_LeftBottom = 5,
	eDT_Left = 6,
	eDT_LeftTop = 7,
};

#endif
