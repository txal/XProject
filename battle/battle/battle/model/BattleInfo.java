/**
 * 
 */
package com.nucleus.logic.core.modules.battle.model;

import java.util.List;
import java.util.Map;
import java.util.Set;

import com.nucleus.logic.core.modules.scene.model.Scene;

/**
 * 战斗信息
 * 
 * @author Omanhom
 * 
 */
public interface BattleInfo {

	/** 回合行动顺序队列，这里会发生补位操作 */
	public List<BattleSoldier> curRoundActionQueue();

	/** 回合是否可开始 */
	public boolean isRoundStartable();

	public BattleSoldier battleSoldier(long id);

	public BattleTeam getAteam();

	public BattleTeam getBteam();

	public void setAteam(BattleTeam team);

	public void setBteam(BattleTeam team);

	public boolean hasJoin(long playerId);

	/** 获取我方队伍 */
	public BattleTeam myTeam(long playerId);

	/** 获取敌方队伍 */
	public BattleTeam enemyTeam(long playerId);

	/** 获取队伍 */
	public BattleTeam battleTeam(long leaderPlayerId);

	/** 加入观看列表 */
	public int joinWatch(long playerId, Set<Long> watchPlayerIds);

	/** 退出观看列表 */
	public void exitWatch(final Set<Long> watchPlayerIds);

	/** 观看列表 */
	public Set<Long> watchList();

	public Map<Long, BattlePlayer> aTeamPlayers();

	public Map<Long, BattlePlayer> bTeamPlayers();

	public void addPlayerToAteam(BattlePlayer player);

	public void addPlayerToBteam(BattlePlayer player);

	/** 回合前置行动队列 */
	public List<BattleSoldier> preRoundActionQueue();

	/** 战斗所处的当前场景 */
	public Scene currentScene();

	public Set<Long> factionReliveSoldierIds();

	public boolean allReady();
	
	public Set<Long> roundReadyPlayers();

	public void clearRoundReadyPlayer();

	public void addRoundReadyPlayer(long playerId);
}
