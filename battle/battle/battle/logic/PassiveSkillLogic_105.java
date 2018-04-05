package com.nucleus.logic.core.modules.battle.logic;

import java.util.HashMap;
import java.util.Map;

import org.apache.commons.lang3.ArrayUtils;
import org.springframework.stereotype.Service;

import com.nucleus.commons.data.StaticConfig;
import com.nucleus.logic.core.modules.AppStaticConfigs;
import com.nucleus.logic.core.modules.battle.data.PassiveSkillConfig;
import com.nucleus.logic.core.modules.battle.data.PassiveSkillLaunchTimingEnum;
import com.nucleus.logic.core.modules.battle.model.BattleSoldier;
import com.nucleus.logic.core.modules.battle.model.CommandContext;
import com.nucleus.player.service.ScriptService;

/**
 * 满足某些条件可以使用extra参数影响伤害输出
 *
 * @author wangyu
 */
@Service
public class PassiveSkillLogic_105 extends AbstractPassiveSkillLogic {
	@Override
	protected void doApply(BattleSoldier soldier, BattleSoldier target, CommandContext context, PassiveSkillConfig config, PassiveSkillLaunchTimingEnum timing, IPassiveSkill passiveSkill) {
		if (context == null)
			return;
		int skillId = config.getRelativeSkillId() > 0 ? config.getRelativeSkillId() : passiveSkill.getId();
		int skillLevel = soldier.skillLevel(skillId);
		if (ArrayUtils.isNotEmpty(config.getPropertyEffectFormulas())) {
			Map<String, Object> params = new HashMap<String, Object>();
			params.put("level", soldier.grade());
			params.put("skillLevel", skillLevel);
			params.put("damage", context.getDamageOutput());
			params.put("self", soldier);
			params.put("target", target);

			String formula = config.getPropertyEffectFormulas()[0];
			if (soldier.allLuckyPassSkills()) {
				formula = config.getExtraParams()[0];
			}
			Float damage = ScriptService.getInstance().calcuFloat("", formula, params, false);
			setDamage(context, damage.intValue());
			// 如果触发了浴血凤凰，会影响扣血下限，所以特殊处理
			if (skillId == StaticConfig.get(AppStaticConfigs.PHOENIX_BLOOD_SKILL).getAsInt(5322)) {
				soldier.setEffectPhoenixSkill(true);
			}
		}
	}

	protected void setDamage(CommandContext context, int damage) {
		context.setDamageOutput(damage);
	}
}
