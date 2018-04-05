package com.nucleus.logic.core.modules.battle.logic;

import com.nucleus.commons.annotation.GenIgnored;
import com.nucleus.logic.core.modules.battle.model.BattleSoldier;
import com.nucleus.logic.core.modules.battle.model.CommandContext;

/**
 * 目标是否为傀儡生物
 * 
 * @author wangyu
 *
 */
@GenIgnored
public class PassiveSkillLaunchCondition_81 extends AbstractPassiveSkillLaunchCondition {

	private int ifGhost;

	@Override
	public boolean launchable(BattleSoldier soldier, BattleSoldier target, CommandContext context, IPassiveSkill passiveSkill) {
		if (ifGhost == 0)
			return target.isGhost();
		else
			return !target.isGhost();
	}

	public int getIfGhost() {
		return ifGhost;
	}

	public void setIfGhost(int ifGhost) {
		this.ifGhost = ifGhost;
	}

}
