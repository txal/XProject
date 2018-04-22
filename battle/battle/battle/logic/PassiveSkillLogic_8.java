package com.nucleus.logic.core.modules.battle.logic;

import org.springframework.stereotype.Service;

import com.nucleus.logic.core.modules.battle.data.PassiveSkillConfig;
import com.nucleus.logic.core.modules.battle.data.PassiveSkillLaunchTimingEnum;
import com.nucleus.logic.core.modules.battle.dto.VideoActionTargetSkillState;
import com.nucleus.logic.core.modules.battle.model.BattleSoldier;
import com.nucleus.logic.core.modules.battle.model.CommandContext;

/**
 * 击飞
 * 
 * @author wgy
 *
 */
@Service
public class PassiveSkillLogic_8 extends AbstractPassiveSkillLogic {

	@Override
	public boolean launchable(BattleSoldier soldier, BattleSoldier target, CommandContext context, PassiveSkillConfig config, PassiveSkillLaunchTimingEnum timing, IPassiveSkill passiveSkill) {
		boolean launchable = super.launchable(soldier, target, context, config, timing, passiveSkill);
		if (!launchable)
			return false;
		if (target.isLeave())
			return false;
		return true;
	}

	@Override
	protected void doApply(BattleSoldier soldier, BattleSoldier target, CommandContext context, PassiveSkillConfig config, PassiveSkillLaunchTimingEnum timing, IPassiveSkill passiveSkill) {
		target.setLeave(true);
		VideoActionTargetSkillState state = new VideoActionTargetSkillState(target, passiveSkill.getId());
		context.skillAction().addTargetState(state);
	}
}
