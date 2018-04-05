/**
 * 
 */
package com.nucleus.logic.core.modules.battle.data;

import java.beans.Transient;
import java.util.ArrayList;
import java.util.Collections;
import java.util.HashMap;
import java.util.HashSet;
import java.util.Iterator;
import java.util.LinkedHashSet;
import java.util.List;
import java.util.Map;
import java.util.Map.Entry;
import java.util.Set;

import org.apache.commons.collections.CollectionUtils;
import org.apache.commons.lang3.StringUtils;
import org.apache.commons.lang3.builder.ReflectionToStringBuilder;
import org.apache.commons.lang3.builder.ToStringStyle;

import com.nucleus.commons.data.DataId;
import com.nucleus.commons.data.StaticConfig;
import com.nucleus.commons.data.StaticDataManager;
import com.nucleus.commons.message.BroadcastMessage;
import com.nucleus.commons.utils.ExcelUtils;
import com.nucleus.commons.utils.RandomUtils;
import com.nucleus.commons.utils.SplitUtils;
import com.nucleus.logic.core.modules.AppSkillActionStatusCode;
import com.nucleus.logic.core.modules.AppStaticConfigs;
import com.nucleus.logic.core.modules.battle.BattleUtils;
import com.nucleus.logic.core.modules.battle.dto.VideoSkillAction;
import com.nucleus.logic.core.modules.battle.logic.ITargetSelectLogic;
import com.nucleus.logic.core.modules.battle.logic.SkillAiLogic;
import com.nucleus.logic.core.modules.battle.logic.SkillLogic;
import com.nucleus.logic.core.modules.battle.logic.SkillTargetInfo;
import com.nucleus.logic.core.modules.battle.logic.SkillTargetInfoList;
import com.nucleus.logic.core.modules.battle.logic.TargetSelectLogicParam;
import com.nucleus.logic.core.modules.battle.manager.SkillLogicManager;
import com.nucleus.logic.core.modules.battle.manager.TargetSelectLogicManager;
import com.nucleus.logic.core.modules.battle.model.BattleSoldier;
import com.nucleus.logic.core.modules.battle.model.CommandContext;
import com.nucleus.logic.core.modules.charactor.data.GeneralCharactor.CharactorType;
import com.nucleus.logic.core.modules.constants.CommonEnums.BattleCommandType;
import com.nucleus.player.service.ScriptService;

/**
 * 技能
 * 
 * @author liguo
 * 
 */
public class Skill implements BroadcastMessage {
	public static final int SPECIAL_SKILL_ID = 1812;// 特殊技能：觉醒
	public static final int SPECIAL_SKILL_ID_BACKUP = 1817;// 觉醒技能因为没有目标而无法施放的时候，转而使用替代技能

	public static Skill get(int id) {
		return StaticDataManager.getInstance().get(Skill.class, id);
	}

	/**
	 * 普攻
	 * 
	 * @return
	 */
	public static Skill defaultActiveSkill() {
		return Skill.get(defaultActiveSkillId());
	}

	public static int defaultActiveSkillId() {
		return StaticConfig.get(AppStaticConfigs.DEFAULT_ACTIVE_SKILL_ID).getAsInt(1);
	}

	/**
	 * 抓捕
	 * 
	 * @return
	 */
	public static Skill captureSkill() {
		int skillId = StaticConfig.get(AppStaticConfigs.DEFAULT_CAPTURE_SKILL_ID).getAsInt(5);
		return Skill.get(skillId);
	}

	/**
	 * 防御
	 * 
	 * @return
	 */
	public static Skill defenseSkill() {
		return Skill.get(defenseSkillId());
	}

	public static int defenseSkillId() {
		int skillId = StaticConfig.get(AppStaticConfigs.DEFAULT_DEFENSE_SKILL_ID).getAsInt(2);
		return skillId;
	}

	/**
	 * 召唤
	 * 
	 * @return
	 */
	public static Skill summonSkill() {
		int skillId = StaticConfig.get(AppStaticConfigs.DEFAULT_SUMMON_SKILL_ID).getAsInt(4);
		return Skill.get(skillId);
	}

	public static int useItemSkillId() {
		return StaticConfig.get(AppStaticConfigs.USE_ITEM_SKILL_ID).getAsInt(7);
	}

	/**
	 * 使用物品
	 * 
	 * @return
	 */
	public static Skill useItemSkill() {
		return Skill.get(useItemSkillId());
	}

	public static int retreatSkillId() {
		return StaticConfig.get(AppStaticConfigs.DEFAULT_RETREAT_SKILL_ID).getAsInt(6);
	}

	/**
	 * 撤退
	 * 
	 * @return
	 */
	public static Skill retreatSkill() {
		return Skill.get(retreatSkillId());
	}

	public static int defaultProtectSkillId() {
		return StaticConfig.get(AppStaticConfigs.DEFAULT_PROTECT_SKILL_ID).getAsInt(3);
	}

	/**
	 * 保护
	 * 
	 * @return
	 */
	public static Skill defaultProtectSkill() {
		return Skill.get(defaultProtectSkillId());
	}

	/**
	 * 盘丝门派特色被动技能ID
	 * 
	 * @return
	 */
	public static int psFactionEffectPassiveSkill() {
		return StaticConfig.get(AppStaticConfigs.PS_FACTION_PASSIVE_SKILL_ID).getAsInt(0);
	}

