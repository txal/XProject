package com.nucleus.logic.core.modules.battle.logic;

import java.util.ArrayList;
import java.util.List;

import org.apache.commons.lang3.builder.ReflectionToStringBuilder;
import org.apache.commons.lang3.builder.ToStringStyle;

public class SkillTargetInfoList {

	private List<SkillTargetInfo> skillTargetInfoList = new ArrayList<>();

	public List<SkillTargetInfo> getSkillTargetInfoList() {
		return skillTargetInfoList;
	}

	public void setSkillTargetInfoList(List<SkillTargetInfo> skillTargetInfoList) {
		this.skillTargetInfoList = skillTargetInfoList;
	}

	public void addSkillTargetInfo(SkillTargetInfo skillTargetInfo) {
		this.skillTargetInfoList.add(skillTargetInfo);
	}

	@Override
	public String toString() {
		return ReflectionToStringBuilder.toString(this, ToStringStyle.SHORT_PREFIX_STYLE);
	}

}
