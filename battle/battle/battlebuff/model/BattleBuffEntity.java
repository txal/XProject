package com.nucleus.logic.core.modules.battlebuff.model;

import java.beans.Transient;
import java.util.HashMap;
import java.util.List;
import java.util.Map;
import java.util.Set;

import com.nucleus.commons.data.StaticConfig;
import com.nucleus.commons.utils.RandomUtils;
import com.nucleus.logic.core.modules.AppStaticConfigs;
import com.nucleus.logic.core.modules.battle.BattleUtils;
import com.nucleus.logic.core.modules.battle.dto.VideoActionTargetState;
import com.nucleus.logic.core.modules.battle.dto.VideoBuffRemoveTargetState;
import com.nucleus.logic.core.modules.battle.dto.VideoRoundAction;
import com.nucleus.logic.core.modules.battle.model.BattleSoldier;
import com.nucleus.logic.core.modules.battle.model.CommandContext;
import com.nucleus.logic.core.modules.battlebuff.IBattleBuffLogic;
import com.nucleus.logic.core.modules.battlebuff.data.BattleBuff;
import com.nucleus.logic.core.modules.battlebuff.data.BattleBuff.BattleBasePropertyType;
import com.nucleus.logic.core.modules.faction.data.Faction;
import com.nucleus.logic.core.modules.faction.logic.FactionBattleLogicParam;
import com.nucleus.logic.core.modules.faction.logic.FactionBattleLogicParam_2;
import com.nucleus.logic.core.modules.spell.ISpellEffectCalculator;
import com.nucleus.logic.core.modules.spell.data.Spell.SpellPropertyEffect;

/**
 * buff实体
 * 
 * @author liguo
 * 
 */
public class BattleBuffEntity {

	/** 所属技能编号 */
	private int skillId;

	/** 当前buff回合剩余数 */
	private int buffPersistRound;

	/** 所有buff作用回合数 */
	private int buffEffectTimes;

	/** 战斗buff数据 */
	private BattleBuff battleBuff;

	/** 基础buff列表 */
	private List<BattleBuffContext> buffContexts;

	/** buff施放者 */
	private BattleSoldier triggerSoldier;

	/** buff受影响者 */
	private BattleSoldier effectSoldier;

	/** buff效果值 */
	private int buffEffectValue;
	/**
	 * 默认情况下反击buff可以反击配置为“可反击”的技能,如果需要特别反击某些特定技能,则将技能保存在该集合内,非反击buff该集合为空
	 */
	private Set<Integer> strikeBackSkillIds;

	/** 中buff时的伤害值 */
	private int hitDamageInput;

	/** 战斗中使用的临时信息 */
	private Map<String, Object> battleMeta = new HashMap<>();

	public BattleBuffEntity(BattleBuff battleBuff, CommandContext commandContext, BattleSoldier effectSoldier, int persistRound) {
		BattleSoldier triggerSoldier = commandContext.trigger();
		this.setBuffPersistRound(persistRound);
		this.battleBuff = battleBuff;
		this.skillId = commandContext.skill().getId();
		this.buffContexts = battleBuff.battleBuffContexts();
		this.setTriggerSoldier(triggerSoldier);
		this.setEffectSoldier(effectSoldier);
		// // 记录本次伤害
		int damageOutput = commandContext.getDamageOutput();
		if (damageOutput < 0)
			this.hitDamageInput = Math.abs(damageOutput);
	}

	public BattleBuffEntity(BattleBuff buff, BattleSoldier trigger, BattleSoldier effectSoldier, int skillId, int persistRound) {
		this.battleBuff = buff;
		this.skillId = skillId;
		this.buffContexts = buff.battleBuffContexts();
		this.triggerSoldier = trigger;
		this.effectSoldier = effectSoldier;
		this.buffPersistRound = persistRound;
	}

	public BattleBuffEntity(BattleBuff buff, CommandContext commandContext, List<BattleBuffContext> buffContexts, int persistRound) {
		this.battleBuff = buff;
		this.triggerSoldier = commandContext.trigger();
		this.effectSoldier = commandContext.target();
		this.skillId = commandContext.skill().getId();
		this.buffContexts = buffContexts;
		this.buffPersistRound = persistRound;
	}

	public BattleBuffEntity(BattleBuff buff, BattleSoldier trigger, BattleSoldier effectSoldier, int skillId, int persistRound, List<BattleBuffContext> buffContext) {
		this.battleBuff = buff;
		this.triggerSoldier = trigger;
		this.effectSoldier = effectSoldier;
		this.skillId = skillId;
		this.buffPersistRound = persistRound;
		this.buffContexts = buffContext;
	}

	public int skillId() {
		return this.skillId;
	}

	public BattleBuff battleBuff() {
		return this.battleBuff;
	}

	public int battleBuffId() {
		return this.battleBuff.getId();
	}

	public int battleBuffType() {
		return this.battleBuff.getBuffType();
	}

