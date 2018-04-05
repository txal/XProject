/**
 * 
 */
package com.nucleus.logic.core.modules.battle.model;

import java.util.ArrayList;
import java.util.Collection;
import java.util.Collections;
import java.util.HashMap;
import java.util.HashSet;
import java.util.Iterator;
import java.util.List;
import java.util.Map;
import java.util.Set;
import java.util.concurrent.ConcurrentHashMap;
import java.util.concurrent.locks.ReentrantLock;

import org.apache.commons.collections.CollectionUtils;
import org.apache.commons.logging.Log;
import org.apache.commons.logging.LogFactory;

import com.nucleus.commons.data.StaticConfig;
import com.nucleus.commons.log.LogUtils;
import com.nucleus.commons.utils.RandomUtils;
import com.nucleus.commons.utils.SplitUtils;
import com.nucleus.logic.core.modules.AppSkillActionStatusCode;
import com.nucleus.logic.core.modules.AppStaticConfigs;
import com.nucleus.logic.core.modules.battle.BattleUtils;
import com.nucleus.logic.core.modules.battle.data.Monster.MonsterType;
import com.nucleus.logic.core.modules.battle.data.PassiveSkillConfig;
import com.nucleus.logic.core.modules.battle.data.PassiveSkillLaunchTimingEnum;
import com.nucleus.logic.core.modules.battle.data.PassiveSkillLogicEnum;
import com.nucleus.logic.core.modules.battle.data.Skill;
import com.nucleus.logic.core.modules.battle.dto.VideoActionTargetState;
import com.nucleus.logic.core.modules.battle.dto.VideoAntiSkillTargetState;
import com.nucleus.logic.core.modules.battle.dto.VideoBuffRemoveTargetState;
import com.nucleus.logic.core.modules.battle.dto.VideoRound;
import com.nucleus.logic.core.modules.battle.dto.VideoSkillAction;
import com.nucleus.logic.core.modules.battle.dto.VideoSoldier.SoldierStatus;
import com.nucleus.logic.core.modules.battle.dto.VideoTargetShoutState;
import com.nucleus.logic.core.modules.battle.event.IPlayerBattleFinishCallback;
import com.nucleus.logic.core.modules.battle.event.IRetreatCallback;
import com.nucleus.logic.core.modules.battle.logic.IPassiveSkill;
import com.nucleus.logic.core.modules.battle.model.RoundContext.RoundState;
import com.nucleus.logic.core.modules.battlebuff.data.BattleBuff;
import com.nucleus.logic.core.modules.battlebuff.data.BattleBuff.BattleBasePropertyType;
import com.nucleus.logic.core.modules.battlebuff.model.BattleBuffEntity;
import com.nucleus.logic.core.modules.charactor.data.GeneralCharactor.CharactorType;
import com.nucleus.logic.core.modules.charactor.data.ShoutConfig;
import com.nucleus.logic.core.modules.charactor.data.ShoutConfig.BattleShoutTypeEnum;
import com.nucleus.logic.core.modules.charactor.model.AptitudeProperties;
import com.nucleus.logic.core.modules.charactor.model.PersistPlayerChild;
import com.nucleus.logic.core.modules.charactor.model.PersistPlayerPet;
import com.nucleus.logic.core.modules.faction.data.Faction;
import com.nucleus.logic.core.modules.faction.logic.FactionBattleLogicParam;
import com.nucleus.logic.core.modules.faction.logic.FactionBattleLogicParam_12;
import com.nucleus.logic.core.modules.faction.logic.FactionBattleLogicParam_6;
import com.nucleus.logic.core.modules.faction.logic.FactionBattleLogicParam_8;
import com.nucleus.logic.core.modules.faction.logic.FactionBattleLogicParam_9;
import com.nucleus.logic.core.modules.player.data.StateBar;
import com.nucleus.logic.core.modules.player.dto.PlayerDressInfo;
import com.nucleus.logic.core.modules.player.dto.PlayerSimpleDressInfoDto;
import com.nucleus.logic.core.modules.player.model.PersistPlayer;
import com.nucleus.logic.core.modules.player.model.PlayerStateBarInfo;
import com.nucleus.logic.core.modules.spell.ISpellEffectCalculator;
import com.nucleus.logic.core.modules.system.data.NpcAppearance;
import com.nucleus.logic.scene.modules.mythland.MythLandSceneService;
import com.nucleus.logic.whole.modules.system.manager.GameServerManager;
import com.nucleus.player.service.ScriptService;

/**
 * @author liguo
 * 
 */
public class BattleSoldier implements Comparable<BattleSoldier> {
	/** 鬼魂术技能编号 */
	public static final int GHOST_SKILL_ID_1 = 5108;
	/** 高级鬼魂术技能编号 */
	public static final int GHOST_SKILL_ID_2 = 5208;
	/** 神佑 */
	public static final int GOD_HELP_SKILL_ID_1 = 5116;
	/** 高级神佑 */
	public static final int GOD_HELP_SKILL_ID_2 = 5216;
	/** 装备特效:神佑 */
	public static final int GOD_HELP_SKILL_ID_3 = 4012;
	/** 高级毒 */
	public static final int HIGH_POISON_SKILL = 5227;
	/** 免疫所有Buff */
	public static final int ALL_BUFF_NOT_SKILL = 6567;
	private Log battleLog = LogFactory.getLog("battle.log");

	/** 队伍 */
	private BattleTeam battleTeam;

	/** buff容器 */
	private BattleSoldierBuffHolder battleSoldierBuffHolder;

	/** 技能容器 */
	private BattleSoldierSkillHolder battleSoldierSkillHolder;

	/** 士兵唯一编号 */
	private long id;

	/** 玩家编号 0:不可控制, >0:可控制 */
	private long playerId;

	/** 对应角色 */
	private int charactorId;

	/** 对应怪物 */
	private int monsterId;

	/** 怪物类型 */
	private int monsterType;

	/** 等级 */
	private int grade;

	/** 战斗自编号 */
	private int customId;

	/** 基础战斗属性 */
	private BattleSoldierProperties battleProperties;

	/** 角色经验 */
	private long exp;

	/** 受击度 */
	private float strikeRate;

	/** 上阵站位,0表示没上阵，还在后备队列中 */
	private int position;

	/** 阵型位置索引[1~5] **/
	private int formationIndex;

	/** 战斗单元 */
	private BattleUnit battleUnit;

	/** 自动战斗 */
	private boolean autoBattle;

	/** 是否行动 */
	private boolean actionDone;

	/** 战斗状态 */
	private SoldierStatus soldierStatus = SoldierStatus.Normal;

	/** 保护方士兵编号列表 */
	private List<Long> protectedBySoldierIds = new ArrayList<Long>();

	/** 强制技能 */
	private int forceSkillId = 0;
	/** 在指定的回合使用强制技能 */
	private int forceSkillRound = 0;
	/** 设置了强制技能后需对应目标 */
	private BattleSoldier forceTarget;
	/** 当前回合执行器 */
	private DefaultBattleRoundProcessor curRoundProcessor;
	/** 当前回合上下文 */
	private RoundContext roundContext;
	/**
	 * 是否已经离开战场,如怪物被扑捉
	 */
	private boolean isLeave;
	/** 修炼等级 */
	private int spellLevel;
	/** 修炼效果计算器 */
	private ISpellEffectCalculator spellEffectCalculator;
	/** 怒气值 */
	private int sp;
	/** 最大怒气值 */
	private int maxSp;
	/** 第几回合死掉 */
	private int deadRound;
	/** 资质属性 */
	private AptitudeProperties aptitudeProperties;

	/** 名称 */
	private String name;

	/** 攻击次数 */
	private int attackTimes;
	/** 攻击次数（魔法系） */
	private int magicAttackTimes;

	/** 受击次数 */
	private int beAttackTimes;

	/** 战士着装信息（衣服染色,头发染色,饰物染色,武器模型,变身后的新模型,角色编号) */
	private PlayerDressInfo playerDressInfo;
	/** 怪物外观（用于替换怪物外观） */
	private NpcAppearance npcAppearance;
	/** 强制离开战斗 */
	private boolean forceLeaveBattle;
	/** 本回合受击次数(物理) */
	private int roundBePhyAttackTimes;
	/** 本回合受击次数(法术) */
	private int roundBeMagicAttackTimes;
	/** 本场战斗中使用过的技能 */
	private Map<Integer, Integer> usedSkills = new ConcurrentHashMap<>();
	/** 战斗结束回调 */
	private List<IPlayerBattleFinishCallback> battleFinishCallbacks = new ArrayList<>();
	private ReentrantLock battleFinishCallbackLock = new ReentrantLock();
	private boolean inBan;
	/** 武器攻击公式参数 */
	private Map<String, Object> weaponAttackParams = new HashMap<>();
	/** 撤退回调 */
	private IRetreatCallback retreatCallback;
	/** 第几回合参战 */
	private int joinRound;
	/** 本回合触发过的被动技能效果 key=configId, value=次数 */
	private Map<Integer, Integer> roundPassiveEffects = new ConcurrentHashMap<>();
	/** 死时的怒气 */
	private int deadSp;
	/** 上回合受击次数 */
	private int lastRoundBeAttackTimes;
	/** 已喊话记录 */
	private Set<ShoutConfig.BattleShoutTypeEnum> shoutedTypes = new HashSet<>(ShoutConfig.BattleShoutTypeEnum.values().length);
	/** 喊话文本 */
	private Map<ShoutConfig.BattleShoutTypeEnum, ShoutConfig> shoutConfigs = new HashMap<>(ShoutConfig.BattleShoutTypeEnum.values().length);
	/** 子女喊话文本 */
	private Map<Integer, ShoutConfig> childShoutConfigs = new HashMap<>(ShoutConfig.BattleShoutTypeEnum.values().length);
	/** 法宝法力 */
	private int magicEquipmentMana;
	/** 战斗中最大伤害值 */
	private int maxDamage;
	/** 战斗中宠物最大伤害 */
	private int maxPetDamage;
	/** 本回合失去的血量 */
	private int roundLossHp;
	/** 是否触发浴血凤凰被动技能(如果触发了，就可以扣0滴血，否则至少扣1血) */
	private boolean effectPhoenixSkill;
	/** 不考虑敌方命中率，直接闪避成功(有的被动效果可以忽略命中率，直接闪避) */
	private boolean dodgeSuccess;
	/** 本回合是否首次被攻击 */
	private boolean firstBeAttacked;

