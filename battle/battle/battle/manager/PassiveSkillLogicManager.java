package com.nucleus.logic.core.modules.battle.manager;

import java.util.Set;

import javax.annotation.PostConstruct;

import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;

import com.nucleus.commons.logic.LogicManager;
import com.nucleus.commons.utils.SpringUtils;
import com.nucleus.logic.core.modules.battle.logic.IPassiveSkillLogic;

/**
 * 被动技能效果逻辑管理
 * 
 * @author wgy
 *
 */
@Service
public class PassiveSkillLogicManager extends LogicManager<IPassiveSkillLogic> {

	public static PassiveSkillLogicManager getInstance() {
		return SpringUtils.getBeanOfType(PassiveSkillLogicManager.class);
	}

	@Autowired(required = false)
	private Set<IPassiveSkillLogic> set;

	@Override
	public Set<IPassiveSkillLogic> getSet() {
		return set;
	}

	@PostConstruct
	@Override
	protected void init() {
		super.init();
	}

}
