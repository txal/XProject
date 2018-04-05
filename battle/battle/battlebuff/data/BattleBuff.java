package com.nucleus.logic.core.modules.battlebuff.data;

import java.util.ArrayList;
import java.util.HashSet;
import java.util.List;
import java.util.Set;

import javax.persistence.Transient;

import org.apache.commons.lang3.StringUtils;
import org.apache.commons.lang3.builder.ReflectionToStringBuilder;
import org.apache.commons.lang3.builder.ToStringStyle;

import com.google.common.collect.BiMap;
import com.google.common.collect.HashBiMap;
import com.nucleus.commons.data.DataBasic;
import com.nucleus.commons.data.StaticDataManager;
import com.nucleus.commons.message.BroadcastMessage;
import com.nucleus.commons.utils.ExcelUtils;
import com.nucleus.commons.utils.SplitUtils;
import com.nucleus.logic.core.modules.battle.data.SkillWeightInfo;
import com.nucleus.logic.core.modules.battle.data.SkillsWeight;
import com.nucleus.logic.core.modules.battle.data.StrikeBackInfo;
import com.nucleus.logic.core.modules.battlebuff.BattleBuffLogicManager;
import com.nucleus.logic.core.modules.battlebuff.IBattleBuffLogic;
import com.nucleus.logic.core.modules.battlebuff.model.BattleBuffContext;
import com.nucleus.logic.core.modules.battlebuff.model.BuffLogicParam;
import com.nucleus.logic.core.modules.charactor.model.AptitudeProperties;
import com.nucleus.logic.core.modules.constants.CommonEnums.BattleCommandType;

/**
 * 战斗buff
 * 
 * @author liguo
 * 
 */
public class BattleBuff implements BroadcastMessage, DataBasic {

	public enum BattleBasePropertyType {
		/** 未知 */
		Unknown(false),
		/** 血量1 */
		Hp(false),
		/** 先手值2 */
		Speed(false),
		/** 攻击力3 */
		Attack(false),
		/** 防御力4 */
		Defense(false),
		/** 暴击率5 */
		CritRate(true),
		/** 命中率6 */
		HitRate(true),
		/** 闪避率7 */
		DodgeRate(true),
		/** 法力8 */
		Mp(false),
		/** 法术暴击率9 */
		MagicCritRate(true),
		/** 法术命中率10 */
		MagicHitRate(true),
		/** 法术闪避率11 */
		MagicDodgeRate(true),
		/** 灵力12 */
		Magic(false),
		/** 受到的伤害13 */
		DamageInput(false),
		/** 治疗效果增强14 */
		HpBuffEffectEnhance(false),
		/** 法攻15 */
		MagicAttack(false),
		/** 法防16 */
		MagicDefense(false),
		/** (受到的)法术伤害17 */
		MagicHurt(false),
		/** 速度百分比18 **/
		SpeedRate(true),
		/** 通用增伤百分比19 **/
		DamageIncrease(true),
		/** 通用减伤百分比20 **/
		DamageDecrease(true),
		/** 物理增伤百分比21 **/
		PhysicalDamageIncrease(true),
		/** 物理减伤百分比22 **/
		PhysicalDamageDecrease(true),
		/** 法术增伤百分比23 **/
		MagicDamageIncrease(true),
		/** 法术减伤百分比24 **/
		MagicDamageDecrease(true),
		/** 怒气25 */
		Sp(false),
		/** 体质26 */
		Constitution(false),
		/** 魔力27 */
		Intelligent(false),
		/** 力量28 */
		Strength(false),
		/** 耐力29 */
		Stamina(false),
		/** 敏捷30 */
		Dexterity(false),
		/** 气血百分比31 */
		HpRate(true),
		/** 攻击力百分比32 */
		AttackRate(true),
		/** 防御百分比33 */
		DefenseRate(true),
		/** 灵力百分比34 */
		MagicRate(true),
		/** 伤害输出35 */
		DamageOutput(false),
		/** 伤害输出(率)36 */
		DamageOutputRate(true),
		/** 受到的伤害(率)37 */
		DamageInputRate(true),
		/** 抗暴击(物抗和法抗)38 */
		CritRateReduce(true),
		/** 封印命中率 39 */
		SealHitRate(true),
		/** 抵抗封印概率 40 */
		SealHitReduce(true),
		/** 出战宠数量限制 41 */
		CallPetCount(false),
		/** 暴击伤害率 42 */
		CritHurtRate(true),
		/** 怒气消耗减免率 43 */
		SpendSpDiscountRate(true),
		/** 怒气百分比 44 **/
		SpRate(true),
		/** 法宝法力 45 **/
		MagicMana(false),
		/** 药效吸收46 */
		DrugHealInput(true),
		/** 47 施放技能最小hp */
		MinFireHp(false),
		/** 48 施放技能最大hp */
		MaxFireHp(false),
		/** 49 受到物理伤害 */
		PhyHurt(false),
		/** 50 物理抗暴率 */
		PhyCritReduceRate(true),
		/** 51 法术抗暴率 */
		MagicCritReduceRate(true),
		/** 52 血量上限 */
		MaxHp(true),
		/** 53 全属性（加点五种属性，目前只用于翅膀） */
		AllAttribute(false),
		/** 54 暴击伤害抗伤率 */
		CritHurtReduceRate(true),
		/** 55 法攻百分比 **/
		MagicAttackRate(true),
		/** 56 法防百分比 */
		MagicDefenseRate(true);

