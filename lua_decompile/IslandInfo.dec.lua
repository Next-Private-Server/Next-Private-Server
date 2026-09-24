local ISLAND = -1
local RANKING = -1
local PERMA_THEME = -1
local EVENT_THEME = -1
local IslandInfoTab = {
  Overlay = {
    Touch = {}
  },
  index = 0
}
function IslandInfoTab:new(obj)
  local obj = obj or {}
  setmetatable(obj, self)
  self.__index = self
  return obj
end
function IslandInfoTab:selectTab()
  self:setOrientationPriority(-1)
  self.Sprite:setColor(1, 1, 1)
  self.Overlay.Sprite:setColor(1, 1, 1)
end
function IslandInfoTab:deselectTab()
  self:setOrientationPriority(self.index)
  self.Sprite:setColor(0.9, 0.9, 0.9)
  self.Overlay.Sprite:setColor(0.75, 0.75, 0.75)
end
function IslandInfoTab.Overlay.Touch:onTouchUp(element)
  local tab = element:parent()
  local islandInfo = tab:parent()
  if islandInfo.tabSelected ~= tab.index then
    islandInfo.tabSelected = tab.index
    islandInfo:selectNewTab()
    if islandInfo.tabSelected == PERMA_THEME then
      game.logEvent("popup_island_info_theme_tab_click", "island_id", islandInfo.currentIsland)
    elseif islandInfo.tabSelected == EVENT_THEME then
    end
  end
end
local BuyButtonBase = {
  UpSprite = {},
  Touch = {}
}
function BuyButtonBase:new(obj)
  local obj = obj or {}
  setmetatable(obj, self)
  self.__index = self
  return obj
end
local EventThemeBuyButtonBase = {
  UpSprite = {},
  Touch = {}
}
function EventThemeBuyButtonBase:new(obj)
  local obj = obj or {}
  setmetatable(obj, self)
  self.__index = self
  return obj
end
local IslandInfo = {
  FadedBG = {},
  bg = {},
  FadeSprite = {},
  BotFadeSprite = {},
  IslandDescription = {
    Text = {},
    Touch = {},
    Swiper = {}
  },
  BioButton = {},
  BoostsButton = {},
  ScrollBar = {},
  ScrollMarker = {
    Touch = {}
  },
  Icon = {},
  BuyButton = BuyButtonBase:new(),
  IconFrame = {},
  EventThemeBuyButton = EventThemeBuyButtonBase:new(),
  LevelReq = {},
  TempAvailText = {},
  Tab1 = IslandInfoTab:new({index = 1}),
  Tab2 = IslandInfoTab:new({index = 2}),
  Tab3 = IslandInfoTab:new({index = 3}),
  Tab4 = IslandInfoTab:new({index = 4}),
  transitionState = 1,
  transitionTime = 0,
  clicked = -1,
  allowClick = 1,
  currentIsland = -1,
  tabSelected = 1,
  visibleTabs = {},
  curThemeIds = {},
  names = {},
  animations = {},
  bios = {},
  boosts = {},
  levelReqs = {},
  lockedStatus = {},
  lockedText = {},
  availableStatus = {},
  ownedStatus = {},
  placementIds = {},
  showThemesTutorial = {},
  buyButtonText = {}
}
local permaThemePlacementIds = {}
permaThemePlacementIds[1] = "island_theme_plane"
permaThemePlacementIds[2] = "island_theme_cold"
permaThemePlacementIds[3] = "island_theme_air"
permaThemePlacementIds[4] = "island_theme_water"
permaThemePlacementIds[5] = "island_theme_earth"
local function getPermaThemePlacementId(islandId)
  return permaThemePlacementIds[islandId] or ""
end
local eventThemePlacementIds = {}
eventThemePlacementIds[1] = "island_theme_hal"
eventThemePlacementIds[2] = "island_theme_xmas"
eventThemePlacementIds[3] = "island_theme_val"
eventThemePlacementIds[4] = "island_theme_easter"
eventThemePlacementIds[5] = "island_theme_summer"
eventThemePlacementIds[6] = "island_theme_ann"
eventThemePlacementIds[13] = "island_theme_thanks"
eventThemePlacementIds[17] = "island_theme_dotd"
eventThemePlacementIds[19] = "island_theme_newyear"
local function getEventThemePlacementId(islandId)
  return eventThemePlacementIds[islandId] or ""
end
local function getPlacementId(tabId, islandid)
  if tabId == PERMA_THEME then
    return getPermaThemePlacementId(islandid)
  elseif tabId == EVENT_THEME then
    return getEventThemePlacementId(islandid)
  else
    return ""
  end
end
function IslandInfo:addTab(tabIndex, tabIcon, tabIconSheet, themeId, nameStr, animationStr, bioStr, boostStr, levelReq, lockedStatus, lockedText, available, ownedStatus, placementId, showThemesTut, buyButtonTxt)
  local tab = self:GetElement("Tab" .. tabIndex)
  table.insert(self.visibleTabs, tab)
  tab.Overlay.Sprite:GetVar("spriteName"):SetString(tabIcon)
  tab.Overlay.Sprite:GetVar("sheetName"):SetString(tabIconSheet)
  tab:setVisible()
  table.insert(self.curThemeIds, themeId)
  table.insert(self.names, nameStr)
  table.insert(self.animations, animationStr)
  table.insert(self.bios, bioStr)
  table.insert(self.boosts, boostStr)
  table.insert(self.levelReqs, levelReq)
  table.insert(self.lockedStatus, lockedStatus)
  table.insert(self.lockedText, lockedText)
  table.insert(self.availableStatus, available)
  table.insert(self.ownedStatus, ownedStatus)
  table.insert(self.placementIds, placementId)
  table.insert(self.showThemesTutorial, showThemesTut)
  table.insert(self.buyButtonText, buyButtonTxt)
