package com.nucleus.logic.core.modules.battle.ai.rules;

import com.nucleus.logic.core.modules.battle.data.Skill;
import com.nucleus.logic.core.modules.battle.model.BattleSoldier;
import com.nucleus.logic.core.modules.battle.model.CommandContext;

/**
 * 当前没有召唤物（山精）存在
 * <p>
 * Created by Tony on 15/6/19.
 */
public class SkillAICondition_14 extends DefaultSkillAICondition {

	public SkillAICondition_14(String ruleStr) {
	}

	@Override
	public boolean isAvailable(BattleSoldier soldier, Skill skill, CommandContext ctx) {
		return soldier.team().getCalledMonsters().size() <= 0;
	}

}
