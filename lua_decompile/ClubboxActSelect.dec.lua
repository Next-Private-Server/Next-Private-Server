local CarouselHelper = include("CarouselHelper")
local ClubboxActSelect = {
  FadedBG = {},
  DJWordsLabel = {
    Text = {}
  },
  ActSelect = {
    Touch = {},
    Swiper = {},
    Spotlight = {},
    LeftButton = {
      Touch = {}
    },
    RightButton = {
      Touch = {}
    },
    SelectButton = {
      Touch = {}
    },
    ActName = {},
    LeftHalfBg = {
      HypeBlob = {
        HypeIcon = {},
        HypeCount = {}
      }
    },
    RightHalfBg = {
      RewardBlob = {
        RewardIcon = {},
        RewardCount = {}
      }
    },
    populateOrder = {
      [0] = 2,
      [1] = 1,
      [2] = 3
    },
    selectedActId = -1,
    numActs = 0
  },
  IslandSelect = {
    IslandCarousel = {
      SelectIslandButton = {
        Touch = {}
      },
      RightButton = {},
      LeftButton = {}
    },
    selectedIslandId = 1
  },
  ConfirmationView = {
    ConfirmAllButton = {
      Touch = {}
    }
  },
  BackButton = {
    Overlay = {},
    Touch = {}
  },
  viewMode = 0
}
function ClubboxActSelect:onInit()
  self("transitionState"):SetInt(1)
  self("transitionTime"):SetFloat(0)
  playSoundFx("audio/sfx/menu_slide.wav")
  manager:setContext("BLANK")
end
function ClubboxActSelect:onPostInit()
  self:refreshView()
end
function ClubboxActSelect:setToActSelectView()
  self.ActSelect:enable()
  self.IslandSelect:disable()
  self.ConfirmationView:disable()
  self.TutorialDj.Sprite("spriteName"):SetString("gfx/clubbox/T-Pain_Big_Welcome")
  if game.player():hasClubboxedPreviously() then
    self.DJWordsLabel:populate("CLUBBOX_SELECT_ACT_DESC")
  else
    self.DJWordsLabel:populate("CLUBBOX_TUTORIAL_SELECT_ACT")
  end
  self.BackButton.Overlay("spriteName"):SetString("button_no")
  self.BackButton.Overlay("sheetName"):SetString("xml_resources/context_buttons.xml")
  self.BackButton.Text("text"):SetString("EXIT")
end
function ClubboxActSelect:setToLocationSelectView()
  self.ActSelect:disable()
  self.IslandSelect:enable()
  self.ConfirmationView:disable()
  self.TutorialDj.Sprite("spriteName"):SetString("gfx/clubbox/T-Pain_Arms_Crossed")
  self.DJWordsLabel:populate("CLUBBOX_TUTORIAL_SELECT_LOCATION")
  self.BackButton.Overlay("spriteName"):SetString("button_back")
  self.BackButton.Overlay("sheetName"):SetString("xml_resources/context_buttons.xml")
  self.BackButton.Text("text"):SetString("BACK")
end
function ClubboxActSelect:advanceToConfirmation()
  if self.ActSelect.selectedActId == -1 then
    self.viewMode = 0
  elseif self.IslandSelect.selectedIslandId == 0 then
    self.viewMode = 1
  else
    self.viewMode = 2
  end
  self:refreshView()
end
function ClubboxActSelect:setToConfirmationView()
  self.ActSelect:disable()
  self.IslandSelect:disable()
  self.ConfirmationView:enable()
  self.TutorialDj.Sprite("spriteName"):SetString("gfx/clubbox/T-Pain_Big_Welcome")
  local islandText = LOC(game.islandName(self.IslandSelect.selectedIslandId))
  if self.ActSelect.selectedActId > 0 then
    local actText = LOC(game.getClubboxActTitle(self.ActSelect.selectedActId))
    local tutorialText = LOC("CLUBBOX_TUTORIAL_CONFIRMATION")
    replacesText = tutorialText:gsub("%${ACT}", actText)
    replacesText = replacesText:gsub("%${ISLAND}", islandText)
    self.DJWordsLabel:populate(replacesText)
    self.BackButton.Overlay("spriteName"):SetString("button_back")
    self.BackButton.Overlay("sheetName"):SetString("xml_resources/context_buttons.xml")
    self.BackButton.Text("text"):SetString("BACK")
  end
end
function ClubboxActSelect:refreshView()
  if self.viewMode == 0 then
    self:setToActSelectView()
  elseif self.viewMode == 1 then
    self:setToLocationSelectView()
  else
    self:setToConfirmationView()
  end