	public BattleSoldier() {
		this.battleProperties = new BattleSoldierProperties();
	}

	public BattleSoldier(BattleTeam battleTeam, BattleUnit battleUnit) {
		this.id = battleUnit.uid();
		this.playerId = battleUnit.playerId();
		this.battleUnit = battleUnit;
		this.battleTeam = battleTeam;
		this.charactorId = battleUnit.charactorId();
		this.grade = battleUnit.grade();
		this.monsterId = battleUnit.monsterId();
		this.exp = battleUnit.exp();
		this.battleSoldierBuffHolder = new BattleSoldierBuffHolder(this);
		this.battleSoldierSkillHolder = new BattleSoldierSkillHolder(this);
		this.strikeRate = battleBaseStrikeRate();
		// 注意：因为怪物的属性需要根据敌方来定,而此时怪物的敌方未定,因此在战斗敌我双方设置完后,怪物的该属性会被重新设置
		this.battleProperties = new BattleSoldierProperties(battleUnit, this);
		this.sp = battleUnit.initSp();
		this.maxSp = this.maxSp();
		this.name = battleUnit.name();
		this.aptitudeProperties = new AptitudeProperties(battleUnit.aptitudeProperties());// 基础部分
		this.aptitudeProperties.increaseProperty(battleUnit.equipmentAptitudeProperties());// 装备附加
		this.joinRound = battleTeam.battle().getCount();// 第几回合参战
		if (battleUnit instanceof PersistPlayer) {
			PersistPlayer pp = (PersistPlayer) battleUnit;
			PlayerSimpleDressInfoDto dressInfo = pp.persistVisitor().simpleDressInfoDto();
			this.playerDressInfo = new PlayerDressInfo(battleUnit, dressInfo);
		} else {
			this.playerDressInfo = new PlayerDressInfo(battleUnit);
			if (battleUnit instanceof PersistPlayerPet) {
				PersistPlayerPet battlePet = this.player().battlePet();
				if (battlePet != null) {
					this.playerDressInfo.setPetOrnamentDyeCaseId(battlePet.getOrnamentDyeCaseId());
					this.playerDressInfo.setDyeCaseId(battlePet.getDyeCaseId());
				}
			} else if (battleUnit instanceof PersistPlayerChild) {
				PersistPlayerChild ppc = this.player().battleChild();
				if (ppc != null) {
					this.playerDressInfo.setDyeCaseId(ppc.getDyeCaseId());
				}
			}
		}
		// 战斗开始时法宝法力为3
		if (isMainCharactor())
			this.magicEquipmentMana = StaticConfig.get(AppStaticConfigs.MAGIC_EQUIPMENT_START_POWER).getAsInt(3);
		battleUnit.afterBattlePropertiesInit(this);
	}

	public BattleSoldier(BattleTeam battleTeam, BattleUnit battleUnit, int position) {
		this(battleTeam, battleUnit);
		this.setPosition(position);
	}

	public int increaseSp(int sp) {
		int maxSp = maxSp();
		if (this.sp >= maxSp)
			return 0;
		int addSp = Math.min(sp, maxSp - this.sp);
		this.sp += addSp;
		return addSp;
	}

	public boolean immuneBuffer() {
		if (this.skillHolder().skill(ALL_BUFF_NOT_SKILL) != null)
			return true;
		return false;
	}

	private void increaseSpWhenBeAttack(CommandContext context) {
		if (!this.isMainCharactor())
			return;
		float rate = Math.abs((float) context.getDamageOutput()) / this.maxHp();
		int addSp = 0;
		if (rate < 0.03)
			addSp = 2;
		else if (rate < 0.1)
			addSp = 10;
		else if (rate < 0.2)
			addSp = 20;
		else if (rate < 0.3)
			addSp = 30;
		else if (rate < 0.5)
			addSp = 40;
		else if (rate < 0.8)
			addSp = 50;
		else if (rate >= 1)
			addSp = 0;
		else
			addSp = 60;
		// 被动技能：怒气百分比影响
		float spRate = this.skillHolder().passiveSkillPropertyEffect(BattleBasePropertyType.SpRate);
		if (spRate > 0 && addSp > 0) {
			addSp *= (1F + spRate);
			addSp = Math.min(addSp, 60);
		}
		// addSp = this.increaseSp(addSp);//bug:重复加sp
		context.setTargetSp(addSp);
	}

	public void decreaseSp(int sp) {
		if (sp >= 0)
			return;
		this.sp += sp;
		if (this.sp < 0)
			this.sp = 0;
	}

	public boolean isMainCharactor() {
		return this.charactorType() == CharactorType.MainCharactor.ordinal();
	}

	public int maxSp() {
		return StaticConfig.get(AppStaticConfigs.MAX_RAGE_LIMIT).getAsInt(150);
	}

	public boolean isEffectPhoenixSkill() {
		return effectPhoenixSkill;
	}

	public boolean isDodgeSuccess() {
		return dodgeSuccess;
	}

	public void setDodgeSuccess(boolean dodgeSuccess) {
		this.dodgeSuccess = dodgeSuccess;
	}

	public void setEffectPhoenixSkill(boolean effectPhoenixSkill) {
		this.effectPhoenixSkill = effectPhoenixSkill;
	}

	/**
	 * 初始化各项属性值
	 */
	public void initProperties() {
		if (this.battleProperties == null)
			this.battleProperties = new BattleSoldierProperties();
		else
			this.battleProperties.reset();
		this.battleProperties.init(battleUnit, this);
	}

	/**
	 * 初始化各项基础战斗属性(与环数相关时额外使用)
	 */
	public void initProperties(int ring) {
		if (this.battleProperties == null)
			this.battleProperties = new BattleSoldierProperties();
		else
			this.battleProperties.reset();
		this.battleProperties.init(battleUnit, this, ring);
	}

	public void monsterVary(int monsterTypeVal) {
		MonsterType monsterType = MonsterType.values()[monsterTypeVal];
		switch (monsterType) {
			case Boss:
				this.battleProperties.setHp((int) (this.battleProperties.getHp() * 1.4));
				this.battleProperties.setAttack((int) (this.battleProperties.getAttack() * 1.3));
				this.battleProperties.setDefense((int) (this.battleProperties.getDefense() * 1.2));
				this.battleProperties.setMagic((int) (this.battleProperties.getMagic() * 1.1));
				this.battleProperties.setSpeed((int) (this.battleProperties.getSpeed() * 1.1));
				break;
			case Baobao:
				this.battleProperties.setHp((int) (this.battleProperties.getHp() * 0.5));
				this.battleProperties.setAttack((int) (this.battleProperties.getAttack() * 0.5));
				this.battleProperties.setDefense((int) (this.battleProperties.getDefense() * 0.5));
				this.battleProperties.setMagic((int) (this.battleProperties.getMagic() * 0.5));
				this.battleProperties.setSpeed((int) (this.battleProperties.getSpeed() * 0.5));
				break;
			case Mutate:
				this.battleProperties.setHp((int) (this.battleProperties.getHp() * 0.5));
				this.battleProperties.setAttack((int) (this.battleProperties.getAttack() * 0.5));
				this.battleProperties.setDefense((int) (this.battleProperties.getDefense() * 0.5));
				this.battleProperties.setMagic((int) (this.battleProperties.getMagic() * 0.5));
				this.battleProperties.setSpeed((int) (this.battleProperties.getSpeed() * 0.5));
				break;
			default:
		}
		this.setMonsterType(monsterTypeVal);
	}

	public BattleUnit battleUnit() {
		return this.battleUnit;
	}

	public BattleSoldierSkillHolder skillHolder() {
		return this.battleSoldierSkillHolder;
	}

	public BattleSoldierBuffHolder buffHolder() {
		return this.battleSoldierBuffHolder;
	}

	public void initForceSkill(int skillId, int... rounds) {
		this.forceSkillId = skillId;
		if (rounds.length > 0 && rounds[0] > 0)
			this.forceSkillRound = rounds[0];

	}

	public BattleTeam battleTeam() {
		return this.battleTeam;
	}

	public Skill forceSkill() {
		if (0 == forceSkillId)
			return null;
		if (this.forceSkillRound > 0) {
			if (this.forceSkillRound != this.battle().getCount())
				return null;
		}
		Skill skill = Skill.get(forceSkillId);
		this.forceSkillId = 0;
		this.forceSkillRound = 0;
		return skill;
	}

	public int forceSkillId() {
		return this.forceSkillId;
	}

	public void forceSkillId(int skillId) {
		this.forceSkillId = skillId;
	}

	public boolean isFirstBeAttacked() {
		return firstBeAttacked;
	}

	public void setFirstBeAttacked(boolean firstBeAttacked) {
		this.firstBeAttacked = firstBeAttacked;
	}

	public BattleSoldier getForceTarget() {
		return this.forceTarget;
	}

	public void setForceTarget(BattleSoldier target) {
		this.forceTarget = target;
	}

	/**
	 * 增加hp
	 * 
	 * @param hpVaryAmount
	 */
	public int increaseHp(int hpVaryAmount) {
		if (hpVaryAmount <= 0)
			return hpVaryAmount;

		int originalHp = this.hp();
		this.battleProperties.setHp(this.hp() + hpVaryAmount);
		if (this.hp() > this.maxHp())
			this.battleProperties.setHp(this.maxHp());
		if (battleLog.isDebugEnabled())
			battleLog.debug(this.team().battle().getId() + ">>>" + toShortString() + " to increase hp:" + hpVaryAmount + ",originalHp:" + originalHp);
		return hpVaryAmount;
	}

	/**
	 * 增加hp
	 * 
	 * @param commandContext
	 * @param hpVaryAmount
	 */
	public int increaseHp(CommandContext commandContext, int hpVaryAmount) {
		// 仙人指路
		BattlePlayer battlePlayer = player();
		if (battlePlayer != null) {
			PlayerStateBarInfo immortalBarInfo = battlePlayer.persistPlayer().stateBarInfoOf(StateBar.IMMORTAL_GUILD_POWER_UP);
			if (immortalBarInfo != null && !immortalBarInfo.expired()) {
				hpVaryAmount *= (1 + immortalBarInfo.getValue());
			}
		}

		increaseHp(hpVaryAmount);
		// commandContext.setDamageOutput(hpVaryAmount);
		if (commandContext.debugEnable() && commandContext.debugInfo() != null)
			commandContext.debugInfo().setHp(hpVaryAmount);
		return hpVaryAmount;
	}

