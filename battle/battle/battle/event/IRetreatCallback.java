package com.nucleus.logic.core.modules.battle.event;

import com.nucleus.logic.core.modules.battle.model.BattlePlayer;
import com.nucleus.logic.core.modules.battle.model.BattleTeam;

/**
 * 撤退回调
 * 
 * @author wgy
 *
 */
@FunctionalInterface
public interface IRetreatCallback {
	public abstract void onRetreat(BattleTeam team, BattlePlayer player);
}
