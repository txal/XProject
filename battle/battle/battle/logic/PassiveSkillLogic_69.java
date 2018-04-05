package com.nucleus.logic.core.modules.battle.logic;

import java.util.HashMap;
import java.util.Map;

import org.apache.commons.lang3.StringUtils;
import org.springframework.stereotype.Service;

import com.nucleus.logic.core.modules.battle.data.PassiveSkillConfig;
import com.nucleus.logic.core.modules.battle.data.PassiveSkillLaunchTimingEnum;
import com.nucleus.logic.core.modules.battle.model.BattleSoldier;
import com.nucleus.logic.core.modules.battle.model.CommandContext;
import com.nucleus.logic.core.modules.battlebuff.data.BattleBuff.BattleBasePropertyType;
import com.nucleus.player.service.ScriptService;

/**
 * 改变施放技能hp需求
 * 
 * @author wgy
 *
 */
@Service
public class PassiveSkillLogic_69 extends AbstractPassiveSkillLogic {
	
	@Override
	protected void doApply(BattleSoldier soldier, BattleSoldier target, CommandContext context, PassiveSkillConfig config, PassiveSkillLaunchTimingEnum timing, IPassiveSkill passiveSkill) {
		int property = config.getPropertys()[0];
		if (config.getPropertyEffectFormulas() != null && config.getPropertyEffectFormulas().length > 0) {
			String formula = config.getPropertyEffectFormulas()[0];
			int value = 0;
			if (StringUtils.isNotBlank(formula)) {
				if (property == BattleBasePropertyType.MinFireHp.ordinal()) {
					value = calcValue(context, formula);
					context.setMinFireHp(value);
				} else if (property == BattleBasePropertyType.MaxFireHp.ordinal()) {
					value = calcValue(context, formula);
					context.setMaxFireHp(value);
				}
			}
		}
	}

	private int calcValue(CommandContext context, String formula) {
		Map<String, Object> params = new HashMap<>();
		params.put("trigger", context.trigger());
		return ScriptService.getInstance().calcuInt("", formula, params, false);
	}
}
