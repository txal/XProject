package com.nucleus.logic.core.modules.battle.logic;

import java.util.Set;

import com.nucleus.commons.annotation.GenIgnored;
import com.nucleus.logic.core.modules.battle.data.Skill;
import com.nucleus.logic.core.modules.battle.model.BattleSoldier;
import com.nucleus.logic.core.modules.battle.model.CommandContext;

/**
 * 对方有特定被动技能时触发
 * 
 * @author wgy
 *
 */
@GenIgnored
public class PassiveSkillLaunchCondition_3 extends AbstractPassiveSkillLaunchCondition {
	private Set<Integer> skillIds;

	@Override
	public boolean launchable(BattleSoldier soldier, BattleSoldier target, CommandContext context, IPassiveSkill passiveSkill) {
		if (target == null)
			return false;
		boolean success = false;
		for (Integer skillId : this.skillIds) {
			Skill skill = target.skillHolder().passiveSkill(skillId);
			if (skill != null) {
				success = true;
				break;
			}
		}
		return success;
	}

	public Set<Integer> getSkillIds() {
		return skillIds;
	}

	public void setSkillIds(Set<Integer> skillIds) {
		this.skillIds = skillIds;
	}

}
