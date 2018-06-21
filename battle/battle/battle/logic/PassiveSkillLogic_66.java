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
 * 暴击时变动暴击时伤害率
 * 
 * @author zhanhua.xu
 *
 */
@Service
public class PassiveSkillLogic_66 extends AbstractPassiveSkillLogic {
	@Override
	protected void doApply(BattleSoldier soldier, BattleSoldier target, CommandContext context, PassiveSkillConfig config, PassiveSkillLaunchTimingEnum timing, IPassiveSkill passiveSkill) {
		float critHurtRate = context.getCritHurtRate();
		int skillLevel = soldier.skillLevel(passiveSkill.getId());
		float rate = calcLevelValue(soldier, config.getPropertyEffectFormulas()[0], context, skillLevel);
		BattleSoldier t = context.target() != null ? context.target() : context.getFirstTarget();
		if ((rate > 0 && context.trigger().getId() == soldier.getId()) || (rate < 0 && t != null && t.getId() == soldier.getId())) {
			critHurtRate += rate;
			context.setCritHurtRate(critHurtRate);
		}
	}

	private float calcLevelValue(BattleSoldier soldier, String formula, CommandContext context, int skillLevel) {
		Map<String, Object> params = new HashMap<String, Object>();
		params.put("skillLevel", skillLevel);
		params.put("level", soldier.grade());
		return ScriptService.getInstance().calcuFloat("", formula, params, false);
	}
}
