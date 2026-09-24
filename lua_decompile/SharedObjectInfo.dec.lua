local OffsetTransition = include("MenuElementPositionOffsetTransition")
local Genes = include("Genes")
local SharedObjectInfo = {
  FadedBG = {},
  InfoFrame = {
    Sprite = {},
    Swiper = {}
  },
  BlackCover = {
    Sprite = {}
  },
  InfoContent = {
    Text = {}
  },
  ScrollBar = {
    Sprite = {}
  },
  ScrollMarker = {
    Marker = {},
    Touch = {},
    originalYOffset = 0
  },
  FadeSprite = {
    Sprite = {}
  },
  BotFadeSprite = {
    Sprite = {}
  },
  RightFadeSprite = {
    Sprite = {}
  },
  LeftFadeSprite = {
    Sprite = {}
  },
  Animation = {
    Sprite = {},
    Effect = {},
    Touch = {}
  },
  TimeRemainingText = {
    AvailableUntil = {},
    TimerText = {}
  },
  ImageTitle = {
    Text = {},
    Sprite = {},
    Touch = {}
  },
  StatsList = {},
  BioButton = {
    Label = {},
    Touch = {}
  },
  StatsButton = {
    Label = {},
    Touch = {}
  },
  infoFrameEndX = -300 * game.windowScaleX()
}
function SharedObjectInfo:new(obj)
  local obj = obj or {}
  setmetatable(obj, self)
  self.__index = self
  return obj
end
local transitionState = 0
SharedObjectInfo.currentView = 0
local fader, faderSprite
local infoFrameEndY = -1.1 * lua_sys.deviceMarginY()
local function _initGenes(element)
  if game.selectedObjIsMonster() then
    local monsterId = game.monsterTypeId(game.selectedMonsterId())
    Genes.InitForMonsterId(monsterId, element, {
      layer = "PopUps",
      spacing = -2 * game.hudScale(),
      prefix = "geneItem",
      priority = -4,
      vAnchor = lua_sys.BOTTOM,
      offsetY = -4 * game.menuScaleY()
    })
  elseif game.selectedObjType() == game.SpecificEntityType_CASTLE then
    local name = game.objectName()
    if string.find(name, "MONSTER_N") ~= nil then
      local geneItem = menu:addTemplateElement("template_elementicon", "geneItem0", element)
      geneItem:V("SpriteName"):SetString("gene_fire")
      geneItem:V("SheetName"):SetString("xml_resources/hud02.xml")
      geneItem:V("Size"):SetFloat(0.5)
      geneItem:V("Layer"):SetString("PopUps")
      geneItem:setParent(element)
      geneItem:setOrientation(lua_sys.MenuOrientation(0, -4 * game.menuScaleY(), -4, lua_sys.HCENTER, lua_sys.VCENTER))
      geneItem:setRelativeObjectAnchors(lua_sys.HCENTER, lua_sys.BOTTOM)
      geneItem:init()
      geneItem:setPositionBroadcast(true)
    end
  end
end
function SharedObjectInfo:onInit()
  self.infoFrameEndX = -300 * game.windowScaleX()
  if game.selectedObjIsMonster() then
    local overlapHorz = self.InfoFrame:absW() / lua_sys.screenWidth() > 0.44
    local contextBarHeight = game.contextBarHeight()
    local availableSpace = lua_sys.screenHeight() - contextBarHeight - contextBarHeight
    local overlapVert = availableSpace <= self.InfoFrame:absH()
    if overlapHorz and overlapVert then
      infoFrameEndY = (self.InfoFrame:absH() - availableSpace) / -2 + lua_sys.deviceMarginY()
    end
  end
  fader = self.FadeSprite
  faderSprite = fader.Sprite
  self.ImageFrame:Init()
  self.ImageFrame.onDoneHide = nil
  local imageFrameTransition = self.ImageFrame.OffsetTransition
  imageFrameTransition.delayOnStart = 0.5
  imageFrameTransition.duration = 0.25
  imageFrameTransition.startX = 30 * game.hudScale()
  imageFrameTransition.startY = infoFrameEndY
  imageFrameTransition.endX = -160 * game.windowScaleX()
  imageFrameTransition.endY = infoFrameEndY
  imageFrameTransition.ease = lua_sys.Linear_EaseNone
  OffsetTransition.OnInit(self.InfoFrame, {
    delayOnStart = 0.6,
    duration = 0.3,
    startX = 0,
    startY = infoFrameEndY,
    endX = self.infoFrameEndX,
    endY = infoFrameEndY
  })
  _initGenes(self.ImageFrame)
  collectgarbage("stop")
