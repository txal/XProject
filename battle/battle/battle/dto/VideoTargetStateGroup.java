package com.nucleus.logic.core.modules.battle.dto;

import java.util.ArrayList;
import java.util.List;

import org.apache.commons.lang3.builder.ReflectionToStringBuilder;
import org.apache.commons.lang3.builder.ToStringStyle;

import com.nucleus.commons.message.BroadcastMessage;

public class VideoTargetStateGroup implements BroadcastMessage {
	private List<VideoTargetState> targetStates = new ArrayList<VideoTargetState>();
	/** 反击 */
	private VideoSkillAction strikeBackAction;
	/** 保护动作 */
	private VideoInsideSkillAction protectAction;
	/** 保护者编号 */
	private long protectSoldierId;

	public List<VideoTargetState> getTargetStates() {
		return targetStates;
	}

	public void setTargetStates(List<VideoTargetState> targetStates) {
		this.targetStates = targetStates;
	}

	public VideoSkillAction getStrikeBackAction() {
		return strikeBackAction;
	}

	public void setStrikeBackAction(VideoSkillAction strikeBackAction) {
		this.strikeBackAction = strikeBackAction;
	}

	public VideoInsideSkillAction getProtectAction() {
		return protectAction;
	}

	public void setProtectAction(VideoInsideSkillAction protectAction) {
		this.protectAction = protectAction;
	}

	public long getProtectSoldierId() {
		return protectSoldierId;
	}

	public void setProtectSoldierId(long protectSoldierId) {
		this.protectSoldierId = protectSoldierId;
	}

	@Override
	public String toString() {
		return ReflectionToStringBuilder.toString(this, ToStringStyle.SHORT_PREFIX_STYLE);
	}
}
