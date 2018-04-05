/**
 * 
 */
package com.nucleus.logic.core.modules.battlebuff;

import org.springframework.stereotype.Service;

import com.nucleus.logic.core.modules.battle.data.Skill;
import com.nucleus.logic.core.modules.battle.dto.VideoActionTargetState;
import com.nucleus.logic.core.modules.battle.model.BattleSoldier;
import com.nucleus.logic.core.modules.battlebuff.model.BattleBuffEntity;

/**
 * 防御
 * 
 * @author hwy
 *
 */
@Service
public class BattleBuffLogic_22 extends BattleBuffLogicAdapter {

	@Override
	public void onRoundStart(BattleBuffEntity buffEntity) {
		BattleSoldier target = buffEntity.getEffectSoldier();
		if (target == null)
			return;
		int curRound = target.battle().getCount();
		int skillId = Skill.defenseSkillId();
		target.initForceSkill(skillId, curRound);
		target.currentVideoRound().readyAction().addTargetState(new VideoActionTargetState(target, 0, 0, false));
	}
}
