package com.nucleus.logic.core.modules.battle.logic;

import java.util.HashMap;
import java.util.Map;

import org.apache.commons.lang3.StringUtils;
import org.springframework.stereotype.Service;

import com.nucleus.logic.core.modules.battle.data.PassiveSkillConfig;
import com.nucleus.logic.core.modules.battle.data.PassiveSkillLaunchTimingEnum;
import com.nucleus.logic.core.modules.battle.model.BattleSoldier;
import com.nucleus.logic.core.modules.battle.model.CommandContext;
import com.nucleus.player.service.ScriptService;

/**
 * 死后设置固定怒气
 * 
 * @author zhanhua.xu
 *
 */
@Service
public class PassiveSkillLogic_62 extends AbstractPassiveSkillLogic {
	@Override
	protected void doApply(BattleSoldier soldier, BattleSoldier target, CommandContext context, PassiveSkillConfig config, PassiveSkillLaunchTimingEnum timing, IPassiveSkill passiveSkill) {
		if (!soldier.isDead())
			return;
		int deadSp = soldier.deadSp();
		if (deadSp <= 0)
			return;
		String formula = config.getPropertyEffectFormulas()[0];
		int skillLevel = soldier.skillLevel(passiveSkill.getId());
		int sp = calcFormula(soldier, formula, skillLevel);
		if (sp <= 0)
			return;
		if (sp > deadSp)
			sp = deadSp;

		soldier.setSp(sp);
	}

	private int calcFormula(BattleSoldier soldier, String formula, int skillLevel) {
		if (StringUtils.isBlank(formula))
			return 0;
		Map<String, Object> params = new HashMap<String, Object>();
		params.put("self", soldier);
		params.put("skillLevel", skillLevel);
		int v = ScriptService.getInstance().calcuInt("", formula, params, false);
		return v;
	}
}