	public int beforeFire(BattleSoldier trigger, VideoSkillAction action) {
		BattleCommandType curBattleCommandType = battleCommandType();
		CommandContext context = trigger.getCommandContext();
		int state = trigger.buffHolder().buffBanState(curBattleCommandType);
		if (state != 0 && !context.isStrokeBack())// 反击状态下可以突破buff封禁限制
			return state;
		trigger.buffHolder().buffEffectBeforeAttack(context);
		if (!canFindTarget(trigger, context))
			return AppSkillActionStatusCode.CannotFindTarget;

		if (!this.buffRequired.isEmpty()) {
			boolean buffExist = true;
			int statusCode = 0;
			for (Iterator<Entry<Integer, Integer>> it = this.buffRequired.entrySet().iterator(); it.hasNext();) {
				Entry<Integer, Integer> entry = it.next();
				int buffId = entry.getKey();
				if (!trigger.buffHolder().hasBuff(buffId)) {
					buffExist = false;
					statusCode = entry.getValue();
					break;
				}
			}
			if (!buffExist) {
				if (statusCode > 0)
					return statusCode;
				return AppSkillActionStatusCode.NeedTransform;
			}
		}
		if (context.isStrokeBack()) // 反击不消耗mp/hp
			return 0;
		BattleSoldier target = context.target();
		if (target != null && this.id != Skill.useItemSkillId()) {
			if (this.isDeadTriggerSkill() && this.ifHpIncreaseFunction()) {
				if (target.isDead()) {
					if ((target.isGhost() && !context.isEffectGhost()) || target.buffHolder().hasPreventReliveBuff())
						return AppSkillActionStatusCode.CannotReliveTarget;
				} else {
					if (target.preventHeal() && this.targetRemoveBuffTypes().isEmpty())
						return AppSkillActionStatusCode.CannotHealTarget;
				}
			} else {
				// 有的被动会影响能否治疗鬼魂，所以在此处触发该被动
				trigger.skillHolder().passiveSkillEffectByTiming(target, context, PassiveSkillLaunchTimingEnum.AfterSeleFirstTarget);
				if (!this.isUseAliveTarget()) {// 复活技能
					if (!target.isDead()) {
						return AppSkillActionStatusCode.ForDeadTarget;
					} else if ((target.isGhost() && !context.isEffectGhost()) || target.buffHolder().hasPreventReliveBuff()) {
						return AppSkillActionStatusCode.CannotReliveTarget;
					}
				} else if (this.ifHpIncreaseFunction()) {// +hp
					if (target.preventHeal() && this.targetRemoveBuffTypes().isEmpty())
						return AppSkillActionStatusCode.CannotHealTarget;
				}
			}
		}
		int[] arr = calcSpends(trigger, context);
		int minFireHp = arr[0];
		int maxFireHp = arr[1];
		int mpSpent = arr[2];
		if (minFireHp > 0 && trigger.hp() < minFireHp) {
			return AppSkillActionStatusCode.SkillApplyHpNotEnough;
		}
		if (maxFireHp > 0 && trigger.hp() > maxFireHp) {
			return AppSkillActionStatusCode.SkillApplyHpExceeded;
		}
		if (context.isCombo() && this.ifMagicAttack()) {
			mpSpent = 0;// 法术连击不扣mp
		}
		if (mpSpent < 0) {
			mpSpent = context.battle().mpSpent(context, trigger, mpSpent);
		}
		if (trigger.mp() < Math.abs(mpSpent)) {
			return AppSkillActionStatusCode.SkillApplyMpNotEnough;
		}
		int spSpent = (int) BattleUtils.valueWithSoldierSkill(trigger, this.spendSpFormula, this);
		if (spSpent < 0) {
			float spendSpDiscountRate = trigger.spendSpDiscountRate();
			spSpent *= spendSpDiscountRate;
			context.setSpSpent(spSpent);
			// trigger.skillHolder().passiveSkillEffectByTiming(context.target(), context, PassiveSkillLaunchTimingEnum.SpConsume);
			// spSpent = context.getSpSpent();
		}
		// 子女使用技能不需要消耗怒气值
		if (trigger.charactorType() == CharactorType.Child.ordinal())
			spSpent = 0;
		if (trigger.getSp() < Math.abs(spSpent))
			return AppSkillActionStatusCode.SkillApplySpNotEnough;
		if (target != null && this.friendly > 0 && trigger.friendlyWith(target.getId()) < this.friendly)
			return AppSkillActionStatusCode.FRIENDLY_NOT_ENOUGH;
		trigger.decreaseMp(mpSpent);
		trigger.decreaseSp(spSpent);
		action.setMpSpent(mpSpent);
		action.setSpSpent(spSpent);
		return 0;
	}

	public void afterFired(BattleSoldier trigger, VideoSkillAction action) {
	}

	private int[] calcSpends(BattleSoldier trigger, CommandContext context) {
		int minFireHp = (int) BattleUtils.valueWithSoldierSkill(trigger, this.getApplyHpLimitFormula(), this);
		int maxFireHp = (int) BattleUtils.valueWithSoldierSkill(trigger, this.getApplyHpMaxLimitFormula(), this);
		int mpSpent = (int) BattleUtils.valueWithSoldierSkill(trigger, this.getSpendMpFormula(), this);
		int oldMpSpend = context.getMpSpent();
		context.setMinFireHp(minFireHp);
		context.setMaxFireHp(maxFireHp);
		context.setMpSpent(mpSpent + oldMpSpend);
		trigger.skillHolder().passiveSkillEffectByTiming(context.target(), context, PassiveSkillLaunchTimingEnum.BeforeSkill);
		minFireHp = context.getMinFireHp();
		maxFireHp = context.getMaxFireHp();
		mpSpent = context.getMpSpent();
		return new int[] { minFireHp, maxFireHp, mpSpent };
	}

	/**
	 * 判断有无可攻击目标(非隐身),如果无则不出手
	 * 
	 * @param trigger
	 * @param context
	 * @return
	 */
	protected boolean canFindTarget(BattleSoldier trigger, CommandContext context) {
		if (!this.ifHpLossFunction() || this.isCanApplyToHiddenTarget())
			return true;
		SkillAiLogic logic = context.skill().skillAi().skillAiLogic();
		Map<Long, BattleSoldier> targets = logic.availableTargets(context);
		if (targets == null || targets.isEmpty())
			return false;
		List<BattleSoldier> hiddenSoldiers = new ArrayList<>();
		for (BattleSoldier target : targets.values()) {
			if (!this.isDeadTriggerSkill()) {
				if (this.isUseAliveTarget() == target.isDead())
					continue;
			}
			if (!target.buffHolder().isHidden())
				return true;
			else
				hiddenSoldiers.add(target);
		}
		for (BattleSoldier soldier : hiddenSoldiers) {
			trigger.skillHolder().passiveSkillEffectByTiming(soldier, context, PassiveSkillLaunchTimingEnum.SelectTarget);
			if (context.isHiddenFail())
				return true;
		}
		return false;
	}

