package com.nucleus.logic.core.modules.battle.ai.rules;

import java.util.List;

import org.apache.commons.lang3.math.NumberUtils;

import com.nucleus.commons.utils.SplitUtils;
import com.nucleus.logic.core.modules.battle.data.Skill;
import com.nucleus.logic.core.modules.battle.model.BattleSoldier;
import com.nucleus.logic.core.modules.battle.model.CommandContext;

/**
 * 自身等级小于15级或敌方目标大于1个
 * <p>
 * Created by Tony on 15/6/19.
 */
public class SkillAICondition_16 extends DefaultSkillAICondition {

	private final int level;

	private final int targetCount;

	public SkillAICondition_16(String ruleStr) {
		final String[] ruleInfo = SplitUtils.split2StringArray(ruleStr, ":");
		level = NumberUtils.toInt(ruleInfo[0]);
		targetCount = NumberUtils.toInt(ruleInfo[1]);
	}

	@Override
	public boolean isAvailable(BattleSoldier soldier, Skill skill, CommandContext ctx) {
		final List<BattleSoldier> soldiers = getAvailableTargets(soldier, skill);
		if (soldier.grade() < level || soldiers.size() > targetCount) {
			return true;
		}
		return false;
	}

}
