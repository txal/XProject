package com.nucleus.logic.core.modules.battle.model;

import java.util.ArrayList;
import java.util.Collection;
import java.util.Collections;
import java.util.Iterator;
import java.util.List;
import java.util.Map;
import java.util.Set;
import java.util.concurrent.ConcurrentHashMap;

import javax.persistence.Transient;

import com.nucleus.commons.data.StaticConfig;
import com.nucleus.logic.core.modules.AppStaticConfigs;
import com.nucleus.logic.core.modules.battle.SkillManager;
import com.nucleus.logic.core.modules.battle.data.Skill;
import com.nucleus.logic.core.modules.battle.data.SkillInfo;
import com.nucleus.logic.core.modules.battle.data.TalentPassiveSkill;
import com.nucleus.logic.core.modules.battle.data.WingPassiveSkill;
import com.nucleus.logic.core.modules.battle.logic.IPassiveSkill;
import com.nucleus.logic.core.modules.charactor.data.GeneralCharactor.CharactorType;
import com.nucleus.logic.core.modules.charactor.model.PlayerPropertyHolder;
import com.nucleus.logic.core.modules.equipment.model.EquipmentExtra;
import com.nucleus.logic.core.modules.faction.data.Faction;
import com.nucleus.logic.core.modules.faction.data.FactionSkill;
import com.nucleus.logic.core.modules.faction.dto.FactionSkillDto;
import com.nucleus.logic.core.modules.magicequipment.manager.MagicEquipmentManager;
import com.nucleus.logic.core.modules.player.data.FunctionOpen;
import com.nucleus.logic.core.modules.player.data.FunctionOpen.FunctionOpenEnum;
import com.nucleus.logic.core.modules.player.model.PersistPlayer;
import com.nucleus.logic.core.modules.player.model.PersistPlayerFactionSkills;
import com.nucleus.logic.core.modules.player.model.PersistPlayerTransform;
import com.nucleus.logic.core.modules.player.model.PlayerPersistVisitor;
import com.nucleus.logic.core.modules.ride.model.PersistPlayerRide;
import com.nucleus.logic.core.modules.talent.data.TalentSkillInfo;
import com.nucleus.logic.core.modules.talent.model.PersistPlayerTalent;
import com.nucleus.logic.core.modules.talent.model.PlayerTalentSkillInfo;
import com.nucleus.logic.core.modules.wing.data.WingTalent;
import com.nucleus.logic.core.modules.wing.data.WingTalentEffect;
import com.nucleus.logic.core.modules.wing.model.PersistPlayerWing;
import com.nucleus.logic.core.modules.wing.model.PlayerWingTalent;
import com.nucleus.player.model.PackItemAdapter;

/**
 * 
 * @author Omanhom
 *
 */
public class PlayerBattleSkillHolder extends AbstractBattleSkillHolder<PersistPlayer> {
	/**
	 * 装备特技
	 */
	private Map<Integer, Skill> equipmentSkillMap = new ConcurrentHashMap<Integer, Skill>();
	/**
	 * 装备特效
	 */
	private Map<Integer, Skill> equipmentPassiveSkillMap = new ConcurrentHashMap<Integer, Skill>();
	/**
	 * 变身卡附带技能
	 */
	private Map<Integer, Skill> transformSkillMap = new ConcurrentHashMap<Integer, Skill>();
	/**
	 * 坐骑技能
	 */
	private Map<Integer, Skill> rideMountSkillMap = new ConcurrentHashMap<Integer, Skill>();
	/**
	 * 法宝被动技能
	 */
	private Map<Integer, Skill> magicEquipmentPassiveSkillMap = new ConcurrentHashMap<Integer, Skill>();
	/**
	 * 法宝技能
	 */
	private Map<Integer, Skill> magicEquipmentActiveSkillMap = new ConcurrentHashMap<Integer, Skill>();
	/**
	 * 仙羽被动技能
	 */
	private Map<Integer, Skill> wingPassiveSkillMap = new ConcurrentHashMap<Integer, Skill>();
	/**
	 * 天赋被动技能
	 */
	private Map<Integer, Skill> talentPassiveSkillMap = new ConcurrentHashMap<Integer, Skill>();

