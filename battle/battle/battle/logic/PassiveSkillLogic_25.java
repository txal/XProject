package com.nucleus.logic.core.modules.battle.logic;

import java.util.HashMap;
import java.util.List;
import java.util.Map;

import org.apache.commons.lang3.StringUtils;
import org.springframework.stereotype.Service;

import com.nucleus.logic.core.modules.battle.data.PassiveSkillConfig;
import com.nucleus.logic.core.modules.battle.model.BattleSoldier;
import com.nucleus.logic.core.modules.battlebuff.data.BattleBuff.BattleBasePropertyType;
import com.nucleus.player.service.ScriptService;

/**
 * 战斗中影响属性
 * 
 * @author wgy
 *
 */
@Service
public class PassiveSkillLogic_25 extends AbstractPassiveSkillLogic {
	@Override
	public float propertyEffect(BattleSoldier soldier, BattleBasePropertyType property, PassiveSkillConfig config, IPassiveSkill passiveSkill) {
		if (!launchable(soldier, config, passiveSkill))
			return 0;
		float v = 0;
		int skillLevel = soldier.skillLevel(passiveSkill.getId());
		for (int i = 0; i < config.getPropertys().length; i++) {
			if (config.getPropertys()[i] != property.ordinal())
				continue;
			String formula = config.getPropertyEffectFormulas()[i];
			if (StringUtils.isBlank(formula))
				continue;
			v += calcPropertyEffectFormula(soldier, skillLevel, formula);
			break;
		}
		return v;
	}

	private boolean launchable(BattleSoldier soldier, PassiveSkillConfig config, IPassiveSkill passiveSkill) {
		List<AbstractPassiveSkillLaunchCondition> conditions = config.launchConditions();
		if (conditions == null || conditions.isEmpty())
			return true;
		for (AbstractPassiveSkillLaunchCondition condition : config.launchConditions()) {
			if (!condition.launchable(soldier, null, null, passiveSkill))
				return false;
		}
		return true;
	}

	private float calcPropertyEffectFormula(BattleSoldier soldier, int skillLevel, String formula) {
		Map<String, Object> params = new HashMap<String, Object>();
		params.put("level", soldier.grade());
		params.put("trigger", soldier);
		params.put("skillLevel", skillLevel);
		float v = ScriptService.getInstance().calcuFloat("", formula, params, false);
		return v;
	}
}