	public void decreaseHpByBuff(int hpVaryAmount) {
		if (hpVaryAmount > -1)
			return;
		int originalHp = this.hp();
		this.battleProperties.setHp(this.hp() + hpVaryAmount);
		this.roundLossHp += hpVaryAmount;
		if (this.hp() < 0)
			this.battleProperties.setHp(0);
		if (battleLog.isDebugEnabled())
			battleLog.debug(this.team().battle().getId() + ">>>" + toShortString() + " to decrease hp:" + hpVaryAmount + ",originalHp:" + originalHp);
	}

	/**
	 * 减少hp
	 * 
	 * @param hpVaryAmount
	 */
	public void decreaseHp(int hpVaryAmount, BattleSoldier... attackers) {
		if (hpVaryAmount > -1)
			return;
		int originalHp = this.hp();
		this.battleProperties.setHp(this.hp() + hpVaryAmount);
		this.roundLossHp += hpVaryAmount;
		if (this.hp() < 0)
			this.battleProperties.setHp(0);
		if (this.isDead()) {
			this.onDead(attackers);
		}
		if (battleLog.isDebugEnabled())
			battleLog.debug(this.team().battle().getId() + ">>>" + toShortString() + " to decrease hp:" + hpVaryAmount + ",originalHp:" + originalHp);
	}

	/**
	 * 减少hp
	 * 
	 * @param commandContext
	 * @param hpVaryAmount
	 */
	public int decreaseHp(CommandContext commandContext, int hpVaryAmount) {
		BattleSoldier trigger = commandContext.trigger();
		boolean same = this.getId() == trigger.getId();// 攻击者=受击者(自伤)
		// 法伤减免(减免到n)
		if (commandContext.skill().ifMagicSkill()) {
			float buffEffect = this.buffHolder().baseEffects(BattleBasePropertyType.MagicHurt);
			if (buffEffect != 0)
				hpVaryAmount *= buffEffect;
			buffEffect = this.buffHolder().baseEffects(BattleBasePropertyType.MagicDamageDecrease);
			if (buffEffect != 0)
				if (buffEffect > 1)
					buffEffect = 1;
			hpVaryAmount *= (1 - buffEffect);
		} else if (commandContext.skill().ifPhyAttack()) {
			float buffEffect = this.buffHolder().baseEffects(BattleBasePropertyType.PhyHurt);
			if (buffEffect != 0)
				hpVaryAmount *= buffEffect;
		}
		hpVaryAmount = tempDamageEffect(trigger, hpVaryAmount);
		// 总伤害
		float buffEffect = trigger.buffHolder().baseEffects(BattleBasePropertyType.DamageOutput);
		float damageOutputRate = 0;
		float damageInputRate = 0;
		if (buffEffect != 0)
			hpVaryAmount *= buffEffect;
		else {
			damageOutputRate = trigger.buffHolder().baseEffects(BattleBasePropertyType.DamageOutputRate);
		}
		buffEffect = this.buffHolder().baseEffects(BattleBasePropertyType.DamageInput);
		if (buffEffect != 0)
			hpVaryAmount *= buffEffect;
		else {
			damageInputRate = this.buffHolder().baseEffects(BattleBasePropertyType.DamageInputRate);
		}
		if (damageOutputRate != 0) {
			if (damageOutputRate < -1)
				damageOutputRate = -1;
			hpVaryAmount *= (1 + damageOutputRate);
		}
		if (damageInputRate != 0) {
			if (damageInputRate < -1)
				damageInputRate = -1;
			hpVaryAmount *= (1 + damageInputRate);
		}
		hpVaryAmount = tempBuffEffect(trigger, hpVaryAmount);
		commandContext.setDamageOutput(hpVaryAmount);

		// 技能免疫（伤害前处理）
		buffHolder().antiSkill(commandContext);
		if (commandContext.isBuffAntiSkill()) {
			VideoAntiSkillTargetState state = new VideoAntiSkillTargetState(this);
			commandContext.skillAction().addTargetState(state);
			return 0;
		}

		// 记录需要扣减受击度的soldier
		commandContext.getBeAttackedTargets().put(this.id, this);

		// 被动技能影响
		if (!same)
			trigger.skillHolder().passiveSkillEffectByTiming(this, commandContext, PassiveSkillLaunchTimingEnum.DamageOutput);
		// 连击加伤害
		if (commandContext.isCombo())
			trigger.skillHolder().passiveSkillEffectByTiming(this, commandContext, PassiveSkillLaunchTimingEnum.ComboDamageOutput);
		this.skillHolder().passiveSkillEffectByTiming(trigger, commandContext, PassiveSkillLaunchTimingEnum.DamageInput);
		this.skillHolder().passiveSkillEffectByTiming(trigger, commandContext, PassiveSkillLaunchTimingEnum.AfterDamageInput);
		hpVaryAmount = commandContext.getDamageOutput();
		// 因为新增了一个被动技能，浴血凤凰，可以免除伤害，所以允许出现伤害为0
		if (isEffectPhoenixSkill() && hpVaryAmount == 0) {
			setEffectPhoenixSkill(false);
			return 0;
		}
		if (hpVaryAmount > -1)
			hpVaryAmount = -1;
		increaseSpWhenBeAttack(commandContext);
		decreaseHp(hpVaryAmount, trigger);
		if (this.isDead()) {
			// 击飞
			if (!same)
				trigger.skillHolder().passiveSkillEffectByTiming(this, commandContext, PassiveSkillLaunchTimingEnum.TargetKilled);
			// 挂了宠物喊话
			if (isMainCharactor()) {
				BattleSoldier pet = myPet();
				if (pet != null && !pet.isDead()) {
					pet.shout(ShoutConfig.BattleShoutTypeEnum.MasterFall, commandContext);
				}
			}
		}
		if (commandContext.debugEnable())
			commandContext.debugInfo().setHp(hpVaryAmount);
		return hpVaryAmount;
	}

	private int tempDamageEffect(BattleSoldier trigger, int hpVaryAmount) {
		BattlePlayer leader = trigger.team().leader();
		if (leader == null)
			return hpVaryAmount;
		if (!MythLandSceneService.getInstance().inMythScene(leader))
			return hpVaryAmount;
		PlayerStateBarInfo barInfo = leader.persistPlayer().stateBarInfoOf(StateBar.MYTH_LAND_POWER_UP);
		if (barInfo != null && !barInfo.expired()) {
			hpVaryAmount *= (1 + barInfo.getValue());
		}
		return hpVaryAmount;
	}

	private int tempBuffEffect(BattleSoldier trigger, int hpVaryAmount) {
		// 仙人指路，本人有buff
		if (trigger.playerId() > 0) {
			BattlePlayer battlePlayer = trigger.player();
			if (battlePlayer != null) {
				PlayerStateBarInfo immortalBarInfo = battlePlayer.persistPlayer().stateBarInfoOf(StateBar.IMMORTAL_GUILD_POWER_UP);
				if (immortalBarInfo != null && !immortalBarInfo.expired()) {
					// int old = hpVaryAmount;
					hpVaryAmount *= (1 + immortalBarInfo.getValue());
					// System.out.println("#####tempBuffEddect##" +
					// trigger.getId() + "--" + trigger.name() + "--old=" + old
					// + "--incr=" + hpVaryAmount);
					return hpVaryAmount;
				}
			}
		}

		return hpVaryAmount;
	}

	public void onDead(BattleSoldier... attackers) {
		this.deadSp = this.sp;// 缓存怒气
		this.sp = 0;// 死亡怒气清除
		this.deadRound = battle().getCount();// 记录死亡回合
		// 人物/伙伴死亡后留在场内;npc/召唤出来的小怪/宠物飞出场外
		CharactorType type = CharactorType.values()[this.charactorType()];
		switch (type) {
			case Monster:
			case Pet:
				this.isLeave = true;
				break;
			case MainCharactor:
			case Crew:
				this.isLeave = false;
				break;
			default:
				this.isLeave = true;
				break;
		}
		// 复活
		BattleSoldier attacker = null;
		if (attackers.length > 0)
			attacker = attackers[0];
		CommandContext commandContext = attacker == null ? null : attacker.commandContext;
		boolean banLife = false;
		if (commandContext != null)
			banLife = commandContext.skill().isBanLife();
		// 门派特色(盘丝洞)：保命
		if (!banLife)
			factionEffectSaveLife(attacker);
		if (!this.isDead())
			return;
		// 门派特色(普陀山):复活
		if (!banLife)
			factionEffectRelive(attacker);
		if (!this.isDead())
			return;
		if (this.isLeave)
			this.isLeave = !this.buffHolder().hasPreventLeaveBuff();
		this.team().increaseRoundDeadCount(1);
		this.skillHolder().passiveSkillEffectByTiming(attacker, commandContext, PassiveSkillLaunchTimingEnum.Dead);
		this.attackDead(commandContext);
		otherEscape(commandContext);
		if (this.isLeave) {
			this.skillHolder().passiveSkillEffectByTiming(attacker, attacker == null ? null : attacker.commandContext, PassiveSkillLaunchTimingEnum.OnLeave);
			this.leaveTeam();
		}
	}

	/**
	 * 死亡的时候触发其他单位撤退
	 */
	private void otherEscape(CommandContext context) {
		for (BattleSoldier soldier : this.team().aliveSoldiers()) {
			if (soldier.getId() == this.id)
				continue;
			soldier.skillHolder().passiveSkillEffectByTiming(this, context, PassiveSkillLaunchTimingEnum.TeammateDead);
		}

		for (BattleSoldier s : this.team().getEnemyTeam().aliveSoldiers())
			s.skillHolder().passiveSkillEffectByTiming(this, context, PassiveSkillLaunchTimingEnum.EnemyDead);
	}

	/**
	 * 门派特色(普陀山):神佑效果
	 */
	private void factionEffectRelive(BattleSoldier attacker) {
		Faction f = this.faction();
		if (f != null) {
			FactionBattleLogicParam param = f.getFactionBattleLogicParam();
			if (param != null && param instanceof FactionBattleLogicParam_6 && !this.ifChild()) {
				FactionBattleLogicParam_6 p = (FactionBattleLogicParam_6) param;
				float rate = p.getRate();
				if (this.hasGodHelp())
					rate += p.getPlusRate();
				float percentage = p.getPercentage();
				if (percentage > 0) {
					boolean hit = RandomUtils.baseRandomHit(rate);
					if (hit) {
						int hp = (int) (this.maxHp() * percentage);
						if (hp > 0) {
							this.increaseHp(hp);
							this.setLeave(false);
							VideoActionTargetState state = new VideoActionTargetState(this, hp, 0, false);
							RoundState rs = this.roundContext().getState();
							if (rs == RoundState.RoundStart) {
								this.currentVideoRound().readyAction().addTargetState(state);
							} else if (rs == RoundState.RoundAction) {
								if (attacker != null)
									attacker.getCommandContext().skillAction().addTargetState(state);
							} else if (rs == RoundState.RoundOver) {
								this.currentVideoRound().endAction().addTargetState(state);
							}
						}
					}
				}
			}
		}
	}

