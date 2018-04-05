/**
 * 
 */
package com.nucleus.logic.core.modules.battle.dto;

import java.util.ArrayList;
import java.util.List;

import javax.persistence.Transient;

import com.nucleus.commons.data.DataId;

import org.apache.commons.lang3.builder.ReflectionToStringBuilder;
import org.apache.commons.lang3.builder.ToStringStyle;

import com.nucleus.commons.message.BroadcastMessage;
import com.nucleus.logic.core.modules.battle.model.BattleSoldier;
import com.nucleus.logic.core.modules.battle.model.BattleTeam;
import com.nucleus.logic.core.modules.formation.data.Formation;

/**
 * @author Omanhom
 */
public class VideoTeam implements BroadcastMessage {

	/** 队伍唯一编号，每场战斗不同 */
	private int id;

	private List<Long> playerIds = new ArrayList<Long>();
	/** 队伍 */
	private List<VideoSoldier> teamSoldiers = new ArrayList<VideoSoldier>();
	/** 原始玩家id */
	private List<Long> originalPlayerIds = new ArrayList<>();
	/** 原始出战单位 */
	private List<VideoSoldier> originalSoldiers = new ArrayList<>();
	/** 队伍阵型 **/
	@DataId(Formation.class)
	private int formationId;

	public VideoTeam() {
	}

	public VideoTeam(BattleTeam battleTeam) {
		this.id = battleTeam.getId();

		for (long playerId : battleTeam.playerIds()) {
			getPlayerIds().add(playerId);
		}

		for (BattleSoldier soldier : battleTeam.soldiersMap().values()) {
			teamSoldiers.add(new VideoSoldier(soldier));
		}
		this.formationId = battleTeam.getFormationId();
		this.originalPlayerIds.addAll(this.playerIds);
		this.originalSoldiers.addAll(this.teamSoldiers);
	}

	public boolean hasPlayer(long playerId) {
		return this.getPlayerIds().contains(playerId);
	}

	public long leaderPlayerId() {
		return this.getPlayerIds().iterator().next();
	}

	public List<VideoSoldier> getTeamSoldiers() {
		return teamSoldiers;
	}

	public void setTeamSoldiers(List<VideoSoldier> teamSoldiers) {
		this.teamSoldiers = teamSoldiers;
	}

	@Override
	public String toString() {
		return ReflectionToStringBuilder.toString(this, ToStringStyle.SHORT_PREFIX_STYLE);
	}

	public List<Long> getPlayerIds() {
		return playerIds;
	}

	public void setPlayerIds(List<Long> playerIds) {
		this.playerIds = playerIds;
	}

	public int getFormationId() {
		return formationId;
	}

	public void setFormationId(int formationId) {
		this.formationId = formationId;
	}

	public int getId() {
		return id;
	}

	public void setId(int id) {
		this.id = id;
	}

	public List<VideoSoldier> getOriginalSoldiers() {
		return originalSoldiers;
	}

	@Transient
	public void setOriginalSoldiers(List<VideoSoldier> originalSoldiers) {
		this.originalSoldiers = originalSoldiers;
	}

	public List<Long> getOriginalPlayerIds() {
		return originalPlayerIds;
	}

	@Transient
	public void setOriginalPlayerIds(List<Long> originalPlayerIds) {
		this.originalPlayerIds = originalPlayerIds;
	}

	public void restore() {
		this.playerIds = this.originalPlayerIds;
		this.teamSoldiers = this.originalSoldiers;
	}
}
