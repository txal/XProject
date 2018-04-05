package com.nucleus.logic.core.modules.battle.logic;

import org.springframework.stereotype.Service;

import com.nucleus.logic.core.modules.battle.data.PassiveSkillConfig;
import com.nucleus.logic.core.modules.battle.data.PassiveSkillLaunchTimingEnum;
import com.nucleus.logic.core.modules.battle.dto.VideoBuffRemoveTargetState;
import com.nucleus.logic.core.modules.battle.model.BattleSoldier;
import com.nucleus.logic.core.modules.battle.model.BattleSoldierBuffHolder;
import com.nucleus.logic.core.modules.battle.model.CommandContext;
import com.nucleus.logic.core.modules.battlebuff.data.BattleBuff;

/**
 * 敌方存在自己施放的某些buff时，再追加另外的buff
 *
 * @author hwy
 */
@Service
public class PassiveSkillLogic_97 extends AbstractPassiveSkillLogic {
	@Override
	protected void doApply(BattleSoldier soldier, BattleSoldier target, CommandContext context, PassiveSkillConfig config, PassiveSkillLaunchTimingEnum timing, IPassiveSkill passiveSkill) {
		if (config == null || config.getExtraParams().length < 2)
			return;
		String[] extraParams = config.getExtraParams();
		int buffId = Integer.parseInt(extraParams[0]);
		int addBuffId = Integer.parseInt(extraParams[1]);
		BattleBuff buff = BattleBuff.get(addBuffId);
		if (buff == null)
			return;
		for (BattleSoldier enemySoldier : soldier.battleTeam().getEnemyTeam().aliveSoldiers()) {
			BattleSoldierBuffHolder buffHolder = enemySoldier.buffHolder();
			if (buffHolder.hasBuff(buffId) && buffHolder.getBuff(buffId).getTriggerSoldier().getId() == soldier.getId()) {
				// 把之前的buff 移除
				buffHolder.removeBuffById(buffId);
				if (enemySoldier.currentVideoRound() != null) {
					enemySoldier.currentVideoRound().endAction().addTargetState(new VideoBuffRemoveTargetState(soldier, buffId));
				}
				addBuff(soldier, enemySoldier, passiveSkill.getId(), buff);
			}
		}
	}
}
