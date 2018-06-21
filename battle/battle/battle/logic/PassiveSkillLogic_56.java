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
 * 被封印机率降低
 * 
 * @author wgy
 *
 */
@Service
public class PassiveSkillLogic_56 extends AbstractPassiveSkillLogic {
	@Override
	protected void doApply(BattleSoldier soldier, BattleSoldier target, CommandContext context, PassiveSkillConfig config, PassiveSkillLaunchTimingEnum timing, IPassiveSkill passiveSkill) {
		String formula = config.getPropertyEffectFormulas()[0];
		Map<String, Object> params = new HashMap<String, Object>();
		int skillLevel = soldier.skillLevel(passiveSkill.getId());
		params.put("level", soldier.grade());
		params.put("skillLevel", skillLevel);
		params.put("self", soldier);

		Float rate = ScriptService.getInstance().calcuFloat("PassiveSkillLogic_56", formula, params, false);
		context.setBeBuffRate(rate);
	}
}
