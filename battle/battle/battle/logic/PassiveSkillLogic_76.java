package com.nucleus.logic.core.modules.battle.logic;

import java.util.Set;

import org.springframework.stereotype.Service;

import com.nucleus.commons.utils.SplitUtils;
import com.nucleus.logic.core.modules.battle.data.PassiveSkillConfig;
import com.nucleus.logic.core.modules.battle.data.PassiveSkillLaunchTimingEnum;
import com.nucleus.logic.core.modules.battle.model.BattleSoldier;
import com.nucleus.logic.core.modules.battle.model.CommandContext;

/**
 * 16那个有抗封印，所以加这个
 * 
 * @author yifan.chen
 *
 */
@Service
public class PassiveSkillLogic_76 extends AbstractPassiveSkillLogic {
	@Override
	protected void doApply(BattleSoldier soldier, BattleSoldier target, CommandContext context, PassiveSkillConfig config, PassiveSkillLaunchTimingEnum timing, IPassiveSkill passiveSkill) {
		if (context.getBeAddBuffId() <= 0)
			return;
		Set<Integer> buffIds = SplitUtils.split2IntSet(config.getExtraParams()[0], ",");
		if (buffIds.contains(context.getBeAddBuffId()))
			context.setBeAddBuffId(0);
	}
}