end
function SharedObjectInfo:initCurrentView()
  self.currentView = 0
  if game.selectedObjType() == game.SpecificEntityType_MONSTER then
    if game.showBios() == game.PersistentData_BIO then
      self.currentView = 0
    elseif game.showBios() == game.PersistentData_LIKES then
      if game.selectedMonsterHasLikes() and not game.hideMonsterLikes() then
        self.currentView = 2
      else
        self.currentView = 0
      end
    else
      self.currentView = 1
    end
  else
    self.currentView = 0
  end
end
function SharedObjectInfo:onPostInit()
  self:initCurrentView()
  self:refreshView()
  self.ImageFrame:Show()
  OffsetTransition.Show(self.InfoFrame)
  lua_sys.playSoundFx("audio/sfx/menu_slide.wav")
  transitionState = 1
  if self.InfoContent.Text:absH() <= self.InfoContent:absH() then
    self.ScrollBar.Sprite:V("visible"):SetInt(0)
    self.ScrollMarker.Marker:V("visible"):SetInt(0)
  end
end
function SharedObjectInfo:onTick(dt)
  OffsetTransition.OnTick(self.InfoFrame, dt, {
    ease = lua_sys.Linear_EaseNone
  })
  if transitionState ~= 0 then
    if self.Animation.Sprite:V("visible"):GetInt() == 0 then
      self.Animation.Sprite:V("visible"):SetInt(1)
    end
    if self.InfoFrame:V("xOffset"):GetInt() <= self.infoFrameEndX and transitionState == 1 then
      collectgarbage("collect")
      collectgarbage("restart")
      transitionState = 0
    end
    local topSprite = self.FadeSprite
    local botSprite = self.BotFadeSprite
    game.setClipping("Clipping", topSprite:absX() * lua_sys.deviceScaleX(), topSprite:absY() * lua_sys.deviceScaleY(), topSprite:absW() * lua_sys.deviceScaleX(), (botSprite:absY() + botSprite:absH() - topSprite:absY()) * lua_sys.deviceScaleY())
    collectgarbage("step", 20)
  end
end
function SharedObjectInfo:queuePop()
  manager:hideContextBar()
  transitionState = 2
  self.FadedBG:Hide()
  self.ImageFrame:Hide()
  OffsetTransition.Hide(self.InfoFrame)
end
function SharedObjectInfo:refreshView()
  if self.currentView == 0 then
    self.InfoContent.Text:V("visible"):SetInt(1)
    self.InfoFrame.Touch:V("enabled"):SetInt(1)
    self.BioButton:enable()
    self.BioButton.Touch:V("enabled"):SetInt(0)
    if self.InfoContent.Text:absH() > self.InfoContent:absH() then
      self.ScrollBar.Sprite:V("visible"):SetInt(1)
      self.ScrollMarker.Marker:V("visible"):SetInt(1)
    end
    game.setShowBios(game.PersistentData_BIO)
  else
    self.BioButton:disable()
    self.BioButton.Touch:V("enabled"):SetInt(1)
    self.InfoContent.Text:V("visible"):SetInt(0)
    self.InfoFrame.Touch:V("enabled"):SetInt(0)
    self.ScrollBar.Sprite:V("visible"):SetInt(0)
    self.ScrollMarker.Marker:V("visible"):SetInt(0)
  end
  if self.currentView == 1 then
    self.StatsButton:enable()
    self.StatsButton.Touch:V("enabled"):SetInt(0)
    self.StatsList:showStats()
    game.setShowBios(game.PersistentData_STATS)
  else
    self.StatsButton:disable()
    self.StatsButton.Touch:V("enabled"):SetInt(1)
    self.StatsList:hideStats()
  end
  if self.currentView == 2 then
    if self.LikesButton ~= nil then
      self.LikesButton:enable()
      self.LikesButton.Touch:V("enabled"):SetInt(0)
    end
    if self.InfoLikes ~= nil then
      self.InfoLikes:showLikes()
    end
    game.setShowBios(game.PersistentData_LIKES)
  else
    if self.LikesButton ~= nil and self.LikesButton.UpSprite:V("visible"):GetInt() == 1 then
      self.LikesButton:disable()
      self.LikesButton.Touch:V("enabled"):SetInt(1)
    end
    if self.InfoLikes ~= nil then
      self.InfoLikes:hideLikes()
    end
  end
end
function SharedObjectInfo:populateTitansoulStats()
  local statsArray
  statsArray = {
    "template_stat_species",
    "template_stat_class",
    "template_stat_beds"
  }
  self.StatsList:populateStatsArr(statsArray)
