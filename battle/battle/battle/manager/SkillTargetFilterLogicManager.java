package com.nucleus.logic.core.modules.battle.manager;

import java.util.Set;

import javax.annotation.PostConstruct;

import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;

import com.nucleus.commons.logic.LogicManager;
import com.nucleus.commons.utils.SpringUtils;
import com.nucleus.logic.core.modules.battle.logic.AbstractSkillTargetFilterLogic;

/**
 * 目标过滤逻辑管理
 * 
 * @author wgy
 *
 */
@Service
public class SkillTargetFilterLogicManager extends LogicManager<AbstractSkillTargetFilterLogic> {

	public static SkillTargetFilterLogicManager getInstance() {
		return SpringUtils.getBeanOfType(SkillTargetFilterLogicManager.class);
	}

	@Autowired(required = false)
	private Set<AbstractSkillTargetFilterLogic> set;

	@Override
	public Set<AbstractSkillTargetFilterLogic> getSet() {
		return this.set;
	}

	@PostConstruct
	@Override
	protected void init() {
		super.init();
	}
}
