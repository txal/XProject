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
 * 给全队成员增加buff
 * 
 * @author wgy
 *
 */
@Service
public class PassiveSkillLogic_39 extends AbstractPassiveSkillLogic {
	@Override
	protected void doApply(BattleSoldier soldier, BattleSoldier target, CommandContext context, PassiveSkillConfig config, PassiveSkillLaunchTimingEnum timing, IPassiveSkill passiveSkill) {
		if (config.getTargetBuff() > 0) {
			BattleBuff buff = BattleBuff.get(config.getTargetBuff());
			if (buff != null) {
				int persistRound = Integer.parseInt(buff.getBuffsPersistRoundFormula());
				if (persistRound > 0) {
					soldier.battleTeam().getTeamBuffIds().add(buff.getId());
					for (BattleSoldier member : soldier.battleTeam().soldiersMap().values()) {
						BattleBuffEntity buffEntity = new BattleBuffEntity(buff, soldier, member, passiveSkill.getId(), persistRound);
						member.buffHolder().addBuff(buffEntity);
						if (timing != PassiveSkillLaunchTimingEnum.BattleReady) {
							// 战斗中附加
							if (timing == PassiveSkillLaunchTimingEnum.RoundStart) {
								soldier.currentVideoRound().readyAction().addTargetState(new VideoBuffAddTargetState(buffEntity));
							} else if (soldier.getCommandContext() != null) {
								soldier.getCommandContext().skillAction().addTargetState(new VideoBuffAddTargetState(buffEntity));
							}
						}
					}
				}
			}
		}
	}
}
