package com.nucleus.logic.core.modules.battle.ai.rules;

import com.nucleus.commons.utils.SplitUtils;
import com.nucleus.logic.core.modules.battle.data.Skill;
import com.nucleus.logic.core.modules.battle.model.BattleSoldier;
import com.nucleus.logic.core.modules.battle.model.CommandContext;

import org.apache.commons.lang3.math.NumberUtils;

/**
 * 敌方[camp]存活单位≤[aliveCount]
 * <p>
 * Created by Tony on 15/6/19.
 */
public class SkillAICondition_4 extends DefaultSkillAICondition {

	private final int camp;

	private final int aliveCount;

	public SkillAICondition_4(String ruleStr) {
		final String[] ruleInfo = SplitUtils.split2StringArray(ruleStr, ":");
		camp = NumberUtils.toInt(ruleInfo[0]);
		aliveCount = NumberUtils.toInt(ruleInfo[1]);
	}

	@Override
	public boolean isAvailable(BattleSoldier soldier, Skill skill, CommandContext ctx) {
		if (camp <= 0) {
			return soldier.team().getEnemyTeam().aliveSoldiers().size() <= aliveCount;
		} else {
			return soldier.team().aliveSoldiers().size() <= aliveCount;
		}
	}

}