	@Transient
	private transient PlayerPersistVisitor persistVisitor;

	public PlayerBattleSkillHolder(PersistPlayer battleUnit) {
		super(battleUnit);
		// 召唤
		int defaultSummonSkillId = StaticConfig.get(AppStaticConfigs.DEFAULT_SUMMON_SKILL_ID).getAsInt(4);
		Skill defaultSummonSkill = Skill.get(defaultSummonSkillId);
		// 捕捉
		int defaultCaptureSkillId = StaticConfig.get(AppStaticConfigs.DEFAULT_CAPTURE_SKILL_ID).getAsInt(5);
		Skill defaultCaptureSkill = Skill.get(defaultCaptureSkillId);

		this.activeSkillsMap.put(defaultSummonSkill.getId(), defaultSummonSkill);
		this.activeSkillsMap.put(defaultCaptureSkill.getId(), defaultCaptureSkill);

		this.persistVisitor = battleUnit.persistVisitor();
		populateActiveSkills(battleUnit);
		populateTransformSkill();
		populateRideMountSkill();
		populateTalentPassiveSkill();
	}

	protected void populateActiveSkills(PersistPlayer battleUnit) {
		PersistPlayerFactionSkills pps = persistVisitor.persistPlayerFactionSkills();
		this.factionSkillsMap.clear();
		this.factionSkillsMap.putAll(pps.factionSkillsMap());

		Faction faction = battleUnit.faction();
		populateFactionSkill(this.activeSkillsMap, faction.mainFactionSkill());
		List<FactionSkill> propertySkills = faction.propertyFactionSkills();
		for (int i = 0; i < propertySkills.size(); i++) {
			FactionSkill factionSkill = propertySkills.get(i);
			populateFactionSkill(this.activeSkillsMap, factionSkill);
		}
		populateFactionSkill(this.activeSkillsMap, faction.mustFactionSkill());
		populateEquipmentSkill();
		populateCoupleSkill();
		populateRideMountSkill();
		populateMagicEquipmentSkill();
		populateWingPassiveSkill();
	}

	private void populateFactionSkill(Map<Integer, Skill> skillsMap, FactionSkill factionSkill) {
		List<SkillInfo> skillInfos = factionSkill.skillInfos();
		int factionSkillId = factionSkill.getId();
		FactionSkillDto factionSkillDto = factionSkillsMap.get(factionSkillId);
		if (null == factionSkillDto) {
			if (battleLog.isDebugEnabled())
				battleLog.debug("=========factionSkillDto is null, factionSkillId:[" + factionSkillId + "]");
			return;
		}
		int skillLevel = factionSkillDto.getFactionSkillLevel();
		for (int i = 0; i < skillInfos.size(); i++) {
			SkillInfo skillInfo = skillInfos.get(i);
			int curSkillId = skillInfo.getSkillId();
			Skill curSkill = Skill.get(curSkillId);
			if (null == curSkill || skillLevel < skillInfo.getAcquireFactionSkillLevel())
				continue;
			skillsMap.put(curSkillId, curSkill);
			this.skillsLevelMap.put(curSkillId, skillLevel);
		}
	}

	@Override
	public void populateEquipmentSkill() {
		equipmentSkillMap.clear();
		equipmentPassiveSkillMap.clear();
		PlayerPropertyHolder playerPropertyHolder = this.battleUnit.propertyHolder();
		for (Iterator<PackItemAdapter> it = playerPropertyHolder.equipmentPartTypeMap().values().iterator(); it.hasNext();) {
			PackItemAdapter packItem = it.next();
			EquipmentExtra extra = (EquipmentExtra) packItem.getExtraObject();
			if (extra != null) {
				this.mergeSkill(extra.getActiveSkillIds(), this.equipmentSkillMap);
				this.mergeSkill(extra.getPassiveSkillIds(), this.equipmentPassiveSkillMap);
			}
		}
	}