	public void reduceBuffRound() {
		this.setBuffPersistRound(this.getBuffPersistRound() - 1);
		if (this.getBuffPersistRound() <= 0 || buffRemoveCheck()) {
			removeBuff();
			this.effectSoldier.currentVideoRound().endAction().addTargetState(new VideoBuffRemoveTargetState(this.effectSoldier, this.battleBuffId()));
		}
	}

	private boolean buffRemoveCheck() {
		if (this.battleBuff.getBuffClassType() != BattleBuff.BuffClassTypeEnum.Ban.ordinal())
			return false;
		if (this.effectSoldier != null && !this.effectSoldier.ifChild()) {
			Faction faction = this.effectSoldier.faction();
			if (faction != null) {
				FactionBattleLogicParam param = faction.getFactionBattleLogicParam();
				if (param != null && (param instanceof FactionBattleLogicParam_2)) {
					FactionBattleLogicParam_2 p = (FactionBattleLogicParam_2) param;
					return RandomUtils.baseRandomHit(p.getUnbanRate());
				}
			}
		}
		return false;
	}

	@Transient
	public boolean isBanBuff() {
		return this.battleBuff.getBuffClassType() == BattleBuff.BuffClassTypeEnum.Ban.ordinal();
	}

	public void fastRemoveBuff() {
		VideoBuffRemoveTargetState targetState = new VideoBuffRemoveTargetState(effectSoldier, this.battleBuff.getId());
		effectSoldier.currentVideoRound().getReadyAction().addTargetState(targetState);
		removeBuff();
	}

	public void reduceEffectTimes() {
		this.setBuffEffectTimes(this.getBuffEffectTimes() - 1);
		if (this.getBuffEffectTimes() < 0) {
			removeBuff();
		}
	}

	public void removeBuff() {
		int battleBuffId = battleBuffId();
		this.effectSoldier.buffHolder().removeBuffById(battleBuffId);
		IBattleBuffLogic logic = this.battleBuff().buffLogic();
		if (logic != null)
			logic.onRemove(this);
	}

	/**
	 * 执行回合开始buff
	 * 
	 * @return
	 */
	public void executeRoundStartBuff() {
		if (this.battleBuff.isForDead() == this.effectSoldier.isDead()) {
			IBattleBuffLogic logic = this.battleBuff.buffLogic();
			if (logic != null) {
				logic.onRoundStart(this);
			} else
				this.executeRoundBuff(effectSoldier.currentVideoRound().readyAction());
		}
	}

	/**
	 * 执行回合结束buff
	 */
	public void executeRoundEndBuff() {
		IBattleBuffLogic logic = this.battleBuff.buffLogic();
		if (logic != null)
			logic.onRoundEnd(this);
		this.executeRoundBuff(effectSoldier.currentVideoRound().endAction());
	}

	/**
	 * 获得buff 之后生效
	 */
	public void effectWhenGetBuff() {
		IBattleBuffLogic logic = this.battleBuff.buffLogic();
		if (logic != null)
			logic.afterGetBuff(this);
	}

	private void executeRoundBuff(VideoRoundAction roundAction) {
		float enchanceEffect = this.effectSoldier.buffHolder().baseEffects(BattleBasePropertyType.HpBuffEffectEnhance);
		boolean preventHeal = this.effectSoldier.buffHolder().hasPreventHealBuff();
		for (int i = 0; i < buffContexts.size(); i++) {
			BattleBuffContext buffContext = buffContexts.get(i);
			BattleBasePropertyType battleBasePropertyType = buffContext.battleBasePropertyType();

			int buffEffectValue = 0;
			if (battleBasePropertyType == BattleBasePropertyType.Hp) {
				// buff的原始回血效果
				float originalValue = BattleUtils.calculateBaseEffect(this, buffContext);
				// 修炼治疗效果加成
				buffEffectValue = (int) casterSpellHealEffect(originalValue);
				buffEffectValue *= (1 + enchanceEffect);
				if (buffEffectValue > 0 && preventHeal)
					buffEffectValue = 0;

				// 因为后续可能会有复活动作，避免出现先复活然后再扣血，因此先加扣血动作
				VideoActionTargetState state = new VideoActionTargetState(effectSoldier, buffEffectValue, 0, false);
				roundAction.addTargetState(state);
				if (buffEffectValue < 0) {
					// 预计会死
					boolean willDie = effectSoldier.hp() + buffEffectValue <= 0;
					state.setDead(willDie);
					effectSoldier.decreaseHp(buffEffectValue);
					state.setLeave(effectSoldier.isLeave());
				} else {
					effectSoldier.increaseHp(buffEffectValue);
				}
			} else if (battleBasePropertyType == BattleBasePropertyType.Mp) {
				buffEffectValue = (int) BattleUtils.calculateBaseEffect(this, buffContext);
				if (buffEffectValue < 0) {
					effectSoldier.decreaseMp(buffEffectValue);
				} else {
					effectSoldier.increaseMp(buffEffectValue);
				}
				roundAction.addTargetState(new VideoActionTargetState(effectSoldier, 0, buffEffectValue, false));
			} else if (battleBasePropertyType == BattleBasePropertyType.Sp) {
				buffEffectValue = (int) BattleUtils.calculateBaseEffect(this, buffContext);
				if (buffEffectValue > 0)
					effectSoldier.increaseSp(buffEffectValue);
				else
					effectSoldier.decreaseSp(buffEffectValue);
				roundAction.addTargetState(new VideoActionTargetState(effectSoldier, 0, 0, false, buffEffectValue));
			} else if (battleBasePropertyType == BattleBasePropertyType.MaxHp) {
				float rate = BattleUtils.calculateBaseEffect(this, buffContext);
				if (!getBattleMeta().isEmpty() && getBattleMeta().containsKey("maxHp"))
					return;

				// 当前属性
				int curMaxHp = effectSoldier.maxHp();
				float curHpRate = effectSoldier.hpRate();
				// 影响后属性
				int afterMaxHp = (int) Math.floor(curMaxHp * rate);
				int afterHp = (int) Math.floor(afterMaxHp * curHpRate);
				effectSoldier.battleBaseProperties().setMaxHp(afterMaxHp);
				effectSoldier.battleBaseProperties().setHp(afterHp);
				// 记录原气血上限
				getBattleMeta().put("maxHp", curMaxHp);
				buffEffectValue = curMaxHp - afterMaxHp;

				roundAction.addTargetState(new VideoActionTargetState(effectSoldier, 0, 0, false, 0, 0, buffEffectValue));
			}
			this.setBuffEffectValue(buffEffectValue);
		}
	}

