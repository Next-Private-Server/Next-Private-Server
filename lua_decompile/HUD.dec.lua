local ScrollingListHelperV2 = include("ScrollingListHelperV2")
local MenuHelpers = include("MenuHelpers")
local FadeTransition = include("FadeTransition")
local HUD = {
  LeftButtons = {
    Touch = {},
    Swiper = {},
    BracketTop = {
      Bar = {},
      Arrow = {}
    },
    BracketBottom = {
      Bar = {},
      Arrow = {}
    },
    RankButton = {},
    GoalsButton = {},
    ActivityButton = {},
    StickerbookButton = {
      Indicator = {}
    }
  },
  ActivityCenter = {
    Panel = {
      BattleButton = {},
      CurrencyScratch = {},
      MemoryGame = {},
      BreedingScratch = {},
      DailyLoginButton = {},
      CalendarButton = {}
    }
  },
  PromoCenter = {},
  ViewButton = {
    Sprite = {},
    Touch = {}
  }
}
function HUD:onInit()
  self("waitingOnComposerRename"):SetInt(0)
end
function HUD:onPostInit()
  self:DoStoredScript("doIslandAdjustments")
  local function checkGoalsPulse()
    local PULSE_DELAY = 10
    if game.questsCompleted() > 0 and not game.tutorialActive() and not SESSION_HAS_TRIGGERED_QUEST_PULSE then
      SESSION_HAS_TRIGGERED_QUEST_PULSE = true
      self.pulseDelay = PULSE_DELAY
    end
  end
  self.pulseDelay = 0
  checkGoalsPulse()
  self:SetupGenericListener(game.engineReceiver(), "game::msg::MsgQuestCompleted", "gotMsgQuestCompleted")
  local profilePicE = self:E("ProfilePic")
  local profileScale = profilePicE:templateVars().scale
  local levelE = profilePicE:E("Level")
  local levelIconC = levelE:C("Icon")
  local palette = include("ColourPalette")
  if game.isBattleIsland() then
    profilePicE("isBattleMode"):SetInt(1)
    levelIconC("spriteName"):SetString("BattleLevel_Star")
    levelE:C("Text"):setColor(palette:getRGBFloats(palette.BATTLE_XP_STAR_LEVEL_HUD))
  else
    levelIconC("spriteName"):SetString("PlayerLevel_Star_HUD")
    levelE:C("Text"):setColor(palette:getRGBFloats(palette.XP_STAR_LEVEL_HUD))
  end
  levelE("xOffset"):SetFloat(-12 * profileScale)
  levelE("yOffset"):SetFloat(-10 * profileScale)
  profilePicE("textScale"):SetFloat(1.6 * profileScale / game.hudScale())
  self:refreshAvatar()
  self.LeftButtons.GoalsButton:hide()
  self.LeftButtons.ActivityButton:hide()
  self.LeftButtons.BracketTop.Bar:GetVar("visible"):SetInt(0)
  self.LeftButtons.BracketTop.Arrow:GetVar("visible"):SetInt(0)
  self.LeftButtons.BracketBottom.Bar:GetVar("visible"):SetInt(0)
  self.LeftButtons.BracketBottom.Arrow:GetVar("visible"):SetInt(0)
  self:SetupGenericListener(game.engineReceiver(), "game::msg::MsgContextBarStateChange", "gotMsgContextBarStateChange")
  self.ViewFader = FadeTransition:new({
    duration = 0.33,
    minFade = 0.2,
    maxFade = 0.8,
    onUpdate = function(alpha)
      self.ViewButton.Sprite("alpha"):SetFloat(alpha)
    end
  })
  self.ViewFader:SetAlpha(0.8)
end
function HUD:gotMsgContextBarStateChange(msg)
  local contextBar = game.getContextBar()
  if contextBar then
    self:InitLeftButtons()
  end
