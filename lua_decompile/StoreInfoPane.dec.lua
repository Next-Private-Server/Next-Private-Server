local MenuHelpers = include("MenuHelpers")
local Tab = {
  Sprite = {},
  Overlay = {},
  Touch = {},
  index = 0,
  selectedPriority = 0,
  deselectedPriority = 0
}
function Tab:new(obj)
  local obj = obj or {}
  setmetatable(obj, self)
  self.__index = self
  return obj
end
function Tab:setVisible()
  self.Sprite:GetVar("visible"):SetInt(1)
  self.Overlay:GetVar("visible"):SetInt(1)
  self.Touch:GetVar("enabled"):SetInt(1)
end
function Tab:setInvisible()
  self.Sprite:GetVar("visible"):SetInt(0)
  self.Overlay:GetVar("visible"):SetInt(0)
  self.Touch:GetVar("enabled"):SetInt(0)
end
function Tab:select()
  self:setOrientationPriority(self.selectedPriority)
  self.Sprite:setColor(1, 1, 1)
  self.Overlay:setColor(1, 1, 1)
end
function Tab:deselect()
  self:setOrientationPriority(self.deselectedPriority)
  self.Sprite:setColor(0.9, 0.9, 0.9)
  self.Overlay:setColor(0.75, 0.75, 0.75)
end
function Tab.Touch:onTouchUp(element)
  if element:parent().tabSelected ~= element.index then
    element:parent().tabSelected = element.index
    element:parent():selectNewTab()
  end
end
local StoreInfoPane = {
  bg = {},
  BioButton = {
    Touch = {}
  },
  IslandsButton = {},
  StatsButton = {},
  BoostsButton = {},
  MovesButton = {},
  ScrollMarker = {
    Touch = {}
  },
  ScrollBar = {},
  ObjectDesc = {
    Text = {},
    Touch = {},
    Swiper = {}
  },
  Islands = {
    Swiper = {},
    Touch = {}
  },
  Stats = {},
  MovesList = {},
  CostumeInfo = {},
  AdditionalBuyPrice = {},
  BuyButton = {},
  BuyPrice = {},
  IslandThemeBuyButton = {
    Text = {},
    UpSprite = {},
    Touch = {}
  },
  EventThemeBuyButton = {
    Touch = {}
  },
  BlackCover = {},
  FadeSprite = {},
  BotFadeSprite = {},
  Tab1 = Tab:new({
    index = 1,
    selectedPriority = -1,
    deselectedPriority = 1
  }),
  Tab2 = Tab:new({
    index = 2,
    selectedPriority = -2,
    deselectedPriority = 2
  }),
  Tab3 = Tab:new({
    index = 3,
    selectedPriority = -4,
    deselectedPriority = 2
  })
}
StoreInfoPane.clicked = -1
StoreInfoPane.allowClick = 1
StoreInfoPane.islandId = 0
StoreInfoPane.selectedItemId = -1
StoreInfoPane.tabSelected = 1
local ISLAND = -1
local PERMA_THEME = -1
local EVENT_THEME = -1
StoreInfoPane.eTabs = {}
StoreInfoPane.themeIds = {}
StoreInfoPane.names = {}
StoreInfoPane.animations = {}
StoreInfoPane.descriptions = {}
StoreInfoPane.boosts = {}
StoreInfoPane.lockedStatus = {}
StoreInfoPane.lockedText = {}
StoreInfoPane.availableStatus = {}
StoreInfoPane.ownedStatus = {}
StoreInfoPane.placementIds = {}
StoreInfoPane.showThemesTutorial = {}
function StoreInfoPane:onInit()
  self:setSearchChildren(false)
  self:GetVar("selectedThemeId"):SetInt(-1)
end
function StoreInfoPane:onPostInit()
  self.islandId = 0
  self:hideButtons()
  self:hideTabs()
  self.BuyButton:setInvisible()
  self.BuyPrice:setInvisible()
  self.bg:GetVar("alpha"):SetFloat(0)
  self:updateComponents()
end
function StoreInfoPane:clearTabData()
  ISLAND = -1
  PERMA_THEME = -1
  EVENT_THEME = -1
  local i = 1
  local tab = self:E("Tab" .. i)
  while tab ~= nil do
    tab:setInvisible()
    i = i + 1
    tab = self:E("Tab" .. i)
  end
  self.eTabs = {}
  self.themeIds = {}
  self.names = {}
  self.descriptions = {}
  self.animations = {}
  self.boosts = {}
  self.lockedStatus = {}
  self.lockedText = {}
  self.availableStatus = {}
  self.ownedStatus = {}
  self.placementIds = {}
  self.showThemesTutorial = {}
end
function StoreInfoPane:addTab(tabIndex, tabIcon, tabIconSheet, themeId, name, animation, bioStr, boostsStr, locked, lockedText, available, owned, placementId, showThemesTut)
  table.insert(self.eTabs, self:E("Tab" .. tabIndex))
  self:E("Tab" .. tabIndex).Overlay:GetVar("spriteName"):SetString(tabIcon)
  self:E("Tab" .. tabIndex).Overlay:GetVar("sheetName"):SetString(tabIconSheet)
  self.eTabs[tabIndex]:setVisible()
  self.eTabs[tabIndex]:GetVar("enabled"):SetInt(1)
  table.insert(self.themeIds, themeId)
  table.insert(self.names, name)
  table.insert(self.animations, animation)
  table.insert(self.descriptions, bioStr)
  table.insert(self.boosts, boostsStr)
  table.insert(self.lockedStatus, locked)
  table.insert(self.lockedText, lockedText)
  table.insert(self.availableStatus, available)
  table.insert(self.ownedStatus, owned)
  table.insert(self.placementIds, placementId)
  table.insert(self.showThemesTutorial, showThemesTut)
end
local getPermaThemePlacementId = function(islandid)
  if islandid == 1 then
    return "island_theme_plant"
  elseif islandid == 2 then
    return "island_theme_cold"
  elseif islandid == 3 then
    return "island_theme_air"
  elseif islandid == 4 then
    return "island_theme_water"
  elseif islandid == 5 then
    return "island_theme_earth"
  end
  return ""
end
local getEventThemePlacementId = function(islandid)
  if islandid == 1 then
    return "island_theme_hal"
  elseif islandid == 2 then
    return "island_theme_xmas"
  elseif islandid == 3 then
    return "island_theme_val"
  elseif islandid == 4 then
    return "island_theme_easter"
  elseif islandid == 5 then
    return "island_theme_summer"
  elseif islandid == 6 then
    return "island_theme_ann"
  elseif islandid == 13 then
    return "island_theme_thanks"
  elseif islandid == 17 then
    return "island_theme_dotd"
  elseif islandid == 19 then
    return "island_theme_newyear"
  end
  return ""
end
local function getPlacementId(tabId, islandid)
  if tabId == -1 then
    return ""
  elseif tabId == ISLAND then
    return ""
  elseif tabId == PERMA_THEME then
    return getPermaThemePlacementId(islandid)
  elseif tabId == EVENT_THEME then
    return getEventThemePlacementId(islandid)
  end
end
local function getBuyButtonTouch(touch, tabIndex)
  if tabIndex == PERMA_THEME then
    return touch.normalBuyActivateTheme
  elseif tabIndex == EVENT_THEME then
    return touch.trialActivateTheme
  end
  return nil
