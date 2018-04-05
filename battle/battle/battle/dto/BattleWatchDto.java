package com.nucleus.logic.core.modules.battle.dto;

import com.nucleus.commons.message.BroadcastMessage;
import com.nucleus.commons.message.GeneralResponse;

/**
 * 观战信息DTO
 *
 * Created by Tony on 15/6/23.
 */
public class BattleWatchDto extends GeneralResponse implements BroadcastMessage {

	/**
	 * 被观看的战斗队伍ID，对应VideoTeam.id
	 */
	private int watchTeamId;

	/**
	 * 战斗
	 */
	private Video video;

	public BattleWatchDto() {
	}

	public BattleWatchDto(int watchTeamId, Video video) {
		this.watchTeamId = watchTeamId;
		this.video = video;
	}

	public int getWatchTeamId() {
		return watchTeamId;
	}

	public void setWatchTeamId(int watchTeamId) {
		this.watchTeamId = watchTeamId;
	}

	public Video getVideo() {
		return video;
	}

	public void setVideo(Video video) {
		this.video = video;
	}
}
