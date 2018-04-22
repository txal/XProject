package com.nucleus.logic.core.modules.battle.logic;

import java.util.Set;

import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;

import com.nucleus.commons.utils.RandomUtils;
import com.nucleus.commons.utils.SplitUtils;
import com.nucleus.logic.core.modules.battle.data.PassiveSkillConfig;
import com.nucleus.logic.core.modules.battle.data.PassiveSkillLaunchTimingEnum;
import com.nucleus.logic.core.modules.battle.dto.VideoAction;
import com.nucleus.logic.core.modules.battle.model.BattleSoldier;
import com.nucleus.logic.core.modules.battle.model.CommandContext;

/**
 * 随机召唤
 * 
 * @author wgy
 *
 */
@Service
public class PassiveSkillLogic_46 extends AbstractPassiveSkillLogic {
	@Autowired
	private CallMonsterService callMonsterHandler;

	@Override
	protected void doApply(BattleSoldier soldier, BattleSoldier target, CommandContext context, PassiveSkillConfig config, PassiveSkillLaunchTimingEnum timing, IPassiveSkill passiveSkill) {
		if (config.getExtraParams() == null || config.getExtraParams().length <= 0)
			return;
		Set<Integer> monsterIds = SplitUtils.split2IntSet(config.getExtraParams()[0], ",");
		if (monsterIds.isEmpty())
			return;
		int count = 1;
		if (config.getExtraParams().length > 1)
			count = Integer.parseInt(config.getExtraParams()[1]);
		VideoAction actionHolder = null;
		if (context != null)
			actionHolder = context.skillAction();
		else if (timing == PassiveSkillLaunchTimingEnum.RoundOver)
			actionHolder = soldier.currentVideoRound().endAction();
		if (actionHolder == null)
			return;
		for (int i = 0; i < count; i++) {
			int monsterId = RandomUtils.next(monsterIds);
			if (monsterId <= 0)
				continue;
			callMonsterHandler.doCall(soldier, monsterId, actionHolder, null, true, passiveSkill.getId());
		}
	}
}
