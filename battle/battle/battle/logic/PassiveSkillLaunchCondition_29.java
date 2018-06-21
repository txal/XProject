package com.nucleus.logic.core.modules.battle.logic;

import com.nucleus.commons.annotation.GenIgnored;
import com.nucleus.logic.core.modules.battle.model.BattleSoldier;
import com.nucleus.logic.core.modules.battle.model.CommandContext;

/**
 * 本队死亡单位数量大于等于指定值
 * 
 * @author wgy
 *
 */
@GenIgnored
public class PassiveSkillLaunchCondition_29 extends AbstractPassiveSkillLaunchCondition {
	private int count;

	@Override
	public boolean launchable(BattleSoldier soldier, BattleSoldier target, CommandContext context, IPassiveSkill passiveSkill) {
		return soldier.team().getCurrentRoundDeadCount() >= count;
	}

	public int getCount() {
		return count;
	}

	public void setCount(int count) {
		this.count = count;
	}

}
