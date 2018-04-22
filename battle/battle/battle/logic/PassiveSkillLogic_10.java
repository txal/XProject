package com.nucleus.logic.core.modules.battle.logic;

import java.util.ArrayList;
import java.util.HashMap;
import java.util.List;
import java.util.Map;

import org.apache.commons.lang3.StringUtils;
import org.springframework.stereotype.Service;

import com.nucleus.logic.core.modules.battle.data.PassiveSkillConfig;
import com.nucleus.logic.core.modules.battle.data.PassiveSkillLaunchTimingEnum;
import com.nucleus.logic.core.modules.battle.dto.VideoBuffAddTargetState;
import com.nucleus.logic.core.modules.battle.model.BattleSoldier;
import com.nucleus.logic.core.modules.battle.model.CommandContext;
import com.nucleus.logic.core.modules.battle.model.RoundContext.RoundState;
import com.nucleus.logic.core.modules.battlebuff.data.BattleBuff;
import com.nucleus.logic.core.modules.battlebuff.model.BattleBuffEntity;
import com.nucleus.player.service.ScriptService;

/**
 * 附加buff
 * 
 * @author wgy
 *
 */
@Service
public class PassiveSkillLogic_10 extends AbstractPassiveSkillLogic {
	@Override
	protected void doApply(BattleSoldier soldier, BattleSoldier target, CommandContext context, PassiveSkillConfig config, PassiveSkillLaunchTimingEnum timing, IPassiveSkill passiveSkill) {
		BattleBuff buff = BattleBuff.get(config.getSelfBuff());
		int skillId = config.getRelativeSkillId() > 0 ? config.getRelativeSkillId() : passiveSkill.getId();
		if (buff != null) {
			BattleBuffEntity buffEntity = addBuff(soldier, soldier, skillId, buff);
			if (buffEntity != null) {
				VideoBuffAddTargetState state = new VideoBuffAddTargetState(buffEntity);
				if (timing == PassiveSkillLaunchTimingEnum.RoundStart) {
					soldier.currentVideoRound().readyAction().addTargetState(state);
				} else if (timing == PassiveSkillLaunchTimingEnum.DamageInput || timing == PassiveSkillLaunchTimingEnum.UnderAttack) {
					if (target != null && target.getCommandContext() != null)
						target.getCommandContext().skillAction().addTargetState(state);
				} else if (timing == PassiveSkillLaunchTimingEnum.BeAfterCrit) {
					if (target != null && target.getCommandContext() != null)
						target.getCommandContext().skillAction().addTargetState(state);
				} else if (timing == PassiveSkillLaunchTimingEnum.Dead) {
					RoundState rs = soldier.roundContext().getState();
					state.setLeave(!buffEntity.battleBuff().isForDead());
					if (rs == RoundState.RoundStart)
						soldier.currentVideoRound().readyAction().addTargetState(state);
					else if (rs == RoundState.RoundOver)
						soldier.currentVideoRound().endAction().addTargetState(state);
					else if (rs == RoundState.RoundAction && target != null && target.getCommandContext() != null) {
						target.getCommandContext().skillAction().addTargetState(state);
					}
				} else if (timing == PassiveSkillLaunchTimingEnum.BeRelived && context != null) {
					context.skillAction().addTargetState(state);
				} else if (timing == PassiveSkillLaunchTimingEnum.BeforeCallPet && context != null) {
					soldier.currentVideoRound().readyAction().addTargetState(state);
				} else if (soldier.getCommandContext() != null) {
					soldier.getCommandContext().skillAction().addTargetState(state);
				}
			}
		}
		buff = BattleBuff.get(config.getTargetBuff());
		if (buff != null) {
			BattleBuffEntity buffEntity = addBuff(soldier, target, skillId, buff);
			if (buffEntity != null) {
				VideoBuffAddTargetState state = new VideoBuffAddTargetState(buffEntity);
				if (timing != PassiveSkillLaunchTimingEnum.BattleReady) {
					if (timing == PassiveSkillLaunchTimingEnum.RoundStart)
						soldier.currentVideoRound().readyAction().addTargetState(state);
					else if (timing == PassiveSkillLaunchTimingEnum.DamageInput) {
						if (target != null && target.getCommandContext() != null) {
							target.getCommandContext().skillAction().addTargetState(state);
						}
					} else if (soldier.getCommandContext() != null)
						soldier.getCommandContext().skillAction().addTargetState(state);
				}
				if (context != null && context.battle() != null) {
					List<BattleBuffEntity> addBuffs = new ArrayList<>(1);
					addBuffs.add(buffEntity);
					context.battle().onBuffAdd(context, soldier, target, addBuffs);
				}
			}
		}
		if (StringUtils.isNotBlank(config.getSpendMpFormula())) {
			Map<String, Object> params = new HashMap<String, Object>();
			params.put("level", soldier.grade());
			int mp = ScriptService.getInstance().calcuInt("", config.getSpendMpFormula(), params, false);
			soldier.decreaseMp(mp);
		}
	}
}
