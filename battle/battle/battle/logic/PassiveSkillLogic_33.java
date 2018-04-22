package com.nucleus.logic.core.modules.battle.logic;

import org.springframework.stereotype.Service;

import com.nucleus.logic.core.modules.battle.data.PassiveSkillConfig;
import com.nucleus.logic.core.modules.battle.data.PassiveSkillLaunchTimingEnum;
import com.nucleus.logic.core.modules.battle.model.BattleSoldier;
import com.nucleus.logic.core.modules.battle.model.CommandContext;

/**
 * 减敌方逃跑成功率
 * 
 * @author wgy
 *
 */
@Service
public class PassiveSkillLogic_33 extends AbstractPassiveSkillLogic {
	@Override
	protected void doApply(BattleSoldier soldier, BattleSoldier target, CommandContext context, PassiveSkillConfig config, PassiveSkillLaunchTimingEnum timing, IPassiveSkill passiveSkill) {
		if (config.getExtraParams() == null || config.getExtraParams().length <= 0)
			return;
		float r = Float.parseFloat(config.getExtraParams()[0]);
		float v = soldier.battleTeam().getEnemyTeam().getRetreateReducceRate();
		v += r;
		soldier.battleTeam().getEnemyTeam().setRetreateReducceRate(v);
	}
}
