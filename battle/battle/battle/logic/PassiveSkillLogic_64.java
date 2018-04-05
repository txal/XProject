/**
 * 
 */
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
 * 目标防御变化
 * 
 * @author xitao.huang
 *
 */
@Service
public class PassiveSkillLogic_64 extends AbstractPassiveSkillLogic {

	public PassiveSkillLogic_64() {
	}

	@Override
	protected void doApply(BattleSoldier soldier, BattleSoldier target, CommandContext context, PassiveSkillConfig config, PassiveSkillLaunchTimingEnum timing, IPassiveSkill passiveSkill) {
		if (context == null)
			return;
		String formula = config.getPropertyEffectFormulas()[0];
		if (StringUtils.isNotBlank(formula)) {
			int grade = soldier.grade();
			int skillLevel = soldier.battleUnit().battleSkillHolder().skillLevel(passiveSkill.getId());
			Map<String, Object> params = new HashMap<String, Object>();
			params.put("level", grade);
			params.put("skillLevel", skillLevel);
			params.put("target", target);
			params.put("selft", soldier);

			Float defence = ScriptService.getInstance().calcuFloat("", formula, params, false);
			int property = config.getPropertys()[0];
			target.battleBaseProperties().applyOf(BattleBasePropertyType.values()[property], defence);
		}

	}
}
