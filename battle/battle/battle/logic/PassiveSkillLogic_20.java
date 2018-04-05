package com.nucleus.logic.core.modules.battle.logic;

import org.springframework.stereotype.Service;

import com.nucleus.logic.core.modules.battle.data.PassiveSkillConfig;
import com.nucleus.logic.core.modules.battle.data.PassiveSkillLaunchTimingEnum;
import com.nucleus.logic.core.modules.battle.dto.VideoActionTargetSkillState;
import com.nucleus.logic.core.modules.battle.dto.VideoActionTargetState;
import com.nucleus.logic.core.modules.battle.model.BattleSoldier;
import com.nucleus.logic.core.modules.battle.model.CommandContext;

/**
 * 复活
 * 
 * @author wgy
 *
 */
@Service
public class PassiveSkillLogic_20 extends AbstractPassiveSkillLogic {
	@Override
	protected void doApply(BattleSoldier soldier, BattleSoldier target, CommandContext context, PassiveSkillConfig config, PassiveSkillLaunchTimingEnum timing, IPassiveSkill passiveSkill) {
		if (config.getExtraParams() != null) {
			float hpRate = Float.parseFloat(config.getExtraParams()[0]);
			int hp = (int) (soldier.maxHp() * hpRate);
			int mp = (int) (soldier.maxMp() * hpRate);
			soldier.increaseHp(hp);
			soldier.increaseMp(mp);
			VideoActionTargetState state = new VideoActionTargetState(soldier, hp, mp, false);
			soldier.currentVideoRound().readyAction().addTargetState(state);
			VideoActionTargetSkillState skillState = new VideoActionTargetSkillState(soldier, passiveSkill.getId());
			soldier.currentVideoRound().readyAction().addTargetState(skillState);
		}
	}
}
