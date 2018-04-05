package com.nucleus.logic.core.modules.battle.logic;

import com.nucleus.commons.annotation.GenIgnored;
import com.nucleus.logic.core.modules.battle.model.BattleSoldier;
import com.nucleus.logic.core.modules.battle.model.CommandContext;

/**
 * 己方有死亡单位
 * 
 * @author wgy
 *
 */
@GenIgnored
public class PassiveSkillLaunchCondition_23 extends AbstractPassiveSkillLaunchCondition {

	@Override
	public boolean launchable(BattleSoldier soldier, BattleSoldier target, CommandContext context, IPassiveSkill passiveSkill) {
		for (BattleSoldier s : soldier.team().allSoldiersMap().values()) {
			if (s.getId() == soldier.getId())
				continue;
			if (s.isDead())
				return true;
		}
		return false;
	}

}
