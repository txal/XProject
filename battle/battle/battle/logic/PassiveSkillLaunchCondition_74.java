package com.nucleus.logic.core.modules.battle.logic;

import com.nucleus.commons.annotation.GenIgnored;
import com.nucleus.logic.core.modules.battle.model.BattleSoldier;
import com.nucleus.logic.core.modules.battle.model.CommandContext;

/**
 * 使用指定技能时（优先检查强制技能，再查当前技能）
 * 
 * @author hwy
 *
 */
@GenIgnored
public class PassiveSkillLaunchCondition_74 extends AbstractPassiveSkillLaunchCondition {
	private int skillId;

	@Override
	public boolean launchable(BattleSoldier soldier, BattleSoldier target, CommandContext context, IPassiveSkill passiveSkill) {
		if (context == null)
			return false;
		return context.trigger().forceSkillId() == skillId;
	}

	public int getSkillId() {
		return skillId;
	}

	public void setSkillId(int skillId) {
		this.skillId = skillId;
	}
}
