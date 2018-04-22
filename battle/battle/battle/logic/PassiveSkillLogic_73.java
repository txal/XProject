package com.nucleus.logic.core.modules.battle.logic;

import java.util.HashMap;
import java.util.List;
import java.util.Map;
import java.util.stream.Collectors;

import org.apache.commons.collections.CollectionUtils;
import org.springframework.stereotype.Service;

import com.nucleus.logic.core.modules.battle.data.PassiveSkillConfig;
import com.nucleus.logic.core.modules.battle.data.PassiveSkillLaunchTimingEnum;
import com.nucleus.logic.core.modules.battle.dto.VideoActionTargetState;
import com.nucleus.logic.core.modules.battle.model.BattleSoldier;
import com.nucleus.logic.core.modules.battle.model.CommandContext;
import com.nucleus.logic.core.modules.battlebuff.data.BattleBuff.BattleBasePropertyType;
import com.nucleus.player.service.ScriptService;

/**
 * 离场恢复全体宠物和子女血量
 * 
 * @author wgy
 *
 */
@Service
public class PassiveSkillLogic_73 extends AbstractPassiveSkillLogic {

	@Override
	protected void doApply(BattleSoldier soldier, BattleSoldier target, CommandContext context, PassiveSkillConfig config, PassiveSkillLaunchTimingEnum timing, IPassiveSkill passiveSkill) {
		List<BattleSoldier> targets = soldier.team().aliveSoldiers().stream().filter(s -> s.ifPet() || s.ifChild()).collect(Collectors.toList());
		if (CollectionUtils.isEmpty(targets))
			return;
		for (BattleSoldier s : targets) {
			VideoActionTargetState state = new VideoActionTargetState(s, 0, 0, false);
			for (int i = 0; i < config.getPropertys().length; i++) {
				final int property = config.getPropertys()[i];
				final int value = calcValue(s, config.getPropertyEffectFormulas()[i]);
				if (property == BattleBasePropertyType.Hp.ordinal()) {
					s.increaseHp(value);
					state.setHp(value);
				} else if (property == BattleBasePropertyType.Mp.ordinal()) {
					s.increaseMp(value);
					state.setMp(value);
				}
			}
			if (context != null)
				context.skillAction().addTargetState(state);
		}
	}

	private int calcValue(BattleSoldier target, String formula) {
		Map<String, Object> params = new HashMap<>();
		params.put("target", target);
		int v = ScriptService.getInstance().calcuInt("", formula, params, false);
		return v;
	}
}
