package com.nucleus.logic.core.modules.battle.logic;

import org.springframework.stereotype.Service;

import com.nucleus.commons.log.LogUtils;
import com.nucleus.logic.core.modules.battle.data.PassiveSkillConfig;
import com.nucleus.logic.core.modules.battle.data.PassiveSkillLaunchTimingEnum;
import com.nucleus.logic.core.modules.battle.dto.VideoBuffAddTargetState;
import com.nucleus.logic.core.modules.battle.dto.VideoBuffRemoveTargetState;
import com.nucleus.logic.core.modules.battle.model.BattleSoldier;
import com.nucleus.logic.core.modules.battle.model.CommandContext;
import com.nucleus.logic.core.modules.battlebuff.model.BattleBuffEntity;

/**
 * 夺取buff
 * 
 * @author wgy
 *
 */
@Service
public class PassiveSkillLogic_59 extends AbstractPassiveSkillLogic {
	@Override
	protected void doApply(BattleSoldier soldier, BattleSoldier target, CommandContext context, PassiveSkillConfig config, PassiveSkillLaunchTimingEnum timing, IPassiveSkill passiveSkill) {
		int buffType = 0;
		try {
			buffType = Integer.parseInt(config.getExtraParams()[0]);
		} catch (Exception e) {
			LogUtils.errorLog(e);
		}
		if (buffType < 1)
			return;
		BattleBuffEntity robBuff = null;
		for (BattleBuffEntity buff : target.buffHolder().allBuffs().values()) {
			if (buffType == buff.battleBuffType()) {
				robBuff = buff;
				break;
			}
		}
		if (robBuff != null) {
			final int removedBuffId = robBuff.battleBuffId();
			target.buffHolder().removeBuffById(removedBuffId);
			context.skillAction().addTargetState(new VideoBuffRemoveTargetState(target, removedBuffId));
			robBuff.setEffectSoldier(soldier);
			if (soldier.buffHolder().addBuff(robBuff)) {
				VideoBuffAddTargetState state = new VideoBuffAddTargetState(robBuff);
				context.skillAction().addTargetState(state);
			}
		}
	}
}