	/**
	 * 门派特色(狮驼岭):宠物不逃跑
	 */
	private void factionEffectNotEscape() {
		if (!this.ifPet())
			return;
		BattlePlayer bp = this.player();
		if (bp == null)
			return;
		Faction f = Faction.get(bp.factionId());
		if (f != null) {
			FactionBattleLogicParam param = f.getFactionBattleLogicParam();
			if (param != null && param instanceof FactionBattleLogicParam_8) {
				this.commandContext.setAutoEscapeable(false);
			}
		}
	}

	/**
	 * 门派特色(盘丝洞):保命
	 * 
	 * @param attacker
	 */
	private boolean factionEffectSaveLife(BattleSoldier attacker) {
		Faction f = this.faction();
		if (f != null) {
			FactionBattleLogicParam param = f.getFactionBattleLogicParam();
			if (param != null && param instanceof FactionBattleLogicParam_9 && !this.ifChild()) {
				if (this.battle().battleInfo().factionReliveSoldierIds().contains(this.id))
					return false;
				FactionBattleLogicParam_9 p = (FactionBattleLogicParam_9) param;
				float rate1 = p.getRate1();
				float rate2 = factionSaveLifeRateEffect(p.getRate2(), attacker);
				float rate = this.battle() instanceof PveBattle ? rate1 : rate2;
				boolean saveLife = RandomUtils.baseRandomHit(rate);
				if (saveLife) {
					this.battle().battleInfo().factionReliveSoldierIds().add(this.id);
					int hp = 1;// 保留1点hp
					this.increaseHp(hp);
					this.setLeave(false);
					int spVary = 0;
					// 复活恢复怒气
					if (this.skillHolder().passiveSkill(Skill.psFactionEffectPassiveSkill()) != null) {
						this.sp = this.deadSp;
						spVary = this.sp;
						this.deadSp = 0;
					}
					VideoActionTargetState state = new VideoActionTargetState(this, hp, 0, false, spVary);
					RoundState rs = this.roundContext().getState();
					if (rs == RoundState.RoundStart) {
						this.currentVideoRound().readyAction().addTargetState(state);
					} else if (rs == RoundState.RoundAction) {
						if (attacker != null)
							attacker.getCommandContext().skillAction().addTargetState(state);
					} else if (rs == RoundState.RoundOver) {
						this.currentVideoRound().endAction().addTargetState(state);
					}
					return true;
				}
			}
		}
		return false;
	}

	private float factionSaveLifeRateEffect(float rate, BattleSoldier attacker) {
		try {
			List<IPassiveSkill> skills = this.skillHolder().battleSkillHolder().passiveSkillFilter();
			for (Iterator<IPassiveSkill> it = skills.iterator(); it.hasNext();) {
				IPassiveSkill ps = it.next();
				if (ps.getConfigId() == null)
					continue;
				for (int configId : ps.getConfigId()) {
					PassiveSkillConfig config = PassiveSkillConfig.get(configId);
					if (config == null || config.getExtraParams() == null || config.getExtraParams().length < 2)
						continue;
					// 92被动逻辑，被非npc 击倒可增加门派技能触发概率
					if (config.getLogicId() != PassiveSkillLogicEnum.PSFactionUniqueSkillRate.ordinal())
						continue;
					if (!attacker.ifMainCharactor())
						continue;
					String rateFormula = config.getExtraParams()[0];
					Map<String, Object> params = new HashMap<String, Object>();
					try {
						params.put("skillLevel", skillLevel(Integer.parseInt(config.getExtraParams()[1])));
					} catch (Exception e) {
						LogUtils.errorLog(e);
					}

					rate += ScriptService.getInstance().calcuFloat("cur factionSaveLifeRateEffect", rateFormula, params, false);
				}
			}
		} catch (Exception e) {
			LogUtils.errorLog("BattleSoldier.factionSaveLifeRateEffect: " + e);
		}
		return rate;
	}

	/**
	 * 增加mp
	 * 
	 * @param mpAmount
	 */
	public void increaseMp(int mpAmount) {
		if (mpAmount <= 0)
			return;
		float originalMp = this.mp();
		this.battleProperties.setMp(this.mp() + mpAmount);
		if (this.mp() > this.maxMp())
			this.battleProperties.setMp(this.maxMp());
		if (battleLog.isDebugEnabled())
			battleLog.debug(this.team().battle().getId() + ">>>" + toShortString() + " to increase mp:" + mpAmount + ",originalMp:" + originalMp);
	}

	/**
	 * 增加mp
	 * 
	 * @param commandContext
	 * @param mpAmount
	 */
	public void increaseMp(CommandContext commandContext, int mpAmount) {
		increaseMp(mpAmount);
	}

	/**
	 * 减少mp
	 * 
	 * @param mpAmount
	 */
	public void decreaseMp(int mpAmount) {
		if (mpAmount >= 0)
			return;
		float originalMp = this.mp();
		this.battleProperties.setMp(this.mp() + mpAmount);
		if (this.mp() < 0)
			this.battleProperties.setMp(0);
		if (battleLog.isDebugEnabled())
			battleLog.debug(this.team().battle().getId() + ">>>" + toShortString() + " to decrease mp:" + mpAmount + ",originalMp:" + originalMp);
	}

	/**
	 * 减少mp
	 * 
	 * @param commandContext
	 * @param mpAmount
	 */
	public void decreaseMp(CommandContext commandContext, int mpAmount) {
		decreaseMp(mpAmount);
	}

	/**
	 * 自动战斗
	 */
	public void autoBattle() {
		// if (this.isDead())
		// return;
		setAutoBattle(true);
		initCommandContext(this.skillHolder().selectCommand());
	}

	/**
	 * 用指定的技能进行自动战斗
	 * 
	 * @param skill
	 */
	public void autoBattle(Skill skill, BattleSoldier target) {
		if (this.isDead())
			return;
		setAutoBattle(true);
		this.commandContext = new CommandContext(this, skill, target);
	}

	public void initCommandContextIfAbsent() {
		if (this.commandContext == null) {
			// this.commandContext = new CommandContext(this,
			// this.skillHolder().aiSkill(), null);
			this.commandContext = this.skillHolder().selectCommand();
		}
	}

	/**
	 * 受击结算
	 * 
	 * @param commandContext
	 *            - 攻击者指令内容
	 */
	public void underAttack(CommandContext commandContext) {
		long triggerId = commandContext.trigger().getId();
		if (triggerId != this.getId() && !isTeamMember(triggerId)) {
			if (!this.isDead()) {
				VideoSkillAction skillAction = commandContext.skillAction();
				if (commandContext.getDamageOutput() < 0) {
					shout(ShoutConfig.BattleShoutTypeEnum.SufferBeating, commandContext);
					removeBuffOnAttack(skillAction);
				}
				commandContext.populateTarget(this);
				this.buffHolder().buffEffectWhenUnderAttack(commandContext);
				// 反弹/反击
				this.skillHolder().passiveSkillEffectByTiming(commandContext.trigger(), commandContext, PassiveSkillLaunchTimingEnum.UnderAttack);
				if (!commandContext.isStrokeBack())
					commandContext.strikeBack(skillAction);
			}
		}
	}

	/**
	 * 受击死亡
	 * 
	 * @param commandContext
	 */
	public void attackDead(CommandContext commandContext) {
		if (commandContext == null)
			return;
		long triggerId = commandContext.trigger().getId();
		if (triggerId != this.getId() && !isTeamMember(triggerId)) {
			if (this.isDead()) {
				this.buffHolder().buffEffectWhenAttackDead(commandContext);
			}
		}
	}

	/**
	 * 受击移除buff
	 * 
	 * @param skillAction
	 */
	private void removeBuffOnAttack(VideoSkillAction skillAction) {
		List<Integer> buffIdList = new ArrayList<Integer>();
		for (Iterator<BattleBuffEntity> it = this.buffHolder().allBuffs().values().iterator(); it.hasNext();) {
			BattleBuffEntity buff = it.next();
			if (buff.battleBuff().isRemoveOnAttack()) {
				buffIdList.add(buff.battleBuffId());
			}
		}
		if (!buffIdList.isEmpty()) {
			skillAction.addTargetState(new VideoBuffRemoveTargetState(this, buffIdList.toArray(new Integer[buffIdList.size()])));
			for (Integer buffId : buffIdList)
				this.buffHolder().removeBuffById(buffId);
		}
	}

	public int getPosition() {
		return position;
	}

	public void setPosition(int position) {
		this.position = position;
	}

	public void setBattleUnit(BattleUnit battleUnit) {
		this.battleUnit = battleUnit;
	}

	public int charactorId() {
		return charactorId;
	}

	public int grade() {
		return grade;
	}

	public void setGrade(int grade) {
		this.grade = grade;
	}

	public int monsterId() {
		return monsterId;
	}

	public int skillLevel(int skillId) {
		BattleSkillHolder<?> skillHolder = this.battleUnit.battleSkillHolder();
		if (skillHolder instanceof MonsterBattleSkillHolder)
			return this.grade;
		return this.battleUnit.battleSkillHolder().skillLevel(skillId);
	}

	public int getSpellLevel() {
		return spellLevel;
	}

	public void setSpellLevel(int spellLevel) {
		this.spellLevel = spellLevel;
	}

	/** 基础速度 */
	public int spd() {
		return this.battleProperties.getSpeed();
	}

