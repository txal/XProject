/**
 * 
 */
package com.nucleus.logic.core.modules.battle.model;

import java.util.ArrayList;
import java.util.Collections;
import java.util.HashSet;
import java.util.Iterator;
import java.util.List;
import java.util.Map;
import java.util.Set;
import java.util.concurrent.ConcurrentHashMap;

import com.nucleus.commons.exception.GeneralException;
import com.nucleus.logic.core.modules.AppErrorCodes;
import com.nucleus.logic.core.modules.scene.model.Scene;

/**
 * @author Omanhom
 * 
 */
public class DefaultBattleInfo implements BattleInfo {
	/** 观战玩家 */
	private final Set<Long> watchPlayerIds = Collections.newSetFromMap(new ConcurrentHashMap<Long, Boolean>());

	private BattleTeam ateam;
	private BattleTeam bteam;

	private final Map<Long, BattlePlayer> aTeamPlayers = new ConcurrentHashMap<>();
	private final Map<Long, BattlePlayer> bTeamPlayers = new ConcurrentHashMap<>();
	/** 本场战斗通过门派特色复活过的单位 */
	private final Set<Long> factionReliveSoldierIds = new HashSet<>();
	private final Set<Long> roundReadyPlayers = Collections.newSetFromMap(new ConcurrentHashMap<Long, Boolean>());
	@Override
	public boolean hasJoin(long playerId) {
		boolean result = ateam.hasPlayer(playerId);
		if (!result)
			result = bteam.hasPlayer(playerId);
		return result;
	}

	@Override
	public BattleTeam myTeam(long playerId) {
		if (ateam.hasPlayer(playerId)) {
			return ateam;
		} else if (bteam.hasPlayer(playerId)) {
			return bteam;
		} else {
			throw new GeneralException(AppErrorCodes.BATTLE_NOT_JOIN);
		}
	}

	@Override
	public BattleTeam enemyTeam(long playerId) {
		if (!ateam.hasPlayer(playerId) && bteam.hasPlayer(playerId)) {
			return ateam;
		} else if (ateam.hasPlayer(playerId) && !bteam.hasPlayer(playerId)) {
			return bteam;
		} else {
			throw new GeneralException(AppErrorCodes.BATTLE_NOT_JOIN);
		}
	}

	@Override
	public BattleTeam getAteam() {
		return ateam;
	}

	public void setAteam(BattleTeam ateam) {
		this.ateam = ateam;
	}

	@Override
	public BattleTeam getBteam() {
		return bteam;
	}

	public void setBteam(BattleTeam bteam) {
		this.bteam = bteam;
	}

	@Override
	public List<BattleSoldier> curRoundActionQueue() {
		List<BattleSoldier> soldiers = new ArrayList<BattleSoldier>();
		soldiers.addAll(ateam.roundQueue());
		soldiers.addAll(bteam.roundQueue());
		return soldiers;
	}

	@Override
	public boolean isRoundStartable() {
		boolean isATeamReady = ateam.isPlayerSoldiersReady();
		boolean isBTeamReady = bteam.isPlayerSoldiersReady();
		return isATeamReady && isBTeamReady;
	}

	@Override
	public BattleSoldier battleSoldier(long id) {
		BattleSoldier target = null;
		if (ateam != null)
			target = ateam.soldier(id);
		if (target != null)
			return target;
		if (bteam != null)
			target = bteam.soldier(id);
		return target;
	}

	@Override
	public BattleTeam battleTeam(long leaderPlayerId) {
		BattleTeam battleTeam = null;
		if (leaderPlayerId == getAteam().leaderId())
			battleTeam = getAteam();
		else if (leaderPlayerId == getBteam().leaderId())
			battleTeam = getBteam();
		return battleTeam;
	}

	@Override
	public int joinWatch(long playerId, final Set<Long> watchPlayerIds) {
		int battleTeamId = 0;
		if (playerId > 0) {
			battleTeamId = myTeam(playerId).getId();
		}
		if (watchPlayerIds != null && !watchPlayerIds.isEmpty()) {
			this.watchPlayerIds.addAll(watchPlayerIds);
		}
		return battleTeamId;
	}

	@Override
	public void exitWatch(final Set<Long> watchPlayerIds) {
		if (watchPlayerIds != null && !watchPlayerIds.isEmpty()) {
			this.watchPlayerIds.removeAll(watchPlayerIds);
		}
	}

	@Override
	public Map<Long, BattlePlayer> aTeamPlayers() {
		return this.aTeamPlayers;
	}

	@Override
	public Map<Long, BattlePlayer> bTeamPlayers() {
		return this.bTeamPlayers;
	}

	@Override
	public void addPlayerToAteam(BattlePlayer player) {
		if (player == null)
			return;
		this.aTeamPlayers.put(player.getId(), player);
	}

	@Override
	public void addPlayerToBteam(BattlePlayer player) {
		if (player == null)
			return;
		this.bTeamPlayers.put(player.getId(), player);
	}

	public Set<Long> watchList() {
		return this.watchPlayerIds;
	}

	@Override
	public String toString() {
		StringBuilder sb = new StringBuilder();
		Battle battle = this.ateam.battle();
		sb.append(battle.getClass().getSimpleName());
		sb.append("[");
		sb.append("id:").append(battle.getId());
		sb.append(",count:").append(battle.getCount());
		sb.append(",ateam:").append(this.ateam.playerIds());
		sb.append(",bteam:").append(this.bteam.playerIds());
		sb.append("]");
		return sb.toString();
	}

	@Override
	public List<BattleSoldier> preRoundActionQueue() {
		return Collections.emptyList();
	}

	@Override
	public Scene currentScene() {
		if (ateam.leader() != null) {
			return ateam.leader().currentScene();
		}
		return null;
	}

	@Override
	public Set<Long> factionReliveSoldierIds() {
		return this.factionReliveSoldierIds;
	}

	@Override
	public boolean allReady() {
		if (!ateam.playerIds().isEmpty() && !roundReadyPlayers.containsAll(ateam.playerIds()))
			return false;
		if (!bteam.isNpcTeam() && !bteam.playerIds().isEmpty() && !roundReadyPlayers.containsAll(bteam.playerIds()))
			return false;
		return true;
	}
	
	public Set<Long> roundReadyPlayers() {
		return this.roundReadyPlayers;
	}

	@Override
	public void clearRoundReadyPlayer() {
		// 如果玩家已经离线,则不移除该id,每回合默认就绪,避免其他玩家等太久,其他在线玩家则每回合清除,当前回合播放完再放回就绪列表
		for (Iterator<Long> it = roundReadyPlayers.iterator(); it.hasNext();) {
			BattlePlayer bp = battlePlayer(it.next());
			if (bp == null || bp.isConnected())
				it.remove();
		}
	}

	@Override
	public void addRoundReadyPlayer(long playerId) {
		this.roundReadyPlayers.add(playerId);
	}
	
	public BattlePlayer battlePlayer(long playerId) {
		return this.aTeamPlayers.getOrDefault(playerId, this.bTeamPlayers.get(playerId));
	}
}
