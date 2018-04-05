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
 * 恢复mp/hp/sp
 * 
 * @author zhanhua.xu
 *
 */
@Service
public class PassiveSkillLogic_84 extends AbstractPassiveSkillLogic {
	@Override
	protected void doApply(BattleSoldier soldier, BattleSoldier target, CommandContext context, PassiveSkillConfig config, PassiveSkillLaunchTimingEnum timing, IPassiveSkill passiveSkill) {
		if (soldier.isDead())
			return;
		if (context == null)
			return;

		int value = (int) calcLevelValue(context, soldier, target, config.getPropertyEffectFormulas()[0]);
		if (value <= 0)
			return;
		int property = config.getPropertys()[0];
		if (property == BattleBasePropertyType.Hp.ordinal()) {
			soldier.increaseHp(value);
			context.skillAction().addTargetState(new VideoActionTargetState(soldier, value, 0, false));
		} else if (property == BattleBasePropertyType.Mp.ordinal()) {
			soldier.increaseMp(value);
			context.skillAction().addTargetState(new VideoActionTargetState(soldier, 0, value, false));
		} else if (property == BattleBasePropertyType.Sp.ordinal()) {
			soldier.increaseSp(value);
			context.skillAction().addTargetState(new VideoActionTargetState(soldier, 0, 0, false, value));
		}
	}

	private float calcLevelValue(CommandContext context, BattleSoldier soldier, BattleSoldier target, String formula) {
		Map<String, Object> params = new HashMap<String, Object>();
		params.put("damage", context.getTotalHpVaryAmount());
		params.put("level", soldier.grade());
		params.put("self", soldier);
		params.put("target", target);
		return ScriptService.getInstance().calcuFloat("", formula, params, false);
	}
}
