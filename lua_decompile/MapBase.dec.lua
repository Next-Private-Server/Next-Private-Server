local IslandMapData = require("IslandMapData")
local MenuHelpers = require("MenuHelpers")
local OffsetTransition = require("OffsetTransition")
local FadeTransition = require("FadeTransition")
local Tweener = include("Tweener")
local Coroutines = include("Coroutines")
local TweenerPingPong = include("TweenerPingPong")
local MapBase = {
  Main = {
    IslandName = {
      Sprite = {},
      Text = {}
    },
    LeftButton = {
      Touch = {}
    },
    RightButton = {
      Touch = {}
    },
    IslandInfo = {
      BedsOccupied = {
        Text = {}
      },
      Collected = {},
      CollectedLayoutHelper = {},
      CostInfo = {
        SaleInfo = {},
        Cost = {}
      },
      Requirements = {
        Text = {}
      }
    },
    SeasonalInfo = {
      Title = {},
      LocalizedTitle = {},
      Timer = {}
    },
    ActivateButton = {
      Text = {},
      Touch = {}
    }
  },
  OptionsPanel = {
    SortButton = {
      Overlay = {},
      Text = {},
      Touch = {}
    },
    SaveButton = {
      NewNotification = {
        Sprite = {}
      },
      Overlay = {},
      Text = {},
      Touch = {}
    },
    ResetButton = {
      Overlay = {},
      Text = {},
      Touch = {}
    },
    MotionToggleButton = {
      Overlay = {},
      Text = {},
      Touch = {}
    }
  },
  IslandList = {
    OffsetTransition = {}
  },
  MirrorIslandList = {
    OffsetTransition = {}
  },
  TopHUD = {
    NotificationAlertButton = {},
    SaleAlertButton = {},
    SeasonalAlertButton = {}
  },
  BottomHUD = {
    OptionsButton = {
      Overlay = {},
      Text = {},
      Touch = {}
    },
    MirrorButton = {
      Overlay = {},
      Text = {},
      Touch = {},
      SaleIndicator = {}
    }
  },
  MinimizeButton = {
    Sprite = {},
    Touch = {}
  },
  SelectHole = {},
  ExitHole = {
    TouchBlocker = {
      Touch = {}
    }
  },
  Motes = {
    Particles = {}
  },
  OptionsOverlay = {
    Sprite = {},
    Touch = {}
  },
  SortingOverlay = {
    Sprite = {},
    Touch = {}
  },
  MotionModeOverlay = {
    Sprite = {}
  },
  PoiBackdrop = {
    BG = {}
  },
  PoiText = {
    Title = {},
    Body = {}
  }
}
local MapSongs = {
  {
    songFile = "audio/music/map_song",
    offsets = {
      0,
      19.2,
      28.8,
      48,
      67.2
    },
    isUnlocked = function(isMirrorMode)
      return not isMirrorMode
    end
  },
  {
    songFile = "audio/music/map_song_natural",
    offsets = {
      0,
      19.2,
      24,
      62.4
    },
    isUnlocked = function(isMirrorMode)
      if isMirrorMode then
        return false
      end
      return game.isIslandOwned(5) and game.isIslandOwned(4) and game.isIslandOwned(3) and game.isIslandOwned(2) and game.isIslandOwned(1)
    end
  },
  {
    songFile = "audio/music/map_song_fire",
    offsets = {
      0,
      19.2,
      38.4,
      57.6
    },
    isUnlocked = function(isMirrorMode)
      if isMirrorMode then
        return false
      end
      return game.isIslandOwned(13) and game.isIslandOwned(14) and game.isIslandOwned(22)
    end
  },
  {
    songFile = "audio/music/map_song_magical",
    offsets = {
      0,
      19.2,
      38.4,
      57.6
    },
    isUnlocked = function(isMirrorMode)
      if isMirrorMode then
        return false
      end
      return game.isIslandOwned(25) and game.isIslandOwned(19) and game.isIslandOwned(18) and game.isIslandOwned(17) and game.isIslandOwned(16) and game.isIslandOwned(15)
    end
  },
  {
    songFile = "audio/music/map_song_mirror",
    offsets = {
      0,
      28.8,
      48,
      67.2
    },
    isUnlocked = function(isMirrorMode)
      return isMirrorMode
    end
  },
  {
    songFile = "audio/music/map_song_natural_mirror",
    offsets = {
      0,
      28.8,
      48,
      67.2
    },
    isUnlocked = function(isMirrorMode)
      if not isMirrorMode then
        return false
      end
      return game.isIslandOwned(105) and game.isIslandOwned(104) and game.isIslandOwned(103) and game.isIslandOwned(102) and game.isIslandOwned(101)
    end
  },
  {
    songFile = "audio/music/map_song_magical_mirror",
    offsets = {
      0,
      19.2,
      38.4,
      57.6
    },
    isUnlocked = function(isMirrorMode)
      if not isMirrorMode then
        return false
      end
      return game.isIslandOwned(118) and game.isIslandOwned(117) and game.isIslandOwned(116) and game.isIslandOwned(115)
    end
  }
}
local CLUBBOX_MEMORY_ID = 1000000
local root
local showSelectHole = false
local showExitHole = true
local tickables = {}
function MapBase:onInit()
  root = self
  self.showingOptions = false
  self.selectedMapSong = nil
  if game.mapContext():isFriendMode() or not game.mapContext():isFromWorld() then
    game.stopPlayingMidi()
  end
  self.selectedIsland = 0
  local transitionDuration = 0.67
  local islandNameStartOffsetY = -lua_sys.screenHeight() * 0.5
  local transition = OffsetTransition:new({
    startY = islandNameStartOffsetY,
    endY = self.Main.IslandName:GetVar("yOffset"):GetFloat(),
    duration = transitionDuration,
    onUpdate = function(x, y)
      self.Main.IslandName:GetVar("yOffset"):SetFloat(y)
    end
  })
  transition:SetOffset(self.Main.IslandName:GetVar("xOffset"):GetFloat(), islandNameStartOffsetY)
  transition.id = "IslandNameOffsetTransition"
  tickables[transition.id] = transition
  self.Main.IslandName.OffsetTransition = transition
  transition = FadeTransition:new({
    duration = transitionDuration / 2,
    onUpdate = function(alpha)
      self.Main.IslandName:GetVar("alpha"):SetFloat(alpha)
      self.Main.IslandName.Text:GetVar("alpha"):SetFloat(alpha)
      self.Main.IslandName.Sprite:GetVar("alpha"):SetFloat(alpha)
    end
  })
  transition.id = "IslandNameFadeTransition"
  tickables[transition.id] = transition
  self.Main.IslandName.FadeTransition = transition
  function self.Main.IslandName.Show()
    if game.mapContext():inMotionSickMode() then
      self.Main.IslandName.FadeTransition:Show()
    else
      self.Main.IslandName.OffsetTransition:Show()
    end
  end
  function self.Main.IslandName.Hide()
    if game.mapContext():inMotionSickMode() then
      self.Main.IslandName.FadeTransition:Hide()
    else
      self.Main.IslandName.OffsetTransition:Hide()
    end
  end
  function self.Main.IslandName.Cancel()
    if game.mapContext():inMotionSickMode() then
      self.Main.IslandName.FadeTransition:Cancel()
    else
      self.Main.IslandName.OffsetTransition:Cancel()
    end
  end
  local activateButtonStartOffsetY = lua_sys.screenHeight()
  local activateButtonEndOffsetY = self.Main.ActivateButton:GetVar("yOffset"):GetFloat()
  if game.mapContext():isFriendMode() then
    activateButtonEndOffsetY = 64 * game.mapScale()
    self.Main.IslandInfo.Requirements:GetVar("yOffset"):SetFloat(90 * game.mapScale())
  end
  transition = FadeTransition:new({
    duration = 0.33,
    onUpdate = function(alpha)
      self.Main.ActivateButton:GetVar("alpha"):SetFloat(alpha)
      self.Main.ActivateButton:updateComponents()
    end,
    onDoneShow = function()
      game.mapContext():updateTutorialArrowOnButton()
    end
  })
  transition.id = "ActivateButtonFadeTransition"
  tickables[transition.id] = transition
  self.Main.ActivateButton.FadeTransition = transition
  transition = FadeTransition:new({
    duration = 0.33,
    onUpdate = function(alpha)
      self.Main.LeftButton:GetVar("alpha"):SetFloat(alpha)
      self.Main.LeftButton:updateComponents()
    end
  })
  transition.id = "LeftButtonFadeTransition"
  tickables[transition.id] = transition
  self.Main.LeftButton.FadeTransition = transition
  transition = FadeTransition:new({
    duration = 0.33,
    onUpdate = function(alpha)
      self.Main.RightButton:GetVar("alpha"):SetFloat(alpha)
      self.Main.RightButton:updateComponents()
    end
  })
  transition.id = "RightButtonFadeTransition"
  tickables[transition.id] = transition
  self.Main.RightButton.FadeTransition = transition
  transition = FadeTransition:new({
    duration = transitionDuration,
    onUpdate = function(alpha)
      self.Main.IslandInfo:SetAlpha(alpha)
    end
  })
  transition:SetAlpha(0)
  transition.id = "IslandInfoFadeTransition"
  tickables[transition.id] = transition
  self.Main.IslandInfo.FadeTransition = transition
  transition = FadeTransition:new({
    duration = 0.5,
    onUpdate = function(alpha)
      self.PoiText.Title:GetVar("alpha"):SetFloat(alpha)
      self.PoiText.Body:GetVar("alpha"):SetFloat(alpha)
    end
  })
  transition:SetAlpha(0)
  transition.id = "PoiTextFadeTransition"
  tickables[transition.id] = transition
  self.PoiText.FadeTransition = transition
  transition = FadeTransition:new({
    duration = 0.5,
    maxFade = 0.5,
    onUpdate = function(alpha)
      self.PoiBackdrop.BG:GetVar("alpha"):SetFloat(alpha)
    end
  })
  transition:SetAlpha(0)
  transition.id = "PoiBackdropFadeTransition"
  tickables[transition.id] = transition
  self.PoiBackdrop.FadeTransition = transition
  transition = FadeTransition:new({
    duration = transitionDuration,
    maxFade = 0.6,
    onUpdate = function(alpha)
      self.SortingOverlay.Sprite:GetVar("alpha"):SetFloat(alpha)
    end
  })
  transition:SetAlpha(0)
  transition.id = "SortingOverlayFadeTransition"
  tickables[transition.id] = transition
  self.SortingOverlay.FadeTransition = transition
  transition = FadeTransition:new({
    duration = transitionDuration,
    maxFade = 0.6,
    onUpdate = function(alpha)
      self.OptionsOverlay.Sprite:GetVar("alpha"):SetFloat(alpha)
    end
  })
  transition:SetAlpha(0)
  transition.id = "OptionsOverlayFadeTransition"
  tickables[transition.id] = transition
  self.OptionsOverlay.FadeTransition = transition
  transition = OffsetTransition:new({
    startY = -lua_sys.screenHeight() * 0.5 - 110 * game.mapScale(),
    endY = 0,
    duration = transitionDuration,
    ease = lua_sys.Back_EaseIn,
    onUpdate = function(x, y)
      self.OptionsPanel:GetVar("yOffset"):SetFloat(y)
    end
  })
  transition.id = "OptionsPanelOffsetTransition"
  tickables[transition.id] = transition
  self.OptionsPanel.OffsetTransition = transition
  transition = FadeTransition:new({
    duration = transitionDuration / 1.5,
    onUpdate = function(alpha)
      self.MotionModeOverlay.Sprite:GetVar("alpha"):SetFloat(alpha)
    end
  })
  transition:SetAlpha(0)
  transition.id = "MotionModeOverlayFadeTransition"
  tickables[transition.id] = transition
  self.MotionModeOverlay.FadeTransition = transition
  local listTransitionDuration = 0.67
  transition = OffsetTransition:new({
    startX = -430 * game.mapScale(),
    endX = -24 * game.mapScale(),
    duration = listTransitionDuration,
    ease = lua_sys.Linear_EaseNone,
    onUpdate = function(x, y)
      self.IslandList:GetVar("xOffset"):SetFloat(x)
      self.TopHUD:GetVar("xOffset"):SetFloat(x)
    end
  })
  transition.id = "IslandListOffsetTransition"
  tickables[transition.id] = transition
  self.IslandList.OffsetTransition = transition
  transition = OffsetTransition:new({
    startX = -430 * game.mapScale(),
    endX = -24 * game.mapScale(),
    duration = listTransitionDuration,
    ease = lua_sys.Linear_EaseNone,
    onUpdate = function(x, y)
      self.MirrorIslandList:GetVar("xOffset"):SetFloat(x)
      self.TopHUD:GetVar("xOffset"):SetFloat(x)
    end
  })
  transition.id = "MirrorIslandListOffsetTransition"
  tickables[transition.id] = transition
  self.MirrorIslandList.OffsetTransition = transition
  transition = OffsetTransition:new({
    startX = -self.BottomHUD:absW(),
    endX = 0,
    duration = 0.67,
    ease = lua_sys.Linear_EaseNone,
    onUpdate = function(x, y)
      self.BottomHUD:GetVar("xOffset"):SetFloat(x)
    end
  })
  transition.id = "BottomHUDTransition"
  tickables[transition.id] = transition
  self.BottomHUD.OffsetTransition = transition
  transition = OffsetTransition:new({
    startX = -lua_sys.screenWidth(),
    endX = 30 * game.mapScale(),
    duration = transitionDuration,
    ease = lua_sys.Linear_EaseNone,
    onUpdate = function(x, y)
      self.Main.SeasonalInfo:GetVar("xOffset"):SetFloat(x)
    end
  })
  transition:SetOffset(-lua_sys.screenWidth(), self.Main.SeasonalInfo:GetVar("yOffset"):GetFloat())
  transition.id = "SeasonalInfoOffsetTransition"
  tickables[transition.id] = transition
  self.Main.SeasonalInfo.OffsetTransition = transition
  self.Main.SeasonalInfo.isShowing = false
  transition = FadeTransition:new({
    duration = 2,
    onUpdate = function(alpha)
      self.Motes.Particles:GetVar("alpha"):SetFloat(alpha)
    end
  })
  transition:SetAlpha(0)
  transition.id = "ParticleFadeTransition"
  tickables[transition.id] = transition
  self.Motes.FadeTransition = transition
  local alert = TweenerPingPong:new({
    loopTime = 0.4,
    ease = lua_sys.Quadratic_EaseIn
  })
  alert.id = "CollectedAlert"
  tickables[alert.id] = alert
  self.Main.Collected.alert = alert
  self.islandInfoHidden = true
  function self.IslandList.OnEntrySelected(islandId)
    self:SelectIsland(islandId)
  end
  function self.IslandList.OnEntryDeselected()
    if game.mapContext():inMotionSickMode() then
      function self.MotionModeOverlay.FadeTransition.onDoneShow()
        self.MotionModeOverlay.FadeTransition.ease = lua_sys.Quadratic_EaseOut
        self.MotionModeOverlay.FadeTransition:Hide()
        game.mapContext():deselectNode()
        game.mapContext():showPoiPins(false)
      end
      self:ResetContext()
      self:HideIslandInfo()
      self.MotionModeOverlay.FadeTransition.ease = lua_sys.Quadratic_EaseIn
      self.MotionModeOverlay.FadeTransition:Show()
    else
      game.mapContext():deselectNode()
      game.mapContext():showPoiPins()
    end
  end
  function self.IslandList.OnDirtyChanged(dirty)
    if dirty then
      self.OptionsPanel.SaveButton.NewNotification.Sprite:GetVar("visible"):SetInt(1)
    else
      self.OptionsPanel.SaveButton.NewNotification.Sprite:GetVar("visible"):SetInt(0)
    end
  end
  function self.MirrorIslandList.OnEntrySelected(islandId)
    self:SelectIsland(IslandMapData:GetIslandData(islandId).id)
  end
  function self.MirrorIslandList.OnEntryDeselected()
    if game.mapContext():inMotionSickMode() then
      function self.MotionModeOverlay.FadeTransition.onDoneShow()
        self.MotionModeOverlay.FadeTransition.ease = lua_sys.Quadratic_EaseOut
        self.MotionModeOverlay.FadeTransition:Hide()
        game.mapContext():deselectNode()
        game.mapContext():showPoiPins(false)
      end
      self:ResetContext()
      self:HideIslandInfo()
      self.MotionModeOverlay.FadeTransition.ease = lua_sys.Quadratic_EaseIn
      self.MotionModeOverlay.FadeTransition:Show()
    else
      game.mapContext():deselectNode()
      game.mapContext():showPoiPins()
    end
  end
  function self.MirrorIslandList.OnDirtyChanged(dirty)
    if dirty then
      self.OptionsPanel.SaveButton.NewNotification.Sprite:GetVar("visible"):SetInt(1)
    else
      self.OptionsPanel.SaveButton.NewNotification.Sprite:GetVar("visible"):SetInt(0)
    end
  end
  if showSelectHole then
    self.SelectHole:Setup()
    tickables.SelectHole = self.SelectHole
  end
  if showExitHole then
    self.ExitHole:Setup({
      onComplete = function()
        local currentIsland = game.currentIsland()
        local selectedIslandId = self.selectedIsland
        if game.showPaironormalMinor() and selectedIslandId == game.IslandType_PAIRONORMAL then
          local currentPlayer = game.player()
          if game.mapContext():isFriendMode() then
            currentPlayer = game.getVisitedFriend()
          end
          if currentIsland == game.IslandType_PAIRONORMAL then
            local paironormalIsland = currentPlayer:getIslandWithId(game.IslandType_PAIRONORMAL)
            if paironormalIsland and paironormalIsland:islandMode() == 1 then
              currentIsland = currentIsland + 100
            end
          end
          local selectedIsland = currentPlayer:getIslandWithId(game.IslandType_PAIRONORMAL)
          if selectedIsland then
            game.changeIslandMode(selectedIsland, root.isMirrorMode and 1 or 0)
          end
          if self.isMirrorMode then
            selectedIslandId = selectedIslandId + 100
          end
        end
        if selectedIslandId == currentIsland then
          game.loadWorldContext(false, "load_map")
        else
          game.activateIslandOnIslandMap(selectedIslandId)
        end
        game.stopPlayingMp3()
      end
    })
    tickables.ExitHole = self.ExitHole
  end
  if not game.mapContext():isFriendMode() then
    if game.currentIsland() == game.IslandType_BATTLE then
      transition = FadeTransition:new({
        duration = 4,
        onUpdate = function(alpha)
          if transition.targetAlpha == 1 then
            if alpha > 0.5 and not self.playingMapMusic then
              self.worldMusicTime = lua_sys.getMp3CurrentTime()
              self.playingMapMusic = true
              if self.mapMusicStartTime then
                lua_sys.playMP3(self.selectedMapSong)
                lua_sys.setMp3CurrentTime(self.mapMusicStartTime)
                self.mapMusicTimeRemaining = lua_sys.getMp3Duration() - self.mapMusicStartTime
              else
                self:playNextMapSong()
              end
            end
          elseif alpha < 0.5 and self.playingMapMusic then
            self.mapMusicStartTime = lua_sys.getMp3CurrentTime()
            self.playingMapMusic = false
            lua_sys.playMP3(self.battleMusic)
            lua_sys.setMp3CurrentTime(self.worldMusicTime)
          end
          local a = math.abs((alpha - 0.5) * 2)
          game.setMp3Fade(a, 0)
        end
      })
    else
      transition = FadeTransition:new({
        duration = 4,
        onUpdate = function(alpha)
          game.setMidiFade(1 - alpha, 0)
          game.setMp3Fade(alpha, 0)
        end
      })
      game.setMp3Fade(0, 0)
    end
    transition.id = "MusicCrossfadeTransition"
    tickables[transition.id] = transition
    self.crossfadeTransition = transition
  end
