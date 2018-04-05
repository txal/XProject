package com.nucleus.logic.core.modules.battle.logic;

import java.util.HashMap;
import java.util.Map;

import com.nucleus.commons.annotation.GenIgnored;
import com.nucleus.logic.core.modules.battle.model.BattleSoldier;
import com.nucleus.logic.core.modules.battle.model.CommandContext;
import com.nucleus.player.service.ScriptService;

/**
 * 对目标伤害大于某个值
 * 
 * @author wgy
 *
 */
@GenIgnored
public class PassiveSkillLaunchCondition_12 extends AbstractPassiveSkillLaunchCondition {
	private String damageLimitFormula;

	@Override
	public boolean launchable(BattleSoldier soldier, BattleSoldier target, CommandContext context, IPassiveSkill passiveSkill) {
		Map<String, Object> params = new HashMap<String, Object>();
		params.put("level", (target != null ? target.grade() : 0));
		int limit = ScriptService.getInstance().calcuInt("", damageLimitFormula, params, false);
		if (Math.abs(context.getDamageOutput()) >= limit)
			return true;
		return false;
	}

	public String getDamageLimitFormula() {
		return damageLimitFormula;
	}

	public void setDamageLimitFormula(String damageLimitFormula) {
		this.damageLimitFormula = damageLimitFormula;
	}

}