		private boolean percent = false;

		BattleBasePropertyType(boolean percent) {
			this.percent = percent;
		}

		public boolean isPercent() {
			return this.percent;
		}

		private static BiMap<BattleBasePropertyType, BattleBasePropertyType> pairIndexes = null;

		static {
			pairIndexes = HashBiMap.create();
			pairIndexes.put(Speed, SpeedRate);
			pairIndexes.put(Attack, AttackRate);
			pairIndexes.put(Defense, DefenseRate);
			pairIndexes.put(Hp, HpRate);
			pairIndexes.put(Magic, MagicRate);
		}

		public BattleBasePropertyType oppo() {
			BattleBasePropertyType oppo = pairIndexes.get(this);
			if (oppo == null) {
				oppo = pairIndexes.inverse().get(this);
			}
			return oppo;
		}

		public static BattleBasePropertyType ofAptitudeType(int aptitudeTypeId) {
			if (aptitudeTypeId == AptitudeProperties.MP_TYPE) {
				return Mp;
			} else if (aptitudeTypeId == AptitudeProperties.AptitudeType.Constitution.ordinal()) {
				return Constitution;
			} else if (aptitudeTypeId == AptitudeProperties.AptitudeType.Intelligent.ordinal()) {
				return Intelligent;
			} else if (aptitudeTypeId == AptitudeProperties.AptitudeType.Strength.ordinal()) {
				return Strength;
			} else if (aptitudeTypeId == AptitudeProperties.AptitudeType.Stamina.ordinal()) {
				return Stamina;
			} else if (aptitudeTypeId == AptitudeProperties.AptitudeType.Dexterity.ordinal()) {
				return Dexterity;
			} else {
				return Unknown;
			}
		}

		public static Set<Integer> allAttribute() {
			Set<Integer> allOrdinal = new HashSet<>();
			allOrdinal.add(Constitution.ordinal());
			allOrdinal.add(Intelligent.ordinal());
			allOrdinal.add(Strength.ordinal());
			allOrdinal.add(Stamina.ordinal());
			allOrdinal.add(Dexterity.ordinal());
			return allOrdinal;
		}
	}

	public enum BattleBuffExecuteStage {
		/** 0 未知 */
		Unknown,
		/** 1 回合开始 */
		RoundStart,
		/** 2 行动开始 */
		ActionStart,
		/** 3 行动结束 */
		ActionEnd,
		/** 4 回合结束 */
		RoundEnd,
		/** 5 角色属性影响 */
		BaseProperty,
		/** 6 反击 */
		StrikeBack,
		/** 7 反震 */
		Rebound,
		/** 8 死亡触发 */
		Dead,
		/** 9 攻击之前 */
		BeforeAttack,
		/** 10 获得buff 之后 */
		AfterGetBuff;
	}

	public enum BattleBuffType {
		/** 未知 */
		Unknown,
		/** 异常状态 */
		AbnormalStatus,
		/** 辅助状态 */
		AssistStatus,
		/** 临时状态 */
		TemporaryStatus,
		/** 特殊状态 */
		SpecialStatus,
		/** 隐身 */
		Hidden
	}

	public enum BuffPropertyEnum {
		/** 未知 */
		Unknown,
		/** 持续回合数 */
		Rounds,
		/** 生效次数 */
		EffectTimes
	}

	public enum BattleBuffBanStateTipsEnum {
		/**
		 * 未封印行动
		 */
		NO,
		/**
		 * 提示封禁
		 */
		BanWithTips,
		/**
		 * 不提示封禁
		 */
		BanWithoutTips,
	}

