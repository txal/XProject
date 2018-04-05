package com.nucleus.logic.core.modules.battle.ai.rules;

import com.nucleus.commons.utils.SplitUtils;
import com.nucleus.logic.core.modules.battle.data.Skill;
import com.nucleus.logic.core.modules.battle.model.BattleSoldier;
import com.nucleus.logic.core.modules.battle.model.CommandContext;

import org.apache.commons.lang3.math.NumberUtils;

import java.util.ArrayList;
import java.util.List;

/**
 * [camp]至少[count]个单位HP＜[rate]
 * <p>
 * Created by Tony on 15/6/19.
 */
public class SkillAICondition_2 extends DefaultSkillAICondition {

	private final int camp;

	private final float rate;

	private final int count;

	private final boolean ignoreGhost;

	public SkillAICondition_2(String ruleStr) {
		final String[] ruleInfo = SplitUtils.split2StringArray(ruleStr, ":");
		camp = NumberUtils.toInt(ruleInfo[0]);
		count = NumberUtils.toInt(ruleInfo[1]);
		rate = NumberUtils.toFloat(ruleInfo[2]);
		if (ruleInfo.length > 3) {
			this.ignoreGhost = NumberUtils.toFloat(ruleInfo[3]) > 0;
		} else {
			this.ignoreGhost = true;
		}
	}

	@Override
	public boolean isAvailable(BattleSoldier soldier, Skill skill, CommandContext ctx) {
		List<BattleSoldier> soldiers = null;
		if (camp == 0) {
			soldiers = new ArrayList<>(soldier.team().soldiersMap().values());
		} else {
			soldiers = new ArrayList<>(soldier.team().getEnemyTeam().soldiersMap().values());
		}
		int cur = 0;
		for (BattleSoldier battleSoldier : soldiers) {
			if (this.ignoreGhost && battleSoldier.isGhost())
				continue;
			if (battleSoldier.isDead())
				continue;
			if (battleSoldier.hpRate() < rate) {
				cur++;
				if (cur >= this.count) {
					return true;
				}
			}
		}
		return false;
	}

}
