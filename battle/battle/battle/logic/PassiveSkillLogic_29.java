package com.nucleus.logic.core.modules.battle.logic;

import java.util.HashMap;
import java.util.Map;

import org.springframework.stereotype.Service;

import com.nucleus.logic.core.modules.battle.data.PassiveSkillConfig;
import com.nucleus.logic.core.modules.battle.data.PassiveSkillLaunchTimingEnum;
import com.nucleus.logic.core.modules.battle.model.BattleSoldier;
import com.nucleus.logic.core.modules.battle.model.CommandContext;
import com.nucleus.player.service.ScriptService;

/**
 * 药效增强
 * 
 * @author wgy
 *
 */
@Service
public class PassiveSkillLogic_29 extends AbstractPassiveSkillLogic {
	@Override
	protected void doApply(BattleSoldier soldier, BattleSoldier target, CommandContext context, PassiveSkillConfig config, PassiveSkillLaunchTimingEnum timing, IPassiveSkill passiveSkill) {
		if (config.getExtraParams() != null && config.getExtraParams().length > 0) {
			float r = context.getDrugEffectRate();

			String formula = config.getExtraParams()[0];
			Map<String, Object> params = new HashMap<String, Object>();
			int skillLevel = soldier.skillLevel(passiveSkill.getId());
			params.put("level", soldier.grade());
			params.put("skillLevel", skillLevel);

			Float effectRate = ScriptService.getInstance().calcuFloat("PassiveSkillLogic_29", formula, params, false);
			r += effectRate;
			context.setDrugEffectRate(r);
		}
	}
}