end
function StoreInfoPane:initIslandView()
  local tabIndex = #self.eTabs + 1
  ISLAND = tabIndex
  local tabIcon = "button_info2"
  local tabIconSheet = "xml_resources/context_buttons.xml"
  local themeId = -1
  local name = store:ItemTitle(self.selectedItemId)
  local animation = "island" .. self.islandId
  local bioStr = game.islandDescription(self.islandId)
  local boostsStr = ""
  local levelReq = 0
  local locked = levelReq > game.playerLevel() or not game.hasNecessaryPrevIslandsToUnlock(self.islandId)
  local lockedText = game.getLocalizedText("NOTIFICATION_REQUIRES_LEVEL")
  lockedText = select(1, lockedText:gsub("XXX", levelReq))
  local available = true
  local owned = game.isIslandOwned(self.islandId)
  local placement = ""
  if game.islandThemePlacementId ~= nil and themeId ~= -1 then
    placement = game.islandThemePlacementId(themeId)
  else
    placement = getPlacementId(tabIndex, self.islandId)
  end
  local showThemesTut = themeId ~= -1 and game.isIslandThemeUnlocked(themeId) and lua_sys.getPlatformName() ~= "pc"
  self:addTab(tabIndex, tabIcon, tabIconSheet, themeId, name, animation, bioStr, boostsStr, locked, lockedText, available, owned, placement, showThemesTut)
end
function StoreInfoPane:initTheme(tabIndex, tabIcon, tabIconSheet, themeIdsArr)
  local themeId = themeIdsArr[0]
  local name = game.islandThemeName(themeId)
  local animation = "island" .. self.islandId .. "_theme" .. themeId
  local levelReq = game.islandThemeRequiredLevel(themeId)
  local txt = game.islandThemeDesc(themeId)
  if levelReq > game.playerLevel() then
    txt = game.getLocalizedText("NOTIFICATION_REQUIRES_LEVEL")
    txt = select(1, txt:gsub("XXX", levelReq))
  end
  local boosts = game.islandThemeModifiers(themeId)
  if boosts ~= "" then
    boosts = boosts .. [[


]] .. game.getLocalizedText("THEME_FUNCTION_SUMMARY")
  end
  local locked = false
  local lockedText = ""
  local available = true
  if game.playerLevel() < game.islandThemeRequiredLevel(themeId) then
    locked = true
    lockedText = game.getLocalizedText("NOTIFICATION_REQUIRES_LEVEL")
    lockedText = select(1, lockedText:gsub("XXX", levelReq))
  elseif tabIndex == EVENT_THEME and not game.isTimedIslandThemeAvail(themeId) then
    available = false
  end
  local owned = game.isIslandThemeOwnedById(themeId)
  local placement = ""
  if game.islandThemePlacementId ~= nil and themeId ~= -1 then
    placement = game.islandThemePlacementId(themeId)
  else
    placement = getPlacementId(tabIndex, self.islandId)
  end
  local showThemesTut = themeId ~= -1 and not locked and game.hasOpenedThemesTab() == false and lua_sys.getPlatformName() ~= "pc"
  self:addTab(tabIndex, tabIcon, tabIconSheet, themeId, name, animation, txt, boosts, locked, lockedText, available, owned, placement, showThemesTut)
end
function StoreInfoPane:initPermaTheme()
  local tabIndex = #self.eTabs + 1
  local tabIcon = "news_islandskins"
  local tabIconSheet = "xml_resources/hud03.xml"
  if game.isIslandOwned(self.islandId) then
    local themeIdArr = game.getIslandThemeIds(self.islandId, false, false)
    if themeIdArr:size() > 0 then
      PERMA_THEME = tabIndex
      self:initTheme(tabIndex, tabIcon, tabIconSheet, themeIdArr)
    end
  end
end
function StoreInfoPane:initEventTheme()
  local tabIndex = #self.eTabs + 1
  local tabIcon = "news_seasonals"
  local tabIconSheet = "xml_resources/buttons02.xml"
  if game.isIslandOwned(self.islandId) then
    local themeIdArr = game.getIslandThemeIds(self.islandId, true, true)
    if themeIdArr:size() > 0 then
      EVENT_THEME = tabIndex
      self:initTheme(tabIndex, tabIcon, tabIconSheet, themeIdArr)
    end
  end
end
function StoreInfoPane:showButtons()
  if store:Category() == game.StoreCategories_TYPE_MONSTER or store:Category() == game.StoreCategories_TYPE_STARPOWER then
    local buttons = {}
    self.BioButton:setVisible()
    table.insert(buttons, self.BioButton)
    self.IslandsButton:setVisible()
    table.insert(buttons, self.IslandsButton)
    self.StatsButton:setVisible()
    table.insert(buttons, self.StatsButton)
    if game.isBattleIsland() then
      self.MovesButton:setVisible()
      table.insert(buttons, self.MovesButton)
    end
    self.BlackCover:setVisible()
    local offsetY = 6 * game.menuScaleX() + self.BlackCover:absH() - 1
    self.FadeSprite:GetVar("yOffset"):SetFloat(offsetY)
    self.ObjectDesc:setSize(lua_sys.Vector2(260 * game.menuScaleX(), 100 * game.menuScaleX()))
    MenuHelpers.CenterHorizontally(buttons)
  elseif store:Category() == game.StoreCategories_TYPE_ISLAND then
    local buttons = {}
    self.BioButton:setVisible()
    table.insert(buttons, self.BioButton)
    self.BoostsButton:setVisible()
    table.insert(buttons, self.BoostsButton)
    MenuHelpers.CenterHorizontally(buttons)
  end
end
function StoreInfoPane:hideButtons()
  self.BioButton:setInvisible()
  self.IslandThemeBuyButton:setInvisible()
  self.EventThemeBuyButton:setInvisible()
  self.IslandsButton:setInvisible()
  self.StatsButton:setInvisible()
  self.MovesButton:setInvisible()
  self.BoostsButton:setInvisible()
  self.BlackCover:setInvisible()
  local offsetY = 10 * game.menuScaleX()
  self.FadeSprite:GetVar("yOffset"):SetFloat(offsetY)
  self.ObjectDesc:setSize(lua_sys.Vector2(260 * game.menuScaleX(), 124 * game.menuScaleX()))
end
function StoreInfoPane:hideTabs()
  local i = 1
  local tab = self:E("Tab" .. i)
  while tab ~= nil do
    if i ~= 1 then
      tab:deselect()
    else
      tab:select()
    end
    i = i + 1
    tab = self:E("Tab" .. i)
  end
  local i = 1
  local tab = self:E("Tab" .. i)
  while tab ~= nil do
    tab:setInvisible()
    i = i + 1
    tab = self:E("Tab" .. i)
  end
