package com.nucleus.logic.core.modules.battle.data;

/**
 * 被动技能逻辑枚举
 * 
 * @author wgy
 *
 */
public enum PassiveSkillLogicEnum {
	Unknow,
	/** 1影响属性 */
	PropertyEffect,
	/** 2伤害输出 */
	DamageOutput,
	/** 3连击 */
	Combo,
	/** 4追击 */
	PursueAttack,
	/** 5反震 */
	Rebound,
	/** 6技能抗性 */
	AntiSkill,
	/** 7反击 */
	StrikeBack,
	/** 8击飞 */
	HitOut,
	/** 9吸血 可被反击的技能如：普攻和单体物理攻击才能吸血 */
	SuckHp,
	/** 10附加buff */
	AddBuff,
	/** 11攻击隐身目标 */
	AttackHidden,
	/** 12恢复hp/mp/sp */
	RestoreMpHpSp,
	/** 13消耗减免 */
	SpentDiscount,
	/** 14清除buff(自己) */
	ClearBuff,
	/** 15不受暴击 */
	AntiCrit,
	/** 16buff免疫 */
	AntiBuff,
	/** 17强制使用某技能 */
	ForceSkill,
	/** 18不逃跑 */
	NoEscape,
	/** 19保命 */
	KeepLife,
	/** 20复活 */
	Relive,
	/** 21死亡后不退出战场 */
	NotLeave,
	/** 22特殊buff */
	AddSpeicalBuff,
	/** 23法术伤害转化成hp */
	MagicDamageToHp,
	/** 24buff增强 */
	BuffEnhance,
	/** 25战斗中临时影响属性 */
	PropertyEffectInBattle,
	/** 26击飞(特殊) */
	HitOutSpecial,
	/** 27防御减伤 */
	DefenseCommandDecreaseDamage,
	/** 28攻击力变动 */
	AttackVaryRate,
	/** 29药效增强 */
	DrugHealEnhance,
	/** 30宝石镶嵌效果增强 */
	EmbedEffectEnhance,
	/** 31战斗开始给宠物增加buff */
	AddPetBuff,
	/** 32逃跑成功率 */
	RetreatRate,
	/** 33减敌方逃跑成功率 */
	ReduceEnemyRetreatRate,
	/** 34被击飞时为己方召唤救兵 */
	CallBackup,
	/** 35法术连击 */
	MagicCombo,
	/** 36魅 */
	Mei,
	/** 37免疫特定类型的buff */
	AntiTypedBuff,
	/** 38每隔n回合施放特定技能xxx */
	RoundForceSkill,
	/** 39给队伍全员增加buff */
	TeamBuff,
	/** 40移除队伍buff */
	RemoveTeamBuff,
	/** 41给主人物加buff */
	MainCharactorBuff,
	/** 42代理其他技能 */
	SkillProxy,
	/** 43孤军奋战 */
	TeammateDeadBuff,
	/** 44攻击敌方特定怪 */
	AttackSpeicifyEnemy,
	/** 45召唤指定怪 */
	CallMonster,
	/** 46随机召唤 */
	RandomCallMonster,
	/** 47指定怪物逃跑 */
	TargetEscape,
	/** 48给指定目标加buff */
	AddBuffToTarget,
	/** 49鼓舞：给指定目标叠加buff,有100%上限 */
	AddBuffToTargetWithLimit,
	/** 50自动保护 */
	AutoProtect,
	/** 51自动逃跑 */
	AutoEscape,
	/** 52执行前置技能 */
	PreActionSkill,
	/** 53叠加buff */
	OverlayBuff,
	/** 54给队伍其他单位加buff */
	TeamOtherBuff,
	/** 55暴击率附加 */
	CritRatePlus,
	/** 56被封印机率降低 */
	BeBanRateDecrease,
	/** 57必然反击(世界boss怪专用) */
	MustStrikeBack,
	/** 58前置技能：自动使用技能ai */
	PreActionSkillByAi,
	/** 59夺取buff */
	RobBuff,
	/** 60 恢复主人的hp/mp/sp/magicmana */
	RestorePlayerMpHpSp,
	/** 61 映射并强制使用某技能 */
	MappingForceSkill,
	/** 62 复活恢复怒气 */
	ReliveRestoreSp,
	/** 63 指定怪物数量影响伤害输出 */
	DamageOutputByMonster,
	/** 64 目标防御变化 */
	TargetDefenceChange,
	/** 65 死亡之后触发技能 */
	AffterDeadSkill,
	/** 66 暴击伤害率影响 */
	CritHurtRatePlus,
	/** 67 服务端临时附加影响属性buff */
	TempBuff,
	/** 68 群攻法连:击杀任一目标触发法术连击 */
	MultiMagicCombo,
	/** 69 施放技能hp需求变动 */
	HpFireChange,
	/** 70 恢复己方角色(除自己)hp/mp */
	TeamPlayerRestore,
	/** 71 用指定技能(多个则随机)攻击符合条件目标 */
	UseSkillWithSelectTargetAi,
	/** 72 禁锢敌方速度最快目标 */
	AddBuffToFastEnemy,
	/** 73 恢复全体宠物子女hp */
	RestorePetChild,
	/** 74 恢复己方hp/mp最低单位 */
	RestoreMinHpMpTarget,
	/** 75 攻击前触发影响攻击力 */
	AttackEffect,
	/** 76 免疫指定的buff */
	AntiSpcBuff,
	/** 77 法术吸血 */
	MagicSuckHp,
	/** 78 保护减伤 */
	ProtectDecreaseDamage,
	/** 79 伤害吸收 */
	DamageAbsord,
	/** 80 宠物保护主人 */
	ProtectOwner,
	/** 81 技能清除目标buff */
	ClearTargetBuff,
	/** 82 暴击附加伤害 */
	CritDamagePlus,
	/** 83 队友HP影响 */
	TeamHpEffect,
	/** 84 恢复mp/hp/sp */
	RecoverState,
	/** 85 攻击配置血量的目标 */
	AttackHpEnemy,
	/** 86 攻击配置门派的目标 */
	AttackFactionEnemy,
	/** 87 攻击倒地目标 */
	AttackDeadEnemy,
	/** 88 单类宝石镶嵌效果增强 */
	SingleEmbedEffectEnhance,
	/** 89 伤害输出恢复怒气值 */
	DamageOutputAddSp,
	/** 90 减少敌方mp/hp/sp */
	ReduceState,
	/** 91 根据敌方队伍存在的buff数恢复自身HP */
	EnemyBuffCountAddHp,
	/** 92 盘丝门派绝技机率增强 */
	PSFactionUniqueSkillRate,
	/** 93 对目标的队友进行溅射伤害 */
	HurtTargetTeamMember,
	/** 94 叠加累计次数buff,有上限 */
	AddAccumulatedBuff,
	/** 95 指定技能连击 */
	DefineSkillCombo,
	/** 96 恢复宠物的hp/mp/sp/ */
	RestorePetMpHpSp,
	/** 97 敌方存在自己施放的某些buff时，再追加另外的buff */
	PursueBuff,
	/** 98 忽略敌方命中率，直接闪避 */
	DodgeSuccess,
	/** 99 改变Hp/Mp/Sp 效果公式 */
	ChangePropertyFormula,
	/** 100 对目标的队友中带有某些buff的进行溅射伤害 */
	HurtTeamWithBuff,
	/** 101 给宠物增加buff */
	PetBuff,
	/** 102 额外增加目标hp/mp/sp */
	AddTargetSp,
	/** 103 吸血(相对9逻辑去掉了可反击技能的限制) */
	PassLogic103,
	/** 104 保存战斗信息（比如自己被击飞的时候记录自己被击败，可能会影响战斗奖励） */
	PassLogic104,
	/** 107 存在指定技能时，收到的伤害为攻击次数*固定参数 */
	PassLogic107,
	/** 108 喊话 */
	PassLogic108;

}
