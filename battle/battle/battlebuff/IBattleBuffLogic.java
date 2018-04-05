package com.nucleus.logic.core.modules.battlebuff;

import com.nucleus.commons.logic.Logic;
import com.nucleus.logic.core.modules.battle.model.CommandContext;
import com.nucleus.logic.core.modules.battlebuff.data.BattleBuff;
import com.nucleus.logic.core.modules.battlebuff.data.BattleBuff.BattleBasePropertyType;
import com.nucleus.logic.core.modules.battlebuff.model.BattleBuffEntity;
import com.nucleus.logic.core.modules.battlebuff.model.BuffLogicParam;

/**
 * 
 * @author wgy
 *
 */
public interface IBattleBuffLogic extends Logic {
	public void initParam(BattleBuff buff, String param);

	/**
	 * 行动开始前执行
	 * 
	 * @param commandContext
	 */
	public void onActionStart(CommandContext commandContext, BattleBuffEntity buffEntity);

	/**
	 * 当次行动完毕执行
	 */
	public void onActionEnd(CommandContext commandContext, BattleBuffEntity buffEntity);

	/**
	 * buff移除处理逻辑
	 */
	public void onRemove(BattleBuffEntity buffEntity);

	/**
	 * 受击死亡
	 */
	public void attackDead(CommandContext commandContext, BattleBuffEntity buffEntity);

	/**
	 * 受到攻击
	 */
	public void underAttack(CommandContext commandContext, BattleBuffEntity buffEntity);

	/**
	 * 技能发动之前
	 */
	public void beforeSkillFire(CommandContext commandContext, BattleBuffEntity buffEntity);

	/**
	 * 进行攻击之前
	 */
	public void beforeAttack(CommandContext commandContext, BattleBuffEntity buffEntity);

	/**
	 * 反击的时候
	 */
	public void onStrikeBack(CommandContext commandContext, BattleBuffEntity buffEntity);

	/**
	 * 获得buff之后
	 */
	public void afterGetBuff(BattleBuffEntity buffEntity);

	/**
	 * buff抗性
	 * 
	 * @param commandContext
	 * @param logicParam
	 */
	public void antiBuff(CommandContext commandContext, BuffLogicParam logicParam);

	public boolean propertyEffectable(CommandContext commandContext, BattleBasePropertyType propertyType);

	public void onRoundStart(BattleBuffEntity buffEntity);

	public void onRoundEnd(BattleBuffEntity buffEntity);

	/** 是否不可被使用物品 */
	public boolean antiItem(BuffLogicParam logicParam, int itemId);

	/**
	 * @param commandContext
	 *            指令施放上下文
	 * @param buffEntity
	 */
	public void onBeforeRemove(CommandContext commandContext, BattleBuffEntity buffEntity);
}