	public void fired(CommandContext commandContext) {
		SkillLogic skillLogic = SkillLogicManager.getInstance().getLogic(logicId);
		if (skillLogic == null)
			return;
		skillLogic.fired(commandContext);
	}

	/** 技能适用战斗类型 */
	public enum BattleType {
		/** 通用 */
		All,
		/** 适用pve */
		PVE,
		/** 适用pvp */
		PVP
	}

	public enum UserTargetScopeType {
		/** 未知 */
		Unknown,
		/** 敌方 */
		Enemy,
		/** 仅自身 */
		Self,
		/** 己方除自身外的单位，包括己方全部人的宠物 */
		FriendsExceptSelfWithPet,
		/** 己方所有单位，包括己方全部人的宠物 */
		FriendsWithPet,
		/** 仅己方全部宠物 */
		FriendPets,
		/** 场上除自身外所有单位 */
		ExceptSelf,
		/** 身上宠物 */
		PetsInBag,
		/** 伴侣 */
		Fere,
		/** 9 仅敌方玩家 */
		EnemyPlayer,
		/** 10仅己方玩家 */
		MyTeamPlayer,
		/** 11 仅敌方全部宠物 */
		EnemyPets
	}

	public enum SkillActionTypeEnum {
		UnKnow, Attack, Seal, Support, Heal
	}

	public enum SkillActionStatus {
		/** 正常 */
		Ordinary,
		/** 生命值不足无法施放技能 */
		SkillApplyHpNotEnough,
		/** 生命值过多无法施放技能 */
		SkillApplyHpExceeded,
		/** 法力值不足无法施放技能 */
		SkillApplyMpNotEnough,
		/** 行动被封印 */
		ActionBanned,
		/** 防御 */
		Defense,
		/** 不能捕捉宠物 */
		CatchPetFailure,
		/** 队伍已满 */
		TeamFull,
		/** 最多只能召唤1个怪物 */
		NoMoreMonsterCall,
		/** 需要变身才能使用 */
		NeedTransform,
		/** 封印但不提示 */
		ActionBannedWithoutTips,
		/** 怒气值不足无法施放技能 */
		SkillApplySpNotEnough,
		/** 每只宠物只能召唤一次 */
		CallPetOnlyOnce,
		/** 最多允许5个宠物参战 */
		OutOffCallPetCount,
		/** 只能对倒地的目标使用 */
		ForDeadTarget,
		/** 不能对倒地的目标使用 */
		ForLiveTarget,
		/** 所使用物品不存在 */
		UserItemNotFound,
		/** 技能被免疫 */
		AntiSkill,
		/** 等级不够无法捕捉 */
		CatchPetLevelNotSuit,
		/** 携带的宠物已达上限 */
		CarryPetFull,
	}

	public enum SkillMagicType {
		/** 未知 */
		Unknown,
		/** 水 */
		Water,
		/** 雷 */
		Thunder,
		/** 火 */
		Fire,
		/** 土 */
		Earth,
		/** 风 */
		Wind
	}

	public enum SkillType {
		Normal,
		/** 负面法术 */
		Negative
	}

	public enum SkillAttackType {
		Default,
		/** 物理系法术 */
		Phy,
		/** 魔法系法术 */
		Magic,
	}

	public enum RelationTypeEnum {
		Normal,
		/** 夫妻法术 */
		Couple,
	}

	public enum ClientSkillType {
		/**
		 * "1 普攻 2 远单 3 远群 4 远单飞 5 远群飞 6 近单 7 近群 8 己单 9 己群 10捕捉"
		 */
		/** 无 */
		Null,
		/** 普攻 */
		NormalAttack,
		/** 2 远单 */
		LongSingle,
		/** 3 远群 */
		LongGroup,
		/** 4 远单飞 */
		LongSingleFly,
		/** 5 远群飞 */
		LongGroupFly,
		/** 6 近单 */
		ShortSingle,
		/** 7 近群 */
		ShortGroup,
		/** 8 己单 */
		SelfSingle,
		/** 9 己群 */
		SelfGroup,
		/** 10 捕捉 */
		Catch;
	}

	/** 技能编号 */
	private int id;

	/** 动作准备播放时长(秒) */
	private float actionReadyPlaySec;

	/** 单次动作播放时长(秒) */
	private float singleActionPlaySec;

	/** 动作结束播放时长(秒) */
	private float actionEndPlaySec;

	/** 技能名称 */
	private String name;

	/** 技能图标 */
	private String icon;

	/** 技能描述 */
	private String description;

	/** 技能简短描述 */
	private String shortDescription;
	/** 伙伴技能描述 */
	private String crewDescription;
	/** 技能评分 */
	private int ranking;

	/** 技能速度加成 */
	private String extraSpeedFormula;
	/** 技能暴击率加成 */
	private String extraCritRateFormula;

	/** 是否播放一次 */
	private boolean atOnce;

	/** 特效类型 */
	private int clientEffectType;

	/** 施放特效位置 */
	private int clientFireEffectPosition;

	/** 受击特效位置 */
	private int clientHitEffectPosition;

	/** 受击特效范围 */
	private int clientHitEffectScope;

	/** 技能类别 */
	private int clientSkillType;

	/** 是否可被反击 */
	private boolean strikebackable;

	/** 特效缩放万分比 */
	private int clientSkillScale;

	/** 是否主动技能 */
	private boolean activeSkill;

	/** 门派技能编号 */
	private int factionSkillId;

	/** 逻辑编号 */
	private int logicId;
	/** 战斗指令类型 */
	private int battleCommandType;
	@DataId(SkillAi.class)
	/** 技能ai编号 */
	private int skillAiId;
	/**
	 * 具体每个目标的选择逻辑,比如回血技能会优选选择血量少的目标
	 */
	private int targetSelectLogicId;
	private TargetSelectLogicParam selectLogicParam;
	/** 技能命中率公式 */
	private String hitRate;

