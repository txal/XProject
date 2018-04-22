package com.nucleus.logic.core.modules.battle.logic;

import java.util.HashMap;
import java.util.Map;

import com.nucleus.commons.annotation.GenIgnored;
import com.nucleus.commons.utils.RandomUtils;
import com.nucleus.logic.core.modules.battle.model.BattleSoldier;
import com.nucleus.logic.core.modules.battle.model.CommandContext;
import com.nucleus.player.service.ScriptService;

/**
 * 使用物理物理系/魔法系技能，按几率触发
 * 
 * @author wangyu
 *
 */
@GenIgnored
public class PassiveSkillLaunchCondition_83 extends AbstractPassiveSkillLaunchCondition {
	/** 技能类型(物理、魔法) */
	private int skillType;
	/** 触发概率 */
	private String rate;

	@Override
	public boolean launchable(BattleSoldier soldier, BattleSoldier target, CommandContext context, IPassiveSkill passiveSkill) {
		if (context.skill().getSkillAttackType() != skillType)
			return false;
		int skillLevel = soldier.skillLevel(passiveSkill.getId());
		Map<String, Object> params = new HashMap<String, Object>();
		params.put("skillLevel", skillLevel);
		float v = ScriptService.getInstance().calcuFloat("", rate, params, false);
		boolean success = RandomUtils.baseRandomHit(v);
		return success;
	}

	public int getSkillType() {
		return skillType;
	}

	public void setSkillType(int skillType) {
		this.skillType = skillType;
	}

	public String getRate() {
		return rate;
	}

	public void setRate(String rate) {
		this.rate = rate;
	}

}
