package com.nucleus.logic.core.modules.battle.logic;

import org.springframework.stereotype.Service;

import com.nucleus.logic.core.modules.battle.data.PassiveSkillConfig;
import com.nucleus.logic.core.modules.battle.data.PassiveSkillLaunchTimingEnum;
import com.nucleus.logic.core.modules.battle.dto.VideoBuffAddTargetState;
import com.nucleus.logic.core.modules.battle.model.BattleSoldier;
import com.nucleus.logic.core.modules.battle.model.CommandContext;
import com.nucleus.logic.core.modules.battlebuff.data.BattleBuff;
import com.nucleus.logic.core.modules.battlebuff.model.BattleBuffEntity;

/**
 * 自身死亡给指定目标加buff
 * 
 * @author wgy
 *
 */
@Service
public class PassiveSkillLogic_48 extends AbstractPassiveSkillLogic {
	@Override
	protected void doApply(BattleSoldier soldier, BattleSoldier target, CommandContext context, PassiveSkillConfig config, PassiveSkillLaunchTimingEnum timing, IPassiveSkill passiveSkill) {
		if (config.getExtraParams() == null || config.getExtraParams().length <= 0)
			return;
		int monsterId = Integer.parseInt(config.getExtraParams()[0]);
		int buffId = config.getTargetBuff();
		if (monsterId <= 0 || buffId <= 0)
			return;
		BattleBuff buff = BattleBuff.get(buffId);
		if (buff == null)
			return;
		int skillId = config.getRelativeSkillId() > 0 ? config.getRelativeSkillId() : passiveSkill.getId();
		for (BattleSoldier s : soldier.team().aliveSoldiers()) {
			if (s.monsterId() != monsterId)
				continue;
			BattleBuffEntity buffEntity = addBuff(soldier, s, skillId, buff);
			if (buffEntity != null) {
				if (timing == PassiveSkillLaunchTimingEnum.Dead)
					soldier.currentVideoRound().endAction().addTargetState(new VideoBuffAddTargetState(buffEntity));
			}
		}
	}
}
