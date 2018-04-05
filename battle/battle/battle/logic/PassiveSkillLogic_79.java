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
 * 伤害吸收
 * 
 * @author hwy
 *
 */
@Service
public class PassiveSkillLogic_79 extends AbstractPassiveSkillLogic {

	@Override
	protected void doApply(BattleSoldier soldier, BattleSoldier target, CommandContext context, PassiveSkillConfig config, PassiveSkillLaunchTimingEnum timing, IPassiveSkill passiveSkill) {
		int skillLevel = soldier.skillLevel(passiveSkill.getId());
		int val = calcValue(context, config, skillLevel);
		val = Math.abs(val);
		int property = config.getPropertys()[0];
		if (property == BattleBasePropertyType.Hp.ordinal()) {
			soldier.increaseHp(val);
			context.skillAction().addTargetState(new VideoActionTargetState(soldier, val, 0, false));
		} else if (property == BattleBasePropertyType.Mp.ordinal()) {
			soldier.increaseMp(val);
			context.skillAction().addTargetState(new VideoActionTargetState(soldier, 0, val, false));
		} else if (property == BattleBasePropertyType.Sp.ordinal()) {
			soldier.increaseSp(val);
			context.skillAction().addTargetState(new VideoActionTargetState(soldier, 0, 0, false, val));
		}
	}

	private int calcValue(CommandContext context, PassiveSkillConfig config, int skillLevel) {
		Map<String, Object> params = new HashMap<String, Object>();
		params.put("damage", context.getDamageOutput());
		params.put("skillLevel", skillLevel);
		int hp = ScriptService.getInstance().calcuInt("", config.getPropertyEffectFormulas()[0], params, false);
		return hp;
	}
}