	/** 使用生命限制公式 */
	private String applyHpLimitFormula;

	/** 使用生命上限公式 */
	private String applyHpMaxLimitFormula;

	/** 自身消耗气血公式 */
	private String spendHpFormula;

	/** 自身消耗法力公式 */
	private String spendMpFormula;

	/** 需要闪避 */
	private boolean needDodge;

	/** 需要暴击 */
	private boolean needCrit;

	/** 自身下回合强制技能编号 */
	private int selfNextRoundForceSkillId;

	/** 是否运用群伤规则 */
	private boolean useSkillMassRule;

	/** 目标是否存活 */
	private boolean useAliveTarget;

	/** 法术系别 */
	private int skillMagicType;

	/** 作用目标列表 */
	private List<SkillTargetInfo> skillTargetInfos = new ArrayList<SkillTargetInfo>();

	/** 作用目标列表Map - key:目标顺序 */
	private Map<Integer, SkillTargetInfo> skillTargetInfosMap = new HashMap<Integer, SkillTargetInfo>();

	/** 多段攻击作用目标列表 */
	private List<SkillTargetInfoList> comboTargetInfoList = new ArrayList<>();

	/** 目标战斗buff编号列表 */
	private Set<Integer> targetBattleBuffIds = new HashSet<Integer>();
	/** 目标随机buff编号(权重，buff编号集) */
	private Map<Integer, Integer> targetRandomBuffMap = new HashMap<>();
	/** 手动选择目标额外附加buff */
	private Set<Integer> mainTargetPlusBuffs = new HashSet<>();

	/** 我方战斗buff编号列表 */
	private Set<Integer> selfBattleBuffIds = new HashSet<Integer>();

	/** 是否hp减益 */
	private boolean ifHpLossFunction = false;
	/** +hp */
	private boolean hpIncreaseFunction;
	/** 正/负面法术 */
	private int skillType;
	/** 物理系/魔法系 */
	private int skillAttackType;
	/**
	 * 施放成功机率公式
	 */
	private String successRateFormula;
	/**
	 * 使用成功目标hp效果公式
	 */
	private String targetSuccessHpEffect;
	/** 使用失败目标hp效果公式 */
	private String targetFailureHpEffect;
	/** 使用成功目标mp效果公式 */
	private String targetSuccessMpEffect;
	/** 使用失败目标mp效果公式 */
	private String targetFailureMpEffect;
	/** 使用成功目标sp效果 */
	private String targetSuccessSpEffect;
	/** 失败目标sp效果 */
	private String targetFailureSpEffect;
	/**
	 * 目标额外hp效果
	 */
	private String targetPlusHpEffect;
	/**
	 * 非boss伤害加成
	 */
	private float damagePlusRate;

	/**
	 * 夜间伤害变化
	 */
	private float nightDamageVaryRate;
	/**
	 * 自身消耗特技值公式
	 */
	private String spendSpFormula;
	/**
	 * 使用成功自身hp效果公式
	 */
	private String selfSuccessHpEffectFormula;
	/**
	 * 使用成功自身mp效果公式*
	 */
	private String selfSuccessMpEffectFormula;
	/**
	 * 使用成功己方队伍hp效果公式（只限主人或伙伴）
	 */
	private String teamSuccessHpEffectFormula;
	/**
	 * 使用成功己方队伍mp效果公式（只限主人或伙伴）
	 */
	private String teamSuccessMpEffectFormula;
	/**
	 * 技能使用cd(回合)
	 */
	private int cd;
	/**
	 * 施放需拥有buff,没有时返回的错误码
	 */
	private Map<Integer, Integer> buffRequired = new HashMap<Integer, Integer>();
	/**
	 * 是否可用于隐藏目标
	 */
	private boolean canApplyToHiddenTarget;
	/**
	 * 移除目标buff, key=buffId, value=移除机率
	 */
	private Map<Integer, Float> targetRemoveBuffs;
	/** 移除目标某些类型的buff */
	private Set<Integer> targetRemoveBuffTypes;
	/**
	 * 施放技能后自身可能移除buff
	 */
	private Map<Integer, Float> selfRemoveBuffs;
	/**
	 * 召唤怪物编号
	 */
	private int callMonsterId;
	/**
	 * 召唤小怪数量
	 */
	private int callMonsterCount;
	/** 最大召唤数量 */
	private int maxCall;
	/**
	 * 吸血转化率
	 */
	private float suckHpRate;
	/**
	 * 吸魔转化率
	 */
	private float suckMpRate;
	/** 技能适用于战斗类型 */
	private int battleType;
	/** 攻/封/辅/疗 */
	private int skillActionType;
	/** 忽略修炼影响 */
	private boolean ignoreSpellEffect;
	/** 关系类型：夫妻法术限夫妻间使用 */
	private int relationType;
	/** 友好度需求 */
	private int friendly;
	/** 死亡仍会触发buff */
	private boolean deadTriggerBuff;
	/** 死亡仍会触发技能 */
	private boolean deadTriggerSkill;
	/** 首目标必中 */
	private boolean mustFirstTarget;
	/** 是否不可防御 */
	private boolean cannotDefense;
	/** 是否不可保护 */
	private boolean cannotProtect;
	/** 禁止保命 */
	private boolean banLife;
	/** 逻辑参数 */
	private String logicParam;
	/** 按概率移除敌方某种类型的一个buff */
	private Map<Integer, Float> targetRemoveOneBuffByType;
	/** 关联技能编号，有时候被动技能触发了某个主动技能，但计算效果的时候需要取被动的等级 */
	private int relativeSkillId;

	public BattleCommandType battleCommandType() {
		return BattleCommandType.values()[this.battleCommandType];
	}

	public boolean ifHpLossFunction() {
		return ifHpLossFunction;
	}

	public boolean ifHpIncreaseFunction() {
		return this.hpIncreaseFunction;
	}

	public String getLogicParam() {
		return logicParam;
	}

	public int getRelativeSkillId() {
		return relativeSkillId;
	}

