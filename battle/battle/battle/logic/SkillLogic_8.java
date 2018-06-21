package com.nucleus.logic.core.modules.battle.logic;

import org.springframework.stereotype.Service;

import com.nucleus.logic.core.modules.battle.BattleUtils;
import com.nucleus.logic.core.modules.battle.data.Skill;
import com.nucleus.logic.core.modules.battle.model.BattleSoldier;
import com.nucleus.logic.core.modules.battle.model.CommandContext;

/**
 * 两种攻击方案候选特殊处理逻辑
 * 
 * @author wgy
 *
 */
@Service
public class SkillLogic_8 extends SkillLogic_1 {
	@Override
	protected int calculateHp(BattleSoldier trigger, Skill skill, BattleSoldier target, CommandContext commandContext, float damageVaryRate, float massDamageRate, boolean success) {
		// 比较两种方案,取伤害值大的一种
		// 方案1计算固定伤害,附加普通怪物加成
		int hp1 = BattleUtils.skillEffect(commandContext, target, skill.getTargetSuccessHpEffect(), null);
		hp1 *= damageVaryRate;
		hp1 = monsterTypeVary(commandContext, target, hp1);
		// 方案2附加群伤规则
		int hp2 = BattleUtils.skillEffect(commandContext, target, skill.getTargetPlusHpEffect(), null);
		hp2 *= damageVaryRate * massDamageRate;
		// 因为后续的规则都一致,所以比较基础值即可
		int hp = hp1;
		if (Math.abs(hp2) > Math.abs(hp1))
			hp = hp2;
		int hpVaryAmount = calculateHpVaryAmount(commandContext, target, hp);
		return hpVaryAmount;
	}
}
