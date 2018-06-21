package com.nucleus.logic.core.modules.battle.logic;

import com.nucleus.commons.annotation.GenIgnored;
import com.nucleus.logic.core.modules.battle.model.BattleSoldier;
import com.nucleus.logic.core.modules.battle.model.CommandContext;

/**
 * 使用某技能小于指定次数
 * 
 * @author wgy
 *
 */
@GenIgnored
public class PassiveSkillLaunchCondition_31 extends AbstractPassiveSkillLaunchCondition {
	private int skillId;
	private int times;

	@Override
	public boolean launchable(BattleSoldier soldier, BattleSoldier target, CommandContext context, IPassiveSkill passiveSkill) {
		Integer usedTimes = soldier.getUsedSkills().get(skillId);
		if (usedTimes == null)
			usedTimes = 0;
		return usedTimes < times;
	}

	public int getSkillId() {
		return skillId;
	}

	public void setSkillId(int skillId) {
		this.skillId = skillId;
	}

	public int getTimes() {
		return times;
	}

	public void setTimes(int times) {
		this.times = times;
	}

}