end
function HUD:InitLeftButtons()
  if self.left_buttons then
    return
  end
  local yPos = self.LeftButtons:absY()
  local contextBar = game.getContextBar()
  local contextBarHeight = contextBar and contextBar:getHeight(false, false) or 0
  local availableHeight = lua_sys.screenHeight() - yPos - contextBarHeight
  self.LeftButtons:setSize(lua_sys.Vector2(self.LeftButtons:absW(), availableHeight))
  self.left_buttons = {}
  if game.isBattleIsland() then
    if game.playerCanFriendBattle() then
      table.insert(self.left_buttons, self.LeftButtons.RankButton)
      if self.LeftButtons.isHidden then
        self.LeftButtons.RankButton:DoStoredScript("hide")
      else
        self.LeftButtons.RankButton:DoStoredScript("show")
      end
    end
  else
    table.insert(self.left_buttons, self.LeftButtons.GoalsButton)
    if self.LeftButtons.isHidden then
      self.LeftButtons.GoalsButton:DoStoredScript("hide")
    else
      self.LeftButtons.GoalsButton:DoStoredScript("show")
    end
  end
  self:SetupGenericListener(self.LeftButtons.GoalsButton.Pulse:GetReceiver(), "sys::msg::MsgAnimationFinished", "gotMsgAnimationFinished")
  local function getTemplateArgs(template, name)
    return {
      template = template,
      name = name,
      parent = self.LeftButtons,
      relativeTo = self.LeftButtons,
      relativeAnchorH = lua_sys.HCENTER,
      relativeAnchorV = lua_sys.TOP,
      anchorH = lua_sys.HCENTER,
      achorV = lua_sys.TOP,
      priority = -1
    }
  end
  local stickerbookButton = MenuHelpers.CreateFromTemplate(getTemplateArgs("template_hud_button_stickerbook", "StickerbookButton"))
  function stickerbookButton.isVisibleOnHUD()
    return not self.LeftButtons.isHidden
  end
  stickerbookButton:RefreshCardAlbumStatus()
  table.insert(self.left_buttons, stickerbookButton)
  self.LeftButtons.StickerbookButton = stickerbookButton
  if self.LeftButtons.isHidden then
    self.LeftButtons.StickerbookButton:Hide()
  end
  self:SetupGenericListener(game.engineReceiver(), "game::msg::MsgCardAlbumUpdated", "gotMsgCardAlbumUpdated")
  local hasClubbox = function()
    if game.clubboxActIsAvail() then
      if game.isMemberOfGroup(70) then
        return false
      end
      return game.clubboxShortestTimeAvail() > 0
    end
    return false
  end
  if game.isAdmin() then
    local bbbButton = MenuHelpers.CreateFromTemplate(getTemplateArgs("template_hud_button_adminBbbEntry", "BBBIDEntryButton"))
    table.insert(self.left_buttons, bbbButton)
    self.LeftButtons.BBBIDEntryButton = bbbButton
    if self.LeftButtons.isHidden then
      self.LeftButtons.BBBIDEntryButton:DoStoredScript("hide")
    else
      self.LeftButtons.BBBIDEntryButton:DoStoredScript("show")
    end
    if game.inAdminViewMode() then
      local deleteIslandButton = MenuHelpers.CreateFromTemplate(getTemplateArgs("template_hud_button_adminDeleteIsland", "DeleteIsland"))
      table.insert(self.left_buttons, deleteIslandButton)
      self.LeftButtons.DeleteIsland = deleteIslandButton
      if self.LeftButtons.isHidden then
        self.LeftButtons.DeleteIsland:DoStoredScript("hide")
      else
        self.LeftButtons.DeleteIsland:DoStoredScript("show")
      end
    end
  end
  if hasClubbox() then
    local clubboxButton = MenuHelpers.CreateFromTemplate(getTemplateArgs("template_hud_button_clubbox", "ClubboxButton"))
    table.insert(self.left_buttons, clubboxButton)
    self.LeftButtons.ClubboxButton = clubboxButton
    if self.LeftButtons.isHidden then
      self.LeftButtons.ClubboxButton:DoStoredScript("hide")
    else
      self.LeftButtons.ClubboxButton:DoStoredScript("show")
    end
  end
  if not game.isMemberOfGroup(70) then
    do
      local minigames = game.getActiveMinigameIds()
      for i = 0, minigames:size() - 1 do
        do
          local args = getTemplateArgs("template_hud_button_minigame", "MinigameButton")
          function args.setupFn(t)
            t:Setup(minigames[i])
          end
          local minigameButton = MenuHelpers.CreateFromTemplate(args)
          if minigameButton then
            table.insert(self.left_buttons, minigameButton)
            self.LeftButtons.MinigameButton = minigameButton
            if self.LeftButtons.isHidden then
              minigameButton:DoStoredScript("hide")
            else
              minigameButton:DoStoredScript("show")
            end
          end
        end
      end
    end
  end
  table.insert(self.left_buttons, self.LeftButtons.ActivityButton)
  if self.LeftButtons.isHidden then
    self.LeftButtons.ActivityButton:DoStoredScript("hide")
  else
    self.LeftButtons.ActivityButton:DoStoredScript("show")
  end
  if game.isDebugBuild() or game.isQABuild() then
    local testButton = include("ButtonFactory"):CreateButton({
      root = self.LeftButtons,
      text = "Test",
      relAnchorV = lua_sys.TOP,
      anchorV = lua_sys.TOP,
      relativeTo = self.LeftButtons,
      priority = -1,
      layer = "Popups",
      onTouchUp = function(component, element)
        if element.isDragging then
          element.isDragging = false
          return
        end
        include("Test").Run()
      end
    })
    table.insert(self.left_buttons, testButton)
    if self.LeftButtons.isHidden then
      testButton:DoStoredScript("hide")
    else
      testButton:DoStoredScript("show")
    end
  end
  self.LeftBarScrollingList = ScrollingListHelperV2:new({
    direction = lua_sys.MenuSwipeComponent_SwipeDirectionVertical,
    spacing = 8 * game.hudScale(),
    padding = 12 * game.hudScale(),
    centerContents = false,
    Element = self.LeftButtons,
    entries = self.left_buttons
  })
  for _, v in ipairs(self.left_buttons) do
    if v.SetClipRect then
      v:SetClipRect(self.LeftButtons:absX(), self.LeftButtons:absY(), self.LeftButtons:absW(), self.LeftButtons:absH())
    end
  end
  local notifiedDragging = false
  function self.LeftButtons.Swiper.onDrag(component, element, from, to)
    if not notifiedDragging and math.abs(from - to) > 4 then
      notifiedDragging = true
      for _, v in ipairs(self.left_buttons) do
        v.isDragging = true
      end
    end
  end
  function self.LeftButtons.Swiper.onRelease(component, element)
    for _, v in ipairs(self.left_buttons) do
      v.isDragging = false
    end
    notifiedDragging = false
  end
  self.LeftBarScrollingList:Tick(0)
  local requireScrolling = self.LeftBarScrollingList:GetContentSize() > self.LeftBarScrollingList:GetViewSize()
  self.LeftButtons.BracketTop.Bar:GetVar("visible"):SetInt(requireScrolling and 1 or 0)
  self.LeftButtons.BracketBottom.Bar:GetVar("visible"):SetInt(requireScrolling and 1 or 0)
