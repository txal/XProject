package com.nucleus.logic.core.modules.battle.logic;

import com.nucleus.commons.annotation.GenIgnored;
import com.nucleus.logic.core.modules.battle.model.BattleSoldier;
import com.nucleus.logic.core.modules.battle.model.CommandContext;

/**
 * 自己是否死亡
 * 
 * @author hwy
 *
 */
@GenIgnored
public class PassiveSkillLaunchCondition_63 extends AbstractPassiveSkillLaunchCondition {
	private int isDead;

	@Override
	public boolean launchable(BattleSoldier soldier, BattleSoldier target, CommandContext context, IPassiveSkill passiveSkill) {
		if (isDead > 0)
			return soldier.isDead();
		else
			return !soldier.isDead();
	}

	public int getIsDead() {
		return isDead;
	}

	public void setIsDead(int isDead) {
		this.isDead = isDead;
	}

}
