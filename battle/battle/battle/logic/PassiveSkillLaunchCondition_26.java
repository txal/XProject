package com.nucleus.logic.core.modules.battle.logic;

import com.nucleus.commons.annotation.GenIgnored;
import com.nucleus.logic.core.modules.battle.model.BattleSoldier;
import com.nucleus.logic.core.modules.battle.model.CommandContext;

/**
 * 除自己之外全部小怪死亡
 * 
 * @author wgy
 *
 */
@GenIgnored
public class PassiveSkillLaunchCondition_26 extends AbstractPassiveSkillLaunchCondition {

	@Override
	public boolean launchable(BattleSoldier soldier, BattleSoldier target, CommandContext context, IPassiveSkill passiveSkill) {
		if (soldier.isDead())
			return false;
		for (BattleSoldier s : soldier.team().allSoldiersMap().values()) {
			if (s.getId() == soldier.getId())
				continue;
			if (!s.isDead())
				return false;
		}
		return true;
	}

}
