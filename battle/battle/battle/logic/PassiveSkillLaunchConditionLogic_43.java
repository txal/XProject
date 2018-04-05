package com.nucleus.logic.core.modules.battle.logic;

import java.util.Map;
import java.util.Set;

import org.springframework.stereotype.Service;

import com.nucleus.commons.utils.SplitUtils;

/**
 * 己方有指定任一buff类型或者任一指定buff就能触发
 *
 * @author zhanhua.xu
 */
@Service
public class PassiveSkillLaunchConditionLogic_43 extends AbstractPassiveSkillLaunchConditionLogic {
	@Override
	public AbstractPassiveSkillLaunchCondition getInstance(Map<String, String> properties) {
		if (properties == null || properties.isEmpty())
			return null;
		PassiveSkillLaunchCondition_43 condition = (PassiveSkillLaunchCondition_43) newInstance();
		condition.setId(Integer.parseInt(properties.get("id")));
		String buffTypeStr = properties.get("buffTypes");
		Set<Integer> buffTypes = SplitUtils.split2IntSet(buffTypeStr, "\\|");
		condition.setBuffTypes(buffTypes);
		String buffIdStr = properties.get("buffIds");
		Set<Integer> buffIds = SplitUtils.split2IntSet(buffIdStr, "\\|");
		condition.setBuffIds(buffIds);
		return condition;
	}

	@Override
	public AbstractPassiveSkillLaunchCondition newInstance() {
		return new PassiveSkillLaunchCondition_43();
	}
}
