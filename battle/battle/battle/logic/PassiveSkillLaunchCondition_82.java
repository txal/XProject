package com.nucleus.logic.core.modules.battle.logic;

import java.util.HashMap;
import java.util.Map;

import com.nucleus.commons.annotation.GenIgnored;
import com.nucleus.logic.core.modules.battle.model.BattleSoldier;
import com.nucleus.logic.core.modules.battle.model.CommandContext;
import com.nucleus.player.service.ScriptService;

/**
 * 目标受击大于等于气血上限百分比
 * 
 * @author wangyu
 *
 */
@GenIgnored
public class PassiveSkillLaunchCondition_82 extends AbstractPassiveSkillLaunchCondition {

	private String precent;

	@Override
	public boolean launchable(BattleSoldier soldier, BattleSoldier target, CommandContext context, IPassiveSkill passiveSkill) {
		if (context == null)
			return false;
		int skillLevel = soldier.skillLevel(passiveSkill.getId());
		Map<String, Object> paramMap = new HashMap<>();
		paramMap.put("skillLevel", skillLevel);
		float pre = ScriptService.getInstance().calcuFloat("PassiveSkillLaunchCondition_78.launchable", this.precent, paramMap, false);
		return Math.abs(context.getDamageOutput()) >= (int) (target.maxHp() * pre);
	}

	public String getPrecent() {
		return precent;
	}

	public void setPrecent(String precent) {
		this.precent = precent;
	}

}
