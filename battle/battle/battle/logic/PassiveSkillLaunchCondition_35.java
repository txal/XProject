package com.nucleus.logic.core.modules.battle.logic;

import com.nucleus.commons.annotation.GenIgnored;
import com.nucleus.logic.core.modules.battle.model.BattleSoldier;
import com.nucleus.logic.core.modules.battle.model.CommandContext;

/**
 * 仅对头号目标有效
 * 
 * @author wgy
 *
 */
@GenIgnored
public class PassiveSkillLaunchCondition_35 extends AbstractPassiveSkillLaunchCondition {

	@Override
	public boolean launchable(BattleSoldier soldier, BattleSoldier target, CommandContext context, IPassiveSkill passiveSkill) {
		if (target == null || context.getFirstTarget() == null)
			return false;
		return target.getId() == context.getFirstTarget().getId();
	}

}