end
local function getBuyButtonText(tabIndex, themeId, owned, currentIsland, locked)
  local buyButtonText = "GET_LABEL"
  if themeId ~= -1 then
    if not locked then
      if owned then
        if game.isIslandThemeActiveById(currentIsland, themeId) then
          buyButtonText = game.getLocalizedText("DEACTIVATE_BUTTON")
        else
          buyButtonText = game.getLocalizedText("ACTIVATE_BUTTON")
        end
      elseif tabIndex == EVENT_THEME then
        if game.isIslandThemeActiveById(currentIsland, themeId) then
          buyButtonText = game.getLocalizedText("DEACTIVATE_TRIAL_BUTTON")
        else
          buyButtonText = game.getLocalizedText("ACTIVATE_TRIAL_BUTTON")
        end
      end
    else
      buyButtonText = ""
    end
  else
    buyButtonText = ""
  end
  return buyButtonText
end
local function getBuyButtonTouch(touch, tabIndex)
  if tabIndex == PERMA_THEME then
    return touch.normalBuyActivate
  elseif tabIndex == EVENT_THEME then
    return touch.trialActivate
  end
  return nil
end
local getBuyActivate = function(touch)
  return touch.normalBuyActivate
end
function IslandInfo:initIslandView()
  local tabIndex = #self.visibleTabs + 1
  ISLAND = tabIndex
  local tabIcon = "button_info2"
  local tabIconSheet = "xml_resources/context_buttons.xml"
  local curThemeId = -1
  local island = game.currentPlayer():getIslandWithId(self.currentIsland)
  local islandMode = island and island:islandMode() or 0
  local nameStr = game.islandName(self.currentIsland)
  if self.currentIsland == game.IslandType_PAIRONORMAL then
    if islandMode == 0 then
      nameStr = "ISLAND_31_MAJ"
    else
      nameStr = "ISLAND_31_MIN"
    end
  end
  local bioStr = game.islandDescription(self.currentIsland)
  local animation = "island" .. self.currentIsland
  if self.currentIsland == game.IslandType_PAIRONORMAL and islandMode == 1 then
    animation = animation .. "_MIN"
  end
  local boostStr = self:getThemeBoostStr(curThemeId)
  local levelReq = game.islandUnlockLevel(self.currentIsland)
  local locked = levelReq > game.playerLevel() or not game.hasNecessaryPrevIslandsToUnlock(self.currentIsland)
  local lockedText = game.getLocalizedText("NOTIFICATION_REQUIRES_LEVEL")
  lockedText = select(1, lockedText:gsub("XXX", levelReq))
  local available = true
  local owned = curThemeId == -1 or game.isIslandThemeOwnedById(curThemeId)
  local placementId = ""
  local showThemesTut = false
  local buyButtonText = getBuyButtonText(tabIndex, curThemeId, owned, self.currentIsland, locked)
  self:addTab(tabIndex, tabIcon, tabIconSheet, curThemeId, nameStr, animation, bioStr, boostStr, levelReq, locked, lockedText, available, owned, placementId, showThemesTut, buyButtonText)
end
function IslandInfo:initRankingView()
  local tabIndex = #self.visibleTabs + 1
  RANKING = tabIndex
  local tabIcon = "button_thumbsup"
  local tabIconSheet = "xml_resources/context_buttons.xml"
  local curThemeId = -1
  local nameStr = game.islandName(self.currentIsland)
  local bioStr = ""
  local animation = "island" .. self.currentIsland
  local boostStr = ""
  local levelReq = game.islandUnlockLevel(self.currentIsland)
  local locked = levelReq > game.playerLevel() or not game.hasNecessaryPrevIslandsToUnlock(self.currentIsland)
  local lockedText = game.getLocalizedText("NOTIFICATION_REQUIRES_LEVEL")
  lockedText = select(1, lockedText:gsub("XXX", levelReq))
  local available = true
  local owned = curThemeId == -1 or game.isIslandThemeOwnedById(curThemeId)
  local placementId = ""
  local showThemesTut = false
  local buyButtonText = getBuyButtonText(tabIndex, curThemeId, owned, self.currentIsland, locked)
  self:addTab(tabIndex, tabIcon, tabIconSheet, curThemeId, nameStr, animation, bioStr, boostStr, levelReq, locked, lockedText, available, owned, placementId, showThemesTut, buyButtonText)
end
function IslandInfo:getIslandThemeIds(limited)
  if not limited then
    return game.getIslandThemeIds(self.currentIsland, false, false)
  else
    return game.getIslandThemeIds(self.currentIsland, true, true)
  end
end
function IslandInfo:getThemeBoostStr(curThemeId)
  if curThemeId ~= -1 then
    return game.islandThemeModifiers(curThemeId)
  end
  return ""