end
function HUD:ShowLeftButtons()
  self.LeftButtons.isHidden = false
  if self.left_buttons then
    for _, v in ipairs(self.left_buttons) do
      v:DoStoredScript("show")
    end
  end
  self.LeftBarScrollingList:Refresh()
  local requireScrolling = self.LeftBarScrollingList and self.LeftBarScrollingList:GetContentSize() > self.LeftBarScrollingList:GetViewSize()
  local shouldShowBrackets = not self.LeftButtons.isHidden and requireScrolling
  self.LeftButtons.BracketTop.Bar:GetVar("visible"):SetInt(shouldShowBrackets and 1 or 0)
  self.LeftButtons.BracketBottom.Bar:GetVar("visible"):SetInt(shouldShowBrackets and 1 or 0)
end
function HUD:HideLeftButtons()
  self.LeftButtons.isHidden = true
  self.LeftButtons.BracketTop.Bar:GetVar("visible"):SetInt(0)
  self.LeftButtons.BracketTop.Arrow:GetVar("visible"):SetInt(0)
  self.LeftButtons.BracketBottom.Bar:GetVar("visible"):SetInt(0)
  self.LeftButtons.BracketBottom.Arrow:GetVar("visible"):SetInt(0)
  if self.left_buttons then
    for _, v in ipairs(self.left_buttons) do
      v:DoStoredScript("hide")
    end
  end