end
function MapBase:onPostInit()
  local currentIsland = game.currentIsland()
  game.mapContext():setNodeRadius(64)
  self.focusOffsetX = lua_sys.screenWidth() - self.Main:absW() * 0.5 - lua_sys.deviceMarginX()
  self.focusOffsetY = lua_sys.screenHeight() * 0.35
  game.mapContext():setFocusOffset(lua_sys.Vector2(self.focusOffsetX, self.focusOffsetY))
  game.mapContext():setXOffsetMinimize(420 * game.mapScale())
  self.Main.IslandInfo.Collected.CollectedRares.BaseSpriteSize = self.Main.IslandInfo.Collected.CollectedRares.Sprite:GetVar("size"):GetFloat()
  self.Main.IslandInfo.Collected.CollectedEpics.BaseSpriteSize = self.Main.IslandInfo.Collected.CollectedEpics.Sprite:GetVar("size"):GetFloat()
  self.Main.IslandInfo.Collected.CollectedSeasonals.BaseSpriteSize = self.Main.IslandInfo.Collected.CollectedSeasonals.Sprite:GetVar("size"):GetFloat()
  if game.mapContext():isFriendMode() then
    currentIsland = game.currentFriendIsland()
    if game.currentFriendIslandType() == game.IslandType_COMPOSER then
      currentIsland = game.IslandType_COMPOSER
    end
  elseif game.currentIslandType() == game.IslandType_COMPOSER then
    currentIsland = game.IslandType_COMPOSER
  end
  self.isMirrorMode = IslandMapData:GetIslandData(currentIsland).on_mirror_map
  if game.showPaironormalMinor() and currentIsland == game.IslandType_PAIRONORMAL then
    local currentPlayer = game.player()
    if game.mapContext():isFriendMode() then
      currentPlayer = game.getVisitedFriend()
    end
    local island = currentPlayer:getIslandWithId(currentIsland)
    self.isMirrorMode = island:islandMode() == 1
  end
  local initialFocusIsland = game.mapContext():initialFocusIsland()
  if initialFocusIsland > 0 then
    self.isMirrorMode = IslandMapData:GetIslandData(initialFocusIsland).on_mirror_map
  end
  self.isMinimized = false
  game.mapContext():setMirrorMode(self.isMirrorMode, false)
  local regularIslands = game.islandSorting(false)
  local mirrorIslands = game.islandSorting(true)
  local islands = self.isMirrorMode and mirrorIslands or regularIslands
  self:refreshNodes(islands, 1)
  if not game.mapContext():isFriendMode() then
    game.mapContext():showActiveIndicator(false)
  end
  self.IslandList:Populate(regularIslands, false)
  self.MirrorIslandList:Populate(mirrorIslands, true)
  if self.isMirrorMode then
    self.IslandList.OffsetTransition:SetOffset(-lua_sys.screenWidth(), 0)
    self.Motes.FadeTransition:Show()
  else
    self.MirrorIslandList.OffsetTransition:SetOffset(-lua_sys.screenWidth(), 0)
  end
  self.TopHUD:GetVar("xOffset"):SetFloat(0)
  self.seasonalIslandIdx = 0
  self.seasonalIslands = {}
  for i = 0, regularIslands:size() - 1 do
    local islandId = regularIslands[i]
    local islandMapData = IslandMapData:GetIslandData(islandId)
    local islandSeasonalThemeData = islandMapData:getAvailableSeasonalThemeData()
    if islandSeasonalThemeData then
      table.insert(self.seasonalIslands, islandId)
    end
  end
  self.seasonalIslandsMirror = {}
  for i = 0, mirrorIslands:size() - 1 do
    local islandId = mirrorIslands[i]
    local islandMapData = IslandMapData:GetIslandData(islandId)
    local islandSeasonalThemeData = islandMapData:getAvailableSeasonalThemeData()
    if islandSeasonalThemeData then
      table.insert(self.seasonalIslandsMirror, islandId)
    end
  end
  self.saleIslandIdx = 0
  self.saleIslands = {}
  for i = 0, regularIslands:size() - 1 do
    local islandId = regularIslands[i]
    if game.islandSale(islandId) then
      table.insert(self.saleIslands, islandId)
    end
  end
  self.saleIslandsMirror = {}
  for i = 0, mirrorIslands:size() - 1 do
    local islandId = mirrorIslands[i]
    if game.islandSale(islandId) then
      table.insert(self.saleIslandsMirror, islandId)
    end
  end
  self:RefreshButtons()
  local startSelected = initialFocusIsland > 0
  if startSelected then
    print("Initial Focus Island = ", initialFocusIsland)
    self.queuedIslandSelection = initialFocusIsland
  else
    if self.isMirrorMode then
      self.MirrorIslandList:CenterScrollingList(currentIsland, false)
      self.MirrorIslandList.Swiper:onTick(self.MirrorIslandList, 0)
    else
      self.IslandList:CenterScrollingList(currentIsland, false)
      self.IslandList.Swiper:onTick(self.IslandList, 0)
    end
    RunIndyCoroutine(function()
      game.mapContext():focusOnNode(currentIsland, IslandMapData:GetIslandData(currentIsland).node, false, false)
      Coroutines.WaitForSeconds(0.1)
      game.mapContext():deselectNode(true, false)
      game.mapContext():showPoiPins(false)
    end)
  end
  if currentIsland == game.IslandType_BATTLE then
    self.playingMapMusic = false
    local battleMusicId = game.getBattlePlayerData():getCurrentlyPlayingBattleMusic()
    self.battleMusic = game.getBattleMusicData(battleMusicId).file
  else
    self.playingMapMusic = true
    self:playNextMapSong()
  end
  local minimizeSetting = game.getLocalSettings():get("mapMinimized")
  if minimizeSetting == "1" then
    if self.isMirrorMode then
      self.MirrorIslandList:GetVar("xOffset"):SetFloat(-430 * game.mapScale())
    else
      self.IslandList:GetVar("xOffset"):SetFloat(-430 * game.mapScale())
    end
    self.TopHUD:GetVar("xOffset"):SetFloat(-430 * game.mapScale())
    self.BottomHUD:GetVar("xOffset"):SetFloat(-self.BottomHUD:absW())
    self.MinimizeButton.Sprite:GetVar("spriteName"):SetString("button_show_hud")
    self.isMinimized = true
    self.Main:setSize(lua_sys.Vector2(lua_sys.screenWidth() - lua_sys.deviceMarginX(), lua_sys.screenHeight() - lua_sys.deviceMarginY()))
    self.focusOffsetX = (lua_sys.screenWidth() - lua_sys.deviceMarginX()) * 0.5
    game.mapContext():setFocusOffset(lua_sys.Vector2(self.focusOffsetX, self.focusOffsetY))
    game.mapContext():setXOffsetMinimize(0)
    game.mapContext():setMinimized(self.isMinimized)
  end
  if game.mapContext():inMotionSickMode() then
    self.Main.IslandName.FadeTransition:SetAlpha(0)
    self.Main.IslandName:GetVar("yOffset"):SetFloat(24 * game.mapScale())
  end
