package com.nucleus.logic.core.modules.battle;

import java.io.Serializable;
import java.util.ArrayList;
import java.util.HashSet;
import java.util.List;
import java.util.Map;
import java.util.Set;

import org.apache.mina.util.ConcurrentHashSet;
import org.springframework.stereotype.Service;

import com.nucleus.commons.data.DataChangeListener;
import com.nucleus.commons.utils.RandomUtils;
import com.nucleus.commons.utils.SpringUtils;
import com.nucleus.logic.core.modules.battle.data.Skill;
import com.nucleus.logic.core.modules.equipment.data.PetEquipmentSkill;

/**
 * 
 * @author liguo
 * 
 */
@Service
public class SkillManager implements DataChangeListener {

	public final static int PET_SKILL_ID_SIZE = 4;

	public static final int PET_SKILL_ID_PRE_LEN = 2;// 技能id前缀位数,如前两位作为初/高/特殊标记
	public final static int PET_LOW_CLASS_SKILL_ID_INITIAL = 51;// 初级技能id前两位

	public final static int PET_HIGH_CLASS_SKILL_ID_INITIAL = 52;// 高级技能id前两位

	public final static int PET_SPECIAL_CLASS_SKILL_ID_INITIAL = 53;// 特殊技能id前两位

	public final static int PET_LOW_CLASS_SKILL = 1;// 低级技能标识

	public final static int PET_HIGH_CLASS_SKILL = 2;// 高级技能标识

	public final static int PET_SPECIAL_CLASS_SKILL = 3;// 特殊技能标识
	
	public final static int PET_ACTIVE_CLASS_SKILL = 4; // 主动技能标识

	public final static int HIGHT_TO_LOW_DIFF = 100;// 高级技能id=低级技能id+100

	/** 宠物低级技能编号列表 */
	private Set<Integer> petLowClassSkillIds = new ConcurrentHashSet<Integer>();

	/** 宠物高级技能编号列表 */
	private Set<Integer> petHighClassSkillIds = new ConcurrentHashSet<Integer>();
	/**
	 * 特殊技能id集合
	 */
	private Set<Integer> petSpecialSkillIds = new ConcurrentHashSet<Integer>();
	/** 夫妻法术 */
	private Set<Integer> coupleSkillIds = new ConcurrentHashSet<>();

	public static SkillManager getInstance() {
		return SpringUtils.getBeanOfType(SkillManager.class);
	}

	private void addSkillId(int skillId) {
		String skillIdStr = String.valueOf(skillId);
		int idSize = skillIdStr.length();

		switch (idSize) {
			case PET_SKILL_ID_SIZE:
				int initialId = Integer.parseInt(skillIdStr.substring(0, PET_SKILL_ID_PRE_LEN));

				switch (initialId) {
					case PET_LOW_CLASS_SKILL_ID_INITIAL:
						this.petLowClassSkillIds.add(skillId);
						break;
					case PET_HIGH_CLASS_SKILL_ID_INITIAL:
						this.petHighClassSkillIds.add(skillId);
						break;
					case PET_SPECIAL_CLASS_SKILL_ID_INITIAL:
						this.petSpecialSkillIds.add(skillId);
					default:
				}

				break;
			default:
		}
	}

	private void cleanAll() {
		this.petLowClassSkillIds.clear();
		this.petHighClassSkillIds.clear();
		this.coupleSkillIds.clear();
	}

	public int randomPetSkillId(List<Integer> petSkillClasses, Set<Integer> excludeSkillIds) {
		Set<Integer> targetSkillIds = new HashSet<Integer>();
		for (int i = 0; i < petSkillClasses.size(); i++) {
			switch (petSkillClasses.get(i)) {
				case PET_LOW_CLASS_SKILL:
					Set<Integer> lowSkillIds = classSkill(PET_LOW_CLASS_SKILL, petLowClassSkillIds);
					targetSkillIds.addAll(lowSkillIds);
					break;
				case PET_HIGH_CLASS_SKILL:
					Set<Integer> highSkillIds = classSkill(PET_HIGH_CLASS_SKILL, petHighClassSkillIds);
					targetSkillIds.addAll(highSkillIds);
					break;
				case PET_SPECIAL_CLASS_SKILL:
					Set<Integer> specialSkillIds = classSkill(PET_SPECIAL_CLASS_SKILL, petSpecialSkillIds);
					targetSkillIds.addAll(specialSkillIds);
					break;
				case PET_ACTIVE_CLASS_SKILL:
					Set<Integer> activeSkillIds = classSkill(PET_ACTIVE_CLASS_SKILL, petSpecialSkillIds);
					targetSkillIds.addAll(activeSkillIds);
					break;
				default:
			}
		}
		if (null != excludeSkillIds && !excludeSkillIds.isEmpty())
			targetSkillIds.removeAll(excludeSkillIds);
		return targetSkillIds.isEmpty() ? 0 : RandomUtils.next(targetSkillIds);
	}

