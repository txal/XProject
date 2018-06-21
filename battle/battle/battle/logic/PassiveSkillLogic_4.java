package com.nucleus.logic.core.modules.battle.logic;

import java.util.HashMap;
import java.util.List;
import java.util.Map;

import org.springframework.stereotype.Service;

import com.nucleus.logic.core.modules.battle.data.PassiveSkillConfig;
import com.nucleus.logic.core.modules.battle.data.PassiveSkillLaunchTimingEnum;
import com.nucleus.logic.core.modules.battle.manager.SkillLogicManager;
import com.nucleus.logic.core.modules.battle.model.BattleSoldier;
import com.nucleus.logic.core.modules.battle.model.CommandContext;
import com.nucleus.player.service.ScriptService;

/**
 * 倒地追击
 * 
 * @author wgy
 *
 */
@Service
public class PassiveSkillLogic_4 extends AbstractPassiveSkillLogic {
	@Override
	public boolean launchable(BattleSoldier soldier, BattleSoldier target, CommandContext context, PassiveSkillConfig config, PassiveSkillLaunchTimingEnum timing, IPassiveSkill passiveSkill) {
		if (!super.launchable(soldier, target, context, config, timing, passiveSkill))
			return false;
		if (target == null || !target.isDead())
			return false;
		if (context != null && context.isPursueAttack())
			return false;
		if (!soldier.isEnemy(target.getId()))
			return false;
		if (target.team() != null && target.team().aliveSoldiers().isEmpty())
			return false;
		return true;
	}

	@Override
	protected void doApply(BattleSoldier soldier, BattleSoldier target, CommandContext context, PassiveSkillConfig config, PassiveSkillLaunchTimingEnum timing, IPassiveSkill passiveSkill) {
		SkillAiLogic skillAiLogic = context.skill().skillAi().skillAiLogic();
		List<SkillTargetPolicy> targetPolicys = skillAiLogic.selectTargets(context);
		if (targetPolicys.isEmpty())
			return;
		SkillTargetPolicy policy = targetPolicys.get(0);
		if (config.getExtraParams() != null && config.getExtraParams().length > 0) {
			String rateFormula = config.getExtraParams()[0];
			Map<String, Object> paramMap = new HashMap<>();
			paramMap.put("skillLevel", soldier.skillLevel(passiveSkill.getId()));
			float rate = ScriptService.getInstance().calcuFloat("", rateFormula, paramMap, true);
			context.setCurDamageVaryRate(rate);
		}
		if (context.debugEnable())
			context.initDebugInfo(soldier, context.skill(), policy.getTarget());
		SkillLogic_1 logic = (SkillLogic_1) SkillLogicManager.getInstance().getLogic(1);
		if (logic.attack(context, policy.getTarget(), 1, 1)) {
			context.setPursueAttack(true);
			policy.getTarget().addBeAttackTimes(1, context.skill().ifMagicSkill());
		}
	}
}
