package com.nucleus.logic.core.modules.battle.logic;

import java.util.List;
import java.util.Map;

import org.apache.commons.collections.CollectionUtils;
import org.springframework.stereotype.Service;

import com.nucleus.logic.core.modules.battle.dto.VideoBuffAddTargetState;
import com.nucleus.logic.core.modules.battle.model.BattleSoldier;
import com.nucleus.logic.core.modules.battle.model.CommandContext;
import com.nucleus.logic.core.modules.battlebuff.data.BattleBuff.BattleBuffType;
import com.nucleus.logic.core.modules.battlebuff.model.BattleBuffEntity;

/**
 * 封印类和伤害类buff延长1回合
 * 
 * @author hwy
 * 
 */
@Service
public class SkillLogic_15 extends SkillLogic_1 {

	@Override
	protected void afterTargetSelected(CommandContext commandContext, List<SkillTargetPolicy> targetPolicys, BattleSoldier targetSelected) {
		BattleSoldier target = targetSelected;
		if (target.isDead() || target.isLeave()) {
			if (!CollectionUtils.isEmpty(targetPolicys))
				target = targetPolicys.get(0).getTarget();
			else
				return;
		}

		Map<Integer, BattleBuffEntity> allBuffs = target.buffHolder().allBuffs();
		for (BattleBuffEntity buff : allBuffs.values()) {
			if (buff.battleBuff().getBuffType() == BattleBuffType.AbnormalStatus.ordinal()) {
				buff.setBuffPersistRound(buff.getBuffPersistRound() + 1);
				target.currentVideoRound().endAction().addTargetState(new VideoBuffAddTargetState(buff));
			}
		}
	}
}