end
function IslandInfo:initTheme(tabIndex, tabIcon, tabIconSheet, themeIdsArr, showThemesTut)
  local curThemeId = -1
  local nameStr = ""
  local animation = ""
  local bioStr = ""
  local boostStr = ""
  local levelReq = 1
  local locked = true
  local lockedText = ""
  local available = true
  local owned = false
  local buyButtonText = ""
  if themeIdsArr ~= nil and themeIdsArr:size() > 0 then
    curThemeId = themeIdsArr[0]
    nameStr = game.islandThemeName(curThemeId)
    animation = "island" .. self.currentIsland .. "_theme" .. curThemeId
    boostStr = self:getThemeBoostStr(curThemeId)
    if boostStr ~= "" then
      boostStr = boostStr .. [[


]] .. game.getLocalizedText("THEME_FUNCTION_SUMMARY")
    end
    levelReq = game.islandThemeRequiredLevel(curThemeId)
    locked = not game.isIslandThemeUnlocked(curThemeId)
    local txt = game.islandThemeDesc(curThemeId)
    if game.tutorialDisableExtraFeatures() then
      locked = true
      txt = game.getLocalizedText("TUTORIAL_LOCKED_FEATURE")
    elseif game.playerLevel() < game.islandThemeRequiredLevel(curThemeId) then
      locked = true
      lockedText = game.getLocalizedText("NOTIFICATION_REQUIRES_LEVEL")
      lockedText = select(1, lockedText:gsub("XXX", levelReq))
      txt = lockedText
    elseif tabIndex == EVENT_THEME and not game.isTimedIslandThemeAvail(curThemeId) then
      available = false
    end
    bioStr = txt
    owned = curThemeId == -1 or game.isIslandThemeOwnedById(curThemeId)
    buyButtonText = getBuyButtonText(tabIndex, curThemeId, owned, self.currentIsland, locked)
  end
  local placementId = ""
  if game.islandThemePlacementId and curThemeId ~= -1 then
    placementId = game.islandThemePlacementId(curThemeId)
  else
    placementId = getPlacementId(tabIndex, self.currentIsland)
  end
  if locked then
    showThemesTut = false
  end
  self:addTab(tabIndex, tabIcon, tabIconSheet, curThemeId, nameStr, animation, bioStr, boostStr, levelReq, locked, lockedText, available, owned, placementId, showThemesTut, buyButtonText)
end
function IslandInfo:initPermaTheme()
  local tabIndex = #self.visibleTabs + 1
  local tabIcon = "news_islandskins"
  local tabIconSheet = "xml_resources/hud03.xml"
  local themeIdsArr = self:getIslandThemeIds(false)
  local showThemesTut = true
  if themeIdsArr and themeIdsArr:size() > 0 then
    PERMA_THEME = tabIndex
    self:initTheme(tabIndex, tabIcon, tabIconSheet, themeIdsArr, showThemesTut)
  end
end
function IslandInfo:initEventTheme()
  local tabIndex = #self.visibleTabs + 1
  local tabIcon = "news_seasonals"
  local tabIconSheet = "xml_resources/buttons02.xml"
  local themeIdsArr = self:getIslandThemeIds(true)
  local showThemesTut = false
  if themeIdsArr and themeIdsArr:size() > 0 then
    EVENT_THEME = tabIndex
    self:initTheme(tabIndex, tabIcon, tabIconSheet, themeIdsArr, showThemesTut)
    self("eventThemeTabName"):SetString("Tab" .. tabIndex)
  end
end
function IslandInfo:onInit()
  self.currentIsland = game.currentIsland()
  local i = 1
  local tab = self:GetElement("Tab" .. i)
  while tab do
    tab:setInvisible()
    i = i + 1
    tab = self:GetElement("Tab" .. i)
  end
  self:initIslandView()
  self:initRankingView()
  self:initPermaTheme()
  self:initEventTheme()
  lua_sys.playSoundFx("audio/sfx/menu_slide.wav")
  self.BuyButton:setInvisible()
  self.EventThemeBuyButton:setInvisible()
  self:SetupGenericListener(game.engineReceiver(), "game::msg::MsgIslandThemePurchased", "gotMsgIslandThemePurchased")
end
function IslandInfo:onPostInit()
  game.logEvent("popup_island_info_init", "island_id", tostring(self.currentIsland))
  if self.IslandDescription.Text:absH() <= self.IslandDescription:absH() then
    self.ScrollBar.Sprite:GetVar("visible"):SetInt(0)
    self.ScrollMarker.Marker:GetVar("visible"):SetInt(0)
  end
  self.Buffs:populate()
  self:selectNewTab()
end
function IslandInfo:queuePop()
  self.transitionState = 2
end
function IslandInfo:updateClipping()
  game.setClipping("Clipping", self.FadeSprite:absX() * lua_sys.deviceScaleX(), self.FadeSprite:absY() * lua_sys.deviceScaleY() + 2, self.FadeSprite:absW() * lua_sys.deviceScaleX(), (self.BotFadeSprite:absY() + self.BotFadeSprite:absH() - self.FadeSprite:absY()) * lua_sys.deviceScaleY() - 4)
end
function IslandInfo:updateScrollBar()
  local textComponent = self.IslandDescription.Text
  if textComponent:absH() - 5 <= self.IslandDescription:absH() then
    self.ScrollBar.Sprite:GetVar("visible"):SetInt(0)
    self.ScrollMarker.Marker:GetVar("visible"):SetInt(0)
  else
    self.ScrollBar.Sprite:GetVar("visible"):SetInt(1)
    self.ScrollMarker.Marker:GetVar("visible"):SetInt(1)
  end
