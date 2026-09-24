local FillQuestDescription = include("FillQuestDescription")
local GoalHelp = include("GoalHelp")
local Genes = include("Genes")
local DeviceCaps = include("DeviceCaps")
local GoalEntry = {
  GoalIcon = {},
  GoalDesc = {},
  CollectButton = {
    super_onInit = nil,
    super_setInvisible = nil,
    super_setVisible = nil,
    setInvisible = nil,
    setVisible = nil,
    UpSprite = {super_onInit = nil, setInvisible = nil},
    Label = {},
    Touch = {super_onTouchUp = nil},
    isVisible = true
  },
  Progress = {
    super_onInit = nil,
    setInvisible = nil,
    ProgressBarBacking = {},
    ProgressBar = {},
    Label = {},
    isVisible = true
  },
  LeftDivider = {},
  RightDivider = {}
}
function GoalEntry:getNotificationValues()
  if self:parent():GetLuaTable().newNotificationTransitionState == nil then
    return 1, 0
  end
  return self:parent():GetLuaTable().newNotificationTransitionState, self:parent():GetLuaTable().newNotificationTransitionTime
end
function GoalEntry:setNotificationTime(time)
  self:parent():GetLuaTable().newNotificationTransitionTime = time
end
function GoalEntry:setNotificationState(state)
  self:parent():GetLuaTable().newNotificationTransitionState = state
end
function GoalEntry:onInit()
  if self.quest == nil then
    return
  end
  self:V("id"):SetInt(self.quest:getId())
  self.RewardCoins = self.quest:getRewardCoins()
  self.RewardDiamonds = self.quest:getRewardDiamonds()
  self.RewardXp = self.quest:getRewardXp()
  self.RewardFood = self.quest:getRewardFood()
  self.RewardShards = self.quest:getRewardShards()
  self.RewardEntity = self.quest:getRewardEntity()
  self.RewardKeys = self.quest:getRewardKeys()
  self.RewardRelics = self.quest:getRewardRelics()
  self.RewardStarpower = self.quest:getRewardStarpower()
  self("rewardEntity"):SetInt(0)
  self:populateRewards()
  self:populateElementIcons()
  if game.inAdminViewMode() then
    if not GoalEntry.quest:isComplete() then
      local refreshButton = menu:addTemplateElement("template_admin_goalcontrols", "", self)
      refreshButton:relativeTo(self)
      refreshButton:setOrientation(lua_sys.MenuOrientation(60 * game.menuScaleX(), 0, -1, lua_sys.HCENTER, lua_sys.VCENTER))
      refreshButton:setRelativeObjectAnchors(lua_sys.HCENTER, lua_sys.VCENTER)
      refreshButton:init()
      refreshButton("Id"):SetString("" .. self.quest:getId())
    end
    self:E("CollectButton"):setInvisible()
    self:E("CollectButton"):C("Label"):V("visible"):SetInt(0)
  end
  if not self.quest:isNew() then
    self.onTick = nil
  end
end
function GoalEntry:onPostInit()
  if self:E("Progress"):C("ProgressBar"):V("visible"):GetInt() == 0 and self.numRewards == 0 then
    self:E("CollectButton"):V("xOffset"):SetInt(0)
  end
end
function GoalEntry:onTick(dt)
  if self.quest:isNew() and self:visibleOnLayer("Clipping") then
    game.markQuestToRead(self.quest:getId())
    self.onTick = nil
  end
