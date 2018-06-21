package com.nucleus.logic.core.modules.battle.model;

import java.util.ArrayList;
import java.util.HashSet;
import java.util.Iterator;
import java.util.List;
import java.util.Map;
import java.util.Set;
import java.util.concurrent.ConcurrentHashMap;

import org.apache.commons.collections.CollectionUtils;

import com.nucleus.AppServerMode;
import com.nucleus.logic.AppCommonUtils;
import com.nucleus.logic.core.modules.battle.data.Skill;
import com.nucleus.logic.core.modules.battle.data.SkillInfo;
import com.nucleus.logic.core.modules.charactor.data.ChildFactionSkill;
import com.nucleus.logic.core.modules.charactor.model.PersistPlayerChild;
import com.nucleus.logic.core.modules.charactor.model.PlayerPropertyHolder;
import com.nucleus.logic.core.modules.equipment.model.PetDanEquipmentExtra;
import com.nucleus.logic.core.modules.equipment.model.PetEquipmentExtra;
import com.nucleus.logic.core.modules.magicequipment.manager.MagicEquipmentManager;
import com.nucleus.logic.core.modules.player.model.CorePlayer;
import com.nucleus.logic.core.modules.ride.manager.PlayerRideManager;
import com.nucleus.logic.core.modules.ride.model.PersistPlayerRide;
import com.nucleus.logic.core.modules.scene.manager.ScenePlayerManager;
import com.nucleus.logic.core.modules.scene.model.ScenePlayer;

/**
 * 
 * @author wgy
 *
 */
public class ChildBattleSkillHolder extends AbstractBattleSkillHolder<PersistPlayerChild> {

	/** 坐骑技能 */
	private Map<Integer, Skill> rideMountSkillMap = new ConcurrentHashMap<Integer, Skill>();
	/** 法宝技能 */
	private Map<Integer, Skill> magicEquipmentSkillMap = new ConcurrentHashMap<Integer, Skill>();

	public ChildBattleSkillHolder(PersistPlayerChild battleUnit) {
		super(battleUnit);
		populateSkills(battleUnit);
		populateRideMountSkill();
		populateMagicEquipmentSkill();
		calPetDanSkillLevel(battleUnit);
	}

	protected void populateSkills(PersistPlayerChild battleUnit) {
		int skillLevel = battleUnit.grade();
		Set<Integer> allSkills = new HashSet<>();
		allSkills.addAll(battleUnit.skillIds());// 普通宠物技能
		if (battleUnit.getChildSkillId() > 0)
			allSkills.add(battleUnit.getChildSkillId());// 子女特殊技能
		ChildFactionSkill fs = ChildFactionSkill.get(battleUnit.getFactionId());// 门派技能
		if (fs != null) {
			for (SkillInfo info : fs.getSkillInfos()) {
				if (skillLevel < info.getAcquireFactionSkillLevel())
					continue;
				allSkills.add(info.getSkillId());
			}
		}
		// 护符技能
		for (PetEquipmentExtra extra : battleUnit.equipmentsMap().values()) {
			if (CollectionUtils.isNotEmpty(extra.getPetSkillIds()))
				allSkills.addAll(extra.getPetSkillIds());
		}
		for (Iterator<Integer> it = allSkills.iterator(); it.hasNext();) {
			int skillId = it.next();
			Skill skill = Skill.get(skillId);
			if (skill == null) {
				it.remove();
				continue;
			}
			if (skill.isActiveSkill())
				this.activeSkillsMap.put(skillId, skill);
			else
				this.passiveSkillsMap.put(skillId, skill);
			this.skillsLevelMap.put(skillId, skillLevel);
		}
	}

	@Override
	public void addSkill(Skill skill) {
		super.addSkill(skill);
		if (skill != null)
			this.skillsLevelMap.put(skill.getId(), battleUnit.grade());
	}

	public void rePopulateSkill() {
		this.activeSkillsMap.clear();
		this.passiveSkillsMap.clear();
		this.skillsLevelMap.clear();
		initDefaultSkill();
		populateSkills(battleUnit);

		this.rideMountSkillMap.clear();
		populateRideMountSkill();

		this.magicEquipmentSkillMap.clear();
		populateMagicEquipmentSkill();
		calPetDanSkillLevel(battleUnit);
	}

	@Override
	public boolean containSkill(int skillId) {
		if (super.containSkill(skillId))
			return true;
		if (this.rideMountSkillMap.containsKey(skillId)) {
			return true;
		}
		return this.magicEquipmentSkillMap.containsKey(skillId);
	}

	@Override
	public List<Skill> passiveSkills() {
		List<Skill> skills = new ArrayList<Skill>(super.passiveSkills());
		skills.addAll(this.rideMountSkillMap.values());
		skills.addAll(this.magicEquipmentSkillMap.values());
		return skills;
	}

	public void populateRideMountSkill() {
		PersistPlayerRide ppt = this.playerRide();
		this.rideMountSkillMap.clear();
		if (ppt != null)
			ppt.addSkillToMap(this.battleUnit, this.rideMountSkillMap, this.skillsLevelMap);
	}

	public PersistPlayerRide playerRide() {
		if (this.battleUnit == null)
			return null;
		if (AppCommonUtils.isValidMode(AppServerMode.Core.name())) {
			CorePlayer corePlayer = this.battleUnit.owner();
			if (corePlayer == null)
				return null;
			return PlayerRideManager.getInstance().load(corePlayer);
		} else if (AppCommonUtils.isValidMode(AppServerMode.Scene.name())) {
			long playerId = this.battleUnit.playerId();
			ScenePlayer scenePlayer = ScenePlayerManager.getInstance().get(playerId);
			if (scenePlayer != null)
				return scenePlayer.playerRide();
		}
		return null;
	}

	public void populateMagicEquipmentSkill() {
		PlayerPropertyHolder propertyHolder = this.playerPropertyHolder();
		this.magicEquipmentSkillMap.clear();
		if (propertyHolder != null)
			MagicEquipmentManager.getInstance().addToPassiveSkillMap(propertyHolder, this.battleUnit, this.magicEquipmentSkillMap, this.skillsLevelMap);
	}

	public PlayerPropertyHolder playerPropertyHolder() {
		if (this.battleUnit == null)
			return null;
		if (AppCommonUtils.isValidMode(AppServerMode.Core.name())) {
			CorePlayer corePlayer = this.battleUnit.owner();
			if (corePlayer == null)
				return null;
			return corePlayer.persistPlayer().propertyHolder();
		} else if (AppCommonUtils.isValidMode(AppServerMode.Scene.name())) {
			long playerId = this.battleUnit.playerId();
			ScenePlayer scenePlayer = ScenePlayerManager.getInstance().get(playerId);
			if (scenePlayer != null)
				return scenePlayer.persistPlayer().propertyHolder();
		}
		return null;
	}

	public void calPetDanSkillLevel(PersistPlayerChild battleUnit) {
		Map<Integer, PetDanEquipmentExtra> petDanMap = battleUnit.allDanInfoMap();
		for (Iterator<PetDanEquipmentExtra> iter = petDanMap.values().iterator(); iter.hasNext();) {
			PetDanEquipmentExtra petDan = iter.next();
			if (petDan.isSenior())
				skillsLevelMap.replace(petDan.getSkill(), petDan.getLevel());
			else
				skillsLevelMap.replace(petDan.getSkill(), petDan.getLevel() + petDan.getEcho());
		}
	}
}