end
function StoreInfoPane:showBio()
  self.BioButton:enable()
  self.BioButton.Touch:GetVar("enabled"):SetInt(0)
  if self.IslandsButton.UpSprite:GetVar("visible"):GetInt() == 1 then
    self.IslandsButton:disable()
    self.IslandsButton.Touch:GetVar("enabled"):SetInt(1)
  end
  if self.StatsButton.UpSprite:GetVar("visible"):GetInt() == 1 then
    self.StatsButton:disable()
    self.StatsButton.Touch:GetVar("enabled"):SetInt(1)
  end
  if game.isBattleIsland() and self.MovesButton.UpSprite:GetVar("visible"):GetInt() == 1 then
    self.MovesButton:disable()
    self.MovesButton.Touch:GetVar("enabled"):SetInt(1)
  end
  if self.BoostsButton.UpSprite:GetVar("visible"):GetInt() == 1 then
    self.BoostsButton:disable()
    self.BoostsButton.Touch:GetVar("enabled"):SetInt(1)
  end
  self.ObjectDesc:setVisible()
  if store:Category() == game.StoreCategories_TYPE_ISLAND then
    self.ObjectDesc.Text:GetVar("autoScale"):SetInt(0)
    self.ObjectDesc.Text:GetVar("size"):SetFloat(0.35 * game.hudScale())
    self.ObjectDesc.Text:GetVar("text"):SetString(self.descriptions[self.tabSelected])
    self.ObjectDesc.Text:GetVar("autoScale"):SetInt(1)
    self.ObjectDesc.Touch:GetVar("enabled"):SetInt(1)
  end
  self.ObjectDesc.Touch:GetVar("enabled"):SetInt(1)
  self.ObjectDesc.Swiper:refresh(self.ObjectDesc)
  self.ScrollMarker:GetVar("scrollSize"):SetFloat(self.ObjectDesc:GetVar("scrollSize"):GetFloat())
  if self.ObjectDesc.Text:absH() <= self.ObjectDesc:absH() then
    self.ScrollBar:setInvisible()
    self.ScrollMarker:setInvisible()
  else
    self.ScrollBar:setVisible()
    self.ScrollMarker:setVisible()
  end
  self.ObjectDesc.Swiper:resetScrollPos(self)
  self.Islands:setInvisible()
  self.Stats:setInvisible()
  self.MovesList:hide()
  self.CostumeInfo:hide()
  self.AdditionalBuyPrice:setInvisible()
end
function StoreInfoPane:showBoosts()
  self.BioButton:disable()
  self.BioButton.Touch:GetVar("enabled"):SetInt(1)
  if self.IslandsButton.UpSprite:GetVar("visible"):GetInt() == 1 then
    self.IslandsButton:disable()
    self.IslandsButton.Touch:GetVar("enabled"):SetInt(1)
  end
  if self.StatsButton.UpSprite:GetVar("visible"):GetInt() == 1 then
    self.StatsButton:disable()
    self.StatsButton.Touch:GetVar("enabled"):SetInt(1)
  end
  if game.isBattleIsland() and self.MovesButton.UpSprite:GetVar("visible"):GetInt() == 1 then
    self.MovesButton:disable()
    self.MovesButton.Touch:GetVar("enabled"):SetInt(1)
  end
  self.BoostsButton:enable()
  self.BoostsButton.Touch:GetVar("enabled"):SetInt(0)
  self.ObjectDesc:setVisible()
  self.ObjectDesc.Text:GetVar("autoScale"):SetInt(0)
  self.ObjectDesc.Text:GetVar("size"):SetFloat(0.35 * game.hudScale())
  self.ObjectDesc.Text:GetVar("text"):SetString(self.boosts[self.tabSelected])
  self.ObjectDesc.Text:GetVar("autoScale"):SetInt(1)
  self.ObjectDesc.Touch:GetVar("enabled"):SetInt(1)
  self.ObjectDesc.Swiper:refresh(self.ObjectDesc)
  self.ScrollMarker:GetVar("scrollSize"):SetFloat(self.ObjectDesc:GetVar("scrollSize"):GetFloat())
  if self.ObjectDesc.Text:absH() <= self.ObjectDesc:absH() then
    self.ScrollBar:setInvisible()
    self.ScrollMarker:setInvisible()
  else
    self.ScrollBar:setVisible()
    self.ScrollMarker:setVisible()
  end
  self.ObjectDesc.Swiper:resetScrollPos(self)
  self.Islands:setInvisible()
  self.Stats:setInvisible()
  self.MovesList:hide()
  self.CostumeInfo:hide()
  self.AdditionalBuyPrice:setInvisible()
end
function StoreInfoPane:showIslands()
  self.BioButton:disable()
  self.BioButton.Touch:GetVar("enabled"):SetInt(1)
  self.IslandsButton:enable()
  self.IslandsButton.Touch:GetVar("enabled"):SetInt(0)
  if self.StatsButton.UpSprite:GetVar("visible"):GetInt() == 1 then
    self.StatsButton:disable()
    self.StatsButton.Touch:GetVar("enabled"):SetInt(1)
  end
  if game.isBattleIsland() then
    self.MovesButton:disable()
    self.MovesButton.Touch:GetVar("enabled"):SetInt(1)
  end
  self.ObjectDesc:setInvisible()
  self.Islands:setVisible()
  self.Islands.Swiper:refresh(self.Islands)
  self.ScrollMarker:GetVar("scrollSize"):SetFloat(self.Islands.scrollSize)
  if self.Islands.contentHeight > self.bg:absH() then
    self.ScrollBar:setVisible()
    self.ScrollMarker:setVisible()
  else
    self.ScrollBar:setInvisible()
    self.ScrollMarker:setInvisible()
  end
  self.Stats:setInvisible()
  self.MovesList:hide()
  self.CostumeInfo:hide()
  self.AdditionalBuyPrice:setInvisible()
end
function StoreInfoPane:showStats()
  if self.BioButton.UpSprite:GetVar("visible"):GetInt() == 1 then
    self.BioButton:disable()
    self.BioButton.Touch:GetVar("enabled"):SetInt(1)
  end
  if self.IslandsButton.UpSprite:GetVar("visible"):GetInt() == 1 then
    self.IslandsButton:disable()
    self.IslandsButton.Touch:GetVar("enabled"):SetInt(1)
  end
  self.StatsButton:enable()
  self.StatsButton.Touch:GetVar("enabled"):SetInt(0)
  if game.isBattleIsland() then
    self.MovesButton:disable()
    self.MovesButton.Touch:GetVar("enabled"):SetInt(1)
  end
  self.ObjectDesc:setInvisible()
  self.Islands:setInvisible()
  self.Stats:setVisible()
  self.ScrollBar:setInvisible()
  self.ScrollMarker:setInvisible()
  self.MovesList:hide()
  self.CostumeInfo:hide()
  self.AdditionalBuyPrice:setInvisible()
end
function StoreInfoPane:showMoves()
  if self.BioButton.UpSprite:GetVar("visible"):GetInt() == 1 then
    self.BioButton:disable()
    self.BioButton.Touch:GetVar("enabled"):SetInt(1)
  end
  if self.IslandsButton.UpSprite:GetVar("visible"):GetInt() == 1 then
    self.IslandsButton:disable()
    self.IslandsButton.Touch:GetVar("enabled"):SetInt(1)
  end
  if self.StatsButton.UpSprite:GetVar("visible"):GetInt() == 1 then
    self.StatsButton:disable()
    self.StatsButton.Touch:GetVar("enabled"):SetInt(1)
  end
  self.MovesButton:enable()
  self.MovesButton.Touch:GetVar("enabled"):SetInt(0)
  self.ObjectDesc:setInvisible()
  self.Islands:setInvisible()
  self.Stats:setInvisible()
  self.ScrollBar:setInvisible()
  self.ScrollMarker:setInvisible()
  self.MovesList:DoStoredScript("show")
  self.CostumeInfo:hide()
  self.AdditionalBuyPrice:setInvisible()
