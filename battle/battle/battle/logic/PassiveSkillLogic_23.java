package com.nucleus.logic.core.modules.battle.logic;

import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;

import com.nucleus.logic.core.modules.battle.data.PassiveSkillConfig;
import com.nucleus.logic.core.modules.battle.data.PassiveSkillLaunchTimingEnum;
import com.nucleus.logic.core.modules.battle.model.BattleSoldier;
import com.nucleus.logic.core.modules.battle.model.CommandContext;

/**
 * 雷/水/火/土系法术吸收
 * 
 * @author wgy
 *
 */
@Service
public class PassiveSkillLogic_23 extends AbstractPassiveSkillLogic {
	@Autowired
	private PassiveSkillLogic_9 skill;

	@Override
	protected void doApply(BattleSoldier soldier, BattleSoldier target, CommandContext context, PassiveSkillConfig config, PassiveSkillLaunchTimingEnum timing, IPassiveSkill passiveSkill) {
		skill.doApply(soldier, target, context, config, timing, passiveSkill);
		context.setDamageOutput(0);// 吸收伤害转换成自身hp
		// 我打你，你敢吸收？那我就要做点事情了
		target.skillHolder().passiveSkillEffectByTiming(target, target.getCommandContext(), PassiveSkillLaunchTimingEnum.TriggerAfterDamageInput);
	}
}
