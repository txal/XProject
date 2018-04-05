package com.nucleus.logic.core.modules.battle.ai.rules;

import java.util.ArrayList;
import java.util.List;
import java.util.Map;

import com.nucleus.logic.core.modules.battle.data.Skill;
import com.nucleus.logic.core.modules.battle.model.BattleSoldier;
import com.nucleus.logic.core.modules.battle.model.CommandContext;
import com.nucleus.logic.core.modules.battlebuff.data.BattleBuff;
import com.nucleus.logic.core.modules.battlebuff.model.BattleBuffEntity;

/**
 * 默认不限制使用 Created by Tony on 15/6/19.
 */
public class DefaultSkillAICondition implements SkillAICondition {

	@Override
	public boolean isAvailable(BattleSoldier soldier, Skill skill, CommandContext ctx) {
		return true;
	}

	protected List<BattleSoldier> getAvailableTargets(BattleSoldier soldier, Skill skill) {
		final CommandContext checkContext = new CommandContext(soldier, skill, null);
		final Map<Long, BattleSoldier> availableTargets = skill.skillAi().skillAiLogic().availableTargets(checkContext);
		return new ArrayList<>(availableTargets.values());
	}

	protected boolean hasBanState(BattleSoldier soldier) {
		for (BattleBuffEntity buffEntity : soldier.buffHolder().allBuffs().values()) {
			if (buffEntity.battleBuff().getBuffClassType() == BattleBuff.BuffClassTypeEnum.Ban.ordinal()) {
				return true;
			}
		}
		return false;
	}
}
