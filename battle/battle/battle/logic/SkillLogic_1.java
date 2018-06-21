/**
 * 
 */
package com.nucleus.logic.core.modules.battle.logic;

import java.util.ArrayList;
import java.util.HashMap;
import java.util.List;
import java.util.Map;

import org.apache.commons.lang3.StringUtils;
import org.springframework.stereotype.Service;

import com.nucleus.commons.utils.RandomUtils;
import com.nucleus.logic.core.modules.battle.BattleUtils;
import com.nucleus.logic.core.modules.battle.data.PassiveSkillLaunchTimingEnum;
import com.nucleus.logic.core.modules.battle.data.Skill;
import com.nucleus.logic.core.modules.battle.data.SkillMassDamageRule;
import com.nucleus.logic.core.modules.battle.dto.VideoActionTargetState;
import com.nucleus.logic.core.modules.battle.dto.VideoDodgeTargetState;
import com.nucleus.logic.core.modules.battle.dto.VideoTargetStateGroup;
import com.nucleus.logic.core.modules.battle.model.BattleSoldier;
import com.nucleus.logic.core.modules.battle.model.CommandContext;
import com.nucleus.logic.core.modules.battlebuff.data.BattleBuff.BattleBasePropertyType;
import com.nucleus.logic.core.modules.battlebuff.model.BattleBuffEntity;
import com.nucleus.logic.core.modules.charactor.data.ShoutConfig;
import com.nucleus.logic.whole.modules.system.manager.GameServerManager;
import com.nucleus.player.service.ScriptService;

/**
 * 普攻/法术/特技
 * 
 * @author liguo
 * 
 */
@Service
public class SkillLogic_1 extends SkillLogicAdapter {

	@Override
	public void doFired(CommandContext commandContext) {
		preFired(commandContext);
		final boolean debugEnable = commandContext.debugEnable();
		BattleSoldier trigger = commandContext.trigger();
		Skill skill = commandContext.skill();
		if (skill.getSelfNextRoundForceSkillId() > 0) {
			trigger.initForceSkill(skill.getSelfNextRoundForceSkillId());
			trigger.setForceTarget(commandContext.target());
		}

		SkillAiLogic skillAiLogic = skill.skillAi().skillAiLogic();

		List<SkillTargetPolicy> targetPolicys = new ArrayList<>();
		if (commandContext.isCombo() && !commandContext.getComboTargetPolicys().isEmpty())
			targetPolicys.addAll(commandContext.getComboTargetPolicys());
		else
			targetPolicys.addAll(skillAiLogic.selectTargets(commandContext));
		if (targetPolicys.isEmpty())
			return;
		BattleSoldier targetSelected = commandContext.target() != null ? commandContext.target() : targetPolicys.get(0).getTarget();
		commandContext.setFirstTarget(targetSelected);
		// 如果是手动选择目标，此处会已经有了target，而且在手动选择的时候已经触发过该被动，不重复触发
		if (commandContext.target() == null)
			trigger.skillHolder().passiveSkillEffectByTiming(targetSelected, commandContext, PassiveSkillLaunchTimingEnum.AfterSeleFirstTarget);
		afterTargetSelected(commandContext, targetPolicys, targetSelected);
		float massDamgeRate = 1F;
		if (skill.isUseSkillMassRule()) {
			SkillMassDamageRule massDamageInfo = SkillMassDamageRule.get(targetPolicys.size());
			if (null != massDamageInfo) {
				massDamgeRate = massDamageInfo.getDamageRate();
			}
		}
		if (Skill.SkillActionTypeEnum.Attack.ordinal() == skill.getSkillActionType() || Skill.SkillActionTypeEnum.Seal.ordinal() == skill.getSkillActionType())
			trigger.shout(ShoutConfig.BattleShoutTypeEnum.Attack, commandContext);
		commandContext.updateTotalAttackCount(0);
		commandContext.randomPerAttackRate();
		for (SkillTargetPolicy tp : targetPolicys) {
			SkillTargetInfo policy = tp.getPolicy();
			commandContext.setCurAttackVaryRate(policy.getAttackVaryRate());
			if (debugEnable)
				commandContext.initDebugInfo(trigger, skill, tp.getTarget());
			BattleSoldier target = tp.getTarget();
			float damageVaryRate = policy.getDamageVaryRate();
			if (attack(commandContext, target, damageVaryRate, massDamgeRate)) {
				trigger.skillHolder().passiveSkillEffectByTiming(target, commandContext, PassiveSkillLaunchTimingEnum.SingleAttackEnd);
				// 追击特殊处理
				trigger.skillHolder().passiveSkillEffectByTiming(target, commandContext, PassiveSkillLaunchTimingEnum.PursueAttack);
			}
		}
		// 记录攻击过的目标
		commandContext.setTargetPolicys(targetPolicys);
		trigger.skillHolder().passiveSkillEffectByTiming(commandContext.target(), commandContext, PassiveSkillLaunchTimingEnum.PlusAttack);
		if (commandContext.totalAttackCount() > 0 && skill.isAtOnce())
			commandContext.updateTotalAttackCount(1);
		trigger.addAttackTimes(commandContext.totalAttackCount(), skill.ifMagicAttack());
	}