	public enum BuffClassTypeEnum {
		Normal,
		/** 封印 */
		Ban
	}

	/** 编号 */
	private int id;

	/** 名称 */
	private String name;

	/** 描述 */
	private String description;

	/** 特效 */
	private int animation;

	/** 特效锚点 */
	private String animationMount;

	/** 图标 */
	private String icon;

	/** buff类型 */
	private int buffType;

	/** 反击概率 */
	private float strikeBackSuccessRate;

	/** 反击伤害变动率 */
	private float strikeBackDamageVaryRate;

	/** 用于反击的技能id:该技能的几率,…(逗号分隔) */
	private String strikeBackSkillInfo;
	/**
	 * 可反击的技能id列表,逗号分隔,如果没有配置则反击所有可反击的技能
	 */
	private String beStrikeBackSkillIdStr;
	/** 所有buff获得几率公式 */
	private String buffsAcquireRateFormula;

	/** 所有buff持续回合数公式 */
	private String buffsPersistRoundFormula;

	/** 所有buff作用次数 */
	private int buffsEffectTimes;

	/** 所有buff生效时机 */
	private String buffsExecuteStage;

	private Set<Integer> buffsExecuteStageSet;
	/** 封禁战斗指令列表文本 */
	private String banBattleCommandTypesStr;

	/** 所有基础buff编号 */
	private int[] battleBasePropertyTypes;

	/** 基础buff效果公式 */
	private String[] battleBasePropertyEffectFormulas;

	/** 所有基础buff内容列表 */
	private List<BattleBuffContext> battleBuffContexts = new ArrayList<BattleBuffContext>();

	/** 封禁战斗指令列表 */
	private List<BattleCommandType> banBattleCommandTypes = new ArrayList<BattleCommandType>();

	/** 反击信息 */
	private StrikeBackInfo strikeBackInfo;

	/** 速度是否改变 */
	private boolean speedChange = false;
	/** buff对应逻辑id */
	private int buffLogicId;
	/** buff逻辑参数 */
	private BuffLogicParam buffParam;
	/**
	 * 受到攻击时是否接触buff
	 */
	private boolean removeOnAttack;
	/**
	 * 是否阻止复活
	 */
	private boolean preventRelive;
	/**
	 * 是否飘字
	 */
	private boolean showTips;
	/** 分类,如封禁等 */
	private int buffClassType;
	/** 同类是否可叠加 */
	private boolean sameClassTypePileable;
	/** 存在该buff的时候施放技能提示 */
	private int skillActionStatusCode;
	/** 阻止治疗 */
	private boolean preventHeal;
	/** 阻止自动逃跑 */
	private boolean preventAutoEscape;
	/** 作用于死亡目标 */
	private boolean forDead;
	/** 死亡后依然进行buff逻辑处理 */
	private boolean deadTreatment;
	/** 额外属性 */
	private String extraParam;

	public static BattleBuff get(int id) {
		return StaticDataManager.getInstance().get(BattleBuff.class, id);
	}

	@Transient
	public void setBuffLogicParamStr(String buffLogicParamStr) {
		if (StringUtils.isBlank(buffLogicParamStr))
			return;
		if (this.buffLogicId <= 0)
			return;
		IBattleBuffLogic logic = buffLogic();
		if (logic == null)
			return;
		logic.initParam(this, buffLogicParamStr);
	}

