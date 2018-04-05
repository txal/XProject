package com.nucleus.logic.core.modules.battle.ai.rules;

import org.apache.commons.lang3.math.NumberUtils;

import com.nucleus.logic.core.modules.battle.data.Skill;
import com.nucleus.logic.core.modules.battle.model.BattleSoldier;
import com.nucleus.logic.core.modules.battle.model.CommandContext;
import com.nucleus.logic.core.modules.battlebuff.data.BattleBuff;

import java.util.regex.Matcher;
import java.util.regex.Pattern;

/**
 * 气血，魔法，怒气限制判断 参数：hp>0.5或mp<=1.0或sp=0，数字与对比符可变
 * <p>
 * Created by Tony on 15/6/19.
 */
public class SkillAICondition_1 extends DefaultSkillAICondition {

	/**
	 * 等于 *
	 */
	private static final int CMP_TYPE_EQ = 0;

	/**
	 * 大于 *
	 */
	private static final int CMP_TYPE_GT = 1;

	/**
	 * 小于 *
	 */
	private static final int CMP_TYPE_LT = 2;

	/**
	 * 大于等于 *
	 */
	private static final int CMP_TYPE_GE = 3;

	/**
	 * 小于等于 *
	 */
	private static final int CMP_TYPE_LE = 4;

	// 参数解析正则表达式
	private static final Pattern regPattern = Pattern.compile("(hp|mp|sp)([=<>]+)([0-9\\.]+)");

	private BattleBuff.BattleBasePropertyType propertyType;

	private final float limitValue;

	private int cmpType;

	public SkillAICondition_1(String ruleStr) {
		// 这里实现解释: hp>0.5或mp<=1.0或sp=0 这种参数
		Matcher m = regPattern.matcher(ruleStr.toLowerCase());
		String strProperty = null;
		String strCmpType = null;
		String strPercent = null;
		if (m.find()) {
			strProperty = m.group(1);
			strCmpType = m.group(2);
			strPercent = m.group(3);
		}
		if (strProperty == null || strCmpType == null || strPercent == null) {
			throw new IllegalArgumentException(ruleStr);
		}
		if ("hp".equals(strProperty)) {
			propertyType = BattleBuff.BattleBasePropertyType.Hp;
		} else if ("mp".equals(strProperty)) {
			propertyType = BattleBuff.BattleBasePropertyType.Mp;
		} else if ("sp".equals(strProperty)) {
			propertyType = BattleBuff.BattleBasePropertyType.Sp;
		}
		if (propertyType == null) {
			throw new IllegalArgumentException(strProperty);
		}

		if ("=".equals(strCmpType)) {
			cmpType = CMP_TYPE_EQ;
		} else if (">".equals(strCmpType)) {
			cmpType = CMP_TYPE_GT;
		} else if ("<".equals(strCmpType)) {
			cmpType = CMP_TYPE_LT;
		} else if (">=".equals(strCmpType)) {
			cmpType = CMP_TYPE_GE;
		} else if ("<=".equals(strCmpType)) {
			cmpType = CMP_TYPE_LE;
		}
		limitValue = NumberUtils.toFloat(strPercent);
	}

	public static void main(String[] args) {
		SkillAICondition_1 rule = new SkillAICondition_1("hp>=0.5");
		System.out.println(rule);
	}

	@Override
	public boolean isAvailable(BattleSoldier soldier, Skill skill, CommandContext ctx) {
		float currentValue = 0F;
		final boolean isPercent = isPercent();
		if (propertyType == BattleBuff.BattleBasePropertyType.Hp) {
			currentValue = isPercent ? soldier.hpRate() : soldier.hp();
		} else if (propertyType == BattleBuff.BattleBasePropertyType.Mp) {
			currentValue = isPercent ? soldier.mpRate() : soldier.mp();
		} else if (propertyType == BattleBuff.BattleBasePropertyType.Sp) {
			currentValue = isPercent ? soldier.getSp() * 1F / soldier.maxSp() : soldier.getSp();
		}
		return cmp(cmpType, currentValue, limitValue);
	}

	private boolean isPercent() {
		return this.limitValue >= 0 && this.limitValue < 1.F;
	}

	private boolean cmp(int cmpType, float currentValue, float value) {
		if (cmpType == CMP_TYPE_EQ && currentValue == value) {
			return true;
		} else if (cmpType == CMP_TYPE_GT && currentValue > value) {
			return true;
		} else if (cmpType == CMP_TYPE_LT && currentValue < value) {
			return true;
		} else if (cmpType == CMP_TYPE_GE && currentValue >= value) {
			return true;
		} else if (cmpType == CMP_TYPE_LE && currentValue <= value) {
			return true;
		}
		return false;
	}

}