	protected void afterTargetSelected(CommandContext commandContext, List<SkillTargetPolicy> targetPolicys, BattleSoldier targetSelected) {
	}

	protected void preFired(CommandContext commandContext) {
	}

	public boolean attack(CommandContext commandContext, BattleSoldier target, float damageVaryRate, float massDamageRate) {
		boolean isValidAttack = false;
		Skill skill = commandContext.skill();
		if (null == target) {
			return isValidAttack;
		}
		boolean targetDead = target.isDead();
		if (!skill.isDeadTriggerSkill()) {
			if (targetDead == skill.isUseAliveTarget())
				return isValidAttack;
		}
		if (targetDead && !skill.isUseAliveTarget() && target.isGhost() && !commandContext.isEffectGhost())
			return isValidAttack;// 不能复活鬼魂
		BattleSoldier trigger = commandContext.trigger();
		if (trigger.isDead() && !commandContext.isDeadStrokeBack()) {
			return isValidAttack;
		}
		commandContext.skillAction().addTargetStateGroup(new VideoTargetStateGroup());
		isValidAttack = true;
		commandContext.addAttackCount(1);
		commandContext.getTargetIds().add(target.getId());
		target.skillHolder().passiveSkillEffectByTiming(target, commandContext, PassiveSkillLaunchTimingEnum.BefroeBeAttacked);
		if (target.isFirstBeAttacked()) {
			target.setFirstBeAttacked(false);
		}
		if (!hit(commandContext, target)) {
			VideoDodgeTargetState dodgeTargetState = new VideoDodgeTargetState(target);
			commandContext.skillAction().addTargetState(dodgeTargetState);
			return isValidAttack;
		}
		boolean success = true;
		if (StringUtils.isNotBlank(skill.getSuccessRateFormula())) {
			float successRate = BattleUtils.skillRate(trigger, skill, target);
			success = RandomUtils.baseRandomHit(successRate);
		}
		boolean lowGhost = target.isLowGhost();
		// 被动技能影响攻击变动率:commandContext.getCurAttackVaryRate()
		trigger.skillHolder().passiveSkillEffectByTiming(target, commandContext, PassiveSkillLaunchTimingEnum.BeforeAttack);
		int hpVaryAmount = calculateHp(trigger, skill, target, commandContext, damageVaryRate, massDamageRate, success); // 公式解析计算得到的值
		int spVaryAmount = calculateSp(trigger, target, commandContext, success);
		final boolean debugEnable = commandContext.debugEnable();
		if (debugEnable)
			commandContext.debugInfo().setHurtRate(damageVaryRate * massDamageRate);
		if (hpVaryAmount > 0) {
			// 天赋被动会使得某些治疗技能对傀儡有效，所以加一重限定
			if (target.preventHeal(skill.targetRemoveBuffTypes()) && !commandContext.isEffectGhost())
				hpVaryAmount = 0;
			else {
				commandContext.setDamageOutput(hpVaryAmount);
				boolean preventRelive = isPreventRelive(target, commandContext);// 是否阻止复活
				if (!preventRelive) {
					trigger.skillHolder().passiveSkillEffectByTiming(target, commandContext, PassiveSkillLaunchTimingEnum.HealOutput);// 治疗增益
					target.skillHolder().passiveSkillEffectByTiming(trigger, commandContext, PassiveSkillLaunchTimingEnum.Heal);
					hpVaryAmount = commandContext.getDamageOutput();
					hpVaryAmount = target.increaseHp(commandContext, hpVaryAmount);
					if (targetDead && !target.isDead()) {
						trigger.skillHolder().passiveSkillEffectByTiming(target, commandContext, PassiveSkillLaunchTimingEnum.AfterReviveTarget);
						target.skillHolder().passiveSkillEffectByTiming(target, commandContext, PassiveSkillLaunchTimingEnum.BeRelived);
					}
				} else {
					hpVaryAmount = 0;
				}
			}
		} else if (hpVaryAmount < 0) {
			hpVaryAmount = target.decreaseHp(commandContext, hpVaryAmount);
			target.addBeAttackTimes(1, skill.ifMagicSkill());
			target.roundDamageInput(-hpVaryAmount);
			trigger.culMaxDamage(-hpVaryAmount);
		}
		commandContext.addHpVaryAmount(hpVaryAmount);
		boolean delayMpSuck = false;

		int mpVaryAmount = calculateMp(trigger, skill, target, commandContext, success);
		if (mpVaryAmount != 0) {
			if (debugEnable)
				commandContext.debugInfo().setMp(mpVaryAmount);
			if (mpVaryAmount > 0 && !lowGhost)
				target.increaseMp(commandContext, mpVaryAmount);
			else if (mpVaryAmount < 0) {
				target.decreaseMp(commandContext, mpVaryAmount);
				delayMpSuck = true;
			}
		}
		int sp = spVaryAmount + commandContext.getTargetSp();
		if (sp != 0 && !target.isDead()) {
			if (debugEnable)
				commandContext.debugInfo().setSp(sp);
			if (sp > 0)
				target.increaseSp(sp);
			else if (sp < 0)
				target.decreaseSp(sp);
		}
		// 目标受击之前判断是否被直接击飞
		trigger.skillHolder().passiveSkillEffectByTiming(target, commandContext, PassiveSkillLaunchTimingEnum.TargetBeforeUnderAttack);
		if (!commandContext.isBuffAntiSkill()) {
			commandContext.skillAction().addFirstTargetState(new VideoActionTargetState(target, hpVaryAmount, mpVaryAmount, commandContext.isCrit(), sp));
		} else {
			commandContext.setBuffAntiSkill(false);// 重置标记,避免群攻情况下影响其他目标
		}
		// if (target.isLeave())
		// return isValidAttack;// 目标击飞不再继续后续流程
		// 吸魔
		if (delayMpSuck) {
			SkillLogicAssist.getInstance().mpFromTarget2Trigger(commandContext, trigger, mpVaryAmount);
		}
		// 吸血
		if (!lowGhost) {
			SkillLogicAssist.getInstance().hpFromTarget2Trigger(commandContext, trigger, hpVaryAmount);
			// 被动技能:攻击吸血
			trigger.skillHolder().passiveSkillEffectByTiming(target, commandContext, PassiveSkillLaunchTimingEnum.AttackSuckHp);
		}
		// 自伤
		// 2016-08-10:自伤仅处理一次(特技'万物复苏')
		if (commandContext.totalAttackCount() < 2)
			selfHurt(trigger, commandContext);
		// 治疗队伍
		teamHpEffect(trigger, commandContext, hpVaryAmount);
		// 回复队伍魔法
		teamMpEffect(trigger, commandContext, mpVaryAmount);
		// 被动技能:受击吸血
		if (!lowGhost && !target.isLeave())
			target.skillHolder().passiveSkillEffectByTiming(trigger, commandContext, PassiveSkillLaunchTimingEnum.BeAttackSuckHp);
		if (debugEnable)
			commandContext.debugInfo().setTargetDead(target.isDead());
		if (target.isDead()) {
			addTargetBuffWhenDie(commandContext, target);
			// target.setSp(0);
			return isValidAttack;
		}
		trigger.skillHolder().passiveSkillEffectByTiming(target, commandContext, PassiveSkillLaunchTimingEnum.TargetAddBuff);
		final List<BattleBuffEntity> addBuffs = addTargetBuff(commandContext, target);
		removeTargetBuffs(commandContext, target);
		commandContext.battle().onBuffAdd(commandContext, trigger, target, addBuffs);
		target.underAttack(commandContext);
		return isValidAttack;
	}

