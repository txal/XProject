package com.nucleus.logic.core.modules.battle.data;

import java.beans.Transient;
import java.util.ArrayList;
import java.util.Collections;
import java.util.List;
import java.util.Map;
import java.util.Map.Entry;

import org.apache.commons.lang3.StringUtils;
import org.apache.commons.lang3.builder.ReflectionToStringBuilder;
import org.apache.commons.lang3.builder.ToStringStyle;

import com.nucleus.commons.data.StaticDataManager;
import com.nucleus.commons.message.BroadcastMessage;
import com.nucleus.commons.utils.SplitUtils;
import com.nucleus.logic.core.modules.battle.logic.AbstractPassiveSkillLaunchCondition;
import com.nucleus.logic.core.modules.battle.logic.AbstractPassiveSkillLaunchConditionLogic;
import com.nucleus.logic.core.modules.battle.logic.IPassiveSkillLogic;
import com.nucleus.logic.core.modules.battle.manager.PassiveSkillLaunchConditionLogicManager;
import com.nucleus.logic.core.modules.battle.manager.PassiveSkillLogicManager;

/**
 * 被动技能配置
 * 
 * @author wgy
 *
 */
public class PassiveSkillConfig implements BroadcastMessage {
	private int id;
	/**
	 * 技能逻辑id
	 */
	private int logicId;
	/**
	 * 技能发动条件
	 */
	private List<AbstractPassiveSkillLaunchCondition> launchConditions;
	/**
	 * 触发时机
	 */
	private int launchTiming;
	/**
	 * 影响属性
	 */
	private int[] propertys;
	/**
	 * 影响属性效果公式
	 */
	private String[] propertyEffectFormulas;
	/**
	 * 扩展参数
	 */
	private String[] extraParams;
	/**
	 * 消耗mp公式
	 */
	private String spendMpFormula;
	/**
	 * 自身附加buff
	 */
	private int selfBuff;
	/**
	 * 目标附加buff
	 */
	private int targetBuff;
	/**
	 * 描述
	 */
	private String description;
	/** 比如有些加buff的被动技能计算buff回合等需要用到技能等级的地方，可以指定技能来计算等级*/
	private int relativeSkillId;
	public static PassiveSkillConfig get(int id) {
		return StaticDataManager.getInstance().get(PassiveSkillConfig.class, id);
	}

	public IPassiveSkillLogic logic() {
		return PassiveSkillLogicManager.getInstance().getLogic(this.logicId);
	}

	public int getId() {
		return id;
	}

	public void setId(int id) {
		this.id = id;
	}

	public int getLogicId() {
		return logicId;
	}

	public void setLogicId(int logicId) {
		this.logicId = logicId;
	}

	@Transient
	public void setLaunchConditionStr(String launchConditionStr) {
		if (StringUtils.isBlank(launchConditionStr)) {
			this.launchConditions = Collections.emptyList();
			return;
		}
		// id=1,value=xx;id=2,value=xx;...
		String[] conditionStrArr = SplitUtils.split2StringArray(launchConditionStr, ";");
		this.launchConditions = new ArrayList<AbstractPassiveSkillLaunchCondition>();
		for (String conditionStr : conditionStrArr) {
			Map<String, String> properties = SplitUtils.split2StringMap(conditionStr, ",", "=");
			specialCharReplace(properties);
			Integer id = Integer.parseInt(properties.get("id"));
			AbstractPassiveSkillLaunchConditionLogic logic = conditionLogic(id);
			if (logic == null)
				return;
			this.launchConditions.add(logic.getInstance(properties));
		}
	}

	private void specialCharReplace(Map<String, String> properties) {
		for (Entry<String, String> entry : properties.entrySet()) {
			String value = entry.getValue().replace("#", ",");
			entry.setValue(value);
		}
	}

	public List<AbstractPassiveSkillLaunchCondition> launchConditions() {
		return this.launchConditions;
	}

	private AbstractPassiveSkillLaunchConditionLogic conditionLogic(int id) {
		final PassiveSkillLaunchConditionLogicManager logicManager = PassiveSkillLaunchConditionLogicManager.getInstance();
		if (logicManager == null) {
			return null;
		}
		return logicManager.getLogic(id);
	}

	public int getLaunchTiming() {
		return launchTiming;
	}

	public void setLaunchTiming(int launchTiming) {
		this.launchTiming = launchTiming;
	}

	public int[] getPropertys() {
		return propertys;
	}

	public void setPropertys(int[] propertys) {
		this.propertys = propertys;
	}

	public String[] getPropertyEffectFormulas() {
		return propertyEffectFormulas;
	}

	public void setPropertyEffectFormulas(String[] propertyEffectFormulas) {
		this.propertyEffectFormulas = propertyEffectFormulas;
	}

	public String[] getExtraParams() {
		return extraParams;
	}

	public void setExtraParams(String[] extraParams) {
		this.extraParams = extraParams;
	}

	public String getSpendMpFormula() {
		return spendMpFormula;
	}

	public void setSpendMpFormula(String spendMpFormula) {
		this.spendMpFormula = spendMpFormula;
	}

	public int getSelfBuff() {
		return selfBuff;
	}

	public void setSelfBuff(int selfBuff) {
		this.selfBuff = selfBuff;
	}

	public String getDescription() {
		return description;
	}

	public void setDescription(String description) {
		this.description = description;
	}

	public int getTargetBuff() {
		return targetBuff;
	}

	public void setTargetBuff(int targetBuff) {
		this.targetBuff = targetBuff;
	}

	public int getRelativeSkillId() {
		return relativeSkillId;
	}

	public void setRelativeSkillId(int relativeSkillId) {
		this.relativeSkillId = relativeSkillId;
	}

	@Override
	public String toString() {
		return ReflectionToStringBuilder.toString(this, ToStringStyle.SHORT_PREFIX_STYLE);
	}
}
