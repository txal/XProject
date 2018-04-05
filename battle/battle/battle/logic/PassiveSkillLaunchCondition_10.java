package com.nucleus.logic.core.modules.battle.logic;

import java.util.HashMap;
import java.util.Map;

import org.apache.commons.lang3.ArrayUtils;
import org.apache.commons.lang3.StringUtils;
import org.apache.commons.lang3.math.NumberUtils;

import com.nucleus.commons.annotation.GenIgnored;
import com.nucleus.commons.utils.RandomUtils;
import com.nucleus.logic.core.modules.battle.data.PassiveSkillConfig;
import com.nucleus.logic.core.modules.battle.data.Skill;
import com.nucleus.logic.core.modules.battle.model.BattleSoldier;
import com.nucleus.logic.core.modules.battle.model.CommandContext;
import com.nucleus.player.service.ScriptService;

/**
 * 水/火/雷/土系法术按机率触发
 * 
 * @author wgy
 *
 */
@GenIgnored
public class PassiveSkillLaunchCondition_10 extends AbstractPassiveSkillLaunchCondition {
	private int skillMagicType;
	private String rate;
	private int rateUpSkill;
	private int rateUpConfigId;

	@Override
	public boolean launchable(BattleSoldier soldier, BattleSoldier target, CommandContext context, IPassiveSkill passiveSkill) {
		if (StringUtils.isEmpty(rate))
			return false;
		Skill skill = context.skill();
		int skillLevel = soldier.skillLevel(passiveSkill.getId());
		if (skill.getSkillMagicType() != skillMagicType)
			return false;
		boolean success = RandomUtils.baseRandomHit(calRate(soldier, skillLevel) + rateUp(soldier));
		return success;
	}

	private float calRate(BattleSoldier soldier, int skillLevel) {
		Map<String, Object> params = new HashMap<String, Object>();
		params.put("level", soldier.grade());
		params.put("skillLevel", soldier.grade());
		params.put("skillGrade", skillLevel);
		return ScriptService.getInstance().calcuFloat("", rate, params, false);
	}

	protected float rateUp(BattleSoldier soldier) {
		Skill skill = soldier.skillHolder().passiveSkill(rateUpSkill);
		if (skill != null) {
			String[] formula = PassiveSkillConfig.get(rateUpConfigId).getExtraParams();
			if (ArrayUtils.isNotEmpty(formula)) {
				Map<String, Object> params = new HashMap<String, Object>();
				params.put("level", soldier.grade());
				params.put("skillLevel", soldier.skillLevel(skill.getId()));
				return ScriptService.getInstance().calcuFloat("PassiveSkillLaunchCondition_10.rateUp", formula[0], params, false);
			}

		}
		return NumberUtils.FLOAT_ZERO;
	}

	public int getSkillMagicType() {
		return skillMagicType;
	}

	public void setSkillMagicType(int skillMagicType) {
		this.skillMagicType = skillMagicType;
	}

	public String getRate() {
		return rate;
	}

	public void setRate(String rate) {
		this.rate = rate;
	}

	public int getRateUpSkill() {
		return rateUpSkill;
	}

	public void setRateUpSkill(int rateUpSkill) {
		this.rateUpSkill = rateUpSkill;
	}

	public int getRateUpConfigId() {
		return rateUpConfigId;
	}

	public void setRateUpConfigId(int rateUpConfigId) {
		this.rateUpConfigId = rateUpConfigId;
	}

}
