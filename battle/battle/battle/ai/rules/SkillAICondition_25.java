package com.nucleus.logic.core.modules.battle.ai.rules;

import org.apache.commons.lang3.math.NumberUtils;

import com.nucleus.commons.utils.SplitUtils;
import com.nucleus.logic.core.modules.battle.data.Skill;
import com.nucleus.logic.core.modules.battle.model.BattleSoldier;
import com.nucleus.logic.core.modules.battle.model.CommandContext;

/**
 * 不处于buffId，HP小于等于hpRate
 * <p>
 * Created by hwy on 17/6/7.
 */
public class SkillAICondition_25 extends DefaultSkillAICondition {

	private final int buffId;

	private final float hpRate;

	public SkillAICondition_25(String ruleStr) {
		final String[] ruleInfo = SplitUtils.split2StringArray(ruleStr, ":");
		buffId = NumberUtils.toInt(ruleInfo[0]);
		hpRate = NumberUtils.toFloat(ruleInfo[1]);
	}

	@Override
	public boolean isAvailable(BattleSoldier soldier, Skill skill, CommandContext ctx) {
		if (soldier.buffHolder().hasBuff(buffId))
			return false;
		if (soldier.hpRate() > hpRate)
			return false;
		return true;
	}
}