	/** 先手值 */
	public int speed() {
		int buffEffect = (int) buffHolder().baseEffects(BattleBasePropertyType.Speed);
		Skill curSkill = null;
		if (this.commandContext != null)
			curSkill = this.commandContext.skill();
		float skillSpeed = 0.0f;
		if (curSkill != null)
			skillSpeed = BattleUtils.valueWithSoldierSkill(this, curSkill.getExtraSpeedFormula(), curSkill);
		// 阵型加成,会减速度
		float speedRate = propFloat(BattleBasePropertyType.SpeedRate) + this.battleTeam.formation().effectRate(this.formationIndex, BattleBasePropertyType.SpeedRate);
		float speedAdd = this.spd() * speedRate;
		float passiveEffect = this.skillHolder().passiveSkillPropertyEffect(BattleBasePropertyType.Speed);
		return (int) Math.max(0, this.battleProperties.getSpeed() + skillSpeed + buffEffect + speedAdd + passiveEffect);
	}

	/** 基础攻击力 */
	public int atk() {
		return this.battleProperties.getAttack();
	}

	/** 攻击力 */
	public int attack() {
		float pivot = 1.f;
		if (this.commandContext != null)
			pivot = this.commandContext.getPerAttackVaryRate();
		int buffEffect = (int) buffHolder().baseEffects(BattleBasePropertyType.Attack);
		float attackVaryRate = 1F;
		if (null != this.commandContext)
			attackVaryRate = this.commandContext.getCurAttackVaryRate();
		float buffRate = buffHolder().baseEffects(BattleBasePropertyType.AttackRate);
		attackVaryRate += buffRate;
		int v = (int) (this.battleProperties.getAttack() * attackVaryRate * pivot + buffEffect);
		v = (int) dayNightEffect(v);
		return v;
	}

	/** hp */
	public int hp() {
		return this.battleProperties.getHp();
	}

	/** 当前血量比例 **/
	public float hpRate() {
		return ((float) this.hp()) / this.maxHp();
	}

	public int getMaxDamage() {
		return maxDamage;
	}

	public void setMaxDamage(int maxDamage) {
		this.maxDamage = maxDamage;
	}

	public int getMaxPetDamage() {
		return maxPetDamage;
	}

	public void setMaxPetDamage(int maxPetDamage) {
		this.maxPetDamage = maxPetDamage;
	}

	/** mp */
	public int mp() {
		return this.battleProperties.getMp();
	}

	/** 当前魔法值比例 */
	public float mpRate() {
		return ((float) this.mp()) / this.maxMp();
	}

	/** 最大hp */
	public int maxHp() {
		return (this.battleProperties.getMaxHp());
	}

	/** 最大mp */
	public int maxMp() {
		return this.battleProperties.getMaxMp();
	}

	/** 基础防御力 */
	public int def() {
		return this.battleProperties.getDefense();
	}

	/** 基础法术防御力 */
	public int bmd() {
		return this.battleProperties.getMagicDefense();
	}

	/** 基础法术攻击力 */
	public int bma() {
		return this.battleProperties.getMagicAttack();
	}

	/** 防御力 */
	public int defense() {
		int buffEffect = (int) buffHolder().baseEffects(BattleBasePropertyType.Defense);
		int passiveEffect = (int) this.skillHolder().passiveSkillPropertyEffect(BattleBasePropertyType.Defense);
		int v = this.def() + buffEffect + passiveEffect;
		v = (int) dayNightEffect(v);
		return v;
	}

	/** 基础攻击力 */
	public int mgc() {
		return this.battleProperties.getMagic();
	}

	/** 灵力 */
	public int magic() {
		float pivot = 1.f;
		if (this.commandContext != null)
			pivot = this.commandContext.getPerAttackVaryRate();
		int buffEffect = (int) buffHolder().baseEffects(BattleBasePropertyType.Magic);
		int passiveEffect = (int) this.skillHolder().passiveSkillPropertyEffect(BattleBasePropertyType.Magic);
		float attackVaryRate = 1F;
		if (null != this.commandContext)
			attackVaryRate = this.commandContext.getCurAttackVaryRate();
		return (int) (this.mgc() * attackVaryRate * pivot + buffEffect + passiveEffect);
	}

	/**
	 * 物理命中率
	 * 
	 * @return
	 */
	public float hitRate() {
		float buffEffect = buffHolder().baseEffects(BattleBasePropertyType.HitRate);
		return this.battleProperties.getHitRate() + this.battleUnit.extraGeneralHitRate(this.grade) + buffEffect;
	}

	/** 基础物理暴击率 */
	public float ctr() {
		return this.battleProperties.getCritRate();
	}

	/** 物理暴击率 */
	public float critRate() {
		float buffEffect = buffHolder().baseEffects(BattleBasePropertyType.CritRate);
		float extraCritRate = extraCritRate();
		return this.ctr() + buffEffect + extraCritRate;
	}

	/** 技能暴击率加成 */
	private float extraCritRate() {
		Skill curSkill = null;
		if (this.commandContext != null)
			curSkill = this.commandContext.skill();
		float extraCritRate = 0.0f;
		if (curSkill != null)
			extraCritRate = BattleUtils.valueWithSoldierSkill(this, curSkill.getExtraCritRateFormula(), curSkill);
		return extraCritRate;
	}

	/** 抗暴率 */
	public float critReduceRate() {
		float rate = propFloat(BattleBasePropertyType.CritRateReduce);
		float buffEffect = buffHolder().baseEffects(BattleBasePropertyType.CritRateReduce);
		float phyCritRate = propFloat(BattleBasePropertyType.PhyCritReduceRate);
		return rate + buffEffect + phyCritRate;
	}

	/** 基础闪避率 */
	public float dgr() {
		return this.battleProperties.getDodgeRate();
	}

	/** 闪避率 */
	public float dodgeRate() {
		float buffEffect = buffHolder().baseEffects(BattleBasePropertyType.DodgeRate);
		float v = this.dgr() + buffEffect + this.battleUnit.extraGeneralDodgeRate(this.grade);
		v += this.skillHolder().passiveSkillPropertyEffect(BattleBasePropertyType.DodgeRate);
		return v;
	}

	/** 基础法术暴击率 */
	public float mcrt() {
		return this.battleProperties.getMagicCritRate();
	}

	/** 法术暴击率 */
	public float magicCritRate() {
		float buffEffect = buffHolder().baseEffects(BattleBasePropertyType.MagicCritRate);
		float extraCritRate = extraCritRate();
		float v = this.skillHolder().passiveSkillPropertyEffect(BattleBasePropertyType.MagicCritRate);
		return this.mcrt() + buffEffect + extraCritRate + v;
	}

	/** 法术抗暴率 */
	public float magicCritReduceRate() {
		float rate = propFloat(BattleBasePropertyType.CritRateReduce);
		float buffEffect = buffHolder().baseEffects(BattleBasePropertyType.CritRateReduce);
		float magicCritRate = propFloat(BattleBasePropertyType.MagicCritReduceRate);
		return rate + buffEffect + magicCritRate;
	}

	/** 基础法术命中率 */
	public float mhtr() {
		return this.battleProperties.getMagicHitRate();
	}

	/** 法术命中率 */
	public float magicHitRate() {
		float buffEffect = buffHolder().baseEffects(BattleBasePropertyType.MagicHitRate);
		return this.mhtr() + buffEffect;
	}

	/** 基础法术闪避率 */
	public float mdgr() {
		return this.battleProperties.getMagicDodgeRate();
	}

	/** 法术闪避率 */
	public float magicDodgeRate() {
		float buffEffect = buffHolder().baseEffects(BattleBasePropertyType.MagicDodgeRate);
		float formationMagicDodgeRate = this.battleTeam.formation().effectRate(this.formationIndex, BattleBasePropertyType.MagicDodgeRate);
		float v = this.skillHolder().passiveSkillPropertyEffect(BattleBasePropertyType.MagicDodgeRate);
		return this.mdgr() + buffEffect + formationMagicDodgeRate + v;
	}

	/** 法术攻击力 */
	public int magicAttack() {
		int buffEffect = (int) buffHolder().baseEffects(BattleBasePropertyType.MagicAttack);
		return this.magic() + buffEffect + bma() - mgc();
	}

	/** 法术防御力 */
	public int magicDefense() {
		int buffEffect = (int) buffHolder().baseEffects(BattleBasePropertyType.MagicDefense);
		int passiveEffect = (int) this.skillHolder().passiveSkillPropertyEffect(BattleBasePropertyType.MagicDefense);
		return this.magic() + buffEffect + bmd() - mgc() + passiveEffect;
	}

	/** 暴击伤害率 */
	public float critHurtRate() {
		float rate = propFloat(BattleBasePropertyType.CritHurtRate);
		return rate;
	}

	/** 暴击伤害抗伤率 */
	public float critHurtReduceRate() {
		float rate = propFloat(BattleBasePropertyType.CritHurtReduceRate);
		return rate;
	}

	/** 角色经验 */
	public long exp() {
		return this.exp;
	}

	/** 受击度 */
	public float strikeRate() {
		return this.strikeRate;
	}

	/** 增加受击度 */
	public void increaseStrikeRate() {
		float calcStrikeRate = this.strikeRate + battleStrikeVaryRate();
		float battleMaxStrikeRate = battleMaxStrikeRate();
		if (calcStrikeRate > battleMaxStrikeRate) {
			this.strikeRate = battleMaxStrikeRate;
		} else {
			this.strikeRate = calcStrikeRate;
		}
	}

	/** 每回合清除受击度 */
	public void decreaseStrikeRatePerRound() {
		this.strikeRate = 0;
	}

	protected void reduceStrikeRate(float calcStrikeRate) {
		float battleBaseStrikeRate = battleBaseStrikeRate();
		if (calcStrikeRate > battleBaseStrikeRate) {
			this.strikeRate = battleBaseStrikeRate;
		} else {
			this.strikeRate = calcStrikeRate;
		}
		this.strikeRate = Math.max(0, this.strikeRate);
	}

	public int charactorType() {
		return battleUnit.charactorType().ordinal();
	}

	public int factionId() {
		int factionId = 0;
		switch (CharactorType.values()[this.charactorType()]) {
			case MainCharactor:
			case Crew:
				factionId = battleUnit.faction().getId();
				break;
			default:
		}
		return factionId;
	}

	public Faction faction() {
		return battleUnit.faction();
	}

	public long getId() {
		return this.id;
	}

	public boolean isDead() {
		return this.hp() <= 0;
	}

	public int customId() {
		return this.customId;
	}

	public int customId(int customId) {
		return this.customId = customId;
	}

	public long id() {
		return this.id;
	}

	public long playerId() {
		return this.playerId;
	}

	public void setPlayerId(long playerId) {
		this.playerId = playerId;
	}

	public String name() {
		return this.name;
	}

	public void name(String name) {
		this.name = name;
	}

