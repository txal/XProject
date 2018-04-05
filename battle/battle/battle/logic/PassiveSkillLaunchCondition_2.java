package com.nucleus.logic.core.modules.battle.logic;

import java.util.HashMap;
import java.util.Map;

import org.apache.commons.lang3.ArrayUtils;
import org.apache.commons.lang3.math.NumberUtils;

import com.nucleus.commons.annotation.GenIgnored;
import com.nucleus.commons.utils.RandomUtils;
import com.nucleus.logic.core.modules.battle.data.PassiveSkillConfig;
import com.nucleus.logic.core.modules.battle.data.Skill;
import com.nucleus.logic.core.modules.battle.model.BattleSoldier;
import com.nucleus.logic.core.modules.battle.model.CommandContext;
import com.nucleus.player.service.ScriptService;

/**
 * 使用普通物理攻击时按机率触发
 * 
 * @author wgy
 *
 */
@GenIgnored
public class PassiveSkillLaunchCondition_2 extends AbstractPassiveSkillLaunchCondition {
	private float rate;
	private int rateUpSkill;
	private int rateUpConfigId;

	@Override
	public boolean launchable(BattleSoldier soldier, BattleSoldier target, CommandContext context, IPassiveSkill passiveSkill) {
		if (context.skill().getId() != Skill.defaultActiveSkillId())
			return false;
		boolean success = RandomUtils.baseRandomHit(rate + rateUp(soldier));
		return success;
	}

	protected float rateUp(BattleSoldier soldier) {
		Skill skill = soldier.skillHolder().passiveSkill(rateUpSkill);
		if (skill != null) {
			String[] formula = PassiveSkillConfig.get(rateUpConfigId).getExtraParams();
			if (ArrayUtils.isNotEmpty(formula)) {
				Map<String, Object> params = new HashMap<String, Object>();
				params.put("level", soldier.grade());
				params.put("skillLevel", soldier.skillLevel(skill.getId()));
				return ScriptService.getInstance().calcuFloat("PassiveSkillLaunchCondition_2.rateUp", formula[0], params, false);
			}

		}
		return NumberUtils.FLOAT_ZERO;
	}

	public float getRate() {
		return rate;
	}

	public void setRate(float rate) {
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
