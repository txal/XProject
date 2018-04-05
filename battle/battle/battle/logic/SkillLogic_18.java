package com.nucleus.logic.core.modules.battle.logic;

import java.util.Iterator;
import java.util.Map;

import org.apache.commons.lang3.StringUtils;
import org.springframework.stereotype.Service;

import com.nucleus.commons.utils.RandomUtils;
import com.nucleus.commons.utils.SplitUtils;
import com.nucleus.logic.core.modules.battle.BattleUtils;
import com.nucleus.logic.core.modules.battle.data.Skill;
import com.nucleus.logic.core.modules.battle.model.BattleSoldier;
import com.nucleus.logic.core.modules.battle.model.CommandContext;

/**
 * 多种概率触发多种效果
 * 
 * @author wangyu
 *
 */
@Service
public class SkillLogic_18 extends SkillLogic_1 {

	@Override
	protected int calculateHp(BattleSoldier trigger, Skill skill, BattleSoldier target, CommandContext commandContext, float damageVaryRate, float massDamageRate, boolean success) {
		if (StringUtils.isBlank(skill.getTargetSuccessHpEffect())) {
			return 0;
		}
		String param = skill.getLogicParam();
		if (param == null || "".equals(param)) {
			return 0;
		}
		Map<Integer, Integer> rates = SplitUtils.split2IntMap(param, ",", ":");
		double num = 1.0;
		int base = 0;
		boolean temp = false;
		int random = RandomUtils.nextInt(100);
		for (Iterator<Integer> iter = rates.keySet().iterator(); iter.hasNext();) {
			int rate = iter.next();
			if (random >= base && random < base + rate) {
				temp = true;
			}
			if (temp) {
				num = rates.get(rate) / 100.0;
				break;
			}
			base += rate;
		}
		int damage = BattleUtils.skillEffect(commandContext, target, skill.getTargetSuccessHpEffect(), null);
		int hpFromFormula = (int) (damage * num);
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

}
