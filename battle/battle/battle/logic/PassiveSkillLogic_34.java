package com.nucleus.logic.core.modules.battle.logic;

import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;

import com.nucleus.logic.core.modules.battle.data.PassiveSkillConfig;
import com.nucleus.logic.core.modules.battle.data.PassiveSkillLaunchTimingEnum;
import com.nucleus.logic.core.modules.battle.model.BattleSoldier;
import com.nucleus.logic.core.modules.battle.model.CommandContext;

/**
 * 援助：被击飞的时候有机率召唤一个援军
 * 
 * @author wgy
 *
 */
@Service
public class PassiveSkillLogic_34 extends AbstractPassiveSkillLogic {
	@Autowired
	private CallMonsterService callMonsterHandler;

	@Override
	protected void doApply(BattleSoldier soldier, BattleSoldier target, CommandContext context, PassiveSkillConfig config, PassiveSkillLaunchTimingEnum timing, IPassiveSkill passiveSkill) {
		if (context == null || config.getExtraParams() == null || config.getExtraParams().length <= 0)
			return;
		int monsterId = Integer.parseInt(config.getExtraParams()[0]);
		if (monsterId <= 0)
			return;
		callMonsterHandler.doCall(soldier, monsterId, context.skillAction(), null, false, passiveSkill.getId());
	}
}
