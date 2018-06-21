package com.nucleus.logic.core.modules.battle.logic;

import java.util.HashMap;
import java.util.Map;
import java.util.Set;

import org.springframework.stereotype.Service;

import com.nucleus.commons.utils.SplitUtils;
import com.nucleus.logic.core.modules.battle.data.PassiveSkillConfig;
import com.nucleus.logic.core.modules.battle.data.PassiveSkillLaunchTimingEnum;
import com.nucleus.logic.core.modules.battle.model.BattleSoldier;
import com.nucleus.logic.core.modules.battle.model.CommandContext;
import com.nucleus.player.service.ScriptService;

/**
 * 怪物数量影响伤害输出
 * 
 * @author wgy
 *
 */
@Service
public class PassiveSkillLogic_63 extends AbstractPassiveSkillLogic {
	@Override
	protected void doApply(BattleSoldier soldier, BattleSoldier target, CommandContext context, PassiveSkillConfig config, PassiveSkillLaunchTimingEnum timing, IPassiveSkill passiveSkill) {
		if (context == null)
			return;
		String formula = config.getPropertyEffectFormulas()[0];
		Set<Integer> monsterIds = SplitUtils.split2IntSet(config.getExtraParams()[0], ",");
		Map<String, Object> params = new HashMap<String, Object>();
		params.put("monsterCount", monsterCountOf(soldier, monsterIds));
		params.put("damage", context.getDamageOutput());

		Float damage = ScriptService.getInstance().calcuFloat("", formula, params, false);
		context.setDamageOutput(damage.intValue());

	}

	private int monsterCountOf(BattleSoldier soldier, Set<Integer> monsterIds) {
		return (int) (soldier.team().aliveSoldiers().stream().filter(s -> monsterIds.contains(s.monsterId())).count());
	}

}
