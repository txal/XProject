/**
 * 
 */
package com.nucleus.logic.core.modules.battle.model;

import java.util.ArrayList;
import java.util.Collection;
import java.util.Collections;
import java.util.Comparator;
import java.util.Iterator;
import java.util.List;
import java.util.Map;
import java.util.concurrent.ConcurrentHashMap;

import org.apache.commons.logging.Log;
import org.apache.commons.logging.LogFactory;

import com.nucleus.commons.data.StaticConfig;
import com.nucleus.commons.utils.SplitUtils;
import com.nucleus.logic.core.modules.AppStaticConfigs;
import com.nucleus.logic.core.modules.battle.data.PetSkillTypeEnum;
import com.nucleus.logic.core.modules.battle.data.Skill;
import com.nucleus.logic.core.modules.battle.logic.IPassiveSkill;
import com.nucleus.logic.core.modules.faction.dto.FactionSkillDto;

/**
 * 技能Holder
 * 
 * @author liguo
 * 
 */
public abstract class BattleSkillHolder<BU extends BattleUnit> {

	protected Log battleLog = LogFactory.getLog("battle.log");

	protected BU battleUnit;

	/** 通用默认攻击技能 */
	protected Skill defaultActiveSkill = Skill.defaultActiveSkill();

	/** 所有战斗主动技能 */
	protected final Map<Integer, Skill> activeSkillsMap = new ConcurrentHashMap<Integer, Skill>();

	/** 所有战斗被动技能 */
	protected final Map<Integer, Skill> passiveSkillsMap = new ConcurrentHashMap<Integer, Skill>();

	/** 所有战斗技能等级信息 */
	protected final Map<Integer, Integer> skillsLevelMap = new ConcurrentHashMap<Integer, Integer>();

	/** 所有门派技能等级信息 */
	protected final Map<Integer, FactionSkillDto> factionSkillsMap = new ConcurrentHashMap<Integer, FactionSkillDto>();

	public BattleSkillHolder(BU battleUnit) {
		this.battleUnit = battleUnit;
		this.activeSkillsMap.put(defaultActiveSkill.getId(), defaultActiveSkill);
	}

	public int skillLevel(int skillId) {
		Integer skillLevelInt = skillsLevelMap.get(skillId);
		if (null == skillLevelInt) {
			return 0;
		}
		return skillLevelInt;
	}

	public abstract Skill aiSkill();

	public Skill skill(int skillId) {
		Skill skill = this.activeSkillsMap.get(skillId);
		if (skill != null)
			return skill;
		return this.passiveSkillsMap.get(skillId);
	}

	public Skill activeSkill(int skillId) {
		return activeSkillsMap.get(skillId);
	}

	public Skill passiveSkill(int skillId) {
		return passiveSkillsMap.get(skillId);
	}

	public boolean containSkill(int skillId) {
		return this.activeSkillsMap.containsKey(skillId) || this.passiveSkillsMap.containsKey(skillId);
	}

	public boolean containActiveSkill(int skillId) {
		return activeSkillsMap.containsKey(skillId);
	}

	public boolean containPassiveSkill(int skillId) {
		return passiveSkillsMap.containsKey(skillId);
	}

	public Collection<Skill> activeSkills() {
		return activeSkillsMap.values();
	}

	public List<Skill> passiveSkills() {
		List<Skill> skillList = new ArrayList<>(passiveSkillsMap.values());
		Collections.sort(skillList, new Comparator<Skill>() {
			@Override
			public int compare(Skill o1, Skill o2) {
				return (Integer.valueOf(o1.getId())).compareTo(Integer.valueOf(o2.getId()));
			}
		});
		return skillList;
	}

	/**
	 * 返回角色门派技能等级
	 * 
	 * @param factionSkillId
	 *            门派技能id
	 * @return 如果没有此门派技能信息则返回0
	 */
	public int playerFactionSkillLevel(int factionSkillId) {
		FactionSkillDto skillDto = this.factionSkillsMap.get(factionSkillId);
		if (skillDto == null)
			return 0;
		return skillDto.getFactionSkillLevel();
	}

	public abstract void onFactionSkillUpgrade(FactionSkillDto fsDto);

	public abstract void populateEquipmentSkill();

	public void addSkill(Skill skill) {
		if (skill == null)
			return;
		if (skill.isActiveSkill())
			this.activeSkillsMap.put(skill.getId(), skill);
		else
			this.passiveSkillsMap.put(skill.getId(), skill);
	}

	public void removeSkill(int skillId) {
		this.activeSkillsMap.remove(skillId);
		this.passiveSkillsMap.remove(skillId);
		this.skillsLevelMap.remove(skillId);
	}

	public void forceSkillLevel(int skillId, int skillsLevel) {
		this.skillsLevelMap.put(skillId, skillsLevel);
	}

	/**
	 * 过滤被动技能:高低级同时存在只返回高级,如果有指定逻辑则返回指定逻辑的技能
	 * 
	 * @return
	 */
	public List<IPassiveSkill> passiveSkillFilter() {
		if (this.passiveSkills().isEmpty())
			return Collections.emptyList();
		List<IPassiveSkill> skills = new ArrayList<IPassiveSkill>();
		for (Iterator<Skill> it = this.passiveSkills().iterator(); it.hasNext();) {
			Skill skill = it.next();
			if (skill == null || !(skill instanceof IPassiveSkill))
				continue;
			IPassiveSkill ps = (IPassiveSkill) skill;
			if (ps.getType() == PetSkillTypeEnum.Low.ordinal()) {
				int highSkillId = ps.getId() + 100;// 高级技能id=低级技能id+100;
				// 如果存在对应的高级技能,则低级技能忽略
				if (this.passiveSkill(highSkillId) != null)
					continue;
			}
			skills.add(ps);
		}
		return skills;
	}

	public boolean allLuckyPassSkills() {
		String strIds = StaticConfig.get(AppStaticConfigs.EQUIPMENT_LUCKY_NUM_PASS_SKILLS).getValue();
		int[] skillIds = SplitUtils.split2IntArray(strIds, "_");
		for (int i : skillIds) {
			if (!containPassiveSkill(i))
				return false;
		}
		return true;
	}

	public BU battleUnit() {
		return this.battleUnit;
	}
}
