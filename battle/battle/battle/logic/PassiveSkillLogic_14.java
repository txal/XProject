package com.nucleus.logic.core.modules.battle.logic;

import java.util.HashSet;
import java.util.Set;

import org.springframework.stereotype.Service;

import com.nucleus.commons.utils.SplitUtils;
import com.nucleus.logic.core.modules.battle.data.PassiveSkillConfig;
import com.nucleus.logic.core.modules.battle.data.PassiveSkillLaunchTimingEnum;
import com.nucleus.logic.core.modules.battle.dto.VideoBuffRemoveTargetState;
import com.nucleus.logic.core.modules.battle.model.BattleSoldier;
import com.nucleus.logic.core.modules.battle.model.CommandContext;
import com.nucleus.logic.core.modules.battlebuff.data.BattleBuff.BattleBuffType;
import com.nucleus.logic.core.modules.battlebuff.model.BattleBuffEntity;

/**
 * 回合结束有机会清除异常状态(移除buff)
 * 
 * @author wgy
 *
 */
@Service
public class PassiveSkillLogic_14 extends AbstractPassiveSkillLogic {

	@Override
	protected void doApply(BattleSoldier soldier, BattleSoldier target, CommandContext context, PassiveSkillConfig config, PassiveSkillLaunchTimingEnum timing, IPassiveSkill passiveSkill) {
		Set<Integer> buffsTypes = SplitUtils.split2IntSet(config.getExtraParams()[0], ",");
		Set<Integer> buffIds = null;
		if (config.getExtraParams().length > 1)
			buffIds = SplitUtils.split2IntSet(config.getExtraParams()[1], ",");
		Set<Integer> removed = new HashSet<Integer>();
		if (buffIds != null)
			removed.addAll(buffIds);
		clearBuff(soldier, target, removed, buffsTypes);
	}

	protected void clearBuff(BattleSoldier soldier, BattleSoldier target, Set<Integer> removed, Set<Integer> buffsTypes) {
		for (int buffType : buffsTypes) {
			if (buffType == BattleBuffType.Unknown.ordinal())
				continue;
			for (BattleBuffEntity buff : soldier.buffHolder().allBuffs().values()) {
				if (buff.battleBuffType() == buffType)
					removed.add(buff.battleBuffId());
			}
		}
		if (!removed.isEmpty()) {
			for (int buffId : removed)
				soldier.buffHolder().removeBuffById(buffId);
			soldier.currentVideoRound().endAction().addTargetState(new VideoBuffRemoveTargetState(soldier, removed.toArray(new Integer[] {})));
		}
	}

}
