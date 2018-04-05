package com.nucleus.logic.core.modules.battle.ai.rules;

import java.util.List;

import com.nucleus.commons.utils.SplitUtils;
import com.nucleus.logic.core.modules.battle.data.Skill;
import com.nucleus.logic.core.modules.battle.model.BattleSoldier;
import com.nucleus.logic.core.modules.battle.model.CommandContext;
import com.nucleus.logic.core.modules.charactor.data.GeneralCharactor;

/**
 * 所有玩家或者伙伴目标已经倒地或者中封印状态并且存在宠物单位
 * <p>
 * Created by Tony on 15/6/19.
 */
public class SkillAICondition_9 extends DefaultSkillAICondition {

	public SkillAICondition_9(String ruleStr) {
		final String[] ruleInfo = SplitUtils.split2StringArray(ruleStr, ":");
	}

	@Override
	public boolean isAvailable(BattleSoldier soldier, Skill skill, CommandContext ctx) {
		List<BattleSoldier> soldiers = getAvailableTargets(soldier, skill);
		boolean hasPet = false;
		for (BattleSoldier bs : soldiers) {
			if (!hasPet && !bs.isDead() && bs.charactorType() == GeneralCharactor.CharactorType.Pet.ordinal()) {
				hasPet = true;
				continue;
			}
			if (bs.isMainCharactor() || bs.charactorType() == GeneralCharactor.CharactorType.Crew.ordinal()) {
				if (!bs.isDead() || !bs.buffHolder().isAttackBanned()) {
					return false;
				}
			}

		}
		return hasPet;
	}

}
