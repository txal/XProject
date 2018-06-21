package com.nucleus.logic.core.modules.battle.data;

/**
 * 触发条件
 * 
 * @author wgy
 *
 */
public enum PassiveSkillLaunchConditionEnum {
	Unknow,
	/** 1物理攻击按机率 */
	PhyAttackByRate,
	/** 2普攻按机率 */
	NormalAttackByRate,
	/** 3对方有特定被动技能时触发 */
	TargetHasSkillOn,
	/** 4技能互斥:1目标存在指定技能则无法触发;2己方有特定技能则忽略规则1 */
	SkillAnti,
	/** 5法术攻击按机率 */
	MagicAttackByRate,
	/** 6夜晚按机率 */
	NightByRate,
	/** 7目标有指定任一buff类型就能触发 */
	TargetHasBuffOn,
	/** 8第N回合 */
	Round,
	/** 9按机率 */
	ByRate,
	/** 10水/火/雷/土系法术按机率触发 */
	Magic4ByRate,
	/** 11boss和玩家无效 */
	NoBoss,
	/** 12对目标伤害大于某个值 */
	DamageMoreThan,
	/** 13前N回合 */
	PreNRound,
	/** 14死后N回合 */
	NRoundAfterDead,
	/** 15己方存在指定技能则无法触发 */
	SelfHasSkillOff,
	/** 16对方存在指定技能则无法触发 */
	TargetHasSkillOff,
	/** 17符合指定类型的buff */
	BuffTypeFit,
	/** 18每隔N回合 */
	PerNRound,
	/** 19封印状态 */
	InBanState,
	/** 20己方被封单位大于等于指定数量(自身除外) */
	SelInBanCountMoreThan,
	/** 21目标存在指定buff则技能无法触发 */
	TargetHasBuffIds,
	/** 22己方场上还存活除自己之外其他单位 */
	OtherAlive,
	/** 23己方有死亡单位 */
	SelfHasDeadUnit,
	/** 24敌方指定目标死亡 */
	EnemySpecifyTargetDead,
	/** 25己方指定目标未死 */
	SelfSpecifyTargetAlive,
	/** 26除自己之外其他小怪死亡 */
	OtherAllDead,
	/** 27没有指定技能的单位全部死亡 */
	AllDeadWithoutSkill,
	/** 28生命值低于指定值 */
	HpLessThan,
	/** 29前一回合死亡数量大于等于指定值 */
	RoundDeadCount,
	/** 30己方存活战斗单位数量小于指定值 */
	AliveCountLessThan,
	/** 31使用某技能小于指定次数 */
	UseSkillTimeslessThan,
	/** 32使用复活技能 */
	UsingReliveSkill,
	/** 33使用指定技能时 */
	UsingSkill,
	/** 34封印技 */
	BanSkill,
	/** 35仅对头号目标生效 */
	FirstTarget,
	/** 36给目标加指定buff */
	TargetAddBuffIdFit,
	/** 37所有消耗mp的法术 */
	SpendMpSkill,
	/** 38当前技能是否可被反击 */
	StrikeBackable,
	/** 39击杀目标 */
	TargetKilled,
	/** 40普通物理攻击时按机率，且该机率受自身力量点数影响 */
	NormalAttackRateAndAptitude,
	/** 41物理攻击按指定技能及公式计算概率 */
	PhyAttackBySkillRate,
	/** 42法术攻击按指定技能及公式计算概率 */
	MagicAttackBySkillRate,
	/** 43己方有指定任一buff类型就能触发 */
	SelfHasBuffOn,
	/** 44己方存在指定技能则触发 */
	SelfHasSkillOn,
	/** 45使用指定技能内其中之一则触发 */
	UsingInSkills,
	/** 46使用存活时治疗技能 */
	UsingHealSkill,
	/** 47使用群伤规则技能 */
	UsingSkillMassRule,
	/** 48使用加血治疗技能 */
	UsingIncreaseHpFunction,
	/** 49回合内指定被动技能触发次数超/未超上限 */
	SkillApplyTimes,
	/** 50技能出现暴击 */
	SkillCrit,
	/** 51暴走按机率 */
	OutbreakRate,
	/** 52使用门派默认攻击技能 */
	UsingFactionDefaultSkill,
	/** 53本次出手有任一目标死亡 */
	AnyTargetDead,
	/** 54 敌方有单位死亡(技能召唤、援助单位、鬼魂宠物除外) */
	EnemyDead,
	/** 55 第n回合及以后 */
	AfterNRound,
	/** 56使用加血治疗技能(不包括特技) */
	UsingIncreaseHpSkill,
	/** 57参战后每隔n回合 */
	PerNRoundAfterJoinBattle,
	/** 58 生命值大于等于指定值 */
	HpMoreThan,
	/** 59 己方存活战斗单位数量大于等于指定值 */
	AliveCountMoreThan,
	/** 60 PVP条件下发动 */
	Pvp,
	/** 61 PVE条件下发动 */
	Pve,
	/** 62 指定的buff在剩余第几回合的时候触发 */
	BuffRoundOn,
	/** 63 自己没有死 */
	SelfNoDead,
	/** 64 指定关系触发 */
	Relation,
	/** 65 本回合触发过的被动技能效果 */
	RoundPassiveEffects,
	/** 66 生命值低于指定百分比 */
	HpLowPercent,
	/** 67 生命值高于指定百分比 */
	HpHighPercent,
	/** 68 使用某主动技能的时候不触发 */
	ActiveSkillCannot,
	/** 69 SP少于指定值 */
	SpLessThan,
	/** 70 HP损失导致SP增加大于某值 */
	TargetSpMoreThan,
	/** 71 回合首次受击 */
	RoundFirstBeAttack,
	/** 72 受击大于等于血气上限百分比 */
	BeAttackHpPercent,
	/** 73 单回合掉血大于等于血气上限百分比 */
	RoundLossHp,
	/** 74 使用指定技能时（检查强制技能） */
	UsingForceSkill,
	/** 75 使用指定技能时（无强制技能情况下） */
	UsingSkillNotForce,
	/** 76 受击致死 */
	BeAttackedDead,
	/** 77 是否宠物 */
	IsPet,
	/** 78 是否有宠物 */
	HadPet,
	/** 79 魔法系攻击次数取模 */
	MagicAttackCount,
	/** 80 自己已召唤的单位不超过某个值 */
	CallCountLessThan,
	/** 81 目标是/不是傀儡生物 */
	TargetGhost,
	/** 82 目标受击大于等于气血上限百分比 */
	TargetHpPercent,
	/** 83 使用物理/魔法系法术，按几率触发 */
	SkillAttackType,
	/** 84 造成伤害值尾数为指定值 */
	DamageTailNumber,
	/** 85 回合数尾数为指定值 */
	RoundTailNumber,
	/** 86 单体攻击 */
	SingleAttack;

}