end
function SharedObjectInfo:populateMineStats()
  local leftStat = menu:addTemplateElement("template_minetime", "leftStat", self)
  leftStat:setParent(self.InfoFrame)
  leftStat:setOrientation(lua_sys.MenuOrientation(0, 0, -3, lua_sys.LEFT, lua_sys.TOP))
  leftStat:setRelativeObjectAnchors(lua_sys.LEFT, lua_sys.TOP)
  leftStat:init()
  leftStat:setPositionBroadcast(true)
end
function SharedObjectInfo:populateBakeryStats()
  local timeLeft = game.bakeryTime()
  if timeLeft <= 0 then
    self.BlackCover.Sprite:V("height"):SetInt(4 * game.windowScaleY())
    local faderSize = faderSprite:size()
    faderSprite:setSize(lua_sys.Vector2(faderSize.x, faderSize.y + 46 * game.windowScaleY()))
  else
    local leftStat = menu:addTemplateElement("template_bakerytime", "leftStat", self)
    leftStat:setParent(self.InfoFrame)
    leftStat:setOrientation(lua_sys.MenuOrientation(0, 0, -3, lua_sys.LEFT, lua_sys.TOP))
    leftStat:setRelativeObjectAnchors(lua_sys.LEFT, lua_sys.TOP)
    leftStat:init()
    leftStat:setPositionBroadcast(true)
  end
end
function SharedObjectInfo:populateFuzerStats()
  local timeLeft = game.timeLeftToFuze()
  if timeLeft <= 0 then
    self.BlackCover.Sprite:V("height"):SetInt(4 * game.windowScaleY())
    local faderSize = faderSprite:size()
    faderSprite:setSize(lua_sys.Vector2(faderSize.x, faderSize.y + 46 * game.windowScaleY()))
  else
    local leftStat = menu:addTemplateElement("template_fuzertime", "leftStat", self)
    leftStat:setParent(self.InfoFrame)
    leftStat:setOrientation(lua_sys.MenuOrientation(0, 0, -3, lua_sys.LEFT, lua_sys.TOP))
    leftStat:setRelativeObjectAnchors(lua_sys.LEFT, lua_sys.TOP)
    leftStat:init()
    leftStat:setPositionBroadcast(true)
  end
end
function SharedObjectInfo:populateBreedingStats()
  local timeLeft = game.timeLeftToBreed()
  if timeLeft <= 0 then
    self.BlackCover.Sprite:V("height"):SetInt(4 * game.windowScaleY())
    local faderSize = faderSprite:size()
    faderSprite:setSize(lua_sys.Vector2(faderSize.x, faderSize.y + 46 * game.windowScaleY()))
  else
    local leftStat = menu:addTemplateElement("template_breedingtime", "leftStat", self)
    leftStat:setParent(self.InfoFrame)
    leftStat:setOrientation(lua_sys.MenuOrientation(0, 0, -3, lua_sys.LEFT, lua_sys.TOP))
    leftStat:setRelativeObjectAnchors(lua_sys.LEFT, lua_sys.TOP)
    leftStat:init()
    leftStat:setPositionBroadcast(true)
  end
end
function SharedObjectInfo:populateNurseryStats()
  local timeLeft = game.timeLeftToHatchEgg()
  if timeLeft <= 0 then
    self.BlackCover.Sprite:V("height"):SetInt(4 * game.windowScaleY())
    local faderSize = faderSprite:size()
    faderSprite:setSize(lua_sys.Vector2(faderSize.x, faderSize.y + 46 * game.windowScaleY()))
  else
    local leftStat = menu:addTemplateElement("template_nurserytime", "leftStat", self)
    leftStat:setParent(self.InfoFrame)
    leftStat:setOrientation(lua_sys.MenuOrientation(0, 0, -3, lua_sys.LEFT, lua_sys.TOP))
    leftStat:setRelativeObjectAnchors(lua_sys.LEFT, lua_sys.TOP)
    leftStat:init()
    leftStat:setPositionBroadcast(true)
  end
end
function SharedObjectInfo.FadedBG:onDoneHide()
  self.Touch:V("enabled"):SetInt(0)
  self:root():popPopUp()
  manager:setContext(manager:reserveState())
end
function SharedObjectInfo.InfoFrame.Sprite:onInit(element)
  self("topHeight"):SetFloat(50)
  self("bottomHeight"):SetFloat(50)
  self("leftWidth"):SetFloat(50)
  self("rightWidth"):SetFloat(50)
  self("size"):SetFloat(0.5 * game.menuScaleX())
  self("includeBorder"):SetInt(1)
  self("spriteName"):SetString("gfx/menu/Black9SFrame50")
  self("layer"):SetString("PopUps")