	/**
	 * 伤敌自损
	 * 
	 * @param trigger
	 * @param commandContext
	 */
	private void selfHurt(BattleSoldier trigger, CommandContext commandContext) {
		Skill skill = commandContext.skill();
		if (StringUtils.isNotBlank(skill.getSelfSuccessHpEffectFormula())) {
			Map<String, Object> paramMap = new HashMap<>();
			paramMap.put("damageOutput", commandContext.getDamageOutput());
			paramMap.put("trigger", trigger);
			if (commandContext.target() != null)
				paramMap.put("target", commandContext.target());
			int hp = ScriptService.getInstance().calcuInt("SkillLogic_1.selfHurt skillId:" + skill.getId(), skill.getSelfSuccessHpEffectFormula(), paramMap, false);
			if (hp < 0) {
				// trigger.decreaseHp(commandContext, hp);
				// 2016-08-24:自伤直接减,不计算各类减伤(因为宠物技能'舍命一击'原始伤害输出会被自伤覆盖)
				trigger.decreaseHp(hp);
				commandContext.skillAction().addTargetState(new VideoActionTargetState(trigger, hp, 0, false));
			}
		}
	}

	/**
	 * 治疗己方队伍（仅限主人物和伙伴）
	 * 
	 * @param trigger
	 * @param commandContext
	 */
	private void teamHpEffect(BattleSoldier trigger, CommandContext commandContext, int damageOut) {
		Skill skill = commandContext.skill();
		if (StringUtils.isNotBlank(skill.getTeamSuccessHpEffectFormula()) && damageOut != 0) {
			boolean needCrit = skill.isNeedCrit();
			skill.setNeedCrit(true);
			Map<String, Object> paramMap = new HashMap<>();
			paramMap.put("damageOutput", damageOut);
			paramMap.put("skillLevel", trigger.skillLevel(skill.getId()));
			int hp = ScriptService.getInstance().calcuInt("SkillLogic_1.teamHpEffect", skill.getTeamSuccessHpEffectFormula(), paramMap, false);
			if (hp == 0)
				return;
			if (hp > 0) {
				commandContext.getMateData().put("team_add_hp", hp);
				trigger.skillHolder().passiveSkillEffectByTiming(commandContext.target(), commandContext, PassiveSkillLaunchTimingEnum.HealOutput);// 治疗增益
				hp = (Integer) commandContext.getMateData().getOrDefault("team_add_hp", 0);
				commandContext.getMateData().clear();
				float factor = trigger.propFloat(BattleBasePropertyType.HpBuffEffectEnhance);
				hp = (int) (hp * (1 + factor));
				hp = spellHealEffect(trigger, hp);
				int addHp = 0;
				for (BattleSoldier soldier : trigger.team().soldiersMap().values()) {
					boolean prevent = soldier.buffHolder().hasPreventHealBuff();
					if ((soldier.isMainCharactor() || soldier.ifCrew()) && !soldier.isDead() && !prevent) {
						addHp = critCal(commandContext, soldier, hp);
						soldier.increaseHp(addHp);
						commandContext.skillAction().addTargetState(new VideoActionTargetState(soldier, addHp, 0, commandContext.isCrit()));
					}
				}
			}
			skill.setNeedCrit(needCrit);
		}
	}

