package com.nucleus.logic.core.modules.battle.logic;

import com.nucleus.commons.annotation.GenIgnored;
import com.nucleus.logic.core.modules.battle.model.BattleSoldier;
import com.nucleus.logic.core.modules.battle.model.CommandContext;

/**
 * 第n回合及以后
 * 
 * @author wgy
 *
 */
@GenIgnored
public class PassiveSkillLaunchCondition_55 extends AbstractPassiveSkillLaunchCondition {
	private int round;
	@Override
	public boolean launchable(BattleSoldier soldier, BattleSoldier target, CommandContext context, IPassiveSkill passiveSkill) {
		return soldier.battle().getCount() >= round;
	}
	public int getRound() {
		return round;
	}
	public void setRound(int round) {
		this.round = round;
	}

}