end
function MapBase:refreshNodes(islands, initialAlpha)
  local currentIsland = game.currentIsland()
  local currentIslandMode = 0
  if currentIsland == game.IslandType_PAIRONORMAL and self.isMirrorMode then
    currentIslandMode = 1
  end
  local currentIslandMapData = IslandMapData:GetIslandData(currentIsland, currentIslandMode)
  for i = 0, islands:size() - 1 do
    local islandId = islands[i]
    local islandMode = 0
    if islandId == game.IslandType_PAIRONORMAL and self.isMirrorMode then
      islandMode = 1
    end
    local islandMapData = IslandMapData:GetIslandData(islands[i], islandMode)
    local isIslandOwned = game.isIslandOwned(islandId)
    if game.mapContext():isFriendMode() then
      isIslandOwned = game.doesFriendOwnIsland(islandId)
    end
    if isIslandOwned then
      game.mapContext():setNodePinAnim(islandMapData.node, "xml_bin/map_pins_location_large.bin", islandMapData:getPinAnim(), islandMapData:getPinSheet(), islandMapData:getPinSprite(), initialAlpha)
    else
      local iconSheet = islandMapData:getSelectedIslandIconSheet()
      local iconSprite = islandMapData:getSelectedIslandIconSprite()
      if self.isMirrorMode and islandMapData.type == game.IslandType_PAIRONORMAL then
        iconSprite = iconSprite .. "_MIN"
      end
      game.mapContext():setNodeSelectedSheetImage(islandMapData.node, iconSheet, iconSprite, lua_sys.Vector2(0, 24))
    end
    if not game.mapContext():isFriendMode() and islandId == currentIslandMapData.id then
      local onMirror = islandMapData.on_mirror_map
      game.mapContext():setActiveIndicator(islandMapData.location_node, onMirror)
    end
    if game.mapContext():isFriendMode() then
      local showTorch = game.islandHasUnlitTorches(islandId)
      if showTorch then
        game.mapContext():addTorchSticker(islandMapData.node, game.getIslandTorchGfx(islandId), lua_sys.Vector2(-84, 104), false)
      end
    end
    if isIslandOwned and game.clubboxActIsAvail() then
      local currentPlayer = game.player()
      if game.mapContext():isFriendMode() then
        currentPlayer = game.getVisitedFriend()
      end
      local currentClubboxAct = currentPlayer:currentyActiveClubbox()
      if currentClubboxAct ~= nil and 0 < currentClubboxAct:actId() then
        local clubbox = currentPlayer:getPlayerClubbox(currentClubboxAct:actId())
        local island = currentPlayer:getIslandWithId(islandId)
        if clubbox and clubbox:islandId() == island:uniqueId() then
          game.mapContext():addClubboxSticker(islandMapData.node, lua_sys.Vector2(-80, -38))
        end
      end
    end
  end
  local pois = game.mapContext():getPointsOfInterest()
  for i = 0, pois:size() - 1 do
    game.mapContext():setNodePinAnim(pois[i], "xml_bin/map_pins_location_large.bin", "pin_pointofinterest_idle", "map_pins_sheet_01.xml", "map_pin_pointofinterest", initialAlpha)
  end
  if not self.isMirrorMode then
    game.mapContext():setNodePinAnim("special_memory", "xml_bin/map_pins_location_large.bin", "special_memory", "", "", initialAlpha)
  end
