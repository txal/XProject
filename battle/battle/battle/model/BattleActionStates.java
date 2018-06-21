/**
 * 
 */
package com.nucleus.logic.core.modules.battle.model;

import java.util.Collection;

import com.nucleus.logic.core.modules.battle.dto.VideoTargetState;

/**
 * @author Omanhom
 * 
 */
public interface BattleActionStates {
	public void addTargetState(VideoTargetState targetState);

	public void addFirstTargetState(VideoTargetState targetState);

	public void addTargetStates(Collection<VideoTargetState> targetState);

	// public List<VideoTargetState> getTargetStates();
	//
	// public void setTargetStates(List<VideoTargetState> targetStates);

	public boolean empty();
}
