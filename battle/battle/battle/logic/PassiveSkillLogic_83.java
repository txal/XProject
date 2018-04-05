package com.nucleus.logic.core.modules.battle.logic;

import java.util.HashMap;
import java.util.Map;

import org.apache.commons.lang3.ArrayUtils;
import org.apache.commons.lang3.StringUtils;
import org.springframework.stereotype.Service;

import com.nucleus.logic.core.modules.battle.data.PassiveSkillConfig;
import com.nucleus.logic.core.modules.battle.data.PassiveSkillLaunchTimingEnum;
import com.nucleus.logic.core.modules.battle.data.Skill;
import com.nucleus.logic.core.modules.battle.model.BattleSoldier;
import com.nucleus.logic.core.modules.battle.model.CommandContext;
import com.nucleus.player.service.ScriptService;

/**
 * 团队HP影响
 * 
 * @author hwy
 *
 */
@Service
public class PassiveSkillLogic_83 extends PassiveSkillLogic_2 {
	@Override
	protected void doApply(BattleSoldier soldier, BattleSoldier target, CommandContext context, PassiveSkillConfig config, PassiveSkillLaunchTimingEnum timing, IPassiveSkill passiveSkill) {
		if (context == null)
			return;
		Skill skill = context.skill();
		Map<String, Object> mateData = context.getMateData();
		if (StringUtils.isNotBlank(skill.getTeamSuccessHpEffectFormula()) && mateData.containsKey("team_add_hp")) {
			int skillId = config.getRelativeSkillId() > 0 ? config.getRelativeSkillId() : passiveSkill.getId();
			int skillLevel = soldier.skillLevel(skillId);
			if (ArrayUtils.isNotEmpty(config.getPropertyEffectFormulas())) {
				int damage = (Integer) mateData.getOrDefault("team_add_hp", 0);
				String formula = config.getPropertyEffectFormulas()[0];
				Map<String, Object> params = new HashMap<String, Object>();
				params.put("skillLevel", skillLevel);
				params.put("damage", damage);
				params.put("weaponAttack", soldier.weaponAttack());
				int hp = ScriptService.getInstance().calcuInt("PassiveSkillLogic_83.doApply", formula, params, false);
				context.getMateData().put("team_add_hp", hp);
			}
		} else {
			super.doApply(soldier, target, context, config, timing, passiveSkill);
		}
	}
}
