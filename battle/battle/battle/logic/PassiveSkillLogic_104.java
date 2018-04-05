package com.nucleus.logic.core.modules.battle.logic;

import java.util.Set;
import java.util.concurrent.ConcurrentHashMap;

import org.springframework.stereotype.Service;

import com.nucleus.commons.utils.StringFormatUtils;
import com.nucleus.logic.chat.modules.data.ChatChannel.ChatChannelEnum;
import com.nucleus.logic.chat.modules.data.ChatChannel.LableTypeEnum;
import com.nucleus.logic.chat.modules.dto.SystemNotify;
import com.nucleus.logic.core.modules.AppStaticStrings;
import com.nucleus.logic.core.modules.battle.data.PassiveSkillConfig;
import com.nucleus.logic.core.modules.battle.data.PassiveSkillLaunchTimingEnum;
import com.nucleus.logic.core.modules.battle.model.Battle;
import com.nucleus.logic.core.modules.battle.model.BattlePlayer;
import com.nucleus.logic.core.modules.battle.model.BattleSoldier;
import com.nucleus.logic.core.modules.battle.model.CommandContext;
import com.nucleus.logic.core.modules.scene.model.NpcSceneDogBattle;
import com.nucleus.logic.core.modules.scene.model.NpcSceneImmortalBattle;
import com.nucleus.logic.scene.SceneModeService;
import com.nucleus.outer.msg.GeckoMultiMessage;

/**
 * 特定战斗中，保留战斗信息。例如天降鸿运战斗中如果福娃被击败，可以记录该信息，战斗结束增加奖励
 * 
 * @author wangyu
 *
 */
@Service
public class PassiveSkillLogic_104 extends AbstractPassiveSkillLogic {

	@Override
	protected void doApply(BattleSoldier soldier, BattleSoldier target, CommandContext context, PassiveSkillConfig config, PassiveSkillLaunchTimingEnum timing, IPassiveSkill passiveSkill) {
		Battle battle = context.battle();
		if (battle instanceof NpcSceneImmortalBattle) {
			NpcSceneImmortalBattle immortalBattle = (NpcSceneImmortalBattle) battle;
			immortalBattle.setDefeatBaby(true);
			if (context.trigger().player() != null) {
				long playerId = context.trigger().player().getId();
				SystemNotify notify = new SystemNotify(ChatChannelEnum.Unknown, StringFormatUtils.getText(AppStaticStrings.DEFEAT_BABY_REWARD), LableTypeEnum.Screen);
				SceneModeService.getInstance().toOuter().send(new GeckoMultiMessage(notify, playerId));
			}
		} else if (battle instanceof NpcSceneDogBattle) {
			NpcSceneDogBattle immortalBattle = (NpcSceneDogBattle) battle;
			immortalBattle.setDefeatBaby(true);
			if (context.trigger().player() != null) {
				Set<Long> playerIds = ConcurrentHashMap.newKeySet();
				for (long playerId : context.trigger().team().playerIds()) {
					playerIds.add(playerId);
				}
				SystemNotify notify = new SystemNotify(ChatChannelEnum.Unknown, StringFormatUtils.getText(AppStaticStrings.FIND_THE_DOG), LableTypeEnum.Screen);
				SceneModeService.getInstance().toOuter().send(new GeckoMultiMessage(notify, playerIds));
			}
		}
	}
}
