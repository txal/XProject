package com.nucleus.logic.core.modules.battle.data;

import org.apache.commons.lang3.builder.ReflectionToStringBuilder;
import org.apache.commons.lang3.builder.ToStringStyle;

import com.nucleus.commons.data.StaticDataManager;
import com.nucleus.logic.core.modules.battle.dto.PvpTypeEnum;

/**
 * PVP类型
 *
 * @author zhanhua.xu
 */
public class PvpType {
	public static PvpType get(int id) {
		return StaticDataManager.getInstance().get(PvpType.class, id);
	}

	public static PvpType get(PvpTypeEnum type) {
		return get(type.ordinal());
	}

	/** 战斗类型编号 */
	private int id;
	/** 战斗类型名称 */
	private String name;
	/** 胜利增加好友度 */
	private boolean winAddDegree;
	/** 达到指定回合触发系统惩罚 */
	private int punishRound;
	/** 系统惩罚时扣血比例 */
	private String punishRate;

	/** 计算排名积分公式 */
	private String rankScoreFormula;

	public int getId() {
		return id;
	}

	public void setId(int id) {
		this.id = id;
	}

	public String getName() {
		return name;
	}

	public void setName(String name) {
		this.name = name;
	}

	public boolean isWinAddDegree() {
		return winAddDegree;
	}

	public void setWinAddDegree(boolean winAddDegree) {
		this.winAddDegree = winAddDegree;
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

	public String getRankScoreFormula() {
		return rankScoreFormula;
	}

	public void setRankScoreFormula(String rankScoreFormula) {
		this.rankScoreFormula = rankScoreFormula;
	}

	@Override
	public String toString() {
		return ReflectionToStringBuilder.toString(this, ToStringStyle.SHORT_PREFIX_STYLE);
	}
}
