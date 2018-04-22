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
 * 技能消耗减免
 * 
 * @author wgy
 *
 */
@Service
public class PassiveSkillLogic_13 extends AbstractPassiveSkillLogic {
	@Override
	protected void doApply(BattleSoldier soldier, BattleSoldier target, CommandContext context, PassiveSkillConfig config, PassiveSkillLaunchTimingEnum timing, IPassiveSkill passiveSkill) {
		int property = config.getPropertys()[0];
		int value = 0;
		int skillLevel = soldier.skillLevel(passiveSkill.getId());
		if (config.getPropertyEffectFormulas() != null && config.getPropertyEffectFormulas().length > 0) {
			String formula = config.getPropertyEffectFormulas()[0];
			if (StringUtils.isNotBlank(formula)) {
				if (property == BattleBasePropertyType.Hp.ordinal()) {
					value = calcValue(skillLevel, context.getHpSpent(), formula);
				} else if (property == BattleBasePropertyType.Mp.ordinal()) {
					value = calcValue(skillLevel, context.getMpSpent(), formula);
				} else if (property == BattleBasePropertyType.Sp.ordinal()) {
					value = calcValue(skillLevel, context.getSpSpent(), formula);
				}
			}
		}
		if (property == BattleBasePropertyType.Hp.ordinal()) {
			context.setHpSpent(value);
		} else if (property == BattleBasePropertyType.Mp.ordinal()) {
			context.setMpSpent(value);
		} else if (property == BattleBasePropertyType.Sp.ordinal()) {
			context.setSpSpent(value);
		}
	}

	private int calcValue(int skillLevel, int spend, String formula) {
		if (StringUtils.isBlank(formula))
			return 0;
		Map<String, Object> params = new HashMap<String, Object>();
		params.put("skillLevel", skillLevel);
		params.put("spend", spend);
		return ScriptService.getInstance().calcuInt("", formula, params, false);
	}
}
