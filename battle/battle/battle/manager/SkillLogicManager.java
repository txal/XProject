/**
 * 
 */
package com.nucleus.logic.core.modules.battle.manager;

import java.util.Set;

import javax.annotation.PostConstruct;

import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;

import com.nucleus.commons.logic.LogicManager;
import com.nucleus.commons.utils.SpringUtils;
import com.nucleus.logic.core.modules.battle.logic.SkillLogic;

/**
 * @author Omanhom
 * 
 */
@Service
public class SkillLogicManager extends LogicManager<SkillLogic> {
	public static SkillLogicManager getInstance() {
		return SpringUtils.getBeanOfType(SkillLogicManager.class);
	}

	@Autowired
	private Set<SkillLogic> set;

	@Override
	public Set<SkillLogic> getSet() {
		return set;
	}

	@PostConstruct
	@Override
	protected void init() {
		super.init();
	}
}