end
function StoreInfoPane:showCostumeInfo()
  self.BioButton:disable()
  self.BioButton.Touch:GetVar("enabled"):SetInt(0)
  self.IslandsButton:disable()
  self.IslandsButton.Touch:GetVar("enabled"):SetInt(0)
  self.StatsButton:disable()
  self.StatsButton.Touch:GetVar("enabled"):SetInt(0)
  self.MovesButton:disable()
  self.MovesButton.Touch:GetVar("enabled"):SetInt(0)
  self.ObjectDesc:setInvisible()
  self.Islands:setInvisible()
  self.Stats:setInvisible()
  self.ScrollBar:setInvisible()
  self.ScrollMarker:setInvisible()
  self.MovesList:hide()
  self.CostumeInfo:DoStoredScript("show")
end
function StoreInfoPane:updateComponents()
  local alpha = self.bg:GetVar("alpha"):GetFloat()
  self.BuyButton.UpSprite:GetVar("alpha"):SetFloat(alpha)
  self.BuyButton.Text:GetVar("alpha"):SetFloat(alpha)
  self.ObjectDesc.Text:GetVar("alpha"):SetFloat(alpha)
  self.BuyPrice:GetVar("alpha"):SetFloat(alpha)
  self.BuyPrice:updateAlpha()
  self.AdditionalBuyPrice:GetVar("alpha"):SetFloat(alpha)
  self.AdditionalBuyPrice:updateAlpha()
  self.BlackCover.Sprite:GetVar("alpha"):SetFloat(alpha)
  self.FadeSprite.Sprite:GetVar("alpha"):SetFloat(alpha)
  self.BotFadeSprite.Sprite:GetVar("alpha"):SetFloat(alpha)
  self.BioButton:GetVar("alpha"):SetFloat(alpha)
  self.ScrollBar.Sprite:GetVar("alpha"):SetFloat(alpha)
  self.ScrollMarker.Marker:GetVar("alpha"):SetFloat(alpha)
  if alpha < 0.1 then
    self.ScrollMarker.Touch:GetVar("enabled"):SetInt(0)
  else
    self.ScrollMarker.Touch:GetVar("enabled"):SetInt(1)
  end
  self.BioButton:updateComponents()
  self.IslandsButton:GetVar("alpha"):SetFloat(alpha)
  self.IslandsButton:updateComponents()
  self.Islands:GetVar("alpha"):SetFloat(alpha)
  self.Islands:updateComponents()
  self.StatsButton:GetVar("alpha"):SetFloat(alpha)
  self.StatsButton:updateComponents()
  self.Stats:GetVar("alpha"):SetFloat(alpha)
  self.Stats:updateComponents()
  if game.isBattleIsland() then
    self.MovesButton:GetVar("alpha"):SetFloat(alpha)
    self.MovesButton:updateComponents()
    self.MovesList:GetVar("alpha"):SetFloat(alpha)
    self.MovesList:updateComponents()
  end
  self.BoostsButton:GetVar("alpha"):SetFloat(alpha)
  self.BoostsButton:updateComponents()
  self.IslandThemeBuyButton:GetVar("alpha"):SetFloat(alpha)
  self.IslandThemeBuyButton:updateComponents()
  self.EventThemeBuyButton:GetVar("alpha"):SetFloat(alpha)
  self.EventThemeBuyButton:updateComponents()
  if store:Category() == game.StoreCategories_TYPE_ISLAND then
    local i = 1
    local tab = self:E("Tab" .. i)
    while tab ~= nil do
      if i == ISLAND then
        tab.Sprite:GetVar("alpha"):SetFloat(alpha)
        tab.Overlay:GetVar("alpha"):SetFloat(alpha)
      elseif tab:GetVar("enabled"):GetInt() == 1 then
        tab.Sprite:GetVar("alpha"):SetFloat(alpha)
        tab.Overlay:GetVar("alpha"):SetFloat(alpha)
        if alpha > 0.1 then
          tab.Touch:GetVar("enabled"):SetInt(1)
        end
      end
      i = i + 1
      tab = self:E("Tab" .. i)
    end
  end
  self.CostumeInfo:GetVar("alpha"):SetFloat(alpha)
  self.CostumeInfo:updateAlpha()
end
function StoreInfoPane:initIslandTabs(islandId, selectedId)
  self.tabSelected = 1
  self.islandThemeBoosts = ""
  self.islandId = islandId
  self.selectedItemId = selectedId
  self:clearTabData()
  self:initIslandView()
  self:initPermaTheme()
  self:initEventTheme()
  lua_sys.playSoundFx("audio/sfx/menu_slide.wav")
  self:SetupGenericListener(game.engineReceiver(), "game::msg::MsgIslandThemePurchased", "gotMsgIslandThemePurchased")
  game.logEvent("store_island_info_init", "island_id", self.islandId)
  self:selectNewTab()
end
local function logTabClick(tabSelected, currentIsland)
  if tabSelected == PERMA_THEME then
    game.logEvent("store_island_info_theme_tab_click", "island_id", currentIsland)
  elseif tabSelected == EVENT_THEME then
  end
end
function StoreInfoPane:selectTab(tabIndex)
  for i = 1, #self.eTabs do
    if i ~= tabIndex then
      self.eTabs[i]:deselect()
    else
      self.eTabs[i]:select()
    end
  end
  self:populateTabView(self.tabSelected, self.themeIds[self.tabSelected], self.names[self.tabSelected], self.animations[self.tabSelected], self.descriptions[self.tabSelected], self.boosts[self.tabSelected], self.ownedStatus[self.tabSelected], self.lockedStatus[self.tabSelected], self.lockedText[self.tabSelected], self.availableStatus[self.tabSelected], self.showThemesTutorial[self.tabSelected])
  logTabClick(self.tabSelected, self.islandId)
end
function StoreInfoPane:selectNewTab()
  if self.tabSelected < 1 or #self.eTabs < self.tabSelected then
    self.tabSelected = 1
  end
  self:selectTab(self.tabSelected)
end
function StoreInfoPane:gotMsgIslandThemePurchased(msg)
  for i = 1, #self.themeIds do
    if self.themeIds[i] == msg.theme_id then
      self.ownedStatus[i] = true
    end
  end
  if msg.activateNow then
    if store:BuyItem() then
      game.loadWorldContext()
    end
  elseif msg.theme_id == self.themeIds[self.tabSelected] then
    self.IslandThemeBuyButton.Text:GetVar("text"):SetString("ACTIVATE_BUTTON")
    self.IslandThemeBuyButton:enable()
    self.EventThemeBuyButton:setInvisible()
  end
end
function StoreInfoPane:setLocked(lockedTxt)
  descText = lockedTxt
  store:SetSelectedLockVisibility(true)
  self.ObjectDesc:sizeForNoStats()
  self:hideButtons()
  self.IslandThemeBuyButton:disable()
  store:SetLockedAppearance(lockedTxt, true)
