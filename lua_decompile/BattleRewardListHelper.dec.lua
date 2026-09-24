local BattleRewardListHelper = {}
function BattleRewardListHelper.Populate(element, reward)
  local rewardList = {}
  local costumeId = reward.costumeId or 0
  if costumeId > 0 then
    local costumeData = game.getCostumeData(costumeId)
    table.insert(rewardList, {
      name = "UNLOCKED_COSTUME",
      name2 = costumeData.name,
      costumeId = costumeId,
      animFile = game.getMonsterAnimationFileFromType(costumeData.monsterId),
      animName = game.getMonsterAnimationNameFromType(costumeData.monsterId),
      bgAnimFile = "glow.bin",
      bgAnimName = "glow"
    })
  end
  local trophy = reward.trophy or 0
  if trophy > 0 then
    table.insert(rewardList, {
      name = "NEW_TROPHY",
      name2 = "CHECK_MARKET",
      animFile = game.entityAnimFile(trophy),
      animName = game.entityAnimName(trophy),
      bgAnimFile = "glow.bin",
      bgAnimName = "glow"
    })
  end
  local diamonds = reward.diamonds or 0
  if diamonds > 0 then
    table.insert(rewardList, {
      name = diamonds,
      name2 = "DIAMONDS",
      value = diamonds,
      animFile = "battle_buttons_anim.bin",
      animName = "diamond pile",
      tint = {
        r = game.StoreContext_diamondColour.r,
        g = game.StoreContext_diamondColour.g,
        b = game.StoreContext_diamondColour.b
      }
    })
  end
  local relics = reward.relics or 0
  if relics > 0 then
    table.insert(rewardList, {
      name = relics,
      name2 = "RELICS",
      value = relics,
      animFile = "battle_buttons_anim.bin",
      animName = "relic pile",
      tint = {
        r = game.StoreContext_relicColour.r,
        g = game.StoreContext_relicColour.g,
        b = game.StoreContext_relicColour.b
      }
    })
  end
  local keys = reward.keys or 0
  if keys > 0 then
    table.insert(rewardList, {
      name = keys,
      name2 = "KEYS",
      value = keys,
      animFile = "battle_buttons_anim.bin",
      animName = "key pile",
      tint = {
        r = game.StoreContext_keyColour.r,
        g = game.StoreContext_keyColour.g,
        b = game.StoreContext_keyColour.b
      }
    })
  end
  local starpower = reward.starpower or 0
  if starpower > 0 then
    table.insert(rewardList, {
      name = starpower,
      name2 = "STARPOWER",
      value = starpower,
      animFile = "battle_buttons_anim.bin",
      animName = "starpower pile",
      tint = {
        r = game.StoreContext_starpowerColour.r,
        g = game.StoreContext_starpowerColour.g,
        b = game.StoreContext_starpowerColour.b
      }
    })
  end
  local food = reward.food or 0
  if food > 0 then
    table.insert(rewardList, {
      name = food,
      name2 = "CODE_REWARD_FOOD",
      value = food,
      animFile = "battle_buttons_anim.bin",
      animName = "food pile",
      tint = {
        r = game.StoreContext_foodColour.r,
        g = game.StoreContext_foodColour.g,
        b = game.StoreContext_foodColour.b
      }
    })
  end
  local medals = reward.medals or 0
  if medals > 0 then
    table.insert(rewardList, {
      name = medals,
      name2 = "MEDALS",
      animFile = "battle_buttons_anim.bin",
      animName = "metal pile",
      value = medals,
      tint = {
        r = game.StoreContext_medalColour.r,
        g = game.StoreContext_medalColour.g,
        b = game.StoreContext_medalColour.b
      }
    })
  end
  local xp = reward.xp or 0
  if xp > 0 then
    table.insert(rewardList, {
      name = xp,
      name2 = "XP",
      animFile = "battle_buttons_anim.bin",
      animName = "xp pile",
      value = xp,
      tint = {
        r = game.StoreContext_battleXpColour.r,
        g = game.StoreContext_battleXpColour.g,
        b = game.StoreContext_battleXpColour.b
      }
    })
  end
  local coins = reward.coins or 0
  if coins > 0 then
    table.insert(rewardList, {
      name = coins,
      name2 = "COINS",
      value = coins,
      animFile = "battle_buttons_anim.bin",
      animName = "coin pile",
      tint = {
        r = game.StoreContext_coinColour.r,
        g = game.StoreContext_coinColour.g,
        b = game.StoreContext_coinColour.b
      }
    })
  end
  print("unlockLimitedQuests:", reward.unlockLimitedQuests)
  local unlockLimitedQuests = reward.unlockLimitedQuests or false
  if unlockLimitedQuests then
    table.insert(rewardList, {
      name = LOC("REWARD_UNLOCKED"),
      name2 = LOC("LIMITED_QUESTS"),
      animFile = "battle_buttons_anim.bin",
      animName = "limited quests"
    })
  end
  print("unlockVersusMode:", reward.unlockVersusMode)
  local unlockVersusMode = reward.unlockVersusMode or false
  if unlockVersusMode then
    table.insert(rewardList, {
      name = LOC("REWARD_UNLOCKED"),
      name2 = LOC("VERSUS_MODE"),
      animFile = "battle_buttons_anim.bin",
      animName = "vs mode"
    })
  end
  local function createFunc(idx, itemName)
    local rewardListEntry = rewardList[idx + 1]
    local item = menu:addTemplateElement(rewardListEntry.template or "template_battle_campaign_reward_entry", itemName, element)
    item("ItemTitle"):SetString(rewardListEntry.name or "")
    item("ItemTitle2"):SetString(rewardListEntry.name2 or "")
    item("AnimationFile"):SetString(rewardListEntry.animFile or "")
    item("AnimationName"):SetString(rewardListEntry.animName or "")
    item("CostumeId"):SetInt(rewardListEntry.costumeId or 0)
    item("BgAnimationFile"):SetString(rewardListEntry.bgAnimFile or "")
    item("BgAnimationName"):SetString(rewardListEntry.bgAnimName or "")
    if not rewardListEntry.tint then
      local tint = {
        r = 1,
        g = 1,
        b = 1
      }
    end
    item("TintR"):SetFloat(tint.r)
    item("TintG"):SetFloat(tint.g)
    item("TintB"):SetFloat(tint.b)
    return item
  end
  include("ScrollingListHelper").ListPopulate(element, #rewardList, createFunc)
end
return BattleRewardListHelper
