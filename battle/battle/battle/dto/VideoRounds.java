/**
 * 
 */
package com.nucleus.logic.core.modules.battle.dto;

import java.util.ArrayList;
import java.util.List;

import org.apache.commons.lang3.builder.ReflectionToStringBuilder;
import org.apache.commons.lang3.builder.ToStringStyle;

import com.nucleus.commons.message.GeneralResponse;
import com.nucleus.logic.core.modules.battle.model.Battle;

/**
 * @author Omanhom
 * 
 */
public class VideoRounds extends GeneralResponse {
	public VideoRounds() {
	}

	private List<VideoRound> videoRounds = new ArrayList<VideoRound>();

	/** 初始化当前回合记录器 */
	public void initCurrentVideoRound(Battle battle) {
		VideoRound curVideoRound = new VideoRound(battle);
		videoRounds.add(curVideoRound);
	}

	/** 获得当前回合记录器 */
	public VideoRound currentVideoRound() {
		int index = videoRounds.size() - 1;
		if (index < 0)
			return null;
		return videoRounds.get(index);
	}

	public VideoRound videoRound(int round) {
		round = round - 1;
		if (round < 0)
			return null;
		return videoRounds.get(round);
	}

	/** 元素为VideoRound */
	public List<VideoRound> getVideoRounds() {
		return videoRounds;
	}

	public void setVideoRounds(List<VideoRound> videoRounds) {
		this.videoRounds = videoRounds;
	}

	public boolean empty() {
		return this.videoRounds.isEmpty();
	}

	@Override
	public String toString() {
		return ReflectionToStringBuilder.toString(this, ToStringStyle.SHORT_PREFIX_STYLE);
	}
}
