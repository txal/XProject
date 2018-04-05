package com.nucleus.logic.core.modules.battle.logic;

import java.util.HashMap;
import java.util.Map;

import org.springframework.stereotype.Service;

import com.nucleus.logic.core.modules.battle.data.PassiveSkillConfig;
import com.nucleus.logic.core.modules.battle.data.PassiveSkillLaunchTimingEnum;
import com.nucleus.logic.core.modules.battle.model.BattleSoldier;
import com.nucleus.logic.core.modules.battle.model.CommandContext;
import com.nucleus.logic.core.modules.battlebuff.data.BattleBuff.BattleBasePropertyType;

/**
 * 目标为鬼魂就替换原本的属性效果公式
 *
 * @author wangyu
 */
@Service
public class PassiveSkillLogic_99 extends AbstractPassiveSkillLogic {
	@Override
	protected void doApply(BattleSoldier soldier, BattleSoldier target, CommandContext context, PassiveSkillConfig config, PassiveSkillLaunchTimingEnum timing, IPassiveSkill passiveSkill) {
		int[] properties = config.getPropertys();
		String[] formulas = config.getPropertyEffectFormulas();
		if (properties.length <= 0) {
			return;
		}
		context.setEffectGhost(true);
		Map<String, Object> paramMap = new HashMap<>();
		Map<String, Object> Metaparam = context.getMateData();
		if (Metaparam != null && !Metaparam.isEmpty()) {
			paramMap.putAll(Metaparam);
		}
		paramMap.put("skillLevel", soldier.skillLevel(passiveSkill.getId()));
		for (int i = 0; i < properties.length; i++) {
			if (properties[i] == BattleBasePropertyType.DamageInput.ordinal()) {
				paramMap.put("hpEffect", formulas[i]);
			}
			if (properties[i] == BattleBasePropertyType.Mp.ordinal()) {
				paramMap.put("mpEffect", formulas[i]);
			}
		}
		context.setMateData(paramMap);
	}
}
