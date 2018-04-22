/**
 * 
 */
package com.nucleus.logic.core.modules.battle.model;

import java.util.ArrayList;
import java.util.HashMap;
import java.util.HashSet;
import java.util.List;
import java.util.Map;
import java.util.Set;
import java.util.concurrent.ConcurrentHashMap;

import com.nucleus.commons.utils.RandomUtils;
import com.nucleus.logic.core.modules.battle.data.Skill;
import com.nucleus.logic.core.modules.battle.data.Skill.SkillAttackType;
import com.nucleus.logic.core.modules.battle.data.StrikeBackInfo;
import com.nucleus.logic.core.modules.battle.dto.AttackDebugInfo;
import com.nucleus.logic.core.modules.battle.dto.VideoBuffRemoveTargetState;
import com.nucleus.logic.core.modules.battle.dto.VideoRound;
import com.nucleus.logic.core.modules.battle.dto.VideoSkillAction;
import com.nucleus.logic.core.modules.battle.logic.SkillTargetPolicy;
import com.nucleus.logic.core.modules.battlebuff.IBattleBuffLogic;
import com.nucleus.logic.core.modules.battlebuff.model.BattleBuffEntity;
import com.nucleus.logic.core.modules.charactor.model.PersistPlayerChild;
import com.nucleus.logic.core.modules.charactor.model.PersistPlayerPet;
import com.nucleus.logic.core.modules.player.data.Props;
import com.nucleus.logic.core.modules.player.dto.PlayerDto.PlayerTeamStatus;

/**
 * 指令施放上下文
 * 
 * @author liguo
 * 
 */
public class CommandContext {

	/** 技能施放者 */
	private BattleSoldier trigger;

	/** 施放的技能 */
	private Skill skill;

	/** 技能目标 */
	private BattleSoldier target;

	/** 替换宠物唯一编号 */
	private long petCharactorUniqueId;

	/** 技能是否暴击 */
	private boolean crit;

	/** 当前攻击力变动率 */
	private float curAttackVaryRate = 1.0F;

	/** 当前伤害变动率 */
	private float curDamageVaryRate = 1.0F;
	/** 每次出手攻击力变动,比如某技能打3下,该值都一致 */
	private float perAttackVaryRate = 1.f;
	/** 被反击动作 */
	private VideoSkillAction strikeSkillAction;
	/** 当前动作 */
	private VideoSkillAction skillAction;
	/** 是否已反击 */
	private boolean isStrokeBack = false;

	/** 攻击次数 */
	private int totalAttackCount;
	/** 攻击调试信息 */
	private AttackDebugInfo currentDebugInfo;
	private List<AttackDebugInfo> debugInfoList = new ArrayList<AttackDebugInfo>();
	/** 被攻击过(扣血)的目标id,回血不算,主要是缓存需要结算受击度的目标 */
	private Map<Long, BattleSoldier> beAttackedTargets = new HashMap<Long, BattleSoldier>();
	/** 伤害输出 */
	private int damageOutput;
	/** 施放技能hp消耗 */
	private int hpSpent;
	/** 施放技能消耗 */
	private int mpSpent;
	/** 怒气消耗 */
	private int spSpent;
	/** 是否触发连击 */
	private boolean isCombo;
	/** 是否触发追击 */
	private boolean isPursueAttack;
	/** 是否抗暴击 */
	private boolean isAntiCrit;
	/** 隐身无效 */
	private boolean hiddenFail;
	/** 将要被增加的buffId */
	private int beAddBuffId;
	/** 目标怒气变化 */
	private int targetSp;
	/** 使用的物品索引 */
	private int usedItemIndex = -1;
	/** 技能免疫 */
	private boolean buffAntiSkill;
	/** buff免疫 */
	private boolean antiBuff;
	/** 目标buff */
	private BattleBuffEntity targetBuff;
	/** 防御技能减伤 */
	private float defenseDamageRate;
	/** 药物效率 */
	private float drugEffectRate;
	/** 逃跑成功率 */
	private float retreatSuccessRate;
	/** 是否自动逃跑 */
	private boolean autoEscapeable;
	/** 攻击的目标id集合,包括被闪避的 */
	private Set<Long> targetIds = new HashSet<>();
	/** 换宠缓存宠物 */
	private PersistPlayerPet cachedBattlePet;
	/** 战斗中撤退之后的组队状态 */
	private PlayerTeamStatus retreatTeamStatus;
	/** 附加暴击率 */
	private float critRatePlus;
	/** 被加buff机率减免 */
	private float beBuffRate;
	/** 头号目标 */
	private BattleSoldier firstTarget;
	/** 所使用物品 */
	private Props props;
	/** 暴击伤害率 */
	private float critHurtRate;
	/** 总治疗量/总伤害量 */
	private long totalHpVaryAmount;
	/** 死亡反击 */
	private boolean deadStrokeBack;
	/** 施放技能所需最低hp */
	private int minFireHp;
	/** 施放技能最大hp限制 */
	private int maxFireHp;
	private PersistPlayerChild cachedBattleChild;
	/** 暴击附加伤害 */
	private int critDamageOutput;
	/** 保护方防御减伤 */
	private float protectorDefenseDamageRate;
	/** 多段攻击下标索引 */
	private int comboIndex;

