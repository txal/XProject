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
 * 己方所有单位，包括己方全部人的宠物
 * 
 * @author liguo
 * 
 */
@Service
public class SkillAiLogic_4 extends SkillAiLogicAdapter {

	@Override
	public Map<Long, BattleSoldier> availableTargets(CommandContext commandContext) {
		Map<Long, BattleSoldier> map = new HashMap<Long, BattleSoldier>(commandContext.trigger().team().soldiersMap());
		return map;
	}
}
