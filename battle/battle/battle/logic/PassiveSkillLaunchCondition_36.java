package com.nucleus.logic.core.modules.battle.logic;

import com.nucleus.commons.annotation.GenIgnored;
import com.nucleus.logic.core.modules.battle.model.BattleSoldier;
import com.nucleus.logic.core.modules.battle.model.CommandContext;

/**
 * 给目标加指定buff
 * 
 * @author wgy
 *
 */
@GenIgnored
public class PassiveSkillLaunchCondition_36 extends AbstractPassiveSkillLaunchCondition {
	private int buffId;

	@Override
	public boolean launchable(BattleSoldier soldier, BattleSoldier target, CommandContext context, IPassiveSkill passiveSkill) {
		if (context.getBeAddBuffId() <= 0)
			return false;
		return buffId == context.getBeAddBuffId();
	}

}
