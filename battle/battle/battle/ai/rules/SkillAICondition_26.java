package com.nucleus.logic.core.modules.battle.ai.rules;

import java.util.List;

import org.apache.commons.lang3.math.NumberUtils;

import com.nucleus.commons.utils.SplitUtils;
import com.nucleus.logic.core.modules.battle.data.Skill;
import com.nucleus.logic.core.modules.battle.model.BattleSoldier;
import com.nucleus.logic.core.modules.battle.model.CommandContext;

/**
 * 自身等级小于15级或敌方目标大于1个，地方全部携带buffId，rate机率触发
 * <p>
 * Created by hwy on 17/6/7.
 */
public class SkillAICondition_26 extends DefaultSkillAICondition {

	private final int level;

	private final int targetCount;

	private final int buffId;

	private final double rate;

	public SkillAICondition_26(String ruleStr) {
		final String[] ruleInfo = SplitUtils.split2StringArray(ruleStr, ":");
		level = NumberUtils.toInt(ruleInfo[0]);
		targetCount = NumberUtils.toInt(ruleInfo[1]);
		buffId = NumberUtils.toInt(ruleInfo[2]);
		rate = NumberUtils.toDouble(ruleInfo[3]);
	}

	@Override
	public boolean isAvailable(BattleSoldier soldier, Skill skill, CommandContext ctx) {
		final List<BattleSoldier> soldiers = getAvailableTargets(soldier, skill);
		if (soldier.grade() < level || soldiers.size() > targetCount) {
			int hasBuffCount = 0;
			for (BattleSoldier s : soldiers) {
				if (s.buffHolder().hasBuff(buffId))
					hasBuffCount++;
			}

			final double rnd = Math.random();
			if (hasBuffCount == soldiers.size() && rnd <= rate)
				return true;
		}
		return false;
	}

}
