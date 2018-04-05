package com.nucleus.logic.core.modules.battle.logic;

import java.util.List;

import org.springframework.stereotype.Service;

import com.nucleus.logic.core.modules.battle.model.BattleSoldier;
import com.nucleus.logic.core.modules.battle.model.CommandContext;

/**
 * 按速度触发某技能连续使用
 * 
 * @author hwy
 * 
 */
@Service
public class SkillLogic_14 extends SkillLogic_1 {

	@Override
	protected void afterTargetSelected(CommandContext commandContext, List<SkillTargetPolicy> targetPolicys, BattleSoldier targetSelected) {
		BattleSoldier trigger = commandContext.trigger();
		if (trigger.speed() <= targetSelected.speed())
			targetPolicys.remove(targetPolicys.get(0));
	}
}
