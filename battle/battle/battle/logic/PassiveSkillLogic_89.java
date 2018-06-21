package com.nucleus.logic.core.modules.battle.logic;

import java.util.HashMap;
import java.util.Map;

import org.springframework.stereotype.Service;

import com.nucleus.logic.core.modules.battle.data.PassiveSkillConfig;
import com.nucleus.logic.core.modules.battle.data.PassiveSkillLaunchTimingEnum;
import com.nucleus.logic.core.modules.battle.dto.VideoActionTargetState;
import com.nucleus.logic.core.modules.battle.model.BattleSoldier;
import com.nucleus.logic.core.modules.battle.model.CommandContext;
import com.nucleus.logic.core.modules.battlebuff.data.BattleBuff.BattleBasePropertyType;
import com.nucleus.player.service.ScriptService;

/**
 * 伤害输出恢复怒气值
 * 
 * @author hwy
 *
 */
@Service
public class PassiveSkillLogic_89 extends PassiveSkillLogic_2 {
	@Override
	protected void doApply(BattleSoldier soldier, BattleSoldier target, CommandContext context, PassiveSkillConfig config, PassiveSkillLaunchTimingEnum timing, IPassiveSkill passiveSkill) {
		super.doApply(soldier, target, context, config, timing, passiveSkill);

		int property = config.getPropertys()[1];
		int skillLevel = soldier.skillLevel(passiveSkill.getId());
		int value = calcLevelValue(config.getPropertyEffectFormulas()[1], skillLevel);
		if (property == BattleBasePropertyType.Sp.ordinal()) {
			soldier.increaseSp(value);
			context.skillAction().addTargetState(new VideoActionTargetState(soldier, 0, 0, false, value));
		}
	}

	private int calcLevelValue(String formula, int skillLevel) {
		Map<String, Object> params = new HashMap<String, Object>();
		params.put("skillLevel", skillLevel);
		return ScriptService.getInstance().calcuInt("PassiveSkillLogic_89.calcLevelValue", formula, params, false);
	}
}
