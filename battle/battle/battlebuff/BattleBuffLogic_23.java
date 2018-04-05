/**
 * 
 */
package com.nucleus.logic.core.modules.battlebuff;

import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;

import com.nucleus.commons.utils.RandomUtils;
import com.nucleus.logic.core.modules.battlebuff.model.BattleBuffEntity;
import com.nucleus.logic.core.modules.battlebuff.model.BuffLogicParam;
import com.nucleus.logic.core.modules.battlebuff.model.BuffLogicParam_5;

/**
 * 有机率防御
 * 
 * @author wgy
 *
 */
@Service
public class BattleBuffLogic_23 extends BattleBuffLogicAdapter {
	@Autowired
	private BattleBuffLogic_22 proxy;

	@Override
	protected BuffLogicParam newParam() {
		return new BuffLogicParam_5();
	}

	@Override
	public void onRoundStart(BattleBuffEntity buffEntity) {
		BuffLogicParam_5 param = (BuffLogicParam_5) buffEntity.battleBuff().getBuffParam();
		boolean success = RandomUtils.baseRandomHit(param.getRate());
		if (success)
			proxy.onRoundStart(buffEntity);
	}
}
