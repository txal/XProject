package com.nucleus.logic.core.modules.battle.data;

import org.apache.commons.lang3.builder.ReflectionToStringBuilder;
import org.apache.commons.lang3.builder.ToStringStyle;

import com.nucleus.commons.annotation.GenIgnored;
import com.nucleus.commons.data.StaticDataManager;
import com.nucleus.commons.message.BroadcastMessage;

/**
 * 群攻伤害规则
 * 
 * @author liguo
 * 
 */
@GenIgnored
public class SkillMassDamageRule implements BroadcastMessage {

	public static SkillMassDamageRule get(int id) {
		return StaticDataManager.getInstance().get(SkillMassDamageRule.class, id);
	}

	/** 目标数 */
	private int id;

	/** 伤害比例 */
	private float damageRate;

	public int getId() {
		return id;
	}

	public void setId(int id) {
		this.id = id;
	}

	public float getDamageRate() {
		return damageRate;
	}

	public void setDamageRate(float damageRate) {
		this.damageRate = damageRate;
	}

	@Override
	public String toString() {
		return ReflectionToStringBuilder.toString(this, ToStringStyle.SHORT_PREFIX_STYLE);
	}

}
