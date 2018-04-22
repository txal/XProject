package com.nucleus.logic.core.modules.battle.logic;

import java.util.HashMap;
import java.util.Map;

import org.apache.commons.lang3.StringUtils;
import org.springframework.stereotype.Service;

import com.nucleus.logic.core.modules.battle.data.PassiveSkillConfig;
import com.nucleus.logic.core.modules.battle.data.PassiveSkillLaunchTimingEnum;
import com.nucleus.logic.core.modules.battle.dto.VideoActionTargetSkillState;
import com.nucleus.logic.core.modules.battle.dto.VideoActionTargetState;
import com.nucleus.logic.core.modules.battle.model.BattleSoldier;
import com.nucleus.logic.core.modules.battle.model.CommandContext;
import com.nucleus.logic.core.modules.battle.model.RoundContext.RoundState;
import com.nucleus.player.service.ScriptService;

/**
 * 保命
 * 
 * @author wgy
 *
 */
@Service
public class PassiveSkillLogic_19 extends AbstractPassiveSkillLogic {
	@Override
	protected void doApply(BattleSoldier soldier, BattleSoldier target, CommandContext context, PassiveSkillConfig config, PassiveSkillLaunchTimingEnum timing, IPassiveSkill passiveSkill) {
		if (context != null && context.skill().isBanLife())
			return;
		if (soldier.isDead()) {
			String formula = config.getPropertyEffectFormulas()[0];
			int hp = calcFormula(soldier, formula);
			soldier.increaseHp(hp);
			soldier.setLeave(false);
			VideoActionTargetState state = new VideoActionTargetState(soldier, hp, 0, false);
			VideoActionTargetSkillState skillState = new VideoActionTargetSkillState(soldier, passiveSkill.getId());
			RoundState rs = soldier.roundContext().getState();
			if (rs == RoundState.RoundStart) {
				soldier.currentVideoRound().readyAction().addTargetState(state);
				soldier.currentVideoRound().readyAction().addTargetState(skillState);
			} else if (rs == RoundState.RoundAction) {
				context.skillAction().addTargetState(state);
				context.skillAction().addTargetState(skillState);
			} else if (rs == RoundState.RoundOver) {
				soldier.currentVideoRound().endAction().addTargetState(state);
				soldier.currentVideoRound().endAction().addTargetState(skillState);
			}
		}
	}

	private int calcFormula(BattleSoldier soldier, String formula) {
		if (StringUtils.isBlank(formula))
			return 0;
		Map<String, Object> params = new HashMap<String, Object>();
		params.put("self", soldier);
		int v = ScriptService.getInstance().calcuInt("", formula, params, false);
		return v;
	}
}
