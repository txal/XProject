/**
 * 
 */
package com.nucleus.logic.core.modules.battle.logic;

import java.util.HashMap;
import java.util.Map;

import org.springframework.stereotype.Service;

import com.nucleus.logic.core.modules.battle.model.BattlePlayerSoldierInfo;
import com.nucleus.logic.core.modules.battle.model.BattleSoldier;
import com.nucleus.logic.core.modules.battle.model.BattleTeam;
import com.nucleus.logic.core.modules.battle.model.CommandContext;

/**
 * 仅己方全部宠物
 * 
 * @author liguo
 * 
 */
@Service
public class SkillAiLogic_5 extends SkillAiLogicAdapter {
	@Override
	public Map<Long, BattleSoldier> availableTargets(CommandContext commandContext) {
		Map<Long, BattleSoldier> map = new HashMap<Long, BattleSoldier>();
		BattleTeam myTeam = commandContext.trigger().team();
		for (BattlePlayerSoldierInfo info : myTeam.playerSoldierInfos()) {
			BattleSoldier petSoldier = myTeam.battleSoldier(info.petSoldierId());
			if (petSoldier != null)
				map.put(petSoldier.getId(), petSoldier);
		}
		return map;
	}
}
