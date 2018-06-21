package com.nucleus.logic.core.modules.battle.logic;

import com.nucleus.commons.annotation.GenIgnored;
import com.nucleus.logic.core.modules.battle.model.BattleSoldier;
import com.nucleus.logic.core.modules.battle.model.CommandContext;

/**
 * 封印状态
 * 
 * @author wgy
 *
 */
@GenIgnored
public class PassiveSkillLaunchCondition_19 extends AbstractPassiveSkillLaunchCondition {
	private boolean attackBanned;

	@Override
	public boolean launchable(BattleSoldier soldier, BattleSoldier target, CommandContext context, IPassiveSkill passiveSkill) {
		return this.attackBanned == soldier.buffHolder().isAttackBanned();
	}

	public boolean isAttackBanned() {
		return attackBanned;
	}

	public void setAttackBanned(boolean attackBanned) {
		this.attackBanned = attackBanned;
	}
}