end
function StoreInfoPane:setUnavailable()
  store:SetSelectedLockVisibility(true)
  self.ObjectDesc:sizeForNoStats()
  self:hideButtons()
  self.IslandThemeBuyButton:setInvisible()
  self.EventThemeBuyButton:setInvisible()
  store:SetLockedAppearance("", true)
  store:SetTempAvailText("TIMED_EVENT_EXPIRED", "", false)
  local txt
  if game.islandThemeIsSeasonal(self.themeIds[self.tabSelected]) then
    txt = LOC("SEASONAL_SKIN_UNAVAILABLE")
    local eventStr = LOC(game.islandThemeSeasonAvailable(self.themeIds[self.tabSelected]))
    local monthStr = LOC(game.islandThemeMonthAvailable(self.themeIds[self.tabSelected]))
    txt = txt:gsub("XXX", eventStr)
    txt = txt:gsub("YYY", monthStr)
  else
    txt = LOC("SEASONAL_SKIN_UNAVAILABLE_GENERIC")
  end
  self.ObjectDesc.Text:GetVar("autoScale"):SetInt(0)
  self.ObjectDesc.Text:GetVar("size"):SetFloat(0.25 * game.menuScaleX())
  self.ObjectDesc.Text:GetVar("text"):SetString(txt)
  self.ObjectDesc.Text:GetVar("autoScale"):SetInt(1)
  self.ObjectDesc.Touch:GetVar("enabled"):SetInt(1)
  self.ObjectDesc.Swiper:refresh(self.ObjectDesc)
end
function StoreInfoPane:setNewlyUnavailable()
  self:setUnavailable()
  self.IslandThemeBuyButton:setVisible()
  self.IslandThemeBuyButton:disable()
  self.EventThemeBuyButton:setVisible()
  self.EventThemeBuyButton:disable()
  store:SetTempAvailText("TIMED_EVENT_EXPIRED", "", true)
end
function StoreInfoPane:populateTabView(tabIndex, themeId, name, animation, bio, boosts, owned, locked, lockedTxt, available, showThemesTut)
  if showThemesTut and game.hasOpenedThemesTab() == false and self.islandId ~= game.IslandType_GOLD then
    game.displayNotification("ISLAND_THEME_TUTORIAL")
    game.openedThemesTab()
  end
  self.EventThemeBuyButton:setInvisible()
  store:SetSelectedLockVisibility(false)
  store:SetTempAvailText("AVAILABLE_UNTIL", "", false)
  store:ChangeAnimation(animation)
  store:RenameSelectedItem(name)
  if tabIndex == ISLAND then
    self.IslandThemeBuyButton:setInvisible()
    self.BuyButton:setVisible()
    self.BuyButton:setEnable()
    self.BuyPrice:setVisible()
    if owned then
      self.BuyButton.Text:GetVar("text"):SetString(game.getLocalizedText("GO"))
      self.BuyPrice.Text:GetVar("text"):SetString("OWNED")
      self.BuyPrice.CurrencySprite:GetVar("visible"):SetInt(0)
    end
  else
    self.BuyButton:setInvisible()
    self.BuyPrice:setInvisible()
    self.IslandThemeBuyButton:setVisible()
    self.IslandThemeBuyButton:enable()
    local islandThemeBuyButtonTxt = "GET_LABEL"
    if owned then
      if game.isIslandThemeActiveById(self.islandId, themeId) then
        islandThemeBuyButtonTxt = game.getLocalizedText("DEACTIVATE_BUTTON")
      else
        islandThemeBuyButtonTxt = game.getLocalizedText("ACTIVATE_BUTTON")
      end
    else
      if tabIndex == EVENT_THEME then
        self.EventThemeBuyButton:setVisible()
        self.EventThemeBuyButton:enable()
        if game.isIslandThemeActiveById(self.islandId, themeId) then
          islandThemeBuyButtonTxt = game.getLocalizedText("DEACTIVATE_TRIAL_BUTTON")
        else
          islandThemeBuyButtonTxt = game.getLocalizedText("ACTIVATE_TRIAL_BUTTON")
        end
      end
      self.IslandThemeBuyButton.Touch.onTouchUp = getBuyButtonTouch(self.IslandThemeBuyButton.Touch, tabIndex)
      store:HideAnyCostElement(true)
    end
    self.IslandThemeBuyButton.Text:GetVar("text"):SetString(islandThemeBuyButtonTxt)
  end
  self.ObjectDesc:setVisible()
  self.ObjectDesc.Text:GetVar("autoScale"):SetInt(0)
  self.ObjectDesc.Text:GetVar("size"):SetFloat(0.25 * game.menuScaleX())
  self.ObjectDesc.Text:GetVar("text"):SetString(bio)
  self.ObjectDesc.Text:GetVar("autoScale"):SetInt(1)
  self.ObjectDesc.Touch:GetVar("enabled"):SetInt(1)
  self.ObjectDesc.Swiper:refresh(self.ObjectDesc)
  if boosts ~= "" then
    self.ObjectDesc:sizeForStats()
    self:showButtons()
  else
    self.ObjectDesc:sizeForNoStats()
    self:hideButtons()
    if tabIndex == EVENT_THEME and game.isTimedIslandThemeAvail(themeId) and self.islandId == game.IslandType_GOLD then
      self.IslandThemeBuyButton:setVisible()
      self.IslandThemeBuyButton:enable()
    end
  end
  if self.ObjectDesc.Text:absH() <= self.ObjectDesc:absH() then
    self.ScrollBar:setInvisible()
    self.ScrollMarker:setInvisible()
  else
    self.ScrollBar:setVisible()
    self.ScrollMarker:setVisible()
  end
  self:showBio()
  self.ObjectDesc.Swiper:refresh(self.ObjectDesc)
  self.ScrollMarker:GetVar("scrollSize"):SetFloat(self.ObjectDesc:GetVar("scrollSize"):GetFloat())
  self.ObjectDesc.Swiper:resetScrollPos(self)
  store:SetLockedAppearance("", false)
  if not owned then
    if locked then
      self:setLocked(lockedTxt)
    elseif tabIndex == EVENT_THEME and themeId ~= -1 then
      if available then
        if themeId ~= -1 and 0 >= game.timedAvailIslandThemeTimeRemaining(themeId) then
          self:setNewlyUnavailable()
        end
      else
        self:setUnavailable()
      end
    end
  else
    self.EventThemeBuyButton:setInvisible()
  end
end
function StoreInfoPane:onTick(dt)
  self.showingNewsFlashThisFrame = false
  if store:Category() == game.StoreCategories_TYPE_ISLAND and self.tabSelected ~= -1 and self.tabSelected == EVENT_THEME and self.themeIds[self.tabSelected] ~= -1 and not self.lockedStatus[self.tabSelected] and not self.ownedStatus[self.tabSelected] then
    local secondsRemaining = game.timedAvailIslandThemeTimeRemaining(self.themeIds[self.tabSelected])
    if secondsRemaining > 0 then
      if self.IslandThemeBuyButton.UpSprite.visible == 0 then
        self.IslandThemeBuyButton.Touch.onTouchUp = getBuyButtonTouch(self.IslandThemeBuyButton.Touch, self.tabSelected)
      end
      store:SetTempAvailText("AVAILABLE_UNTIL", game.timeToString(secondsRemaining, true), true)
    elseif self.IslandThemeBuyButton.Touch:GetVar("enabled"):GetInt() == 1 then
      self:setNewlyUnavailable()
    end
  end
