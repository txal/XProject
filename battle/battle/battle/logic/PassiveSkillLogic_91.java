package com.nucleus.logic.core.modules.battle.logic;

import java.util.HashMap;
import java.util.Map;
import java.util.Set;

import org.springframework.stereotype.Service;

import com.nucleus.commons.utils.SplitUtils;
import com.nucleus.logic.core.modules.battle.data.PassiveSkillConfig;
import com.nucleus.logic.core.modules.battle.data.PassiveSkillLaunchTimingEnum;
import com.nucleus.logic.core.modules.battle.dto.VideoActionTargetState;
import com.nucleus.logic.core.modules.battle.model.BattleSoldier;
import com.nucleus.logic.core.modules.battle.model.CommandContext;
import com.nucleus.logic.core.modules.battle.model.RoundContext.RoundState;
import com.nucleus.logic.core.modules.battlebuff.data.BattleBuff.BattleBasePropertyType;
import com.nucleus.player.service.ScriptService;

/**
 * 根据敌方队伍存在的buff数恢复自身HP
 * 
 * @author hwy
 *
 */
@Service
public class PassiveSkillLogic_91 extends AbstractPassiveSkillLogic {
	@Override
	protected void doApply(BattleSoldier soldier, BattleSoldier target, CommandContext context, PassiveSkillConfig config, PassiveSkillLaunchTimingEnum timing, IPassiveSkill passiveSkill) {
		if (soldier.isDead() || config.getExtraParams().length <= 0)
			return;
		Set<Integer> buffIds = SplitUtils.split2IntSet(config.getExtraParams()[0], "\\|");
		int buffCount = 0;
		for (BattleSoldier enemySoldier : soldier.team().getEnemyTeam().aliveSoldiers()) {
			for (int id : buffIds) {
				if (enemySoldier.buffHolder().hasBuff(id)) {
					buffCount++;
					break;
				}
			}
		}
		int skillLevel = soldier.skillLevel(passiveSkill.getId());
		if (buffCount == 0)
			return;
		int value = (int) calcLevelValue(config.getPropertyEffectFormulas()[0], buffCount, skillLevel);
		if (value <= 0)
			return;
		int property = config.getPropertys()[0];
		VideoActionTargetState state = null;
		if (property == BattleBasePropertyType.Hp.ordinal()) {
			soldier.increaseHp(value);
			state = new VideoActionTargetState(soldier, value, 0, false);
		} else if (property == BattleBasePropertyType.Mp.ordinal()) {
			soldier.increaseMp(value);
			state = new VideoActionTargetState(soldier, 0, value, false);
		} else if (property == BattleBasePropertyType.Sp.ordinal()) {
			soldier.increaseSp(value);
			state = new VideoActionTargetState(soldier, 0, 0, false, value);
		}

		if (timing == PassiveSkillLaunchTimingEnum.TeammateAttackEnd || timing == PassiveSkillLaunchTimingEnum.TargetKilled)
			context.skillAction().addTargetState(state);
		else if (soldier.roundContext().getState() == RoundState.RoundStart)
			soldier.currentVideoRound().readyAction().addTargetState(state);
		else if (soldier.roundContext().getState() == RoundState.RoundOver)
			soldier.currentVideoRound().endAction().addTargetState(state);
		else if (soldier.roundContext().getState() == RoundState.RoundAction)
			context.skillAction().addTargetState(state);
	}

	private float calcLevelValue(String formula, int buffCount, int skillLevel) {
		Map<String, Object> params = new HashMap<String, Object>();
		params.put("buffCount", buffCount);
		params.put("skillLevel", skillLevel);
		return ScriptService.getInstance().calcuFloat("PassiveSkillLogic_91.calcLevelValue", formula, params, false);
	}
}