	@Override
	public void afterPropertySet() {
		if (null != getBattleBasePropertyTypes()) {
			BattleBasePropertyType[] battleBasePropertyTypes = BattleBasePropertyType.values();
			int battleBasePropertyTypesLen = battleBasePropertyTypes.length;
			for (int i = 0; i < getBattleBasePropertyTypes().length; i++) {
				int battleBasePropertyType = getBattleBasePropertyTypes()[i];
				if (battleBasePropertyType > battleBasePropertyTypesLen) {
					continue;
				}
				BattleBuffContext buffContext = new BattleBuffContext(this.getId(), battleBasePropertyTypes[battleBasePropertyType], getBattleBasePropertyEffectFormulas()[i]);
				battleBuffContexts.add(buffContext);
				if (buffContext.battleBasePropertyType() == BattleBasePropertyType.Speed) {
					speedChange = true;
				}
			}
		}

		if (StringUtils.isNotBlank(banBattleCommandTypesStr)) {
			String[] banBattleCommandTypesArr = banBattleCommandTypesStr.split(",");
			BattleCommandType[] battleCommandTypes = BattleCommandType.values();
			int battleCommandTypeLen = battleCommandTypes.length;
			for (int i = 0; i < banBattleCommandTypesArr.length; i++) {
				int battleComandType = Integer.parseInt(banBattleCommandTypesArr[i]);
				if (battleComandType > battleCommandTypeLen) {
					continue;
				}
				banBattleCommandTypes.add(battleCommandTypes[battleComandType]);
			}
		}

		if (StringUtils.isNotBlank(strikeBackSkillInfo)) {
			List<SkillWeightInfo> strikeBackSkillWeightInfos = new ArrayList<SkillWeightInfo>();
			int skillsWeightScope = 0;
			for (String skillInfoStr : strikeBackSkillInfo.split(",")) {
				if (StringUtils.isBlank(skillInfoStr)) {
					continue;
				}

				String[] skillInfo = skillInfoStr.split(":");
				if (skillInfo.length != 2) {
					continue;
				}

				int skillId = Integer.parseInt(skillInfo[0]);
				int skillWeight = Integer.parseInt(skillInfo[1]);
				strikeBackSkillWeightInfos.add(new SkillWeightInfo(skillId, skillWeight));
				skillsWeightScope += skillWeight;
			}
			Set<Integer> beStrikeBackSkillIds = SplitUtils.split2IntSet(beStrikeBackSkillIdStr, ",");
			this.strikeBackInfo = new StrikeBackInfo(new SkillsWeight(skillsWeightScope, strikeBackSkillWeightInfos), strikeBackSuccessRate, strikeBackDamageVaryRate, beStrikeBackSkillIds);
		}

		this.buffsExecuteStageSet = SplitUtils.split2IntSet(this.buffsExecuteStage, ",");
	}

	public StrikeBackInfo strikeBackInfo() {
		return this.strikeBackInfo;
	}

	public List<BattleBuffContext> battleBuffContexts() {
		return this.battleBuffContexts;
	}

	public List<BattleCommandType> banBattleCommandTypes() {
		return banBattleCommandTypes;
	}