	/** 多段攻击记录目标 */
	private List<SkillTargetPolicy> comboTargetPolicys = new ArrayList<>();
	/** 保存攻击过的目标 */
	private List<SkillTargetPolicy> targetPolicys = new ArrayList<>();
	/** 临时数据 */
	private Map<String, Object> mateData = new ConcurrentHashMap<String, Object>();
	/** 能否作用鬼魂 */
	private boolean effectGhost;

	public boolean isEffectGhost() {
		return effectGhost;
	}

	public void setEffectGhost(boolean effectGhost) {
		this.effectGhost = effectGhost;
	}

	public CommandContext(BattleSoldier trigger, Skill skill, BattleSoldier target) {
		this.trigger = trigger;
		this.skill = skill;
		this.target = target;
	}

	public CommandContext(BattleSoldier trigger, Skill skill, BattleSoldier target, long petCharactorUniqueId) {
		this(trigger, skill, target);
		this.petCharactorUniqueId = petCharactorUniqueId;
	}

	public CommandContext(BattleSoldier trigger, Skill skill, BattleSoldier target, long petCharactorUniqueId, int usedItemIndex, Props props) {
		this(trigger, skill, target);
		this.petCharactorUniqueId = petCharactorUniqueId;
		this.usedItemIndex = usedItemIndex;
		this.props = props;
	}

	public BattleSoldier trigger() {
		return this.trigger;
	}

	/**
	 * 当前战斗
	 * 
	 * @return
	 */
	public Battle battle() {
		return this.trigger().battleTeam().battle();
	}

	public void strikeBack(VideoSkillAction underStrikeBackSkillAction) {
		if (isStrokeBack() || !this.skill().isStrikebackable()) {
			return;
		}

		BattleBuffEntity strikeBackBuffEntity = target.buffHolder().strikeBackBuffEntity();
		if (null == strikeBackBuffEntity) {
			return;
		}
		StrikeBackInfo strikeBackInfo = strikeBackBuffEntity.battleBuff().strikeBackInfo();
		if (null == strikeBackInfo || !strikeBackInfo.hasStrikeBack()) {
			return;
		}

		Skill strikeBackSkill = strikeBackInfo.strikeBackSkill();
		if (null == strikeBackSkill) {
			return;
		}
		// 如果有配置可反击的技能,并且当前技能不在此列,则不可反击,如果为空则都可反击
		if (!strikeBackInfo.getBeStrikeBackSkillIds().isEmpty() && !strikeBackInfo.getBeStrikeBackSkillIds().contains(this.skill.getId()))
			return;
		CommandContext oldContext = target.getCommandContext();// 保留旧指令
		CommandContext commandContext = new CommandContext(target, strikeBackSkill, trigger);
		commandContext.setStrokeBack(true);
		commandContext.setHiddenFail(true);// 可以反击隐身目标
		VideoSkillAction strikeSkillAction = new VideoSkillAction(target.getId());
		underStrikeBackSkillAction.currentTargetStateGroup().setStrikeBackAction(strikeSkillAction);
		commandContext.setStrikeSkillAction(strikeSkillAction);
		commandContext.setCurDamageVaryRate(strikeBackInfo.strikeBackDamageVaryRate());
		IBattleBuffLogic logic = strikeBackBuffEntity.battleBuff().buffLogic();
		if (logic != null)
			logic.onStrikeBack(commandContext, strikeBackBuffEntity);
		target.initCommandContext(commandContext);
		strikeBackSkill.fired(commandContext);
		strikeBackBuffEntity.reduceEffectTimes();
		if (strikeBackBuffEntity.getBuffEffectTimes() <= 0) {
			strikeSkillAction.addTargetState(new VideoBuffRemoveTargetState(this.target, strikeBackBuffEntity.battleBuffId()));
		}
		target.destoryCommandContext();
		target.initCommandContext(oldContext);// 反击完毕重新设置回之前的指令
	}

