package com.nucleus.logic.core.modules.battle.ai.rules;

import com.nucleus.commons.utils.SplitUtils;
import com.nucleus.logic.core.modules.battle.data.Skill;
import com.nucleus.logic.core.modules.battle.model.BattleSoldier;
import com.nucleus.logic.core.modules.battle.model.CommandContext;

import org.apache.commons.lang3.math.NumberUtils;

import java.util.List;

/**
 * 敌方只有1个目标时
 * <p>
 * Created by Tony on 15/6/19.
 */
public class SkillAICondition_17 extends DefaultSkillAICondition {

	private final int targetCount;

	public SkillAICondition_17(String ruleStr) {
		final String[] ruleInfo = SplitUtils.split2StringArray(ruleStr, ":");
		targetCount = NumberUtils.toInt(ruleInfo[0]);
	}

	@Override
	public boolean isAvailable(BattleSoldier soldier, Skill skill, CommandContext ctx) {
		final List<BattleSoldier> soldiers = getAvailableTargets(soldier, skill);
		int count = 0;
		for (BattleSoldier bs : soldiers) {
			if (bs.isDead())
				continue;
			count++;
		}
		if (count > 0 && count <= targetCount) {
			return true;
		}
		return false;
	}

}