	public BattleTeam team() {
		return battleTeam;
	}

	public String toShortString() {
		StringBuilder sb = new StringBuilder();
		sb.append("soldier{");
		sb.append("id:").append(this.getId());
		sb.append(", name:").append(this.name());
		sb.append(", position:" + this.getPosition());
		sb.append(", hp:" + this.hp());
		sb.append("}");
		return sb.toString();
	}

	public String toBattleInfo() {
		StringBuilder sb = new StringBuilder();
		sb.append("soldier:{");
		sb.append("id:").append(this.getId());
		sb.append(", name:").append(this.name());
		sb.append(", hp:").append(this.hp());
		sb.append(", maxHp:").append(this.maxHp());
		sb.append(", mp:").append(this.mp());
		sb.append(", maxMp:").append(this.maxMp());
		sb.append(", phyAttack:").append(this.attack());
		sb.append(", phyDefense:").append(this.defense());
		sb.append(", magic:").append(this.magic());
		sb.append(", magicAttack:").append(this.magicAttack());
		sb.append(", magicDefense:").append(this.magicDefense());
		sb.append(", speed:").append(this.speed());
		sb.append(", strikeRate").append(this.strikeRate());
		sb.append(", critRate:").append(this.critRate());
		sb.append(", critHurtRate:").append(this.critHurtRate());
		sb.append(", critHurtReduceRate:").append(this.critHurtReduceRate());
		sb.append(", dodgeRate:").append(this.dodgeRate());
		sb.append(", magicCritRate:").append(this.magicCritRate());
		sb.append(", magicHitRate:").append(this.magicHitRate());
		sb.append(", magicDodgeRate:").append(this.magicDodgeRate());
		sb.append(", grade:").append(this.grade());
		sb.append(", spellLevel:").append(this.getSpellLevel());
		sb.append(", spellInfo:").append(this.spellEffectCalculator().toSpellInfo(this));
		sb.append("}");
		return sb.toString();
	}

	// ===============================
	// 战斗回合开始结束操作======================================

	/** 结算回合开始buff */
	public void executeRoundStartBuffs() {
		buffHolder().executeRoundStartBuffs();
	}

	/** 结算回合结束buff */
	public void executeRoundEndBuffs() {
		// if (this.isDead())
		// return;
		buffHolder().executeRoundEndBuffs();
		this.soldierStatus = SoldierStatus.Normal;
		this.protectedBySoldierIds.clear();
	}

	/**
	 * 回合开始
	 */
	public void actionStart() {
		try {
			actionDone = false;
			this.curRoundProcessor.resetSpeedChange();
			this.battleSoldierBuffHolder.executeActionStartBuffs();

			if (!this.isDead()) {
				final boolean success = this.skillHolder().onActionStart(this.commandContext);
				if (success) {
					tryEscape();
					this.skillHolder().passiveSkillEffectByTiming(this, this.commandContext, PassiveSkillLaunchTimingEnum.BeforeFireSkill);
					this.commandContext.fireSkill();
					if (this.commandContext != null) {
						Skill skill = this.commandContext.skill();
						if (skill != null && skill.getId() == Skill.SPECIAL_SKILL_ID && this.commandContext.skillAction().getSkillStatusCode() == AppSkillActionStatusCode.CannotFindTarget) {
							skill = Skill.get(Skill.SPECIAL_SKILL_ID_BACKUP);
							if (skill != null) {
								clearCurrentRoundSkillActions();
								this.commandContext = new CommandContext(this, skill, this);
								skill.fired(this.commandContext);
							}
						}
					}
				} else {
					// 2016/2/20 当前回合未出手时也增加skillAction，客户端可能需要喊话
					if (this.commandContext != null) {
						this.commandContext.skillAction().setSkillStatusCode(AppSkillActionStatusCode.RoundPass);
					}
				}
				actionDone = true;
			}
			this.battleSoldierBuffHolder.executeActionEndBuffs();
		} catch (Exception e) {
			LogUtils.errorLog("BattleSoldier.actionStart: " + this.commandContext, e);
		} finally {
			// 真正行动完毕才清空指令,避免死后复活再次行动出现指令为null的情况
			if (this.isActionDone())
				this.commandContext = null;
		}
	}

	/**
	 * 清除自己已行动动作
	 */
	private void clearCurrentRoundSkillActions() {
		for (Iterator<VideoSkillAction> it = this.currentVideoRound().getSkillActions().iterator(); it.hasNext();) {
			VideoSkillAction action = it.next();
			if (action.getActionSoldierId() == this.id)
				it.remove();
		}
	}

	/**
	 * 宠物尝试逃跑
	 */
	private void tryEscape() {
		Skill skill = this.commandContext.skill();
		boolean retreatSkill = skill != null && skill.getId() == Skill.retreatSkillId();
		if (this.charactorType() == CharactorType.Pet.ordinal() && !retreatSkill) {
			if (this.preventAutoEscape())
				return;
			this.commandContext.setAutoEscapeable(true);// 默认允许宠物自动逃跑
			factionEffectNotEscape();
			if (!this.commandContext.isAutoEscapeable())
				return;
			this.skillHolder().passiveSkillEffectByTiming(this, this.commandContext, PassiveSkillLaunchTimingEnum.BeforeTryEscape);
			if (!this.commandContext.isAutoEscapeable())
				return;
			float escapeRate = 0.f;
			float hpRate = this.hpRate();
			Battle battle = this.battle();
			if (hpRate <= battle.petEscapeHpRate1()) {
				escapeRate = battle.petEscapeRate1();
			} else if (hpRate <= battle.petEscapeHpRate2()) {
				escapeRate = battle.petEscapeRate2();
			}
			if (escapeRate > 0) {
				if (this.commandContext != null) {
					if (skill != null) {
						if (skill.getId() == Skill.useItemSkillId() || skill.getId() == Skill.defenseSkillId()) {
							escapeRate += battle.petEscapePlusRate();
						}
					}
				}
				boolean success = RandomUtils.baseRandomHit(escapeRate);
				if (success) {
					this.commandContext.setSkill(Skill.retreatSkill());
				}
			}
		}
	}

	/**
	 * 阻止自动逃跑
	 * 
	 * @return
	 */
	public boolean preventAutoEscape() {
		return this.buffHolder().hasPreventAutoEscapeBuff();
	}

	/**
	 * 计算玩家战斗中最大伤害和宠物最大伤害
	 * 
	 * @param battle
	 * @param damage
	 */
	public void culMaxDamage(int damage) {
		if (isMainCharactor()) {
			if (damage > maxDamage) {
				setMaxDamage(damage);
			}
		} else if (ifPet() && battleUnit() instanceof PersistPlayerPet) {
			PersistPlayerPet pet = (PersistPlayerPet) battleUnit();
			long playerId = pet.getPlayerId();
			BattleInfo info = battle().battleInfo();
			BattleSoldier player = info.battleSoldier(playerId);
			if (damage > player.getMaxPetDamage()) {
				player.setMaxPetDamage(damage);
			}
		}
	}

	public VideoRound currentVideoRound() {
		return team().battle().getVideo().getRounds().currentVideoRound();
	}

	public boolean isTeamMember(long soldierId) {
		return battleTeam().hasSoldier(soldierId);
	}

	public boolean isEnemy(long soldierId) {
		if (this.id == soldierId)
			return false;
		boolean isEnemy = this.battleTeam.getEnemyTeam().allSoldiersMap().containsKey(soldierId);
		return isEnemy;
	}

	// ===============================
	// 技能上下文操作======================================
	private CommandContext commandContext;
	private CommandContext oldCommandContext;// 如果遭受速度快的一方打击且触发自身反击的情况下,要把下好的指令保存下来,反击之后继续执行之前的指令

	public void initCommandContext(CommandContext commandContext) {
		this.commandContext = commandContext;
	}

	public void destoryCommandContext() {
		this.commandContext = null;
	}

	public CommandContext getCommandContext() {
		return commandContext;
	}

	public CommandContext getOldCommandContext() {
		return oldCommandContext;
	}

	public void setOldCommandContext(CommandContext oldCommandContext) {
		this.oldCommandContext = oldCommandContext;
	}

	@Override
	public int compareTo(BattleSoldier o) {
		if (this.forceLeaveBattle)
			return 1;
		else if (o.forceLeaveBattle)
			return -1;
		int value = this.speed() - o.speed();
		if (value == 0) {
			value = this.charactorType() - o.charactorType();
			if (value == 0) {
				long diffExp = this.exp() - o.exp();
				if (diffExp > 0) {
					value = 1;
				} else if (diffExp < 0) {
					value = -1;
				}
			}
		}
		return value;
	}

	@Override
	public String toString() {
		return toShortString();
	}

	public boolean isAutoBattle() {
		return autoBattle;
	}

	public void setAutoBattle(boolean autoBattle) {
		this.autoBattle = autoBattle;
	}

	public boolean isActionDone() {
		return actionDone;
	}

	public void setActionDone(boolean actionDone) {
		this.actionDone = actionDone;
	}

	public DefaultBattleRoundProcessor getCurRoundProcessor() {
		return curRoundProcessor;
	}

	public void setCurRoundProcessor(DefaultBattleRoundProcessor curRoundProcessor) {
		this.curRoundProcessor = curRoundProcessor;
		this.roundContext = curRoundProcessor.context();
	}

	public SoldierStatus soldierStatus() {
		return this.soldierStatus;
	}

	public void updateSoldierStatus(SoldierStatus soldierStatus) {
		this.soldierStatus = soldierStatus;
	}

	public float underAttackShowTime() {
		return battleSkillHpSpentShowTime();
	}

	public Battle battle() {
		return this.battleTeam().battle();
	}

	public List<Long> protectedBySoldierIds() {
		return this.protectedBySoldierIds;
	}

	public void addProtectedBySoldierId(long protectedBySoldierId) {
		this.protectedBySoldierIds.add(protectedBySoldierId);
	}

	public int getMonsterType() {
		return monsterType;
	}

	public void setMonsterType(int monsterType) {
		this.monsterType = monsterType;
	}

	public int getSp() {
		return sp;
	}

	public void setSp(int sp) {
		this.sp = sp;
	}

	public int getMaxSp() {
		return maxSp;
	}

	public void setMaxSp(int maxSp) {
		this.maxSp = maxSp;
	}

	public int getDeadRound() {
		return deadRound;
	}

	public void setDeadRound(int deadRound) {
		this.deadRound = deadRound;
	}

