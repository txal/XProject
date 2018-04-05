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
 * 减伤
 * 
 * @author yifan.chen
 *
 */
@Service
public class PassiveSkillLogic_78 extends AbstractPassiveSkillLogic {

	@Override
	protected void doApply(BattleSoldier soldier, BattleSoldier target, CommandContext context, PassiveSkillConfig config, PassiveSkillLaunchTimingEnum timing, IPassiveSkill passiveSkill) {
		if (config.getExtraParams() != null && config.getExtraParams().length > 0) {
			int skillLevel = soldier.skillLevel(passiveSkill.getId());

			Map<String, Object> params = new HashMap<String, Object>();
			params.put("level", soldier.grade());
			params.put("skillLevel", skillLevel);
			Float defenceDamageRate = ScriptService.getInstance().calcuFloat("", config.getExtraParams()[0], params, false);
			context.setProtectorDefenseDamageRate(defenceDamageRate);
		}
	}

}
