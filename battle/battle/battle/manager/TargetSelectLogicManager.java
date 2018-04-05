package com.nucleus.logic.core.modules.battle.manager;

import java.util.Set;

import javax.annotation.PostConstruct;

import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;

import com.nucleus.commons.logic.LogicManager;
import com.nucleus.commons.utils.SpringUtils;
import com.nucleus.logic.core.modules.battle.logic.ITargetSelectLogic;

/**
 * 目标选择逻辑管理器
 * 
 * @author wgy
 *
 */
@Service
public class TargetSelectLogicManager extends LogicManager<ITargetSelectLogic> {
	@Autowired
	private Set<ITargetSelectLogic> set;

	public static TargetSelectLogicManager getInstance() {
		return SpringUtils.getBeanOfType(TargetSelectLogicManager.class);
	}

	@Override
	public Set<ITargetSelectLogic> getSet() {
		return set;
	}

	@PostConstruct
	@Override
	protected void init() {
		super.init();
	}
}
