package com.nucleus.logic.core.modules.battle.data;

import java.util.Set;

import javax.persistence.Transient;

import org.apache.commons.lang3.builder.ReflectionToStringBuilder;
import org.apache.commons.lang3.builder.ToStringStyle;

import com.nucleus.commons.data.StaticDataManager;
import com.nucleus.commons.message.BroadcastMessage;
import com.nucleus.commons.utils.SplitUtils;

/**
 * 可认证技能
 * 
 * @author wgy
 *
 */
public class CertificateSkillConfig implements BroadcastMessage {
	private int id;
	private Set<Integer> skillIds;

	public static CertificateSkillConfig get(int id) {
		return StaticDataManager.getInstance().get(CertificateSkillConfig.class, id);
	}

	public static CertificateSkillConfig get() {
		return get(1);
	}

	public int getId() {
		return id;
	}

	public void setId(int id) {
		this.id = id;
	}

	public Set<Integer> getSkillIds() {
		return skillIds;
	}

	public void setSkillIds(Set<Integer> skillIds) {
		this.skillIds = skillIds;
	}

	@Transient
	public void setSkillIdStr(String skillIdStr) {
		this.skillIds = SplitUtils.split2IntSet(skillIdStr, ",");
	}

	@Override
	public String toString() {
		return ReflectionToStringBuilder.toString(this, ToStringStyle.SHORT_PREFIX_STYLE);
	}
}