	public int getFormationIndex() {
		return formationIndex;
	}

	public void setFormationIndex(int formationIndex) {
		this.formationIndex = formationIndex;
	}

	public boolean ifMainCharactor() {
		BattlePlayerSoldierInfo info = this.battleTeam().soldiersByPlayer(playerId);
		if (info == null)
			return false;
		return info.mainCharactorSoldierId() == this.id;
	}

	public boolean ifPet() {
		BattlePlayerSoldierInfo info = this.battleTeam().soldiersByPlayer(playerId);
		if (info == null)
			return false;
		return info.petSoldierId() == this.id;
	}

	public boolean ifCrew() {
		return CharactorType.Crew.ordinal() == this.charactorType();
	}

	public boolean ifChild() {
		return this.charactorType() == CharactorType.Child.ordinal();
	}

	/**
	 * 是否变异
	 * 
	 * @return
	 */
	public boolean isMutate() {
		return this.battleUnit.mutate();
	}

	public void leaveTeam() {
		this.curRoundProcessor.getActionQueue().remove(this);
		this.battleTeam.soldierLeave(this);
		this.isLeave = true;
	}

	public boolean isLeave() {
		return isLeave;
	}

	public void setLeave(boolean isLeave) {
		this.isLeave = isLeave;
	}

	/**
	 * 基础受击度
	 * 
	 * @return
	 */
	private float battleBaseStrikeRate() {
		return StaticConfig.get(AppStaticConfigs.BATTLE_BASE_STRIKE_RATE).getAsFloat(0F);
	}

	/**
	 * 受击度变动率
	 * 
	 * @return
	 */
	private float battleStrikeVaryRate() {
		return StaticConfig.get(AppStaticConfigs.BATTLE_STRIKE_VARY_RATE).getAsFloat(0.05F);
	}

	/**
	 * 最大受击度
	 * 
	 * @return
	 */
	private float battleMaxStrikeRate() {
		return StaticConfig.get(AppStaticConfigs.BATTLE_MAX_STRIKE_RATE).getAsFloat(0.1F);
	}

	/**
	 * 施放技能自身消耗气血展示时长
	 * 
	 * @return
	 */
	private float battleSkillHpSpentShowTime() {
		return StaticConfig.get(AppStaticConfigs.BATTLE_SKILL_HP_SPENT_SHOW_TIME).getAsFloat(0.5F);
	}

	public ISpellEffectCalculator spellEffectCalculator() {
		// 如果自身有设置修炼计算器则返回当前设置,否则返回按照BattleUnit的默认设置
		if (this.spellEffectCalculator != null)
			return this.spellEffectCalculator;
		return this.battleUnit.spellEffectCalculator();
	}

	public void setSpellEffectCalculator(ISpellEffectCalculator spellEffectCalculator) {
		this.spellEffectCalculator = spellEffectCalculator;
	}

	/**
	 * 重置属性
	 */
	public void restore() {
		this.battleProperties.setHp(this.maxHp());
		this.battleProperties.setMp(this.maxMp());
		this.sp = this.getMaxSp();
	}

	/**
	 * 体质
	 * 
	 * @return
	 */
	public int constitution() {
		return this.aptitudeProperties == null ? 0 : this.aptitudeProperties.getConstitution();
	}

	/**
	 * 魔力
	 * 
	 * @return
	 */
	public int intelligent() {
		return this.aptitudeProperties == null ? 0 : this.aptitudeProperties.getIntelligent();
	}

	/**
	 * 力量
	 * 
	 * @return
	 */
	public int strength() {
		return this.aptitudeProperties == null ? 0 : this.aptitudeProperties.getStrength();
	}

	/**
	 * 耐力
	 * 
	 * @return
	 */
	public int stamina() {
		return this.aptitudeProperties == null ? 0 : this.aptitudeProperties.getStamina();
	}

	/**
	 * 敏捷
	 * 
	 * @return
	 */
	public int dexterity() {
		return this.aptitudeProperties == null ? 0 : this.aptitudeProperties.getDexterity();
	}

	public BattleSoldierProperties battleBaseProperties() {
		return this.battleProperties;
	}

	/**
	 * 是否鬼魂生物(拥有鬼魂术)
	 * 
	 * @return
	 */
	public boolean isGhost() {
		return isLowGhost() || isHighGhost();
	}

	/**
	 * 低级鬼魂
	 * 
	 * @return
	 */
	public boolean isLowGhost() {
		boolean lowGhost = this.skillHolder().battleSkillHolder().containPassiveSkill(GHOST_SKILL_ID_1);
		return lowGhost && !isHighGhost();
	}

	/**
	 * 高级鬼魂
	 * 
	 * @return
	 */
	public boolean isHighGhost() {
		return this.skillHolder().battleSkillHolder().containPassiveSkill(GHOST_SKILL_ID_2);
	}

	/**
	 * 有神佑技能
	 * 
	 * @return
	 */
	public boolean hasGodHelp() {
		BattleSkillHolder<?> holder = this.skillHolder().battleSkillHolder();
		return holder.containPassiveSkill(GOD_HELP_SKILL_ID_1) || holder.containPassiveSkill(GOD_HELP_SKILL_ID_2) || holder.containPassiveSkill(GOD_HELP_SKILL_ID_3);
	}

	public int getAttackTimes() {
		return attackTimes;
	}

	public void setAttackTimes(int attackTimes) {
		this.attackTimes = attackTimes;
	}

	public int getMagicAttackTimes() {
		return magicAttackTimes;
	}

	public void setMagicAttackTimes(int magicAttackTimes) {
		this.magicAttackTimes = magicAttackTimes;
	}

	public int getBeAttackTimes() {
		return beAttackTimes;
	}

	public void setBeAttackTimes(int beAttackTimes) {
		this.beAttackTimes = beAttackTimes;
	}

	public void addAttackTimes(int times, boolean magic) {
		this.attackTimes += times;
		this.addAttackTypeTimes(magic);
	}

	public void addAttackTypeTimes(boolean magic) {
		if (magic)
			this.magicAttackTimes++;
	}

	public void addBeAttackTimes(int times, boolean magic) {
		this.beAttackTimes += times;
		this.increaseRoundBeAttackTimes(magic);
	}

	public PlayerDressInfo getPlayerDressInfo() {
		return playerDressInfo;
	}

	public void setPlayerDressInfo(PlayerDressInfo playerDressInfo) {
		this.playerDressInfo = playerDressInfo;
	}

	public NpcAppearance getNpcAppearance() {
		return npcAppearance;
	}

	public void setNpcAppearance(NpcAppearance npcAppearance) {
		this.npcAppearance = npcAppearance;
	}

	public RoundContext roundContext() {
		return this.roundContext;
	}

	public BattlePlayer player() {
		if (this.playerId > 0) {
			return battleTeam.player(this.playerId);
		}
		return null;
	}

	/**
	 * 昼夜效果
	 * 
	 * @param originalValue
	 * @return
	 */
	private float dayNightEffect(float originalValue) {
		if (!GameServerManager.getInstance().night())
			return originalValue;
		String skillIdStr = StaticConfig.get(AppStaticConfigs.ANTI_NIGHT_DEBUFF_SKILLS).getValue();
		Set<Integer> skillIds = SplitUtils.split2IntSet(skillIdStr, "\\|");
		for (int skillId : skillIds) {
			if (this.skillHolder().battleSkillHolder().containSkill(skillId))
				return originalValue;
		}

		// 门派特色
		Faction faction = this.faction();
		if (faction != null) {
			FactionBattleLogicParam param = faction.getFactionBattleLogicParam();
			if (param != null) {
				if (param instanceof FactionBattleLogicParam_12 && !this.ifChild()) {
					return originalValue;
				}
			}
		}
		float reduceRate = StaticConfig.get(AppStaticConfigs.NIGHT_DEBUFF_EFFECT).getAsFloat(0.1f);
		float rate = 1 - reduceRate;
		return originalValue * rate;
	}

	/**
	 * 武器攻击
	 * 
	 * @return
	 */
	public int weaponAttack() {
		return this.battleUnit.weaponAttack(this.grade, weaponAttackParams);
	}

	public boolean forceLeaveBattle() {
		return this.forceLeaveBattle;
	}

	public void forceLeaveBattle(boolean forceLeave) {
		this.forceLeaveBattle = forceLeave;
	}

	/**
	 * 治疗无效
	 * 
	 * @return
	 */
	public boolean preventHeal() {
		return preventHeal(Collections.emptySet());
	}

	public boolean preventHeal(Set<Integer> buffTypes) {
		if (this.isLowGhost())
			return true;
		if (this.isDead() && this.buffHolder().hasPreventReliveBuff()) {
			return true;
		} else if (this.buffHolder().hasPreventHealBuff() && !ignorePreventHealBuff(buffTypes)) {
			return true;
		}
		return false;
	}

	/**
	 * 是否能复活
	 * 
	 * @return
	 */
	public boolean canRelive() {
		if (!this.isDead())
			return false;
		if (this.isGhost())
			return false;
		if (this.buffHolder().hasPreventReliveBuff())
			return false;
		return true;
	}

	/**
	 * 是否能使用复活道具
	 * 
	 * @return
	 */
	public boolean canUseReliveProp() {
		if (this.isGhost())
			return false;
		if (this.buffHolder().hasPreventReliveBuff())
			return false;
		return true;
	}

	public void increaseRoundBeAttackTimes(boolean magic) {
		if (magic)
			this.roundBeMagicAttackTimes++;
		else
			this.roundBePhyAttackTimes++;
	}

	public int getRoundBePhyAttackTimes() {
		return roundBePhyAttackTimes;
	}

	public void setRoundBePhyAttackTimes(int roundBePhyAttackTimes) {
		this.roundBePhyAttackTimes = roundBePhyAttackTimes;
	}

	public int getRoundBeMagicAttackTimes() {
		return roundBeMagicAttackTimes;
	}

	public void setRoundBeMagicAttackTimes(int roundBeMagicAttackTimes) {
		this.roundBeMagicAttackTimes = roundBeMagicAttackTimes;
	}

	public void clearRoundBeAttackTimes() {
		this.roundBeMagicAttackTimes = 0;
		this.roundBePhyAttackTimes = 0;
		this.roundLossHp = 0;
		this.firstBeAttacked = true;
	}

	public Map<Integer, Integer> getUsedSkills() {
		return usedSkills;
	}

