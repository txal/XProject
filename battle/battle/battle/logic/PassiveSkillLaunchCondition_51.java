package com.nucleus.logic.core.modules.battle.logic;

import java.util.HashMap;
import java.util.Map;

import com.nucleus.commons.annotation.GenIgnored;
import com.nucleus.commons.utils.RandomUtils;
import com.nucleus.logic.core.modules.battle.model.BattleSoldier;
import com.nucleus.logic.core.modules.battle.model.CommandContext;
import com.nucleus.player.service.ScriptService;

/**
 * 暴走几率
 * 
 * @author hwy
 *
 */
@GenIgnored
public class PassiveSkillLaunchCondition_51 extends AbstractPassiveSkillLaunchCondition {
	private String rateFormula;

	@Override
	public boolean launchable(BattleSoldier soldier, BattleSoldier target, CommandContext context, IPassiveSkill passiveSkill) {
		if (!context.skill().ifPhyAttack())
			return false;
		Map<String, Object> params = new HashMap<String, Object>();
		params.put("useSkillMassRule", context.skill().isUseSkillMassRule());
		float rate = ScriptService.getInstance().calcuFloat("", rateFormula, params, false);
		boolean launchable = RandomUtils.baseRandomHit(rate);
		return launchable;
	}

	public String getRateFormula() {
		return rateFormula;
	}

	public void setRateFormula(String rateFormula) {
		this.rateFormula = rateFormula;
	}

}
