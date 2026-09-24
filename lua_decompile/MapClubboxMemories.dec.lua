local CarouselHelper = include("CarouselHelper")
local MenuHelpers = include("MenuHelpers")
local FadeTransition = include("FadeTransition")
local MapClubboxMemories = {
  Fade = {},
  DJDialog = {},
  LightBurst = {},
  ActSelect = {
    ActName = {},
    HypeBlob = {
      HypeCount = {}
    },
    RewardBlob = {
      RewardCount = {}
    },
    SelectButton = {
      Text = {},
      Touch = {}
    }
  },
  Contents = {
    Touch = {},
    Swiper = {},
    LeftButton = {
      Touch = {}
    },
    RightButton = {
      Touch = {}
    }
  }
}
local activeClubboxActId = function()
  local activeClubbox = game.player():currentyActiveClubbox()
  return activeClubbox and activeClubbox:actId() or -1
end
local function isUnlocked(actId)
  local actData = game.getClubboxActData(actId)
  local topHype = game.player():curClubboxTopHype(actId)
  return topHype >= actData:mixerUnlocksAt() and activeClubboxActId() ~= actId
end
function MapClubboxMemories:onInit()
  self.entries = {}
  function self.Fade.Touch.onTouchUp()
  end
  function self.ActSelect.SelectButton.Touch.onTouchUp(component, element)
    component:super_onTouchUp(element)
    if self.selectedActElement then
      local actId = self.selectedActElement.actId
      if isUnlocked(actId) then
        if actId == activeClubboxActId() then
          game.goToClubbox(0, 0)
        else
          game.gotoClubboxMemory(self.selectedActElement.actId)
        end
      end
    end
  end
  self.selectedActElement = nil
  self.buttonsEnabled = true
  self:SetupGenericListener(game.engineReceiver(), "sys::msg::MsgMouseScroll", "gotMsgMouseScroll")
  self.SpotlightFader = FadeTransition:new({
    duration = 0.33,
    maxFade = 0.5,
    onUpdate = function(alpha)
      self.LightBurst("alpha"):SetFloat(alpha)
    end
  })
  self.SpotlightFader:SetAlpha(0)
end
function MapClubboxMemories:onPostInit()
  self.DJDialog:SetText("CLUBBOX_MEMORY_DJ_INSTRUCTIONS", false)
  self:Populate()
  self.carousel = CarouselHelper:new({
    Element = self.Contents,
    entries = self.entries,
    tiltAngle = 75,
    radius = 140 * game.menuScaleX(),
    verticalBias = -32 * game.menuScaleY(),
    activeIndex = 0,
    onActiveChanged = function(old, new, entry)
      self:SelectAct(entry)
    end,
    onEnableButtons = function(enable)
      self.buttonsEnabled = enable
      if enable then
        self.Contents.LeftButton:enable()
        self.Contents.RightButton:enable()
        self:SelectAct(self.selectedActElement)
      else
        self.Contents.LeftButton:disable()
        self.Contents.RightButton:disable()
        self.ActSelect.SelectButton:disable()
      end
    end
  })
  function self.Contents.LeftButton.Touch.onTouchDown()
    self.carousel:StartMovement(-1)
    self.Contents.RightButton:disable()
    self.buttonsEnabled = false
  end
  function self.Contents.LeftButton.Touch.onTouchUp()
    self.carousel:StopMovement()
    self.buttonsEnabled = true
  end
  function self.Contents.LeftButton.Touch.onTouchRelease()
    self.carousel:StopMovement()
    self.buttonsEnabled = true
  end
  function self.Contents.RightButton.Touch.onTouchDown()
    self.carousel:StartMovement(1)
    self.Contents.LeftButton:disable()
    self.buttonsEnabled = false
  end
  function self.Contents.RightButton.Touch.onTouchUp()
    self.carousel:StopMovement()
    self.buttonsEnabled = true
  end
  function self.Contents.RightButton.Touch.onTouchRelease()
    self.carousel:StopMovement()
    self.buttonsEnabled = true
  end
  local function findUnlockedActElement()
    for i = 1, #self.entries do
      local entry = self.entries[i]
      local actId = entry.actId
      if isUnlocked(actId) then
        return entry, i
      end
    end
    return self.entries[1], 1
  end
  local unlockedElement, unlockedElementIndex = findUnlockedActElement()
  if unlockedElement then
    self.carousel:SetSelectedIndex(unlockedElementIndex)
  end
