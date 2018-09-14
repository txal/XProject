#ifndef __OBJDEF_H__
#define __OBJDEF_H__

#include "Common/DataStruct/ObjID.h"

//游戏对象类型
enum GAME_OBJ_TYPE
{
	eOT_None = 0,
	eOT_Player = 1,		//玩家
	eOT_Monster = 2,	//怪物
	eOT_Robot = 10,		//机器人
	eOT_SceneDrop = 11,	//场景掉落
	eOT_Detector = 12,	//探测器
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
