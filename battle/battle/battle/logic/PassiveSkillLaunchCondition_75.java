package com.nucleus.logic.core.modules.battle.logic;

import java.util.Set;

import com.nucleus.commons.annotation.GenIgnored;
import com.nucleus.logic.core.modules.battle.model.BattleSoldier;
import com.nucleus.logic.core.modules.battle.model.CommandContext;

/**
 * 使用指定技能时（无强制技能情况下）
 * 
 * @author hwy
 *
 */
@GenIgnored
public class PassiveSkillLaunchCondition_75 extends AbstractPassiveSkillLaunchCondition {
	private Set<Integer> skillId;

	@Override
	public boolean launchable(BattleSoldier soldier, BattleSoldier target, CommandContext context, IPassiveSkill passiveSkill) {
		if (context == null)
			return false;
		if (skillId != null) {
			for (Integer id : skillId) {
				if (context.skill().getId() == id && context.trigger().forceSkillId() == 0) {
					return true;
				}
			}
		}
		return false;
	}

	public Set<Integer> getSkillId() {
		return skillId;
	}

	public void setSkillId(Set<Integer> skillId) {
		this.skillId = skillId;
	}

}
