package com.nucleus.logic.core.modules.battle.logic;

import org.springframework.stereotype.Service;

import com.nucleus.logic.core.modules.battle.data.PassiveSkillConfig;
import com.nucleus.logic.core.modules.battle.data.PassiveSkillLaunchTimingEnum;
import com.nucleus.logic.core.modules.battle.model.BattleSoldier;
import com.nucleus.logic.core.modules.battle.model.CommandContext;

/**
 * 指定技能连击
 * 
 * @author hwy
 *
 */
@Service
public class PassiveSkillLogic_95 extends PassiveSkillLogic_3 {
	@Override
	protected void doApply(BattleSoldier soldier, BattleSoldier target, CommandContext context, PassiveSkillConfig config, PassiveSkillLaunchTimingEnum timing, IPassiveSkill passiveSkill) {
		if (config == null || config.getExtraParams() == null)
			return;
		String[] params = config.getExtraParams();
		if (params.length <= 0)
			return;
		int skillId = Integer.parseInt(params[0]);
		defineSkillCombo(soldier, target, context, config, skillId);
	}
}