	public void setRelativeSkillId(int relativeSkillId) {
		this.relativeSkillId = relativeSkillId;
	}

	public void setLogicParam(String logicParam) {
		this.logicParam = logicParam;
	}

	public boolean ifHealFunction() {
		if (useAliveTarget && this.hpIncreaseFunction) {
			return true;
		}
		return false;
	}

	public boolean ifReliveFunction() {
		return (!this.useAliveTarget || deadTriggerSkill) && this.hpIncreaseFunction;
	}

	public boolean ifMagicAttack() {
		return this.skillAttackType == SkillAttackType.Magic.ordinal();
	}

	public boolean ifPhyAttack() {
		return this.skillAttackType == SkillAttackType.Phy.ordinal();
	}

	public boolean skillDefensable() {
		return this.skillAttackType == SkillAttackType.Phy.ordinal();
	}

	public boolean ifMagicSkill() {
		return this.skillMagicType != SkillMagicType.Unknown.ordinal();
	}

	public List<SkillTargetInfo> skillTargetInfos() {
		return skillTargetInfos;
	}

	public Map<Integer, SkillTargetInfo> skillTargetInfosMap() {
		return skillTargetInfosMap;
	}

	public List<SkillTargetInfoList> comboTargetInfoList() {
		return comboTargetInfoList;
	}

	public Set<Integer> targetBattleBuffIds() {
		Set<Integer> targetBattleBuffIds = new LinkedHashSet<>(this.targetBattleBuffIds);
		int randomBuffId = targetRandomBuffId();
		if (randomBuffId > 0)
			targetBattleBuffIds.add(randomBuffId);
		return targetBattleBuffIds;
	}

	public int targetRandomBuffId() {
		int buffId = 0;
		if (this.targetRandomBuffMap.isEmpty())
			return buffId;
		int randomVal = RandomUtils.nextInt(RandomUtils.BASE);
		int curVal = 0;
		for (Entry<Integer, Integer> entry : this.targetRandomBuffMap.entrySet()) {
			curVal += entry.getValue();
			if (curVal >= randomVal)
				return entry.getKey();
		}
		return buffId;
	}

	public Set<Integer> mainTargetPlusBuffs() {
		return this.mainTargetPlusBuffs;
	}

	public Set<Integer> selfBattleBuffIds() {
		return selfBattleBuffIds;
	}

	public int getId() {
		return id;
	}

	public void setId(int id) {
		this.id = id;
	}

	public String getName() {
		return name;
	}

	public void setName(String name) {
		this.name = name;
	}

	public int getSkillAiId() {
		return skillAiId;
	}

	public void setSkillAiId(int skillAiId) {
		this.skillAiId = skillAiId;
	}

	public String getIcon() {
		return icon;
	}

	public void setIcon(String icon) {
		this.icon = ExcelUtils.removeFloat(icon);
	}

	public String getDescription() {
		return description;
	}

	public void setDescription(String description) {
		this.description = description;
	}

	public int getClientEffectType() {
		return clientEffectType;
	}

	public void setClientEffectType(int clientEffectType) {
		this.clientEffectType = clientEffectType;
	}

	public int getClientFireEffectPosition() {
		return clientFireEffectPosition;
	}

	public void setClientFireEffectPosition(int clientFireEffectPosition) {
		this.clientFireEffectPosition = clientFireEffectPosition;
	}

	public int getClientHitEffectPosition() {
		return clientHitEffectPosition;
	}

	public void setClientHitEffectPosition(int clientHitEffectPosition) {
		this.clientHitEffectPosition = clientHitEffectPosition;
	}

	public int getClientHitEffectScope() {
		return clientHitEffectScope;
	}

	public void setClientHitEffectScope(int clientHitEffectScope) {
		this.clientHitEffectScope = clientHitEffectScope;
	}

	public int getClientSkillType() {
		return clientSkillType;
	}

	public void setClientSkillType(int clientSkillType) {
		this.clientSkillType = clientSkillType;
	}

	public int getLogicId() {
		return logicId;
	}

	public void setLogicId(int logicId) {
		this.logicId = logicId;
	}

	public boolean isNeedDodge() {
		return needDodge;
	}

	public void setNeedDodge(boolean needDodge) {
		this.needDodge = needDodge;
	}

	public boolean isNeedCrit() {
		return needCrit;
	}

	public void setNeedCrit(boolean needCrit) {
		this.needCrit = needCrit;
	}

	public SkillAi skillAi() {
		return SkillAi.get(skillAiId);
	}

	public int getClientSkillScale() {
		return clientSkillScale;
	}

	public void setClientSkillScale(int clientSkillScale) {
		this.clientSkillScale = clientSkillScale;
	}

	public boolean isActiveSkill() {
		return activeSkill;
	}

	public void setActiveSkill(boolean activeSkill) {
		this.activeSkill = activeSkill;
	}

	@Transient
	public void setTargetBattleBuffIdsStr(String targetBattleBuffIdsStr) {
		this.targetBattleBuffIds = SplitUtils.split2IntSet(targetBattleBuffIdsStr, ",");
	}

	@Transient
	public void setTargetRandomBuffStr(String targetRandomBuffStr) {
		if (StringUtils.isBlank(targetRandomBuffStr))
			return;
		this.targetRandomBuffMap = SplitUtils.split2IntMap(targetRandomBuffStr, ",", ":");
	}

	@Transient
	public void setMainTargetPlusBuffStr(String mainTargetPlusBuffStr) {
		this.mainTargetPlusBuffs = SplitUtils.split2IntSet(mainTargetPlusBuffStr, ",");
	}

	@Transient
	public void setSelfBattleBuffIdsStr(String selfBattleBuffIdsStr) {
		this.selfBattleBuffIds = SplitUtils.split2IntSet(selfBattleBuffIdsStr, ",");
	}

	public float getSingleActionPlaySec() {
		return singleActionPlaySec;
	}

	public void setSingleActionPlaySec(float singleActionPlaySec) {
		this.singleActionPlaySec = singleActionPlaySec;
	}

