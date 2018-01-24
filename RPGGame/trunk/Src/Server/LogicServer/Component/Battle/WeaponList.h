#ifndef __WEAPON_LIST_H__
#define __WEAPON_LIST_H__

#include "Common/Platform.h"

#define nMAX_GUNS 4
#define nMAX_BOMBS 2
#define nMAX_WEAPON 6

enum GUN_TYPE
{
	eGT_SQ = 1,		//手枪
	eGT_BQ = 2,		//步枪
	eGT_JQ = 3,		//机枪
	eGT_TZQ = 4,	//特种枪
	eGT_Count = 5,	//数量
};

struct Gun
{
	uint16_t uID;
	uint8_t uSubType;		//子类型
	uint8_t uClipCap;		//弹夹容量
	uint16_t uBulletBackup;	//备用子弹数
	uint16_t uReloadTime;	//装填时间
	uint16_t uTimePerShot;	//毫秒每击
	uint16_t uRecoilTime;	//后坐力时间
};

struct Bomb
{
	uint16_t uID;
	uint8_t uBombCap;	//手雷容量
	uint16_t uBombCD;	//冷却时间
	int64_t nCDCompleteTime;	//冷却完成时间
};

struct WeaponList
{
	Gun tGunList[nMAX_GUNS];
	Bomb tBombList[nMAX_BOMBS];
	WeaponList()
	{
		memset(tGunList, 0, sizeof(tGunList));
		memset(tBombList, 0, sizeof(tBombList));
	}
};


#endif