	public void fireSkill() {
		Skill forceSkill = trigger.forceSkill();
		if (null != forceSkill) {
			this.skill = forceSkill;
			if (trigger.getForceTarget() != null) {
				this.target = trigger.getForceTarget();
				trigger.setForceTarget(null);
			}
		}
		skill.fired(this);
	}

	public VideoRound currentVideoRound() {
		return trigger.currentVideoRound();
	}

	public VideoSkillAction skillAction() {
		if (null != this.strikeSkillAction) {
			return this.strikeSkillAction;
		}
		if (this.skillAction != null)
			return this.skillAction;
		VideoRound curVideoRound = currentVideoRound();
		VideoSkillAction action = new VideoSkillAction(trigger.getId());
		curVideoRound.addSkillAction(action);
		this.skillAction = action;
		return action;
	}

	public Skill skill() {
		return skill;
	}

	public void setSkill(Skill skill) {
		this.skill = skill;
	}

	public BattleSoldier target() {
		return target;
	}

	public void populateTarget(BattleSoldier target) {
		this.target = target;
	}

	public boolean isCrit() {
		return crit;
	}

	public void setCrit(boolean crit) {
		this.crit = crit;
	}

	public float getCurAttackVaryRate() {
		return curAttackVaryRate;
	}

	public void setCurAttackVaryRate(float curAttackVaryRate) {
		this.curAttackVaryRate = curAttackVaryRate;
	}

	public float getCurDamageVaryRate() {
		return curDamageVaryRate;
	}

	public void setCurDamageVaryRate(float curDamageVaryRate) {
		this.curDamageVaryRate = curDamageVaryRate;
	}

	public VideoSkillAction getStrikeSkillAction() {
		return strikeSkillAction;
	}

	public void setStrikeSkillAction(VideoSkillAction strikeSkillAction) {
		this.strikeSkillAction = strikeSkillAction;
	}

	public boolean isStrokeBack() {
		return isStrokeBack;
	}

	public void setStrokeBack(boolean isStrokeBack) {
		this.isStrokeBack = isStrokeBack;
	}

	public int totalAttackCount() {
		return totalAttackCount;
	}

	public void updateTotalAttackCount(int totalAttackCount) {
		this.totalAttackCount = totalAttackCount;
	}

	public void addAttackCount(int count) {
		this.totalAttackCount += count;
	}

	public long petCharactorUniqueId() {
		return petCharactorUniqueId;
	}

	public AttackDebugInfo debugInfo() {
		return currentDebugInfo;
	}

	public void setCurrentDebugInfo(AttackDebugInfo currentDebugInfo) {
		this.currentDebugInfo = currentDebugInfo;
	}

	public void initDebugInfo(BattleSoldier trigger, Skill skill, BattleSoldier target) {
		this.currentDebugInfo = new AttackDebugInfo(trigger, skill, target);
		this.debugInfoList.add(this.currentDebugInfo);
	}

	public List<AttackDebugInfo> getDebugInfoList() {
		return debugInfoList;
	}

	public void setDebugInfoList(List<AttackDebugInfo> debugInfoList) {
		this.debugInfoList = debugInfoList;
	}

	public Map<Long, BattleSoldier> getBeAttackedTargets() {
		return beAttackedTargets;
	}

	public void setBeAttackedTargets(Map<Long, BattleSoldier> beAttackedTargets) {
		this.beAttackedTargets = beAttackedTargets;
	}

