package com.nucleus.logic.core.modules.battle.logic;

import org.springframework.stereotype.Service;

import com.nucleus.commons.utils.SpringUtils;
import com.nucleus.logic.core.modules.battle.dto.VideoActionTargetState;
import com.nucleus.logic.core.modules.battle.model.BattleSoldier;
import com.nucleus.logic.core.modules.battle.model.CommandContext;

/**
 * 技能逻辑辅助
 * 
 * @author wgy
 *
 */
@Service
public class SkillLogicAssist {

	public static SkillLogicAssist getInstance() {
		return SpringUtils.getBeanOfType(SkillLogicAssist.class);
	}

	/**
	 * 吸血
	 * 
	 * @param commandContext
	 *            技能指令上下文
	 * @param consumer
	 *            接受者
	 * @param hpFromTarget
	 *            来自目标实际扣血
	 * @return
	 */
	public int hpFromTarget2Trigger(CommandContext commandContext, BattleSoldier consumer, int hpFromTarget) {
		final float suckRate = commandContext.skill().getSuckHpRate();
		if (suckRate <= 0 || hpFromTarget == 0)
			return 0;
		hpFromTarget = Math.abs(hpFromTarget);
		hpFromTarget *= suckRate;
		consumer.increaseHp(commandContext, hpFromTarget);
		commandContext.skillAction().addTargetState(new VideoActionTargetState(consumer, hpFromTarget, 0, false));
		return hpFromTarget;
	}

	/**
	 * 吸魔
	 * 
	 * @param commandContext
	 *            技能指令上下文
	 * @param comsumer
	 *            接受者
	 * @param mpFromTarget
	 *            来自目标实际扣魔
	 * @return
	 */
	public int mpFromTarget2Trigger(CommandContext commandContext, BattleSoldier comsumer, int mpFromTarget) {
		final float suckRate = commandContext.skill().getSuckMpRate();
		if (suckRate <= 0 || mpFromTarget == 0)
			return 0;
		mpFromTarget = Math.abs(mpFromTarget);
		mpFromTarget *= suckRate;
		comsumer.increaseMp(commandContext, mpFromTarget);
		commandContext.skillAction().addTargetState(new VideoActionTargetState(comsumer, 0, mpFromTarget, false));
		return mpFromTarget;
	}
}