	public void setUsedSkills(Map<Integer, Integer> usedSkills) {
		this.usedSkills = usedSkills;
	}

	public Map<Integer, Integer> roundPassiveEffects() {
		return this.roundPassiveEffects;
	}

	public int roundPassiveEffectTimeOf(int configId) {
		if (!this.roundPassiveEffects.containsKey(configId))
			return 0;
		return this.roundPassiveEffects.get(configId);
	}

	public void increaseUsedSkillTimes(int skillId) {
		Integer t = this.usedSkills.get(skillId);
		if (t == null)
			t = 0;
		t++;
		this.usedSkills.put(skillId, t);
	}

	public void addRoundPassiveEffectTime(int configId) {
		int t = 1;
		if (this.roundPassiveEffects.containsKey(configId))
			t += this.roundPassiveEffects.get(configId);
		this.roundPassiveEffects.put(configId, t);
	}

	public void clearRoundPsssiveEffect() {
		this.roundPassiveEffects.clear();
	}

	public void addBattleFinishCallback(IPlayerBattleFinishCallback callback) {
		this.battleFinishCallbacks.add(callback);
	}

	public void battleFinishCallbackHandle() {
		try {
			battleFinishCallbackLock.lock();
			for (Iterator<IPlayerBattleFinishCallback> it = this.battleFinishCallbacks.iterator(); it.hasNext();) {
				IPlayerBattleFinishCallback callback = it.next();
				callback.afterBattleFinish();
				it.remove();
			}
		} catch (Exception e) {
			e.printStackTrace();
		} finally {
			battleFinishCallbackLock.unlock();
		}
	}

	public boolean isInBan() {
		return inBan;
	}

	public void setInBan(boolean inBan) {
		this.inBan = inBan;
	}

	public void joinRoundProcessor(DefaultBattleRoundProcessor processor) {
		this.setCurRoundProcessor(processor);
		processor.apply(this);
	}

	public Map<String, Object> getWeaponAttackParams() {
		return weaponAttackParams;
	}

	public void setWeaponAttackParams(Map<String, Object> weaponAttackParams) {
		this.weaponAttackParams = weaponAttackParams;
	}

	/**
	 * 阻止治疗buff无效(即可以治疗)
	 * 
	 * @param buffTypes
	 * @return
	 */
	public boolean ignorePreventHealBuff(Set<Integer> buffTypes) {
		if (buffTypes.isEmpty())
			return false;
		final List<BattleBuffEntity> preventHealBuffs = new ArrayList<>(this.buffHolder().allBuffs().size());
		for (BattleBuffEntity buff : this.buffHolder().allBuffs().values()) {
			BattleBuff bf = buff.battleBuff();
			if (bf.isPreventHeal())
				preventHealBuffs.add(buff);
		}
		for (Iterator<BattleBuffEntity> it = preventHealBuffs.iterator(); it.hasNext();) {
			BattleBuffEntity buff = it.next();
			if (buffTypes.contains(buff.battleBuffType()))
				it.remove();
		}
		return preventHealBuffs.isEmpty();
	}

	/** 伴侣id */
	public long fereId() {
		return this.battleUnit.fereId();
	}

	/**
	 * 是否伴侣
	 * 
	 * @param targetId
	 * @return
	 */
	public boolean ifFere(long targetId) {
		return this.fereId() == targetId;
	}

	/**
	 * 是否是我师傅
	 * 
	 * @param targetId
	 * @return
	 */
	public boolean ifMyMaster(long targetId) {
		return this.battleUnit().ifMyMaster(targetId);
	}

	/** 跟目标的友好度 */
	public int friendlyWith(long targetId) {
		return this.battleUnit.friendlyWith(targetId);
	}

	public IRetreatCallback getRetreatCallback() {
		return retreatCallback;
	}

	public void setRetreatCallback(IRetreatCallback retreatCallback) {
		this.retreatCallback = retreatCallback;
	}

	public void retreatCallbackHandle() {
		if (retreatCallback != null)
			retreatCallback.onRetreat(battleTeam, player());
	}

	public int joinRound() {
		return this.joinRound;
	}

	public void joinRound(int round) {
		this.joinRound = round;
	}

	/** 抗毒 */
	public boolean antiPoison() {
		return this.skillHolder().battleSkillHolder().containPassiveSkill(HIGH_POISON_SKILL);
	}

	/** 最大出战宠物次数 */
	public int maxCallPetCount() {
		int max = StaticConfig.get(AppStaticConfigs.MAX_PET_COUNT).getAsInt(5);
		max += propInt(BattleBasePropertyType.CallPetCount);
		return max;
	}

	/**
	 * 集齐所有吉星被动技能
	 * 
	 * @return
	 */
	public boolean allLuckyPassSkills() {
		return this.skillHolder().battleSkillHolder().allLuckyPassSkills();
	}

	public float propFloat(BattleBasePropertyType propertyType) {
		return this.battleBaseProperties().getFloat(propertyType);
	}

	public int propInt(BattleBasePropertyType propertyType) {
		return this.battleBaseProperties().getInt(propertyType);
	}

	public float spendSpDiscountRate() {
		float spendSpRate = this.skillHolder().passiveSkillPropertyEffect(BattleBasePropertyType.SpendSpDiscountRate);
		if (spendSpRate != 0)
			return spendSpRate;
		return 1F;
	}

	/**
	 * 能否接受使用物品
	 * 
	 * @param itemId
	 * @return
	 */
	public boolean antiItem(int itemId) {
		return this.buffHolder().antiItem(itemId);
	}

	/**
	 * 是否存在指定技能
	 * 
	 * @param skillId
	 * @return
	 */
	public boolean hasSkill(int skillId) {
		return this.skillHolder().battleSkillHolder().containSkill(skillId);
	}

	public int deadSp() {
		return this.deadSp;
	}

	public void clearDeadSp() {
		this.deadSp = 0;
	}

	public int deadRound() {
		return this.deadRound;
	}

	public int roundBeAttackTimes() {
		return this.roundBeMagicAttackTimes + this.roundBePhyAttackTimes;
	}

	public int roundBePhyAttackTimes() {
		return this.roundBePhyAttackTimes;
	}

	public int roundLossHp() {
		return this.roundLossHp;
	}

	public int roundBeMagicAttackTimes() {
		return this.roundBeMagicAttackTimes;
	}

	public int lastRoundBeAttackTimes() {
		return this.lastRoundBeAttackTimes;
	}

	public void setLastRoundBeAttackTimes(int times) {
		this.lastRoundBeAttackTimes = times;
	}

	public boolean isBro(BattleSoldier target) {
		return isMainCharactor() && player().isBro(target.getId());
	}

	public void shout(ShoutConfig.BattleShoutTypeEnum type, CommandContext ctx) {
		if (!(ifPet() || ifCrew() || ifChild()))
			return;
		// 子女喊话，召唤必喊
		if (ifChild() && type == BattleShoutTypeEnum.Summon) {
			this.childShout(type, ctx);
			return;
		}
		if (shoutedTypes.contains(type))
			return;
		ShoutConfig shoutConfig = shoutConfigs.get(type);
		if (shoutConfig == null)
			return;
		double rate = Math.random();
		if (rate <= shoutConfig.getProbability()) {
			// 机率命中
			shoutedTypes.add(type);
			VideoTargetShoutState shoutState = new VideoTargetShoutState(this, type, shoutConfig.getShoutContent());
			if (ctx == null)
				battle().getVideo().addStartState(shoutState);
			else
				currentVideoRound().addShoutState(shoutState);
		}
	}

	public void childShout(ShoutConfig.BattleShoutTypeEnum type, CommandContext ctx) {
		Collection<ShoutConfig> childShoutCollection = childShoutConfigs.values();
		if (CollectionUtils.isEmpty(childShoutCollection))
			return;
		ShoutConfig shoutConfig = RandomUtils.next(childShoutCollection);
		VideoTargetShoutState shoutState = new VideoTargetShoutState(this, type, shoutConfig.getShoutContent());
		if (ctx == null)
			battle().getVideo().addStartState(shoutState);
		else
			currentVideoRound().addShoutState(shoutState);
	}

	public void addShoutConfig(ShoutConfig.BattleShoutTypeEnum type, ShoutConfig shoutConfig) {
		shoutConfigs.put(type, shoutConfig);
	}

	public void addChildShoutConfig(int id, ShoutConfig shoutConfig) {
		childShoutConfigs.put(id, shoutConfig);
	}

	public BattleSoldier myPet() {
		BattlePlayerSoldierInfo info = battleTeam.soldiersByPlayer(playerId);
		if (info != null) {
			BattleSoldier pet = battleTeam.battleSoldier(info.petSoldierId());
			return pet;
		}
		return null;
	}

	public void beforeStart() {
		shout(ShoutConfig.BattleShoutTypeEnum.BattleBegin, null);
	}

	public int getMagicEquipmentMana() {
		return magicEquipmentMana;
	}

	public void setMagicEquipmentMana(int magicEquipmentMana) {
		this.magicEquipmentMana = magicEquipmentMana;
	}

	/**
	 * 增加法宝法力，回合结束+1
	 */
	public int increateMagicEquipmentMana() {
		int addValue = 0;
		if (isMainCharactor() && magicEquipmentMana < this.battle().maxMagicEquipPower()) {
			addValue = this.battle().roundAddMagicEquipPower();
			this.magicEquipmentMana += addValue;
		}
		return addValue;
	}

	public void decreateMagicEquipmentMana(int count) {
		if (count > 0)
			return;
		this.magicEquipmentMana += count;
		if (this.magicEquipmentMana < 0)
			this.magicEquipmentMana = 0;
	}

	public float playerBuffEffect(BattleBasePropertyType properType) {
		BattlePlayer player = this.player();
		if (player == null)
			return 0;
		float v = 0;
		for (PlayerStateBarInfo info : player.persistPlayer().stateBarMap().values()) {
			v += info.propertyEffectOf(this, properType);
		}
		return v;
	}

	public void roundDamageInput(int damage) {
		this.roundContext().addDamageInput(this.id, damage);
	}

	public int roundDamageInput() {
		return this.roundContext().damageInputOf(this.id);
	}

	public Skill factionDefaultSkill() {
		Faction f = this.faction();
		if (f == null)
			return null;
		return Skill.get(f.getDefaultSkillId());
	}

	public int getRoundLossHp() {
		return roundLossHp;
	}

	public void setRoundLossHp(int roundLossHp) {
		this.roundLossHp = roundLossHp;
	}
}