	public int getDamageOutput() {
		return damageOutput;
	}

	public void setDamageOutput(int damageOutput) {
		this.damageOutput = damageOutput;
	}

	public int getHpSpent() {
		return hpSpent;
	}

	public void setHpSpent(int hpSpent) {
		this.hpSpent = hpSpent;
	}

	public int getMpSpent() {
		return mpSpent;
	}

	public void setMpSpent(int mpSpent) {
		this.mpSpent = mpSpent;
	}

	public int getSpSpent() {
		return spSpent;
	}

	public void setSpSpent(int spSpent) {
		this.spSpent = spSpent;
	}

	public boolean isCombo() {
		return isCombo;
	}

	public void setCombo(boolean isCombo) {
		this.isCombo = isCombo;
	}

	public boolean isPursueAttack() {
		return isPursueAttack;
	}

	public void setPursueAttack(boolean isPursueAttack) {
		this.isPursueAttack = isPursueAttack;
	}

	public boolean isAntiCrit() {
		return isAntiCrit;
	}

	public void setAntiCrit(boolean isAntiCrit) {
		this.isAntiCrit = isAntiCrit;
	}

	public boolean isHiddenFail() {
		return hiddenFail;
	}

	public void setHiddenFail(boolean hiddenFail) {
		this.hiddenFail = hiddenFail;
	}

	public int getBeAddBuffId() {
		return beAddBuffId;
	}

	public void setBeAddBuffId(int beAddBuffId) {
		this.beAddBuffId = beAddBuffId;
	}

	public int getTargetSp() {
		return targetSp;
	}

	public void setTargetSp(int targetSp) {
		this.targetSp = targetSp;
	}

	public int getUsedItemIndex() {
		return usedItemIndex;
	}

	public void setUsedItemIndex(int usedItemIndex) {
		this.usedItemIndex = usedItemIndex;
	}

	public boolean isBuffAntiSkill() {
		return buffAntiSkill;
	}

	public void setBuffAntiSkill(boolean buffAntiSkill) {
		this.buffAntiSkill = buffAntiSkill;
	}

	public boolean isAntiBuff() {
		return antiBuff;
	}

	public void setAntiBuff(boolean antiBuff) {
		this.antiBuff = antiBuff;
	}

	public BattleBuffEntity getTargetBuff() {
		return targetBuff;
	}

	public void setTargetBuff(BattleBuffEntity targetBuff) {
		this.targetBuff = targetBuff;
	}

	public float getDefenseDamageRate() {
		return defenseDamageRate;
	}

	public void setDefenseDamageRate(float defenseDamageRate) {
		this.defenseDamageRate = defenseDamageRate;
	}

	public float getDrugEffectRate() {
		return drugEffectRate;
	}

	public void setDrugEffectRate(float drugEffectRate) {
		this.drugEffectRate = drugEffectRate;
	}

	public float getRetreatSuccessRate() {
		return retreatSuccessRate;
	}

	public void setRetreatSuccessRate(float retreatSuccessRate) {
		this.retreatSuccessRate = retreatSuccessRate;
	}

	public boolean isAutoEscapeable() {
		return autoEscapeable;
	}

	public void setAutoEscapeable(boolean autoEscapeable) {
		this.autoEscapeable = autoEscapeable;
	}

	public Set<Long> getTargetIds() {
		return targetIds;
	}

	public void setTargetIds(Set<Long> targetIds) {
		this.targetIds = targetIds;
	}

	public boolean debugEnable() {
		return this.battle().battleRoundProcessor().debugEnable();
	}

	public PersistPlayerPet getCachedBattlePet() {
		return cachedBattlePet;
	}

	public void setCachedBattlePet(PersistPlayerPet cachedBattlePet) {
		this.cachedBattlePet = cachedBattlePet;
	}

	public PlayerTeamStatus getRetreatTeamStatus() {
		return retreatTeamStatus;
	}

	public void setRetreatTeamStatus(PlayerTeamStatus retreatTeamStatus) {
		this.retreatTeamStatus = retreatTeamStatus;
	}

	public float getCritRatePlus() {
		return critRatePlus;
	}

	public void setCritRatePlus(float critRatePlus) {
		this.critRatePlus = critRatePlus;
	}

