package com.nucleus.logic.core.modules.battle.logic;

import org.springframework.stereotype.Service;

import com.nucleus.logic.core.modules.battle.data.PassiveSkillConfig;
import com.nucleus.logic.core.modules.battle.data.PassiveSkillLaunchTimingEnum;
import com.nucleus.logic.core.modules.battle.model.BattleSoldier;
import com.nucleus.logic.core.modules.battle.model.CommandContext;

/**
 * 满足某些条件可以使用extra参数恢复hp/mp
 *
 * @author wangyu
 */
@Service
public class PassiveSkillLogic_106 extends PassiveSkillLogic_12 {
	@Override
	protected void doApply(BattleSoldier soldier, BattleSoldier target, CommandContext context, PassiveSkillConfig config, PassiveSkillLaunchTimingEnum timing, IPassiveSkill passiveSkill) {
		if (soldier.allLuckyPassSkills()) {
			context.getMateData().put("metaFormulas", config.getExtraParams());
		}
		super.doApply(soldier, target, context, config, timing, passiveSkill);
	}
}
