package com.nucleus.logic.core.modules.battle.logic;

import java.util.Set;

import org.springframework.stereotype.Service;

import com.nucleus.commons.utils.SplitUtils;
import com.nucleus.logic.core.modules.battle.data.PassiveSkillConfig;
import com.nucleus.logic.core.modules.battle.data.PassiveSkillLaunchTimingEnum;
import com.nucleus.logic.core.modules.battle.model.BattleSoldier;
import com.nucleus.logic.core.modules.battle.model.CommandContext;
import com.nucleus.logic.core.modules.battlebuff.data.BattleBuff;

/**
 * 免疫特定类型的buff
 * 
 * @author wgy
 *
 */
@Service
public class PassiveSkillLogic_37 extends AbstractPassiveSkillLogic {
	@Override
	protected void doApply(BattleSoldier soldier, BattleSoldier target, CommandContext context, PassiveSkillConfig config, PassiveSkillLaunchTimingEnum timing, IPassiveSkill passiveSkill) {
		Set<Integer> buffTypes = SplitUtils.split2IntSet(config.getExtraParams()[0], ",");
		if (buffTypes.isEmpty())
			return;
		int buffId = context.getBeAddBuffId();
		BattleBuff buff = BattleBuff.get(buffId);
		if (buff == null)
			return;
		if (buffTypes.contains(buff.getBuffType()))
			context.setBeAddBuffId(0);
	}
}
