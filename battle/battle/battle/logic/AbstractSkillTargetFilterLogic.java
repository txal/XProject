package com.nucleus.logic.core.modules.battle.logic;

import java.util.Map;

import org.apache.commons.beanutils.BeanUtils;

import com.nucleus.commons.logic.Logic;

/**
 * 目标过滤
 * 
 * @author wgy
 *
 */
public abstract class AbstractSkillTargetFilterLogic implements Logic {
	public abstract AbstractSkillTargetFilter newInstance();

	public AbstractSkillTargetFilter getInstance(Map<String, String> properties) {
		if (properties == null || properties.isEmpty())
			return null;
		AbstractSkillTargetFilter filter = newInstance();
		try {
			BeanUtils.populate(filter, properties);
		} catch (Exception e) {
			e.printStackTrace();
		}
		return filter;
	}
}
