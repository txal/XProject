/**
 * 
 */
package com.nucleus.logic.core.modules.battlebuff;

import org.springframework.stereotype.Service;

import com.nucleus.logic.core.modules.battle.model.CommandContext;
import com.nucleus.logic.core.modules.battlebuff.model.BattleBuffEntity;

/**
 * 影响属性:服务端用来影响属性结算,结算完毕移除buff，客户端不需要表现
 * 比如：'攻击时忽视对方3%物理防御',攻击前给目标加一buff,该buff减目标防御3%,攻击完毕移除
 * 
 * @author wgy
 *
 */
@Service
public class BattleBuffLogic_15 extends BattleBuffLogicAdapter {
	
	@Override
	public void onActionEnd(CommandContext commandContext, BattleBuffEntity buffEntity) {
		buffEntity.getEffectSoldier().buffHolder().removeBuffById(buffEntity.battleBuffId());
	}
}
