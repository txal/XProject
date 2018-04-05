package com.nucleus.logic.core.modules.battle.data;

/**
 * 被动技能触发时机
 * 
 * @author wgy
 *
 */
public enum PassiveSkillLaunchTimingEnum {
	/** 0任意 */
	Any,
	/** 1战斗开始 */
	BattleStart,
	/** 2回合开始 */
	RoundStart,
	/** 3前n回合 */
	PreRound,
	/** 4伤害输出 */
	DamageOutput,
	/** 5攻击结束(出手完毕) */
	AttackEnd,
	/** 6击杀目标后 */
	TargetKilled,
	/** 7被攻击 */
	UnderAttack,
	/** 8施放技能之前 */
	BeforeSkill,
	/** 9死亡后 */
	Dead,
	/** 10回合结束 */
	RoundOver,
	/** 11中buff前 */
	BeforeBuff,
	/** 12逃跑前 */
	BeforeEscape,
	/** 13攻击吸血 */
	AttackSuckHp,
	/** 14暴击前 */
	BeforeCrit,
	/** 15选择目标的时候 */
	SelectTarget,
	/** 16单次攻击结束 */
	SingleAttackEnd,
	/** 17治疗 */
	Heal,
	/** 18追击 */
	PursueAttack,
	/** 19战斗准备阶段 */
	BattleReady,
	/** 20给目标附加buff */
	TargetAddBuff,
	/** 21受击吸血 */
	BeAttackSuckHp,
	/** 22伤害输入(被攻击) */
	DamageInput,
	/** 23buff增强 */
	BuffEnhance,
	/** 24防御减伤 */
	DefenseDamageRate,
	/** 25攻击之前 */
	BeforeAttack,
	/** 26怒气消耗(不使用) */
	SpConsume,
	/** 27药效输出 */
	DrugHealOuput,
	/** 28药效吸收 */
	DrugHealInput,
	/** 29药效返馈 */
	DrugHealReturn,
	/** 30目标受击之前 */
	TargetBeforeUnderAttack,
	/** 31被击飞 */
	OnLeave,
	/** 32吸收类被动技能在受击后转换为hp */
	AfterDamageInput,
	/** 33尝试自动逃跑之前 */
	BeforeTryEscape,
	/** 34 AI选择目标时 */
	AiTarget,
	/** 35 自动保护指定目标 */
	TryAutoProtect,
	/** 36队友死亡 */
	TeammateDead,
	/** 37回合行动前 */
	PreAction,
	/** 38触发技能前 */
	BeforeFireSkill,
	/** 39召唤宠物出战 */
	CallPet,
	/** 40治疗输出 */
	HealOutput,
	/** 41暴击率附加 */
	CritRatePlus,
	/** 42被加buff机率 */
	BeBuffRate,
	/** 43附加攻击 */
	PlusAttack,
	/** 44给目标加buff前 */
	BeforeBuffOutput,
	/** 45暴击后 */
	AfterCrit,
	/** 46暴击时 */
	OnCrit,
	/** 47队友出手完毕 */
	TeammateAttackEnd,
	/** 48 敌人死亡 */
	EnemyDead,
	/** 49 保护前触发 */
	BeforeProtect,
	/** 50 施法者技能被敌方吸收类被动技能吸收转换为hp后 */
	TriggerAfterDamageInput,
	/** 51 连击附加伤害 */
	ComboDamageOutput,
	/** 52 反击 */
	StrokeBack,
	/** 53 封印失败 */
	BanFaild,
	/** 54 受到暴击后 */
	BeAfterCrit,
	/** 55 召唤宠物出战前 */
	BeforeCallPet,
	/** 56 复活目标后 */
	AfterReviveTarget,
	/** 57 被攻击之前 */
	BefroeBeAttacked,
	/** 58 选中首目标之后 */
	AfterSeleFirstTarget,
	/** 59 封印成功 */
	BanSuccess,
	/** 60 自己被复活 */
	BeRelived;
}
