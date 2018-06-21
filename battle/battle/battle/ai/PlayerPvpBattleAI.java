package com.nucleus.logic.core.modules.battle.ai;

import java.util.ArrayList;
import java.util.Collection;
import java.util.Collections;
import java.util.Comparator;
import java.util.List;
import java.util.Map;
import java.util.Set;

import com.nucleus.commons.data.StaticConfig;
import com.nucleus.logic.core.modules.AppStaticConfigs;
import com.nucleus.logic.core.modules.battle.BattleUtils;
import com.nucleus.logic.core.modules.battle.ai.rules.SkillAITarget;
import com.nucleus.logic.core.modules.battle.ai.rules.SkillAITarget_1;
import com.nucleus.logic.core.modules.battle.data.PlayerPvpSkillConfig;
import com.nucleus.logic.core.modules.battle.data.Skill;
import com.nucleus.logic.core.modules.battle.data.SkillAIConfig;
import com.nucleus.logic.core.modules.battle.data.SkillWeightInfo;
import com.nucleus.logic.core.modules.battle.data.SkillsWeight;
import com.nucleus.logic.core.modules.battle.model.BattlePlayerSoldierInfo;
import com.nucleus.logic.core.modules.battle.model.BattleSoldier;
import com.nucleus.logic.core.modules.battle.model.CommandContext;
import com.nucleus.logic.core.modules.charactor.model.PersistPlayerPet;

/**
 * 竞技场主人物ai
 * 
 * @author wgy
 *
 */
public class PlayerPvpBattleAI extends BattleAIAdapter {
	private final BattleSoldier soldier;
	private final List<SkillWeightInfo> skillsInfo;
	private final SkillAITarget defaultAITarget = new SkillAITarget_1("");
	private final Map<Long, PersistPlayerPet> carryPetOfTeamB;

	public PlayerPvpBattleAI(final BattleSoldier soldier, PlayerPvpSkillConfig config, Map<Long, PersistPlayerPet> carryPetOfTeamB) {
		this.soldier = soldier;
		this.carryPetOfTeamB = carryPetOfTeamB;
		this.skillsInfo = new ArrayList<>();
		Collection<Skill> existSkills = soldier.skillHolder().battleSkillHolder().activeSkills();
		for (SkillWeightInfo info : config.skillInfos()) {
			final Skill skill = info.skill();
			if (!existSkills.contains(skill))
				continue;
			skillsInfo.add(info);
		}
	}

	@Override
	public CommandContext selectCommand() {
		final List<SkillWeightInfo> availableSkills = new ArrayList<>();
		for (SkillWeightInfo info : this.skillsInfo) {
			final Skill skill = info.skill();
			if (!isAvailable(this.soldier, skill)) {
				continue;
			}
			availableSkills.add(info);
		}
		for (BattleSoldier actor : soldier.team().soldiersMap().values()) {
			// 有单位倒地，则判断自身是否有复活类技能，如有则优先使用
			if (actor.getId() != soldier.getId() && actor.isDead() /* && 没有其它人施救 */) {
				for (SkillWeightInfo info : availableSkills) {
					Skill skill = info.skill();
					// 有复活技能
					if (skill.isUseAliveTarget() == false || (skill.isDeadTriggerSkill() && skill.ifHpIncreaseFunction())) {
						return makeCommandContext(actor, skill);
					}
				}
			}

			if (actor.isDead()) {
				continue;
			}
		}
		BattlePlayerSoldierInfo soldierInfo = soldier.team().soldiersByPlayer(soldier.playerId());
		BattleSoldier pet = soldier.team().battleSoldier(soldierInfo.petSoldierId());
		if (pet == null && !carryPetOfTeamB.isEmpty()) {// 尝试换宠
			int max = StaticConfig.get(AppStaticConfigs.MAX_PET_COUNT).getAsInt(5);
			if (soldierInfo.getAllPetSoldierIds().size() < max) {
				final PersistPlayerPet playerPet = autoChangePet(soldierInfo.getAllPetSoldierIds());
				if (playerPet != null) {
					final CommandContext commandContext = new CommandContext(this.soldier, Skill.summonSkill(), null, playerPet.getId());
					commandContext.setCachedBattlePet(playerPet);
					return commandContext;
				}
			}
		}
		// 其它技能处理
		Skill skill = Skill.get(1); // 平砍
		int skillsTotalWeight = 0;
		final List<SkillWeightInfo> attackSkills = new ArrayList<>(availableSkills.size());
		for (SkillWeightInfo availableSkillInfo : availableSkills) {
			final Skill availableSkill = availableSkillInfo.skill();
			if (!availableSkill.isUseAliveTarget()) {
				continue;
			}
			skillsTotalWeight += availableSkillInfo.getSkillWeight();
			attackSkills.add(availableSkillInfo);
		}
		int skillId = BattleUtils.randomActiveSkillId(new SkillsWeight(skillsTotalWeight, attackSkills));
		if (skillId > 0) {
			skill = Skill.get(skillId);
			skill = populatePreRequireSkill(this.soldier, skill);
		}
		BattleSoldier target = selectTarget(skill);
		return makeCommandContext(target, skill);
	}

	private PersistPlayerPet autoChangePet(Set<Long> petSoldierIds) {
		final List<PersistPlayerPet> pets = new ArrayList<>(carryPetOfTeamB.values());
		// 功能 #7911【战斗】竞技场系统控制的主角在招宠时优先选择等级最高的宠物
		Collections.sort(pets, new Comparator<PersistPlayerPet>() {
			@Override
			public int compare(PersistPlayerPet o1, PersistPlayerPet o2) {
				return o2.grade() - o1.grade();
			}
		});
		for (PersistPlayerPet pet : pets) {
			if (petSoldierIds.contains(pet.getId()))
				continue;
			return pet;
		}
		return null;
	}

	public CommandContext makeCommandContext(BattleSoldier target, Skill skill) {
		if (target != null) {
			this.soldier.roundContext().putTarget(target.getId(), this.soldier.getId(), skill.getId());
		}
		return new CommandContext(this.soldier, skill, target);
	}

	public BattleSoldier selectTarget(Skill skill) {
		BattleSoldier target;
		SkillAIConfig aiConfig = SkillAIConfig.get(skill.getId());
		if (aiConfig != null) {
			target = aiConfig.selectTarget(soldier, skill, null);
		} else {
			target = defaultAITarget.select(soldier, skill, null);
		}
		return target;
	}
}