end
function StoreInfoPane.ScrollMarker.Touch:onTouchDrag(element, x, y)
  local scrollBar = element:parent().ScrollBar
  local fromTopOfMarkerRange = y - scrollBar:absY() - element:GetVar("originalYOffset"):GetInt()
  local markerBookend = element:GetVar("originalYOffset"):GetInt()
  local scrollSize = element:GetVar("scrollSize"):GetFloat()
  local scrollOffset = -(fromTopOfMarkerRange - markerBookend) / (scrollBar:absH() - 2 * markerBookend - element:absH()) * scrollSize
  scrollOffset = clamp(scrollOffset, -scrollSize, 0)
  element:GetVar("scrollOffset"):SetFloat(scrollOffset)
  element:parent().ObjectDesc.Swiper:setScrollOffsetToMarker(element:parent().ObjectDesc)
  element:parent().Islands.Swiper:setScrollOffsetToMarker(element:parent().Islands)
end
function StoreInfoPane.ObjectDesc:sizeForStats()
  self:setSize(Vector2(self:absW(), 100 * game.menuScaleX()))
  local clipX = 0
  local clipY = (self:parent():absY() + 12 * game.menuScaleX()) * lua_sys.deviceScaleY()
  local clipW = lua_sys.screenWidth() * lua_sys.deviceScaleX()
  local clipH = (self:parent():absH() - 24 * game.menuScaleX()) * lua_sys.deviceScaleY()
  game.setClipping("Clipping", clipX, clipY, clipW, clipH)
end
function StoreInfoPane.ObjectDesc:sizeForNoStats()
  self:parent():showBio()
  self:setSize(Vector2(self:absW(), 100 * game.menuScaleX()))
  local clipX = 0
  local clipY = (self:parent():absY() + 12 * game.menuScaleX()) * lua_sys.deviceScaleY()
  local clipW = lua_sys.screenWidth() * lua_sys.deviceScaleX()
  local clipH = (self:parent():absH() - 24 * game.menuScaleX()) * lua_sys.deviceScaleY()
  game.setClipping("Clipping", clipX, clipY, clipW, clipH)
end
function StoreInfoPane.ObjectDesc:setVisible()
  self.Text:GetVar("visible"):SetInt(1)
  self.Touch:GetVar("enabled"):SetInt(1)
  self:parent().FadeSprite:setVisible()
  self:parent().BotFadeSprite:setVisible()
end
function StoreInfoPane.ObjectDesc:setInvisible()
  self.Text:GetVar("visible"):SetInt(0)
  self.Touch:GetVar("enabled"):SetInt(0)
  self:parent().FadeSprite:setInvisible()
  self:parent().BotFadeSprite:setInvisible()
end
function StoreInfoPane.ObjectDesc.Swiper:onPostInit(element)
  self:GetVar("direction"):SetInt(lua_sys.MenuSwipeComponent_SwipeDirectionVertical)
  self:GetVar("mode"):SetInt(lua_sys.MenuSwipeComponent_SwipeModeFree)
  self:GetVar("tSteps"):SetFloat(25)
  self:GetVar("mouseScrollSpeed"):SetFloat(1)
  self:refresh(element)
end
function StoreInfoPane.ObjectDesc.Swiper:refresh(element)
  self:listenToTouches(element)
  local itemHeight = element.Text:absH()
  local parentHeight = element:absH()
  if itemHeight > parentHeight then
    self:setScrollSize(itemHeight - parentHeight)
  else
    self:setScrollSize(0)
  end
  element:GetVar("scrollSize"):SetFloat(self:scrollSize())
end
local swiperApplies = function(element)
  return element:parent().BioButton.Touch:GetVar("enabled"):GetInt() == 0 or element:parent().BioButton.UpSprite:GetVar("visible"):GetInt() == 0 or element:parent().BoostsButton.Touch:GetVar("enabled"):GetInt() == 0 and element:parent().BoostsButton.UpSprite:GetVar("visible"):GetInt() == 1
end
function StoreInfoPane.ObjectDesc.Swiper:onTick(element, dt)
  if swiperApplies(element) then
    self:correctScrollMarkerPos(element)
  end
end
function StoreInfoPane.ObjectDesc.Swiper:correctScrollMarkerPos(element)
  if swiperApplies(element) then
    local first = element.Text
    if first then
      local scrollOffset = self:scrollOffset()
      if first:getOrientationPosition().y ~= scrollOffset then
        first:setOrientationPosition(lua_sys.Vector2(first:GetVar("xOffset"):GetInt(), scrollOffset))
      end
      local scrollMarker = element:parent().ScrollMarker
      local markerBookend = scrollMarker:GetVar("originalYOffset"):GetInt()
      local markerMovementHeight = element:parent().ScrollBar:absH() - 2 * markerBookend - scrollMarker:absH()
      local scrollMarkerYOffset = 0
      if self:scrollSize() ~= 0 then
        scrollMarkerYOffset = -(scrollOffset / self:scrollSize()) * markerMovementHeight
      end
      scrollMarkerYOffset = clamp(scrollMarkerYOffset, 0, markerMovementHeight)
      scrollMarker:GetVar("yOffset"):SetInt(markerBookend + scrollMarkerYOffset)
    end
  end
end
function StoreInfoPane.ObjectDesc.Swiper:setScrollOffsetToMarker(element)
  if swiperApplies(element) then
    self:setScrollOffset(element:parent().ScrollMarker:GetVar("scrollOffset"):GetFloat())
  end
end
function StoreInfoPane.ObjectDesc.Swiper:resetScrollPos(element)
  if swiperApplies(element) then
    self:setScrollOffset(0)
    self:correctScrollMarkerPos(element)
  end
end
local themeBuyButtonOnPostInit = function(element)
  element:setInvisible()
  element:SetupGenericListener(game.engineReceiver(), "game::msg::MsgPlacementInfo", "gotMsgPlacementInfo")
  element:SetupGenericListener(game.engineReceiver(), "game::msg::MsgPlacementInfoFail", "gotMsgPlacementInfoFail")
  element:SetupGenericListener(game.engineReceiver(), "game::msg::MsgPlacementImageFail", "gotMsgPlacementInfoFail")
  element:SetupGenericListener(game.engineReceiver(), "game::msg::MsgConfirmationSubmission", "gotMsgConfirmationSubmission")
end
local buyButtonConfSubmission = function(element, msg)
  if msg.messageID == "THEME_PACK_PURCHASE" and msg.choice == false then
    element:parent().allowClick = 1
    element:parent().BuyButton:enable()
  end
end
local buyPlacementInfoFail = function(element, msg)
  for i = 1, #element:parent().placementIds do
    if element:parent().placementIds[i] ~= "" and msg.name == element:parent().placementIds[i] then
      if element:parent().clicked == 0 then
        element:parent().allowClick = 1
        element:parent().clicked = 1
        txt = game.getLocalizedText("NOTIFICATION_BUY_THEME_PACK_1")
        txt = select(1, txt:gsub("XXX", game.getIslandThemePackPrice("island_theme", element:parent().themeIds[i])))
        element:parent():GetVar("selectedThemeId"):SetInt(element:parent().themeIds[i])
        game.displayConfirmation("THEME_PACK_PURCHASE", txt)
        element:parent().IslandThemeBuyButton:disable()
        element:parent().EventThemeBuyButton:disable()
      end
      break
    end
  end