end
function IslandInfo:onTick(dt)
  self.showingNewsFlashThisFrame = false
  if self.transitionState == 0 then
    if self.tabSelected == EVENT_THEME and self.curThemeIds[self.tabSelected] ~= -1 and not self.lockedStatus[self.tabSelected] and not self.ownedStatus[self.tabSelected] then
      local secondsRemaining = game.timedAvailIslandThemeTimeRemaining(self.curThemeIds[self.tabSelected])
      if secondsRemaining > 0 then
        if self.BuyButton.UpSprite.visible == 0 then
          self.BuyButton.Touch.onTouchUp = getBuyButtonTouch(self.BuyButton.Touch, self.tabSelected)
        end
        self.BuyButton:setVisible()
        if game.onGoldIsland() ~= true then
          self.EventThemeBuyButton:setVisible()
        end
        self.TempAvailText.TimerText:GetVar("text"):SetString(game.timeToString(secondsRemaining))
        self.TempAvailText:setVisible()
      elseif self.BuyButton.Touch:GetVar("enabled"):GetInt() == 1 then
        self:setNewlyUnavailable()
      end
    end
  else
    self:TickTransition()
    if self.transitionState == 1 then
      self.transitionTime = self.transitionTime + dt * 3
    elseif self.transitionState == 2 then
      self.transitionTime = self.transitionTime - dt * 3
    end
    self.transitionTime = lua_sys.clamp(self.transitionTime, 0, 1)
    self:updateClipping()
    if self.transitionTime == 1 then
      self.transitionState = 0
      self.transitionTime = 1
      self:TickTransition()
    elseif 0 >= self.transitionTime then
      self:root():popPopUp()
    end
  end
end
function IslandInfo:TickTransition()
  self.bg:GetVar("xOffset"):SetFloat(lua_sys.screenWidth() * 0.5 + -0.35 * lua_sys.screenWidth() * (1 / math.max(0.001, self.transitionTime)))
  self.FadedBG.Sprite:GetVar("alpha"):SetFloat(self.transitionTime * 0.5)
end
function IslandInfo:showBio()
  local textComponent = self.IslandDescription.Text
  textComponent:GetVar("autoScale"):SetInt(0)
  textComponent:GetVar("size"):SetFloat(0.35 * game.hudScale())
  textComponent:GetVar("text"):SetString(self.bios[self.tabSelected])
  textComponent:GetVar("autoScale"):SetInt(1)
  self.IslandDescription.Touch:GetVar("enabled"):SetInt(1)
  self.IslandDescription.Swiper:refresh(self.IslandDescription)
  self.BioButton:enable()
  self.BioButton.Touch:GetVar("enabled"):SetInt(0)
  self.BoostsButton:disable()
  self.BoostsButton.Touch:GetVar("enabled"):SetInt(1)
  if textComponent:absH() > self.IslandDescription:absH() then
    self.ScrollBar.Sprite:GetVar("visible"):SetInt(1)
    self.ScrollMarker.Marker:GetVar("visible"):SetInt(1)
  end
  self.IslandDescription.Swiper:resetScrollPos(self)
end
function IslandInfo:showBoosts()
  local textComponent = self.IslandDescription.Text
  textComponent:GetVar("autoScale"):SetInt(0)
  textComponent:GetVar("size"):SetFloat(0.35 * game.hudScale())
  textComponent:GetVar("text"):SetString(self.boosts[self.tabSelected])
  textComponent:GetVar("autoScale"):SetInt(1)
  self.IslandDescription.Touch:GetVar("enabled"):SetInt(1)
  self.IslandDescription.Swiper:refresh(self.IslandDescription)
  self.BoostsButton:enable()
  self.BoostsButton.Touch:GetVar("enabled"):SetInt(0)
  self.BioButton:disable()
  self.BioButton.Touch:GetVar("enabled"):SetInt(1)
  if textComponent:absH() > self.IslandDescription:absH() then
    self.ScrollBar.Sprite:GetVar("visible"):SetInt(1)
    self.ScrollMarker.Marker:GetVar("visible"):SetInt(1)
  end
  self.IslandDescription.Swiper:resetScrollPos(self)
