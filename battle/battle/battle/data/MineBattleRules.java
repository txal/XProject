package com.nucleus.logic.core.modules.battle.data;

import java.beans.Transient;
import java.util.ArrayList;
import java.util.List;

import org.apache.commons.lang3.StringUtils;
import org.apache.commons.lang3.builder.ReflectionToStringBuilder;
import org.apache.commons.lang3.builder.ToStringStyle;

import com.nucleus.commons.annotation.GenIgnored;
import com.nucleus.commons.data.StaticDataManager;
import com.nucleus.commons.message.BroadcastMessage;
import com.nucleus.commons.utils.RandomUtils;

/**
 * 暗雷数量规则
 * 
 * @author liguo
 * 
 */
@GenIgnored
public class MineBattleRules implements BroadcastMessage {

	public static MineBattleRules get(int id) {
		return StaticDataManager.getInstance().get(MineBattleRules.class, id);
	}

	@Override
	public String toString() {
		return ReflectionToStringBuilder.toString(this, ToStringStyle.SHORT_PREFIX_STYLE);
	}

	/** 队伍人数 */
	private int id;

	/** 总权重 */
	private transient int totalWeight;

	/** 怪物数量 */
	private List<Integer> monsterCounts = new ArrayList<Integer>();

	/** 头领数量 */
	private List<Integer> bossCounts = new ArrayList<Integer>();

	/** 权重 */
	private List<Integer> weights = new ArrayList<Integer>();

	/** 强度系数 */
	private List<Float> multipliers = new ArrayList<Float>();
	/** 经验率(包括宠物，角色) */
	private float expRate;
	/** 宝宝刷新率 */
	private float babyRate;
	/** 物品掉落率 */
	private float fallItemRate;

	public int getId() {
		return id;
	}

	public void setId(int id) {
		this.id = id;
	}

	public float getExpRate() {
		return expRate;
	}

	public void setExpRate(float expRate) {
		this.expRate = expRate;
	}

	public float getBabyRate() {
		return babyRate;
	}

	public void setBabyRate(float babyRate) {
		this.babyRate = babyRate;
	}

	@Transient
	public void setMineBattleRulesStr(String mineBattleRulesStr) {
		if (StringUtils.isBlank(mineBattleRulesStr)) {
			return;
		}

		String[] mineBattleRulesArr = mineBattleRulesStr.split(",");
		for (int i = 0; i < mineBattleRulesArr.length; i++) {
			String[] mineBattleRuleArr = mineBattleRulesArr[i].split(":");
			int weight = Integer.parseInt(mineBattleRuleArr[2]);
			this.monsterCounts.add(Integer.parseInt(mineBattleRuleArr[0]));
			this.bossCounts.add(Integer.parseInt(mineBattleRuleArr[1]));
			this.weights.add(weight);
			this.multipliers.add(Float.parseFloat(mineBattleRuleArr[3]));
			this.totalWeight += weight;
		}
	}

	public int randomIndex() {
		int pivot = RandomUtils.nextInt(totalWeight);
		int weightCount = 0;
		for (int i = 0; i < this.weights.size(); i++) {
			weightCount += this.weights.get(i);
			if (pivot < weightCount)
				return i;
		}
		return 0;
	}

	public List<Integer> monsterCounts() {
		return monsterCounts;
	}

	public List<Integer> bossCounts() {
		return bossCounts;
	}

	public List<Float> multipliers() {
		return multipliers;
	}

	public float getFallItemRate() {
		return fallItemRate;
	}

	public void setFallItemRate(float fallItemRate) {
		this.fallItemRate = fallItemRate;
	}

}