end
function SharedObjectInfo.InfoFrame.Swiper:onPostInit(element)
  self("direction"):SetInt(lua_sys.MenuSwipeComponent_SwipeDirectionVertical)
  self("mode"):SetInt(lua_sys.MenuSwipeComponent_SwipeModeFree)
  self("tSteps"):SetFloat(25)
  self:refresh(element)
end
function SharedObjectInfo.InfoFrame.Swiper:refresh(element)
  self:listenToTouches(element)
  local itemHeight = element:parent().InfoContent.Text:absH()
  local parentHeight = element:parent().InfoContent:absH()
  if itemHeight > parentHeight then
    self:setScrollSize(itemHeight - parentHeight)
  else
    self:setScrollSize(0)
  end
  element:V("scrollSize"):SetFloat(self:scrollSize())
end
function SharedObjectInfo.InfoFrame.Swiper:onTick(element, dt)
  local first = element:parent().InfoContent.Text
  if first then
    local scrollOffset = self:scrollOffset()
    if first:getOrientationPosition().y ~= scrollOffset then
      first:setOrientationPosition(Vector2(first:V("xOffset"):GetInt(), scrollOffset))
      local scrollMarker = element:parent().ScrollMarker
      local markerBookend = scrollMarker.originalYOffset
      local markerMovementHeight = element:parent().ScrollBar:absH() - 2 * markerBookend - scrollMarker:absH()
      local scrollMarkerYOffset = 0
      if self:scrollSize() ~= 0 then
        scrollMarkerYOffset = -(scrollOffset / self:scrollSize()) * markerMovementHeight
      end
      scrollMarkerYOffset = clamp(scrollMarkerYOffset, 0, markerMovementHeight)
      scrollMarker:V("yOffset"):SetInt(markerBookend + scrollMarkerYOffset)
    end
  end
end
function SharedObjectInfo.InfoFrame.Swiper:setScrollOffsetToMarker(element)
  self:setScrollOffset(element:parent().ScrollMarker:V("scrollOffset"):GetFloat())
end
function SharedObjectInfo.BlackCover.Sprite:onInit(element)
  self("topHeight"):SetFloat(1)
  self("bottomHeight"):SetFloat(1)
  self("leftWidth"):SetFloat(1)
  self("rightWidth"):SetFloat(1)
  self("size"):SetFloat(0.5)
  self("includeBorder"):SetInt(1)
  self("spriteName"):SetString("__BUILTIN__WHITE_TEXTURE")
  self:setColor(0, 0, 0)
  self("layer"):SetString("ContextBar")
end
function SharedObjectInfo.ScrollBar.Sprite:onInit()
  self("spriteName"):SetString("scroll_bar_01")
  self("sheetName"):SetString("xml_resources/buttons01.xml")
  self("size"):SetFloat(0.3 * game.menuScaleY())
  self("layer"):SetString("ContextBar")
end
function SharedObjectInfo.ScrollMarker.Marker:onInit(element)
  self("useOffsets"):SetInt(1)
  self("spriteName"):SetString("scroll_bar_dot")
  self("sheetName"):SetString("xml_resources/buttons01.xml")
  self("size"):SetFloat(0.3 * game.menuScaleY())
  self("layer"):SetString("ContextBar")
  element.originalYOffset = element:V("yOffset"):GetInt()
end
function SharedObjectInfo.ScrollMarker.Touch:onTouchDrag(element, x, y)
  local scrollBar = element:parent().ScrollBar
  local fromTopOfMarkerRange = y - scrollBar:absY() - element.originalYOffset
  local markerBookend = element.originalYOffset
  local scrollSize = 0
  if element:parent().InfoFrame:V("scrollSize") ~= nil then
    scrollSize = element:parent().InfoFrame:V("scrollSize"):GetFloat()
  end
  local scrollOffset = -(fromTopOfMarkerRange - markerBookend) / (scrollBar:absH() - 2 * markerBookend - element:absH()) * scrollSize
  scrollOffset = clamp(scrollOffset, -scrollSize, 0)
  element:V("scrollOffset"):SetFloat(scrollOffset)
  element:parent().InfoFrame.Swiper:setScrollOffsetToMarker(element)
end
function SharedObjectInfo.FadeSprite.Sprite:onInit(element)
  self("spriteName"):SetString("gfx/fade_sprite")
  self:setScale(Vector2(17 * game.menuScaleX(), 0.5 * game.menuScaleY()))
  self("layer"):SetString("Clipping")
end
function SharedObjectInfo.BotFadeSprite.Sprite:onInit(element)
  self("spriteName"):SetString("gfx/fade_sprite")
  self:setScale(Vector2(15.5 * game.menuScaleX(), 0.5 * game.menuScaleY()))
  self("vFlip"):SetInt(1)
  self("layer"):SetString("Clipping")
