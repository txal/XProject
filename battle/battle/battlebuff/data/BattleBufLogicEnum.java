package com.nucleus.logic.core.modules.battlebuff.data;

public enum BattleBufLogicEnum {
	Unknow,
	/** 1 技能触发休息 */
	SkillTouchRest,
	/** 2 召唤附加buff，buff结束召唤怪物消失 */
	CallMonserBuff,
	/** 3 随机普通攻击敌方目标 */
	RandomAttackEnemy,
	/** 4 伤害反震 */
	Rebound,
	/** 5 有机率免疫攻击法术 */
	AntiMagicAttack,
	/** 6 免疫所有法术并且反弹伤害 */
	AntiAndRebondMagicAttack,
	/** 7 buff抗性 */
	AntiBuff,
	/** 8 装备特效：4009产生buff */
	BuffOn4009,
	/** 9 蝎毒buff特殊逻辑 */
	BuffOnScorpion,
	/** 10 死后n回合复活 */
	ReliveAffterNRound,
	/** 11 禁药 */
	antiProps,
	/** 12 药物抗性 */
	decreaseProps,
	/** 13 伤害吸收 */
	SuckAttack,
	/** 14 攻击部分释放者 */
	AttackBuffTrigger,
	/** 15 攻击完毕移除 */
	AfterAttackRemoveBuff,
	/** 16 免疫物理/法术攻击 */
	BuffLogic16,
	/** 17 有机率攻击buff施放者 */
	BuffLogic17,
	/** 18 物理/法术攻击情况下,反弹百分比伤害 */
	BuffLogic18,
	/** 19 有此buff的目标可以攻击到敌方隐身单位 */
	BuffLogic19,
	/** 20 特殊处理逻辑 */
	BuffLogic20,
	/** 21 挂buff的目标如果执行相应动作则移除该buff */
	BuffLogic21,
	/** 22 防御 */
	BuffLogic22,
	/** 23 有机率防御 */
	BuffLogic23,
	/** 24 影响气血上限buff删除处理 */
	BuffLogic24,
	/** 25 伤害吸收，破裂反震 */
	BuffLogic25,
	/** 26 伤害分担 */
	BuffLogic26,
	/** 27 buff释放者死亡或者离场就移除buff */
	BuffLogic27,
	/** 28 受击后减少buff触发次数 */
	BuffLogic28,
	/** 29 受击后减少buff触发次数 */
	BuffLogic29,
	/** 30 血疫蔓延,中此buff会给该单位位置附近(position+(-)1)目标附加另一buff */
	BuffLogic30,
	/** 31 相同buff连锁伤害 */
	BuffLogic31,
	/** 32 给对方附加buff */
	BuffLogic32,
	/** 33 影响魔法值消耗 */
	BuffLogic33,
	/** 34 执行某动作就扣除一次buff作用次数 */
	BuffLogic34,
	/** 35 影响反击伤害变动率 */
	BuffLogic35,
	/** 36 将buff传染给任意队友 */
	BuffLogic36,
	/** 37 获得buff 之后改变buff某些属性 */
	BuffLogic37,
	/** 38 buff会扣除玩家属性，当属性减少到0时，额外扣除第二种属性值 ；例如扣除魔法的buff，魔法扣到0就扣除Hp */
	BuffLogic38,
	/** 39 使用某技能后就扣除一次buff作用次数 */
	BuffLogic39;
}