	/**
	 * 施放者修炼技能 治疗加成
	 * 
	 * @param originalValue
	 * @return
	 */
	public float casterSpellHealEffect(float originalValue) {
		if (originalValue <= 0) {
			return originalValue;
		}
		ISpellEffectCalculator calculator = triggerSoldier.spellEffectCalculator();
		float finalValue = calculator.calcSpellEffect(triggerSoldier, SpellPropertyEffect.HealIncrease, originalValue);
		return finalValue;
	}

	public float basePropertyEffect(BattleBasePropertyType battleBasePropertyType) {
		float effectValue = 0;
		for (int i = 0; i < buffContexts.size(); i++) {
			BattleBuffContext buffContext = buffContexts.get(i);
			if (battleBasePropertyType == buffContext.battleBasePropertyType()) {
				effectValue += BattleUtils.calculateBaseEffect(this, buffContext);
				continue;
			}
		}
		return effectValue;
	}

	public BattleSoldier getTriggerSoldier() {
		return triggerSoldier;
	}

	public void setTriggerSoldier(BattleSoldier triggerSoldier) {
		this.triggerSoldier = triggerSoldier;
	}

	public BattleSoldier getEffectSoldier() {
		return effectSoldier;
	}

	public void setEffectSoldier(BattleSoldier effectSoldier) {
		this.effectSoldier = effectSoldier;
	}

	public int getBuffPersistRound() {
		return buffPersistRound;
	}

	public void setBuffPersistRound(int buffPersistRound) {
		this.buffPersistRound = buffPersistRound;
	}

	public int getBuffEffectValue() {
		return buffEffectValue;
	}

	public void setBuffEffectValue(int buffEffectValue) {
		this.buffEffectValue = buffEffectValue;
	}

	public int getBuffEffectTimes() {
		return buffEffectTimes;
	}

	public void setBuffEffectTimes(int buffEffectTimes) {
		this.buffEffectTimes = buffEffectTimes;
	}

	public Set<Integer> getStrikeBackSkillIds() {
		return strikeBackSkillIds;
	}

	public void setStrikeBackSkillIds(Set<Integer> strikeBackSkillIds) {
		this.strikeBackSkillIds = strikeBackSkillIds;
	}

	public List<BattleBuffContext> getBuffContexts() {
		return buffContexts;
	}

	public void setBuffContexts(List<BattleBuffContext> buffContexts) {
		this.buffContexts = buffContexts;
	}

	public void increaseBuffEffectValue(int buffEffectValue) {
		int maxValue = StaticConfig.get(AppStaticConfigs.DRUG_RESISTANT_MAX_VALUE).getAsInt(30);
		this.buffEffectValue = (this.buffEffectValue + buffEffectValue) > maxValue ? maxValue : (this.buffEffectValue + buffEffectValue);
	}

	public void decreaseBuffEffectValue(int buffEffectValue) {
		int minValue = StaticConfig.get(AppStaticConfigs.DRUG_RESISTANT_MIN_VALUE).getAsInt(0);
		this.buffEffectValue = (this.buffEffectValue - buffEffectValue) < minValue ? minValue : (this.buffEffectValue - buffEffectValue);
	}

	public int hitDamageInput() {
		return hitDamageInput;
	}

	public Map<String, Object> getBattleMeta() {
		if (this.battleMeta == null) {
			this.battleMeta = new HashMap<>();
		}
		return battleMeta;
	}

	public void setBattleMeta(Map<String, Object> battleMeta) {
		this.battleMeta = battleMeta;
		if (this.battleMeta == null) {
			this.battleMeta = new HashMap<>();
		}
	}
}
