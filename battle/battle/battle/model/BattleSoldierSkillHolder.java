/**
 * 
 */
package com.nucleus.logic.core.modules.battle.model;

import java.util.Iterator;
import java.util.List;
import java.util.Set;

import com.nucleus.commons.data.StaticConfig;
import com.nucleus.commons.log.LogUtils;
import com.nucleus.commons.utils.SplitUtils;
import com.nucleus.logic.core.modules.AppStaticConfigs;
import com.nucleus.logic.core.modules.battle.ai.BattleAI;
import com.nucleus.logic.core.modules.battle.ai.NpcBattleAI;
import com.nucleus.logic.core.modules.battle.ai.PetPveAutoBattleAI;
import com.nucleus.logic.core.modules.battle.ai.PlayerPveAutoBattleAI;
import com.nucleus.logic.core.modules.battle.data.PassiveSkillConfig;
import com.nucleus.logic.core.modules.battle.data.PassiveSkillLaunchTimingEnum;
import com.nucleus.logic.core.modules.battle.data.PassiveSkillLogicEnum;
import com.nucleus.logic.core.modules.battle.data.Skill;
import com.nucleus.logic.core.modules.battle.logic.IPassiveSkill;
import com.nucleus.logic.core.modules.battle.logic.IPassiveSkillLogic;
import com.nucleus.logic.core.modules.battlebuff.data.BattleBuff.BattleBasePropertyType;
import com.nucleus.logic.core.modules.charactor.data.GeneralCharactor.CharactorType;

/**
 * @author liguo
 * 
 */
public class BattleSoldierSkillHolder {
	/** 1813,1814,1815,1816这几个特殊技能施放需要指定buff(120),如果没有该buff则使用特定技能(1812) */
	private static Set<Integer> specialSkillIds;
	private static int specialBuffId;
	private static int specialReplaceSkillId;

	static {
		String var = StaticConfig.get(AppStaticConfigs.SPECIAL_SKILL_CONFIG).getValue();
		String[] strArr = SplitUtils.split2StringArray(var, "\\|");
		if (strArr.length == 3) {
			specialSkillIds = SplitUtils.split2IntSet(strArr[0], "-");
			specialBuffId = Integer.parseInt(strArr[1]);
			specialReplaceSkillId = Integer.parseInt(strArr[2]);
		}
	}

	private BattleSoldier soldier;

	private BattleSkillHolder<?> battleSkillHolder;

	private BattleAI battleAI;
	/** 特殊情况：每回合正常开始行动前施放的技能 */
	private Skill preRoundSkill;

	public BattleSoldierSkillHolder(BattleSoldier soldier) {
		this.soldier = soldier;
		BattleUnit battleUnit = soldier.battleUnit();
		this.battleSkillHolder = battleUnit.battleSkillHolder();

		if (this.soldier.charactorType() == CharactorType.Crew.ordinal() || this.soldier.charactorType() == CharactorType.Monster.ordinal()) {
			this.battleAI = new NpcBattleAI(this.soldier, this.battleSkillHolder);
		} else if (this.soldier.battle() instanceof PveBattle) {
			if (this.soldier.charactorType() == CharactorType.MainCharactor.ordinal())
				this.battleAI = new PlayerPveAutoBattleAI(this.soldier);
			else if (this.soldier.charactorType() == CharactorType.Pet.ordinal() || this.soldier.charactorType() == CharactorType.Child.ordinal())
				this.battleAI = new PetPveAutoBattleAI(this.soldier);
		}
	}

	public BattleSkillHolder<?> battleSkillHolder() {
		return this.battleSkillHolder;
	}

	public Skill aiSkill() {
		Skill skill = preRequireSkill(this.battleSkillHolder.aiSkill());
		return skill;
	}

	public Skill preRequireSkill(Skill skill) {
		// 如果没有变身,使用以下技能先变身
		if (specialSkillIds.contains(skill.getId()) && !soldier.buffHolder().hasBuff(specialBuffId)) {
			skill = Skill.get(specialReplaceSkillId);
		} else if (this.soldier.isAutoBattle() && skill.getId() == 5365 && this.soldier.buffHolder().hasBuff(204)) {
			skill = Skill.defaultActiveSkill();
		} else if (this.soldier.isAutoBattle() && skill.getId() == 5359 && this.soldier.hpRate() < 0.3) {
			skill = Skill.defaultActiveSkill();
		}
		return skill;
	}