end
function IslandInfo:showView(tabIndex, themeId, owned, name, animation, bio, boosts, locked, lockedText, available, buyButtonText, showThemesTut)
  if showThemesTut and not game.hasOpenedThemesTab() and not game.onGoldIsland() then
    game.displayNotification("ISLAND_THEME_TUTORIAL")
    game.openedThemesTab()
  end
  for i = 1, #self.visibleTabs do
    if i ~= tabIndex then
      self.visibleTabs[i]:deselectTab()
    else
      self.visibleTabs[i]:selectTab()
    end
  end
  self.StatsList:hideStats()
  if tabIndex ~= RANKING then
    self.StatsList:hideStats()
  else
    self.StatsList:showStats()
  end
  local textComponent = self.IslandDescription.Text
  textComponent:GetVar("autoScale"):SetInt(0)
  textComponent:GetVar("size"):SetFloat(0.35 * game.hudScale())
  textComponent:GetVar("text"):SetString(bio)
  textComponent:GetVar("autoScale"):SetInt(1)
  self.IslandDescription.Touch:GetVar("enabled"):SetInt(1)
  self.IslandDescription.Swiper:refresh(self.IslandDescription)
  self.IconFrame.Text:GetVar("text"):SetString(name)
  self.Icon.Sprite:GetVar("animation"):SetString(animation)
  self.EventThemeBuyButton:setInvisible()
  self.TempAvailText:setInvisible()
  if boosts == "" then
    self.BlackCover.Sprite:GetVar("height"):SetInt(0)
    self.BioButton:setInvisible()
    self.BoostsButton:setInvisible()
  else
    self.BlackCover.Sprite:GetVar("height"):SetInt(self.BlackCover.Sprite:GetVar("originalHeight"):GetInt())
    self.BioButton:setVisible()
    self.BoostsButton:setVisible()
    self:showBio()
  end
  self.Icon.Sprite:setEnabled()
  self.IconFrame.Sprite:setEnabled()
  self.IconFrame.Text:setEnabled()
  self:removeLockGfx()
  self.LevelReq:GetVar("visible"):SetInt(0)
  if buyButtonText == "" then
    self.BuyButton:setInvisible()
  else
    self.BuyButton.Text:GetVar("text"):SetString(buyButtonText)
    self.BuyButton:setVisible()
    self.BuyButton.Touch.onTouchUp = getBuyButtonTouch(self.BuyButton.Touch, tabIndex)
    if tabIndex == EVENT_THEME and themeId ~= -1 and not owned then
      self.EventThemeBuyButton.Touch.onTouchUp = getBuyActivate(self.EventThemeBuyButton.Touch)
      self.TempAvailText.TimerText:GetVar("text"):SetString(game.timeToString(game.timedAvailIslandThemeTimeRemaining(themeId)))
      self.TempAvailText:setVisible()
    end
  end
  if tabIndex == ISLAND and 0 < #self.Buffs.buffs then
    self.Buffs:setVisible()
    local blackCoverHeight = 16 * game.menuScaleX()
    self.BlackCover.Sprite:GetVar("height"):SetInt(blackCoverHeight)
    self.BuffsBG.Sprite:GetVar("visible"):SetInt(1)
    self.BuffsBG.BuffsLabel:GetVar("visible"):SetInt(1)
  else
    self.Buffs:setInvisible()
    self.BuffsBG.Sprite:GetVar("visible"):SetInt(0)
    self.BuffsBG.BuffsLabel:GetVar("visible"):SetInt(0)
  end
  self.IslandDescription.Swiper:resetScrollPos(self)
  if not owned then
    if locked then
      self:setLocked(lockedText)
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
  self:updateScrollBar()
  self:updateClipping()
end
function IslandInfo:selectTab(tabIndex)
  self:showView(tabIndex, self.curThemeIds[tabIndex], self.ownedStatus[tabIndex], self.names[tabIndex], self.animations[tabIndex], self.bios[tabIndex], self.boosts[tabIndex], self.lockedStatus[tabIndex], self.lockedText[tabIndex], self.availableStatus[tabIndex], self.buyButtonText[tabIndex], self.showThemesTutorial[tabIndex])
end
function IslandInfo:selectNewTab()
  if self.tabSelected < 1 or #self.visibleTabs < self.tabSelected then
    self.tabSelected = 1
  end
  self:GetVar("tabSelectedName"):SetString("Tab" .. self.tabSelected)
  self:selectTab(self.tabSelected)
end
function IslandInfo:addLockGfx()
  local lock = menu:addTemplateElement("template_storeitemlock", "ItemLock", self.IconFrame)
  lock.layer = "PopUps"
  lock:relativeTo(self.IconFrame)
  lock:setOrientation(lua_sys.MenuOrientation(0, 15 * game.menuScaleX(), -3, lua_sys.HCENTER, lua_sys.VCENTER))
  lock:setRelativeObjectAnchors(lua_sys.HCENTER, lua_sys.VCENTER)
  lock:init()
  lock:setPositionBroadcast(true)
  lock:postInit()
end
function IslandInfo:removeLockGfx()
  self.IconFrame:RemoveElement(self.IconFrame:GetElement("ItemLock"))
end
function IslandInfo:setLocked(levelLockedText)
  self.Icon.Sprite:setDisabled()
  self.IconFrame.Sprite:setDisabled()
  self.IconFrame.Text:setDisabled()
  self:addLockGfx()
  self.BlackCover.Sprite:GetVar("height"):SetInt(0)
  self.BioButton:setInvisible()
  self.BoostsButton:setInvisible()
  self.LevelReq:GetVar("visible"):SetInt(1)
  self.TempAvailText:setInvisible()
  if levelLockedText ~= "" then
    self.LevelReq:GetVar("autoScale"):SetInt(0)
    self.LevelReq:GetVar("size"):SetFloat(0.35 * game.hudScale())
    self.LevelReq:GetVar("text"):SetString(levelLockedText)
    self.LevelReq:GetVar("autoScale"):SetInt(1)
    self.LevelReq:GetVar("visible"):SetInt(1)
  else
    self.LevelReq:GetVar("text"):SetString("")
    self.LevelReq:GetVar("visible"):SetInt(0)
  end
  self.BuyButton:setInvisible()
