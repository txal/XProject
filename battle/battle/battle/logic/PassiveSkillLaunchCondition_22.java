package com.nucleus.logic.core.modules.battle.logic;

import java.util.Iterator;

import com.nucleus.commons.annotation.GenIgnored;
import com.nucleus.logic.core.modules.battle.model.BattleSoldier;
import com.nucleus.logic.core.modules.battle.model.CommandContext;

/**
 * 己方场上还存活除自己之外其他单位
 * 
 * @author wgy
 *
 */
@GenIgnored
public class PassiveSkillLaunchCondition_22 extends AbstractPassiveSkillLaunchCondition {

	@Override
	public boolean launchable(BattleSoldier soldier, BattleSoldier target, CommandContext context, IPassiveSkill passiveSkill) {
		boolean launchable = false;
		for (Iterator<BattleSoldier> it = soldier.team().soldiersMap().values().iterator(); it.hasNext();) {
			BattleSoldier s = it.next();
			if (s.getId() == soldier.getId() || s.isDead())
				continue;
			launchable = true;
			break;
		}
		return launchable;
	}

}
