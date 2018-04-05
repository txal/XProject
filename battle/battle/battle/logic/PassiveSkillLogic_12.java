package com.nucleus.logic.core.modules.battle.logic;

import java.util.HashMap;
import java.util.Map;

import org.apache.commons.lang3.StringUtils;
import org.springframework.stereotype.Service;

import com.nucleus.commons.utils.RandomUtils;
import com.nucleus.logic.core.modules.battle.data.PassiveSkillConfig;
import com.nucleus.logic.core.modules.battle.data.PassiveSkillLaunchTimingEnum;
import com.nucleus.logic.core.modules.battle.dto.VideoActionTargetState;
import com.nucleus.logic.core.modules.battle.model.BattleSoldier;
import com.nucleus.logic.core.modules.battle.model.CommandContext;
import com.nucleus.logic.core.modules.battle.model.RoundContext.RoundState;
import com.nucleus.logic.core.modules.battlebuff.data.BattleBuff.BattleBasePropertyType;
import com.nucleus.player.service.ScriptService;

/**
 * 恢复mp/hp/sp
 * 
 * @author wgy
 *
 */
@Service
public class PassiveSkillLogic_12 extends AbstractPassiveSkillLogic {

	@Override
	protected void doApply(BattleSoldier soldier, BattleSoldier target, CommandContext context, PassiveSkillConfig config, PassiveSkillLaunchTimingEnum timing, IPassiveSkill passiveSkill) {
		if (soldier.isDead())
			return;
		int skillLevel = soldier.skillLevel(passiveSkill.getId());
		Map<String, Object> metaData = context.getMateData();
		String[] formulas = (String[]) metaData.get("metaFormulas");
		for (int i = 0; i < config.getPropertyEffectFormulas().length; i++) {
			String formula = null;
			if (formulas != null && !StringUtils.isEmpty(formulas[i])) {
				formula = formulas[i];
			} else {
				formula = config.getPropertyEffectFormulas()[i];
			}
			int value = (int) calcLevelValue(soldier, formula, context, skillLevel);
			int property = config.getPropertys()[i];
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
	}

	private float calcLevelValue(BattleSoldier soldier, String formula, CommandContext context, int skillLevel) {
		Map<String, Object> params = new HashMap<String, Object>();
		params.put("level", soldier.grade());
		params.put("self", soldier);
		params.put("skillLevel", skillLevel);
		params.put("RandomUtils", RandomUtils.getInstance());
		params.put("trigger", soldier);
		if (context != null) {
			params.put("totalHpVary", context.getTotalHpVaryAmount());
			params.put("damage", context.getDamageOutput());
		}
		return ScriptService.getInstance().calcuFloat("", formula, params, false);
	}

}