end
function SharedObjectInfo.RightFadeSprite.Sprite:onInit(element)
  self("spriteName"):SetString("gfx/fade_sprite")
  self:setScale(Vector2(16 * game.menuScaleX(), 0.5 * game.menuScaleY()))
  self("rotation"):SetFloat(90)
  self("layer"):SetString("Clipping")
end
function SharedObjectInfo.LeftFadeSprite.Sprite:onInit(element)
  self("spriteName"):SetString("gfx/fade_sprite")
  self:setScale(Vector2(16 * game.menuScaleX(), 0.5 * game.menuScaleY()))
  self("rotation"):SetFloat(-90)
  self("layer"):SetString("Clipping")
end
function SharedObjectInfo.Animation:onInit()
  local component = self.Sprite
  local effect = self.Effect
  local selectedObject = game.SelectedObject()
  if selectedObject then
    if selectedObject:isMonster() and selectedObject:data():isModal() then
      local currentMode = game.player():getActiveIsland():islandMode()
      local animFile = game.getModalMonsterData(selectedObject:data(), currentMode):animationFile()
      component("animationName"):SetString("xml_bin/" .. animFile)
    else
      component("animationName"):SetString("xml_bin/" .. game.objectAnim())
    end
    local isAwakenedTitansoul = false
    local selectedObject = game.SelectedObject()
    if selectedObject and selectedObject:isTitansoul() and selectedObject:numSoulLinks() > 0 then
      isAwakenedTitansoul = true
    end
    if game.selectedObjectIsActiveBoxMonster() or game.selectedIsEvolvedMonster() and not game.isCelestialIsland() or isAwakenedTitansoul then
      local animUtil = game.AnimUtil(component)
      local hasActivateAnim = animUtil:hasAnimation("Activate")
      if hasActivateAnim then
        component("animation"):SetString("Activate")
        component("pingpong"):SetInt(1)
        local scale = 0.7 * game.menuScaleX()
        local monsterId = game.monsterTypeId(game.selectedMonsterId())
        if game.isWubboxType(monsterId) then
          scale = 0.3 * game.menuScaleX()
        elseif game.isUnderlingIsland() then
          scale = 0.43 * game.menuScaleX()
        elseif game.isCelestialIsland() then
          scale = 0.5 * game.menuScaleX()
        elseif isAwakenedTitansoul then
          scale = 0.25 * game.menuScaleX()
        end
        component:setScale(lua_sys.Vector2(scale, scale))
        self:setOrientationPosition(lua_sys.Vector2(component:size().x / 2, component:size().y / 2 + self:parent().ImageFrame:size().y / 2 - 30 * game.menuScaleX()))
      else
        component("animation"):SetString("Store")
        local scale = 0.7 * game.menuScaleX()
        local monsterId = game.monsterTypeId(game.selectedMonsterId())
        if game.isWubboxType(monsterId) then
          scale = 0.3 * game.menuScaleX()
        elseif game.isUnderlingIsland() then
          scale = 0.5 * game.menuScaleX()
        end
        component:setScale(lua_sys.Vector2(scale, scale))
        self:setOrientationPosition(lua_sys.Vector2(component:size().x / 2, component:size().y / 2 + 15 * game.hudScale()))
      end
    elseif game.selectedObjType() == game.SpecificEntityType_CRUCIBLE then
      component("animationName"):SetString("xml_bin/" .. game.getCrucibleAnimFile())
      component("animation"):SetString(game.getSelectedCrucibleCurAnim())
      component:setScale(lua_sys.Vector2(0.3 * game.menuScaleX(), 0.3 * game.menuScaleX()))
      self:setOrientationPosition(lua_sys.Vector2(component:size().x / 2, component:size().y / 2 + component:size().y / 6))
    elseif game.selectedObjType() == game.SpecificEntityType_AWAKENER then
      component("animation"):SetString(game.SelectedObject():getClosedAnim())
      component:setScale(lua_sys.Vector2(0.5 * game.menuScaleX(), 0.5 * game.menuScaleX()))
      self:setOrientationPosition(lua_sys.Vector2(component:size().x / 2, component:size().y / 2 + component:size().y / 6))
    elseif game.selectedObjType() == game.SpecificEntityType_TORCH then
      game.setTorchAnimState(game.selectedStructureId(), component)
      component:setScale(lua_sys.Vector2(0.4 * game.menuScaleX(), 0.4 * game.menuScaleX()))
      self:setOrientationPosition(lua_sys.Vector2(component:size().x / 2, component:size().y / 2 + component:size().y / 5))
    elseif game.selectedObjType() == game.SpecificEntityType_POLARITY_AMPLIFIER then
      effect("effect"):SetString("particles/Structures/PolarityAmplifier/FX_PolarityAmplifier_Level00.efkefc")
      effect("yOffset"):SetInt(30 * game.menuScaleX())
    else
      component("animation"):SetString(game.objectStoreAnim())
      if game.selectedObjType() == game.SpecificEntityType_BUDDY then
        game.tintInfoBuddy(self)
      end
      local currentMode = game.player():getActiveIsland():islandMode()
      if currentMode == 1 and (game.selectedObjType() == game.SpecificEntityType_FUGUE or game.selectedObjType() == game.SpecificEntityType_NURSERY or game.selectedObjType() == game.SpecificEntityType_BREEDING) then
        component("animation"):SetString(game.objectStoreAnim() .. "_minor")
      end
      component:setScale(lua_sys.Vector2(0.7 * game.menuScaleX(), 0.7 * game.menuScaleX()))
      if game.isBoxMonster(game.selectedMonsterId()) and game.isEpicMonster(game.selectedMonsterId()) then
        component("yOffset"):SetInt(20 * game.menuScaleX())
        component:setScale(lua_sys.Vector2(0.6 * game.menuScaleX(), 0.6 * game.menuScaleX()))
      end
      self:setOrientationPosition(lua_sys.Vector2(component:size().x / 2, component:size().y / 2 + 15 * game.hudScale()))
    end
    if game.selectedObjIsMonster() then
      local selectedMonsterId = game.selectedMonsterId()
      local equippedCostume = game.getEquippedCostumeForMonster(selectedMonsterId)
      game.applyCostumeToAnimComponent(component, equippedCostume)
    end
    if game.selectedObjType() == game.SpecificEntityType_ATTUNER then
      local activeAttunerGene = game.activeAttunerGene()
      component:AddRemap("window_placeholder_01.png", "gfx/attuner_windows/" .. activeAttunerGene.attunerGraphic)
    end
    if game.selectedObjType() == game.SpecificEntityType_DISH_HARMONIZER then
      local targetSheet = "dishharmonizer_" .. game.GetIsletPrimaryGeneName(game.currentIsland()) .. "_sheet.xml"
      game.remapMenuAnim(component, "dishharmonizer_plasma_sheet.xml", targetSheet)
    end
  end
  component("visible"):SetInt(0)
  component("layer"):SetString("PopUps")
