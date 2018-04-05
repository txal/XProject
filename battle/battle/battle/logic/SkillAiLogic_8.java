package com.nucleus.logic.core.modules.battle.logic;

import java.util.Collections;
import java.util.HashMap;
import java.util.Map;

import org.springframework.stereotype.Service;

import com.nucleus.logic.core.modules.battle.model.BattleSoldier;
import com.nucleus.logic.core.modules.battle.model.CommandContext;

/**
 * 伴侣
 * 
 * @author wgy
 *
 */
@Service
public class SkillAiLogic_8 extends SkillAiLogicAdapter {

	@Override
	public Map<Long, BattleSoldier> availableTargets(CommandContext commandContext) {
		BattleSoldier trigger = commandContext.trigger();
		if (trigger.fereId() < 1)
			return Collections.emptyMap();
		BattleSoldier fere = trigger.battleTeam().soldier(trigger.fereId());
		if (fere == null)
			return Collections.emptyMap();
		Map<Long, BattleSoldier> targetMaps = new HashMap<>();
		targetMaps.put(fere.getId(), fere);
		return targetMaps;
	}

}