	/**
	 * 恢复队友mp量
	 * 
	 * @param trigger
	 * @param commandContext
	 * @param damageOut
	 */
	private void teamMpEffect(BattleSoldier trigger, CommandContext commandContext, int mpDamage) {
		Skill skill = commandContext.skill();
		if (StringUtils.isNotBlank(skill.getTeamSuccessMpEffectFormula()) && mpDamage != 0) {
			Map<String, Object> paramMap = new HashMap<>();
			paramMap.put("damageOutput", mpDamage);
			paramMap.put("skillLevel", trigger.skillLevel(skill.getId()));
			if (skill.getRelativeSkillId() != 0) {
				paramMap.put("skillLevel", trigger.skillLevel(skill.getRelativeSkillId()));
			}
			int mp = ScriptService.getInstance().calcuInt("SkillLogic_1.teamMpEffect", skill.getTeamSuccessMpEffectFormula(), paramMap, false);
			if (mp <= 0)
				return;
			List<BattleSoldier> soldiers = new ArrayList<>();
			for (BattleSoldier soldier : trigger.team().soldiersMap().values()) {
				if ((soldier.isMainCharactor() || soldier.ifCrew()) && !soldier.isDead())
					soldiers.add(soldier);
			}
			int addMp = mp / soldiers.size();
			if (addMp <= 0)
				return;
			soldiers.forEach(soldier -> {
				soldier.increaseMp(addMp);
				commandContext.skillAction().addTargetState(new VideoActionTargetState(soldier, 0, addMp, false));
			});
		}
	}

	private boolean isPreventRelive(BattleSoldier target, CommandContext context) {
		if (!target.isDead())
			return false;// 没死不阻止
		// 死了并且有阻止复活的buff
		if (target.isGhost() && !context.isEffectGhost())
			return true;
		return target.buffHolder().hasPreventReliveBuff();
	}

