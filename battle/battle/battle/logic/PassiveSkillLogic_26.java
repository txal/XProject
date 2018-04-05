package com.nucleus.logic.core.modules.battle.logic;

import org.springframework.stereotype.Service;

import com.nucleus.logic.core.modules.battle.data.PassiveSkillConfig;
import com.nucleus.logic.core.modules.battle.data.PassiveSkillLaunchTimingEnum;
import com.nucleus.logic.core.modules.battle.model.BattleSoldier;
import com.nucleus.logic.core.modules.battle.model.CommandContext;

/**
 * 击飞(特殊)
 * 
 * @author wgy
 *
 */
@Service
public class PassiveSkillLogic_26 extends AbstractPassiveSkillLogic {
	@Override
	public boolean launchable(BattleSoldier soldier, BattleSoldier target, CommandContext context, PassiveSkillConfig config, PassiveSkillLaunchTimingEnum timing, IPassiveSkill passiveSkill) {
		boolean success = super.launchable(soldier, target, context, config, timing, passiveSkill);
		if (!success)
			return false;
		if (target == null || target.isLeave())
			return false;
		if (context == null || !context.skill().ifHpLossFunction())
			return false;
		int level = Integer.parseInt(config.getExtraParams()[0]);
		int monsterId = Integer.parseInt(config.getExtraParams()[1]);
		if (target.ifPet() || (monsterId > 0 && target.monsterId() == monsterId)) {
			int lvDiff = target.grade() - soldier.grade();
			if (lvDiff <= level) {
				return true;
			}
		}
		return false;
	}

	@Override
	protected void doApply(BattleSoldier soldier, BattleSoldier target, CommandContext context, PassiveSkillConfig config, PassiveSkillLaunchTimingEnum timing, IPassiveSkill passiveSkill) {
		target.setLeave(true);
	}
}
