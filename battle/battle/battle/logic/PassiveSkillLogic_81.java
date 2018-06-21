package com.nucleus.logic.core.modules.battle.logic;

import java.util.Set;

import org.springframework.stereotype.Service;

import com.nucleus.logic.core.modules.battle.dto.VideoBuffRemoveTargetState;
import com.nucleus.logic.core.modules.battle.model.BattleSoldier;
import com.nucleus.logic.core.modules.battlebuff.data.BattleBuff.BattleBuffType;
import com.nucleus.logic.core.modules.battlebuff.model.BattleBuffEntity;

/**
 * 技能清除目标buff
 * 
 * @author yifan.chen
 *
 */
@Service
public class PassiveSkillLogic_81 extends PassiveSkillLogic_14 {

	@Override
	protected void clearBuff(BattleSoldier soldier, BattleSoldier target, Set<Integer> removed, Set<Integer> buffsTypes) {
		for (int buffType : buffsTypes) {
			if (buffType == BattleBuffType.Unknown.ordinal())
				continue;
			for (BattleBuffEntity buff : target.buffHolder().allBuffs().values()) {
				if (buff.battleBuffType() == buffType)
					removed.add(buff.battleBuffId());
			}
		}
		if (!removed.isEmpty()) {
			for (int buffId : removed)
				target.buffHolder().removeBuffById(buffId);
			soldier.getCommandContext().skillAction().addTargetState(new VideoBuffRemoveTargetState(target, removed.toArray(new Integer[] {})));
		}
	}

}