end
function HUD:playQuestPulseEffect()
  local component = self.LeftButtons.GoalsButton.Pulse
  if component then
    component("visible"):SetInt(1)
    component("animation"):SetString("goal_collect")
    component:Play()
  end
end
function HUD:gotMsgQuestCompleted(msg)
  if self.LeftButtons.GoalsButton.Overlay:GetVar("visible"):GetInt() == 1 and not game.tutorialActive() then
    self:playQuestPulseEffect()
  end
end
function HUD:gotMsgAnimationFinished(msg)
  self.LeftButtons.GoalsButton.Pulse("visible"):SetInt(0)
end
function HUD:refreshAvatar()
  local profilePic = self:E("ProfilePic")
  local profile = game.playerProfile()
  profilePic:SetAvatarData(profile:getPlayerAvatar())
  if game.isBattleIsland() then
    local level = game.getBattlePlayerData().level
    if level >= game.maxPlayerBattleLevel() then
      self:repositionForMaxLevel()
    end
    profilePic:SetLevel(level)
  else
    local level = game.playerLevel()
    if level >= game.maxPlayerLevel() then
      self:repositionForMaxLevel()
    end
    profilePic:SetLevel(level)
  end
end
function HUD:repositionForMaxLevel()
  self:E("XpBarBacking"):DoStoredScript("setInvisibleOnIsland")
  self:E("XpBar"):DoStoredScript("setInvisibleOnIsland")
  local profilePicE = self:E("ProfilePic")
  local profileScale = profilePicE:templateVars().scale
  profilePicE("xOffset"):SetFloat(42 * profileScale)
end
function HUD:onTick(dt)
  if self.LeftButtons.GoalsButton.Overlay:GetVar("visible"):GetInt() == 1 and self.pulseDelay > 0 then
    self.pulseDelay = math.max(self.pulseDelay - dt, 0)
    if self.pulseDelay == 0 then
      self:playQuestPulseEffect()
    end
  end
  if self.LeftBarScrollingList then
    if self.ClubboxButton and self.ClubboxButton.secsRemaining and self.ClubboxButton.secsRemaining == 0 then
      self.LeftBarScrollingList:RemoveEntry(self.ClubboxButton)
      self.LeftButtons:RemoveElement(self.ClubboxButton)
      self.ClubboxButton = nil
      self.LeftBarScrollingList:Refresh()
    end
    if self.StickerbookButton and self.StickerbookButton.secsRemaining and self.StickerbookButton.secsRemaining == 0 then
      self.LeftBarScrollingList:RemoveEntry(self.StickerbookButton)
      self.LeftButtons:RemoveElement(self.StickerbookButton)
      self.StickerbookButton = nil
      self.LeftBarScrollingList:Refresh()
    end
    self.LeftBarScrollingList:Tick(dt)
    local hasLess = not self.LeftButtons.isHidden and 0 > self.LeftBarScrollingList:GetCurrentOffset()
    self.LeftButtons.BracketTop.Arrow("visible"):SetInt(hasLess and 1 or 0)
    local hasMore = not self.LeftButtons.isHidden and self.LeftBarScrollingList:GetCurrentOffset() + self.LeftBarScrollingList:GetContentSize() > self.LeftBarScrollingList:GetViewSize() + 1
    self.LeftButtons.BracketBottom.Arrow("visible"):SetInt(hasMore and 1 or 0)
  end
  self.ViewFader:Tick(dt)