	public int getFactionSkillId() {
		return factionSkillId;
	}

	public void setFactionSkillId(int factionSkillId) {
		this.factionSkillId = factionSkillId;
	}

	public String getHitRate() {
		return hitRate;
	}

	public void setHitRate(String hitRate) {
		this.hitRate = hitRate;
	}

	public float gainHitRate(int skillLevel) {
		if (StringUtils.isBlank(this.hitRate))
			return 0f;
		Map<String, Object> params = new HashMap<String, Object>();
		params.put("skillLevel", skillLevel);
		float v = ScriptService.getInstance().calcuFloat("Skill.gainHitRate", this.hitRate, params, false);
		return v;
	}

	public String getApplyHpLimitFormula() {
		return applyHpLimitFormula;
	}

	public void setApplyHpLimitFormula(String applyHpLimitFormula) {
		this.applyHpLimitFormula = applyHpLimitFormula;
	}

	public String getSpendHpFormula() {
		return spendHpFormula;
	}

	public void setSpendHpFormula(String spendHpFormula) {
		this.spendHpFormula = spendHpFormula;
	}

	public String getSpendMpFormula() {
		return spendMpFormula;
	}

	public void setSpendMpFormula(String spendMpFormula) {
		this.spendMpFormula = spendMpFormula;
	}

	@Transient
	public void setTargetFormula(String targetFormula) {
		if (StringUtils.isBlank(targetFormula)) {
			return;
		}

		String[] targetInfosStrArr = targetFormula.split(",");
		for (int i = 0; i < targetInfosStrArr.length; i++) {
			String[] targetInfoStrArr = targetInfosStrArr[i].split(":");
			int targetNum = Integer.parseInt(targetInfoStrArr[0]);
			SkillTargetInfo skillTargetInfo = new SkillTargetInfo();
			skillTargetInfo.setTargetNum(targetNum);
			skillTargetInfo.setSkillPreqLevel(Integer.parseInt(targetInfoStrArr[1]));
			skillTargetInfo.setAttackVaryRate(Float.parseFloat(targetInfoStrArr[2]));
			skillTargetInfo.setDamageVaryRate(Float.parseFloat(targetInfoStrArr[3]));
			skillTargetInfos.add(skillTargetInfo);
			skillTargetInfosMap.put(targetNum, skillTargetInfo);
		}
	}

	@Transient
	public void setComboFormula(String comboFormula) {
		if (StringUtils.isBlank(comboFormula))
			return;
		String[] comboInfoStrArr = SplitUtils.split2StringArray(comboFormula, "\\|");
		for (int i = 0; i < comboInfoStrArr.length; i++) {
			SkillTargetInfoList skillTargetInfoList = new SkillTargetInfoList();
			String[] comboInfoStrArr2 = SplitUtils.split2StringArray(comboInfoStrArr[i], ",");
			for (int j = 0; j < comboInfoStrArr2.length; j++) {
				String[] comboInfoStrArr3 = SplitUtils.split2StringArray(comboInfoStrArr2[j], ":");
				SkillTargetInfo skillTargetInfo = new SkillTargetInfo();
				skillTargetInfo.setTargetNum(Integer.parseInt(comboInfoStrArr3[0]));
				skillTargetInfo.setSkillPreqLevel(Integer.parseInt(comboInfoStrArr3[1]));
				skillTargetInfo.setAttackVaryRate(Float.parseFloat(comboInfoStrArr3[2]));
				skillTargetInfo.setDamageVaryRate(Float.parseFloat(comboInfoStrArr3[3]));
				skillTargetInfoList.addSkillTargetInfo(skillTargetInfo);
			}
			this.comboTargetInfoList.add(skillTargetInfoList);
		}
	}

	public boolean isAtOnce() {
		return atOnce;
	}

	public void setAtOnce(boolean atOnce) {
		this.atOnce = atOnce;
	}

	public String getShortDescription() {
		return shortDescription;
	}

	public void setShortDescription(String shortDescription) {
		this.shortDescription = shortDescription;
	}

	public String getExtraSpeedFormula() {
		return extraSpeedFormula;
	}

	public void setExtraSpeedFormula(String extraSpeedFormula) {
		this.extraSpeedFormula = extraSpeedFormula;
	}

	public String getApplyHpMaxLimitFormula() {
		return applyHpMaxLimitFormula;
	}

	public void setApplyHpMaxLimitFormula(String applyHpMaxLimitFormula) {
		this.applyHpMaxLimitFormula = applyHpMaxLimitFormula;
	}

	public int getSelfNextRoundForceSkillId() {
		return selfNextRoundForceSkillId;
	}

	public void setSelfNextRoundForceSkillId(int selfNextRoundForceSkillId) {
		this.selfNextRoundForceSkillId = selfNextRoundForceSkillId;
	}

	public boolean isUseSkillMassRule() {
		return useSkillMassRule;
	}

	public void setUseSkillMassRule(boolean useSkillMassRule) {
		this.useSkillMassRule = useSkillMassRule;
	}

	public boolean isUseAliveTarget() {
		return useAliveTarget;
	}

	public void setUseAliveTarget(boolean useAliveTarget) {
		this.useAliveTarget = useAliveTarget;
	}

	public boolean isStrikebackable() {
		return strikebackable;
	}

	public void setStrikebackable(boolean strikebackable) {
		this.strikebackable = strikebackable;
	}

	public int getSkillMagicType() {
		return skillMagicType;
	}

	public void setSkillMagicType(int skillMagicType) {
		this.skillMagicType = skillMagicType;
	}

	public float getActionReadyPlaySec() {
		return actionReadyPlaySec;
	}

	public void setActionReadyPlaySec(float actionReadyPlaySec) {
		this.actionReadyPlaySec = actionReadyPlaySec;
	}

	public float getActionEndPlaySec() {
		return actionEndPlaySec;
	}

	public void setActionEndPlaySec(float actionEndPlaySec) {
		this.actionEndPlaySec = actionEndPlaySec;
	}

	public int getRanking() {
		return ranking;
	}

	public void setRanking(int ranking) {
		this.ranking = ranking;
	}

