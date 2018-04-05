package com.nucleus.logic.core.modules.battle.ai.rules;

import java.util.List;

import com.nucleus.logic.core.modules.battle.data.Skill;
import com.nucleus.logic.core.modules.battle.model.BattleSoldier;
import com.nucleus.logic.core.modules.battle.model.CommandContext;

/**
 * 敌方有隐身目标
 * <p>
 * Created by Tony on 15/6/19.
 */
public class SkillAICondition_18 extends DefaultSkillAICondition {

	public SkillAICondition_18(String ruleStr) {
	}

	@Override
	public boolean isAvailable(BattleSoldier soldier, Skill skill, CommandContext ctx) {
		final List<BattleSoldier> soldiers = getAvailableTargets(soldier, skill);
		for (BattleSoldier battleSoldier : soldiers) {
			if (battleSoldier.buffHolder().isHidden())
				return true;
		}
		return false;
	}

}
