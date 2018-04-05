package com.nucleus.logic.core.modules.battle.ai.rules;

import java.util.Map;

import com.nucleus.commons.utils.SpringUtils;
import com.nucleus.logic.core.modules.battle.data.Skill;
import com.nucleus.logic.core.modules.battle.logic.TargetSelectLogic_7;
import com.nucleus.logic.core.modules.battle.model.BattleSoldier;
import com.nucleus.logic.core.modules.battle.model.CommandContext;

/**
 * 防御排序，最高优先
 * <p>
 * Created by hwy on 17/6/7.
 */
public class SkillAITarget_17 extends DefaultSkillAITarget {

	private TargetSelectLogic_7 proxy = null;

	public SkillAITarget_17(String ruleStr) {

	}

	@Override
	public BattleSoldier select(BattleSoldier trigger, Skill skill, CommandContext ctx) {
		if (proxy == null) {
			proxy = SpringUtils.getBeanOfType(TargetSelectLogic_7.class);
		}
		final CommandContext checkContext = new CommandContext(trigger, skill, null);
		final Map<Long, BattleSoldier> availableTargets = skill.skillAi().skillAiLogic().availableTargets(checkContext);
		return proxy.select(availableTargets, checkContext, null);
	}
}