	public int getBattleCommandType() {
		return battleCommandType;
	}

	public void setBattleCommandType(int battleCommandType) {
		this.battleCommandType = battleCommandType;
	}

	public int getSkillType() {
		return skillType;
	}

	public void setSkillType(int skillType) {
		this.skillType = skillType;
	}

	public int getSkillAttackType() {
		return skillAttackType;
	}

	public void setSkillAttackType(int skillAttackType) {
		this.skillAttackType = skillAttackType;
	}

	public String getSuccessRateFormula() {
		return successRateFormula;
	}

	public void setSuccessRateFormula(String successRateFormula) {
		this.successRateFormula = successRateFormula;
	}

	public String getTargetSuccessHpEffect() {
		return targetSuccessHpEffect;
	}

	public void setTargetSuccessHpEffect(String targetSuccessHpEffect) {
		if (targetSuccessHpEffect != null) {
			this.targetSuccessHpEffect = targetSuccessHpEffect.trim();
			if (targetSuccessHpEffect.trim().startsWith("-")) {
				ifHpLossFunction = true;
			} else {
				hpIncreaseFunction = true;
			}
		} else {
			this.targetSuccessHpEffect = StringUtils.EMPTY;
		}
	}

	public String getTargetFailureHpEffect() {
		return targetFailureHpEffect;
	}

	public void setTargetFailureHpEffect(String targetFailureHpEffect) {
		this.targetFailureHpEffect = targetFailureHpEffect;
	}

	public String getTargetSuccessMpEffect() {
		return targetSuccessMpEffect;
	}

	public void setTargetSuccessMpEffect(String targetSuccessMpEffect) {
		this.targetSuccessMpEffect = targetSuccessMpEffect;
	}

	public String getTargetFailureMpEffect() {
		return targetFailureMpEffect;
	}

	public void setTargetFailureMpEffect(String targetFailureMpEffect) {
		this.targetFailureMpEffect = targetFailureMpEffect;
	}

	public float getDamagePlusRate() {
		return damagePlusRate;
	}

	public void setDamagePlusRate(float damagePlusRate) {
		this.damagePlusRate = damagePlusRate;
	}

	public String getSpendSpFormula() {
		return spendSpFormula;
	}

	public void setSpendSpFormula(String spendSpFormula) {
		this.spendSpFormula = spendSpFormula;
	}

	public String getSelfSuccessHpEffectFormula() {
		return selfSuccessHpEffectFormula;
	}

	public void setSelfSuccessHpEffectFormula(String selfSuccessHpEffectFormula) {
		this.selfSuccessHpEffectFormula = selfSuccessHpEffectFormula;
	}

	public String getSelfSuccessMpEffectFormula() {
		return selfSuccessMpEffectFormula;
	}

	public void setSelfSuccessMpEffectFormula(String selfSuccessMpEffectFormula) {
		this.selfSuccessMpEffectFormula = selfSuccessMpEffectFormula;
	}

	public String getTeamSuccessHpEffectFormula() {
		return teamSuccessHpEffectFormula;
	}

	public void setTeamSuccessHpEffectFormula(String teamSuccessHpEffectFormula) {
		this.teamSuccessHpEffectFormula = teamSuccessHpEffectFormula;
	}

	public String getTeamSuccessMpEffectFormula() {
		return teamSuccessMpEffectFormula;
	}

	public void setTeamSuccessMpEffectFormula(String teamSuccessMpEffectFormula) {
		this.teamSuccessMpEffectFormula = teamSuccessMpEffectFormula;
	}

	public int getCd() {
		return cd;
	}

	public void setCd(int cd) {
		this.cd = cd;
	}

	@Transient
	public void setBuffRequiredStr(String buffRequiredStr) {
		this.buffRequired = SplitUtils.split2IntMap(buffRequiredStr, ",", ":");
	}

	public Map<Integer, Integer> buffRequired() {
		return buffRequired;
	}

	public boolean isCanApplyToHiddenTarget() {
		return canApplyToHiddenTarget;
	}

	public void setCanApplyToHiddenTarget(boolean canApplyToHiddenTarget) {
		this.canApplyToHiddenTarget = canApplyToHiddenTarget;
	}

	@Transient
	public void setTargetRemoveBuffIdStr(String targetRemoveBuffIdStr) {
		this.targetRemoveBuffs = SplitUtils.split2IFMap(targetRemoveBuffIdStr, ",", ":");
	}

	@Transient
	public void setSelfRemoveBuffIdStr(String selfRemoveBuffIdStr) {
		this.selfRemoveBuffs = SplitUtils.split2IFMap(selfRemoveBuffIdStr, ",", ":");
	}

	public Map<Integer, Float> targetRemoveBuffs() {
		return this.targetRemoveBuffs;
	}

	public Map<Integer, Float> selfRemoveBuffs() {
		return this.selfRemoveBuffs;
	}

	public Map<Integer, Float> targetRemoveOneBuffByType() {
		return targetRemoveOneBuffByType;
	}

	@Transient
	public void setTargetRemoveOneBuffByTypeStr(String targetRemoveOneBuffByTypeStr) {
		this.targetRemoveOneBuffByType = SplitUtils.split2IFMap(targetRemoveOneBuffByTypeStr, ",", ":");
	}

	public int getTargetSelectLogicId() {
		return targetSelectLogicId;
	}

	public void setTargetSelectLogicId(int targetSelectLogicId) {
		this.targetSelectLogicId = targetSelectLogicId;
	}

	public String getTargetPlusHpEffect() {
		return targetPlusHpEffect;
	}

	public void setTargetPlusHpEffect(String targetPlusHpEffect) {
		this.targetPlusHpEffect = targetPlusHpEffect;
	}

	public ITargetSelectLogic targetSelectLogic() {
		return TargetSelectLogicManager.getInstance().getLogic(this.targetSelectLogicId);
	}

	public int getCallMonsterId() {
		return callMonsterId;
	}

	public void setCallMonsterId(int callMonsterId) {
		this.callMonsterId = callMonsterId;
	}

