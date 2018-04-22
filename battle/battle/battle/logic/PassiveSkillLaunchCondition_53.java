package com.nucleus.logic.core.modules.battle.logic;

import com.nucleus.commons.annotation.GenIgnored;
import com.nucleus.logic.core.modules.battle.model.BattleSoldier;
import com.nucleus.logic.core.modules.battle.model.CommandContext;

/**
 * 任一目标死亡
 * 
 * @author wgy
 *
 */
@GenIgnored
public class PassiveSkillLaunchCondition_53 extends AbstractPassiveSkillLaunchCondition {
	@Override
	public boolean launchable(BattleSoldier soldier, BattleSoldier target, CommandContext context, IPassiveSkill passiveSkill) {
		if (context == null)
			return false;
		return context.getBeAttackedTargets().values().stream().anyMatch(s -> s.isDead());
	}

}