end
function ClubboxActSelect:queuePop()
  manager:setContext(manager:reserveState())
  self:root():popPopUp()
end
function ClubboxActSelect.ActSelect:onInit()
  self.selectedActId = game.existingClubboxAct()
  self.entries = {}
end
function ClubboxActSelect.ActSelect:onPostInit()
  self.ActSelect:populateActs()
  self.carousel = CarouselHelper:new({
    Element = self,
    entries = self.entries,
    verticalBias = -20 * game.windowScaleY(),
    tiltAngle = 81,
    onActiveChanged = function(old, new, entry)
      self.ActSelect:SelectAct(entry)
    end,
    onEnableButtons = function(enable)
      self.buttonsEnabled = enable
      if enable then
        self.LeftButton:enable()
        self.RightButton:enable()
        self:SelectAct(self.ActSelect.selectedActElement)
      else
        self.LeftButton:disable()
        self.RightButton:disable()
        self.SelectButton:disable()
      end
    end,
    onSetVisible = function(enable)
      for i, entry in ipairs(self.entries) do
        if enable then
          entry:setVisible()
        else
          entry:setInvisible()
        end
      end
    end
  })
  function self.LeftButton.Touch.onTouchDown()
    self.carousel:StartMovement(-1)
    self.RightButton:disable()
    self.buttonsEnabled = false
  end
  function self.LeftButton.Touch.onTouchUp()
    self.carousel:StopMovement()
    self.buttonsEnabled = true
  end
  function self.LeftButton.Touch.onTouchRelease()
    self.carousel:StopMovement()
    self.buttonsEnabled = true
  end
  function self.RightButton.Touch.onTouchDown()
    self.carousel:StartMovement(1)
    self.LeftButton:disable()
    self.buttonsEnabled = false
  end
  function self.RightButton.Touch.onTouchUp()
    self.carousel:StopMovement()
    self.buttonsEnabled = true
  end
  function self.RightButton.Touch.onTouchRelease()
    self.carousel:StopMovement()
    self.buttonsEnabled = true
  end
  self:SelectAct(self.entries[1])
end
function ClubboxActSelect.ActSelect:onTick(dt)
  self.carousel:Tick(dt)
end
function ClubboxActSelect.ActSelect:enable()
  if self.carousel then
    self.carousel:SetVisible(true)
  end
  self.LeftButton:setVisible()
  self.RightButton:setVisible()
  self.Spotlight:setVisible()
  self.SelectButton:setVisible()
  self.ActName:setVisible()
  self.LeftHalfBg:setVisible()
  self.RightHalfBg:setVisible()
  self:refreshSelection()
end
function ClubboxActSelect.ActSelect:disable()
  if self.carousel then
    self.carousel:SetVisible(false)
  end
  self.LeftButton:setInvisible()
  self.RightButton:setInvisible()
  self.Spotlight:setInvisible()
  self.SelectButton:setInvisible()
  self.ActName:setInvisible()
  self.LeftHalfBg:setInvisible()
  self.RightHalfBg:setInvisible()
end
function ClubboxActSelect.ActSelect:populateActs()
  local actsAvailable = game.availClubboxActs()
  self.numActs = actsAvailable:size()
  self.entries = {}
  local numPosters = math.max(2, self.numActs - 1)
  for i = 0, numPosters do
    local actId = -1
    if i < self.numActs then
      actId = actsAvailable[i]
    end
    local item = menu:addTemplateElement("template_clubbox_acts_entry", "entry" .. i, self)
    item:relativeTo(self)
    item:setOrientation(lua_sys.MenuOrientation(0, 0, 0, lua_sys.HCENTER, lua_sys.VCENTER))
    item:setRelativeObjectAnchors(lua_sys.HCENTER, lua_sys.VCENTER)
    item:templateVars().layer = "MidPopUps"
    item:templateVars().spriteScale = 0.35 * game.windowScaleY()
    item:init()
    item:setPositionBroadcast(true)
    item:postInit()
    item:SetAct(actId)
    function item.Touch.onTouchUp()
    end
    item:showAsDeselected()
    table.insert(self.entries, item)
  end
  self:refreshSelection()
end
function ClubboxActSelect.ActSelect:refreshSelection()
  self.SelectButton:refresh()
  self.ActName:updateText()
  self.LeftHalfBg:updateText()
  self.RightHalfBg:updateText()