	public float getSuckHpRate() {
		return suckHpRate;
	}

	public void setSuckHpRate(float suckHpRate) {
		this.suckHpRate = suckHpRate;
	}

	public float getSuckMpRate() {
		return suckMpRate;
	}

	public void setSuckMpRate(float suckMpRate) {
		this.suckMpRate = suckMpRate;
	}

	public int getBattleType() {
		return battleType;
	}

	public void setBattleType(int battleType) {
		this.battleType = battleType;
	}

	public String getTargetSuccessSpEffect() {
		return targetSuccessSpEffect;
	}

	public void setTargetSuccessSpEffect(String targetSuccessSpEffect) {
		this.targetSuccessSpEffect = targetSuccessSpEffect;
	}

	public String getTargetFailureSpEffect() {
		return targetFailureSpEffect;
	}

	public void setTargetFailureSpEffect(String targetFailureSpEffect) {
		this.targetFailureSpEffect = targetFailureSpEffect;
	}

	public Map<Long, BattleSoldier> filter(Map<Long, BattleSoldier> targets) {
		// 父类里面不过滤,原样返回
		return targets;
	}

	@Override
	public String toString() {
		return ReflectionToStringBuilder.toString(this, ToStringStyle.SHORT_PREFIX_STYLE);
	}

	public int getCallMonsterCount() {
		return callMonsterCount;
	}

	public void setCallMonsterCount(int callMonsterCount) {
		this.callMonsterCount = callMonsterCount;
	}

	public int getSkillActionType() {
		return skillActionType;
	}

	public void setSkillActionType(int skillActionType) {
		this.skillActionType = skillActionType;
	}

	@Override
	public int hashCode() {
		final int prime = 31;
		int result = 1;
		result = prime * result + id;
		return result;
	}

	@Override
	public boolean equals(Object obj) {
		if (this == obj)
			return true;
		if (obj == null)
			return false;
		if (getClass() != obj.getClass())
			return false;
		Skill other = (Skill) obj;
		if (id != other.id)
			return false;
		return true;
	}

	public String getCrewDescription() {
		return crewDescription;
	}

	public void setCrewDescription(String crewDescription) {
		this.crewDescription = crewDescription;
	}

	@Transient
	public void setTargetRemoveBuffTypeStr(String targetRemoveBuffTypeStr) {
		this.targetRemoveBuffTypes = SplitUtils.split2IntSet(targetRemoveBuffTypeStr, ",");
	}

	public Set<Integer> targetRemoveBuffTypes() {
		if (this.targetRemoveBuffTypes == null)
			return Collections.emptySet();
		return this.targetRemoveBuffTypes;
	}

	public int getMaxCall() {
		return maxCall;
	}

	public void setMaxCall(int maxCall) {
		this.maxCall = maxCall;
	}

	public boolean unableProtect() {
		// 法术攻击不能保护
		if (!skillDefensable())
			return true;
		// 一次打多人的物理攻击不能保护
		boolean multiTarget = false;
		if (CollectionUtils.isNotEmpty(this.skillTargetInfos)) {
			// 群攻标记
			multiTarget = this.skillTargetInfos.size() > 1 || this.skillTargetInfos.get(0).getTargetNum() == 0;
		}
		return this.atOnce && multiTarget;
	}

	public boolean isIgnoreSpellEffect() {
		return ignoreSpellEffect;
	}

	public void setIgnoreSpellEffect(boolean ignoreSpellEffect) {
		this.ignoreSpellEffect = ignoreSpellEffect;
	}

	public int getRelationType() {
		return relationType;
	}

	public void setRelationType(int relationType) {
		this.relationType = relationType;
	}

	public int getFriendly() {
		return friendly;
	}

	public void setFriendly(int friendly) {
		this.friendly = friendly;
	}

	public boolean isDeadTriggerBuff() {
		return deadTriggerBuff;
	}

	public void setDeadTriggerBuff(boolean deadTriggerBuff) {
		this.deadTriggerBuff = deadTriggerBuff;
	}

	public boolean isDeadTriggerSkill() {
		return deadTriggerSkill;
	}

	public void setDeadTriggerSkill(boolean deadTriggerSkill) {
		this.deadTriggerSkill = deadTriggerSkill;
	}

	public boolean isMustFirstTarget() {
		return mustFirstTarget;
	}

	public void setMustFirstTarget(boolean mustFirstTarget) {
		this.mustFirstTarget = mustFirstTarget;
	}

	public boolean isCannotDefense() {
		return cannotDefense;
	}

	public void setCannotDefense(boolean cannotDefense) {
		this.cannotDefense = cannotDefense;
	}

	public boolean isCannotProtect() {
		return cannotProtect;
	}

	public void setCannotProtect(boolean cannotProtect) {
		this.cannotProtect = cannotProtect;
	}

	public boolean isBanLife() {
		return banLife;
	}

	public void setBanLife(boolean banLife) {
		this.banLife = banLife;
	}

	/** 是否是夫妻法术 */
	public boolean coupleSkill() {
		return this.relationType == RelationTypeEnum.Couple.ordinal();
	}

	public TargetSelectLogicParam selectLogicParam() {
		return this.selectLogicParam;
	}

	public void TargetSelectLogicParam(TargetSelectLogicParam param) {
		this.selectLogicParam = param;
	}

	@Transient
	public void setTargetSelectParamStr(String targetSelectParamStr) {
		if (StringUtils.isBlank(targetSelectParamStr))
			return;
		ITargetSelectLogic logic = targetSelectLogic();
		if (logic == null)
			return;
		logic.initParams(this, targetSelectParamStr);
	}

	public String getExtraCritRateFormula() {
		return extraCritRateFormula;
	}

	@Transient
	public void setExtraCritRateFormula(String extraCritRateFormula) {
		this.extraCritRateFormula = extraCritRateFormula;
	}

	public float getNightDamageVaryRate() {
		return nightDamageVaryRate;
	}

	@Transient
	public void setNightDamageVaryRate(float nightDamageVaryRate) {
		this.nightDamageVaryRate = nightDamageVaryRate;
	}

}
