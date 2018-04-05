package com.nucleus.logic.core.modules.battle.logic;

import java.util.HashMap;
import java.util.Map;

import com.nucleus.commons.annotation.GenIgnored;
import com.nucleus.commons.utils.RandomUtils;
import com.nucleus.logic.core.modules.battle.data.Skill;
import com.nucleus.logic.core.modules.battle.model.BattleSoldier;
import com.nucleus.logic.core.modules.battle.model.CommandContext;
import com.nucleus.player.service.ScriptService;

/**
 * 妙手空空：普通物理攻击时，有30%概率偷取目标一个增益状态。若自身力量点数低于等级*5时，发动概率减半
 * 
 * @author wgy
 *
 */
@GenIgnored
public class PassiveSkillLaunchCondition_40 extends AbstractPassiveSkillLaunchCondition {
	private String rateFormula;

	@Override
	public boolean launchable(BattleSoldier soldier, BattleSoldier target, CommandContext context, IPassiveSkill passiveSkill) {
		if (context.skill().getId() != Skill.defaultActiveSkillId())
			return false;
		Map<String, Object> params = new HashMap<String, Object>();
		params.put("self", soldier);
		float rate = ScriptService.getInstance().calcuFloat("", rateFormula, params, false);
		boolean hit = RandomUtils.baseRandomHit(rate);
		return hit;
	}

	public String getRateFormula() {
		return rateFormula;
	}

	public void setRateFormula(String rateFormula) {
		this.rateFormula = rateFormula;
	}

}
