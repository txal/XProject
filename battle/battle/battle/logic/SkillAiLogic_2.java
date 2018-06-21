/**
 * 
 */
package com.nucleus.logic.core.modules.battle.logic;

import java.util.HashMap;
import java.util.Map;

import org.springframework.stereotype.Service;

import com.nucleus.logic.core.modules.battle.model.BattleSoldier;
import com.nucleus.logic.core.modules.battle.model.CommandContext;

/**
 * 仅自身
 * 
 * @author liguo
 * 
 */
@Service
public class SkillAiLogic_2 extends SkillAiLogicAdapter {

	@Override
	public Map<Long, BattleSoldier> availableTargets(CommandContext commandContext) {
		BattleSoldier trigger = commandContext.trigger();
		Map<Long, BattleSoldier> map = new HashMap<Long, BattleSoldier>();
		map.put(trigger.getId(), trigger);
		return map;
	}

}
