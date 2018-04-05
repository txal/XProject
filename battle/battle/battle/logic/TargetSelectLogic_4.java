package com.nucleus.logic.core.modules.battle.logic;

import java.util.List;
import java.util.Map;
import java.util.Set;

import org.springframework.stereotype.Service;

import com.nucleus.commons.utils.RandomUtils;
import com.nucleus.logic.core.modules.battle.data.Skill;
import com.nucleus.logic.core.modules.battle.model.BattleSoldier;
import com.nucleus.logic.core.modules.battle.model.CommandContext;

/**
 * 随机选择n个
 * 
 * @author wgy
 *
 */
@Service
public class TargetSelectLogic_4 extends TargetSelectLogic_0 {
	
	@Override
	protected TargetSelectLogicParam createParam() {
		return new TargetSelectLogicParam_4();
	}
	@Override
	public List<SkillTargetInfo> skillTargetInfos(Skill skill) {
		TargetSelectLogicParam_4 param = (TargetSelectLogicParam_4) skill.selectLogicParam();
		int count = RandomUtils.nextInt(param.getMin(), param.getMax());
		if (count < 1 || count >= skill.skillTargetInfos().size())
			return skill.skillTargetInfos();
		return skill.skillTargetInfos().subList(0, count);
	}
	
	@Override
	public List<BattleSoldier> filter(Map<Long, BattleSoldier> availableTargets, CommandContext commandContext, Set<Long> ignoreSoldierIds) {
		List<BattleSoldier> soldiers = super.filter(availableTargets, commandContext, ignoreSoldierIds);
		TargetSelectLogicParam_4 param = (TargetSelectLogicParam_4) commandContext.skill().selectLogicParam();
		int count = RandomUtils.nextInt(param.getMin(), param.getMax());
		if (count < 1 || count >= soldiers.size())
			return soldiers;
		return soldiers.subList(0, count);
	}
}
