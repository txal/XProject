/**
 * 
 */
package com.nucleus.logic.core.modules.battle.logic;

import java.util.HashMap;
import java.util.Iterator;
import java.util.Map;
import java.util.Map.Entry;

import org.springframework.stereotype.Service;

import com.nucleus.logic.core.modules.battle.model.BattleSoldier;
import com.nucleus.logic.core.modules.battle.model.BattleTeam;
import com.nucleus.logic.core.modules.battle.model.CommandContext;

/**
 * 仅己方玩家
 * 
 * @author xitao.huang
 *
 */
@Service
public class SkillAiLogic_10 extends SkillAiLogicAdapter {

	@Override
	public Map<Long, BattleSoldier> availableTargets(CommandContext commandContext) {
		BattleTeam myTeam = commandContext.trigger().team();
		Map<Long, BattleSoldier> map = new HashMap<Long, BattleSoldier>();
		for (Iterator<Entry<Long, BattleSoldier>> iterator = myTeam.soldiersMap().entrySet().iterator(); iterator.hasNext();) {
			Entry<Long, BattleSoldier> entry = iterator.next();
			long id = entry.getKey();
			BattleSoldier battleSoldier = entry.getValue();
			if (battleSoldier.isMainCharactor()) {
				map.put(id, battleSoldier);
			}
		}
		return map;
	}

}