end
function MapBase:playNextMapSong()
  local available = {}
  for k, v in ipairs(MapSongs) do
    if v.isUnlocked(self.isMirrorMode) then
      table.insert(available, v)
    end
  end
  if #available > 0 then
    local selectedSongData
    if not self.selectedMapSong then
      selectedSongData = available[math.random(#available)]
    else
      local idx = 0
      for i = 1, #available do
        if available[i].songFile == self.selectedMapSong then
          idx = i
          break
        end
      end
      idx = idx % #available + 1
      selectedSongData = available[idx]
    end
    if selectedSongData then
      self.mapMusicStartTime = 0
      if not self.selectedMapSong then
        self.mapMusicStartTime = selectedSongData.offsets[math.random(#selectedSongData.offsets)]
      end
      self.selectedMapSong = selectedSongData.songFile
      print("Now Playing:", self.selectedMapSong, self.mapMusicStartTime)
      lua_sys.playMP3(self.selectedMapSong)
      lua_sys.setMp3CurrentTime(self.mapMusicStartTime)
      self.mapMusicTimeRemaining = lua_sys.getMp3Duration() - self.mapMusicStartTime
    end
  else
    print("Error! no songs available!")
  end
end
function MapBase:tickMusic(dt)
  if self.playingMapMusic then
    self.mapMusicTimeRemaining = self.mapMusicTimeRemaining - dt
    if self.mapMusicTimeRemaining <= 0 then
      self:playNextMapSong()
    end
  end
end
function MapBase:onTick(dt)
  if self.queuedIslandSelection then
    self:SelectIsland(self.queuedIslandSelection)
    self.queuedIslandSelection = nil
  end
  for _, v in pairs(tickables) do
    v:Tick(dt)
  end
  self:tickMusic(dt)
  if self.Main.SeasonalInfo.isShowing then
    local shouldHide = false
    local eventData = self.Main.SeasonalInfo.eventData
    if eventData then
      local timeLeft = game.timedAvailIslandThemeTimeRemaining(eventData.id)
      if timeLeft > 0 then
        local timeLeftStr = game.timeToString(timeLeft)
        self.Main.SeasonalInfo.Timer:GetVar("text"):SetString(timeLeftStr)
      else
        shouldHide = true
      end
    else
      shouldHide = true
    end
    if shouldHide then
      self.Main.SeasonalInfo.isShowing = false
      self.Main.SeasonalInfo.OffsetTransition:Hide()
    end
  end
end
function MapBase:SelectIslandByNodeName(name)
  local isMirrorMode = self.isMirrorMode
  local islandId = IslandMapData:GetIslandIdByNodeName(name, isMirrorMode)
  if islandId > 0 then
    self:SelectIsland(IslandMapData:GetIslandData(islandId).id)
  end
end
function MapBase:SelectIsland(islandId, animate)
  if self.selectedIsland == islandId then
    return
  end
  if not IslandMapData:GetIslandData(islandId) then
    return
  end
  if self.selectedIsland > 0 then
    self:DeselectIsland()
  end
  print("Select Island", islandId)
  if animate == nil then
    animate = true
  end
  if animate then
    lua_sys.playSoundFx("audio/sfx/menu_click.wav")
  end
  if showSelectHole then
    self.SelectHole:SetHolePosition((self.Main.IslandName:absX() + self.Main.IslandName:absW() * 0.5) / lua_sys.screenWidth(), (self.Main.IslandName:absY() + self.Main.IslandName:absH() * 0.5 - self.Main.IslandName:GetVar("yOffset"):GetFloat() + 195 * game.mapScale()) / lua_sys.screenHeight())
    self.SelectHole:Show(true)
  end
  self.selectedIsland = islandId
  local isUnlocked = game.isIslandOwned(islandId) or game.hasNecessaryPrevIslandsToUnlock(islandId) and game.canUnlockIsland(islandId) or islandId == CLUBBOX_MEMORY_ID
  local isOwned = game.isIslandOwned(islandId) or islandId == CLUBBOX_MEMORY_ID
  local motionMode = game.mapContext():inMotionSickMode()
  local islandMapData = IslandMapData:GetIslandData(islandId)
  if not self.sortingMode then
    if motionMode then
      function self.MotionModeOverlay.FadeTransition.onDoneShow()
        game.mapContext():focusOnNode(islandId, islandMapData.node, animate, isUnlocked and not isOwned)
        self.MotionModeOverlay.FadeTransition.ease = lua_sys.Quadratic_EaseOut
        self.MotionModeOverlay.FadeTransition:Hide()
      end
      self.MotionModeOverlay.FadeTransition.ease = lua_sys.Quadratic_EaseIn
      self.MotionModeOverlay.FadeTransition:Show()
    else
      game.mapContext():focusOnNode(islandId, islandMapData.node, animate, isUnlocked and not isOwned)
    end
  end
  if self.isMirrorMode then
    self.MirrorIslandList:SelectIsland(islandId, animate, motionMode)
  else
    self.IslandList:SelectIsland(islandId, animate, motionMode)
  end
  local currentIsland = game.currentIsland()
  if game.mapContext():isFriendMode() then
    currentIsland = game.currentFriendIsland()
    if game.currentFriendIslandType() == game.IslandType_COMPOSER then
      currentIsland = game.IslandType_COMPOSER
    end
  elseif game.currentIslandType() == game.IslandType_COMPOSER then
    currentIsland = game.IslandType_COMPOSER
  end
  if self.crossfadeTransition then
    if islandId == currentIsland and not self.sortingMode then
      self.crossfadeTransition:Hide()
    else
      self.crossfadeTransition:Show()
    end
  end
  if not self.showingOptions then
    game.getContextBar():setContext("MAP_FOCUSED")
  end
end
function MapBase:OnDoneFocus()
  self:ShowIslandInfo(self.selectedIsland)
  self:ShowSeasonalInfo(self.selectedIsland)
end
function MapBase:DeselectIsland()
  if self.selectedIsland == 0 then
    return
  end
  self.selectedIsland = 0
  if self.isMirrorMode then
    self.MirrorIslandList:DeselectIsland()
  else
    self.IslandList:DeselectIsland()
  end
  if not self.sortingMode then
    self:HideIslandInfo()
  end
  self.SelectHole:Hide()
  if self.crossfadeTransition then
    self.crossfadeTransition:Show()
  end
  self:ResetContext()
end
function MapBase:ShowSeasonalInfo(islandId)
  if islandId == 0 then
    return
  end
  local e = self.Main.SeasonalInfo
  local islandMapData = IslandMapData:GetIslandData(islandId)
  e.eventData = islandMapData:getAvailableSeasonalThemeData()
  if e.eventData then
    if e.eventData.titleCard then
      e.Title:GetVar("spriteName"):SetString(e.eventData.titleCard)
    end
    if game.currentLanguage() ~= "en" or not e.eventData.titleCard then
      e.Title:GetVar("visible"):SetInt(0)
      e.LocalizedTitle:GetVar("visible"):SetInt(1)
      e.LocalizedTitle:GetVar("text"):SetString(game.islandThemeName(e.eventData.id))
    else
      e.LocalizedTitle:GetVar("visible"):SetInt(0)
      e.Title:GetVar("visible"):SetInt(1)
    end
    e.OffsetTransition:Show()
    e.isShowing = true
  end
end
local shouldShowLimitedAvailabilityIndicator = function(islandId)
  return islandId ~= game.IslandType_AMBER and islandId ~= game.IslandType_CELESTIAL and islandId ~= game.IslandType_UNDERLING
end
local hasLimitedAvailabilityCache = {}
local function hasLimitedAvailability(islandId, filter, cacheKey)
  if cacheKey then
    local cached = hasLimitedAvailabilityCache[cacheKey]
    if cached ~= nil then
      return cached
    end
  end
  local availableMonstersIds = game.getAllMonstersForBookOfMonstersIsland(islandId)
  local availableMonsters = {}
  for i = 0, availableMonstersIds:size() - 1 do
    local monsterId = availableMonstersIds[i]
    local monster = game.getMonsterData(monsterId)
    if filter and filter(monster) and game.monsterLimitedAvailability(monsterId, false) then
      if cacheKey then
        hasLimitedAvailabilityCache[cacheKey] = true
      end
      return true
    end
  end
  if cacheKey then
    hasLimitedAvailabilityCache[cacheKey] = false
  end
  return false
end
function MapBase:ShowIslandInfo(islandId)
  if islandId == 0 then
    return
  end
  if not self.islandInfoHidden then
    return
  end
  local islandMapData = IslandMapData:GetIslandData(islandId)
  local islandName = game.islandName(islandId)
  if islandId == CLUBBOX_MEMORY_ID then
    islandName = "CLUBBOX_MEMORY"
  end
  self.Main.IslandName.Text:GetVar("text"):SetString(islandName)
  self.Main.IslandName:setSize(lua_sys.Vector2(math.max(252 * game.mapScale(), self.Main.IslandName.Text:absW() + 48 * game.mapScale()), self.Main.IslandName:absH()))
  self.Main.IslandName.Show()
  self.Main.IslandInfo.FadeTransition:Show()
  self.Main.LeftButton.FadeTransition:Show()
  self.Main.RightButton.FadeTransition:Show()
  self.Main.LeftButton.Touch:GetVar("enabled"):SetInt(1)
  self.Main.RightButton.Touch:GetVar("enabled"):SetInt(1)
  local islandInfoVisibleElements = {}
  local function hideCollected()
    self.Main.IslandInfo.Collected.CollectedCommons:Hide()
    self.Main.IslandInfo.Collected.CollectedRares:Hide()
    self.Main.IslandInfo.Collected.CollectedEpics:Hide()
    self.Main.IslandInfo.Collected.CollectedSeasonals:Hide()
    self.Main.IslandInfo.Collected.CollectedCostumes:Hide()
  end
  if game.mapContext():isFriendMode() or islandId == game.IslandType_TRIBAL or islandId == game.IslandType_COMPOSER or not game.isIslandOwned(islandId) then
    self.Main.IslandInfo.BedsOccupied.Text:GetVar("visible"):SetInt(0)
    hideCollected()
  else
    local pulsedIcons = {}
    self.Main.IslandInfo.BedsOccupied.Text:GetVar("visible"):SetInt(1)
    local bedsOccupiedStr = game.islandBeds(islandId)
    self.Main.IslandInfo.BedsOccupied.Text:GetVar("text"):SetString(bedsOccupiedStr)
    if bedsOccupiedStr ~= "" then
      table.insert(islandInfoVisibleElements, self.Main.IslandInfo.BedsOccupied)
    end
    local includeSeasonals = game.islandType(islandId) == game.IslandType_SEASONAL
    local curr = 0
    local total = 0
    local islandMode = 0
    if self.isMirrorMode and islandId == game.IslandType_PAIRONORMAL then
      islandMode = 1
    end
    game.setBookOfMonstersIslandId(islandId, islandMode)
    curr = game.numUniqueCommonsCollectedOnBookOfMonstersIsland(includeSeasonals)
    total = game.getAllUniqueCommonsForIslandType(game.getBookOfMonstersIslandType(), islandMode, includeSeasonals)
    self.Main.IslandInfo.Collected.CollectedCommons.Text:GetVar("text"):SetString(curr .. "/" .. total)
    local iconImage = islandId == game.IslandType_CELESTIAL and "map_celestial_icon" or "map_common_icon"
    self.Main.IslandInfo.Collected.CollectedCommons.Sprite:GetVar("spriteName"):SetString(iconImage)
    local tooltipText = islandId == game.IslandType_CELESTIAL and "YOUTH_LABEL" or "COMMONS_LABEL"
    self.Main.IslandInfo.Collected.CollectedCommons.Tooltip:setText(tooltipText)
    self.Main.IslandInfo.Collected.CollectedCommons:Show()
    curr = game.numUniqueRaresCollectedOnBookOfMonstersIsland(includeSeasonals)
    total = game.getAllUniqueRaresForIslandType(game.getBookOfMonstersIslandType(), islandMode, includeSeasonals)
    self.Main.IslandInfo.Collected.CollectedRares.Text:GetVar("text"):SetString(curr .. "/" .. total)
    local iconImage = islandId == game.IslandType_CELESTIAL and "map_ascension_icon" or "map_rare_icon"
    self.Main.IslandInfo.Collected.CollectedRares.Sprite:GetVar("spriteName"):SetString(iconImage)
    local tooltipText = islandId == game.IslandType_CELESTIAL and "ADULT_LABEL" or "RARES_LABEL"
    self.Main.IslandInfo.Collected.CollectedRares.Tooltip:setText(tooltipText)
    if total > 0 then
      self.Main.IslandInfo.Collected.CollectedRares:Show()
      local size = self.Main.Collected.CollectedRares.BaseSpriteSize
      self.Main.IslandInfo.Collected.CollectedRares.Sprite:GetVar("size"):SetFloat(size)
      if shouldShowLimitedAvailabilityIndicator(islandId) and hasLimitedAvailability(islandId, function(monster)
        return monster:isRareMonster()
      end, "rare" .. islandId) then
        table.insert(pulsedIcons, self.Main.IslandInfo.Collected.CollectedRares.Sprite)
      end
    else
      self.Main.IslandInfo.Collected.CollectedRares:Hide()
    end
    curr = game.numUniqueEpicsCollectedOnBookOfMonstersIsland(includeSeasonals)
    total = game.getAllUniqueEpicsForIslandType(game.getBookOfMonstersIslandType(), islandMode, includeSeasonals)
    self.Main.IslandInfo.Collected.CollectedEpics.Text:GetVar("text"):SetString(curr .. "/" .. total)
    local tooltipText = islandId == game.IslandType_CELESTIAL and "ELDER_LABEL" or "EPICS_LABEL"
    self.Main.IslandInfo.Collected.CollectedEpics.Tooltip:setText(tooltipText)
    if total > 0 then
      self.Main.IslandInfo.Collected.CollectedEpics:Show()
      local size = self.Main.Collected.CollectedEpics.BaseSpriteSize
      self.Main.IslandInfo.Collected.CollectedEpics.Sprite:GetVar("size"):SetFloat(size)
      if shouldShowLimitedAvailabilityIndicator(islandId) and hasLimitedAvailability(islandId, function(monster)
        return monster:isEpicMonster()
      end, "epic" .. islandId) then
        table.insert(pulsedIcons, self.Main.IslandInfo.Collected.CollectedEpics.Sprite)
      end
    else
      self.Main.IslandInfo.Collected.CollectedEpics:Hide()
    end
    if game.showSeasonalCount() then
      self.Main.IslandInfo.Collected.CollectedSeasonals:Show()
      curr = game.numUniqueSeasonalsCollectedOnBookOfMonstersIsland()
      total = game.getAllUniqueSeasonalsForIslandType(game.getBookOfMonstersIslandType(), islandMode)
      self.Main.IslandInfo.Collected.CollectedSeasonals.Text:GetVar("text"):SetString(curr .. "/" .. total)
    else
      total = 0
    end
    if total > 0 then
      self.Main.IslandInfo.Collected.CollectedSeasonals:Show()
      local size = self.Main.Collected.CollectedSeasonals.BaseSpriteSize
      self.Main.IslandInfo.Collected.CollectedSeasonals.Sprite:GetVar("size"):SetFloat(size)
      if shouldShowLimitedAvailabilityIndicator(islandId) and hasLimitedAvailability(islandId, function(monster)
        return monster:isSeasonal()
      end, "seasonal" .. islandId) then
        table.insert(pulsedIcons, self.Main.IslandInfo.Collected.CollectedSeasonals.Sprite)
      end
    else
      self.Main.IslandInfo.Collected.CollectedSeasonals:Hide()
    end
    local costumeIsland = game.getBookOfMonstersIslandType()
    curr = game.numUniqueCostumesCollectedOnBookOfMonstersIsland()
    total = game.getAllUniqueCostumesForIslandType(costumeIsland, islandMode, false)
    self.Main.IslandInfo.Collected.CollectedCostumes.Text:GetVar("text"):SetString(curr .. "/" .. total)
    if total > 0 and game.getBookOfMonstersIslandType() ~= game.IslandType_GOLD then
      self.Main.IslandInfo.Collected.CollectedCostumes:Show()
    else
      self.Main.IslandInfo.Collected.CollectedCostumes:Hide()
    end
    self.Main.IslandInfo.CollectedLayoutHelper:Refresh()
    table.insert(islandInfoVisibleElements, MenuHelpers.CreateSpacer(0, 12 * game.mapScale()))
    table.insert(islandInfoVisibleElements, self.Main.IslandInfo.Collected)
    self.Main.IslandInfo.Collected.alert.targets = pulsedIcons
  end
  local showRequirements = false
  local showCost = false
  local showSale = false
  local showActivateButton = false
  if game.mapContext():isFriendMode() then
    if game.doesFriendOwnIsland(islandId) then
      showActivateButton = true
      self.Main.ActivateButton:setVisible()
      self.Main.ActivateButton.Text:GetVar("text"):SetString(game.getLocalizedText("GO"))
      self.Main.ActivateButton.Touch:GetVar("enabled"):SetInt(1)
      self.Main.IslandInfo.Requirements.Text:GetVar("text"):SetString("")
    else
      showRequirements = true
      local txt = game.getLocalizedText("LOCKED")
      self.Main.IslandInfo.Requirements.Text:GetVar("text"):SetString(txt)
    end
  elseif not game.hasNecessaryPrevIslandsToUnlock(islandId) and not game.isIslandOwned(islandId) and islandId ~= CLUBBOX_MEMORY_ID then
    showRequirements = true
    local txt = game.getLocalizedText("NOTIFICATION_REQUIRES_ITEM")
    txt = select(1, txt:gsub("XXX", game.getLocalizedText(game.islandName(game.islandLockIsland(islandId)))))
    self.Main.IslandInfo.Requirements.Text:GetVar("text"):SetString(txt)
  elseif not game.canUnlockIsland(islandId) and not game.isIslandOwned(islandId) and islandId ~= CLUBBOX_MEMORY_ID then
    showRequirements = true
    if islandId ~= game.IslandType_BATTLE then
      local txt = game.getLocalizedText("NOTIFICATION_REQUIRES_LEVEL")
      txt = select(1, txt:gsub("XXX", game.islandUnlockLevel(islandId)))
      self.Main.IslandInfo.Requirements.Text:GetVar("text"):SetString(txt)
    else
      local txt = game.getLocalizedText("BATTLE_ISLAND_LOCKED")
      txt = select(1, txt:gsub("XXX", game.islandUnlockLevel(islandId)))
      self.Main.IslandInfo.Requirements.Text:GetVar("text"):SetString(txt)
    end
  else
    self.Main.IslandInfo.Requirements.Text:GetVar("text"):SetString("")
    if not game.isIslandOwned(islandId) and islandId ~= CLUBBOX_MEMORY_ID then
      showCost = true
      if game.islandCost(islandId) == 0 then
        self.Main.IslandInfo.CostInfo.Cost:Show()
        self.Main.IslandInfo.CostInfo.Cost.Text:GetVar("text"):SetString("FREE")
        self.Main.IslandInfo.CostInfo.Cost.Text:setColor(1, 1, 1)
        self.Main.IslandInfo.CostInfo.Cost.Sprite:GetVar("spriteName"):SetString("")
        self.Main.IslandInfo.CostInfo.Cost:Refresh()
        showActivateButton = true
        self.Main.ActivateButton:setVisible()
        self.Main.ActivateButton.Text:GetVar("text"):SetString("GO")
      else
        local currencyStr = game.islandCurrency(islandId)
        local costStr = game.commaizeNumber(game.islandCost(islandId))
        local currencySprite = game.StoreContext_getSpriteFromCurrencyTypeStr(currencyStr)
        if game.islandSale(islandId) then
          showSale = true
          local saleCostStr = costStr
          costStr = game.commaizeNumber(game.islandSaleCost(islandId))
          self.Main.IslandInfo.CostInfo.SaleInfo:Show()
          self.Main.IslandInfo.CostInfo.SaleInfo.Text:GetVar("text"):SetString(saleCostStr)
          game.StoreContext_setCurrencyTypeColour(currencyStr, self.Main.IslandInfo.CostInfo.SaleInfo.Text)
          self.Main.IslandInfo.CostInfo.SaleInfo.Sprite:GetVar("spriteName"):SetString(currencySprite)
          self.Main.IslandInfo.CostInfo.SaleInfo:Refresh()
        end
        self.Main.IslandInfo.CostInfo.Cost:Show()
        self.Main.IslandInfo.CostInfo.Cost.Text:GetVar("text"):SetString(costStr)
        game.StoreContext_setCurrencyTypeColour(currencyStr, self.Main.IslandInfo.CostInfo.Cost.Text)
        self.Main.IslandInfo.CostInfo.Cost.Sprite:GetVar("spriteName"):SetString(currencySprite)
        self.Main.IslandInfo.CostInfo.Cost:Refresh()
        showActivateButton = true
        self.Main.ActivateButton:setVisible()
        self.Main.ActivateButton.Text:GetVar("text"):SetString("BUY_BUTTON")
      end
    else
      showActivateButton = true
      self.Main.ActivateButton:setVisible()
      if IslandMapData:GetIslandData(game.currentIsland()).id == islandId then
        self.Main.ActivateButton.Text:GetVar("text"):SetString("YOU_ARE_HERE")
      elseif islandId == CLUBBOX_MEMORY_ID then
        self.Main.ActivateButton.Text:GetVar("text"):SetString("ACTIVATE")
      else
        self.Main.ActivateButton.Text:GetVar("text"):SetString("GO")
      end
    end
  end
  local costInfoHeight = 0
  if showSale then
    local offset = 40 * game.mapScale()
    costInfoHeight = self.Main.IslandInfo.CostInfo.SaleInfo:absH() + offset
    self.Main.IslandInfo.CostInfo.Cost:GetVar("yOffset"):SetFloat(costInfoHeight)
  else
    self.Main.IslandInfo.CostInfo.Cost:GetVar("yOffset"):SetFloat(0)
    self.Main.IslandInfo.CostInfo.SaleInfo:Hide()
  end
  if showCost then
    costInfoHeight = costInfoHeight + self.Main.IslandInfo.CostInfo.Cost:absH()
  else
    self.Main.IslandInfo.CostInfo.Cost:Hide()
  end
  if costInfoHeight > 0 then
    self.Main.IslandInfo.CostInfo:setSize(lua_sys.Vector2(self.Main.IslandInfo.CostInfo:absW(), costInfoHeight))
    table.insert(islandInfoVisibleElements, self.Main.IslandInfo.CostInfo)
  end
  if showRequirements then
    table.insert(islandInfoVisibleElements, self.Main.IslandInfo.Requirements)
  end
  MenuHelpers.ApplyVerticalLayout(islandInfoVisibleElements)
  local infoHeight = 0
  for _, v in pairs(islandInfoVisibleElements) do
    print("adding element:", v.name and v:name() or "spacer", v:absH())
    infoHeight = infoHeight + v:absH()
  end
  self.Main.IslandInfo:setSize(lua_sys.Vector2(self.Main.IslandInfo:absW(), infoHeight))
  if showActivateButton then
    self.Main.ActivateButton.FadeTransition:SetAlpha(0.1)
    self.Main.ActivateButton.Touch:GetVar("enabled"):SetInt(1)
    self.Main.ActivateButton.FadeTransition:Show()
  else
    self.Main.ActivateButton:setInvisible()
    self.Main.ActivateButton.Touch:GetVar("enabled"):SetInt(0)
  end
  self.islandInfoHidden = false
end
function MapBase:HideIslandInfo()
  if self.islandInfoHidden then
    return
  end
  self.Main.IslandName.Hide()
  self.Main.LeftButton.FadeTransition:Hide()
  self.Main.RightButton.FadeTransition:Hide()
  self.Main.LeftButton.Touch:GetVar("enabled"):SetInt(0)
  self.Main.RightButton.Touch:GetVar("enabled"):SetInt(0)
  self.Main.ActivateButton.FadeTransition:Hide()
  self.Main.ActivateButton.Touch:GetVar("enabled"):SetInt(0)
  self.Main.IslandInfo.FadeTransition:Cancel()
  self.Main.IslandInfo.FadeTransition:SetAlpha(0)
  if self.Main.ActivateButton:GetVar("ButtonState"):GetInt() == game.BUTTON_PRESSED then
    self.Main.ActivateButton.Touch:onTouchRelease(self.Main.ActivateButton)
  end
  if self.Main.LeftButton:GetVar("ButtonState"):GetInt() == game.BUTTON_PRESSED then
    self.Main.LeftButton.Touch:onTouchRelease(self.Main.LeftButton)
  end
  if self.Main.RightButton:GetVar("ButtonState"):GetInt() == game.BUTTON_PRESSED then
    self.Main.RightButton.Touch:onTouchRelease(self.Main.RightButton)
  end
  local hideCollected = function(collected)
    collected.Tooltip.FadeTransition:Cancel()
    collected.Tooltip.FadeTransition:SetAlpha(0)
    collected.Touch:GetVar("enabled"):SetInt(0)
  end
  hideCollected(self.Main.IslandInfo.Collected.CollectedCommons)
  hideCollected(self.Main.IslandInfo.Collected.CollectedRares)
  hideCollected(self.Main.IslandInfo.Collected.CollectedEpics)
  hideCollected(self.Main.IslandInfo.Collected.CollectedSeasonals)
  hideCollected(self.Main.IslandInfo.Collected.CollectedCostumes)
  if self.Main.SeasonalInfo.isShowing then
    self.Main.SeasonalInfo.isShowing = false
    self.Main.SeasonalInfo.OffsetTransition:Hide()
  end
  self.islandInfoHidden = true
end
function MapBase:ToggleMirror()
  if self.IslandList.OffsetTransition.remainingTime > 0 or 0 < self.MirrorIslandList.OffsetTransition.remainingTime then
    return
  end
  game.mapContext():deselectNode()
  local function changeNodes()
    game.mapContext():clearNodeGfx()
    local islands = game.islandSorting(self.isMirrorMode)
    self:refreshNodes(islands, 0)
    game.mapContext():showPins()
    local currentIsland = game.currentIsland()
    if not game.mapContext():isFriendMode() and (currentIsland == game.IslandType_PAIRONORMAL or IslandMapData:GetIslandData(currentIsland).on_mirror_map == self.isMirrorMode) then
      game.mapContext():showActiveIndicator()
    end
  end
  local function crossfadeMusic()
    self.selectedMapSong = nil
    self:playNextMapSong()
    if self.crossfadeTransition then
      self.crossfadeTransition:Show()
    end
  end
  if not self.isMinimized then
    if self.isMirrorMode then
      self.MirrorIslandList.OffsetTransition:Hide()
    else
      self.IslandList.OffsetTransition:Hide()
    end
  else
    local tweener = Tweener:new({
      duration = 0.67,
      onDone = function()
        changeNodes()
        crossfadeMusic()
      end
    })
    tweener.id = "NodesWait"
    tickables[tweener.id] = tweener
    tweener:activate()
  end
  if self.sortingMode then
    self:ToggleSortingMode()
  end
  self.isMirrorMode = not self.isMirrorMode
  self.MinimizeButton.Touch:GetVar("enabled"):SetInt(0)
  local currentIsland = game.currentIsland()
  game.mapContext():setMirrorMode(self.isMirrorMode)
  game.mapContext():hidePins()
  if not game.mapContext():isFriendMode() then
    game.mapContext():hideActiveIndicator()
  end
  game.setMp3Fade(0, self.IslandList.OffsetTransition.duration)
  if self.isMirrorMode then
    self.Motes.FadeTransition:Show()
    self.IslandList:Disable()
    function self.IslandList.OffsetTransition.onDoneHide()
      changeNodes()
      self.MirrorIslandList.OffsetTransition:SetOffset(-lua_sys.screenWidth(), 0)
      self.MirrorIslandList.OffsetTransition:Show()
      self.MirrorIslandList:Enable()
      crossfadeMusic()
    end
    function self.MirrorIslandList.OffsetTransition.onDoneShow()
      self.MinimizeButton.Touch:GetVar("enabled"):SetInt(1)
    end
  else
    self.Motes.FadeTransition:Hide()
    self.MirrorIslandList:Disable()
    function self.MirrorIslandList.OffsetTransition.onDoneHide()
      changeNodes()
      self.IslandList.OffsetTransition:SetOffset(-lua_sys.screenWidth(), 0)
      self.IslandList.OffsetTransition:Show()
      self.IslandList:Enable()
      crossfadeMusic()
    end
    function self.IslandList.OffsetTransition.onDoneShow()
      self.MinimizeButton.Touch:GetVar("enabled"):SetInt(1)
    end
  end
  self.BottomHUD.MirrorButton.Overlay:GetVar("spriteName"):SetString(self.isMirrorMode and "button_mirror_out" or "button_mirror_in")
  self.BottomHUD.MirrorButton.Text:GetVar("text"):SetString(self.isMirrorMode and "CONTEXTBAR_UNMIRROR_LABEL" or "CONTEXTBAR_MIRROR_LABEL")
  self:RefreshButtons()
end
function MapBase:ToggleSortingMode()
  if self.selectedIsland ~= 0 then
    game.mapContext():deselectNode()
    game.mapContext():showPoiPins(not game.mapContext():inMotionSickMode())
  end
  self.sortingMode = not self.sortingMode
  if self.isMirrorMode then
    self.MirrorIslandList:SortingMode(self.sortingMode)
  else
    self.IslandList:SortingMode(self.sortingMode)
  end
  if not self.sortingMode then
    if self.isMirrorMode then
      if self.MirrorIslandList.dirty then
        local islands = game.islandSorting(self.isMirrorMode)
        self.MirrorIslandList:SortEntries(islands)
      end
    elseif self.IslandList.dirty then
      local islands = game.islandSorting(self.isMirrorMode)
      self.IslandList:SortEntries(islands)
    end
  end
  if self.sortingMode then
    self.SortingOverlay.FadeTransition:Show()
    self.SortingOverlay.Touch:GetVar("enabled"):SetInt(1)
    self.MinimizeButton.Touch:GetVar("enabled"):SetInt(0)
    game.logEvent("map_options", "action", "toggle_sortmode_on")
  else
    self.SortingOverlay.FadeTransition:Hide()
    self.SortingOverlay.Touch:GetVar("enabled"):SetInt(0)
    self.MinimizeButton.Touch:GetVar("enabled"):SetInt(1)
    game.logEvent("map_options", "action", "toggle_sortmode_off")
  end
  self:RefreshButtons()
end
function MapBase:SaveIslandCustomSorting()
  if self.isMirrorMode then
    if self.MirrorIslandList.dirty then
      if self.MirrorIslandList.orderReset then
        game.getLocalSettings():set("mapCustomSortingMirror", "")
      else
        game.getLocalSettings():set("mapCustomSortingMirror", self.MirrorIslandList:GetCustomSortingList())
      end
      self.MirrorIslandList.DragAndDropHelper:ResetOriginalOrder()
    end
  elseif self.IslandList.dirty then
    if self.IslandList.orderReset then
      game.getLocalSettings():set("mapCustomSorting", "")
    else
      game.getLocalSettings():set("mapCustomSorting", self.IslandList:GetCustomSortingList())
    end
    self.IslandList.DragAndDropHelper:ResetOriginalOrder()
  end
end
function MapBase:ResetIslandCustomSorting()
  local islands = game.islandSorting(self.isMirrorMode, true)
  if self.isMirrorMode then
    self.MirrorIslandList:SortEntries(islands)
    self.MirrorIslandList.orderReset = true
  else
    self.IslandList:SortEntries(islands)
    self.IslandList.orderReset = true
  end
  game.logEvent("map_options", "action", "reset_island_sorting")
end
function MapBase:ToggleMinimize()
  local durationTime = 0
  local startLerp = 0
  local endLerp = 0
  local endTarget = 0
  local startOffsetX = 0
  if self.isMinimized then
    if self.isMirrorMode then
      self.MirrorIslandList.OffsetTransition:Show()
      self.MirrorIslandList.OffsetTransition.onDoneShow = nil
    else
      self.IslandList.OffsetTransition:Show()
      self.IslandList.OffsetTransition.onDoneShow = nil
    end
    self.MinimizeButton.Sprite:GetVar("spriteName"):SetString("button_hide_hud")
    self.BottomHUD.OffsetTransition:Show()
    self.isMinimized = false
    durationTime = 0.67
    startLerp = lua_sys.deviceMarginX()
    endLerp = 420 * game.mapScale()
    endTarget = lua_sys.screenWidth() - (lua_sys.screenWidth() - 420 * game.mapScale()) * 0.5 - lua_sys.deviceMarginX()
    startOffsetX = 0
  else
    if self.isMirrorMode then
      self.MirrorIslandList.OffsetTransition:Hide()
      self.MirrorIslandList.OffsetTransition.onDoneHide = nil
    else
      self.IslandList.OffsetTransition:Hide()
      self.IslandList.OffsetTransition.onDoneHide = nil
    end
    self.MinimizeButton.Sprite:GetVar("spriteName"):SetString("button_show_hud")
    self.BottomHUD.OffsetTransition:Hide()
    self.isMinimized = true
    durationTime = 0.67
    startLerp = 420 * game.mapScale()
    endLerp = lua_sys.deviceMarginX()
    endTarget = (lua_sys.screenWidth() - lua_sys.deviceMarginX()) * 0.5
    startOffsetX = 420 * game.mapScale()
  end
  local tweener = Tweener:new({
    duration = durationTime,
    initialValue = 0,
    targetValue = 1,
    ease = lua_sys.Linear_EaseNone,
    onUpdate = function(value)
      local dx = lerp(startLerp, endLerp, value)
      self.Main:setSize(lua_sys.Vector2(lua_sys.screenWidth() - dx, lua_sys.screenHeight() - lua_sys.deviceMarginY()))
      dx = lerp(self.focusOffsetX, endTarget, value)
      game.mapContext():setFocusOffset(lua_sys.Vector2(dx, self.focusOffsetY))
      dx = lerp(startOffsetX, 420 * game.mapScale() - startOffsetX, value)
      game.mapContext():setXOffsetMinimize(dx)
    end,
    onDone = function()
      self.focusOffsetX = endTarget
      self.MinimizeButton.Touch:GetVar("enabled"):SetInt(1)
      game.mapContext():onToggleMinimizeEnd()
      self.IslandList:Enable()
      self.MirrorIslandList:Enable()
      game.mapContext():setMinimized(self.isMinimized)
    end
  })
  local minimizeSetting = self.isMinimized and "1" or "0"
  game.getLocalSettings():set("mapMinimized", minimizeSetting)
  tweener.id = "IslandListMinimize"
  tickables[tweener.id] = tweener
  tweener:activate()
  game.mapContext():onToggleMinimizeStart()
  self.MinimizeButton.Touch:GetVar("enabled"):SetInt(0)
  self.IslandList:Disable()
  self.MirrorIslandList:Disable()
end
function MapBase.Main.ActivateButton:ActivateIsland()
  local islandId = root.selectedIsland
  if islandId == 0 then
    return
  end
  if islandId == CLUBBOX_MEMORY_ID then
    if not game.hasPopUp("map_clubbox_memories") then
      game.pushPopUp("map_clubbox_memories")
    end
    return
  end
  local isFriendMode = game.mapContext():isFriendMode()
  if isFriendMode then
    if islandId ~= game.IslandType_COMPOSER then
      if game.showPaironormalMinor() and islandId == game.IslandType_PAIRONORMAL then
        local selectedIsland = game.getVisitedFriend():getIslandWithId(game.IslandType_PAIRONORMAL)
        if selectedIsland then
          game.changeIslandMode(selectedIsland, root.isMirrorMode and 1 or 0)
        end
      end
      game.visitFriendIsland(islandId)
    else
      game.getContextBar():setContext("BLANK")
      menu:pushPopUp("friend_composer_island_select")
    end
    return
  end
  if not game.hasNecessaryPrevIslandsToUnlock(islandId) and not game.isIslandOwned(islandId) then
    local txt = game.getLocalizedText("NOTIFICATION_REQUIRES_ITEM")
    txt = select(1, txt:gsub("XXX", game.getLocalizedText(game.islandName(game.islandLockIsland(islandId)))))
    game.displayNotification(txt)
  elseif not game.canUnlockIsland(islandId) and not game.isIslandOwned(islandId) then
    if islandId ~= game.IslandType_BATTLE then
      local txt = game.getLocalizedText("NOTIFICATION_REQUIRES_LEVEL")
      txt = select(1, txt:gsub("XXX", game.islandUnlockLevel(islandId)))
      game.displayNotification(txt)
    else
      local txt = game.getLocalizedText("BATTLE_ISLAND_LOCKED")
      txt = select(1, txt:gsub("XXX", game.islandUnlockLevel(islandId)))
      game.displayNotification(txt)
    end
  elseif not game.isIslandOwned(islandId) then
    if islandId == game.IslandType_TRIBAL then
      game.getContextBar():setContext("TRIBAL_MENU")
    elseif showExitHole then
      local cost = game.getIslandCostOnIslandMap(islandId)
      local type = game.getIslandCostTypeOnIslandMap(islandId)
      if cost > 0 then
        game.displayIslandPurchaseConfirmation(islandId, cost, type)
      else
        root:DoExitTransition()
      end
    else
      game.activateIslandOnIslandMap(islandId)
    end
  elseif islandId ~= game.IslandType_COMPOSER then
    if showExitHole then
      print("Show Exit Hole")
      root:DoExitTransition()
    else
      local currentIsland = game.currentIsland()
      local selectedIslandId = islandId
      if game.showPaironormalMinor() and selectedIslandId == game.IslandType_PAIRONORMAL then
        local currentPlayer = game.player()
        if game.mapContext():isFriendMode() then
          currentPlayer = game.getVisitedFriend()
        end
        if currentIsland == game.IslandType_PAIRONORMAL then
          local paironormalIsland = currentPlayer:getIslandWithId(game.IslandType_PAIRONORMAL)
          if paironormalIsland and paironormalIsland:islandMode() == 1 then
            currentIsland = currentIsland + 100
          end
        end
        local selectedIsland = currentPlayer:getIslandWithId(game.IslandType_PAIRONORMAL)
        if selectedIsland then
          game.changeIslandMode(selectedIsland, root.isMirrorMode and 1 or 0)
        end
        if self.isMirrorMode then
          selectedIslandId = selectedIslandId + 100
        end
      end
      if selectedIslandId == game.currentIsland() then
        game.loadWorldContext(false, "load_overlay")
      else
        game.activateIslandOnIslandMap(selectedIslandId)
      end
      game.stopPlayingMp3()
    end
  else
    game.getContextBar():setContext("BLANK")
    menu:pushPopUp("composer_island_select")
  end
end
function MapBase.Main.IslandInfo:SetAlpha(alpha)
  self.BedsOccupied.Text:GetVar("alpha"):SetFloat(alpha)
  local function setCollectedAlpha(collected)
    collected.alpha = alpha
    collected:updateComponents()
  end
  setCollectedAlpha(self.Collected.CollectedCommons)
  setCollectedAlpha(self.Collected.CollectedRares)
  setCollectedAlpha(self.Collected.CollectedEpics)
  setCollectedAlpha(self.Collected.CollectedSeasonals)
  setCollectedAlpha(self.Collected.CollectedCostumes)
  self.CostInfo.Cost.alpha = alpha
  self.CostInfo.Cost:updateComponents()
  self.CostInfo.SaleInfo.alpha = alpha
  self.CostInfo.SaleInfo:updateComponents()
  self.Requirements.Text:GetVar("alpha"):SetFloat(alpha)
end
function MapBase:DoExitTransition()
  local mapContext = game.mapContext()
  mapContext:hideArrow()
  local exitHoleX = (self.Main.IslandName:absX() + self.Main.IslandName:absW() * 0.5) / lua_sys.screenWidth()
  local exitHoleY = (self.Main.IslandName:absY() + self.Main.IslandName:absH() * 0.5 - self.Main.IslandName:GetVar("yOffset"):GetFloat() + 195 * game.mapScale()) / lua_sys.screenHeight()
  self.ExitHole:SetHolePosition(exitHoleX, exitHoleY)
  self:HideIslandInfo()
  local centerOnExit = true
  if centerOnExit then
    local tweener = Tweener:new({
      duration = self.ExitHole.Tweener.transitionDuration,
      initialValue = 0,
      targetValue = 1,
      ease = self.ExitHole.Tweener.transitionEasing,
      onUpdate = function(value)
        local dx = lerp(self.focusOffsetX, lua_sys.screenWidth() * 0.5, value)
        local dy = lerp(self.focusOffsetY, lua_sys.screenHeight() * 0.5, value)
        mapContext:setFocusOffset(lua_sys.Vector2(dx, dy))
        dx = lerp(exitHoleX, 0.5, value)
        dy = lerp(exitHoleY, 0.5, value)
        self.ExitHole:SetHolePosition(dx, dy)
      end
    })
    tweener.id = "ExitTransitionExtra"
    tickables[tweener.id] = tweener
    tweener:activate()
  else
    self.Main.IslandName.Cancel()
  end
  if not self.isMinimized then
    if self.isMirrorMode then
      self.MirrorIslandList.OffsetTransition:Hide()
      self.MirrorIslandList.OffsetTransition.onDoneHide = nil
    else
      self.IslandList.OffsetTransition:Hide()
      self.IslandList.OffsetTransition.onDoneHide = nil
    end
  end
  self.BottomHUD.MirrorButton:setInvisible()
  self.BottomHUD.MirrorButton.Overlay:GetVar("visible"):SetInt(0)
  self.BottomHUD.MirrorButton.Text:GetVar("visible"):SetInt(0)
  self.BottomHUD.MirrorButton.SaleIndicator:SetInvisible()
  self.BottomHUD.OptionsButton:setInvisible()
  self.BottomHUD.OptionsButton.Overlay:GetVar("visible"):SetInt(0)
  self.BottomHUD.OptionsButton.Text:GetVar("visible"):SetInt(0)
  self.MinimizeButton:hide()
  self.ExitHole.TouchBlocker.Touch:GetVar("enabled"):SetInt(1)
  self.ExitHole:Show(true)
  game.getContextBar():setContext("BLANK")
end
function MapBase:HoleTest()
  print("Hole Test")
  if self.showingHoleEffect then
    self.showingHoleEffect = false
    self.SelectHole:Show(true)
  else
    self.showingHoleEffect = true
    self.SelectHole:Hide(true)
  end
end
function MapBase:OnFirstMovement()
  if self.crossfadeTransition then
    self.crossfadeTransition:Show()
  end
end
function MapBase:EnableMinimize(enabled)
  if self.MinimizeButton then
    self.MinimizeButton.Touch:GetVar("enabled"):SetInt(enabled)
  end
end
function MapBase:RefreshButtons()
  local initButton = function(button, label, spriteSheet, spriteName, action, layer)
    layer = layer or button.Overlay:GetVar("layer"):GetString()
    button.Overlay:GetVar("layer"):SetString(layer)
    button.Text:GetVar("layer"):SetString(layer)
    button.Overlay:GetVar("sheetName"):SetString(spriteSheet)
    button.Overlay:GetVar("spriteName"):SetString(spriteName)
    if button.Text then
      button.Text:GetVar("text"):SetString(label)
    end
    button.buttonAction = action
  end
  local buttons = self.BottomHUD
  if not self.showingOptions then
    buttons.OptionsButton:setVisible()
    buttons.MirrorButton:setVisible()
    if not game.mapContext():isFriendMode() and #self.saleIslandsMirror > 0 then
      buttons.MirrorButton.SaleIndicator:SetVisible()
      buttons.MirrorButton.SaleIndicator("setNewScale"):SetFloat(game.hudScale())
    else
      buttons.MirrorButton.SaleIndicator:SetInvisible()
    end
  else
    buttons.OptionsButton:setInvisible()
    buttons.MirrorButton:setInvisible()
    buttons.MirrorButton.SaleIndicator:SetInvisible()
  end
  initButton(buttons.OptionsButton, "CONTEXTBAR_OPTIONS_LABEL", "xml_resources/context_buttons.xml", "button_options", function()
    self:ShowOptions()
  end)
  initButton(buttons.MirrorButton, self.isMirrorMode and "CONTEXTBAR_UNMIRROR_LABEL" or "CONTEXTBAR_MIRROR_LABEL", "xml_resources/hud03.xml", self.isMirrorMode and "button_mirror_out" or "button_mirror_in", function()
    self:ToggleMirror()
  end)
  local buttons = self.OptionsPanel
  if self.showingOptions and not self.sortingMode then
    buttons.SortButton:setVisible()
    buttons.MotionToggleButton:setVisible()
  else
    buttons.SortButton:setInvisible()
    buttons.MotionToggleButton:setInvisible()
  end
  if self.showingOptions and self.sortingMode then
    buttons.SaveButton:setVisible()
    buttons.ResetButton:setVisible()
  else
    buttons.SaveButton:setInvisible()
    buttons.ResetButton:setInvisible()
  end
  initButton(buttons.SortButton, self.sortingMode and "LABEL_CANCEL" or "MAP_SORT", self.sortingMode and "xml_resources/context_buttons.xml" or "xml_resources/map_hud.xml", self.sortingMode and "button_no" or "button_map_sort", function()
    if self.isMinimized then
      self:ToggleMinimize()
    end
    self.OptionsOverlay.FadeTransition:Hide()
    self.OptionsOverlay.Touch:GetVar("enabled"):SetInt(0)
    self:ToggleSortingMode()
  end, "FrontPopUps")
  initButton(buttons.MotionToggleButton, game.mapContext():inMotionSickMode() and "MAP_MOTION_OFF" or "MAP_MOTION_ON", "xml_resources/map_hud.xml", game.mapContext():inMotionSickMode() and "button_map_motion_off" or "button_map_motion_on", function()
    self:ToggleMotionSickMode()
  end, "FrontPopUps")
  initButton(buttons.SaveButton, "MAP_SAVE", "xml_resources/composer_buttons01.xml", "button_save", function()
    self:SaveIslandCustomSorting()
  end, "FrontPopUps")
  initButton(buttons.ResetButton, "MAP_RESET", "xml_resources/map_hud.xml", "button_map_reset", function()
    self:ResetIslandCustomSorting()
  end, "FrontPopUps")
  local spaceX = 24 * game.menuScaleX()
  MenuHelpers.CenterHorizontally({
    buttons.SortButton,
    MenuHelpers.CreateSpacer(spaceX, 0),
    buttons.MotionToggleButton
  })
  MenuHelpers.CenterHorizontally({
    buttons.SaveButton,
    MenuHelpers.CreateSpacer(spaceX, 0),
    buttons.ResetButton
  })
  buttons = self.TopHUD
  local showTribalAlert = (game.numIslands() > 1 or game.playerLevel() >= 10) and (game.newTribalInviteNotice() or game.newTribalRequestNotice())
  local showColdIslandAlert = game.playerLevel() >= 6 and not game.isIslandOwned(2) and game.playerCanAffordIsland(2)
  if not self.isMirrorMode and (showTribalAlert or showColdIslandAlert) then
    buttons.NotificationAlertButton.UpSprite:GetVar("sheetName"):SetString("xml_resources/map_hud.xml")
    buttons.NotificationAlertButton.UpSprite:GetVar("spriteName"):SetString("button_map_filter_notification")
    buttons.NotificationAlertButton:enable()
  else
    buttons.NotificationAlertButton.UpSprite:GetVar("sheetName"):SetString("xml_resources/store_buttons01.xml")
    buttons.NotificationAlertButton.UpSprite:GetVar("spriteName"):SetString("button_rnd_base")
    buttons.NotificationAlertButton:disable()
  end
  initButton(buttons.NotificationAlertButton, "", "xml_resources/map_hud.xml", "map_filters_notification", function()
    if showColdIslandAlert then
      self:SelectIsland(2)
    elseif showTribalAlert then
      self:SelectIsland(9)
    end
  end)
  self.saleIslandIdx = 0
  local saleIslands = self.isMirrorMode and self.saleIslandsMirror or self.saleIslands
  if #saleIslands > 0 then
    buttons.SaleAlertButton.UpSprite:GetVar("sheetName"):SetString("xml_resources/map_hud.xml")
    buttons.SaleAlertButton.UpSprite:GetVar("spriteName"):SetString("button_map_filter_sale")
    buttons.SaleAlertButton:enable()
    self.saleIslandIdx = 0
  else
    buttons.SaleAlertButton.UpSprite:GetVar("sheetName"):SetString("xml_resources/store_buttons01.xml")
    buttons.SaleAlertButton.UpSprite:GetVar("spriteName"):SetString("button_rnd_base")
    buttons.SaleAlertButton:disable()
  end
  initButton(buttons.SaleAlertButton, "", "xml_resources/map_hud.xml", "map_filters_sale", function()
    self.saleIslandIdx = self.saleIslandIdx % #saleIslands + 1
    local nextSale = saleIslands[self.saleIslandIdx]
    self:SelectIsland(nextSale)
  end)
  self.seasonalIslandIdx = 0
  local seasonalIslands = self.isMirrorMode and self.seasonalIslandsMirror or self.seasonalIslands
  if #seasonalIslands > 0 then
    buttons.SeasonalAlertButton.UpSprite:GetVar("sheetName"):SetString("xml_resources/map_hud.xml")
    buttons.SeasonalAlertButton.UpSprite:GetVar("spriteName"):SetString("button_map_filter_seasonal")
    buttons.SeasonalAlertButton:enable()
  else
    buttons.SeasonalAlertButton.UpSprite:GetVar("sheetName"):SetString("xml_resources/store_buttons01.xml")
    buttons.SeasonalAlertButton.UpSprite:GetVar("spriteName"):SetString("button_rnd_base")
    buttons.SeasonalAlertButton:disable()
  end
  initButton(buttons.SeasonalAlertButton, "", "xml_resources/store_buttons01.xml", "decoration_filters_seasonal", function()
    self.seasonalIslandIdx = self.seasonalIslandIdx % #seasonalIslands + 1
    local nextSeasonal = seasonalIslands[self.seasonalIslandIdx]
    self:SelectIsland(nextSeasonal)
  end)
  local spaceX = 24 * game.menuScaleX()
  MenuHelpers.CenterHorizontally({
    buttons.NotificationAlertButton,
    MenuHelpers.CreateSpacer(spaceX, 0),
    buttons.SaleAlertButton,
    MenuHelpers.CreateSpacer(spaceX, 0),
    buttons.SeasonalAlertButton
  })
end
function MapBase:SelectPointOfInterest(name, titleText, bodyText)
  if self.selectedIsland > 0 then
    self:DeselectIsland()
  end
  print("Selected Point of Interest:", name)
  game.mapContext():focusOnPointOfInterest(name)
  if string.find(name, "seam") ~= nil then
    name = string.sub(name, 1, -4)
  end
  local substr = string.sub(name, 8)
  local id = "PoiPulse" .. substr .. "FadeTransition"
  if tickables[id] == nil then
    local fadeTransition = FadeTransition:new({
      duration = 0.5,
      ease = lua_sys.Quadratic_EaseIn,
      onUpdate = function(alpha)
        game.mapContext():setPulseFade(substr, alpha)
      end,
      onDoneShow = function()
        local thisFade = tickables[id]
        thisFade.ease = lua_sys.Quadratic_EaseOut
        thisFade:Hide()
        thisFade.targetAlpha = 0.5
        thisFade.duration = 0.5
      end
    })
    fadeTransition.id = id
    tickables[fadeTransition.id] = fadeTransition
  end
  tickables[id].ease = lua_sys.Quadratic_EaseIn
  tickables[id]:Show()
  if self.selectedPointOfInterest ~= name and 0 < self.PoiText.FadeTransition.remainingTime and self.PoiText.FadeTransition.targetAlpha == 0 then
    function self.PoiText.FadeTransition.onDoneHide()
      self.PoiText.Title:GetVar("text"):SetString(titleText)
      self.PoiText.Body:GetVar("text"):SetString(bodyText)
      self.PoiText.FadeTransition:Show()
    end
  else
    self.PoiText.Title:GetVar("text"):SetString(titleText)
    self.PoiText.Body:GetVar("text"):SetString(bodyText)
    self.PoiText.FadeTransition:Show()
  end
  self.PoiBackdrop.FadeTransition:Show()
  self.selectedPointOfInterest = name
end
function MapBase:UnselectPointOfInterest()
  function self.PoiText.FadeTransition.onDoneHide()
    self.selectedPointOfInterest = nil
  end
  self.PoiText.FadeTransition:Hide()
  self.PoiBackdrop.FadeTransition:Hide()
  local substr = string.sub(self.selectedPointOfInterest, 8)
  tickables["PoiPulse" .. substr .. "FadeTransition"].ease = lua_sys.Quadratic_EaseIn
  tickables["PoiPulse" .. substr .. "FadeTransition"]:Hide()
end
function MapBase:SelectSpecial(specialName)
  print("Selected Special", specialName)
  self:SelectIslandByNodeName(specialName)
end
function MapBase:ToggleMotionSickMode()
  game.mapContext():setMotionSickMode(not game.mapContext():inMotionSickMode())
  self:RefreshButtons()
  if game.mapContext():inMotionSickMode() then
    self.Main.IslandName.FadeTransition:SetAlpha(0)
    self.Main.IslandName:GetVar("yOffset"):SetFloat(24 * game.mapScale())
  else
    self.Main.IslandName.FadeTransition:SetAlpha(1)
    self.Main.IslandName:GetVar("yOffset"):SetFloat(-lua_sys.screenHeight() * 0.5)
  end
end
function MapBase:PreviousIsland()
  if self.isMirrorMode then
    local islandIndex = self.MirrorIslandList:GetIdToIndexMap()[self.selectedIsland] - 1
    local prevIslandIndex = (islandIndex - 1) % self.MirrorIslandList.numEntries
    self:SelectIsland(self.MirrorIslandList:GetIndexToIdMap()[prevIslandIndex + 1], true)
  else
    local islandIndex = self.IslandList:GetIdToIndexMap()[self.selectedIsland] - 1
    local prevIslandIndex = (islandIndex - 1) % self.IslandList.numEntries
    self:SelectIsland(self.IslandList:GetIndexToIdMap()[prevIslandIndex + 1], true)
  end
end
function MapBase:NextIsland()
  if self.isMirrorMode then
    local islandIndex = self.MirrorIslandList:GetIdToIndexMap()[self.selectedIsland] - 1
    local prevIslandIndex = (islandIndex + 1) % self.MirrorIslandList.numEntries
    self:SelectIsland(self.MirrorIslandList:GetIndexToIdMap()[prevIslandIndex + 1], true)
  else
    local islandIndex = self.IslandList:GetIdToIndexMap()[self.selectedIsland] - 1
    local prevIslandIndex = (islandIndex + 1) % self.IslandList.numEntries
    self:SelectIsland(self.IslandList:GetIndexToIdMap()[prevIslandIndex + 1], true)
  end
end
function MapBase:ShowOptions()
  self.OptionsPanel.OffsetTransition:Show()
  self.showingOptions = true
  self:RefreshButtons()
  game.getContextBar():setContext("MAP_OPTIONS")
  game.mapContext():updateTutorialArrowOnButton()
  self.OptionsOverlay.FadeTransition:Show()
  self.OptionsOverlay.Touch:GetVar("enabled"):SetInt(1)
  if self.selectedIsland ~= 0 then
    if game.mapContext():inMotionSickMode() then
      function self.MotionModeOverlay.FadeTransition.onDoneShow()
        self.MotionModeOverlay.FadeTransition.ease = lua_sys.Quadratic_EaseOut
        self.MotionModeOverlay.FadeTransition:Hide()
        game.mapContext():deselectNode()
        game.mapContext():showPoiPins(false)
      end
      self:DeselectIsland()
      self:HideIslandInfo()
      self.MotionModeOverlay.FadeTransition.ease = lua_sys.Quadratic_EaseIn
      self.MotionModeOverlay.FadeTransition:Show()
    else
      game.mapContext():deselectNode()
      game.mapContext():showPoiPins()
    end
  end
  if self.selectedPointOfInterest ~= nil then
    game.mapContext():deselectPointOfInterest()
  end
  game.logEvent("map_options", "action", "open_options")
end
function MapBase:HideOptions()
  self.OptionsPanel.OffsetTransition:Hide()
  self.showingOptions = false
  if self.sortingMode then
    self:ToggleSortingMode()
  end
  self:RefreshButtons()
  if self.selectedIsland > 0 then
    game.getContextBar():setContext("MAP_FOCUSED")
  elseif game.mapContext():isFriendMode() then
    game.getContextBar():setContext("MAP_FRIEND_DEFAULT")
  else
    game.getContextBar():setContext("MAP_DEFAULT")
  end
  self.OptionsOverlay.FadeTransition:Hide()
  self.OptionsOverlay.Touch:GetVar("enabled"):SetInt(0)
  if self.OptionsPanel.SortButton:GetVar("ButtonState"):GetInt() == game.BUTTON_PRESSED then
    self.OptionsPanel.SortButton.Touch:onTouchRelease(self.OptionsPanel.SortButton)
  end
  if self.OptionsPanel.MotionToggleButton:GetVar("ButtonState"):GetInt() == game.BUTTON_PRESSED then
    self.OptionsPanel.MotionToggleButton.Touch:onTouchRelease(self.OptionsPanel.MotionToggleButton)
  end
  if self.OptionsPanel.SaveButton:GetVar("ButtonState"):GetInt() == game.BUTTON_PRESSED then
    self.OptionsPanel.SaveButton.Touch:onTouchRelease(self.OptionsPanel.SaveButton)
  end
  if self.OptionsPanel.ResetButton:GetVar("ButtonState"):GetInt() == game.BUTTON_PRESSED then
    self.OptionsPanel.ResetButton.Touch:onTouchRelease(self.OptionsPanel.ResetButton)
  end
  game.mapContext():updateTutorialArrowOnButton()
  game.logEvent("map_options", "action", "close_options")
end
function MapBase:ResetContext()
  if not self.showingOptions then
    if game.mapContext():isFriendMode() then
      game.getContextBar():setContext("MAP_FRIEND_DEFAULT")
    else
      game.getContextBar():setContext("MAP_DEFAULT")
    end
  end
end
return MapBase
