local MenuHelpers = include("MenuHelpers")
local OffsetTransition = include("OffsetTransition")
local IslandMapData = include("IslandMapData")
local MapIslandListEntry = {
  BG = {
    Sprite = {}
  },
  Frame = {
    Sprite = {}
  },
  ActiveIndicator = {
    Sprite = {}
  },
  IslandName = {},
  Alert = {
    Sprite = {}
  },
  MonstersCollected = {},
  StatusStickers = {},
  Lock = {
    Sprite = {}
  },
  SaleIcon = {
    Sprite = {}
  },
  TorchIndicator = {},
  SeasonalIndicator = {},
  Requirements = {
    Text = {}
  },
  Cost = {},
  SaleCost = {},
  Touch = {},
  UpButton = {},
  DownButton = {}
}
local root
local CLUBBOX_MEMORY_ID = 1000000
function MapIslandListEntry:onInit()
  root = self
  self.alpha = 1
  self.entries = {}
  self.offsetTransition = OffsetTransition:new({
    startX = -32,
    endX = 0,
    onUpdate = function(x, y)
      self:GetVar("xOffset"):SetFloat(x)
    end
  })
end
function MapIslandListEntry:onPostInit()
  self.offsetTransition:SetOffset(-32, 0)
end
local hasConundrumReady = function(island)
  if island and island:hasStructureOfType(17) then
    local calendar = game.getDailyCumulativeLoginDataForIsland(island:id())
    if calendar.id > 0 and game.player():getDailyCumulativeLogin():calendar() >= calendar.id then
      local playerState = game.player():getDailyCumulativeLogin()
      if playerState:calendar() == calendar.id and game.serverTime() > playerState:nextCollect() then
        return true
      end
    end
  end
  return false
end
local hasClubbox = function(island)
  local currentClubboxActId = game.existingClubboxAct()
  if island and currentClubboxActId > 0 then
    local clubbox = game.player():getPlayerClubbox(currentClubboxActId)
    return clubbox and clubbox:islandId() == island:uniqueId()
  end
  return false
end
local isInSet = function(islandId, islandSet)
  for i = 1, #islandSet do
    if islandSet[i] == islandId then
      return true
    end
  end
  return false
end
local function getCollectIconForIsland(islandId, mode)
  if isInSet(islandId, {
    10,
    12,
    25
  }) then
    return "map_tag_collect_multi"
  end
  if isInSet(islandId, {22}) then
    return "map_tag_collect_relic"
  end
  if isInSet(islandId, {
    7,
    19,
    24,
    26,
    27,
    28,
    29
  }) then
    return "map_tag_collect_shard"
  end
  if islandId == game.IslandType_PAIRONORMAL then
    if mode == 1 then
      return "map_tag_collect_wildcard"
    end
    return "map_tag_collect_starpower"
  end
  return "map_tag_collect_coin"
end
local getDishHarmonizerIconForIsland = function(islandId)
  return "map_tag_dishharmonize_" .. game.GetIsletPrimaryGeneName(islandId)
end
local getNurseryIconForIsland = function(islandId)
  if islandId == game.IslandType_MAGICAL_NEXUS then
    return "map_tag_icons_orb"
  end
  return "map_tag_incubation"
end
local stickerData = {
  {
    img = getCollectIconForIsland,
    txt = "COLLECT_READY",
    fn = function(island, mode)
      return island:hasMonsterCollectReady(mode)
    end
  },
  {
    img = "map_tag_icons_conundra",
    txt = "CONUNDRA_READY",
    fn = hasConundrumReady
  },
  {
    img = "map_tag_castle",
    txt = "CASTLE_READY",
    fn = function(island)
      return island:hasCastleUpgradeReady()
    end
  },
  {
    img = "map_tag_upgrade",
    txt = "UPGRADE_READY",
    fn = function(island)
      return island:hasStructureUpgradeReady()
    end
  },
  {
    img = "map_tag_baking",
    txt = "BAKING_READY",
    fn = function(island)
      return island:hasBakeryReady()
    end
  },
  {
    img = "map_tag_breed",
    txt = "BREEDING_READY",
    fn = function(island, mode)
      return island:hasBreedingReady(mode)
    end
  },
  {
    img = "map_tag_synth",
    txt = "SYNTHESIS_READY",
    fn = function(island)
      return island:hasSynthesisReady()
    end
  },
  {
    img = "map_tag_attunement",
    txt = "ATTUNEMENT_READY",
    fn = function(island)
      return island:hasAttunementReady()
    end
  },
  {
    img = getDishHarmonizerIconForIsland,
    txt = "DISHHARMONIZER_READY",
    fn = function(island)
      return island:hasDishHarmonizerReady()
    end
  },
  {
    img = getNurseryIconForIsland,
    txt = "NURSERY_READY",
    fn = function(island, mode)
      return island:hasNurseryReady(mode)
    end
  },
  {
    img = "map_tag_mine",
    txt = "MINE_READY",
    fn = function(island)
      return island:hasMineReady()
    end
  },
  {
    img = "map_tag_training",
    txt = "TRAINING_READY",
    fn = function(island)
      return island:hasTrainingReady()
    end
  },
  {
    img = "map_tag_evolve_both",
    txt = "EVOLVING_READY",
    fn = function(island)
      return island:hasEvolutionReady()
    end
  },
  {
    img = "map_tag_expiration",
    txt = "ROTTEN_EGGS",
    fn = function(island)
      return island:hasRottenEggs()
    end
  },
  {
    img = "map_tag_icons_fuzer",
    txt = "FUZING_READY",
    fn = function(island)
      return island:hasFuzingReady()
    end
  },
  {
    img = "map_tag_fugue",
    txt = "FUGUEING_READY",
    fn = function(island)
      return island:hasFuguingReady()
    end
  },
  {
    img = "map_tag_clubbox",
    txt = "CLUBBOX",
    fn = hasClubbox
  }
}
local getStickerImage = function(stickerData, island, mode)
  if type(stickerData.img) == "string" then
    return stickerData.img
  else
    return stickerData.img(island, mode)
  end
