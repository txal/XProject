package com.nucleus.logic.core.modules.battle.logic;

import com.nucleus.commons.annotation.GenIgnored;
import com.nucleus.logic.core.modules.battle.data.Skill;
import com.nucleus.logic.core.modules.battle.model.BattleSoldier;
import com.nucleus.logic.core.modules.battle.model.CommandContext;

/**
 * 使用复活类技能
 * 
 * @author wgy
 *
 */
@GenIgnored
public class PassiveSkillLaunchCondition_32 extends AbstractPassiveSkillLaunchCondition {

	@Override
	public boolean launchable(BattleSoldier soldier, BattleSoldier target, CommandContext context, IPassiveSkill passiveSkill) {
		Skill skill = context.skill();
		if (skill == null)
			return false;
		return skill.ifReliveFunction();
	}
}