end
function SharedObjectInfo.Animation.Touch:onTouchDown()
  if game.isDipster() then
    self:parent():PlayMe()
  end
end
function SharedObjectInfo.Animation:PlayMe()
  local component = self.Sprite
  local selectedMonsterId = game.selectedMonsterId()
  if selectedMonsterId == 0 then
    return
  end
  local monster = game.selectedMonster()
  if monster == nil then
    return
  end
  local s = game.getDipsterShenanigans()
  if s ~= "" then
    component("animationName"):SetString("xml_bin/" .. game.objectAnim())
    component("animation"):SetString(s)
    if monster:isAstralDipster() then
      component("yOffset"):SetInt(75)
      component:setScale(lua_sys.Vector2(0.525 * game.menuScaleX(), 0.525 * game.menuScaleX()))
      self:setOrientationPosition(lua_sys.Vector2(component:size().x / 2, component:size().y / 2 + 15 * game.hudScale()))
    elseif monster:isEpic() then
      component("yOffset"):SetInt(47)
      component:setScale(lua_sys.Vector2(0.7 * game.menuScaleX(), 0.7 * game.menuScaleX()))
      self:setOrientationPosition(lua_sys.Vector2(component:size().x / 2, component:size().y / 2 + 15 * game.hudScale()))
    else
      component("yOffset"):SetInt(35)
      component:setScale(lua_sys.Vector2(0.7 * game.menuScaleX(), 0.7 * game.menuScaleX()))
      self:setOrientationPosition(lua_sys.Vector2(component:size().x / 2, component:size().y / 2 + 15 * game.hudScale()))
    end
    local equippedCostume = game.getEquippedCostumeForMonster(selectedMonsterId)
    game.applyCostumeToAnimComponent(component, equippedCostume)
    component:Stop()
    component:Play()
  end
end
function SharedObjectInfo.TimeRemainingText:onPostInit()
  if game.selectedObjType() == game.SpecificEntityType_TORCH then
    local secondsRemaining = game.torchTime()
    if secondsRemaining > 0 and game.showTorchTime() then
      self.AvailableUntil("text"):SetString("ACTIVE_UNTIL")
      self.TimerText("text"):SetString(game.timeToString(secondsRemaining))
    else
      self:setInvisible()
    end
  elseif game.selectedObjType() == game.SpecificEntityType_MONSTER then
    local secondsRemaining = game.megaTimeRemaining(game.selectedMonsterId())
    if secondsRemaining > 0 then
      self.AvailableUntil("text"):SetString("BIGGIFIED_UNTIL")
      self.TimerText("text"):SetString(game.timeToString(secondsRemaining))
    else
      self:setInvisible()
    end
  else
    self:setInvisible()
  end
