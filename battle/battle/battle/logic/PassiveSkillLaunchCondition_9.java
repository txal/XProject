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
 * 按机率触发
 * 
 * @author wgy
 *
 */
@GenIgnored
public class PassiveSkillLaunchCondition_9 extends AbstractPassiveSkillLaunchCondition {
	private String rate;
	/** 是否扣血 */
	private boolean hpLose;

	@Override
	public boolean launchable(BattleSoldier soldier, BattleSoldier target, CommandContext context, IPassiveSkill passiveSkill) {
		if (StringUtils.isBlank(rate))
			return false;
		if (hpLose && context != null && context.getDamageOutput() > 0)
			return false;
		int skillLevel = soldier.skillLevel(passiveSkill.getId());
		Map<String, Object> params = new HashMap<String, Object>();
		params.put("self", soldier);
		params.put("skillLevel", skillLevel);
		params.put("round", soldier.battle().getCount());

		float v = ScriptService.getInstance().calcuFloat("", rate, params, false);
		return RandomUtils.baseRandomHit(v);
	}

	public String getRate() {
		return rate;
	}

	public void setRate(String rate) {
		this.rate = rate;
	}

	public boolean isHpLose() {
		return hpLose;
	}

	public void setHpLose(boolean hpLose) {
		this.hpLose = hpLose;
	}

}
