package com.nucleus.logic.core.modules.battle.logic;

import org.springframework.stereotype.Service;

import com.nucleus.AppServerMode;
import com.nucleus.logic.core.modules.AppSkillActionStatusCode;
import com.nucleus.logic.core.modules.battle.ai.PetChallengeBattleAI;
import com.nucleus.logic.core.modules.battle.data.PassiveSkillLaunchTimingEnum;
import com.nucleus.logic.core.modules.battle.dto.VideoSwtichPetState;
import com.nucleus.logic.core.modules.battle.model.BattleInfo;
import com.nucleus.logic.core.modules.battle.model.BattlePlayer;
import com.nucleus.logic.core.modules.battle.model.BattlePlayerSoldierInfo;
import com.nucleus.logic.core.modules.battle.model.BattleSoldier;
import com.nucleus.logic.core.modules.battle.model.CommandContext;
import com.nucleus.logic.core.modules.challenge.ChallengeBattle;
import com.nucleus.logic.core.modules.charactor.data.ShoutConfig;
import com.nucleus.logic.core.modules.charactor.model.PersistPlayerChild;
import com.nucleus.logic.core.modules.charactor.model.PersistPlayerPet;
import com.nucleus.logic.core.modules.scene.model.ScenePlayer;
import com.nucleus.logic.scene.SceneModeService;
import com.nucleus.logic.scene.cross.CrossServerUtils;

/**
 * 召唤
 * 
 * @author liguo
 * 
 */
@Service
public class SkillLogic_3 extends SkillLogicAdapter {
	@Override
	protected int beforeFired(CommandContext commandContext) {
		int status = super.beforeFired(commandContext);
		if (status > 0)
			return status;
		BattleSoldier trigger = commandContext.trigger();
		BattlePlayerSoldierInfo soldierInfo = trigger.battleTeam().soldiersByPlayer(trigger.playerId());
		if (soldierInfo == null)
			return 0;
		if (soldierInfo.getAllPetSoldierIds().contains(commandContext.petCharactorUniqueId()))
			status = AppSkillActionStatusCode.CallPetOnlyOnce;
		else {
			int max = trigger.maxCallPetCount();
			if (soldierInfo.getAllPetSoldierIds().size() > max)
				status = AppSkillActionStatusCode.OutOffCallPetCount;
		}
		commandContext.skillAction().setSkillStatusCode(status);
		return status;
	}

	@Override
	public void doFired(CommandContext commandContext) {
		BattleSoldier trigger = commandContext.trigger();
		BattlePlayer owner = trigger.player();
		if (owner == null) {
			return;
		}
		boolean keepNewPet = true;// 保存新宠物到玩家身上
		if ((trigger.battle() instanceof ChallengeBattle) && trigger.battleTeam().isNpcTeam()) {
			keepNewPet = false;// 如果是竞技场战斗被挑战一方的宠物变化不影响玩家实际数据
		}
		// PersistPlayerPet pet = SceneModeService.getInstance().toInner().sync(AppServerMode.Core.ordinal(), "coreinner.changeBattlePet", owner.getId(),
		// commandContext.petCharactorUniqueId(), keepNewPet);
		trigger.skillHolder().passiveSkillEffectByTiming(trigger, commandContext, PassiveSkillLaunchTimingEnum.BeforeCallPet);
		PersistPlayerPet pet = commandContext.getCachedBattlePet();
		PersistPlayerChild child = commandContext.getCachedBattleChild();
		BattleSoldier newPet = null;
		if (pet != null) {
			owner.battlePet(pet);
			owner.bonusPet(pet);
			newPet = trigger.battleTeam().switchPet(pet);
		} else if (child != null)
			newPet = trigger.battleTeam().switchPet(child);
		if (newPet != null) {
			newPet.joinRoundProcessor(trigger.getCurRoundProcessor());
			if (!keepNewPet) {// 竞技场被挑战方换宠,设置自动ai
				newPet.skillHolder().setBattleAI(new PetChallengeBattleAI(newPet));
			}
			// 这里执行的被动技能比如属性或者挂buff，需要在发送给客户端前(也就是下面的addTargetState)设置好,否则可能出现客户端没有表现
			newPet.skillHolder().passiveSkillEffectByTiming(newPet, null, PassiveSkillLaunchTimingEnum.BattleReady);
			callPetPassiveSkillEffect(trigger.battle().battleInfo(), commandContext);
			commandContext.skillAction().addTargetState(new VideoSwtichPetState(newPet));
			newPet.shout(ShoutConfig.BattleShoutTypeEnum.Summon, commandContext);
			if (keepNewPet && pet != null) {
				int toClientId = CrossServerUtils.isCrossSceneServer() ? ((ScenePlayer) owner).onlineGameServerId() : 1;
				SceneModeService.getInstance().toInner().async(AppServerMode.Core.ordinal(), toClientId, "coreinner.changePetConfirm", owner.getId(), commandContext.petCharactorUniqueId());
			}
		}
	}

	private void callPetPassiveSkillEffect(BattleInfo battleInfo, CommandContext context) {
		for (BattleSoldier soldier : battleInfo.getAteam().soldiersMap().values()) {
			soldier.skillHolder().passiveSkillEffectByTiming(soldier, context, PassiveSkillLaunchTimingEnum.CallPet);
		}
		for (BattleSoldier soldier : battleInfo.getBteam().soldiersMap().values()) {
			soldier.skillHolder().passiveSkillEffectByTiming(soldier, context, PassiveSkillLaunchTimingEnum.CallPet);
		}
	}

}
