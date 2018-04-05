package com.nucleus.logic.core.modules.battle.logic;

import java.util.Map;
import java.util.Set;

import org.springframework.stereotype.Service;

import com.nucleus.commons.utils.SplitUtils;

@Service
public class PassiveSkillLaunchConditionLogic_62 extends AbstractPassiveSkillLaunchConditionLogic {

	@Override
	public AbstractPassiveSkillLaunchCondition newInstance() {
		return new PassiveSkillLaunchCondition_62();
	}

	@Override
	public AbstractPassiveSkillLaunchCondition getInstance(Map<String, String> properties) {
		if (properties == null || properties.isEmpty())
			return null;
		PassiveSkillLaunchCondition_62 condition = (PassiveSkillLaunchCondition_62) newInstance();
		condition.setLeftRound(Integer.parseInt(properties.get("leftRound")));
		String clearBuff = properties.getOrDefault("clearBuff", "n");
		condition.setClearBuff("y".equals(clearBuff) ? true : false);

		String buffIdsStr = properties.get("buffIds");
		Set<Integer> buffIds = SplitUtils.split2IntSet(buffIdsStr, "\\|");
		condition.setBuffIds(buffIds);
		return condition;
	}

}
