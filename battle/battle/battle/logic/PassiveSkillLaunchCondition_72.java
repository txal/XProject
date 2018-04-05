package com.nucleus.logic.core.modules.battle.logic;

import java.util.HashMap;
import java.util.Map;

import com.nucleus.commons.annotation.GenIgnored;
import com.nucleus.logic.core.modules.battle.model.BattleSoldier;
import com.nucleus.logic.core.modules.battle.model.CommandContext;
import com.nucleus.player.service.ScriptService;

/**
 * 受击大于等于血气上限百分比
 * 
 * @author hwy
 *
 */
@GenIgnored
public class PassiveSkillLaunchCondition_72 extends AbstractPassiveSkillLaunchCondition {

	private String precent;

	@Override
	public boolean launchable(BattleSoldier soldier, BattleSoldier target, CommandContext context, IPassiveSkill passiveSkill) {
		if (context == null)
			return false;
		int skillLevel = soldier.skillLevel(passiveSkill.getId());
		Map<String, Object> paramMap = new HashMap<>();
		paramMap.put("skillLevel", skillLevel);
		float pre = ScriptService.getInstance().calcuFloat("PassiveSkillLaunchCondition_72.launchable", this.precent, paramMap, false);
		return Math.abs(context.getDamageOutput()) >= (int) (soldier.maxHp() * pre);
	}

	public String getPrecent() {
		return precent;
	}

	public void setPrecent(String precent) {
		this.precent = precent;
	}
}
