package com.nucleus.logic.core.modules.battle.model;

import java.util.ArrayList;
import java.util.Collection;
import java.util.Iterator;
import java.util.List;
import java.util.Map;
import java.util.Set;
import java.util.concurrent.ConcurrentHashMap;

import com.nucleus.AppServerMode;
import com.nucleus.logic.AppCommonUtils;
import com.nucleus.logic.core.modules.battle.data.Skill;
import com.nucleus.logic.core.modules.battle.data.TalentPassiveSkill;
import com.nucleus.logic.core.modules.charactor.data.GeneralCharactor.CharactorType;
import com.nucleus.logic.core.modules.charactor.model.PersistPlayerPet;
import com.nucleus.logic.core.modules.charactor.model.PetPropertyHolder;
import com.nucleus.logic.core.modules.charactor.model.PlayerPropertyHolder;
import com.nucleus.logic.core.modules.equipment.model.PetDanEquipmentExtra;
import com.nucleus.logic.core.modules.magicequipment.manager.MagicEquipmentManager;
import com.nucleus.logic.core.modules.player.data.FunctionOpen;
import com.nucleus.logic.core.modules.player.data.FunctionOpen.FunctionOpenEnum;
import com.nucleus.logic.core.modules.player.model.CorePlayer;
import com.nucleus.logic.core.modules.ride.manager.PlayerRideManager;
import com.nucleus.logic.core.modules.ride.model.PersistPlayerRide;
import com.nucleus.logic.core.modules.scene.manager.ScenePlayerManager;
import com.nucleus.logic.core.modules.scene.model.ScenePlayer;
import com.nucleus.logic.core.modules.talent.data.TalentSkillInfo;
import com.nucleus.logic.core.modules.talent.manager.PlayerTalentManager;
import com.nucleus.logic.core.modules.talent.model.PersistPlayerTalent;
import com.nucleus.logic.core.modules.talent.model.PlayerTalentSkillInfo;

/**
 * 
 * @author Omanhom
 *
 */
public class PetBattleSkillHolder extends AbstractBattleSkillHolder<PersistPlayerPet> {
	/**
	 * 坐骑技能
	 */
	private Map<Integer, Skill> rideMountSkillMap = new ConcurrentHashMap<Integer, Skill>();
	/** 法宝技能 */
	private Map<Integer, Skill> magicEquipmentSkillMap = new ConcurrentHashMap<Integer, Skill>();
	/**
	 * 天赋被动技能
	 */
	private Map<Integer, Skill> talentPassiveSkillMap = new ConcurrentHashMap<Integer, Skill>();

	public PetBattleSkillHolder(PersistPlayerPet battleUnit) {
		super(battleUnit);
		populateSkills(battleUnit);
		populateRideMountSkill();
		populateMagicEquipmentSkill();
		calPetDanSkillLevel(battleUnit);
		populateTalentPassiveSkill();
	}

	protected void populateSkills(PersistPlayerPet battleUnit) {
		PetPropertyHolder petPropertyHolder = battleUnit.propertyHolder();
		int skillLevel = battleUnit.grade();
		Set<Integer> skillIds = petPropertyHolder.skillIds();
		for (Iterator<Integer> it = skillIds.iterator(); it.hasNext();) {
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
		this.talentPassiveSkillMap.clear();
		populateTalentPassiveSkill();
	}

	@Override
	public boolean containSkill(int skillId) {
		if (super.containSkill(skillId))
			return true;
		return this.rideMountSkillMap.containsKey(skillId) || this.magicEquipmentSkillMap.containsKey(skillId) || this.talentPassiveSkillMap.containsKey(skillId);
	}

	@Override
	public List<Skill> passiveSkills() {
		List<Skill> skills = new ArrayList<Skill>(super.passiveSkills());
		skills.addAll(this.rideMountSkillMap.values());
		skills.addAll(this.magicEquipmentSkillMap.values());
		skills.addAll(this.talentPassiveSkillMap.values());
		return skills;
	}

	public void populateTalentPassiveSkill() {
		if (!FunctionOpen.enough(FunctionOpenEnum.Talent))
			return;
		this.talentPassiveSkillMap.clear();
		PersistPlayerTalent playerTalent = playerTalent();
		if (playerTalent == null)
			return;
		Collection<PlayerTalentSkillInfo> skillInfos = playerTalent.skillInfoMap().values();
		for (PlayerTalentSkillInfo skillInfo : skillInfos) {
			TalentSkillInfo talentSkillInfo = TalentSkillInfo.get(skillInfo.getId());
			if (talentSkillInfo == null)
				continue;
			List<Integer> effectIds = talentSkillInfo.passiveSkillEffectIds(CharactorType.Pet);
			if (effectIds.isEmpty())
				continue;
			for (Integer effectId : effectIds) {
				TalentPassiveSkill passiveSkill = TalentPassiveSkill.get(effectId);
				if (passiveSkill == null)
					continue;
				this.talentPassiveSkillMap.put(passiveSkill.getId(), passiveSkill);
				this.skillsLevelMap.put(passiveSkill.getId(), skillInfo.getGrade());
			}
		}
	}

	public PersistPlayerTalent playerTalent() {
		if (this.battleUnit == null)
			return null;
		if (AppCommonUtils.isValidMode(AppServerMode.Core.name())) {
			CorePlayer corePlayer = this.battleUnit.owner();
			if (corePlayer == null)
				return null;
			return PlayerTalentManager.getInstance().load(corePlayer);
		} else if (AppCommonUtils.isValidMode(AppServerMode.Scene.name())) {
			long playerId = this.battleUnit.playerId();
			ScenePlayer scenePlayer = ScenePlayerManager.getInstance().get(playerId);
			if (scenePlayer != null)
				return scenePlayer.playerTalent();
		}
		return null;
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

	public void calPetDanSkillLevel(PersistPlayerPet battleUnit) {
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