end
local buyPlacementInfo = function(element, msg)
  if element:parent().showingNewsFlashThisFrame then
    return
  end
  for i = 1, #element:parent().placementIds do
    if element:parent().placementIds[i] ~= "" and msg.name == element:parent().placementIds[i] then
      print("NEWSFLASH", element:parent().placementIds[i])
      element:parent().allowClick = 1
      element:parent().showingNewsFlashThisFrame = true
      game.pushPopUp("newsflash")
      game.topPopUp():GetVar("placement"):SetString(element:parent().placementIds[i])
      game.topPopUp():DoStoredScript("setUpElements")
      break
    end
  end
end
function StoreInfoPane.IslandThemeBuyButton:onPostInit()
  themeBuyButtonOnPostInit(self)
end
function StoreInfoPane.IslandThemeBuyButton:gotMsgConfirmationSubmission(msg)
  if self:parent().tabSelected == PERMA_THEME then
    buyButtonConfSubmission(self, msg)
  end
end
function StoreInfoPane.IslandThemeBuyButton:gotMsgPlacementInfoFail(msg)
  if self:parent().tabSelected == PERMA_THEME then
    buyPlacementInfoFail(self, msg)
  end
end
function StoreInfoPane.IslandThemeBuyButton:gotMsgPlacementInfo(msg)
  if self:parent().tabSelected == PERMA_THEME then
    buyPlacementInfo(self, msg)
  end
end
local function logStoreBuyClick(element, tabSelected)
  if tabSelected == PERMA_THEME then
    game.logEvent("store_island_info_theme_buy_click", "island_id", element:parent().islandId)
  elseif tabSelected == EVENT_THEME then
  end
end
local function buyActivateShared(component, element)
  local themeId = element:parent().themeIds[element:parent().tabSelected]
  if themeId ~= -1 then
    if game.isIslandThemeOwnedById(themeId) then
      game.activateIslandTheme(themeId)
      store:BuyItem()
    elseif element:parent().allowClick == 1 then
      element:parent().clicked = 0
      if lua_sys.getPlatformName() == "pc" then
        local dlcAppId = game.getIslandThemePackSteamDLCAppId("island_theme", themeId)
        game.ShowAppInSteamStore(dlcAppId)
      else
        element:parent().allowClick = 0
        local placementId = element:parent().placementIds[element:parent().tabSelected]
        game.confirmThemeBuy(themeId, placementId)
      end
      logStoreBuyClick(element, element:parent().tabSelected)
    end
  end
end
function StoreInfoPane.IslandThemeBuyButton.Touch:normalBuyActivateTheme(element)
  self:super_onTouchUp(element)
  buyActivateShared(self, element)
end
function StoreInfoPane.IslandThemeBuyButton.Touch:trialActivateTheme(element)
  self:super_onTouchUp(element)
  if element:parent().themeIds[element:parent().tabSelected] ~= -1 then
    if element:parent().ownedStatus[element:parent().tabSelected] then
      game.activateIslandTheme(element:parent().themeIds[element:parent().tabSelected])
      if store:BuyItem() then
        game.loadWorldContext()
      end
      element:disable()
    else
      game.activateTrialIslandTheme(element:parent().themeIds[element:parent().tabSelected])
      element:disable()
    end
  end
end
function StoreInfoPane.IslandThemeBuyButton.Touch:onTouchUp(element)
  self:normalBuyActivateTheme(element)
end
function StoreInfoPane.EventThemeBuyButton:onPostInit()
  themeBuyButtonOnPostInit(self)
end
function StoreInfoPane.EventThemeBuyButton:gotMsgConfirmationSubmission(msg)
  if self:parent().tabSelected == EVENT_THEME then
    buyButtonConfSubmission(self, msg)
  end
end
function StoreInfoPane.EventThemeBuyButton:gotMsgPlacementInfoFail(msg)
  if self:parent().tabSelected == EVENT_THEME then
    buyPlacementInfoFail(self, msg)
  end
end
function StoreInfoPane.EventThemeBuyButton:gotMsgPlacementInfo(msg)
  if self:parent().tabSelected == EVENT_THEME then
    buyPlacementInfo(self, msg)
  end
end
local function logStoreBuyClick(element, tabSelected)
  if tabSelected == PERMA_THEME then
    game.logEvent("store_island_info_theme_buy_click", "island_id", element:parent().islandId)
  elseif tabSelected == EVENT_THEME then
  end
end
function StoreInfoPane.EventThemeBuyButton.Touch:normalBuyActivateTheme(element)
  self:super_onTouchUp(element)
  buyActivateShared(self, element)
end
function StoreInfoPane.EventThemeBuyButton.Touch:onTouchUp(element)
  self:normalBuyActivateTheme(element)
end
function StoreInfoPane.Islands:onInit()
  self.numIslands = 0
  self.contentHeight = 0
  self.scrollSize = 0
  self:setPositionBroadcast(true)
end
function StoreInfoPane.Islands:repopulate()
  for i = 0, self.numIslands - 1 do
    local islandEntry = self:E("islandEntry" .. i)
    if islandEntry then
      self:RemoveElement(islandEntry)
    end
  end
  local islands = game.getIslandsForMonster(store:MonsterTypeFromItemNum(self:parent()("ItemIndex"):GetInt()))
  local previous
  local width = 0
  local height = 0
  local itemHeight = 0
  self.numIslands = islands:size()
  for i = 0, islands:size() - 1 do
    local islandEntry = menu:addTemplateElement("template_monsterIslandEntry", "islandEntry" .. i, self)
    islandEntry("islandId"):SetInt(islands[i])
    islandEntry:setParent(self)
    if previous == nil then
      islandEntry:relativeTo(self)
      islandEntry:setOrientation(MenuOrientation(0, 0, 0, HCENTER, TOP))
      islandEntry:setRelativeObjectAnchors(HCENTER, TOP)
    else
      islandEntry:relativeTo(previous)
      islandEntry:setOrientation(MenuOrientation(0, 0, 0, HCENTER, TOP))
      islandEntry:setRelativeObjectAnchors(HCENTER, BOTTOM)
    end
    previous = islandEntry
    islandEntry:init()
    islandEntry:setPositionBroadcast(true)
    islandEntry:postInit()
    itemHeight = islandEntry:E("Overlay"):C("Sprite"):absH()
    height = height + itemHeight
    width = islandEntry:E("Overlay"):C("Sprite"):absW()
  end
  height = height + itemHeight / 2 + height / islands:size()
  self.contentHeight = height
  self:setSize(Vector2(width, height))
  self:setPositionBroadcast(true)
end
function StoreInfoPane.Islands:setVisible()
  self.Touch:GetVar("enabled"):SetInt(1)
  for i = 0, self.numIslands - 1 do
    local islandEntry = self:E("islandEntry" .. i)
    if islandEntry ~= nil then
      islandEntry:setVisible()
    end
  end
end
function StoreInfoPane.Islands:setInvisible()
  for i = 0, self.numIslands - 1 do
    local islandEntry = self:E("islandEntry" .. i)
    if islandEntry ~= nil then
      islandEntry:setInvisible()
    end
  end
  self.Touch("enabled"):SetInt(0)