end
function ClubboxActSelect.ActSelect:SelectAct(actElement)
  self.selectedActElement = actElement
  if self.selectedActElement then
    self.selectedActId = self.selectedActElement.actId
    self:refreshSelection()
  end
end
function ClubboxActSelect.ActSelect.ActName:updateText()
  local actId = self:parent().selectedActId
  if actId > 0 then
    self:setVisible()
    self("text"):SetString(LOC(game.getClubboxActTitle(actId)))
  else
    self:setInvisible()
  end
end
function ClubboxActSelect.ActSelect.ActName:setVisible()
  self("visible"):SetInt(1)
end
function ClubboxActSelect.ActSelect.ActName:setInvisible()
  self("visible"):SetInt(0)
end
function ClubboxActSelect.ActSelect.SelectButton:onInit()
  self:super_onInit()
  self:refresh()
end
function ClubboxActSelect.ActSelect.SelectButton:refresh()
  if self:parent().selectedActId > 0 then
    self:enable()
  else
    self:disable()
  end
end
function ClubboxActSelect.ActSelect.SelectButton.Touch:onTouchUp(element)
  self:super_onTouchUp(element)
  if not game.inAdminViewMode() then
    element:parent():parent().viewMode = 1
  else
    element:parent():parent().IslandSelect.selectedIslandId = game.existingClubboxIslandId()
    element:parent():parent().ConfirmationView.ConfirmAllButton.Touch:onTouchUp(element:parent():parent().ConfirmationView.ConfirmAllButton)
  end
  element:parent():parent():refreshView()
end
function ClubboxActSelect.ActSelect.LeftHalfBg:onPostInit()
  self:updateText()
end
function ClubboxActSelect.ActSelect.LeftHalfBg:setVisible()
  self.HypeBlob:setVisible()
end
function ClubboxActSelect.ActSelect.LeftHalfBg:setInvisible()
  self.HypeBlob:setInvisible()
end
function ClubboxActSelect.ActSelect.LeftHalfBg:updateText()
  self.HypeBlob:updateText()
end
function ClubboxActSelect.ActSelect.LeftHalfBg.HypeBlob:setVisible()
  self.HypeIcon("visible"):SetInt(1)
  self.HypeCount("visible"):SetInt(1)
end
function ClubboxActSelect.ActSelect.LeftHalfBg.HypeBlob:setInvisible()
  self.HypeIcon("visible"):SetInt(0)
  self.HypeCount("visible"):SetInt(0)
end
function ClubboxActSelect.ActSelect.LeftHalfBg.HypeBlob:refreshSize()
  self:setSize(Vector2(self:C("HypeIcon"):absW() + self:C("HypeCount"):absW(), self:C("HypeIcon"):absH()))
end
function ClubboxActSelect.ActSelect.LeftHalfBg.HypeBlob:updateText()
  self.HypeCount:updateText()
end
function ClubboxActSelect.ActSelect.LeftHalfBg.HypeBlob.HypeCount:updateText()
  local actSelectEle = self:parent():parent():parent()
  local actId = actSelectEle.selectedActId
  if actId > 0 then
    actSelectEle.LeftHalfBg:setVisible()
    local curHype = game.player():curClubboxTopHype(actId)
    local hypeText = game.getLocalizedText("CLUBBOX_START_HYPE_GENERATED")
    hypeText = hypeText:gsub("%${HYPE}", curHype)
    self("text"):SetString(hypeText)
    self:parent():refreshSize()
  else
    actSelectEle.LeftHalfBg:setInvisible()
  end
end
function ClubboxActSelect.ActSelect.RightHalfBg:onPostInit()
  self:updateText()
end
function ClubboxActSelect.ActSelect.RightHalfBg:setVisible()
  self.RewardBlob:setVisible()
end
function ClubboxActSelect.ActSelect.RightHalfBg:setInvisible()
  self.RewardBlob:setInvisible()
end
function ClubboxActSelect.ActSelect.RightHalfBg:updateText()
  self.RewardBlob:updateText()
end
function ClubboxActSelect.ActSelect.RightHalfBg.RewardBlob:setVisible()
  self.RewardIcon("visible"):SetInt(1)
  self.RewardCount("visible"):SetInt(1)
end
function ClubboxActSelect.ActSelect.RightHalfBg.RewardBlob:setInvisible()
  self.RewardIcon("visible"):SetInt(0)
  self.RewardCount("visible"):SetInt(0)
end
function ClubboxActSelect.ActSelect.RightHalfBg.RewardBlob:refreshSize()
  self:setSize(Vector2(self:C("RewardIcon"):absW() + self:C("RewardCount"):absW(), self:C("RewardIcon"):absH()))
