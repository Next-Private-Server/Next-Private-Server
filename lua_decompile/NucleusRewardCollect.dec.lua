local OffsetTransition = include("MenuElementPositionOffsetTransition")
local MenuHelpers = include("MenuHelpers")
local NucleusRewardCollect = {}
function NucleusRewardCollect:onInit()
  OffsetTransition.OnInit(self:E("bg"), {
    startY = lua_sys.screenHeight() * 2,
    endY = 0,
    duration = 0.66
  })
  self:populateRewards()
  self:showMenu()
end
function NucleusRewardCollect:onTick(dt)
  local options = {
    ease = lua_sys.Quadratic_EaseIn,
    onDoneHide = function(e)
      e:root():popPopUp()
    end
  }
  OffsetTransition.OnTick(self:E("bg"), dt, options)
end
function NucleusRewardCollect:showMenu()
  OffsetTransition.Show(self:E("bg"))
  lua_sys.playSoundFx("audio/sfx/menu_slide.wav")
end
function NucleusRewardCollect:hideMenu()
  OffsetTransition.Hide(self:E("bg"))
  self:E("FadedBG"):DoStoredScript("hide")
  lua_sys.playSoundFx("audio/sfx/menu_slide.wav")
end
function NucleusRewardCollect:populateRewards()
  local rewardTypes = game.nucleusRewardTypes(game.highestNumNucleusMonsterSets())
  local root = self.bg
  local offsetY = 25 * game.hudScale()
  local entries = {}
  local rewardItems = 0
  for i = 0, rewardTypes:size() - 1 do
    if rewardTypes[i] ~= 0 then
      local rewardEntry = menu:addTemplateElement("template_nucleus_reward", "rewardEntry" .. rewardItems, root)
      table.insert(entries, rewardEntry)
      rewardEntry:relativeTo(root)
      rewardEntry:setRelativeObjectAnchors(lua_sys.HCENTER, lua_sys.VCENTER)
      rewardEntry:setOrientation(lua_sys.MenuOrientation(0, offsetY, -1, lua_sys.LEFT, lua_sys.VCENTER))
      local storeType = self:lootTypeToStoreType(rewardTypes[i])
      if storeType == "egg_wildcard" then
        rewardEntry.isAnimated = true
      else
        rewardEntry.isAnimated = false
      end
      rewardEntry("Icon"):SetString(game.StoreContext_getSpriteFromCurrencyTypeStr(storeType))
      rewardEntry("CurrencyType"):SetString(storeType)
      rewardEntry:init()
      rewardEntry:setPositionBroadcast(true)
      rewardEntry:postInit()
      rewardItems = rewardItems + 1
      if i < rewardTypes:size() - 1 then
        table.insert(entries, MenuHelpers.CreateSpacer(4 * game.menuScaleX(), 0))
      end
    end
  end
  MenuHelpers.CenterHorizontally(entries)
end
function NucleusRewardCollect:lootTypeToStoreType(lootType)
  if lootType == game.LootType_Shards then
    return game.StoreContext_TYPE_ETH_CURRENCY
  elseif lootType == game.LootType_Diamonds then
    return game.StoreContext_TYPE_DIAMOND
  elseif lootType == game.LootType_Food then
    return game.StoreContext_TYPE_FOOD
  elseif lootType == game.LootType_Keys then
    return game.StoreContext_TYPE_KEYS
  elseif lootType == game.LootType_EggWildcards then
    return game.StoreContext_TYPE_EGG_WILDCARD
  end
  return game.StoreContext_TYPE_ETH_CURRENCY
end
function NucleusRewardCollect:collect()
  lua_sys.playSoundFx("audio/sfx/structure_nucleus_collect.wav")
  game.collectNucleusReward()
  self:hideMenu()
end
return NucleusRewardCollect
