package com.nucleus.logic.core.modules.battle.logic;

import java.util.HashMap;
import java.util.Map;

import org.springframework.stereotype.Service;

import com.nucleus.logic.core.modules.battle.data.PassiveSkillConfig;
import com.nucleus.logic.core.modules.battle.data.PassiveSkillLaunchTimingEnum;
import com.nucleus.logic.core.modules.battle.dto.VideoActionTargetState;
import com.nucleus.logic.core.modules.battle.model.BattleSoldier;
import com.nucleus.logic.core.modules.battle.model.CommandContext;
import com.nucleus.player.service.ScriptService;

/**
 * 反震伤害
 * 
 * @author wgy
 *
 */
@Service
public class PassiveSkillLogic_5 extends AbstractPassiveSkillLogic {
	@Override
	protected void doApply(BattleSoldier soldier, BattleSoldier target, CommandContext context, PassiveSkillConfig config, PassiveSkillLaunchTimingEnum timing, IPassiveSkill passiveSkill) {
		BattleSoldier trigger = context.trigger();
		int skillLevel = soldier.skillLevel(passiveSkill.getId());
		int hp = calcValue(soldier, context, config, skillLevel);
		trigger.decreaseHp(hp, target);
		context.skillAction().addTargetState(new VideoActionTargetState(trigger, hp, 0, false));
		if (!context.isStrokeBack()) {
			context.setStrokeBack(true);
			soldier.skillHolder().passiveSkillEffectByTiming(soldier, context, PassiveSkillLaunchTimingEnum.StrokeBack);
		}
	}

	private int calcValue(BattleSoldier soldier, CommandContext context, PassiveSkillConfig config, int skillLevel) {
		String formula = config.getPropertyEffectFormulas()[0];
		Map<String, Object> params = new HashMap<String, Object>();
		params.put("damage", context.getDamageOutput());
		params.put("skillLevel", skillLevel);
		params.put("level", soldier.grade());
		int damage = ScriptService.getInstance().calcuInt("", formula, params, false);
		return damage;
	}
}
