package com.nucleus.logic.core.modules.battle.logic;

import java.util.HashMap;
import java.util.Map;

import org.apache.commons.lang3.StringUtils;
import org.springframework.stereotype.Service;

import com.nucleus.commons.utils.SplitUtils;
import com.nucleus.logic.core.modules.battle.BattleUtils;
import com.nucleus.logic.core.modules.battle.data.Skill;
import com.nucleus.logic.core.modules.battle.model.BattleSoldier;
import com.nucleus.logic.core.modules.battle.model.CommandContext;

/**
 * 目标为傀儡生物
 * 
 * @author wangyu
 *
 */
@Service
public class SkillLogic_19 extends SkillLogic_1 {

	@Override
	protected int calculateHp(BattleSoldier trigger, Skill skill, BattleSoldier target, CommandContext commandContext, float damageVaryRate, float massDamageRate, boolean success) {
		if (StringUtils.isBlank(skill.getTargetSuccessHpEffect()) && StringUtils.isBlank(skill.getTargetFailureHpEffect())) {
			return 0;
		}

		int hpFromFormula = 0;
		Map<String, Object> paramMap = populateParam(skill.getLogicParam(), trigger);
		if (success) {
			hpFromFormula = BattleUtils.skillEffect(commandContext, target, skill.getTargetSuccessHpEffect(), paramMap);
		} else {
			hpFromFormula = BattleUtils.skillEffect(commandContext, target, skill.getTargetFailureHpEffect(), paramMap);
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

	@Override
	protected int calculateMp(BattleSoldier trigger, Skill skill, BattleSoldier target, CommandContext commandContext, boolean success) {
		if (StringUtils.isBlank(skill.getTargetSuccessMpEffect()) && StringUtils.isBlank(skill.getTargetFailureMpEffect()))
			return 0;
		int mpFromFormula = 0;
		Map<String, Object> paramMap = populateParam(skill.getLogicParam(), trigger);
		paramMap.put("damageOutput", commandContext.getDamageOutput());

		if (success) {
			mpFromFormula = BattleUtils.skillEffect(commandContext, target, skill.getTargetSuccessMpEffect(), paramMap);
		} else {
			mpFromFormula = BattleUtils.skillEffect(commandContext, target, skill.getTargetFailureMpEffect(), paramMap);
		}
		return mpFromFormula;
	}

	private Map<String, Object> populateParam(String paramStr, BattleSoldier trigger) {
		Map<String, Object> params = new HashMap<String, Object>();
		if (StringUtils.isBlank(paramStr)) {
			return params;
		}
		Map<String, String> param = SplitUtils.split2StringMap(paramStr, ",", ":");
		String skillIdStr = param.get("skillId");
		int skillLevel = 0;
		if (skillIdStr != null) {
			skillLevel = trigger.skillLevel(Integer.parseInt(skillIdStr));
		}
		params.put("skillLevel", skillLevel);
		return params;
	}
}