	public CommandContext selectCommand() {
		if (battleAI == null) {
			return new CommandContext(this.soldier, this.aiSkill(), null);
		}
		CommandContext ctx = null;
		try {
			ctx = battleAI.selectCommand();
		} catch (Exception e) {
			Skill skill = Skill.get(1); // 平砍
			ctx = new CommandContext(soldier, skill, null);
			LogUtils.errorLog("BattleSoldierSkillHolder.selectCommand error:", e);
		}
		return ctx;
	}

	public boolean onActionStart(CommandContext commandContext) {
		if (battleAI != null) {
			return battleAI.onActionStart(this.soldier, commandContext);
		}
		return true;
	}

	public BattleSoldier soldier() {
		return this.soldier;
	}

	public Skill skill(int skillId) {
		return battleSkillHolder.skill(skillId);
	}

	public Skill activeSkill(int skillId) {
		return battleSkillHolder.activeSkill(skillId);
	}

	public Skill passiveSkill(int skillId) {
		return battleSkillHolder.passiveSkill(skillId);
	}

	/**
	 * 被动技能效果,直接影响属性
	 * 
	 * @param propertyType
	 * @return
	 */
	public float passiveSkillPropertyEffect(BattleBasePropertyType propertyType) {
		float v = 0;
		try {
			List<IPassiveSkill> skills = this.battleSkillHolder.passiveSkillFilter();
			for (Iterator<IPassiveSkill> it = skills.iterator(); it.hasNext();) {
				IPassiveSkill ps = it.next();
				if (ps.getConfigId() == null)
					continue;
				for (int i = 0; i < ps.getConfigId().length; i++) {
					int configId = ps.getConfigId()[i];
					PassiveSkillConfig config = PassiveSkillConfig.get(configId);
					if (config == null)
						continue;
					if (config.getLogicId() != PassiveSkillLogicEnum.PropertyEffectInBattle.ordinal())
						continue;
					IPassiveSkillLogic logic = config.logic();
					if (logic == null)
						continue;
					v += logic.propertyEffect(this.soldier, propertyType, config, ps);
				}
			}
		} catch (Exception e) {
			e.printStackTrace();
		}
		return v;
	}

	/**
	 * 触发被动技能
	 * 
	 * @param timing
	 */
	public void passiveSkillEffectByTiming(BattleSoldier target, CommandContext context, PassiveSkillLaunchTimingEnum timing) {
		int tmpConfigId = 0;
		try {
			List<IPassiveSkill> skills = this.battleSkillHolder.passiveSkillFilter();
			for (Iterator<IPassiveSkill> it = skills.iterator(); it.hasNext();) {
				IPassiveSkill ps = it.next();
				if (ps.getConfigId() == null)
					continue;
				for (int configId : ps.getConfigId()) {
					PassiveSkillConfig config = PassiveSkillConfig.get(configId);
					if (config == null)
						continue;
					IPassiveSkillLogic logic = config.logic();
					if (logic == null)
						continue;
					tmpConfigId = configId;
					logic.apply(this.soldier, target, context, config, timing, ps);
				}
			}
		} catch (Exception e) {
			String message = String.format("PassiveSkillConfig:%s, launchTiming:%s", tmpConfigId, timing.ordinal());
			LogUtils.errorLog(message, e);
		}
	}

	/**
	 * 如果该soldier是主角则返回门派技能等级,否则返回各自能力等级
	 * 
	 * @param factionSkillId
	 * @return
	 */
	public int factionSkillLevel(int factionSkillId) {
		int factionSkillLevel = 0;
		if (this.soldier.battleUnit().charactorType() == CharactorType.MainCharactor) {
			factionSkillLevel = this.battleSkillHolder.playerFactionSkillLevel(factionSkillId);
		} else
			factionSkillLevel = this.soldier.grade();
		return factionSkillLevel;
	}

	public Skill getPreRoundSkill() {
		return preRoundSkill;
	}

	public void setPreRoundSkill(Skill preRoundSkill) {
		this.preRoundSkill = preRoundSkill;
	}

	public BattleAI getBattleAI() {
		return battleAI;
	}

	public void setBattleAI(BattleAI battleAI) {
		this.battleAI = battleAI;
	}

}
