package com.nucleus.logic.core.modules.battle.logic;

import org.springframework.stereotype.Service;

import com.nucleus.logic.core.modules.battle.data.PassiveSkillConfig;
import com.nucleus.logic.core.modules.battle.data.PassiveSkillLaunchTimingEnum;
import com.nucleus.logic.core.modules.battle.model.BattleSoldier;
import com.nucleus.logic.core.modules.battle.model.CommandContext;

/**
 * 自动保护
 * 
 * @author wgy
 *
 */
@Service
public class PassiveSkillLogic_50 extends AbstractPassiveSkillLogic {
	@Override
	protected void doApply(BattleSoldier soldier, BattleSoldier target, CommandContext context, PassiveSkillConfig config, PassiveSkillLaunchTimingEnum timing, IPassiveSkill passiveSkill) {
		if (target == null || target.isDead())
			return;
		if (config.getExtraParams() == null || config.getExtraParams().length == 0)
			return;
		int monsterId = Integer.parseInt(config.getExtraParams()[0]);
		if (monsterId <= 0)
			return;
		if (target.monsterId() != monsterId)
			return;
		target.addProtectedBySoldierId(soldier.getId());
	}
}
