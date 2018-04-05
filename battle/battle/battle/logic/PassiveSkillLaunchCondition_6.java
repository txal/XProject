package com.nucleus.logic.core.modules.battle.logic;

import java.util.HashMap;
import java.util.Map;

import com.nucleus.commons.annotation.GenIgnored;
import com.nucleus.commons.utils.RandomUtils;
import com.nucleus.logic.core.modules.battle.model.BattleSoldier;
import com.nucleus.logic.core.modules.battle.model.CommandContext;
import com.nucleus.logic.whole.modules.system.manager.GameServerManager;
import com.nucleus.player.service.ScriptService;

/**
 * 夜晚机率加倍
 * 
 * @author wgy
 *
 */
@GenIgnored
public class PassiveSkillLaunchCondition_6 extends AbstractPassiveSkillLaunchCondition {
	private String rateFormula;

	@Override
	public boolean launchable(BattleSoldier soldier, BattleSoldier target, CommandContext context, IPassiveSkill passiveSkill) {
		Map<String, Object> params = new HashMap<String, Object>();
		params.put("night", GameServerManager.getInstance().night());
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
