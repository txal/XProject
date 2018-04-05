package com.nucleus.logic.core.modules.battle.logic;

import com.nucleus.commons.annotation.GenIgnored;
import com.nucleus.logic.core.modules.battle.model.BattleSoldier;
import com.nucleus.logic.core.modules.battle.model.CommandContext;

/**
 * 目标被击杀
 * 
 * @author wgy
 *
 */
@GenIgnored
public class PassiveSkillLaunchCondition_39 extends AbstractPassiveSkillLaunchCondition {

	@Override
	public boolean launchable(BattleSoldier soldier, BattleSoldier target, CommandContext context, IPassiveSkill passiveSkill) {
		if (context == null || context.target() == null)
			return false;
		return context.target().isDead();
	}

}
