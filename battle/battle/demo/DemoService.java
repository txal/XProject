/**
 * 
 */
package com.nucleus.logic.core.modules.demo;

import java.beans.PropertyDescriptor;
import java.lang.reflect.Method;
import java.util.HashMap;
import java.util.Map;

import org.apache.commons.beanutils.PropertyUtils;
import org.springframework.stereotype.Service;

import com.nucleus.logic.core.modules.battle.data.Monster;
import com.nucleus.logic.core.modules.battle.data.Skill;
import com.nucleus.logic.core.modules.charactor.dto.CharactorDto;
import com.nucleus.logic.core.modules.demo.dto.DemoMonsterConfigDto;
import com.nucleus.logic.core.modules.demo.model.PlayerDemoInfoDto;
import com.nucleus.logic.core.modules.scene.model.ScenePlayer;

/**
 * @author liguo
 * 
 */
@Service
public class DemoService {

	private Map<Long, PlayerDemoInfoDto> playerInfosMap = new HashMap<Long, PlayerDemoInfoDto>();

	private PlayerDemoInfoDto createPlayerInfo(ScenePlayer player) {
		if (null == player) {
			return null;
		}
		int defaultEnemyDummyMonsterId = 100111;
		Monster src = Monster.get(defaultEnemyDummyMonsterId);
		Monster enemyDummyMonster = cloneObject(Monster.class, src);
		DemoMonsterConfigDto dto = new DemoMonsterConfigDto();
		dto.setMonsterId(enemyDummyMonster.getId());
		dto.setMonster(enemyDummyMonster);
		dto.setAttack(enemyDummyMonster.getAttack());
		dto.setDefense(enemyDummyMonster.getDefense());
		dto.setHp(enemyDummyMonster.getHp());
		dto.setSpeed(enemyDummyMonster.getSpeed());
		dto.setMagic(enemyDummyMonster.getMagic());
		dto.setActiveSkillIds(enemyDummyMonster.getActiveSkillsInfo());
		StringBuilder passiveSkillIds = new StringBuilder();
		for (Skill skill : enemyDummyMonster.battleSkillHolder().passiveSkills()) {
			passiveSkillIds.append(skill.getId()).append(",");
		}
		int idx = passiveSkillIds.lastIndexOf(",");
		if (idx != -1)
			passiveSkillIds.substring(0, idx);
		dto.setPassiveSkillIds(passiveSkillIds.toString());
		PlayerDemoInfoDto infoDto = new PlayerDemoInfoDto(player, null, dto);
		playerInfosMap.put(player.getId(), infoDto);
		return infoDto;
	}

	public void savePlayer(PlayerDemoInfoDto infoDto) {
		if (null == infoDto) {
			return;
		}
		playerInfosMap.put(infoDto.getPlayerId(), infoDto);
	}

	public PlayerDemoInfoDto playerInfoDto(ScenePlayer player) {
		if (null == player) {
			return null;
		}

		PlayerDemoInfoDto infoDto = playerInfosMap.get(player.getId());
		if (null == infoDto) {
			infoDto = createPlayerInfo(player);
		}
		infoDto.setPlayerCharactor(new CharactorDto(player.persistPlayer()));
		infoDto.getPlayerCharactor().setFactionId(player.factionId());
		return infoDto;
	}

	@SuppressWarnings("unchecked")
	public <T extends Object> T cloneObject(Class<?> clazz, T srcObject) {
		T clonedObject = null;
		try {
			clonedObject = (T) clazz.newInstance();
			for (PropertyDescriptor entityPd : PropertyUtils.getPropertyDescriptors(srcObject)) {
				String fieldName = entityPd.getName();
				if ("class".equals(fieldName)) {
					continue;
				}

				Method readMethod = entityPd.getReadMethod();
				if (null == readMethod) {
					continue;
				}

				Object fieldValue = readMethod.invoke(srcObject);
				PropertyDescriptor targetPd = PropertyUtils.getPropertyDescriptor(clonedObject, fieldName);

				Method writeMethod = targetPd.getWriteMethod();
				if (null == writeMethod) {
					continue;
				}

				writeMethod.invoke(clonedObject, fieldValue);
			}
		} catch (Exception e) {
			e.printStackTrace();
		}

		return clonedObject;
	}
}
