package com.nucleus.logic.core.modules.battle.manager;

import java.util.Set;

import javax.annotation.PostConstruct;

import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;

import com.nucleus.commons.logic.LogicManager;
import com.nucleus.commons.utils.SpringUtils;
import com.nucleus.logic.core.modules.battle.logic.AbstractPassiveSkillLaunchConditionLogic;

@Service
public class PassiveSkillLaunchConditionLogicManager extends LogicManager<AbstractPassiveSkillLaunchConditionLogic> {
	public static PassiveSkillLaunchConditionLogicManager getInstance() {
		return SpringUtils.getBeanOfType(PassiveSkillLaunchConditionLogicManager.class);
	}

	@Autowired(required = false)
	private Set<AbstractPassiveSkillLaunchConditionLogic> set;

	@Override
	public Set<AbstractPassiveSkillLaunchConditionLogic> getSet() {
		return set;
	}

	@PostConstruct
	@Override
	protected void init() {
		super.init();
	}

}
