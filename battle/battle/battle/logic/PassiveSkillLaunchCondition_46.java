package com.nucleus.logic.core.modules.battle.logic;

import org.apache.commons.lang3.StringUtils;

import com.nucleus.commons.annotation.GenIgnored;
import com.nucleus.logic.core.modules.battle.data.Skill;
import com.nucleus.logic.core.modules.battle.model.BattleSoldier;
import com.nucleus.logic.core.modules.battle.model.CommandContext;

/**
 * 46使用存活时治疗技能
 * 
 * @author zhanhua.xu
 *
 */
@GenIgnored
public class PassiveSkillLaunchCondition_46 extends AbstractPassiveSkillLaunchCondition {
	@Override
	public boolean launchable(BattleSoldier soldier, BattleSoldier target, CommandContext context, IPassiveSkill passiveSkill) {
		final Skill skill;
		return context != null && (skill = context.skill()) != null && (skill.ifHealFunction() || StringUtils.isNotBlank(skill.getTeamSuccessHpEffectFormula()));
	}
}