end
function IslandInfo:setUnavailable()
  self.Icon.Sprite:setDisabled()
  self.IconFrame.Sprite:setDisabled()
  self.IconFrame.Text:setDisabled()
  self:addLockGfx()
  self.BlackCover.Sprite:GetVar("height"):SetInt(0)
  self.BioButton:setInvisible()
  self.BoostsButton:setInvisible()
  self.BuyButton:setInvisible()
  self.EventThemeBuyButton:setInvisible()
  self.TempAvailText.TimerText:GetVar("visible"):SetInt(0)
  self.TempAvailText.AvailableUntil:GetVar("visible"):SetInt(0)
  local txt
  if game.islandThemeIsSeasonal(self.curThemeIds[self.tabSelected]) then
    txt = LOC("SEASONAL_SKIN_UNAVAILABLE")
    local eventStr = LOC(game.islandThemeSeasonAvailable(self.curThemeIds[self.tabSelected]))
    local monthStr = LOC(game.islandThemeMonthAvailable(self.curThemeIds[self.tabSelected]))
    txt = txt:gsub("XXX", eventStr)
    txt = txt:gsub("YYY", monthStr)
  else
    txt = LOC("SEASONAL_SKIN_UNAVAILABLE_GENERIC")
  end
  local textComponent = self.IslandDescription.Text
  textComponent:GetVar("autoScale"):SetInt(0)
  textComponent:GetVar("size"):SetFloat(0.35 * game.hudScale())
  textComponent:GetVar("text"):SetString(txt)
  textComponent:GetVar("autoScale"):SetInt(1)
  self.IslandDescription.Touch:GetVar("enabled"):SetInt(1)
  self.IslandDescription.Swiper:refresh(self.IslandDescription)
end
function IslandInfo:setNewlyUnavailable()
  self:setUnavailable()
  self.BuyButton:setVisible()
  self.BuyButton:disable()
  if game.onGoldIsland() ~= true then
    self.EventThemeBuyButton:setVisible()
    self.EventThemeBuyButton:disable()
  end
  self.TempAvailText.AvailableUntil:GetVar("visible"):SetInt(1)
  self.TempAvailText.AvailableUntil:GetVar("text"):SetString("TIMED_EVENT_EXPIRED")
end
function IslandInfo:gotMsgIslandThemePurchased(msg)
  for i = 1, #self.curThemeIds do
    if self.curThemeIds[i] == msg.theme_id then
      self.ownedStatus[i] = true
    end
  end
  if msg.activateNow then
    game.loadWorldContext()
  elseif msg.theme_id == self.curThemeIds[self.tabSelected] then
    self.BuyButton.Text:GetVar("text"):SetString("ACTIVATE_BUTTON")
    self.BuyButton.Touch.onTouchUp = getBuyButtonTouch(self.BuyButton.Touch, self.tabSelected)
    self.BuyButton:enable()
    self.EventThemeBuyButton:setInvisible()
  end
end
function IslandInfo.LevelReq:onInit(element)
  self:GetVar("multiline"):SetInt(1)
  self:GetVar("font"):Set(game.getTextFont())
  self:GetVar("size"):SetFloat(0.35 * game.hudScale())
  self:GetVar("alignment"):SetInt(lua_sys.MenuTextComponent_TEXT_HCENTER_ALIGNED)
  self:GetVar("textPadding"):SetInt(30 * game.menuScaleX())
  self:GetVar("autoScale"):SetInt(1)
  self:GetVar("layer"):SetString("PopUps")
  self:GetVar("visible"):SetInt(0)
end
function ButtonBasePostInit(obj)
  if obj:parent().tabSelected ~= -1 then
    if obj:parent().tabSelected == PERMA_THEME then
      local themeId = obj:parent().curThemeIds[obj:parent().tabSelected]
      if themeId ~= -1 then
        if obj:parent().lockedStatus[obj:parent().tabSelected] then
          obj:SetInvisible()
        end
      elseif obj:parent().ownedStatus[obj:parent().tabSelected] then
        obj:SetInvisible()
      end
    elseif obj:parent().tabSelected == EVENT_THEME then
      local themeId = obj:parent().curThemeIds[obj:parent().tabSelected]
      if themeId ~= -1 then
        if obj:parent().lockedStatus[obj:parent().tabSelected] then
          obj:SetInvisible()
        end
      elseif obj:parent().ownedStatus[obj:parent().tabSelected] then
        obj:SetInvisible()
      end
    end
  end
end
function BuyButtonBase:onPostInit()
  ButtonBasePostInit(self)
  self:SetupGenericListener(game.engineReceiver(), "game::msg::MsgPlacementInfo", "gotMsgPlacementInfo")
  self:SetupGenericListener(game.engineReceiver(), "game::msg::MsgPlacementInfoFail", "gotMsgPlacementInfoFail")
  self:SetupGenericListener(game.engineReceiver(), "game::msg::MsgPlacementImageFail", "gotMsgPlacementInfoFail")
  self:SetupGenericListener(game.engineReceiver(), "game::msg::MsgConfirmationSubmission", "gotMsgConfirmationSubmission")
end
function BuyButtonBase:buyButtonConfSubmission(msg)
  if msg.messageID == "THEME_PACK_PURCHASE" and msg.choice == false then
    self:parent().allowClick = 1
    self:enable()
  end
end
function BuyButtonBase:buyPlacementInfoFail(msg)
  local parent = self:parent()
  for i = 1, #parent.placementIds do
    if parent.placementIds[i] ~= "" and msg.name == parent.placementIds[i] and parent.clicked == 0 then
      parent.clicked = 1
      parent.allowClick = 1
      local txt = game.getLocalizedText("NOTIFICATION_BUY_THEME_PACK_1")
      txt = select(1, txt:gsub("XXX", game.getIslandThemePackPrice("island_theme", parent.curThemeIds[i])))
      game.displayConfirmation("THEME_PACK_PURCHASE", txt)
      self:disable()
      break
    end
  end
