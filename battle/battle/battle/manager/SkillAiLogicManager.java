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
import com.nucleus.logic.core.modules.battle.logic.SkillAiLogic;

/**
 * @author Omanhom
 * 
 */
@Service
public class SkillAiLogicManager extends LogicManager<SkillAiLogic> {
	public static SkillAiLogicManager getInstance() {
		return SpringUtils.getBeanOfType(SkillAiLogicManager.class);
	}

	@Autowired
	private Set<SkillAiLogic> set;

	@Override
	public Set<SkillAiLogic> getSet() {
		return set;
	}

	@PostConstruct
	@Override
	protected void init() {
		super.init();
	}
}
