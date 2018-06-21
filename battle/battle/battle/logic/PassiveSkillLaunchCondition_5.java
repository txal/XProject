package com.nucleus.logic.core.modules.battle.logic;

import java.util.HashMap;
import java.util.Map;

import com.nucleus.commons.annotation.GenIgnored;
import com.nucleus.commons.utils.RandomUtils;
import com.nucleus.logic.core.modules.battle.model.BattleSoldier;
import com.nucleus.logic.core.modules.battle.model.CommandContext;
import com.nucleus.player.service.ScriptService;

/**
 * 法术攻击
 * 
 * @author wgy
 *
 */
@GenIgnored
public class PassiveSkillLaunchCondition_5 extends AbstractPassiveSkillLaunchCondition {
	private String rate;

	@Override
	public boolean launchable(BattleSoldier soldier, BattleSoldier target, CommandContext context, IPassiveSkill passiveSkill) {
		if (!context.skill().ifMagicSkill())
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
