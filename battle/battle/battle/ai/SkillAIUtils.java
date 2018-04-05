package com.nucleus.logic.core.modules.battle.ai;

import org.apache.commons.lang3.math.NumberUtils;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

import com.nucleus.logic.core.modules.battle.ai.rules.DefaultSkillAICondition;
import com.nucleus.logic.core.modules.battle.ai.rules.DefaultSkillAITarget;
import com.nucleus.logic.core.modules.battle.ai.rules.SkillAICondition;
import com.nucleus.logic.core.modules.battle.ai.rules.SkillAITarget;

/**
 * Created by baoyu on 15/6/19.
 */
public class SkillAIUtils {

	private final static Logger logger = LoggerFactory.getLogger(SkillAIUtils.class);

	private final static DefaultSkillAICondition defaultSkillLimitRule = new DefaultSkillAICondition();

	private final static DefaultSkillAITarget defaultSkillAITarget = new DefaultSkillAITarget();

	public static SkillAICondition createSkillAICondition(int skillId, String ruleStr) {
		String[] strRuleInfo = ruleStr.split(":", 2);
		final int type = (int) NumberUtils.toDouble(strRuleInfo[0]);
		SkillAICondition rule = null;
		if (type > 0) {
			final String params = strRuleInfo.length > 1 ? strRuleInfo[1] : "";
			final String packageName = DefaultSkillAICondition.class.getPackage().getName();
			try {
				Class<SkillAICondition> cls = (Class<SkillAICondition>) Class.forName(packageName + ".SkillAICondition_" + type);
				rule = cls.getConstructor(String.class).newInstance(params);
			} catch (Exception e) {
				logger.error("create skill limit rule error: " + ruleStr, e);
			}
		}
		if (rule == null) {
			rule = defaultSkillLimitRule;
		}
		return rule;
	}

	public static SkillAITarget createSkillAITarget(int skillId, String ruleStr) {
		String[] strRuleInfo = ruleStr.split(":", 2);
		final int type = (int) NumberUtils.toDouble(strRuleInfo[0]);
		SkillAITarget rule = null;
		if (type > 0) {
			final String params = strRuleInfo.length > 1 ? strRuleInfo[1] : "";
			final String packageName = DefaultSkillAICondition.class.getPackage().getName();
			try {
				Class<SkillAITarget> cls = (Class<SkillAITarget>) Class.forName(packageName + ".SkillAITarget_" + type);
				rule = cls.getConstructor(String.class).newInstance(params);
				rule.setSkillId(skillId);
			} catch (Exception e) {
				logger.error("create skill limit rule error: " + skillId + ", " + ruleStr, e);
			}
		}
		if (rule == null) {
			rule = defaultSkillAITarget;
		}
		return rule;
	}

	public static void main(String[] args) {
		final SkillAICondition rule = createSkillAICondition(1, "1:hp>10");
		System.out.println(rule);
	}

}
