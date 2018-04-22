package com.nucleus.logic.core.modules.battle.logic;

import org.springframework.stereotype.Service;

import com.nucleus.logic.core.modules.battle.data.PassiveSkillConfig;
import com.nucleus.logic.core.modules.battle.data.PassiveSkillLaunchTimingEnum;
import com.nucleus.logic.core.modules.battle.model.BattleSoldier;
import com.nucleus.logic.core.modules.battle.model.CommandContext;
import com.nucleus.logic.core.modules.battlebuff.model.BattleBuffEntity;

/**
 * buff增强
 * 
 * @author wgy
 *
 */
@Service
public class PassiveSkillLogic_24 extends AbstractPassiveSkillLogic {
	@Override
	protected void doApply(BattleSoldier soldier, BattleSoldier target, CommandContext context, PassiveSkillConfig config, PassiveSkillLaunchTimingEnum timing, IPassiveSkill passiveSkill) {
		if (context == null)
			return;
		BattleBuffEntity buff = context.getTargetBuff();
		if (buff == null)
			return;
		int round = Integer.parseInt(config.getExtraParams()[0]);
		buff.setBuffPersistRound(buff.getBuffPersistRound() + round);
	}
}
