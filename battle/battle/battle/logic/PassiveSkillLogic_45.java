package com.nucleus.logic.core.modules.battle.logic;

import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;

import com.nucleus.logic.core.modules.battle.data.PassiveSkillConfig;
import com.nucleus.logic.core.modules.battle.data.PassiveSkillLaunchTimingEnum;
import com.nucleus.logic.core.modules.battle.model.BattleSoldier;
import com.nucleus.logic.core.modules.battle.model.CommandContext;

/**
 * 召唤
 * 
 * @author wgy
 *
 */
@Service
public class PassiveSkillLogic_45 extends AbstractPassiveSkillLogic {
	@Autowired
	private CallMonsterService callMonsterHandler;

	@Override
	protected void doApply(BattleSoldier soldier, BattleSoldier target, CommandContext context, PassiveSkillConfig config, PassiveSkillLaunchTimingEnum timing, IPassiveSkill passiveSkill) {
		if (config.getExtraParams() == null || config.getExtraParams().length <= 0)
			return;
		for (String strMonsterId : config.getExtraParams()) {
			int monsterId = Integer.parseInt(strMonsterId);
			if (monsterId <= 0)
				continue;
			if (context != null)
				callMonsterHandler.doCall(soldier, monsterId, context.skillAction(), null, false, passiveSkill.getId());
			else if (timing == PassiveSkillLaunchTimingEnum.RoundOver)
				callMonsterHandler.doCall(soldier, monsterId, soldier.currentVideoRound().endAction(), null, false, passiveSkill.getId());
		}
	}
}