	public float getBeBuffRate() {
		return beBuffRate;
	}

	public void setBeBuffRate(float beBuffRate) {
		this.beBuffRate = beBuffRate;
	}

	public BattleSoldier getFirstTarget() {
		return firstTarget;
	}

	public void setFirstTarget(BattleSoldier firstTarget) {
		this.firstTarget = firstTarget;
	}

	public boolean ifFirstTarget(BattleSoldier battleSoldier) {
		if (this.firstTarget == null)
			return false;
		return battleSoldier.getId() == this.firstTarget.getId();
	}

	public float getPerAttackVaryRate() {
		return perAttackVaryRate;
	}

	public void setPerAttackVaryRate(float perAttackVaryRate) {
		this.perAttackVaryRate = perAttackVaryRate;
	}

	public void randomPerAttackRate() {
		Battle battle = this.battle();
		float min = this.skill.getSkillAttackType() == SkillAttackType.Magic.ordinal() ? battle.battleMinMagicAttackFloatRange() : battle.battleMinAttackFloatRange();
		float max = this.skill.getSkillAttackType() == SkillAttackType.Magic.ordinal() ? battle.battleMaxMagicAttackFloatRange() : battle.battleMaxAttackFloatRange();
		int rndInt = RandomUtils.nextInt((int) (min * 100), (int) (max * 100));
		this.perAttackVaryRate = rndInt / 100.f;
	}

	public Props getProps() {
		return props;
	}

	public void setProps(Props props) {
		this.props = props;
	}

	public float getCritHurtRate() {
		return critHurtRate;
	}

	public void setCritHurtRate(float critHurtRate) {
		this.critHurtRate = critHurtRate;
	}

	public long getTotalHpVaryAmount() {
		return totalHpVaryAmount;
	}

	public void setTotalHpVaryAmount(long totalHpVaryAmount) {
		this.totalHpVaryAmount = totalHpVaryAmount;
	}

	public void addHpVaryAmount(int hp) {
		this.totalHpVaryAmount += hp;
	}

	public boolean isDeadStrokeBack() {
		return deadStrokeBack;
	}

	public void setDeadStrokeBack(boolean deadStrokeBack) {
		this.deadStrokeBack = deadStrokeBack;
	}

	public int getMinFireHp() {
		return minFireHp;
	}

	public void setMinFireHp(int minFireHp) {
		this.minFireHp = minFireHp;
	}

	public int getMaxFireHp() {
		return maxFireHp;
	}

	public void setMaxFireHp(int maxFireHp) {
		this.maxFireHp = maxFireHp;
	}

	public PersistPlayerChild getCachedBattleChild() {
		return cachedBattleChild;
	}

	public void setCachedBattleChild(PersistPlayerChild cachedBattleChild) {
		this.cachedBattleChild = cachedBattleChild;
	}

	public int getCritDamageOutput() {
		return critDamageOutput;
	}

	public void setCritDamageOutput(int critDamageOutput) {
		this.critDamageOutput = critDamageOutput;
	}

	public float getProtectorDefenseDamageRate() {
		return protectorDefenseDamageRate;
	}

	public void setProtectorDefenseDamageRate(float protectorDefenseDamageRate) {
		this.protectorDefenseDamageRate = protectorDefenseDamageRate;
	}

	public Map<String, Object> getMateData() {
		return mateData;
	}

	public void setMateData(Map<String, Object> mateData) {
		this.mateData = mateData;
	}

	public int getComboIndex() {
		return comboIndex;
	}

	public void setComboIndex(int comboIndex) {
		this.comboIndex = comboIndex;
	}

	public List<SkillTargetPolicy> getComboTargetPolicys() {
		return comboTargetPolicys;
	}

	public void setComboTargetPolicys(List<SkillTargetPolicy> comboTargetPolicys) {
		this.comboTargetPolicys = comboTargetPolicys;
	}

	public void clearComboTargetPolicys() {
		this.comboTargetPolicys.clear();
	}

	public List<SkillTargetPolicy> getTargetPolicys() {
		return targetPolicys;
	}

	public void setTargetPolicys(List<SkillTargetPolicy> targetPolicys) {
		this.targetPolicys = targetPolicys;
	}
}
