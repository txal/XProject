package com.nucleus.logic.core.modules.battlebuff;

import java.util.Set;

import javax.annotation.PostConstruct;

import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;

import com.nucleus.commons.logic.LogicManager;
import com.nucleus.commons.utils.SpringUtils;

/**
 * 战斗buff逻辑管理
 * 
 * @author wgy
 *
 */
@Service
public class BattleBuffLogicManager extends LogicManager<IBattleBuffLogic> {
	public static BattleBuffLogicManager getInstance() {
		return SpringUtils.getBeanOfType(BattleBuffLogicManager.class);
	}

	@Autowired
	private Set<IBattleBuffLogic> set;

	@Override
	public Set<IBattleBuffLogic> getSet() {
		return set;
	}

	@PostConstruct
	@Override
	protected void init() {
		super.init();
	}
}
