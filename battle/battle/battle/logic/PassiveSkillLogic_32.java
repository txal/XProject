package com.nucleus.logic.core.modules.battle.logic;

import org.springframework.stereotype.Service;

import com.nucleus.logic.core.modules.battle.data.PassiveSkillConfig;
import com.nucleus.logic.core.modules.battle.data.PassiveSkillLaunchTimingEnum;
import com.nucleus.logic.core.modules.battle.model.BattleSoldier;
import com.nucleus.logic.core.modules.battle.model.CommandContext;

/**
 * 自身逃跑成功率
 * 
 * @author wgy
 *
 */
@Service
public class PassiveSkillLogic_32 extends AbstractPassiveSkillLogic {
	@Override
	protected void doApply(BattleSoldier soldier, BattleSoldier target, CommandContext context, PassiveSkillConfig config, PassiveSkillLaunchTimingEnum timing, IPassiveSkill passiveSkill) {
		if (config.getExtraParams() != null && config.getExtraParams().length > 0) {
			float r = Float.parseFloat(config.getExtraParams()[0]);
			r += context.getRetreatSuccessRate();
			context.setRetreatSuccessRate(r);
		}
	}
}
