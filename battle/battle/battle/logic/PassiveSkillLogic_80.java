package com.nucleus.logic.core.modules.battle.logic;

import org.springframework.stereotype.Service;

import com.nucleus.logic.core.modules.battle.data.PassiveSkillConfig;
import com.nucleus.logic.core.modules.battle.data.PassiveSkillLaunchTimingEnum;
import com.nucleus.logic.core.modules.battle.model.BattleSoldier;
import com.nucleus.logic.core.modules.battle.model.CommandContext;

/**
 * 宠物保护主人
 * 
 * @author yifan.chen
 *
 */
@Service
public class PassiveSkillLogic_80 extends PassiveSkillLogic_50 {
	@Override
	protected void doApply(BattleSoldier soldier, BattleSoldier target, CommandContext context, PassiveSkillConfig config, PassiveSkillLaunchTimingEnum timing, IPassiveSkill passiveSkill) {
		if (target == null || target.isDead())
			return;
		if (target.isMainCharactor() && target.myPet() != null) {
			if (soldier.getId() == target.myPet().getId())
				target.addProtectedBySoldierId(soldier.getId());
		}
		// soldier是主人
		if (soldier.isMainCharactor() && soldier.myPet() != null) {
			if (target.getId() == soldier.myPet().getId())
				soldier.addProtectedBySoldierId(target.getId());
		}

	}
}
