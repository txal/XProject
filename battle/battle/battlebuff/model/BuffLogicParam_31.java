package com.nucleus.logic.core.modules.battlebuff.model;

import java.util.Set;

import com.nucleus.commons.annotation.GenIgnored;

/**
 * 
 * @author hwy
 *
 */
@GenIgnored
public class BuffLogicParam_31 extends BuffLogicParam {

	private Set<Integer> skillIds;

	private String rateFormula;

	public Set<Integer> getSkillIds() {
		return skillIds;
	}

	public void setSkillIds(Set<Integer> skillIds) {
		this.skillIds = skillIds;
	}

	public String getRateFormula() {
		return rateFormula;
	}

	public void setRateFormula(String rateFormula) {
		this.rateFormula = rateFormula;
	}

}
