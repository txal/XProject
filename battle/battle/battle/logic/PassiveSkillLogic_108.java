package com.nucleus.logic.core.modules.battle.logic;

import java.util.Set;

import org.springframework.stereotype.Service;

import com.nucleus.commons.utils.SplitUtils;
import com.nucleus.logic.core.modules.battle.data.PassiveSkillConfig;
import com.nucleus.logic.core.modules.battle.data.PassiveSkillLaunchTimingEnum;
import com.nucleus.logic.core.modules.battle.dto.VideoTargetShoutState;
import com.nucleus.logic.core.modules.battle.model.BattleSoldier;
import com.nucleus.logic.core.modules.battle.model.CommandContext;
import com.nucleus.logic.core.modules.charactor.data.ShoutConfig;

/**
 * 喊话
 *
 * @author wangyu
 */
@Service
public class PassiveSkillLogic_108 extends AbstractPassiveSkillLogic {
	@Override
	protected void doApply(BattleSoldier soldier, BattleSoldier target, CommandContext context, PassiveSkillConfig config, PassiveSkillLaunchTimingEnum timing, IPassiveSkill passiveSkill) {
		String[] params = config.getExtraParams();
		if (params == null || params.length == 0)
			return;
		Set<Integer> shoutIds = SplitUtils.split2IntSet(params[0], ",");
		if (!shoutIds.isEmpty()) {
			ShoutConfig shoutConfig = ShoutConfig.get(shoutIds.iterator().next());
			if (shoutConfig.ifShout()) {
				VideoTargetShoutState shoutState = new VideoTargetShoutState(soldier, shoutConfig.getBattleShoutTypeId(), shoutConfig.getShoutContent());
				soldier.currentVideoRound().addShoutState(shoutState);
			}
		}

	}
}