end
function MapIslandListEntry:Setup(islandId, isMirrorMode, onSelectedCB, onMoveUpCB, onMoveDownCB, onTouchDragCB, onTouchDownCB, onTouchUpCB)
  local islandMode = 0
  if islandId == game.IslandType_PAIRONORMAL and isMirrorMode then
    islandMode = 1
  end
  self.islandMapData = IslandMapData:GetIslandData(islandId, islandMode)
  self.islandId = islandId
  self("IslandId"):SetInt(islandId)
  local islandType = game.islandType(islandId)
  self.onMoveUp = onMoveUpCB
  self.onMoveDown = onMoveDownCB
  self.onTDrag = onTouchDragCB
  self.onTDown = onTouchDownCB
  self.onTUp = onTouchUpCB
  self.onSelected = onSelectedCB
  self.BG.Sprite:GetVar("spriteName"):SetString(self.islandMapData:getTagSprite())
  self.BG.Sprite:GetVar("sheetName"):SetString(self.islandMapData:getTagSheet())
  local islandName = game.islandName(islandId)
  if islandId == CLUBBOX_MEMORY_ID then
    islandName = "CLUBBOX_MEMORY"
  end
  self.IslandName.Text:GetVar("text"):SetString(islandName)
  if game.mapContext():isFriendMode() then
    self.Cost:Hide()
    self.SaleCost:Hide()
    self.SaleIcon.Sprite:GetVar("visible"):SetInt(0)
    self.MonstersCollected.Text:GetVar("visible"):SetInt(0)
    self.Requirements.Text:GetVar("visible"):SetInt(0)
    self.isUnlocked = game.doesFriendOwnIsland(islandId)
    self.Lock.Sprite:GetVar("visible"):SetInt(self.isUnlocked and 0 or 1)
    self.showTorch = game.islandHasUnlitTorches(islandId)
    self.TorchIndicator:GetVar("visible"):SetInt(self.showTorch and 1 or 0)
    if game.doesFriendIslandHaveLightTorchFlag(islandId) then
      self.TorchIndicator:GetVar("spriteName"):SetString("button_light_torch_highlight")
    else
      self.TorchIndicator:GetVar("spriteName"):SetString("button_light_torch")
    end
    self.isFriendMode = true
    self.IslandName:GetVar("yOffset"):SetFloat(36 * game.mapScale())
    return
  end
  self.isFriendMode = false
  self.isUnlocked = game.isIslandOwned(islandId) or game.hasNecessaryPrevIslandsToUnlock(islandId) and game.canUnlockIsland(islandId) or islandId == CLUBBOX_MEMORY_ID
  self.isOwned = game.isIslandOwned(islandId) or islandId == CLUBBOX_MEMORY_ID
  if self.isOwned then
    self.Cost:Hide()
    self.SaleCost:Hide()
    self.SaleIcon.Sprite:GetVar("visible"):SetInt(0)
    self.Requirements.Text:GetVar("visible"):SetInt(0)
    local island = game.player():getIslandWithId(islandId)
    if islandType == game.IslandType_TRIBAL then
      self.MonstersCollected.Text:GetVar("noTranslate"):SetInt(1)
      self.MonstersCollected.Text:GetVar("text"):SetString(game.myTribeName())
    elseif islandType == game.IslandType_COMPOSER then
      self.MonstersCollected.Text:GetVar("visible"):SetInt(0)
    elseif islandId == CLUBBOX_MEMORY_ID then
      self.MonstersCollected.Text:GetVar("visible"):SetInt(0)
    else
      local monstersCollected = game.numUniqueMonstersCollectedOnIsland(islandId, islandMode)
      local totalMonstersToCollect = game.getAllUniqueMonsterTypesForIsland(islandId, islandMode)
      self.MonstersCollected.Text:GetVar("noTranslate"):SetInt(1)
      self.MonstersCollected.Text:GetVar("text"):SetString(monstersCollected .. "/" .. totalMonstersToCollect)
    end
    if island then
      local stickerRoot = self.StatusStickers
      self.stickers = {}
      local MAX_STICKERS = 5
      for i = 1, #stickerData do
        if stickerData[i].fn(island, islandMode) then
          local stickerEntry = menu:addTemplateElement("template_map_list_sticker", "sticker_" .. i, stickerRoot)
          stickerEntry:setParent(stickerRoot)
          stickerEntry:relativeTo(stickerRoot)
          stickerEntry:setOrientation(lua_sys.MenuOrientation(0, 0, -1, lua_sys.RIGHT, lua_sys.TOP))
          stickerEntry:setRelativeObjectAnchors(lua_sys.RIGHT, lua_sys.TOP)
          stickerEntry:calculatePosition()
          stickerEntry:init()
          stickerEntry.Sprite:GetVar("spriteName"):SetString(getStickerImage(stickerData[i], islandId, islandMode))
          stickerEntry:postInit()
          table.insert(self.stickers, stickerEntry)
          if MAX_STICKERS <= #self.stickers then
            break
          end
        end
      end
      MenuHelpers.ApplyHorizontalLayout(self.stickers)
    end
  else
    self.MonstersCollected.Text:GetVar("visible"):SetInt(0)
    if self.isUnlocked then
      self.showCost = true
      if self.showCost then
        if game.islandCost(islandId) == 0 then
          self.Cost.Text:GetVar("text"):SetString("FREE")
          self.Cost.Text:setColor(1, 1, 1)
          self.Cost.Sprite:GetVar("spriteName"):SetString("")
          self.Cost.Touch:GetVar("enabled"):SetInt(0)
          self.Cost:Refresh()
          self.SaleCost:Hide()
          self.SaleIcon.Sprite:GetVar("visible"):SetInt(0)
        else
          local currencyStr = game.islandCurrency(islandId)
          local cost = game.islandSale(islandId) and game.islandSaleCost(islandId) or game.islandCost(islandId)
          local costStr = game.commaizeNumber(cost)
          local currencySprite = game.StoreContext_getSpriteFromCurrencyTypeStr(currencyStr)
          self.Cost.Text:GetVar("text"):SetString(costStr)
          game.StoreContext_setCurrencyTypeColour(currencyStr, self.Cost.Text)
          self.Cost.Sprite:GetVar("spriteName"):SetString(currencySprite)
          self.Cost.Touch:GetVar("enabled"):SetInt(0)
          self.Cost:Refresh()
          self.showSale = game.islandSale(islandId)
          if self.showSale then
            local saleCostStr = game.commaizeNumber(game.islandCost(islandId))
            self.SaleCost:Show()
            self.SaleCost.Text:GetVar("text"):SetString(saleCostStr)
            game.StoreContext_setCurrencyTypeColour(currencyStr, self.SaleCost.Text)
            self.SaleCost.Sprite:GetVar("spriteName"):SetString(currencySprite)
            self.SaleCost:Refresh()
          else
            self.SaleCost:Hide()
            self.SaleIcon.Sprite:GetVar("visible"):SetInt(0)
          end
        end
      else
        self.Cost:Hide()
        self.SaleCost:Hide()
        self.SaleIcon.Sprite:GetVar("visible"):SetInt(0)
      end
      self.Requirements.Text:GetVar("visible"):SetInt(0)
    else
      self.Cost:Hide()
      self.SaleCost:Hide()
      self.SaleIcon.Sprite:GetVar("visible"):SetInt(0)
      if not game.hasNecessaryPrevIslandsToUnlock(islandId) then
        local txt = game.getLocalizedText("NOTIFICATION_REQUIRES_ITEM")
        txt = select(1, txt:gsub("XXX", game.getLocalizedText(game.islandName(game.islandLockIsland(islandId)))))
        self.Requirements.Text:GetVar("text"):SetString(txt)
      elseif islandId ~= game.IslandType_BATTLE then
        local txt = game.getLocalizedText("NOTIFICATION_REQUIRES_LEVEL")
        txt = select(1, txt:gsub("XXX", game.islandUnlockLevel(islandId)))
        self.Requirements.Text:GetVar("text"):SetString(txt)
      else
        local txt = game.getLocalizedText("BATTLE_ISLAND_LOCKED")
        txt = select(1, txt:gsub("XXX", game.islandUnlockLevel(islandId)))
        self.Requirements.Text:GetVar("text"):SetString(txt)
      end
    end
  end
  local islandSeasonalThemeData = self.islandMapData:getAvailableSeasonalThemeData()
  if islandSeasonalThemeData then
    self.SeasonalIndicator:GetVar("visible"):SetInt(1)
    self.SeasonalIndicator:GetVar("spriteName"):SetString(islandSeasonalThemeData.icon)
  else
    self.SeasonalIndicator:GetVar("visible"):SetInt(0)
  end
  self.Lock.Sprite:GetVar("visible"):SetInt(self.isUnlocked and 0 or 1)
  if not self.isUnlocked then
    self.Frame.Sprite:setColor(0.5, 0.5, 0.5)
    self.BG.Sprite:setColor(0.5, 0.5, 0.5)
  end
  local showTribalAlert = islandId == game.IslandType_TRIBAL and (1 < game.numIslands() or game.playerLevel() >= 10) and (game.newTribalInviteNotice() or game.newTribalRequestNotice())
  local showColdIslandAlert = islandId == game.IslandType_COLD and game.playerLevel() >= 6 and not game.isIslandOwned(game.IslandType_COLD) and game.playerCanAffordIsland(game.IslandType_COLD)
  if showTribalAlert or showColdIslandAlert then
    self.Alert.Sprite:GetVar("visible"):SetInt(1)
  end
  if islandId == game.currentIsland() then
    self.ActiveIndicator.Sprite:GetVar("visible"):SetInt(1)
  end