end
function StoreInfoPane.Islands:updateComponents()
  local alpha = self("alpha"):GetFloat()
  for i = 0, self.numIslands - 1 do
    local islandEntry = self:E("islandEntry" .. i)
    if islandEntry ~= nil then
      islandEntry("alpha"):SetFloat(alpha)
      islandEntry:updateComponents()
    end
  end
  self:setPositionBroadcast(true)
end
function StoreInfoPane.Islands.Swiper:onPostInit(element)
  self:GetVar("direction"):SetInt(lua_sys.MenuSwipeComponent_SwipeDirectionVertical)
  self:GetVar("mode"):SetInt(MenuSwipeComponent_SwipeModeFree)
  self:GetVar("tSteps"):SetFloat(25)
  self:listenToTouches(element)
  self:refresh(element)
end
function StoreInfoPane.Islands.Swiper:refresh(element)
  local itemHeight = element.contentHeight
  local parentHeight = element:parent():C("bg"):absH()
  if itemHeight > parentHeight then
    self:setScrollSize(itemHeight - parentHeight)
  else
    self:setScrollSize(0)
  end
  element.scrollSize = self:scrollSize()
end
function StoreInfoPane.Islands.Swiper:onTick(element, dt)
  if element:parent().IslandsButton.Touch("enabled"):GetInt() == 0 and element:parent().IslandsButton.UpSprite("visible"):GetInt() == 1 then
    self:correctScrollMarkerPos(element)
  end
end
function StoreInfoPane.Islands.Swiper:correctScrollMarkerPos(element)
  if element:parent().IslandsButton.Touch("enabled"):GetInt() == 0 and element:parent().IslandsButton.UpSprite("visible"):GetInt() == 1 then
    local first = element:E("islandEntry0")
    if first then
      local offset = self:scrollOffset()
      if first:getOrientationPosition().y ~= offset then
        first:setOrientationPosition(Vector2(first("xOffset"):GetInt(), offset))
      end
      local scrollMarker = element:parent():E("ScrollMarker")
      local markerBookend = scrollMarker("originalYOffset"):GetInt()
      local markerMovementHeight = element:parent():E("ScrollBar"):absH() - 2 * markerBookend - scrollMarker:absH()
      local scrollMarkerYOffset = 0
      if self:scrollSize() ~= 0 then
        scrollMarkerYOffset = -(offset / self:scrollSize()) * markerMovementHeight
      end
      scrollMarkerYOffset = clamp(scrollMarkerYOffset, 0, markerMovementHeight)
      scrollMarker("yOffset"):SetInt(markerBookend + scrollMarkerYOffset)
    end
  end
end
function StoreInfoPane.Islands.Swiper:setScrollOffsetToMarker(element)
  if element:parent().IslandsButton.Touch("enabled"):GetInt() == 0 and element:parent().IslandsButton.UpSprite("visible"):GetInt() == 1 then
    self:setScrollOffset(element:parent():E("ScrollMarker")("scrollOffset"):GetFloat())
  end
end
function StoreInfoPane.Islands.Swiper:resetScrollPos(element)
  if element:parent().IslandsButton.Touch("enabled"):GetInt() == 0 and element:parent().IslandsButton.UpSprite("visible"):GetInt() == 1 then
    self:setScrollOffset(0)
    self:correctScrollMarkerPos(element)
  end
end
function StoreInfoPane.Stats:onInit()
  self.numStats = 0
end
function StoreInfoPane.Stats:repopulate()
  for i = 1, self.numStats do
    local statEntry = self:E("statEntry" .. i)
    if statEntry ~= nil then
      self:RemoveElement(statEntry)
    end
  end
  local previous, statsArray
  local selected = store:getSelected()
  local monsterId = store:MonsterTypeFromItemNum(self:parent()("ItemIndex"):GetInt())
  local monster = game.getMonsterData(monsterId)
  local isTitansoul = monster:isTitansoul()
  if isTitansoul then
    statsArray = {
      "template_stat_store_species",
      "template_stat_store_class",
      "template_stat_store_beds"
    }
  elseif game.isBattleIsland() then
    statsArray = {
      "template_stat_store_species",
      "template_stat_store_class",
      "template_stat_store_beds",
      "template_stat_store_battle_power",
      "template_stat_store_battle_stamina"
    }
  elseif game.isUnderlingIsland() or game.isCelestialIsland() or game.isMagicalNexusIsland() then
    statsArray = {
      "template_stat_store_species",
      "template_stat_store_class"
    }
  elseif game.isEtherealIslet() then
    statsArray = {
      "template_stat_store_species",
      "template_stat_store_class",
      "template_stat_store_coinrate",
      "template_stat_store_maxcoins"
    }
  elseif game.currentIsland() == game.IslandType_PAIRONORMAL then
    local island = game.player():getActiveIsland()
    if island and island:islandMode() == 1 then
      statsArray = {
        "template_stat_store_species",
        "template_stat_store_class",
        "template_stat_store_beds",
        "template_stat_underlingrate"
      }
    else
      print("showing major stats")
      statsArray = {
        "template_stat_store_species",
        "template_stat_store_class",
        "template_stat_store_beds",
        "template_stat_paironormal_currency_rate",
        "template_stat_paironormal_max_currency"
      }
    end
  else
    statsArray = {
      "template_stat_store_species",
      "template_stat_store_class",
      "template_stat_store_beds",
      "template_stat_store_coinrate",
      "template_stat_store_maxcoins"
    }
  end
  for i = 1, #statsArray do
    local statEntry = menu:addTemplateElement(statsArray[i], "statEntry" .. i, self)
    if previous == nil then
      statEntry:relativeTo(self)
      statEntry:setOrientation(MenuOrientation(0, 0, -1, HCENTER, TOP))
      statEntry:setRelativeObjectAnchors(HCENTER, TOP)
    else
      statEntry:relativeTo(previous)
      statEntry:setOrientation(MenuOrientation(0, 0, 0, HCENTER, TOP))
      statEntry:setRelativeObjectAnchors(HCENTER, BOTTOM)
    end
    statEntry("ItemIndex"):SetInt(self:parent()("ItemIndex"):GetInt())
    statEntry:init()
    statEntry:setPositionBroadcast(true)
    statEntry("alpha"):SetFloat(0)
    statEntry:DoStoredScript("updateComponents")
    previous = statEntry
  end
  self.numStats = #statsArray
end
function StoreInfoPane.Stats:setVisible()
  for i = 1, self.numStats do
    local statEntry = self:E("statEntry" .. i)
    if statEntry ~= nil then
      statEntry:setVisible()
    end
  end
end
function StoreInfoPane.Stats:setInvisible()
  for i = 1, self.numStats do
    local statEntry = self:E("statEntry" .. i)
    if statEntry ~= nil then
      statEntry:setInvisible()
    end
  end
end
function StoreInfoPane.Stats:updateComponents()
  local alpha = self("alpha"):GetFloat()
  for i = 1, self.numStats do
    local statEntry = self:E("statEntry" .. i)
    if statEntry ~= nil then
      statEntry("alpha"):SetFloat(alpha)
      statEntry:updateComponents()
    end
  end
  self:setPositionBroadcast(true)
end
return StoreInfoPane
