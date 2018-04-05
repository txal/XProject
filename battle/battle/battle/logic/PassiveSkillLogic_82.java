package com.nucleus.logic.core.modules.battle.logic;

import org.springframework.stereotype.Service;

import com.nucleus.logic.core.modules.battle.data.PassiveSkillConfig;
import com.nucleus.logic.core.modules.battle.data.PassiveSkillLaunchTimingEnum;
import com.nucleus.logic.core.modules.battle.model.BattleSoldier;
import com.nucleus.logic.core.modules.battle.model.CommandContext;

/**
 * 暴击附加伤害
 * 
 * @author yifan.chen
 *
 */
@Service
public class PassiveSkillLogic_82 extends PassiveSkillLogic_2 {
	@Override
	protected void doApply(BattleSoldier soldier, BattleSoldier target, CommandContext context, PassiveSkillConfig config, PassiveSkillLaunchTimingEnum timing, IPassiveSkill passiveSkill) {
		if (context == null)
			return;
		formula = config.getPropertyEffectFormulas()[0];
		super.doApply(soldier, target, context, config, timing, passiveSkill);
	}

	protected void setDamage(CommandContext context, int damage) {
		context.setCritDamageOutput(damage);
	}

}
