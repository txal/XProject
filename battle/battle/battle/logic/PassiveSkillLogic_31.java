package com.nucleus.logic.core.modules.battle.logic;

import org.springframework.stereotype.Service;

import com.nucleus.commons.log.LogUtils;
import com.nucleus.logic.core.modules.battle.data.PassiveSkillConfig;
import com.nucleus.logic.core.modules.battle.data.PassiveSkillLaunchTimingEnum;
import com.nucleus.logic.core.modules.battle.dto.VideoBuffAddTargetState;
import com.nucleus.logic.core.modules.battle.model.BattlePlayerSoldierInfo;
import com.nucleus.logic.core.modules.battle.model.BattleSoldier;
import com.nucleus.logic.core.modules.battle.model.CommandContext;
import com.nucleus.logic.core.modules.battlebuff.data.BattleBuff;
import com.nucleus.logic.core.modules.battlebuff.model.BattleBuffEntity;

/**
 * 给宠物增加buff
 * 
 * @author wgy
 *
 */
@Service
public class PassiveSkillLogic_31 extends AbstractPassiveSkillLogic {
	@Override
	public boolean launchable(BattleSoldier soldier, BattleSoldier target, CommandContext context, PassiveSkillConfig config, PassiveSkillLaunchTimingEnum timing, IPassiveSkill passiveSkill) {
		boolean success = super.launchable(soldier, target, context, config, timing, passiveSkill);
		if (!success)
			return false;
		if (!soldier.ifMainCharactor())
			return false;
		BattlePlayerSoldierInfo soldierInfo = soldier.battleTeam().soldiersByPlayer(soldier.playerId());
		BattleSoldier pet = soldier.battleTeam().soldier(soldierInfo.petSoldierId());
		if (pet == null)
			return false;
		if (pet.isGhost())
			return false;
		return true;
	}

	@Override
	protected void doApply(BattleSoldier soldier, BattleSoldier target, CommandContext context, PassiveSkillConfig config, PassiveSkillLaunchTimingEnum timing, IPassiveSkill passiveSkill) {
		BattlePlayerSoldierInfo soldierInfo = soldier.battleTeam().soldiersByPlayer(soldier.playerId());
		long petId = soldierInfo.petSoldierId();
		if (petId <= 0)
			return;
		BattleSoldier pet = soldier.battleTeam().soldier(petId);
		if (pet == null)
			return;
		if (config.getTargetBuff() > 0) {
			BattleBuff buff = BattleBuff.get(config.getTargetBuff());
			if (buff != null) {
				int persistRound = curRounds(soldier, config);
				if (persistRound > 0) {
					BattleBuffEntity buffEntity = new BattleBuffEntity(buff, soldier, pet, passiveSkill.getId(), persistRound);
					if (pet.buffHolder().addBuff(buffEntity)) {
						if (context != null) {
							context.skillAction().addTargetState(new VideoBuffAddTargetState(buffEntity));
						} else if (timing == PassiveSkillLaunchTimingEnum.RoundStart) {
							soldier.currentVideoRound().readyAction().addTargetState(new VideoBuffAddTargetState(buffEntity));
						} else if (soldier.getCommandContext() != null) {
							soldier.getCommandContext().skillAction().addTargetState(new VideoBuffAddTargetState(buffEntity));
						}
					}
				}
			}
		}
	}

	protected int curRounds(BattleSoldier soldier, PassiveSkillConfig config) {
		int persistRound = 0;
		try {
			persistRound = Integer.parseInt(config.getExtraParams()[0]);
		} catch (Exception e) {
			LogUtils.errorLog(e);
		}
		int current = soldier.battle().getCount();
		persistRound -= current;// 剩余回合
		if (persistRound == 0)
			persistRound = 1;// 符合触发条件的最后一回合，也要加上buff，该buff持续1回合
		// int persistRound = ScriptService.getInstance().calcuInt("", buff.getBuffsPersistRoundFormula(), new HashMap<String, Object>(), false);
		return persistRound;
	}
}
