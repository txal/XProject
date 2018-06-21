package com.nucleus.logic.core.modules.battle.logic;

import java.util.Set;

import com.nucleus.commons.annotation.GenIgnored;
import com.nucleus.logic.core.modules.battle.model.BattleSoldier;
import com.nucleus.logic.core.modules.battle.model.CommandContext;

/**
 * 使用指定技能内其中之一
 * 
 * @author zhanhua.xu
 *
 */
@GenIgnored
public class PassiveSkillLaunchCondition_45 extends AbstractPassiveSkillLaunchCondition {
	private Set<Integer> skillIds;

	@Override
	public boolean launchable(BattleSoldier soldier, BattleSoldier target, CommandContext context, IPassiveSkill passiveSkill) {
		return skillIds != null && context != null && context.skill() != null && skillIds.contains(context.skill().getId());
	}

	public Set<Integer> getSkillIds() {
		return skillIds;
	}

	public void setSkillIds(Set<Integer> skillIds) {
		this.skillIds = skillIds;
	}

}
