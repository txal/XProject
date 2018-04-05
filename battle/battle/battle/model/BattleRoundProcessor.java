/**
 * 
 */
package com.nucleus.logic.core.modules.battle.model;

import java.util.Set;

/**
 * 回合处理器
 * 
 * @author Omanhom
 * 
 */
public interface BattleRoundProcessor {
	/**
	 * 回合处理实现
	 */
	public void handle();

	/**
	 * 回合清理
	 */
	public void clear();

	/**
	 * 撤退的玩家编号
	 * 
	 * @return
	 */
	public Set<Long> retreatPlayerId();

	public void debugInfo(CommandContext commandContext, int code);

	public void degugInfo(String info);

	public boolean debugEnable();

	public RoundContext context();
}
