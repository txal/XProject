/**
 *
 */
package com.nucleus.logic.core.modules.battle.model;

import java.util.ArrayList;
import java.util.List;
import java.util.Map;
import java.util.concurrent.ConcurrentHashMap;

import com.nucleus.AppServerMode;
import com.nucleus.logic.AppCommonUtils;
import com.nucleus.logic.core.modules.battle.data.Skill;
import com.nucleus.logic.core.modules.battle.data.SkillWeightInfo;
import com.nucleus.logic.core.modules.battle.data.SkillsWeight;
import com.nucleus.logic.core.modules.charactor.data.Crew;
import com.nucleus.logic.core.modules.charactor.data.CrewSkillInfo;
import com.nucleus.logic.core.modules.charactor.model.PersistPlayerCrew;
import com.nucleus.logic.core.modules.charactor.model.PlayerPropertyHolder;
import com.nucleus.logic.core.modules.magicequipment.manager.MagicEquipmentManager;
import com.nucleus.logic.core.modules.player.manager.AppPlayerManager;
import com.nucleus.logic.core.modules.player.model.CorePlayer;
import com.nucleus.logic.core.modules.scene.manager.ScenePlayerManager;
import com.nucleus.logic.core.modules.scene.model.ScenePlayer;

/**
 * @author liguo
 */
public class CrewBattleSkillHolder extends NpcBattleSkillHolder<PersistPlayerCrew> {

	private int trainingSkillId;

	private int minSkillLevel;

	private int maxSkillLevel;

	/** 法宝技能 */
	private Map<Integer, Skill> magicEquipmentSkillMap = new ConcurrentHashMap<Integer, Skill>();

	public CrewBattleSkillHolder(PersistPlayerCrew battleUnit) {
		super(battleUnit);
		refreshSkillInfo();
	}

	private void refreshSkillInfo() {
		Crew crew = Crew.get(battleUnit.getCrewId());
		List<CrewSkillInfo> crewSkillInfos = crew.getCrewSkillInfos();

		List<SkillWeightInfo> activeSkillWeightInfos = new ArrayList<SkillWeightInfo>();
		int skillsWeightScope = 0;

		int level = battleUnit.grade();
		int minSkillLevel = Integer.MAX_VALUE;
		for (int i = 0; i < crewSkillInfos.size(); i++) {
			CrewSkillInfo crewSkillInfo = crewSkillInfos.get(i);
			if (level < crewSkillInfo.getAcquireLevel())
				continue;
			int skillWeight = crewSkillInfo.skillWeight();
			activeSkillWeightInfos.add(new SkillWeightInfo(crewSkillInfo.getSkillId(), skillWeight));
			skillsWeightScope += skillWeight;
			if (crewSkillInfo.getAcquireLevel() < minSkillLevel) {
				trainingSkillId = crewSkillInfo.getSkillId();
				minSkillLevel = crewSkillInfo.getAcquireLevel();
			}
			if (crewSkillInfo.getAcquireLevel() > maxSkillLevel) {
				maxSkillLevel = crewSkillInfo.getAcquireLevel();
			}
		}

		this.skillsWeight = new SkillsWeight(skillsWeightScope, activeSkillWeightInfos);
		populateActiveSkills();
		populatePassiveSkills(crew.genPassiveSkills(battleUnit.star()));
		populateMagicEquipmentSkill();
	}

	public int getTrainingSkillId() {
		return trainingSkillId;
	}

	public void refresh() {
		if (battleUnit.grade() >= minSkillLevel || battleUnit.grade() <= maxSkillLevel) {
			if (this.skillsLevelMap != null)
				this.skillsLevelMap.clear();
			if (this.activeSkillsMap != null)
				this.activeSkillsMap.clear();
			refreshSkillInfo();
		}
	}

	@Override
	public boolean containSkill(int skillId) {
		if (super.containSkill(skillId))
			return true;
		return this.magicEquipmentSkillMap.containsKey(skillId);
	}

	@Override
	public List<Skill> passiveSkills() {
		List<Skill> skills = new ArrayList<Skill>(super.passiveSkills());
		skills.addAll(this.magicEquipmentSkillMap.values());
		return skills;
	}

	@Override
	public int skillLevel(int skillId) {
		if (super.containSkill(skillId))
			return battleUnit.grade();// 伙伴的技能等级=自身等级
		else
			return skillsLevelMap.getOrDefault(skillId, 1);
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
			CorePlayer corePlayer = AppPlayerManager.getInstance().getAnyPlayerById(this.battleUnit.playerId());
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
}
