package com.nucleus.logic.core.modules.battle.dto;

import com.nucleus.logic.core.modules.battle.model.BattleSoldier;
import com.nucleus.logic.core.modules.charactor.data.ShoutConfig;

/**
 * 目标喊话
 * 
 * @author Tony
 *
 */
public class VideoTargetShoutState extends VideoTargetState {

	/** 战斗喊话类型:ShoutConfig.BattleShoutTypeEnum_* */
	private int shoutType;

	/** 具体喊话内容 */
	private String message;

	public VideoTargetShoutState() {
	}

	public VideoTargetShoutState(BattleSoldier target, ShoutConfig.BattleShoutTypeEnum typeEnum, String message) {
		super(target);
		this.shoutType = typeEnum.ordinal();
		this.message = message;
	}

	public VideoTargetShoutState(BattleSoldier target, int typeEnumId, String message) {
		super(target);
		this.shoutType = typeEnumId;
		this.message = message;
	}

	public String getMessage() {
		return message;
	}

	public void setMessage(String message) {
		this.message = message;
	}

	public int getShoutType() {
		return shoutType;
	}

	public void setShoutType(int shoutType) {
		this.shoutType = shoutType;
	}
}
