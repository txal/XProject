package com.nucleus.logic.core.modules.battle.ai.rules;

import java.util.ArrayList;
import java.util.List;
import java.util.Map;

import org.apache.commons.lang3.math.NumberUtils;

import com.nucleus.commons.utils.SplitUtils;
import com.nucleus.commons.utils.SpringUtils;
import com.nucleus.logic.core.modules.battle.data.Skill;
import com.nucleus.logic.core.modules.battle.logic.TargetSelectLogic_1;
import com.nucleus.logic.core.modules.battle.model.BattleSoldier;
import com.nucleus.logic.core.modules.battle.model.CommandContext;
import com.nucleus.logic.core.modules.battle.model.RoundContext;
import com.nucleus.logic.core.modules.battle.model.RoundContext.RoundState;

/**
 * 血量排序，最小优先
 * <p>
 * Created by Tony on 15/6/19.
 */
public class SkillAITarget_1 extends DefaultSkillAITarget {

	private TargetSelectLogic_1 proxy = null;

	private boolean ignoreGhost = false;
	private int ignoreBuffId;

	public SkillAITarget_1(String ruleStr) {
		final String[] ruleInfo = SplitUtils.split2StringArray(ruleStr, ":");
		if (ruleInfo.length > 0) {
			this.ignoreGhost = NumberUtils.toInt(ruleInfo[0]) > 0;
			if (ruleInfo.length > 1)
				this.ignoreBuffId = NumberUtils.toInt(ruleInfo[1]);
		}
	}

	@Override
	public BattleSoldier select(BattleSoldier trigger, Skill skill, CommandContext ctx) {
		if (proxy == null) {
			proxy = SpringUtils.getBeanOfType(TargetSelectLogic_1.class);
		}
		final CommandContext checkContext = new CommandContext(trigger, skill, null);
		final Map<Long, BattleSoldier> availableTargets = skill.skillAi().skillAiLogic().availableTargets(checkContext);
		final RoundContext roundContext = trigger.roundContext();
		boolean roundStart = roundContext != null && roundContext.getState() == RoundState.RoundStart;
		final int skillId = skill.getId();
		if (ignoreGhost || ignoreBuffId > 0) {
			final List<BattleSoldier> soldiers = new ArrayList<>(availableTargets.values());
			for (BattleSoldier bs : soldiers) {
				if (ignoreGhost && bs.isGhost()) {
					availableTargets.remove(bs.getId());
				} else if (ignoreBuffId > 0) {
					if (bs.buffHolder().hasBuff(ignoreBuffId) || (roundStart && roundContext.isTargetBySkill(bs.getId(), skillId)))
						availableTargets.remove(bs.getId());
				}
			}
		}

		return proxy.select(availableTargets, checkContext, null);
	}
}
