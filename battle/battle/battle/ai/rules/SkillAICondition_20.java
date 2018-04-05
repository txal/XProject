package com.nucleus.logic.core.modules.battle.ai.rules;

import com.nucleus.commons.utils.SplitUtils;
import com.nucleus.logic.core.modules.battle.data.Skill;
import com.nucleus.logic.core.modules.battle.model.BattleSoldier;
import com.nucleus.logic.core.modules.battle.model.CommandContext;

import org.apache.commons.lang3.math.NumberUtils;

import java.util.List;

/**
 * 有且只有1个非鬼魂单位HP＜100%
 * <p>
 * Created by Tony on 15/6/19.
 */
public class SkillAICondition_20 extends DefaultSkillAICondition {

	private final int targetCount;

	private final float hpRate;

	private final boolean ignoreGhost;

	public SkillAICondition_20(String ruleStr) {
		final String[] ruleInfo = SplitUtils.split2StringArray(ruleStr, ":");
		targetCount = NumberUtils.toInt(ruleInfo[0]);
		hpRate = NumberUtils.toFloat(ruleInfo[1]);
		ignoreGhost = NumberUtils.toInt(ruleInfo[2]) > 0;
	}

	@Override
	public boolean isAvailable(BattleSoldier soldier, Skill skill, CommandContext ctx) {
		final List<BattleSoldier> soldiers = getAvailableTargets(soldier, skill);
		int count = 0;
		for (BattleSoldier bs : soldiers) {
			if (bs.isDead())
				continue;
			if (ignoreGhost && bs.isLowGhost()) {
				continue;
			}
			if (bs.hpRate() >= hpRate) {
				continue;
			}
			count++;
		}
		if (count > 0 && count <= targetCount) {
			return true;
		}
		return false;
	}

}