end
function HUD:doIslandAdjustments()
  self.IslandTitleBG:DoStoredScript("setInvisibleOnIsland")
  self.IslandLabel:DoStoredScript("setInvisibleOnIsland")
  self.CoinCounter:DoStoredScript("setAsCoins")
  self.MedalCounter:DoStoredScript("setInvisibleOnIsland")
  self.XpBarBacking:DoStoredScript("setVisibleOnIsland")
  self.XpBar:DoStoredScript("setVisibleOnIsland")
  self.XpBar:DoStoredScript("show")
  self.ProfilePic:DoStoredScript("setVisibleOnIsland")
  self.GoalsButton:DoStoredScript("setVisibleOnIsland")
  self.ActivityCenter.Panel.BattleButton:DoStoredScript("setInvisibleOnIsland")
  if game.isComposerIsland() then
    self.IslandTitleBG:DoStoredScript("setVisibleOnIsland")
    self.IslandTitleBG:DoStoredScript("show")
    self.IslandTitleBG("yOffset"):SetFloat(self.CoinCounter.BackingSprite("height"):GetFloat())
    self.IslandLabel:DoStoredScript("setVisibleOnIsland")
    self.IslandLabel:DoStoredScript("show")
    self.IslandLabel.Text:DoStoredScript("populate")
    self.FlexCounters:DoStoredScript("setInvisibleOnIsland")
  end
  if game.isEtherealIsland() then
    self.CoinCounter:DoStoredScript("setAsEthereal")
  end
  if game.isBattleIsland() then
    self.GoalsButton:DoStoredScript("setInvisibleOnIsland")
    if game.playerCanFriendBattle() then
      self.RankButton:DoStoredScript("setVisibleOnIsland")
    else
      self.RankButton:DoStoredScript("setInvisibleOnIsland")
    end
    self.FoodCounter:DoStoredScript("setInvisibleOnIsland")
    self.DiamondCounter("xOffset"):SetInt(self.DiamondCounter("xOffset"):GetInt() - self.DiamondCounter.BackingSprite("width"):GetFloat())
    self.MedalCounter:DoStoredScript("setVisibleOnIsland")
    self.MedalCounter:DoStoredScript("show")
    self.FlexCounters:DoStoredScript("setInvisibleOnIsland")
  else
    self.RankButton:DoStoredScript("setInvisibleOnIsland")
    if game.showBattleButton() then
      self.ActivityCenter.Panel.BattleButton:DoStoredScript("showBattleButton")
    elseif game.hintBattleFunctionality() then
      self.ActivityCenter.Panel.BattleButton:DoStoredScript("hintBattleButton")
    end
  end
end
function HUD:hideHUD()
  print("=== Hide HUD")
  self.XpBarBacking:DoStoredScript("hide")
  self.XpBar:DoStoredScript("hide")
  self.CoinCounter:DoStoredScript("hide")
  self.DiamondCounter:DoStoredScript("hide")
  self.FoodCounter:DoStoredScript("hide")
  self.MedalCounter:DoStoredScript("hide")
  self.FlexCounters:DoStoredScript("hideHUD")
  self.ProfilePic:DoStoredScript("hide")
  self.EncoreBar:DoStoredScript("hide")
  self.ActivityCenter.Panel.BattleButton:DoStoredScript("hide")
  self.RankButton:DoStoredScript("hide")
  self:HideLeftButtons()
  self.PromoCenter:Hide()
  self.IslandTitleBG.Sprite("visible"):SetInt(0)
  self.IslandTitleBG.Touch("enabled"):SetInt(0)
  self.IslandLabel.Text("visible"):SetInt(0)
  self.ActivityCenter:Hide()
