package com.nucleus.logic.core.modules.battle.logic;

import org.springframework.stereotype.Service;

import com.nucleus.logic.core.modules.battle.data.PassiveSkillConfig;
import com.nucleus.logic.core.modules.battle.data.PassiveSkillLaunchTimingEnum;
import com.nucleus.logic.core.modules.battle.data.Skill;
import com.nucleus.logic.core.modules.battle.model.BattleSoldier;
import com.nucleus.logic.core.modules.battle.model.CommandContext;

/**
 * 执行前置技能
 * 
 * @author wgy
 *
 */
@Service
public class PassiveSkillLogic_52 extends AbstractPassiveSkillLogic {
	@Override
	protected void doApply(BattleSoldier soldier, BattleSoldier target, CommandContext context, PassiveSkillConfig config, PassiveSkillLaunchTimingEnum timing, IPassiveSkill passiveSkill) {
		if (config.getExtraParams() == null || config.getExtraParams().length <= 0)
			return;
		int skillId = Integer.parseInt(config.getExtraParams()[0]);
		Skill skill = Skill.get(skillId);
		if (skill == null)
			return;
		try {
			soldier.autoBattle(skill, target);
			soldier.actionStart();
		} catch (Exception e) {
			e.printStackTrace();
		}
	}
}
