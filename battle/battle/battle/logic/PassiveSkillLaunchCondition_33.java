package com.nucleus.logic.core.modules.battle.logic;

import java.util.List;

import com.nucleus.commons.annotation.GenIgnored;
import com.nucleus.commons.utils.SplitUtils;
import com.nucleus.logic.core.modules.battle.model.BattleSoldier;
import com.nucleus.logic.core.modules.battle.model.CommandContext;

/**
 * 使用某技能
 * 
 * @author wgy
 *
 */
@GenIgnored
public class PassiveSkillLaunchCondition_33 extends AbstractPassiveSkillLaunchCondition {
	private String skillId;

	@Override
	public boolean launchable(BattleSoldier soldier, BattleSoldier target, CommandContext context, IPassiveSkill passiveSkill) {
		if (context == null)
			return false;
		List<Integer> skillIds = SplitUtils.split2IntList(skillId, "\\|", true);
		if (skillIds != null && !skillIds.isEmpty()) {
			return skillIds.contains(context.skill().getId());
		}
		return false;
	}

	public String getSkillId() {
		return skillId;
	}

	public void setSkillId(String skillId) {
		this.skillId = skillId;
	}

}
