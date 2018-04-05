package com.nucleus.logic.core.modules.battle.data;

import com.nucleus.commons.annotation.GenIgnored;
import com.nucleus.commons.data.DataBasic;
import com.nucleus.commons.data.StaticDataManager;
import com.nucleus.commons.message.BroadcastMessage;
import com.nucleus.logic.core.modules.battle.ai.SkillAIUtils;
import com.nucleus.logic.core.modules.battle.ai.rules.SkillAICondition;
import com.nucleus.logic.core.modules.battle.ai.rules.SkillAITarget;
import com.nucleus.logic.core.modules.battle.model.BattleSoldier;
import com.nucleus.logic.core.modules.battle.model.CommandContext;

import org.apache.commons.lang3.StringUtils;
import org.apache.commons.lang3.builder.ReflectionToStringBuilder;
import org.apache.commons.lang3.builder.ToStringStyle;

/**
 * 技能使用AI数据配置
 * <p>
 * Created by Tony on 15/6/19.
 */
@GenIgnored
public class SkillAIConfig implements BroadcastMessage, DataBasic {

	/** 分类：其它 */
	public static final int CATEGORY_OTHER = 0;

	/** 分类：伤害技能 */
	public static final int CATEGORY_DAMAGE = 1;

	/** 分类：回复 */
	public static final int CATEGORY_HEAL = 2;

	/**
	 * 技能ID，对应技能表 *
	 */
	private int id;

	/**
	 * 分类 *
	 */
	private int category;

	/**
	 * 使用条件规则 *
	 */
	private String aiConditionStr;

	/**
	 * 目标选择规则 *
	 */
	private String targetRuleStr;

	private transient SkillAICondition aiCondition;

	private transient SkillAITarget aiTarget;

	@Override
	public void afterPropertySet() {
		if (StringUtils.isNotBlank(this.aiConditionStr)) {
			this.aiCondition = SkillAIUtils.createSkillAICondition(this.id, this.aiConditionStr);
		}
		if (StringUtils.isNotBlank(this.targetRuleStr)) {
			this.aiTarget = SkillAIUtils.createSkillAITarget(this.id, this.targetRuleStr);
		}
	}

	public static SkillAIConfig get(int skillId) {
		return StaticDataManager.getInstance().get(SkillAIConfig.class, skillId);
	}

	public boolean isAvailable(final BattleSoldier trigger, final Skill skill, final CommandContext ctx) {
		if (aiCondition != null) {
			return aiCondition.isAvailable(trigger, skill, ctx);
		}
		return true;
	}

	public BattleSoldier selectTarget(final BattleSoldier trigger, final Skill skill, final CommandContext ctx) {
		if (aiTarget != null) {
			return aiTarget.select(trigger, skill, ctx);
		}
		return null;
	}

	public int getId() {
		return id;
	}

	public void setId(int id) {
		this.id = id;
	}

	public int getCategory() {
		return category;
	}

	public void setCategory(int category) {
		this.category = category;
	}

	public String getAiConditionStr() {
		return aiConditionStr;
	}

	public void setAiConditionStr(String aiConditionStr) {
		this.aiConditionStr = aiConditionStr;
	}

	public String getTargetRuleStr() {
		return targetRuleStr;
	}

	public void setTargetRuleStr(String targetRuleStr) {
		this.targetRuleStr = targetRuleStr;
	}

	@Override
	public String toString() {
		return ReflectionToStringBuilder.toString(this, ToStringStyle.SHORT_PREFIX_STYLE);
	}
}
