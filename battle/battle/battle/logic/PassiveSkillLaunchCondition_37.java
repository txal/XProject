package com.nucleus.logic.core.modules.battle.logic;

import java.util.HashMap;
import java.util.Map;

import org.apache.commons.lang3.StringUtils;

import com.nucleus.commons.annotation.GenIgnored;
import com.nucleus.commons.utils.RandomUtils;
import com.nucleus.logic.core.modules.battle.model.BattleSoldier;
import com.nucleus.logic.core.modules.battle.model.CommandContext;
import com.nucleus.player.service.ScriptService;

/**
 * 所有消耗mp的法术
 * 
 * @author wgy
 *
 */
@GenIgnored
public class PassiveSkillLaunchCondition_37 extends AbstractPassiveSkillLaunchCondition {
	private String rate;

	@Override
	public boolean launchable(BattleSoldier soldier, BattleSoldier target, CommandContext context, IPassiveSkill passiveSkill) {
		if (StringUtils.isBlank(context.skill().getSpendMpFormula()))
			return false;
		int skillLevel = soldier.skillLevel(passiveSkill.getId());
		Map<String, Object> params = new HashMap<String, Object>();
		params.put("skillLevel", skillLevel);
		float v = ScriptService.getInstance().calcuFloat("", rate, params, false);
		boolean success = RandomUtils.baseRandomHit(v);
		return success;
	}

	public String getRate() {
		return rate;
	}

	public void setRate(String rate) {
		this.rate = rate;
	}

	

}