	public boolean hasSpeedChange() {
		return this.speedChange;
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

	public String getDescription() {
		return description;
	}

	public void setDescription(String description) {
		this.description = description;
	}

	public String getExtraParam() {
		return extraParam;
	}

	public void setExtraParam(String extraParam) {
		this.extraParam = extraParam;
	}

	public int getAnimation() {
		return animation;
	}

	public void setAnimation(int animation) {
		this.animation = animation;
	}

	public String getAnimationMount() {
		return animationMount;
	}

	public void setAnimationMount(String animationMount) {
		this.animationMount = animationMount;
	}

	public String getIcon() {
		return icon;
	}

	public void setIcon(String icon) {
		this.icon = ExcelUtils.removeFloat(icon);
	}

	public String getBuffsAcquireRateFormula() {
		return buffsAcquireRateFormula;
	}

	public void setBuffsAcquireRateFormula(String buffsAcquireRateFormula) {
		this.buffsAcquireRateFormula = buffsAcquireRateFormula;
	}

	public int getBuffType() {
		return buffType;
	}

	public void setBuffType(int buffType) {
		this.buffType = buffType;
	}

	public int getBuffsEffectTimes() {
		return buffsEffectTimes;
	}

	public void setBuffsEffectTimes(int buffsEffectTimes) {
		this.buffsEffectTimes = buffsEffectTimes;
	}

	public String getBuffsPersistRoundFormula() {
		return buffsPersistRoundFormula;
	}

	public void setBuffsPersistRoundFormula(String buffsPersistRoundFormula) {
		this.buffsPersistRoundFormula = buffsPersistRoundFormula;
	}

	public String getBanBattleCommandTypesStr() {
		return banBattleCommandTypesStr;
	}

	public void setBanBattleCommandTypesStr(String banBattleCommandTypesStr) {
		this.banBattleCommandTypesStr = banBattleCommandTypesStr;
	}

	public int[] getBattleBasePropertyTypes() {
		return battleBasePropertyTypes;
	}

	public void setBattleBasePropertyTypes(int[] battleBasePropertyTypes) {
		this.battleBasePropertyTypes = battleBasePropertyTypes;
	}

	public String[] getBattleBasePropertyEffectFormulas() {
		return battleBasePropertyEffectFormulas;
	}

	public void setBattleBasePropertyEffectFormulas(String[] battleBasePropertyEffectFormulas) {
		this.battleBasePropertyEffectFormulas = battleBasePropertyEffectFormulas;
	}

	public float getStrikeBackSuccessRate() {
		return strikeBackSuccessRate;
	}

	public void setStrikeBackSuccessRate(float strikeBackSuccessRate) {
		this.strikeBackSuccessRate = strikeBackSuccessRate;
	}

	public float getStrikeBackDamageVaryRate() {
		return strikeBackDamageVaryRate;
	}

	public void setStrikeBackDamageVaryRate(float strikeBackDamageVaryRate) {
		this.strikeBackDamageVaryRate = strikeBackDamageVaryRate;
	}

	public String getStrikeBackSkillInfo() {
		return strikeBackSkillInfo;
	}

	public void setStrikeBackSkillInfo(String strikeBackSkillInfo) {
		this.strikeBackSkillInfo = strikeBackSkillInfo;
	}

	public String getBuffsExecuteStage() {
		return buffsExecuteStage;
	}

	public void setBuffsExecuteStage(String buffsExecuteStage) {
		this.buffsExecuteStage = buffsExecuteStage;
	}

	public int getBuffLogicId() {
		return buffLogicId;
	}

	public void setBuffLogicId(int buffLogicId) {
		this.buffLogicId = buffLogicId;
	}

	public String getBeStrikeBackSkillIdStr() {
		return beStrikeBackSkillIdStr;
	}

	public void setBeStrikeBackSkillIdStr(String beStrikeBackSkillIdStr) {
		this.beStrikeBackSkillIdStr = beStrikeBackSkillIdStr;
	}

	public boolean isRemoveOnAttack() {
		return removeOnAttack;
	}

	public void setRemoveOnAttack(boolean removeOnAttack) {
		this.removeOnAttack = removeOnAttack;
	}

	public IBattleBuffLogic buffLogic() {
		if (this.buffLogicId <= 0)
			return null;
		final BattleBuffLogicManager logicManager = BattleBuffLogicManager.getInstance();
		if (logicManager == null)
			return null;
		return logicManager.getLogic(this.buffLogicId);
	}

	/**
	 * buff生效阶段标识集合,一个buff可以在多个阶段生效
	 * 
	 * @return
	 */
	public Set<Integer> buffsExecuteStageSet() {
		return this.buffsExecuteStageSet;
	}

	public boolean isPreventRelive() {
		return preventRelive;
	}

	public void setPreventRelive(boolean preventRelive) {
		this.preventRelive = preventRelive;
	}

	public boolean isShowTips() {
		return showTips;
	}

	public void setShowTips(boolean showTips) {
		this.showTips = showTips;
	}

	public int getBuffClassType() {
		return buffClassType;
	}

	public void setBuffClassType(int buffClassType) {
		this.buffClassType = buffClassType;
	}

	public boolean isSameClassTypePileable() {
		return sameClassTypePileable;
	}

	public void setSameClassTypePileable(boolean sameClassTypePileable) {
		this.sameClassTypePileable = sameClassTypePileable;
	}

	@Transient
	public BuffLogicParam getBuffParam() {
		return buffParam;
	}

	@Transient
	public void setBuffParam(BuffLogicParam buffParam) {
		this.buffParam = buffParam;
	}

	public int getSkillActionStatusCode() {
		return skillActionStatusCode;
	}

	public void setSkillActionStatusCode(int skillActionStatusCode) {
		this.skillActionStatusCode = skillActionStatusCode;
	}

	@Override
	public String toString() {
		return ReflectionToStringBuilder.toString(this, ToStringStyle.SHORT_PREFIX_STYLE);
	}

	public boolean isPreventHeal() {
		return preventHeal;
	}

	public void setPreventHeal(boolean preventHeal) {
		this.preventHeal = preventHeal;
	}

	public boolean isPreventAutoEscape() {
		return preventAutoEscape;
	}

	public void setPreventAutoEscape(boolean preventAutoEscape) {
		this.preventAutoEscape = preventAutoEscape;
	}

	public boolean isForDead() {
		return forDead;
	}

	public void setForDead(boolean forDead) {
		this.forDead = forDead;
	}

	public boolean isDeadTreatment() {
		return deadTreatment;
	}

	public void setDeadTreatment(boolean deadTreatment) {
		this.deadTreatment = deadTreatment;
	}

	public boolean antiItem(int itemId) {
		IBattleBuffLogic logic = this.buffLogic();
		if (logic == null)
			return false;
		return logic.antiItem(this.buffParam, itemId);
	}

}