end
function MapIslandListEntry:SetSelected(selected)
  if selected then
    self.offsetTransition:Show()
  else
    self.offsetTransition:Hide()
  end
end
function MapIslandListEntry:onTick(dt)
  self.offsetTransition:Tick(dt)
end
function MapIslandListEntry.Touch:onInit(element)
  self.deltaY = 0
end
function MapIslandListEntry.Touch:onTouchDown(element, x, y)
  self.deltaY = 0
  if root.onTDown then
    root.onTDown(root.islandId, x, y)
  end
end
function MapIslandListEntry.Touch:onTouchUp(element)
  if self.deltaY < 10 and element.onSelected then
    element:onSelected()
  end
  if root.onTUp then
    root.onTUp()
  end
end
function MapIslandListEntry.Touch:onTouchRelease(element)
  if root.onTUp then
    root.onTUp()
  end
end
function MapIslandListEntry.Touch:onTouchDrag(element, x, y, relX, relY, dx, dy)
  self.deltaY = self.deltaY + math.abs(dy)
  if root.onTDrag then
    root.onTDrag(root.islandId, x, y, dx, dy)
  end
end
function MapIslandListEntry.UpButton:onTouch()
  if root.onMoveUp then
    root.onMoveUp(root.islandId)
  end
end
function MapIslandListEntry.DownButton:onTouch()
  if root.onMoveDown then
    root.onMoveDown(root.islandId)
  end