end
function HUD:showHUD()
  print("=== Show HUD")
  self.XpBarBacking:DoStoredScript("show")
  self.XpBar:DoStoredScript("show")
  self.CoinCounter:DoStoredScript("show")
  self.DiamondCounter:DoStoredScript("show")
  self.FoodCounter:DoStoredScript("show")
  self.MedalCounter:DoStoredScript("show")
  self.ProfilePic:DoStoredScript("show")
  self:refreshAvatar()
  self.EncoreBar:DoStoredScript("show")
  self.RankButton:DoStoredScript("show")
  self.ActivityCenter.Panel.BattleButton:DoStoredScript("show")
  self:ShowLeftButtons()
  self.PromoCenter:Show()
  self.IslandTitleBG:DoStoredScript("show")
  self.IslandLabel:DoStoredScript("show")
  self.FlexCounters:DoStoredScript("showHUD")
end
function HUD:disableButtons()
  self.CoinCounter.Touch("enabled"):SetInt(0)
  self.DiamondCounter.Touch("enabled"):SetInt(0)
  self.FoodCounter:DoStoredScript("disableButtons")
  self.FlexCounters:DoStoredScript("disableButtons")
  self.ProfilePic.Touch("enabled"):SetInt(0)
  self.EncoreBar.Touch("enabled"):SetInt(0)
end
function HUD:enableButtons()
  self.CoinCounter.Touch("enabled"):SetInt(1)
  self.DiamondCounter.Touch("enabled"):SetInt(1)
  self.FoodCounter:DoStoredScript("enableButtons")
  self.FlexCounters:DoStoredScript("enableButtons")
  self.ProfilePic.Touch("enabled"):SetInt(1)
  self.EncoreBar.Touch("enabled"):SetInt(1)
end
function HUD:enableSpinGame()
  self.XpBarBacking:DoStoredScript("hide")
  self.XpBar:DoStoredScript("hide")
  self:HideLeftButtons()
  self.ActivityCenter.Panel.BattleButton:DoStoredScript("hide")
  self.ActivityCenter:Hide()
  self.ProfilePic:DoStoredScript("hide")
  self.EncoreBar:DoStoredScript("hide")
  self.RankButton:DoStoredScript("hide")
  self.PromoCenter:Hide()
  self.IslandTitleBG.Sprite("visible"):SetInt(0)
  self.IslandTitleBG.Touch("enabled"):SetInt(0)
  self.IslandLabel.Text("visible"):SetInt(0)
  self.CoinCounter.Touch("enabled"):SetInt(0)
  self.CoinCounter.Plus:setColor(0.5, 0.5, 0.5)
  self.FoodCounter.Touch("enabled"):SetInt(0)
  self.FoodCounter.Plus:setColor(0.5, 0.5, 0.5)
  self.DiamondCounter.Touch("enabled"):SetInt(0)
  self.DiamondCounter.Plus:setColor(0.5, 0.5, 0.5)
  self.FlexCounters:DoStoredScript("enableSpinGame")
  self.ViewButton:GetVar("auto"):SetInt(0)
  self.ViewButton:DoStoredScript("hide")
end
function HUD:disableSpinGame()
  self.CoinCounter.Touch("enabled"):SetInt(1)
  self.CoinCounter.Plus:setColor(1, 1, 1)
  self.FoodCounter.Touch("enabled"):SetInt(1)
  self.FoodCounter.Plus:setColor(1, 1, 1)
  self.DiamondCounter.Touch("enabled"):SetInt(1)
  self.DiamondCounter.Plus:setColor(1, 1, 1)
  self.PromoCenter:Show()
  self.FlexCounters:DoStoredScript("disableSpinGame")
  self.ViewButton:GetVar("auto"):SetInt(1)
  self:showHUD()
end
function HUD:enablePaintMode()
  self:hideHUD()
end
function HUD:disablePaintMode()
  self:showHUD()
end
function HUD:gotMsgCardAlbumUpdated()
  if self.LeftButtons.StickerbookButton then
    self.LeftButtons.StickerbookButton:RefreshCardAlbumStatus()
  end
  if self.LeftBarScrollingList then
    self.LeftBarScrollingList:Refresh()
  end
end
return HUD
