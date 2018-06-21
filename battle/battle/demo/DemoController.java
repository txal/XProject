/**
 * 
 */
package com.nucleus.logic.core.modules.demo;

import java.util.Set;

import org.apache.commons.lang3.StringUtils;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Controller;

import com.nucleus.commons.annotation.RequestType;
import com.nucleus.commons.exception.GeneralException;
import com.nucleus.commons.message.MultiGeneralController;
import com.nucleus.commons.utils.SplitUtils;
import com.nucleus.logic.core.modules.AppErrorCodes;
import com.nucleus.logic.core.modules.battle.data.Monster;
import com.nucleus.logic.core.modules.battle.data.Skill;
import com.nucleus.logic.core.modules.battle.manager.BattleManager;
import com.nucleus.logic.core.modules.battle.model.Battle;
import com.nucleus.logic.core.modules.battle.model.BattleTeam;
import com.nucleus.logic.core.modules.demo.dto.DemoMonsterConfigDto;
import com.nucleus.logic.core.modules.demo.model.DemoBattle;
import com.nucleus.logic.core.modules.demo.model.PlayerDemoInfoDto;
import com.nucleus.logic.core.modules.scene.manager.ScenePlayerManager;
import com.nucleus.logic.core.modules.scene.model.ScenePlayer;
import com.nucleus.logic.core.vo.BattleOverVo;
import com.nucleus.player.model.PlayerErrorCodes;

/**
 * @author liguo
 * 
 */
@Controller
public class DemoController extends MultiGeneralController {

	@Autowired
	private DemoService demoService;

	@Autowired
	private ScenePlayerManager playerManager;

	@Autowired
	private BattleManager battleManager;

	/**
	 * 获取玩家Demo信息
	 * 
	 * @return
	 */
	@RequestType(5)
	public PlayerDemoInfoDto playerDemoInfo() {
		ScenePlayer player = playerManager.getRequestPlayer();
		return demoService.playerInfoDto(player);
	}

	/**
	 * 更新敌人菜鸟属性值
	 * 
	 * @param configDto
	 *            怪物配置信息
	 */
	@RequestType(5)
	public void updateEnemyDummy(DemoMonsterConfigDto configDto) {
		if (configDto == null) {
			throw new GeneralException("属性不能为空", 0);
		}
		ScenePlayer player = playerManager.getRequestPlayer();
		PlayerDemoInfoDto infoDto = demoService.playerInfoDto(player);
		DemoMonsterConfigDto monsterInfo = infoDto.getMonsterInfo();
		if (StringUtils.isNotBlank(configDto.getAttack()))
			monsterInfo.setAttack(configDto.getAttack());
		if (StringUtils.isNotBlank(configDto.getDefense()))
			monsterInfo.setDefense(configDto.getDefense());
		if (StringUtils.isNotBlank(configDto.getHp()))
			monsterInfo.setHp(configDto.getHp());
		if (StringUtils.isNotBlank(configDto.getSpeed()))
			monsterInfo.setSpeed(configDto.getSpeed());
		if (StringUtils.isNotBlank(configDto.getMagic()))
			monsterInfo.setMagic(configDto.getMagic());

		if (configDto.getMonsterId() > 0 && configDto.getMonsterId() != monsterInfo.getMonsterId()) {
			Monster monster = Monster.get(configDto.getMonsterId());
			if (monster == null)
				throw new GeneralException(AppErrorCodes.MONSTER_BATTLE_GROUP_NOT_EXIST);
			monsterInfo.setMonsterId(configDto.getMonsterId());
			Monster newMonster = demoService.cloneObject(Monster.class, monster);
			monsterInfo.setMonster(newMonster);
		}
		Monster monster = monsterInfo.getMonster();
		monster.setSpeed(monsterInfo.getSpeed());
		monster.setAttack(monsterInfo.getAttack());
		monster.setDefense(monsterInfo.getDefense());
		monster.setHp(monsterInfo.getHp());
		monster.setMagic(monsterInfo.getMagic());

		if (StringUtils.isNotBlank(configDto.getActiveSkillIds())) {
			monsterInfo.setActiveSkillIds(configDto.getActiveSkillIds());
			monster.setActiveSkillsInfo(configDto.getActiveSkillIds());
			monster.resetBattleSkillHolder();
		}
		monsterInfo.setPassiveSkillIds(configDto.getPassiveSkillIds());
		Set<Integer> skillIds = SplitUtils.split2IntSet(configDto.getPassiveSkillIds(), ",");
		monster.battleSkillHolder().passiveSkills().clear();
		for (int skillId : skillIds) {
			Skill skill = Skill.get(skillId);
			monster.battleSkillHolder().addSkill(skill);
		}
	}

	/**
	 * 与菜鸟战斗
	 * 
	 * @param dummyNum
	 *            - 菜鸟数量
	 * @return
	 */
	@RequestType(5)
	public void fightDummy(int dummyNum) {
		if (dummyNum < 1 || dummyNum > 14)
			throw new GeneralException("菜鸟数量不能小于1或大于14", 0);
		ScenePlayer player = playerManager.getRequestPlayer();
		if (!player.teamStatus().battlable())
			throw new GeneralException(AppErrorCodes.NOT_BATTLABLE);
		PlayerDemoInfoDto info = demoService.playerInfoDto(player);
		if (info.getMonsterInfo() == null)
			throw new GeneralException(AppErrorCodes.MONSTER_BATTLE_GROUP_NOT_EXIST);
		Monster monster = info.getMonsterInfo().getMonster();
		if (monster == null)
			throw new GeneralException(AppErrorCodes.MONSTER_BATTLE_GROUP_NOT_EXIST);
		DemoBattle demoBattle = new DemoBattle(monster, dummyNum, player);
		demoBattle.start();
	}

	/**
	 * 退出战斗
	 */
	@RequestType(5)
	public void exitBattle() {
		ScenePlayer player = playerManager.getRequestPlayer();
		long playerId = player.getId();
		Battle battle = battleManager.battleByPlayer(playerId);
		if (null == battle)
			throw new GeneralException("没有战斗", 0);
		BattleTeam team = battle.battleInfo().battleTeam(playerId);
		if (null == team)
			throw new GeneralException("你不是队长，无法退出战斗", 0);
		/*
		 * if (team.playerIds().size() > 1) throw new GeneralException("正在组队，无法退出战斗", 0);
		 */
		new BattleOverVo(playerId).handle();
		/*
		 * battleManager.over(battle); PersistPlayer persistPlayer = player.persistPlayer(); player.dispatchEvent(new CharactorPropertyUpdateEvent(playerId, persistPlayer, true));
		 * PersistPlayerPet petCharactor = player.battlePet(); if (petCharactor != null) player.dispatchEvent(new CharactorPropertyUpdateEvent(playerId, petCharactor, true));
		 */
	}

	@RequestType(5)
	public void pvp(long targetPlayerId) {
		ScenePlayer player = playerManager.getRequestPlayer();
		ScenePlayer targetPlayer = playerManager.get(targetPlayerId);
		if (targetPlayer == null)
			throw new GeneralException(PlayerErrorCodes.PLAYER_NULL);
		DemoPvp battle = new DemoPvp(player, targetPlayer);
		battle.start();
	}
}