end
function BuyButtonBase:buyPlacementInfo(msg)
  local parent = self:parent()
  if parent.showingNewsFlashThisFrame then
    return
  end
  for i = 1, #parent.placementIds do
    if parent.placementIds[i] ~= "" and msg.name == parent.placementIds[i] then
      parent.allowClick = 1
      parent.showingNewsFlashThisFrame = true
      game.pushPopUp("newsflash")
      game.topPopUp():GetVar("placement"):SetString(parent.placementIds[i])
      game.topPopUp():DoStoredScript("setUpElements")
      break
    end
  end
end
local function logBuyClick(tabSelected, currentIsland)
  if tabSelected == PERMA_THEME then
    game.logEvent("popup_island_info_theme_buy_click", "island_id", currentIsland)
  elseif tabSelected == EVENT_THEME then
  end
end
function EventThemeBuyButtonBase:onPostInit()
  ButtonBasePostInit(self)
  self:SetupGenericListener(game.engineReceiver(), "game::msg::MsgPlacementInfo", "gotMsgPlacementInfo")
  self:SetupGenericListener(game.engineReceiver(), "game::msg::MsgPlacementInfoFail", "gotMsgPlacementInfoFail")
  self:SetupGenericListener(game.engineReceiver(), "game::msg::MsgPlacementImageFail", "gotMsgPlacementInfoFail")
  self:SetupGenericListener(game.engineReceiver(), "game::msg::MsgConfirmationSubmission", "gotMsgConfirmationSubmission")
end
local buyButtonConfSubmission = function(element, msg)
  if msg.messageID == "THEME_PACK_PURCHASE" and msg.choice == false then
    element:parent().allowClick = 1
    element:enable()
  end
end
local buyPlacementInfoFail = function(element, msg)
  local parent = element:parent()
  for i = 1, #parent.placementIds do
    if parent.placementIds[i] ~= "" and msg.name == parent.placementIds[i] and parent.clicked == 0 then
      parent.clicked = 1
      parent.allowClick = 1
      local txt = game.getLocalizedText("NOTIFICATION_BUY_THEME_PACK_1")
      txt = select(1, txt:gsub("XXX", game.getIslandThemePackPrice("island_theme", parent.curThemeIds[i])))
      parent:V("selectedThemeId"):SetInt(parent.curThemeIds[i])
      game.displayConfirmation("THEME_PACK_PURCHASE", txt)
      element:disable()
      break
    end
  end
end
local buyPlacementInfo = function(element, msg)
  local parent = element:parent()
  if parent.showingNewsFlashThisFrame then
    return
  end
  for i = 1, #parent.placementIds do
    if parent.placementIds[i] ~= "" and msg.name == parent.placementIds[i] then
      parent.allowClick = 1
      parent.showingNewsFlashThisFrame = true
      game.pushPopUp("newsflash")
      game.topPopUp():GetVar("placement"):SetString(parent.placementIds[i])
      game.topPopUp():DoStoredScript("setUpElements")
      break
    end
  end
end
local function logBuyClick(tabSelected, currentIsland)
  if tabSelected == PERMA_THEME then
    game.logEvent("popup_island_info_theme_buy_click", "island_id", currentIsland)
  elseif tabSelected == EVENT_THEME then
  end
end
function IslandInfo.BuyButton:gotMsgConfirmationSubmission(msg)
  if self:parent().tabSelected == PERMA_THEME then
    buyButtonConfSubmission(self, msg)
  end
end
function IslandInfo.BuyButton:gotMsgPlacementInfoFail(msg)
  if self:parent().tabSelected == PERMA_THEME then
    buyPlacementInfoFail(self, msg)
  end
end
function IslandInfo.BuyButton:gotMsgPlacementInfo(msg)
  if self:parent().tabSelected == PERMA_THEME then
    buyPlacementInfo(self, msg)
  end
end
function IslandInfo.BuyButton.Touch:trialActivate(element)
  self:super_onTouchUp(element)
  if element:parent().curThemeIds[element:parent().tabSelected] ~= -1 then
    if element:parent().ownedStatus[element:parent().tabSelected] then
      game.activateIslandTheme(element:parent().curThemeIds[element:parent().tabSelected])
      element:disable()
    else
      game.activateTrialIslandTheme(element:parent().curThemeIds[element:parent().tabSelected])
      element:disable()
    end
  end
end
local function normalBuyActivate(element)
  if element:parent().curThemeIds[element:parent().tabSelected] ~= -1 then
    if element:parent().ownedStatus[element:parent().tabSelected] then
      game.activateIslandTheme(element:parent().curThemeIds[element:parent().tabSelected])
      element:disable()
    elseif element:parent().allowClick == 1 then
      element:parent().clicked = 0
      if lua_sys.getPlatformName() == "pc" then
        local dlcAppId = game.getIslandThemePackSteamDLCAppId("island_theme", element:parent().curThemeIds[element:parent().tabSelected])
        game.ShowAppInSteamStore(dlcAppId)
      else
        element:parent().allowClick = 0
        game.confirmThemeBuy(element:parent().curThemeIds[element:parent().tabSelected], element:parent().placementIds[element:parent().tabSelected])
      end
      logBuyClick(element:parent().tabSelected, element:parent().currentIsland)
    end
  end
