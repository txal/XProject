package com.nucleus.logic.core.modules.battle.data;

import java.util.Collections;
import java.util.Set;

import javax.persistence.Transient;

import org.apache.commons.lang3.builder.ReflectionToStringBuilder;
import org.apache.commons.lang3.builder.ToStringStyle;

import com.nucleus.commons.utils.SplitUtils;

/**
 * npc主动技能
 * 
 * @author wgy
 *
 */
public class NpcActiveSkill extends NpcSkill {
	private Set<Integer> callMonsterIds;

	public Set<Integer> callMonsterIds() {
		if (this.callMonsterIds == null)
			return Collections.emptySet();
		return this.callMonsterIds;
	}

	@Transient
	public void setCallMonsterIdStr(String callMonsterIdStr) {
		this.callMonsterIds = SplitUtils.split2IntSet(callMonsterIdStr, ",");
	}

	@Override
	public String toString() {
		return ReflectionToStringBuilder.toString(this, ToStringStyle.SHORT_PREFIX_STYLE);
	}
}
