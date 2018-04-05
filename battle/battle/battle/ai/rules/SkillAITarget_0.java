package com.nucleus.logic.core.modules.battle.ai.rules;

import com.nucleus.commons.utils.SpringUtils;
import com.nucleus.logic.core.modules.battle.data.Skill;
import com.nucleus.logic.core.modules.battle.logic.TargetSelectLogic_0;
import com.nucleus.logic.core.modules.battle.model.BattleSoldier;
import com.nucleus.logic.core.modules.battle.model.CommandContext;

import java.util.Map;

/**
 * 血量随机选择
 *
 * Created by Tony on 15/6/19.
 */
public class SkillAITarget_0 extends DefaultSkillAITarget {

	private TargetSelectLogic_0 proxy = null;

	public SkillAITarget_0(String ruleStr) {
	}

	@Override
	public BattleSoldier select(BattleSoldier trigger, Skill skill, CommandContext ctx) {
		if (proxy == null) {
			proxy = SpringUtils.getBeanOfType(TargetSelectLogic_0.class);
		}
		final CommandContext checkContext = new CommandContext(trigger, skill, null);
		final Map<Long, BattleSoldier> availableTargets = skill.skillAi().skillAiLogic().availableTargets(checkContext);

		return proxy.select(availableTargets, checkContext, null);
	}
}
