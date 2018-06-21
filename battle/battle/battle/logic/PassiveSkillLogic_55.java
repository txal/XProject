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
 * 暴击率附加
 * 
 * @author wgy
 *
 */
@Service
public class PassiveSkillLogic_55 extends AbstractPassiveSkillLogic {
	@Override
	protected void doApply(BattleSoldier soldier, BattleSoldier target, CommandContext context, PassiveSkillConfig config, PassiveSkillLaunchTimingEnum timing, IPassiveSkill passiveSkill) {
		String formula = config.getPropertyEffectFormulas()[0];
		Map<String, Object> params = new HashMap<String, Object>();
		params.put("self", soldier);
		params.put("level", soldier.grade());
		params.put("skillLevel", soldier.skillLevel(passiveSkill.getId()));
		float rate = ScriptService.getInstance().calcuFloat("", formula, params, false);
		context.setCritRatePlus(rate);
	}
}