	public void populateWingPassiveSkill() {
		if (!FunctionOpen.enough(FunctionOpenEnum.Wing)) {
			return;
		}
		wingPassiveSkillMap.clear();
		PersistPlayerWing pw = persistVisitor.playerWing();
		Collection<PlayerWingTalent> pwts = pw.wingTalentInfos();
		for (PlayerWingTalent pwt : pwts) {
			WingTalent wt = WingTalent.get(pwt.getId());
			List<WingTalentEffect> wtes = wt.passiveSkillEffectList(pwt.getLevel());
			if (wtes.isEmpty())
				continue;
			for (WingTalentEffect wte : wtes) {
				WingPassiveSkill wps = (WingPassiveSkill) WingPassiveSkill.get((int) wte.getValue());
				wingPassiveSkillMap.put(wps.getId(), wps);
			}
		}
	}

	public void populateTalentPassiveSkill() {
		if (!FunctionOpen.enough(FunctionOpenEnum.Talent))
			return;
		this.talentPassiveSkillMap.clear();
		PersistPlayerTalent playerTalent = this.persistVisitor.playerTalent();
		if (playerTalent == null)
			return;
		Collection<PlayerTalentSkillInfo> skillInfos = playerTalent.skillInfoMap().values();
		for (PlayerTalentSkillInfo skillInfo : skillInfos) {
			TalentSkillInfo talentSkillInfo = TalentSkillInfo.get(skillInfo.getId());
			if (talentSkillInfo == null)
				continue;
			List<Integer> effectIds = talentSkillInfo.passiveSkillEffectIds(CharactorType.MainCharactor);
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

	private void mergeSkill(Set<Integer> skillIds, Map<Integer, Skill> skillMap) {
		for (int skillId : skillIds) {
			Skill skill = Skill.get(skillId);
			if (skill == null)
				continue;
			skillMap.put(skillId, skill);
		}
	}

	@Override
	public void onFactionSkillUpgrade(FactionSkillDto fsDto) {
		FactionSkill fs = FactionSkill.get(fsDto.getFactionSkillId());
		if (fs == null)
			return;
		int fsLv = fsDto.getFactionSkillLevel();// 当前门派技能等级
		// 遍历该门派技能下面的所有子技能,如果等级符合则加入技能map
		for (Iterator<SkillInfo> it = fs.skillInfos().iterator(); it.hasNext();) {
			SkillInfo si = it.next();
			int skillId = si.getSkillId();
			Skill skill = Skill.get(skillId);
			if (skill == null || fsLv < si.getAcquireFactionSkillLevel())
				continue;
			this.skillsLevelMap.put(skillId, fsLv);
			// 如果该子技能已经存在则不处理
			if (this.activeSkillsMap.containsKey(skillId))
				continue;
			this.activeSkillsMap.put(skillId, skill);
		}
	}

	@Override
	public Skill activeSkill(int skillId) {
		Skill skill = super.activeSkill(skillId);
		if (skill == null)
			skill = this.equipmentSkillMap.get(skillId);
		if (skill == null)
			skill = this.magicEquipmentActiveSkillMap.get(skillId);
		return skill;
	}

	@Override
	public Skill passiveSkill(int skillId) {
		Skill skill = super.passiveSkill(skillId);
		if (skill == null)
			skill = this.equipmentPassiveSkillMap.get(skillId);
		if (skill == null)
			skill = this.transformSkillMap.get(skillId);
		if (skill == null)
			skill = this.rideMountSkillMap.get(skillId);
		if (skill == null)
			skill = this.magicEquipmentPassiveSkillMap.get(skillId);
		if (skill == null)
			skill = this.wingPassiveSkillMap.get(skillId);
		if (skill == null)
			skill = this.talentPassiveSkillMap.get(skillId);
		return skill;
	}

	@Override
	public List<Skill> passiveSkills() {
		List<Skill> skills = new ArrayList<Skill>(super.passiveSkills());
		skills.addAll(this.equipmentPassiveSkillMap.values());
		skills.addAll(this.transformSkillMap.values());
		skills.addAll(this.rideMountSkillMap.values());
		skills.addAll(this.magicEquipmentPassiveSkillMap.values());
		skills.addAll(this.wingPassiveSkillMap.values());
		skills.addAll(this.talentPassiveSkillMap.values());
		return skills;
	}

	@Override
	public List<IPassiveSkill> passiveSkillFilter() {
		Collection<Skill> skills = this.passiveSkills();
		if (skills.isEmpty())
			return Collections.emptyList();
		List<IPassiveSkill> passiveSkills = new ArrayList<IPassiveSkill>();
		for (Iterator<Skill> it = skills.iterator(); it.hasNext();) {
			Skill skill = it.next();
			if (skill == null || !(skill instanceof IPassiveSkill))
				continue;
			IPassiveSkill ps = (IPassiveSkill) skill;
			passiveSkills.add(ps);
		}
		return passiveSkills;
	}

	public void populateTransformSkill() {
		PersistPlayerTransform ppt = persistVisitor.persistPlayerTransform();
		this.transformSkillMap.clear();
		if (!ppt.expired() && ppt.getSkillId() > 0) {
			Skill skill = Skill.get(ppt.getSkillId());
			if (skill != null)
				this.transformSkillMap.put(ppt.getSkillId(), skill);
		}
	}

	public void populateRideMountSkill() {
		PersistPlayerRide ppt = persistVisitor.playerRide();
		this.rideMountSkillMap.clear();
		if (ppt != null)
			ppt.addSkillToMap(this.battleUnit, this.rideMountSkillMap, this.skillsLevelMap);
	}

	public void addTransformSkill(Skill skill) {
		this.transformSkillMap.put(skill.getId(), skill);
	}

	public void clearTransformSkill() {
		this.transformSkillMap.clear();
	}

	public Map<Integer, Skill> getTalentPassiveSkillMap() {
		return talentPassiveSkillMap;
	}

	public void setTalentPassiveSkillMap(Map<Integer, Skill> talentPassiveSkillMap) {
		this.talentPassiveSkillMap = talentPassiveSkillMap;
	}

	@Override
	public boolean containSkill(int skillId) {
		if (super.containSkill(skillId))
			return true;
		return this.equipmentSkillMap.containsKey(skillId) || this.equipmentPassiveSkillMap.containsKey(skillId) || this.transformSkillMap.containsKey(skillId)
				|| this.rideMountSkillMap.containsKey(skillId) || this.talentPassiveSkillMap.containsKey(skillId);
	}

	@Override
	public boolean containActiveSkill(int skillId) {
		if (super.containActiveSkill(skillId))
			return true;
		return this.equipmentSkillMap.containsKey(skillId);
	}

	@Override
	public boolean containPassiveSkill(int skillId) {
		if (super.containPassiveSkill(skillId))
			return true;
		return this.equipmentPassiveSkillMap.containsKey(skillId) || this.transformSkillMap.containsKey(skillId) || this.rideMountSkillMap.containsKey(skillId)
				|| this.talentPassiveSkillMap.containsKey(skillId);
	}

	public void populateCoupleSkill() {
		this.mergeSkill(SkillManager.getInstance().coupleSkills(), this.activeSkillsMap);
	}

	public void populateMagicEquipmentSkill() {
		PlayerPropertyHolder propertyHolder = this.battleUnit.propertyHolder();
		this.magicEquipmentPassiveSkillMap.clear();
		this.magicEquipmentActiveSkillMap.clear();
		if (propertyHolder != null) {
			MagicEquipmentManager.getInstance().addToPassiveSkillMap(propertyHolder, this.battleUnit, this.magicEquipmentPassiveSkillMap, this.skillsLevelMap);
			MagicEquipmentManager.getInstance().addToActiveSkillMap(propertyHolder, this.battleUnit, magicEquipmentActiveSkillMap, skillsLevelMap);
		}
	}
}
