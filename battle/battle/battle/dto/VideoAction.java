/**
 * 
 */
package com.nucleus.logic.core.modules.battle.dto;

import java.util.ArrayList;
import java.util.Collection;
import java.util.Collections;
import java.util.List;

import org.apache.commons.lang3.builder.ReflectionToStringBuilder;
import org.apache.commons.lang3.builder.ToStringStyle;

import com.nucleus.commons.message.BroadcastMessage;
import com.nucleus.logic.core.modules.battle.model.BattleActionStates;

/**
 * @author Omanhom
 * 
 */
public abstract class VideoAction implements BroadcastMessage, BattleActionStates {
	private List<VideoTargetStateGroup> targetStateGroups = new ArrayList<VideoTargetStateGroup>();

	public VideoAction() {
	}

	public VideoAction(VideoTargetState targetState) {
		this.addTargetState(targetState);
	}

	public void addTargetStateGroup(VideoTargetStateGroup g) {
		this.targetStateGroups.add(g);
	}

	public VideoTargetStateGroup currentTargetStateGroup() {
		int idx = this.targetStateGroups.size() - 1;
		if (idx < 0) {
			VideoTargetStateGroup g = new VideoTargetStateGroup();
			this.targetStateGroups.add(g);
			return g;
		}
		return this.targetStateGroups.get(idx);
	}

	@Override
	public void addTargetState(VideoTargetState targetState) {
		if (targetState == null)
			return;
		VideoTargetStateGroup g = currentTargetStateGroup();
		if (g == null)
			return;
		g.getTargetStates().add(targetState);
	}

	@Override
	public void addFirstTargetState(VideoTargetState targetState) {
		if (targetState == null)
			return;
		VideoTargetStateGroup g = currentTargetStateGroup();
		if (g == null)
			return;
		g.getTargetStates().add(0, targetState);
	}

	@Override
	public void addTargetStates(Collection<VideoTargetState> targetState) {
		if (targetState == null || targetState.isEmpty())
			return;
		VideoTargetStateGroup g = currentTargetStateGroup();
		if (g == null)
			return;
		g.getTargetStates().addAll(targetState);
	}

	public List<VideoTargetState> targetStates() {
		VideoTargetStateGroup g = currentTargetStateGroup();
		if (g == null)
			return Collections.emptyList();
		return g.getTargetStates();
	}

	public void targetStates(List<VideoTargetState> targetStates) {
		VideoTargetStateGroup g = currentTargetStateGroup();
		if (g == null)
			return;
		g.setTargetStates(targetStates);
	}

	public List<VideoTargetStateGroup> getTargetStateGroups() {
		return targetStateGroups;
	}

	public void setTargetStateGroups(List<VideoTargetStateGroup> targetStateGroups) {
		this.targetStateGroups = targetStateGroups;
	}

	@Override
	public boolean empty() {
		VideoTargetStateGroup g = currentTargetStateGroup();
		if (g == null)
			return true;
		if (g.getTargetStates() == null)
			return true;
		if (g.getTargetStates().isEmpty())
			return true;
		return false;
	}

	@Override
	public String toString() {
		return ReflectionToStringBuilder.toString(this, ToStringStyle.SHORT_PREFIX_STYLE);
	}
}