end
function SharedObjectInfo.TimeRemainingText:setInvisible()
  self.AvailableUntil("visible"):SetInt(0)
  self.TimerText("visible"):SetInt(0)
end
function SharedObjectInfo.TimeRemainingText:setVisible()
  self.AvailableUntil("visible"):SetInt(1)
  self.TimerText("visible"):SetInt(1)
end
function SharedObjectInfo.TimeRemainingText.AvailableUntil:onInit()
  self("multiline"):SetInt(0)
  self("font"):Set(game.getTextFont())
  self("size"):SetFloat(0.3 * game.hudScale())
  self("alignment"):SetInt(lua_sys.MenuTextComponent_TEXT_HCENTER_ALIGNED)
  self("text"):SetString("ACTIVE_UNTIL")
  self("autoScaleFactor"):SetFloat(0.01)
  self("autoScale"):SetInt(1)
  self("layer"):SetString("PopUps")
end
function SharedObjectInfo.TimeRemainingText.TimerText:onInit()
  self("textPadding"):SetInt(3 * game.menuScaleX())
  self("size"):SetFloat(0.3 * game.menuScaleY())
  self("autoScale"):SetInt(1)
  self("autoScaleFactor"):SetFloat(0.01)
  self("multiline"):SetInt(0)
  self("text"):SetString("")
  self("font"):Set(game.getTextFont())
  local palette = include("ColourPalette")
  self:setColor(palette:getRGBFloats(palette.AVAILABILITY_TIMER_COLOUR))
  self("alignment"):SetInt(MenuTextComponent_TEXT_HCENTER_ALIGNED)
  self("layer"):SetString("PopUps")
end
function SharedObjectInfo.TimeRemainingText.TimerText:onTick(element, dt)
  if self("visible"):GetInt() == 1 then
    if game.selectedObjType() == game.SpecificEntityType_TORCH then
      local secondsRemaining = game.torchTime()
      if secondsRemaining > 0 then
        self("text"):SetString(game.timeToString(secondsRemaining))
      else
        element:setInvisible()
      end
    elseif game.selectedObjType() == game.SpecificEntityType_MONSTER then
      local secondsRemaining = game.megaTimeRemaining(game.selectedMonsterId())
      if secondsRemaining > 0 then
        self("text"):SetString(game.timeToString(secondsRemaining))
      else
        element:setInvisible()
      end
    end
  end
end
function SharedObjectInfo.ImageTitle:gotMsgRequestNameMonster(msg)
  if msg.id == game.selectedMonsterId() then
    self.Text:V("noTranslate"):SetInt(1)
    self.Text:V("text"):SetString(game.objectName())
    self.Text:V("size"):SetFloat(0.35 * game.hudScale())
    self.Text:V("autoScale"):SetInt(1)
  end
end
function SharedObjectInfo.ImageTitle.Sprite:onInit(element)
  self("spriteName"):SetString("button_continue_green")
  self("sheetName"):SetString("xml_resources/buttons01.xml")
  self("size"):SetFloat(0.5 * game.menuScaleX())
  self("layer"):SetString("PopUps")
end
function SharedObjectInfo.ImageTitle.Touch:onTouchDown(element, x, y)
  element.Sprite:setColor(0.5, 0.5, 0.5)
end
function SharedObjectInfo.ImageTitle.Touch:onTouchRelease(element)
  element.Sprite:setColor(1, 1, 1)
end
function SharedObjectInfo.ImageTitle.Touch:onTouchUp(element, x, y)
  element.Sprite:setColor(1, 1, 1)
  if game.selectedObjIsMonster() then
    game.showMonsterNamePopup(game.getLocalizedText("ENTER_MONSTER_NAME"), game.objectName(), true, -1, 16, true, "MONSTER_NAME")
  end
end
function SharedObjectInfo.StatsList:gotMsgMonsterUpdated(msg)
  self:populateMonsterStats()
