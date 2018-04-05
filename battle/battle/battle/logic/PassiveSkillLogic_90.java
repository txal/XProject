package com.nucleus.logic.core.modules.battle.logic;

import java.util.HashMap;
import java.util.Map;

import org.springframework.stereotype.Service;

import com.nucleus.commons.data.StaticConfig;
import com.nucleus.logic.core.modules.AppStaticConfigs;
import com.nucleus.logic.core.modules.battle.data.PassiveSkillConfig;
import com.nucleus.logic.core.modules.battle.data.PassiveSkillLaunchTimingEnum;
import com.nucleus.logic.core.modules.battle.dto.VideoActionTargetState;
import com.nucleus.logic.core.modules.battle.model.BattleSoldier;
import com.nucleus.logic.core.modules.battle.model.CommandContext;
import com.nucleus.logic.core.modules.battlebuff.data.BattleBuff.BattleBasePropertyType;
import com.nucleus.player.service.ScriptService;

/**
 * 减少敌方mp/hp/sp
 * 
 * @author hwy
 *
 */
@Service
public class PassiveSkillLogic_90 extends AbstractPassiveSkillLogic {
	@Override
	protected void doApply(BattleSoldier soldier, BattleSoldier target, CommandContext context, PassiveSkillConfig config, PassiveSkillLaunchTimingEnum timing, IPassiveSkill passiveSkill) {
		if (target.isDead() || context == null || target.hasSkill(StaticConfig.get(AppStaticConfigs.SCENE_DOG_SPECIAL_SKILL).getAsInt(6988)))
			return;
		int skillLevel = soldier.skillLevel(passiveSkill.getId());
		int[] properties = config.getPropertys();
		for (int i = 0; i < properties.length; i++) {
			int property = properties[i];
			int value = (int) calcLevelValue(config.getPropertyEffectFormulas()[i], target, skillLevel);
			if (value >= 0)
				return;
			if (property == BattleBasePropertyType.Hp.ordinal()) {
				target.decreaseHp(value);
				context.skillAction().addTargetState(new VideoActionTargetState(target, value, 0, false));
			} else if (property == BattleBasePropertyType.Mp.ordinal()) {
				target.decreaseMp(value);
				context.skillAction().addTargetState(new VideoActionTargetState(target, 0, value, false));
			} else if (property == BattleBasePropertyType.Sp.ordinal()) {
				target.decreaseSp(value);
				context.skillAction().addTargetState(new VideoActionTargetState(target, 0, 0, false, value));
			}
		}
	}

	private float calcLevelValue(String formula, BattleSoldier target, int skillLevel) {
		Map<String, Object> params = new HashMap<String, Object>();
		params.put("target", target);
		params.put("skillLevel", skillLevel);
		return ScriptService.getInstance().calcuFloat("", formula, params, false);
	}
}
