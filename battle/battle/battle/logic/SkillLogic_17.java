package com.nucleus.logic.core.modules.battle.logic;

import java.util.HashMap;
import java.util.List;
import java.util.Map;

import org.apache.commons.lang3.StringUtils;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;

import com.nucleus.AppServerMode;
import com.nucleus.commons.utils.RandomUtils;
import com.nucleus.logic.core.modules.AppSkillActionStatusCode;
import com.nucleus.logic.core.modules.AppTraceTypes;
import com.nucleus.logic.core.modules.activity.data.MonkeyStealConfig;
import com.nucleus.logic.core.modules.battle.data.Skill;
import com.nucleus.logic.core.modules.battle.dto.VideoActionStealTargetState;
import com.nucleus.logic.core.modules.battle.dto.VideoSkillAction;
import com.nucleus.logic.core.modules.battle.dto.VideoTargetStateGroup;
import com.nucleus.logic.core.modules.battle.model.BattleSoldier;
import com.nucleus.logic.core.modules.battle.model.CommandContext;
import com.nucleus.logic.core.modules.player.data.AppVirtualItem.VirtualItemEnum;
import com.nucleus.logic.core.modules.scene.model.NpcSceneMonkeyBattle;
import com.nucleus.logic.core.modules.system.manager.GameServerGradeManager;
import com.nucleus.logic.scene.SceneModeService;
import com.nucleus.player.service.ScriptService;

/**
 * 偷钱
 * 
 * @author wgy
 *
 */
@Service
public class SkillLogic_17 extends SkillLogicAdapter {
	@Autowired
	private SceneModeService sceneModeService;

	@Override
	protected int beforeFired(CommandContext commandContext) {
		Skill skill = commandContext.skill();
		VideoSkillAction skillAction = commandContext.skillAction();
		skillAction.setSkillStatusCode(AppSkillActionStatusCode.Ordinary);
		skillAction.setSkillId(skill.getId());
		return AppSkillActionStatusCode.Ordinary;
	}

	@Override
	public void doFired(CommandContext commandContext) {
		Skill skill = commandContext.skill();
		SkillAiLogic skillAiLogic = skill.skillAi().skillAiLogic();
		List<SkillTargetPolicy> targetPolicys = skillAiLogic.selectTargets(commandContext);
		if (targetPolicys.isEmpty())
			return;
		for (SkillTargetPolicy tp : targetPolicys) {
			attack(commandContext, tp.getTarget());
		}
	}

	private void attack(CommandContext commandContext, BattleSoldier target) {
		Skill skill = commandContext.skill();
		if (null == target || target.isDead() == skill.isUseAliveTarget())
			return;
		commandContext.skillAction().addTargetStateGroup(new VideoTargetStateGroup());
		NpcSceneMonkeyBattle battle = (NpcSceneMonkeyBattle) commandContext.battle();
		int limit = battle.copperNeed();
		VideoActionStealTargetState state = new VideoActionStealTargetState(target, skill.getId(), 0, limit);
		long playerCopper = getPlayerCopper(target.playerId());
		// 如果玩家身上铜币不足,则用-1标记结束战斗
		if (playerCopper < limit) {
			state.setCopper(-1);
			battle.maxRound(battle.getCount());// 当玩家铜币不足的时候,如果服务端直接结束战斗,客户端无法表现铜币不足的状态,通过设置下一回合结束战斗(利用回合上限),让客户端有时间处理铜币不足提示
		} else {
			// 计算此次所偷铜币copper,如果玩家当前拥有铜币playerCopper少于该值,则扣除铜币reduceCopper=playerCopper-limit,否则直接扣除copper
			int copper = calcCopper(commandContext);
			if (copper > 0) {
				int reduceCopper = (int) (playerCopper < copper ? playerCopper - battle.minCopper() : copper);
				reduceCopper = Math.max(reduceCopper, 1);// 保底1铜币
				state.setCopper(reduceCopper);
				reducePlayerCopper(commandContext, target.playerId(), reduceCopper);
				battle.increaseTotalCopper(reduceCopper);
			}
		}
		commandContext.addAttackCount(1);
		commandContext.skillAction().addFirstTargetState(state);
	}

	private void reducePlayerCopper(CommandContext ctx, long playerId, int reduceCopper) {
		String desc = String.valueOf(ctx.battle().getId());
		sceneModeService.toInner().async(AppServerMode.Core.ordinal(), "coreinner.feeConsume", playerId, VirtualItemEnum.COPPER.ordinal(), reduceCopper, AppTraceTypes.MONKEY_STEAL_LOST, desc);
	}

	private long getPlayerCopper(long playerId) {
		return sceneModeService.toInner().sync(AppServerMode.Core.ordinal(), "coreinner.getCopper", playerId);
	}

	private int calcCopper(CommandContext ctx) {
		String formula = ctx.skill().getTargetSuccessHpEffect();
		if (StringUtils.isBlank(formula))
			return 0;
		MonkeyStealConfig mc = MonkeyStealConfig.getByRoundAndRandom(ctx.battle().getCount());
		if (mc == null)
			return 0;
		// lower = 0.015, upper = 1.0,先乘以1000变成整数,随机该范围内整数,除于1000,得到小数
		float f = RandomUtils.nextInt((int) (mc.getLower() * 1000), (int) (mc.getUpper() * 1000)) / 1000.f;
		Map<String, Object> params = new HashMap<>();
		params.put("ingotUnit", GameServerGradeManager.getInstance().ingotConvertCopper());
		params.put("factor", f);
		int v = ScriptService.getInstance().calcuInt("SkillLogic_14.calcCopper", formula, params, false);
		v = v < 0 ? 0 : v;
		return v;
	}
}
