package com.nucleus.logic.core.modules.battle.logic;

import com.nucleus.commons.annotation.GenIgnored;
import com.nucleus.logic.core.modules.battle.model.BattleSoldier;
import com.nucleus.logic.core.modules.battle.model.CommandContext;

/**
 * 死后N回合
 * 
 * @author wgy
 *
 */
@GenIgnored
public class PassiveSkillLaunchCondition_14 extends AbstractPassiveSkillLaunchCondition {
	private int round;

	@Override
	public boolean launchable(BattleSoldier soldier, BattleSoldier target, CommandContext context, IPassiveSkill passiveSkill) {
		if (!soldier.isDead())
			return false;
		int currentRound = soldier.battle().getCount();
		return currentRound - soldier.getDeadRound() >= round;
	}

	public int getRound() {
		return round;
	}

	public void setRound(int round) {
		this.round = round;
	}

}
