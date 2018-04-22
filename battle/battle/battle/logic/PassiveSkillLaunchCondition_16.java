package com.nucleus.logic.core.modules.battle.logic;

import java.util.Set;

import com.nucleus.commons.annotation.GenIgnored;
import com.nucleus.logic.core.modules.battle.model.BattleSoldier;
import com.nucleus.logic.core.modules.battle.model.CommandContext;

/**
 * 对方存在指定技能则无法触发
 * 
 * @author wgy
 *
 */
@GenIgnored
public class PassiveSkillLaunchCondition_16 extends AbstractPassiveSkillLaunchCondition {
	private Set<Integer> skillIds;

	@Override
	public boolean launchable(BattleSoldier soldier, BattleSoldier target, CommandContext context, IPassiveSkill passiveSkill) {
		if (target != null && this.skillIds != null && !this.skillIds.isEmpty()) {
			for (int skillId : skillIds) {
				if (target.skillHolder().passiveSkill(skillId) != null)
					return false;
			}
		}
		return true;
	}

	public Set<Integer> getSkillIds() {
		return skillIds;
	}

	public void setSkillIds(Set<Integer> skillIds) {
		this.skillIds = skillIds;
	}

}
