package com.nucleus.logic.core.modules.battle.data;

import org.apache.commons.lang3.builder.ReflectionToStringBuilder;
import org.apache.commons.lang3.builder.ToStringStyle;

import com.nucleus.commons.annotation.GenIgnored;
import com.nucleus.commons.data.StaticDataManager;
import com.nucleus.commons.message.BroadcastMessage;

/**
 * 暗雷宝宝出现几率
 * 
 * @author liguo
 * 
 */
@GenIgnored
public class MineBattleBaobaoRule implements BroadcastMessage {

	public static float occurRate(int id) {
		float occurRate = 0F;
		MineBattleBaobaoRule baobaoRule = StaticDataManager.getInstance().get(MineBattleBaobaoRule.class, id);
		if (null != baobaoRule) {
			occurRate = baobaoRule.getOccurRate();
		}
		return occurRate;
	}

	@Override
	public String toString() {
		return ReflectionToStringBuilder.toString(this, ToStringStyle.SHORT_PREFIX_STYLE);
	}

	/** 携带等级 */
	private int id;

	/** 出现几率 */
	private float occurRate;

	public int getId() {
		return id;
	}

	public void setId(int id) {
		this.id = id;
	}

	public float getOccurRate() {
		return occurRate;
	}

	public void setOccurRate(float occurRate) {
		this.occurRate = occurRate;
	}

}
