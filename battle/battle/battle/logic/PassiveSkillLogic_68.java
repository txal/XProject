package com.nucleus.logic.core.modules.battle.logic;

import org.springframework.stereotype.Service;

import com.nucleus.logic.core.modules.battle.data.PassiveSkillConfig;
import com.nucleus.logic.core.modules.battle.data.PassiveSkillLaunchTimingEnum;
import com.nucleus.logic.core.modules.battle.model.BattleSoldier;
import com.nucleus.logic.core.modules.battle.model.CommandContext;

/**
 * 群攻法连:击杀任一目标触发法术连击
 * 
 * @author wgy
 *
 */
@Service
public class PassiveSkillLogic_68 extends AbstractPassiveSkillLogic {
	@Override
	public boolean launchable(BattleSoldier soldier, BattleSoldier target, CommandContext context, PassiveSkillConfig config, PassiveSkillLaunchTimingEnum timing, IPassiveSkill passiveSkill) {
		if (!super.launchable(soldier, target, context, config, timing, passiveSkill))
			return false;
		BattleSoldier t = target != null ? target : context.getFirstTarget();
		if (t == null)
			return false;
		if (!soldier.isEnemy(t.getId()))
			return false;
		if (t.team().isAllDead())
			return false;
		if (context.isStrokeBack() || context.isCombo())
			return false; // 反击不再导致连击
		return true;
	}
	
	@Override
	protected void doApply(BattleSoldier soldier, BattleSoldier target, CommandContext context, PassiveSkillConfig config, PassiveSkillLaunchTimingEnum timing, IPassiveSkill passiveSkill) {
		magicCombo(soldier, target, context, config, timing, passiveSkill);
	}
}
