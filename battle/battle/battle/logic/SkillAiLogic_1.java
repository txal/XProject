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
 * 选择敌方目标
 * 
 * @author liguo
 * 
 */
@Service
public class SkillAiLogic_1 extends SkillAiLogicAdapter {

	@Override
	public Map<Long, BattleSoldier> availableTargets(CommandContext commandContext) {
		BattleTeam enemyTeam = commandContext.trigger().team().getEnemyTeam();
		return new HashMap<Long, BattleSoldier>(enemyTeam.soldiersMap());
	}

}