end
function MapIslandListEntry:showInfo()
  local islandType = game.islandType(self.islandId)
  if self.isOwned and islandType ~= game.IslandType_COMPOSER then
    self.MonstersCollected.Text:GetVar("visible"):SetInt(1)
  end
  if self.stickers then
    for _, v in pairs(self.stickers) do
      v.Sprite:GetVar("visible"):SetInt(1)
    end
  end
  if self.showCost then
    self.Cost:Show()
  end
  if self.showSale then
    self.SaleCost:Show()
    self.SaleIcon.Sprite:GetVar("visible"):SetInt(1)
  end
  self.Lock.Sprite:GetVar("visible"):SetInt(self.isUnlocked and 0 or 1)
  if not self.isFriendMode then
    self.Requirements.Text:GetVar("visible"):SetInt(self.isUnlocked and 0 or 1)
    self.Alert.Sprite:GetVar("visible"):SetInt(self.showAlert and 1 or 0)
  end
end
function MapIslandListEntry:hideInfo()
  self.MonstersCollected.Text:GetVar("visible"):SetInt(0)
  if self.stickers then
    for _, v in pairs(self.stickers) do
      v.Sprite:GetVar("visible"):SetInt(0)
    end
  end
  self.Cost:Hide()
  self.SaleCost:Hide()
  self.SaleIcon.Sprite:GetVar("visible"):SetInt(0)
  self.Requirements.Text:GetVar("visible"):SetInt(0)
  self.Lock.Sprite:GetVar("visible"):SetInt(0)
  self.Requirements.Text:GetVar("visible"):SetInt(0)
  self.Alert.Sprite:GetVar("visible"):SetInt(0)
end
return MapIslandListEntry