end
function ClubboxActSelect.ActSelect.RightHalfBg.RewardBlob:updateText()
  self.RewardCount:updateText()
end
function ClubboxActSelect.ActSelect.RightHalfBg.RewardBlob.RewardCount:updateText()
  local actSelectEle = self:parent():parent():parent()
  local actId = actSelectEle.selectedActId
  if actId > 0 then
    actSelectEle.RightHalfBg:setVisible()
    local rewardTrackId = game.clubboxActRewardTrackId(actId)
    local rewardTrackData = game.getRewardTrackData(rewardTrackId)
    local currentHype = game.player():curClubboxTopHype(actId)
    local rewardTrackLevelData = game.getRewardTrackLevelData(rewardTrackId, currentHype, false)
    local earnedTier = 0
    local totalLevels = 0
    local rewardText = game.getLocalizedText("CLUBBOX_START_EARNED_REWARDS")
    if rewardTrackLevelData:size() ~= 0 then
      totalLevels = rewardTrackData.totalLevels
      if currentHype >= rewardTrackData.totalPoints then
        earnedTier = totalLevels
      else
        earnedTier = rewardTrackLevelData[0].level - 1
      end
    else
      print("Invalid Reward Track: " .. rewardTrackId)
    end
    rewardText = rewardText:gsub("%${EARNED_TIER}", earnedTier)
    rewardText = rewardText:gsub("%${MAX_TIER}", totalLevels)
    self("text"):SetString(rewardText)
    self:parent():refreshSize()
  else
    actSelectEle.RightHalfBg:setInvisible()
  end
end
function ClubboxActSelect.IslandSelect:onInit()
end
function ClubboxActSelect.IslandSelect:enable()
  self.IslandCarousel:setVisible()
end
function ClubboxActSelect.IslandSelect:disable()
  self.IslandCarousel:setInvisible()
end
function ClubboxActSelect.ConfirmationView:refreshActSprite()
  local actId = self:parent().ActSelect.selectedActId
  if actId > 0 then
    self.ActSprite.Poster("spriteName"):SetString(game.getClubboxActPosterIcon(actId))
    self.ActSprite.Poster("sheetName"):SetString("xml_resources/" .. game.getClubboxActPosterSheet(actId))
  end
end
function ClubboxActSelect.ConfirmationView:refreshIslandSprite()
  local selectedIslandId = self:parent().IslandSelect.selectedIslandId
  self.IslandSprite.Sprite("spriteName"):SetString(game.islandIconSpriteForId(selectedIslandId))
  self.IslandSprite.Sprite("sheetName"):SetString("xml_resources/" .. game.islandIconSheetForId(selectedIslandId))
end
function ClubboxActSelect.ConfirmationView:enable()
  self:refreshActSprite()
  self:refreshIslandSprite()
  self.IslandSprite.Sprite:setVisible()
  self.ActSprite.Poster:setVisible()
  self.ConfirmAllButton:setVisible()
end
function ClubboxActSelect.ConfirmationView:disable()
  self.IslandSprite.Sprite:setInvisible()
  self.ActSprite.Poster:setInvisible()
  self.ConfirmAllButton:setInvisible()
end
function ClubboxActSelect.ConfirmationView.ConfirmAllButton.Touch:onTouchUp(element)
  self:super_onTouchUp(element)
  local actId = element:parent():parent().ActSelect.selectedActId
  if actId > 0 and element:parent():parent().IslandSelect.selectedIslandId ~= 0 then
    manager:setContext(manager:reserveState())
    self:root():popPopUp()
    game.goToClubbox(actId, element:parent():parent().IslandSelect.selectedIslandId)
  end
end
function ClubboxActSelect.BackButton.Touch:onTouchUp(element)
  self:super_onTouchUp(element)
  element.Overlay:setColor(1, 1, 1)
  if element:parent().viewMode == 0 then
    manager:setContext(manager:reserveState())
    game.popPopUp()
  else
    element:parent().viewMode = element:parent().viewMode - 1
    element:parent():refreshView()
  end
end
function ClubboxActSelect.DJWordsLabel:populate(words)
  self.DJWordsLabel.Text("autoScale"):SetInt(0)
  self.DJWordsLabel.Text("size"):SetFloat(0.2 * (screenHeight() / 320))
  self.DJWordsLabel.Text("text"):SetString(words)
  self.DJWordsLabel.Text("autoScale"):SetInt(1)
end
return ClubboxActSelect
