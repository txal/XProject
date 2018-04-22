package com.nucleus.logic.core.modules.battle.dto;

import com.nucleus.commons.message.BroadcastMessage;

/**
 * 指令通知
 * 
 * @author wgy
 *
 */
public class CommandNotify implements BroadcastMessage {
	/** 指令目标 */
	private long targetSoldierId;
	private String command;
	/** 是否清理全部指令 */
	private boolean clearAll;

	public CommandNotify() {
	}

	public CommandNotify(long targetSoldierId, String command, boolean clearAll) {
		this.targetSoldierId = targetSoldierId;
		this.command = command;
		this.clearAll = clearAll;
	}

	public long getTargetSoldierId() {
		return targetSoldierId;
	}

	public void setTargetSoldierId(long targetSoldierId) {
		this.targetSoldierId = targetSoldierId;
	}

	public String getCommand() {
		return command;
	}

	public void setCommand(String command) {
		this.command = command;
	}

	public boolean isClearAll() {
		return clearAll;
	}

	public void setClearAll(boolean clearAll) {
		this.clearAll = clearAll;
	}
}
