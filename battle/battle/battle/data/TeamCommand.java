package com.nucleus.logic.core.modules.battle.data;

import org.apache.commons.lang3.builder.ReflectionToStringBuilder;
import org.apache.commons.lang3.builder.ToStringStyle;

import com.nucleus.commons.data.StaticDataManager;
import com.nucleus.commons.message.BroadcastMessage;

/**
 * 组队指令
 * 
 * @author wgy
 *
 */
public class TeamCommand implements BroadcastMessage {
	private int id;
	private String[] command;

	public static TeamCommand get(int id) {
		return StaticDataManager.getInstance().get(TeamCommand.class, id);
	}

	public int getId() {
		return id;
	}

	public void setId(int id) {
		this.id = id;
	}

	public String[] getCommand() {
		return command;
	}

	public void setCommand(String[] command) {
		this.command = command;
	}

	@Override
	public String toString() {
		return ReflectionToStringBuilder.toString(this, ToStringStyle.SHORT_PREFIX_STYLE);
	}
}
