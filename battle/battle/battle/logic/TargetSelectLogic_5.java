package com.nucleus.logic.core.modules.battle.logic;

import java.util.List;
import java.util.Map;
import java.util.Set;
import java.util.stream.Collectors;

import org.springframework.stereotype.Service;

import com.nucleus.logic.core.modules.battle.model.BattleSoldier;
import com.nucleus.logic.core.modules.battle.model.CommandContext;

/**
 * 封印目标随机选择
 * 
 * @author wgy
 *
 */
@Service
public class TargetSelectLogic_5 extends TargetSelectLogic_0 {
	@Override
	public List<BattleSoldier> filter(Map<Long, BattleSoldier> availableTargets, CommandContext commandContext, Set<Long> ignoreSoldierIds) {
		List<BattleSoldier> targets = super.filter(availableTargets, commandContext, ignoreSoldierIds).stream().filter(s -> s.buffHolder().hasBanBuff()).collect(Collectors.toList());
		return targets;
	}
}
