package com.nucleus.logic.core.modules.battle.logic;

import java.util.Set;

import org.springframework.stereotype.Service;

import com.nucleus.commons.utils.SplitUtils;
import com.nucleus.logic.core.modules.battle.data.PassiveSkillConfig;
import com.nucleus.logic.core.modules.battle.data.PassiveSkillLaunchTimingEnum;
import com.nucleus.logic.core.modules.battle.model.BattleSoldier;
import com.nucleus.logic.core.modules.battle.model.CommandContext;
import com.nucleus.logic.core.modules.battlebuff.data.BattleBuff;
import com.nucleus.logic.core.modules.battlebuff.data.BattleBuff.BuffClassTypeEnum;

/**
 * buff免疫:抗封印
 * 
 * @author wgy
 *
 */
@Service
public class PassiveSkillLogic_16 extends AbstractPassiveSkillLogic {
	@Override
	protected void doApply(BattleSoldier soldier, BattleSoldier target, CommandContext context, PassiveSkillConfig config, PassiveSkillLaunchTimingEnum timing, IPassiveSkill passiveSkill) {
		if (context.getBeAddBuffId() <= 0)
			return;
		Set<Integer> buffIds = SplitUtils.split2IntSet(config.getExtraParams()[0], ",");
		if (buffIds.contains(context.getBeAddBuffId()))
			context.setBeAddBuffId(0);
		else {
			BattleBuff buff = BattleBuff.get(context.getBeAddBuffId());
			if (buff.getBuffClassType() == BuffClassTypeEnum.Ban.ordinal())
				context.setBeAddBuffId(0);
		}
	}
}
