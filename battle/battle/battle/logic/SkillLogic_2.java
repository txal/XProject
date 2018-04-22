package com.nucleus.logic.core.modules.battle.logic;

import org.springframework.stereotype.Service;

import com.nucleus.logic.core.modules.AppSkillActionStatusCode;
import com.nucleus.logic.core.modules.athletics.model.CSAthleticsBattle;
import com.nucleus.logic.core.modules.battle.CommandService;
import com.nucleus.logic.core.modules.battle.dto.VideoSkillAction;
import com.nucleus.logic.core.modules.battle.model.BattlePlayer;
import com.nucleus.logic.core.modules.battle.model.BattlePlayerSoldierInfo;
import com.nucleus.logic.core.modules.battle.model.BattleSoldier;
import com.nucleus.logic.core.modules.battle.model.CommandContext;
import com.nucleus.logic.core.modules.player.data.Props;
import com.nucleus.logic.core.modules.player.model.BattleUsePackItem;
import com.nucleus.logic.core.modules.player.model.PackItem;
import com.nucleus.logic.scene.modules.scene.manager.CoreService;
import com.nucleus.player.model.PackItemAdapter;

/**
 * 使用物品
 * 
 * @author liguo
 * 
 */
@Service
public class SkillLogic_2 extends SkillLogicAdapter {
	@Override
	protected int beforeFired(CommandContext commandContext) {
		int status = super.beforeFired(commandContext);
		if (status != AppSkillActionStatusCode.Ordinary)
			return status;
		BattlePlayer player = commandContext.trigger().player();
		if (player == null) {
			return status;
		}
		BattlePlayerSoldierInfo info = commandContext.trigger().battleTeam().soldiersByPlayer(player.getId());
		if (info != null && info.getUseItemCount() >= CommandService.MAX_USE_ITEM_COUNT) {
			status = AppSkillActionStatusCode.UseItemTimesOut;
			updateStatusCode(commandContext, status);
			return status;
		}

		if (commandContext.trigger().battle() instanceof CSAthleticsBattle) {
			if (info != null && info.getUseItemCount() >= CommandService.CSATH_MAX_USE_ITEM_COUNT) {
				status = AppSkillActionStatusCode.UseItemTimesOut;
				updateStatusCode(commandContext, status);
				return status;
			}
		}

		Props props = commandContext.getProps();
		if (props == null) {
			status = AppSkillActionStatusCode.UserItemNotFound;
			updateStatusCode(commandContext, status);
			return status;
		}
		BattleSoldier target = commandContext.target();

		if (target == null || target.isLeave()) {
			status = AppSkillActionStatusCode.ForPresentTarget;
			updateStatusCode(commandContext, status);
			return status;
		}
		if (target.antiItem(props.getId())) {
			status = AppSkillActionStatusCode.TargetAntiItem;
			updateStatusCode(commandContext, status);
			return status;
		}
		if (props.isReliveTarget() && !target.canUseReliveProp()) {
			status = AppSkillActionStatusCode.CannotReliveTarget;
			updateStatusCode(commandContext, status);
			return status;
		}
		if (props.healTarget() && target.preventHeal()) {
			status = AppSkillActionStatusCode.CannotHealTarget;
			updateStatusCode(commandContext, status);
			return status;
		}

		final int usedItemIndex = commandContext.getUsedItemIndex();
		final boolean targetDead = commandContext.target().isDead();
		status = CoreService.getInstance().checkUseItem(player.getId(), usedItemIndex, targetDead);
		if (status != AppSkillActionStatusCode.Ordinary) {
			updateStatusCode(commandContext, status);
		}
		return status;
	}

	private void updateStatusCode(final CommandContext commandContext, int status) {
		VideoSkillAction skillAction = commandContext.skillAction();
		skillAction.setSkillStatusCode(status);
		skillAction.setSkillId(commandContext.skill().getId());
	}

	@Override
	public void doFired(CommandContext commandContext) {
		BattlePlayer player = commandContext.trigger().player();
		if (player == null)
			return;
		BattleUsePackItem usedItem = CoreService.getInstance().useItem(player.getId(), commandContext.getUsedItemIndex());
		if (usedItem == null) {
			return;
		}
		PackItemAdapter packItem = new PackItem();
		packItem.setItemId(usedItem.getPropId());
		packItem.setItemCount(1);
		packItem.setExtraObject(usedItem.getExtra());
		Props prop = (Props) packItem.getItem();
		// 数量传0是为了不执行删除操作
		prop.apply(packItem, 0, "", commandContext);
		BattleSoldier trigger = commandContext.trigger();
		BattlePlayerSoldierInfo info = trigger.battleTeam().soldiersByPlayer(trigger.playerId());
		if (info != null)
			info.addUseItemCount(1);
	}

}
