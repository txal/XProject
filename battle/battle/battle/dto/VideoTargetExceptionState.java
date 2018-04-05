package com.nucleus.logic.core.modules.battle.dto;

import java.text.MessageFormat;

import com.nucleus.commons.data.ErrorCode;
import com.nucleus.logic.core.modules.battle.model.BattleSoldier;

/**
 * 异常状态
 * 
 * @author wgy
 *
 */
public class VideoTargetExceptionState extends VideoTargetState {
	private int errorCode;
	private String message;

	public VideoTargetExceptionState() {
	}

	public VideoTargetExceptionState(BattleSoldier target, int errorCode, Object... args) {
		super(target);
		ErrorCode ec = ErrorCode.get(errorCode);
		if (ec == null) {
			this.errorCode = 0;
		} else {
			this.errorCode = ec.getId();
			this.message = ec.getMessage();
		}
		try {
			if (args != null && args.length > 0)
				this.message = MessageFormat.format(message, args);
		} catch (Exception e) {
			e.printStackTrace();
		}
	}

	public int getErrorCode() {
		return errorCode;
	}

	public void setErrorCode(int errorCode) {
		this.errorCode = errorCode;
	}

	public String getMessage() {
		return message;
	}

	public void setMessage(String message) {
		this.message = message;
	}
}