	protected int calculateHp(BattleSoldier trigger, Skill skill, BattleSoldier target, CommandContext commandContext, float damageVaryRate, float massDamageRate, boolean success) {
		if (StringUtils.isBlank(skill.getTargetSuccessHpEffect()) && StringUtils.isBlank(skill.getTargetFailureHpEffect()))
			return 0;
		int hpFromFormula = 0;
		Map<String, Object> params = commandContext.getMateData();
		String hpEffect = null;
		if (params != null && params.get("hpEffect") != null)
			hpEffect = (String) params.get("hpEffect");
		if (success) {
			// 天赋技能可以当目标为傀儡，就改变效果公式，吧效果公式放在metaData中，此处取出
			if (hpEffect != null)
				hpFromFormula = BattleUtils.skillEffect(commandContext, target, hpEffect, params);
			else
				hpFromFormula = BattleUtils.skillEffect(commandContext, target, skill.getTargetSuccessHpEffect(), params);
		} else {
			hpFromFormula = BattleUtils.skillEffect(commandContext, target, skill.getTargetFailureHpEffect(), params);
		}
		if (massDamageRate != 0) {
			damageVaryRate *= massDamageRate;
		}
		int hpVaryAmount = hpFromFormula;
		// 群伤规则
		if (hpVaryAmount < -1 || hpVaryAmount > 1) {
			hpVaryAmount = (int) (hpVaryAmount * damageVaryRate);
		}

		// 受击度
		// 攻击者伤害输出受自身受击度影响: 攻击者自身受击度越大,造成的伤害输出越小,此次攻击不改变攻击者自身受击度
		// 攻击者伤害输出=此次伤害*(1-攻击者受击度)；如果攻击方和受击方身上都有受击度，则相加计算
		// 每被攻击一次，受击度增加5%，最高10%
		double strikeRate = Math.min(0.1, trigger.strikeRate() + target.strikeRate());
		hpVaryAmount *= (1 - strikeRate);

		hpVaryAmount = calculateHpVaryAmount(commandContext, target, hpVaryAmount);
		// 普通怪加成
		hpVaryAmount = monsterTypeVary(commandContext, target, hpVaryAmount);
		// 夜间伤害变化
		hpVaryAmount = calculateNightDamageVary(commandContext, target, hpVaryAmount);

		return hpVaryAmount;
	}

	protected int calculateMp(BattleSoldier trigger, Skill skill, BattleSoldier target, CommandContext commandContext, boolean success) {
		int mpFromFormula = 0;
		Map<String, Object> paramMap = new HashMap<>();
		Map<String, Object> metaParam = commandContext.getMateData();
		if (metaParam != null && !metaParam.isEmpty()) {
			paramMap.putAll(metaParam);
		}
		paramMap.put("damageOutput", commandContext.getDamageOutput());
		String mpEffect = null;
		if (paramMap.get("mpEffect") != null)
			mpEffect = (String) paramMap.get("mpEffect");
		if (success) {
			if (mpEffect != null)
				mpFromFormula = BattleUtils.skillEffect(commandContext, target, mpEffect, paramMap);
			else
				mpFromFormula = BattleUtils.skillEffect(commandContext, target, skill.getTargetSuccessMpEffect(), paramMap);
		} else {
			mpFromFormula = BattleUtils.skillEffect(commandContext, target, skill.getTargetFailureMpEffect(), paramMap);
		}
		return mpFromFormula;
	}

	protected int calculateSp(BattleSoldier trigger, BattleSoldier target, CommandContext commandContext, boolean success) {
		if (StringUtils.isBlank(commandContext.skill().getTargetSuccessSpEffect()) && StringUtils.isBlank(commandContext.skill().getTargetFailureSpEffect()))
			return 0;
		int sp = 0;
		if (success)
			sp = BattleUtils.skillEffect(commandContext, target, commandContext.skill().getTargetSuccessSpEffect(), null);
		else
			sp = BattleUtils.skillEffect(commandContext, target, commandContext.skill().getTargetFailureSpEffect(), null);
		return sp;
	}

	protected int calculateNightDamageVary(CommandContext commandContext, BattleSoldier target, int hpVaryAmount) {
		if (!GameServerManager.getInstance().night())
			return hpVaryAmount;
		float rate = commandContext.skill().getNightDamageVaryRate();
		if (rate != 0)
			hpVaryAmount *= (1F + rate);
		return hpVaryAmount;
	}
}