end
function GoalEntry:updateWidth(width)
  local goalIconSize = 0
  if self.GoalIcon:V("visible"):GetInt() ~= 0 then
    goalIconSize = self.GoalIcon:absW() + 8 * game.menuScaleX()
  end
  local collectButtonSize = 0
  collectButtonSize = self.CollectButton:absW()
  local progressSize = 0
  local rewardSize = 0
  if self.numRewards ~= nil and 0 < self.numRewards then
    rewardSize = self:E("Rewards"):absW()
  else
    self.Rewards:setSize(lua_sys.Vector2(0, self.Rewards:absH()))
  end
  local helpArrowSize = self.HelpArrow:absW() + 5 * game.menuScaleX()
  local goalDescWidth = width - goalIconSize - collectButtonSize - progressSize - rewardSize - helpArrowSize
  local offset = 0
  if goalIconSize > 0 then
    offset = offset + goalIconSize
  end
  self.GoalDesc:setSize(lua_sys.Vector2(goalDescWidth, self.GoalDesc:size().y))
  self.GoalDesc:V("xOffset"):SetFloat(offset)
  if goalIconSize == 0 then
    self.New:V("xOffset"):SetFloat(-12 * game.menuScaleX())
  end
  self:calculatePosition()
end
function GoalEntry:populateElementIcons()
  if self.quest == nil then
    return
  end
  local infos = Genes.GetGeneInfosForMonsterId(self.quest:associatedMonsterType())
  if infos then
    for i = 1, #infos do
      local geneItem = menu:addTemplateElement("template_elementicon", "geneItem" .. i, self)
      geneItem:V("SpriteName"):SetString(infos[i].sprite)
      geneItem:V("SheetName"):SetString(infos[i].sheet)
      geneItem:V("Size"):SetFloat(0.2 * game.hudScale())
      geneItem:V("Layer"):SetString("Clipping")
      geneItem:setParent(self)
      geneItem:setOrientation(lua_sys.MenuOrientation((i - #infos * 0.5) * (15 * game.hudScale()), 8, 0, lua_sys.HCENTER, lua_sys.BOTTOM))
      geneItem:setRelativeObjectAnchors(lua_sys.HCENTER, lua_sys.BOTTOM)
      geneItem:init()
      geneItem:setPositionBroadcast(true)
    end
  end
end
local rewardIds = {
  "RewardCoins",
  "RewardDiamonds",
  "RewardXp",
  "RewardFood",
  "RewardShards",
  "RewardEntity",
  "RewardKeys",
  "RewardRelics",
  "RewardStarpower"
}
function GoalEntry:populateRewards()
  local previous
  local numRewards = 0
  for i = 1, #rewardIds do
    if self[rewardIds[i]] > 0 then
      numRewards = numRewards + 1
    end
  end
  if numRewards == 0 then
    self.Progress:V("xOffset"):SetInt(game.menuScaleX())
  end
  for i = 1, #rewardIds do
    local rewardId = rewardIds[i]
    if self[rewardId] > 0 then
      if rewardId == "RewardEntity" then
        self("rewardEntity"):SetInt(1)
      end
      local rewardEntry = menu:addTemplateElement("template_rewardentry", "rewardEntry" .. rewardId, self:E("Rewards"))
      rewardEntry:V("RewardId"):SetString(rewardId)
      rewardEntry:V("RewardAmount"):SetString(game.localizeInt(self[rewardId]))
      if previous == nil then
        rewardEntry:setParent(self:E("Rewards"))
        rewardEntry:setOrientation(lua_sys.MenuOrientation(0, 0, 0, lua_sys.RIGHT, lua_sys.VCENTER))
        rewardEntry:setRelativeObjectAnchors(lua_sys.RIGHT, lua_sys.VCENTER)
      else
        rewardEntry:setParent(previous)
        rewardEntry:setOrientation(lua_sys.MenuOrientation(0, 0, 0, lua_sys.RIGHT, lua_sys.TOP))
        rewardEntry:setRelativeObjectAnchors(lua_sys.RIGHT, lua_sys.BOTTOM)
      end
      rewardEntry:init()
      rewardEntry:setPositionBroadcast(true)
      if previous == nil then
        rewardEntry:V("yOffset"):SetInt(-(rewardEntry:absH() * 0.5 * (numRewards - 1)))
      end
      previous = rewardEntry
    end
  end
  self.numRewards = numRewards
end
function GoalEntry:setInvisible()
  self.GoalIcon:GetVar("visible"):SetInt(0)
  self.GoalDesc:GetVar("visible"):SetInt(0)
  self.hidden = true
end
function GoalEntry:setVisible()
  self.GoalIcon:GetVar("visible"):SetInt(1)
  self.GoalDesc:GetVar("visible"):SetInt(1)
  self.hidden = false
end
function GoalEntry.GoalIcon:onInit(element)
  if GoalEntry.quest == nil then
    return
  end
  local goalIcon = GoalEntry.quest:getImage()
  if goalIcon == "" then
    self:V("visible"):SetInt(0)
  else
    self:V("spriteName"):SetString(goalIcon)
    self:V("sheetName"):SetString("xml_resources/" .. GoalEntry.quest:getSheet() .. ".xml")
    self:V("size"):SetFloat(0.45 * game.menuScaleX())
    self:V("layer"):SetString("Clipping")
  end
end
function GoalEntry.GoalDesc:onInit(element)
  if GoalEntry.quest == nil then
    return
  end
  local description = GoalEntry.quest:getDescription()
  if description == "" then
    description = GoalEntry.quest:getName()
  end
  description = FillQuestDescription(GoalEntry.quest, description)
  self:V("font"):Set(game.getTextFont())
  self:V("size"):SetFloat(0.225 * game.menuScaleX())
  self:V("alignment"):SetInt(lua_sys.MenuTextComponent_TEXT_LEFT_ALIGNED)
  self:V("replaceOnTranslate"):SetInt(1)
  self:V("text"):SetString(description)
  if game.isDebugBuild() and self:parent().DebugQuestIds then
    self:V("text"):SetString("(" .. element.quest:getDataId() .. ")" .. self:V("text"):GetString())
  end
  self:V("autoScale"):SetInt(1)
  self:V("layer"):SetString("Clipping")
end
function GoalEntry.CollectButton:onInit()
  self:super_onInit()
  if game.inAdminViewMode() then
    self:setInvisible()
    self:C("Label"):V("visible"):SetInt(0)
  elseif not GoalEntry.quest:isComplete() then
    self:setInvisible()
    self:C("Label"):V("visible"):SetInt(0)
  else
    self:parent():E("Progress"):setInvisible()
    if self:parent():V("rewardEntity"):GetInt() == 1 then
      self:parent():parent():listenForEntityCollections()
    end
  end
end
function GoalEntry.CollectButton:setInvisible()
  self:super_setInvisible()
  self.isVisible = false
end
function GoalEntry.CollectButton:setVisible()
  self:super_setVisible()
  self.isVisible = true
end
function GoalEntry.CollectButton.UpSprite:onInit(element)
  self:super_onInit(element)
  element.UpSprite("size"):SetFloat(0.4 * game.menuScaleX())
end
function GoalEntry.CollectButton.Label:onInit(element)
  self:V("multiline"):SetInt(0)
  self:V("font"):Set(game.getTitleFont())
  self:V("size"):SetFloat(0.2 * game.menuScaleX())
  self:V("alignment"):SetInt(lua_sys.MenuTextComponent_TEXT_HCENTER_ALIGNED)
  self:V("textPadding"):SetInt(6 * game.menuScaleX())
  self:V("text"):SetString("CONTEXTBAR_COLLECT_LABEL")
  self:V("layer"):SetString("Clipping")
end
function GoalEntry.CollectButton.Touch:onTouchDown(element)
  self:super_onTouchDown(element)
  element.Label:setColor(0.5, 0.5, 0.5)
end
function GoalEntry.CollectButton.Touch:onTouchUp(element)
  self:super_onTouchUp(element)
  element.Label:setColor(1, 1, 1)
  if element:parent():V("rewardEntity"):GetInt() == 1 then
    element:parent():parent():V("clickedQuestName"):SetString(element:parent():name())
    game.displayConfirmation("CONFIRM_ENTITY_REWARD_ISLAND", "CONFIRM_PLACEMENT_NOMOVE")
  else
    if DeviceCaps.supportEffek() then
      local x = element:absX() + element:absW() * 0.5
      local y = element:absY() + element:absH() * 0.5
      local layer = "FrontPopUps"
      local priority = 0.001
      local scale = 20
      local duration = 1
      local playBase = false
      if element:parent().RewardCoins > 0 then
        game.playEffect("particles/Menus/ItemBursts/FX_Burst_Coins.efkefc", x, y, layer, priority, scale, duration)
        playBase = true
      end
      if 0 < element:parent().RewardDiamonds then
        game.playEffect("particles/Menus/ItemBursts/FX_Burst_Diamond.efkefc", x, y, layer, priority, scale, duration)
        playBase = true
      end
      if 0 < element:parent().RewardXp then
        game.playEffect("particles/Menus/ItemBursts/FX_Burst_Stars.efkefc", x, y, layer, priority, scale, duration)
        playBase = true
      end
      if 0 < element:parent().RewardFood then
        game.playEffect("particles/Menus/ItemBursts/FX_Burst_Food.efkefc", x, y, layer, priority, scale, duration)
        playBase = true
      end
      if 0 < element:parent().RewardShards then
        game.playEffect("particles/Menus/ItemBursts/FX_Burst_Shards.efkefc", x, y, layer, priority, scale, duration)
        playBase = true
      end
      if 0 < element:parent().RewardRelics then
        game.playEffect("particles/Menus/ItemBursts/FX_Burst_Relics.efkefc", x, y, layer, priority, scale, duration)
        playBase = true
      end
      if 0 < element:parent().RewardKeys then
        game.playEffect("particles/Menus/ItemBursts/FX_Burst_Keys.efkefc", x, y, layer, priority, scale, duration)
        playBase = true
      end
      if 0 < element:parent().RewardStarpower then
        game.playEffect("particles/Menus/ItemBursts/FX_Burst_StarPower.efkefc", x, y, layer, priority, scale, duration)
        playBase = true
      end
      if playBase then
        game.playEffect("particles/Menus/FX_GoalCollectedUIButton_baseButton.efkefc", x, y, layer, priority + 0.001, scale, duration)
      end
    end
    game.completeQuest(GoalEntry.quest:getId())
  end
end
function GoalEntry.CollectButton.Touch:onTouchRelease(element)
  self:super_onTouchRelease(element)
  element.Label:setColor(1, 1, 1)
end
function GoalEntry.Progress:setInvisible()
  self:C("ProgressBarBacking"):V("visible"):SetInt(0)
  self:C("ProgressBar"):V("visible"):SetInt(0)
  self:C("Label"):V("visible"):SetInt(0)
  self.isVisible = false
end
function GoalEntry.Progress:setVisible()
  self:C("ProgressBarBacking"):V("visible"):SetInt(1)
  self:C("ProgressBar"):V("visible"):SetInt(1)
  self:C("Label"):V("visible"):SetInt(1)
  self.isVisible = true
end
function GoalEntry.Progress.ProgressBarBacking:onInit(element)
  self:V("useOffsets"):SetInt(1)
  self:V("spriteName"):SetString("goal_progress_bar_empty")
  self:V("sheetName"):SetString("xml_resources/hud01.xml")
  self:V("size"):SetFloat(0.5 * game.hudScale())
  self:V("layer"):SetString("Clipping")
end
function GoalEntry.Progress.ProgressBar:onInit(element)
  if GoalEntry.quest == nil then
    return
  end
  self:V("useOffsets"):SetInt(1)
  self:V("spriteName"):SetString("goal_progress_bar_fill")
  self:V("sheetName"):SetString("xml_resources/hud01.xml")
  self:V("size"):SetFloat(0.5 * game.hudScale())
  self:V("layer"):SetString("Clipping")
  self:V("FullMaskH"):SetInt(self:V("maskHeight"):GetInt())
  self:V("FullMaskW"):SetInt(self:V("maskWidth"):GetInt())
  local percentComplete = GoalEntry.quest:percentComplete()
  if self:V("isSourceRotated"):GetInt() == 1 then
    self:V("maskHeight"):SetFloat(self:V("FullMaskH"):GetInt() * lua_sys.clamp(percentComplete, 0, 1))
  else
    self:V("maskWidth"):SetFloat(self:V("FullMaskW"):GetInt() * lua_sys.clamp(percentComplete, 0, 1))
  end
end
function GoalEntry.Progress.Label:onInit(element)
  if GoalEntry.quest == nil then
    return
  end
  self:V("multiline"):SetInt(0)
  self:V("autoScaleFactor"):SetFloat(0.01)
  self:V("autoScale"):SetInt(1)
  self:V("font"):Set(game.getTextFont())
  self:V("size"):SetFloat(0.2 * game.menuScaleX())
  self:V("alignment"):SetInt(lua_sys.MenuTextComponent_TEXT_HCENTER_ALIGNED)
  self:V("textPadding"):SetInt(6 * game.menuScaleX())
  local total = GoalEntry.quest:numProgressMarkersTotal()
  if total == 1 then
    element:setInvisible()
  end
  self:V("text"):SetString(GoalEntry.quest:numProgressMarkersDone() .. "/" .. total)
  self:V("layer"):SetString("Clipping")
end
function GoalEntry.LeftDivider:onInit(element)
  self:V("spriteName"):SetString("goal_swirl")
  self:V("sheetName"):SetString("xml_resources/hud01.xml")
  self:V("size"):SetFloat(0.35 * game.menuScaleX())
  self:V("layer"):SetString("Clipping")
end
function GoalEntry.RightDivider:onInit(element)
  self("spriteName"):SetString("goal_swirl")
  self("sheetName"):SetString("xml_resources/hud01.xml")
  self("size"):SetFloat(0.35 * game.menuScaleX())
  self("vFlip"):SetInt(1)
  self("layer"):SetString("Clipping")
end
local New = {}
function New:onInit(element)
  self:V("spriteName"):SetString("goal_exclaim")
  self:V("sheetName"):SetString("xml_resources/hud01.xml")
  self:V("size"):SetFloat(0.6 * game.hudScale())
  self:V("layer"):SetString("Clipping")
  if not GoalEntry.quest:isNew() then
    self:V("visible"):SetInt(0)
  end
end
function New:onTick(element, dt)
  local state, time = self:parent():getNotificationValues()
  if state ~= 0 and dt <= 0.5 then
    self("size"):SetFloat(0.6 * game.hudScale() * time)
  end
end
GoalEntry.New = New
local HelpArrow = {
  Sprite = {},
  Touch = {}
}
function HelpArrow.Sprite:onInit(element)
  self:V("spriteName"):SetString("arrow01")
  self:V("sheetName"):SetString("xml_resources/hud01.xml")
  self:V("rotation"):SetFloat(-123 * math.pi / 180)
  self:V("size"):SetFloat(0.25 * game.hudScale())
  self:V("layer"):SetString("Clipping")
  if not element:parent():canHelp() then
    self:V("visible"):SetInt(0)
  end
end
GoalEntry.HelpArrow = HelpArrow
function HelpArrow.Touch:onInit(element)
  self:V("layer"):SetString("Clipping")
  self:V("useClipping"):SetInt(1)
end
function HelpArrow.Touch:onTouchDrag(element, x, y, relX, relY, dx, dy)
  self.dragged = self.dragged + math.abs(dy)
end
function HelpArrow.Touch:onTouchDown(element)
  self.dragged = 0
end
function HelpArrow.Touch:onTouchUp(element)
  if self.dragged > 10 then
    return
  end
  if not element:parent():canHelp(element) then
    return
  end
  element:parent():getHelp(element)
end
function GoalEntry:getHelp()
  GoalHelp.getHelp(self.quest, self:parent():parent())
end
function GoalEntry:canHelp()
  return GoalHelp.canHelp(self.quest, self:parent():parent())
end
return GoalEntry
