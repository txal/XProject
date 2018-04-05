package com.nucleus.logic.core.modules.battle.logic;

import java.util.HashMap;
import java.util.Map;

import com.nucleus.commons.annotation.GenIgnored;
import com.nucleus.commons.utils.RandomUtils;
import com.nucleus.logic.core.modules.battle.model.BattleSoldier;
import com.nucleus.logic.core.modules.battle.model.CommandContext;
import com.nucleus.player.service.ScriptService;

/**
 * 罡气 受到法术攻击时，有3%*技能等级的概率降低40%伤害
 *
 * @author zhanhua.xu
 */
@GenIgnored
public class PassiveSkillLaunchCondition_42 extends AbstractPassiveSkillLaunchCondition {
	private String rateFormula;
	private int skillId;

	@Override
	public boolean launchable(BattleSoldier soldier, BattleSoldier target, CommandContext context, IPassiveSkill passiveSkill) {
		if (!context.skill().ifMagicSkill())
			return false;
		int skillLevel = soldier.skillLevel(skillId);
		if (skillLevel <= 0)
			return false;
		Map<String, Object> params = new HashMap<String, Object>();
		params.put("skillLevel", skillLevel);
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

	public int getSkillId() {
		return skillId;
	}

	public void setSkillId(int skillId) {
		this.skillId = skillId;
	}

}