end
function IslandInfo.BuyButton.Touch:normalBuyActivate(element)
  self:super_onTouchUp(element)
  normalBuyActivate(element)
end
function IslandInfo.EventThemeBuyButton.Touch:normalBuyActivate(element)
  self:super_onTouchUp(element)
  normalBuyActivate(element)
end
function IslandInfo.EventThemeBuyButton:gotMsgConfirmationSubmission(msg)
  if self:parent().tabSelected == EVENT_THEME then
    buyButtonConfSubmission(self, msg)
  end
end
function IslandInfo.EventThemeBuyButton:gotMsgPlacementInfoFail(msg)
  if self:parent().tabSelected == EVENT_THEME then
    buyPlacementInfoFail(self, msg)
  end
end
function IslandInfo.EventThemeBuyButton:gotMsgPlacementInfo(msg)
  if self:parent().tabSelected == EVENT_THEME then
    buyPlacementInfo(self, msg)
  end
end
function IslandInfo.ScrollMarker.Touch:onTouchDrag(element, x, y)
  local scrollBar = element:parent().ScrollBar
  local fromTopOfMarkerRange = y - scrollBar:absY() - element:GetVar("originalYOffset"):GetInt()
  local markerBookend = element:GetVar("originalYOffset"):GetInt()
  local descrElement = element:parent().IslandDescription
  local scrollSize = 0
  if descrElement("scrollSize") ~= nil then
    scrollSize = descrElement:GetVar("scrollSize"):GetFloat()
  end
  local scrollOffset = -(fromTopOfMarkerRange - markerBookend) / (scrollBar:absH() - 2 * markerBookend - element:absH()) * scrollSize
  scrollOffset = lua_sys.clamp(scrollOffset, -scrollSize, 0)
  element:GetVar("scrollOffset"):SetFloat(scrollOffset)
  descrElement.Swiper:setScrollOffsetToMarker(descrElement)
end
function IslandInfo.IslandDescription.Text:onInit(element)
  self:GetVar("multiline"):SetInt(1)
  self:GetVar("autoScale"):SetInt(1)
  self:GetVar("autoScaleFactor"):SetFloat(0.01)
  self:GetVar("alignment"):SetInt(lua_sys.MenuTextComponent_TEXT_LEFT_ALIGNED)
  self:GetVar("textPadding"):SetInt(0)
  self:GetVar("font"):Set(game.getTextFont())
  self:GetVar("size"):SetFloat(0.35 * game.hudScale())
  self:GetVar("text"):SetString("")
  self:GetVar("layer"):SetString("Clipping")
end
function IslandInfo.IslandDescription.Text:onPostInit(element)
  game.setClipping("Clipping", 0, (element:absY() - 10 * game.menuScaleY()) * lua_sys.deviceScaleY(), lua_sys.screenWidth() * lua_sys.deviceScaleX(), (element:absH() + 10 * game.menuScaleY()) * lua_sys.deviceScaleY())
end
function IslandInfo.IslandDescription.Swiper:onPostInit(element)
  self:GetVar("direction"):SetInt(lua_sys.MenuSwipeComponent_SwipeDirectionVertical)
  self:GetVar("mode"):SetInt(lua_sys.MenuSwipeComponent_SwipeModeFree)
  self:GetVar("tSteps"):SetFloat(25)
  self:listenToTouches(element)
  self:refresh(element)
end
function IslandInfo.IslandDescription.Swiper:refresh(element)
  local itemHeight = element.Text:absH()
  itemHeight = itemHeight + 10 * game.menuScaleY()
  if itemHeight < element:absH() then
    self:setScrollSize(0)
  else
    self:setScrollSize(itemHeight - element:absH() + element:parent().BlackCover.Sprite:GetVar("height"):GetInt())
  end
  element:GetVar("scrollSize"):SetFloat(self:scrollSize())
end
function IslandInfo.IslandDescription.Swiper:onTick(element, dt)
  self:correctScrollMarkerPos(element)
end
function IslandInfo.IslandDescription.Swiper:correctScrollMarkerPos(element)
  local first = element.Text
  if first then
    local scrollOffset = self:scrollOffset()
    if first:getOrientationPosition().y ~= scrollOffset then
      first:setOrientationPosition(lua_sys.Vector2(first:GetVar("xOffset"):GetInt(), scrollOffset))
      local scrollMarker = element:parent().ScrollMarker
      local markerBookend = scrollMarker:GetVar("originalYOffset"):GetInt()
      local markerMovementHeight = element:parent().ScrollBar:absH() - 2 * markerBookend - scrollMarker:absH()
      local scrollMarkerYOffset = 0
      if self:scrollSize() ~= 0 then
        scrollMarkerYOffset = -(scrollOffset / self:scrollSize()) * markerMovementHeight
      end
      scrollMarkerYOffset = lua_sys.clamp(scrollMarkerYOffset, 0, markerMovementHeight)
      scrollMarker:GetVar("yOffset"):SetInt(markerBookend + scrollMarkerYOffset)
    end
  end
end
function IslandInfo.IslandDescription.Swiper:setScrollOffsetToMarker(element)
  self:setScrollOffset(element:parent().ScrollMarker:GetVar("scrollOffset"):GetFloat())
end
function IslandInfo.IslandDescription.Swiper:resetScrollPos(element)
  self:setScrollOffset(0)
  self:correctScrollMarkerPos(element)
end
return IslandInfo