	public boolean petSkillContains(List<Integer> petSkillClasses, Set<Integer> excludeSkillIds) {
		boolean bool = false;
		for (int i = 0; i < petSkillClasses.size(); i++) {
			switch (petSkillClasses.get(i)) {
				case PET_LOW_CLASS_SKILL:
					Set<Integer> lowSkillIds = classSkill(PET_LOW_CLASS_SKILL, petLowClassSkillIds);
					lowSkillIds.retainAll(excludeSkillIds);
					bool = bool ? bool : (lowSkillIds.size() > 0);
					break;
				case PET_HIGH_CLASS_SKILL:
					Set<Integer> highSkillIds = classSkill(PET_HIGH_CLASS_SKILL, petHighClassSkillIds);
					highSkillIds.retainAll(excludeSkillIds);
					bool = bool ? bool : (highSkillIds.size() > 0);
					break;
				case PET_SPECIAL_CLASS_SKILL:
					Set<Integer> specialSkillIds = classSkill(PET_SPECIAL_CLASS_SKILL, petSpecialSkillIds);
					specialSkillIds.retainAll(excludeSkillIds);
					bool = bool ? bool : (specialSkillIds.size() > 0);
					break;
				default:
			}
		}
		return bool;
	}

	/**
	 * 护符装备技能从原技能中获取，过滤掉填写错误的
	 * 
	 * @param skillType
	 * @param skillIds
	 * @return
	 */
	private Set<Integer> classSkill(int skillType, Set<Integer> skillIds) {
		Set<Integer> skills = PetEquipmentSkill.get(skillType).getSkills();
		Set<Integer> allSkillIds = new HashSet<Integer>(skillIds);
		allSkillIds.retainAll(skills);
		return allSkillIds;
	}

	/**
	 * 不包括特殊技能
	 * 
	 * @param excludeSkillIds
	 * @return
	 */
	public int randomPetSkillId(Set<Integer> excludeSkillIds) {
		List<Integer> srcSkillIds = new ArrayList<Integer>(this.petLowClassSkillIds);
		srcSkillIds.addAll(this.petHighClassSkillIds);
		// srcSkillIds.addAll(this.petSpecialSkillIds);
		return randomSkillId(srcSkillIds, excludeSkillIds);
	}

	public int randomLowPetSkillId() {
		return randomLowPetSkillId(null);
	}

	public int randomLowPetSkillId(Set<Integer> excludeSkillIds) {
		List<Integer> srcSkillIds = new ArrayList<Integer>(this.petLowClassSkillIds);
		return randomSkillId(srcSkillIds, excludeSkillIds);
	}

	public int randomHighPetSkillId() {
		return randomHighPetSkillId(null);
	}

	public int randomHighPetSkillId(Set<Integer> excludeSkillIds) {
		List<Integer> srcSkillIds = new ArrayList<Integer>(this.petHighClassSkillIds);
		return randomSkillId(srcSkillIds, excludeSkillIds);
	}

	private int randomSkillId(List<Integer> srcList, Set<Integer> excludeSkillIds) {
		if (null != excludeSkillIds && !excludeSkillIds.isEmpty())
			srcList.removeAll(excludeSkillIds);
		if (srcList.isEmpty())
			return 0;
		return RandomUtils.next(srcList);
	}

	@Override
	public Class<?>[] interestClass() {
		return new Class[] { Skill.class };
	}

	@Override
	public void change(Class<?> topClazz, Class<?> clazz, Map<Serializable, Object> dataMap, long lastUpdateTime) {
		cleanAll();
		for (Object object : dataMap.values()) {
			Skill skill = (Skill) object;
			this.addSkillId(skill.getId());
			if (skill.coupleSkill())
				this.coupleSkillIds.add(skill.getId());
		}
	}

	public Set<Integer> lowSkills() {
		return this.petLowClassSkillIds;
	}

	public Set<Integer> coupleSkills() {
		return this.coupleSkillIds;
	}
}
