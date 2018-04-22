package com.nucleus.logic.core.modules.battle.logic;

import java.util.HashMap;
import java.util.Map;

import org.springframework.stereotype.Service;

import com.nucleus.logic.core.modules.battle.data.PassiveSkillConfig;
import com.nucleus.logic.core.modules.battle.data.PassiveSkillLaunchTimingEnum;
import com.nucleus.logic.core.modules.battle.dto.VideoActionTargetState;
import com.nucleus.logic.core.modules.battle.model.BattleSoldier;
import com.nucleus.logic.core.modules.battle.model.CommandContext;
import com.nucleus.player.service.ScriptService;

/**
 * 法术吸血
 * 
 * @author hwy
 *
 */
@Service
public class PassiveSkillLogic_77 extends AbstractPassiveSkillLogic {

	@Override
	public boolean launchable(BattleSoldier soldier, BattleSoldier target, CommandContext context, PassiveSkillConfig config, PassiveSkillLaunchTimingEnum timing, IPassiveSkill passiveSkill) {
		if (!super.launchable(soldier, target, context, config, timing, passiveSkill))
			return false;
		// 只有魔法系法术伤害才能吸血
		return context.skill().ifMagicAttack();
	}

	@Override
	protected void doApply(BattleSoldier soldier, BattleSoldier target, CommandContext context, PassiveSkillConfig config, PassiveSkillLaunchTimingEnum timing, IPassiveSkill passiveSkill) {
		int hp = calcValue(soldier, context, config, passiveSkill);
		hp = Math.abs(hp);
		soldier.increaseHp(hp);
		context.skillAction().addTargetState(new VideoActionTargetState(soldier, hp, 0, false));
	}

	private int calcValue(BattleSoldier soldier, CommandContext context, PassiveSkillConfig config, IPassiveSkill passiveSkill) {
		Map<String, Object> params = new HashMap<String, Object>();
		params.put("damage", context.getTotalHpVaryAmount());
		params.put("self", soldier);
		params.put("skillLevel", soldier.skillLevel(passiveSkill.getId()));
		int hp = ScriptService.getInstance().calcuInt("", config.getPropertyEffectFormulas()[0], params, false);
		return hp;
	}
}
