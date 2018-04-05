/**
 * 
 */
package com.nucleus.logic.core.modules.battlebuff;

import java.util.HashMap;
import java.util.Map;

import org.springframework.stereotype.Service;

import com.nucleus.logic.core.modules.battle.dto.VideoActionTargetState;
import com.nucleus.logic.core.modules.battle.dto.VideoBuffRemoveTargetState;
import com.nucleus.logic.core.modules.battle.model.BattleSoldier;
import com.nucleus.logic.core.modules.battle.model.CommandContext;
import com.nucleus.logic.core.modules.battlebuff.model.BattleBuffEntity;
import com.nucleus.logic.core.modules.battlebuff.model.BuffLogicParam;
import com.nucleus.logic.core.modules.battlebuff.model.BuffLogicParam_25;
import com.nucleus.player.service.ScriptService;

/**
 * 伤害吸收，破裂反震
 * 
 * @author hwy
 *
 */
@Service
public class BattleBuffLogic_25 extends BattleBuffLogicAdapter {
	@Override
	protected BuffLogicParam newParam() {
		return new BuffLogicParam_25();
	}

	@Override
	public void beforeSkillFire(CommandContext commandContext, BattleBuffEntity buffEntity) {
		Map<String, Object> meta = buffEntity.getBattleMeta();
		// 没有相关buff记录就添加
		if (meta.isEmpty() || (!meta.containsKey("remainHp") && !meta.containsKey("reboundHp"))) {
			// 根据施法者算出技能等级与技能可承受的伤害
			int buffHp = gainBuffMaxHp(buffEntity, "beforeSkillFire");

			// 记录buff剩余可承受伤害和原始血量上限
			meta.put("remainHp", buffHp);
		}

		if (!meta.isEmpty() && meta.containsKey("remainHp")) {
			// 获取技能剩余可承受伤害
			int buffHp = (Integer) meta.getOrDefault("remainHp", 0);
			int damage = Math.abs(commandContext.getDamageOutput());
			int remainHp = buffHp - damage;

			int shareDamage = 0;
			if (remainHp <= 0) {
				BuffLogicParam_25 param = (BuffLogicParam_25) buffEntity.battleBuff().getBuffParam();
				int maxBuffHp = gainBuffMaxHp(buffEntity, "underAttack");
				meta.remove("remainHp");
				meta.put("reboundHp", (int) Math.floor(maxBuffHp * param.getRate()));
				shareDamage = remainHp;
			} else {
				meta.put("remainHp", remainHp);
			}

			// BattleSoldier trigger = buffEntity.getTriggerSoldier();
			// commandContext.skillAction().addTargetState(new VideoActionTargetState(trigger, shareDamage, 0, false));
			commandContext.setDamageOutput(shareDamage);
		}
	}

	@Override
	public void attackDead(CommandContext commandContext, BattleBuffEntity buffEntity) {
		buffRemove(commandContext, buffEntity);
	}

	@Override
	public void underAttack(CommandContext commandContext, BattleBuffEntity buffEntity) {
		buffRemove(commandContext, buffEntity);
	}

	private void buffRemove(CommandContext commandContext, BattleBuffEntity buffEntity) {
		Map<String, Object> meta = buffEntity.getBattleMeta();
		// buff破碎反伤处理
		if (!meta.isEmpty() && meta.containsKey("reboundHp")) {
			BattleSoldier attacker = commandContext.trigger();
			BattleSoldier target = buffEntity.getEffectSoldier();
			int reboundHp = (Integer) meta.getOrDefault("reboundHp", 0);
			meta.remove("reboundHp");

			attacker.decreaseHp(-reboundHp);
			commandContext.skillAction().addTargetState(new VideoActionTargetState(attacker, -reboundHp, 0, false));

			int buffId = buffEntity.battleBuffId();
			target.buffHolder().removeBuffById(buffId);
			commandContext.skillAction().addTargetState(new VideoBuffRemoveTargetState(target, buffId));
		}
	}

	/**
	 * 获取buff最大承受血量
	 * 
	 * @param buffEntity
	 * @param desc
	 * @return
	 */
	private int gainBuffMaxHp(BattleBuffEntity buffEntity, String desc) {
		BuffLogicParam_25 param = (BuffLogicParam_25) buffEntity.battleBuff().getBuffParam();
		BattleSoldier trigger = buffEntity.getTriggerSoldier();
		int skillId = buffEntity.skillId();
		int skillLevel = trigger.skillLevel(skillId);
		String formula = param.getFormule();
		Map<String, Object> params = new HashMap<String, Object>();
		params.put("skillLevel", skillLevel);
		int maxBuffHp = ScriptService.getInstance().calcuInt("BattleBuffLogic_25." + desc, formula, params, false);
		return maxBuffHp;
	}
}
