package com.nucleus.logic.core.modules.battle.dto;

import com.nucleus.commons.annotation.IncludeEnum;
import com.nucleus.commons.annotation.IncludeEnums;
import com.nucleus.logic.core.modules.battle.data.PvpType;

/**
 * 
 * @author Omanhom
 *
 */
@IncludeEnums({ @IncludeEnum(PvpTypeEnum.class) })
public class PvpVideo extends Video {
	private int type;
	/** 达到指定回合触发系统惩罚 */
	private int punishRound;
	/** 惩罚扣血比例 */
	private String punishRate;

	public PvpVideo() {

	}

	public PvpVideo(int maxRound) {
		super(maxRound);
	}

	public PvpVideo(int maxRound, int type) {
		this(maxRound);
		this.type = type;
		PvpType pType = PvpType.get(type);
		if (pType != null) {
			this.punishRound = pType.getPunishRound();
			this.punishRate = pType.getPunishRate();
		}

	}

	public int getType() {
		return type;
	}

	public void setType(int type) {
		this.type = type;
	}

	public int getPunishRound() {
		return punishRound;
	}

	public void setPunishRound(int punishRound) {
		this.punishRound = punishRound;
	}

	public String getPunishRate() {
		return punishRate;
	}

	public void setPunishRate(String punishRate) {
		this.punishRate = punishRate;
	}

}
