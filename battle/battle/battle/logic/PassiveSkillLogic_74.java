package com.nucleus.logic.core.modules.battle.logic;

import java.util.HashMap;
import java.util.Map;
import java.util.Optional;

import org.springframework.stereotype.Service;

import com.nucleus.logic.core.modules.battle.data.PassiveSkillConfig;
import com.nucleus.logic.core.modules.battle.data.PassiveSkillLaunchTimingEnum;
import com.nucleus.logic.core.modules.battle.dto.VideoActionTargetState;
import com.nucleus.logic.core.modules.battle.model.BattleSoldier;
import com.nucleus.logic.core.modules.battle.model.CommandContext;
import com.nucleus.logic.core.modules.battlebuff.data.BattleBuff.BattleBasePropertyType;
import com.nucleus.player.service.ScriptService;

/**
 * 恢复hp/mp最低单位
 * 
 * @author wgy
 *
 */
@Service
public class PassiveSkillLogic_74 extends AbstractPassiveSkillLogic {

	@Override
	protected void doApply(BattleSoldier soldier, BattleSoldier target, CommandContext context, PassiveSkillConfig config, PassiveSkillLaunchTimingEnum timing, IPassiveSkill passiveSkill) {
		final int property = config.getPropertys()[0];
		Optional<BattleSoldier> opt = soldier.team().aliveSoldiers().stream().sorted((s1, s2) -> {
			if (property == BattleBasePropertyType.Hp.ordinal())
				return s1.hp() - s2.hp();
			else if (property == BattleBasePropertyType.Mp.ordinal())
				return s1.mp() - s2.mp();
			return 0;
		}).findFirst();
		if (!opt.isPresent())
			return;
		target = opt.get();
		final int value = calcValue(target, config.getPropertyEffectFormulas()[0]);
		VideoActionTargetState state = new VideoActionTargetState(target, 0, 0, false);
		if (property == BattleBasePropertyType.Hp.ordinal()) {
			target.increaseHp(value);
			state.setHp(value);
		} else if (property == BattleBasePropertyType.Mp.ordinal()) {
			target.increaseMp(value);
			state.setMp(value);
		}
		if (context != null)
			context.skillAction().addTargetState(state);
	}

	private int calcValue(BattleSoldier target, String formula) {
		Map<String, Object> params = new HashMap<>();
		params.put("target", target);
		int v = ScriptService.getInstance().calcuInt("", formula, params, false);
		return v;
	}
}
