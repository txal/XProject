package com.nucleus.logic.core.modules.battle.logic;

import org.springframework.stereotype.Service;

import com.nucleus.logic.core.modules.battle.data.PassiveSkillConfig;
import com.nucleus.logic.core.modules.battle.data.PassiveSkillLaunchTimingEnum;
import com.nucleus.logic.core.modules.battle.dto.VideoBuffAddTargetState;
import com.nucleus.logic.core.modules.battle.model.BattleSoldier;
import com.nucleus.logic.core.modules.battle.model.CommandContext;
import com.nucleus.logic.core.modules.battle.model.RoundContext.RoundState;
import com.nucleus.logic.core.modules.battlebuff.data.BattleBuff;
import com.nucleus.logic.core.modules.battlebuff.model.BattleBuffEntity;

/**
 * 给本队其他存活单位加buff(只加一次)
 * 
 * @author wgy
 *
 */
@Service
public class PassiveSkillLogic_54 extends AbstractPassiveSkillLogic {
	@Override
	protected void doApply(BattleSoldier soldier, BattleSoldier target, CommandContext context, PassiveSkillConfig config, PassiveSkillLaunchTimingEnum timing, IPassiveSkill passiveSkill) {
		if (config.getTargetBuff() > 0) {
			BattleBuff buff = BattleBuff.get(config.getTargetBuff());
			if (buff != null) {
				int persistRound = Integer.parseInt(buff.getBuffsPersistRoundFormula());
				if (persistRound > 0) {
					for (BattleSoldier member : soldier.battleTeam().aliveSoldiers()) {
						BattleBuffEntity buffEntity = new BattleBuffEntity(buff, soldier, member, passiveSkill.getId(), persistRound);
						if (member.buffHolder().addBuff(buffEntity)) {
							if (context != null) {
								context.skillAction().addTargetState(new VideoBuffAddTargetState(buffEntity));
							} else if (soldier.roundContext().getState() == RoundState.RoundStart) {
								soldier.currentVideoRound().readyAction().addTargetState(new VideoBuffAddTargetState(buffEntity));
							} else if (soldier.roundContext().getState() == RoundState.RoundOver) {
								soldier.currentVideoRound().endAction().addTargetState(new VideoBuffAddTargetState(buffEntity));
							}
						}
					}
				}
			}
		}
	}
}