end
function SharedObjectInfo.StatsList:populateStatsArr(statsArray)
  local previous
  for i = 1, #statsArray do
    local statEntry = self:E("statEntry" .. i)
    if statEntry == nil then
      statEntry = menu:addTemplateElement(statsArray[i], "statEntry" .. i, self)
      if previous == nil then
        statEntry:relativeTo(self)
        statEntry:setOrientation(lua_sys.MenuOrientation(0, 0, -2, lua_sys.HCENTER, lua_sys.TOP))
        statEntry:setRelativeObjectAnchors(lua_sys.HCENTER, lua_sys.TOP)
      else
        statEntry:relativeTo(previous)
        statEntry:setOrientation(lua_sys.MenuOrientation(0, 0, 0, lua_sys.HCENTER, lua_sys.TOP))
        statEntry:setRelativeObjectAnchors(lua_sys.HCENTER, lua_sys.BOTTOM)
      end
      previous = statEntry
      statEntry:init()
      statEntry:setPositionBroadcast(true)
    else
      statEntry:DoStoredScript("repopulate")
    end
  end
  self.NumStats = #statsArray
end
function SharedObjectInfo.StatsList:populateCastleStats()
  local previous
  local statsArray = {
    "template_stat_bedsused",
    "template_stat_maxbeds",
    "template_stat_islandlikes",
    "template_stat_islandrank"
  }
  if game.isEtherealAtelierIsland() then
    table.insert(statsArray, "template_stat_critters")
  end
  for i = 1, #statsArray do
    local statEntry = menu:addTemplateElement(statsArray[i], "statEntry" .. i, self)
    if previous == nil then
      statEntry:relativeTo(self)
      statEntry:setOrientation(lua_sys.MenuOrientation(0, 0, -1, lua_sys.HCENTER, lua_sys.TOP))
      statEntry:setRelativeObjectAnchors(lua_sys.HCENTER, lua_sys.TOP)
    else
      statEntry:relativeTo(previous)
      statEntry:setOrientation(lua_sys.MenuOrientation(0, 0, 0, lua_sys.HCENTER, lua_sys.TOP))
      statEntry:setRelativeObjectAnchors(lua_sys.HCENTER, lua_sys.BOTTOM)
    end
    previous = statEntry
    statEntry:init()
    statEntry:setPositionBroadcast(true)
  end
  self.NumStats = #statsArray
end
function SharedObjectInfo.StatsList:showStats()
  local numStats = self.NumStats
  for i = 1, numStats do
    local stat = self:E("statEntry" .. i)
    if stat ~= nil then
      stat:setVisible()
    end
  end
end
function SharedObjectInfo.StatsList:hideStats()
  local numStats = self.NumStats
  for i = 1, numStats do
    local stat = self:E("statEntry" .. i)
    if stat ~= nil then
      stat:setInvisible()
    end
  end
end
function SharedObjectInfo.BioButton:setInvisible()
  self:super_setInvisible()
  self.Label:V("visible"):SetInt(0)
end
function SharedObjectInfo.BioButton.Label:onInit(element)
  self("multiline"):SetInt(0)
  self("font"):Set(game.getTextFont())
  self("size"):SetFloat(0.3 * game.hudScale())
  self("alignment"):SetInt(lua_sys.MenuTextComponent_TEXT_HCENTER_ALIGNED)
  self("text"):SetString(game.getLocalizedText("BIO"))
  self("autoScale"):SetInt(1)
  self("autoScaleFactor"):SetFloat(0.01)
  self("layer"):SetString("ContextBar")
end
function SharedObjectInfo.BioButton.Touch:onTouchUp(element, x, y)
  self:super_onTouchUp(element, x, y)
  element:parent().currentView = 0
  element:parent():refreshView()
end
function SharedObjectInfo.BioButton.Touch:onTouchRelease(element, x, y)
  self:super_onTouchRelease(element, x, y)
  element:parent().currentView = 0
  element:parent():refreshView()
end
function SharedObjectInfo.StatsButton.Label:onInit(element)
  local txt = game.getLocalizedText("STATS_LABEL")
  local x, y = txt:find("%s")
  if x == nil then
    self("multiline"):SetInt(0)
  else
    self("multiline"):SetInt(1)
  end
  self("autoScale"):SetInt(1)
  self("font"):Set(game.getTextFont())
  self("size"):SetFloat(0.3 * game.hudScale())
  self("alignment"):SetInt(lua_sys.MenuTextComponent_TEXT_HCENTER_ALIGNED)
  self("text"):SetString(txt)
  self("layer"):SetString("ContextBar")
end
function SharedObjectInfo.StatsButton.Touch:onTouchUp(element, x, y)
  self:super_onTouchUp(element, x, y)
  element:parent().currentView = 1
  element:parent():refreshView()
end
function SharedObjectInfo.StatsButton.Touch:onTouchRelease(element, x, y)
  self:super_onTouchRelease(element, x, y)
  element:parent().currentView = 1
  element:parent():refreshView()
end
return SharedObjectInfo
