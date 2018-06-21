package com.nucleus.logic.core.modules.battle.logic;

import java.util.Map;

import org.apache.commons.beanutils.BeanUtils;

import com.nucleus.commons.logic.Logic;

/**
 * 被动技能触发条件逻辑
 * 
 * @author wgy
 *
 */
public abstract class AbstractPassiveSkillLaunchConditionLogic implements Logic {
	public abstract AbstractPassiveSkillLaunchCondition newInstance();

	public AbstractPassiveSkillLaunchCondition getInstance(Map<String, String> properties) {
		if (properties == null || properties.isEmpty())
			return null;
		AbstractPassiveSkillLaunchCondition condition = newInstance();
		try {
			BeanUtils.populate(condition, properties);
		} catch (Exception e) {
			e.printStackTrace();
		}
		return condition;
	}
}
