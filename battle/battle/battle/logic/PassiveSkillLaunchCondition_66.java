package com.nucleus.logic.core.modules.battle.logic;

import com.nucleus.commons.annotation.GenIgnored;
import com.nucleus.logic.core.modules.battle.model.BattleSoldier;
import com.nucleus.logic.core.modules.battle.model.CommandContext;

/**
 * 目标生命值低于指定百分比
 * 
 * @author ws
 *
 */
@GenIgnored
public class PassiveSkillLaunchCondition_66 extends AbstractPassiveSkillLaunchCondition {
	private float hpRate;

	@Override
	public boolean launchable(BattleSoldier soldier, BattleSoldier target, CommandContext context, IPassiveSkill passiveSkill) {
		return target.hpRate() < hpRate;
	}

	public float getHpRate() {
		return hpRate;
	}

	public void setHpRate(float hpRate) {
		this.hpRate = hpRate;
	}

}
