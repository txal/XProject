#ifndef __OBJDEF_H__
#define __OBJDEF_H__

//对象类型
enum OBJTYPE
{
	eOT_None = 0,
	eOT_Role = 1,		//角色
	eOT_Pet = 2,		//宠物
	eOT_Monster = 3,	//怪物
	eOT_Robot = 4,		//机器人
	eOT_Drop = 5,		//掉落物
	eOT_Detector = 6,	//探测器
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
