package com.nucleus.logic.core.modules.battle.logic;

import java.util.HashMap;
import java.util.Map;

import com.nucleus.commons.annotation.GenIgnored;
import com.nucleus.logic.core.modules.battle.model.BattleSoldier;
import com.nucleus.logic.core.modules.battle.model.CommandContext;
import com.nucleus.player.service.ScriptService;

/**
 * 单回合掉血大于等于血气上限百分比
 * 
 * @author hwy
 *
 */
@GenIgnored
public class PassiveSkillLaunchCondition_73 extends AbstractPassiveSkillLaunchCondition {

	private String hpRateFormula;

	@Override
	public boolean launchable(BattleSoldier soldier, BattleSoldier target, CommandContext context, IPassiveSkill passiveSkill) {
		int skillLevel = soldier.skillLevel(passiveSkill.getId());
		Map<String, Object> paramMap = new HashMap<>();
		paramMap.put("skillLevel", skillLevel);
		float hpRate = ScriptService.getInstance().calcuFloat("PassiveSkillLaunchCondition_73.launchable", this.hpRateFormula, paramMap, false);
		return Math.abs(soldier.roundLossHp()) >= (int) (soldier.maxHp() * hpRate);
	}

	public String getHpRateFormula() {
		return hpRateFormula;
	}

	public void setHpRateFormula(String hpRateFormula) {
		this.hpRateFormula = hpRateFormula;
	}
}
