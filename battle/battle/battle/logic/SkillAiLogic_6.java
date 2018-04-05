/**
 * 
 */
package com.nucleus.logic.core.modules.battle.logic;

import java.util.HashMap;
import java.util.Map;

import org.springframework.stereotype.Service;

import com.nucleus.logic.core.modules.battle.model.BattleSoldier;
import com.nucleus.logic.core.modules.battle.model.BattleTeam;
import com.nucleus.logic.core.modules.battle.model.CommandContext;

/**
 * 除自己外双方全部士兵
 * 
 * @author liguo
 * 
 */
@Service
public class SkillAiLogic_6 extends SkillAiLogicAdapter {

	@Override
	public Map<Long, BattleSoldier> availableTargets(CommandContext commandContext) {
		Map<Long, BattleSoldier> targetsMap = new HashMap<Long, BattleSoldier>();
		BattleTeam myTeam = commandContext.trigger().team();
		targetsMap.putAll(myTeam.soldiersMap());
		targetsMap.putAll(myTeam.getEnemyTeam().soldiersMap());
		targetsMap.remove(commandContext.trigger().getId());
		return targetsMap;
	}
}
