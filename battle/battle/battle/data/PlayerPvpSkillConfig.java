package com.nucleus.logic.core.modules.battle.data;

import java.util.ArrayList;
import java.util.List;
import java.util.Map;
import java.util.Map.Entry;

import javax.persistence.Transient;

import org.apache.commons.lang3.builder.ReflectionToStringBuilder;
import org.apache.commons.lang3.builder.ToStringStyle;

import com.nucleus.commons.annotation.GenIgnored;
import com.nucleus.commons.data.StaticDataManager;
import com.nucleus.commons.message.BroadcastMessage;
import com.nucleus.commons.utils.SplitUtils;

/**
 * 各门派玩家pvp战斗中(防守方)使用的技能配置
 * 
 * @author wgy
 *
 */
@GenIgnored
public class PlayerPvpSkillConfig implements BroadcastMessage {
	/** 门派id */
	private int id;
	private List<SkillWeightInfo> skillInfos;

	public static PlayerPvpSkillConfig get(int id) {
		return StaticDataManager.getInstance().get(PlayerPvpSkillConfig.class, id);
	}

	public int getId() {
		return id;
	}

	public void setId(int id) {
		this.id = id;
	}

	public List<SkillWeightInfo> skillInfos() {
		return this.skillInfos;
	}

	@Transient
	public void setSkillInfoStr(String skillInfoStr) {
		Map<Integer, Integer> map = SplitUtils.split2IntMap(skillInfoStr, ",", ":");
		this.skillInfos = new ArrayList<>();
		for (Entry<Integer, Integer> entry : map.entrySet()) {
			this.skillInfos.add(new SkillWeightInfo(entry.getKey(), entry.getValue()));
		}
	}

	@Override
	public String toString() {
		return ReflectionToStringBuilder.toString(this, ToStringStyle.SHORT_PREFIX_STYLE);
	}
}
