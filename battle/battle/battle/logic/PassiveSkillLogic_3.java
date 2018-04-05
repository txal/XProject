package com.nucleus.logic.core.modules.battle.logic;

import org.springframework.stereotype.Service;

import com.nucleus.logic.core.modules.battle.data.PassiveSkillConfig;
import com.nucleus.logic.core.modules.battle.data.PassiveSkillLaunchTimingEnum;
import com.nucleus.logic.core.modules.battle.manager.SkillLogicManager;
import com.nucleus.logic.core.modules.battle.model.BattleSoldier;
import com.nucleus.logic.core.modules.battle.model.CommandContext;

/**
 * 连击
 * 
 * @author wgy
 *
 */
@Service
public class PassiveSkillLogic_3 extends AbstractPassiveSkillLogic {
	@Override
	public boolean launchable(BattleSoldier soldier, BattleSoldier target, CommandContext context, PassiveSkillConfig config, PassiveSkillLaunchTimingEnum timing, IPassiveSkill passiveSkill) {
		if (!super.launchable(soldier, target, context, config, timing, passiveSkill))
			return false;
		if (target == null || target.isDead())
			return false;
		if (!soldier.isEnemy(target.getId()))
			return false;
		if (context.isStrokeBack() || context.isCombo())
			return false; // 反击不再导致连击
		return true;
	}

	@Override
	protected void doApply(BattleSoldier soldier, BattleSoldier target, CommandContext context, PassiveSkillConfig config, PassiveSkillLaunchTimingEnum timing, IPassiveSkill passiveSkill) {
		float rate = 1;
		if (config.getExtraParams() != null) {
			try {
				rate = Float.parseFloat(config.getExtraParams()[0]);
			} catch (Exception e) {
				e.printStackTrace();
			}
		}
		context.setCurDamageVaryRate(rate);
		context.setCombo(true);
		SkillLogic_1 logic = (SkillLogic_1) SkillLogicManager.getInstance().getLogic(1);
		soldier.skillHolder().passiveSkillEffectByTiming(target, context, PassiveSkillLaunchTimingEnum.ComboDamageOutput);
		logic.attack(context, context.target(), 1, 1);
		// 连接触发追击
		soldier.skillHolder().passiveSkillEffectByTiming(target, context, PassiveSkillLaunchTimingEnum.PursueAttack);
	}
}
