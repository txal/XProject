package com.nucleus.logic.core.modules.battle.data;

import com.nucleus.logic.core.modules.AppSkillActionStatusCode;
import com.nucleus.logic.core.modules.battle.BattleUtils;
import com.nucleus.logic.core.modules.battle.dto.VideoSkillAction;
import com.nucleus.logic.core.modules.battle.model.BattleSoldier;
import com.nucleus.logic.core.modules.battle.model.CommandContext;
import com.nucleus.logic.core.modules.battle.model.PveBattle;
import com.nucleus.logic.core.modules.battle.model.PvpBattle;
import com.nucleus.logic.core.modules.constants.CommonEnums.BattleCommandType;

/**
 * 法宝主动技能
 * 
 * @author xitao.huang
 *
 */
public class MagicEquipmentActiveSkill extends MagicEquipmentSkill {
	private String spendMagicManaFormula;
	private String effectFormula;

	public MagicEquipmentActiveSkill() {
	}

	@Override
	public int beforeFire(BattleSoldier trigger, VideoSkillAction action) {
		BattleCommandType curBattleCommandType = battleCommandType();
		CommandContext context = trigger.getCommandContext();
		int state = trigger.buffHolder().buffBanState(curBattleCommandType);
		if (state != 0 && !context.isStrokeBack())// 反击状态下可以突破buff封禁限制
			return state;
		if (!canFindTarget(trigger, context))
			return AppSkillActionStatusCode.CannotFindTarget;
		if (this.getBattleType() == BattleType.PVP.ordinal() && !(context.battle() instanceof PvpBattle)) {
			return AppSkillActionStatusCode.SkillCanntApplyNotPVP;
		}
		if (this.getBattleType() == BattleType.PVE.ordinal() && !(context.battle() instanceof PveBattle)) {
			return AppSkillActionStatusCode.SkillCanntApplyNotPVE;
		}

		int magicManaSpent = (int) BattleUtils.valueWithSoldierSkill(trigger, this.spendMagicManaFormula, this);
		if (Math.abs(magicManaSpent) > trigger.getMagicEquipmentMana()) {
			return AppSkillActionStatusCode.SkillApplyMagicManaNotEnough;
		}
		return 0;
	}
	
	@Override
	public void afterFired(BattleSoldier trigger, VideoSkillAction action) {
		int magicManaSpent = (int) BattleUtils.valueWithSoldierSkill(trigger, this.spendMagicManaFormula, this);
		trigger.decreateMagicEquipmentMana(magicManaSpent);
		action.setMagicManaSpent(magicManaSpent);
	}

	public String getSpendMagicManaFormula() {
		return spendMagicManaFormula;
	}

	public void setSpendMagicManaFormula(String spendMagicManaFormula) {
		this.spendMagicManaFormula = spendMagicManaFormula;
	}

	public String getEffectFormula() {
		return effectFormula;
	}

	public void setEffectFormula(String effectFormula) {
		this.effectFormula = effectFormula;
	}

}
