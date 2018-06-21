#ifndef __BATTLEDEF_H__
#define __BATTLEDEF_H__

//战斗属性
enum FIGHT_PARAM_TYPE
{
	eFP_Atk = 1,		//攻击
	eFP_Def = 2,		//防御	
	eFP_HP = 3,			//血量
	eFP_Crit = 4,		//暴击率
	eFP_CritDmg = 5,	//暴击伤害
	eFP_CritRes = 6,	//暴击抗性
	eFP_AtkAdj = 7,		//攻击修正
	eFP_DefAdj = 8,		//防御修正
	eFP_HPAdj = 9,		//血量修正
	eFP_PhyDmg = 10,	//动能伤害
	eFP_LonDmg = 11,	//离子伤害
	eFP_RadDmg = 12,	//射线伤害
	eFP_PlaDmg = 13,	//电浆伤害
	eFP_FireDmg = 14,	//火焰伤害
	eFP_MisDmg = 15,	//飞弹伤害
	eFP_NorDmg = 16,	//普通伤害
	eFP_Speed = 17,		//速度
	eFP_IgnDef = 18,	//忽略目标防御
	eFP_Count,
};

//战斗参数
struct FIGHT_PARAM
{
	int aParam[eFP_Count];
	FIGHT_PARAM()
	{
		memset(aParam, 0, sizeof(aParam));
	}
	int& operator[](int nIndex)
	{
		assert(nIndex >= 0 && nIndex < eFP_Count);
		return aParam[nIndex];
	}
};

//战斗类型
enum BattleType
{
	eBT_Test = 1,		//测试
	eBT_SingleDup = 2,	//单人副本
	eBT_BugStorm = 3,	//异虫狂潮
	eBT_BugHole = 4,	//异虫巢穴(击杀模式)
	eBT_BugHole1 = 5,	//异虫巢穴(占领模式持续)
	eBT_BugHole2 = 6,	//异虫巢穴(占领模式累积)
};

//阵营
enum BattleCamp
{
	eBC_Attacker = 1,	//攻方
	eBC_Defender = 2,	//守方
	eBC_FreeLand = 3,	//自由阵营(除了中立都可以打 / 被打)
	eBC_Neutral = 4,	//中立阵营(谁都不可以打 / 被打)
};

//仇恨
struct HATE
{
	int nValue;			//伤害值
	uint8_t uRelives;	//复活次数
};

#endif