end
function MapClubboxMemories:onTick(dt)
  self.carousel:Tick(dt)
  self.SpotlightFader:Tick(dt)
end
function MapClubboxMemories:Populate()
  local function initAct(actId, actElement)
    actElement:SetAct(actId)
    function actElement.Touch.onTouchUp()
    end
    local isUnlocked = isUnlocked(actId)
    if not isUnlocked then
      actElement:disable()
    end
  end
  local allActs = game.allClubboxActs()
  for i = 0, allActs:size() - 1 do
    local actId = allActs[i]
    local item = menu:addTemplateElement("template_clubbox_rewind_entry", "entry" .. i, self.Contents)
    item:relativeTo(self.Contents)
    item:setOrientation(lua_sys.MenuOrientation(0, 0, 0, lua_sys.HCENTER, lua_sys.VCENTER))
    item:setRelativeObjectAnchors(lua_sys.HCENTER, lua_sys.VCENTER)
    item:templateVars().layer = "FrontPopUps"
    item:templateVars().scale = 0.6 * game.hudScale()
    item:init()
    item:setPositionBroadcast(true)
    item:postInit()
    initAct(actId, item)
    table.insert(self.entries, item)
  end
end
function MapClubboxMemories:SelectAct(actElement)
  self.selectedActElement = actElement
  if self.selectedActElement then
    local actId = actElement.actId
    if actId > 0 then
      local currentHype = game.player():curClubboxTopHype(actId)
      self.ActSelect.ActName("text"):SetString(LOC(game.getClubboxActTitle(actId)))
      local hypeText = game.getLocalizedText("CLUBBOX_START_HYPE_GENERATED")
      hypeText = hypeText:gsub("%${HYPE}", currentHype)
      self.ActSelect.HypeBlob.HypeCount("text"):SetString(hypeText)
      MenuHelpers.CenterHorizontally({
        self.ActSelect.HypeBlob.HypeIcon,
        self.ActSelect.HypeBlob.HypeCount
      })
      local rewardTrackId = game.clubboxActRewardTrackId(actId)
      local rewardTrackData = game.getRewardTrackData(rewardTrackId)
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
      self.ActSelect.RewardBlob.RewardCount("text"):SetString(rewardText)
      MenuHelpers.CenterHorizontally({
        self.ActSelect.RewardBlob.RewardIcon,
        self.ActSelect.RewardBlob.RewardCount
      })
      local isUnlocked = isUnlocked(actId)
      local isActiveAct = actId == activeClubboxActId()
      if isUnlocked then
        self.ActSelect.SelectButton.Text("noTranslate"):SetInt(0)
        if isActiveAct then
          self.ActSelect.SelectButton.Text("text"):SetString("CLUBBOX_REWIND_ACTION_LIVE")
        else
          self.ActSelect.SelectButton.Text("text"):SetString("CLUBBOX_REWIND_ACTION")
        end
        if self.buttonsEnabled then
          self.ActSelect.SelectButton:enable()
        end
        self.SpotlightFader:Show()
      else
        local lockedString = LOC("CLUBBOX_REWIND_ACTION_LOCKED")
        if isActiveAct then
          lockedString = LOC("CLUBBOX_REWIND_ACTION_LIVE")
        end
        lockedString = string.upper(lockedString)
        self.ActSelect.SelectButton.Text("noTranslate"):SetInt(1)
        self.ActSelect.SelectButton.Text("text"):SetString(lockedString)
        self.ActSelect.SelectButton:disable()
        self.SpotlightFader:Hide()
      end
      if isUnlocked then
        if isActiveAct then
          self.DJDialog:SetText("CLUBBOX_MEMORY_DJ_INSTRUCTIONS_LIVE", false)
        else
          self.DJDialog:SetText("CLUBBOX_MEMORY_DJ_INSTRUCTIONS", false)
        end
      elseif isActiveAct then
        self.DJDialog:SetText("CLUBBOX_MEMORY_DJ_INSTRUCTIONS_LIVE", false)
      else
        self.DJDialog:SetText("CLUBBOX_MEMORY_DJ_INSTRUCTIONS_LOCKED", false)
      end
    else
      print("No Act")
    end
  end
end
function MapClubboxMemories:gotMsgMouseScroll(msg)
  self.carousel:gotMsgMouseScroll(msg)
end
function MapClubboxMemories:queuePop()
  self:root():removePopUp(self:name())
end
return MapClubboxMemories
