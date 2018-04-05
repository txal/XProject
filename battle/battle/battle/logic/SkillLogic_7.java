package com.nucleus.logic.core.modules.battle.logic;

import java.util.ArrayList;
import java.util.Iterator;
import java.util.List;

import org.springframework.stereotype.Service;

import com.nucleus.logic.core.modules.battle.data.Skill;
import com.nucleus.logic.core.modules.battle.dto.VideoBuffRemoveTargetState;
import com.nucleus.logic.core.modules.battle.model.BattleSoldier;
import com.nucleus.logic.core.modules.battle.model.CommandContext;
import com.nucleus.logic.core.modules.battlebuff.model.BattleBuffEntity;

/**
 * 移除buff
 * 
 * @author wgy
 * 
 */
@Service
public class SkillLogic_7 extends SkillLogicAdapter {

	@Override
	public void doFired(CommandContext commandContext) {
		final boolean debugEnable = commandContext.debugEnable();
		BattleSoldier trigger = commandContext.trigger();
		Skill skill = commandContext.skill();
		SkillAiLogic skillAiLogic = skill.skillAi().skillAiLogic();
		List<SkillTargetPolicy> targetPolicys = skillAiLogic.selectTargets(commandContext);
		if (targetPolicys.isEmpty())
			return;
		int validAttackCount = 0;
		for (SkillTargetPolicy tp : targetPolicys) {
			if (debugEnable)
				commandContext.initDebugInfo(trigger, skill, tp.getTarget());
			BattleSoldier target = tp.getTarget();
			if (target == null)
				continue;
			removeBuff(commandContext, target);
			validAttackCount++;
		}

		int totalAttackCount = skill.isAtOnce() ? 1 : validAttackCount;
		commandContext.updateTotalAttackCount(totalAttackCount);
	}

	private void removeBuff(CommandContext commandContext, BattleSoldier target) {
		if (!commandContext.skill().targetRemoveBuffs().isEmpty()) {
			removeTargetBuffs(commandContext, target);
		}
		List<Integer> buffIdList = new ArrayList<Integer>();
		if (!commandContext.skill().targetBattleBuffIds().isEmpty()) {
			for (Iterator<Integer> it = commandContext.skill().targetBattleBuffIds().iterator(); it.hasNext();) {
				Integer id = it.next();
				int buffId = id == null ? 0 : id.intValue();
				if (buffId <= 0)
					continue;
				final BattleBuffEntity buff = target.buffHolder().removeBuffById(buffId);
				if (buff == null)
					continue;
				buffIdList.add(buffId);
			}
		}
		commandContext.skillAction().addTargetState(new VideoBuffRemoveTargetState(target, buffIdList.toArray(new Integer[] {})));
	}

}
