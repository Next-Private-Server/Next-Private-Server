local ElementFader = include("ElementFader")
local ElementTools = include("ElementTools")
local NUM_COLUMNS = 3
local HPADDING = 4 * game.hudScale()
local VPADDING = 4 * game.hudScale()
local BOTTOM_LABEL_SIZE = 30
local BORDER_SIZE = 0.25 * game.menuScaleX() * 50
local ActivityCenter = {
  Panel = {},
  UpdateOnLevel = {},
  disableTouches = false
}
function ActivityCenter:onInit()
  self:SetupGenericListener(game.engineReceiver(), "game::msg::MsgTutorialInitialized", "gotMsgTutorialInitialized")
  self:SetupGenericListener(game.engineReceiver(), "game::msg::MsgTutorialComplete", "gotMsgTutorialComplete")
  self:SetupGenericListener(game.engineReceiver(), "game::msg::MsgLevelChanged", "gotMsgLevelChanged")
  self:SetupGenericListener(game.engineReceiver(), "game::msg::MsgCreateStructure", "gotMsgCreateStructure")
  self:SetupGenericListener(game.engineReceiver(), "game::msg::MsgDestroyStructure", "gotMsgDestroyStructure")
end
function ActivityCenter:Refresh()
  local elements = self.Panel:elements()
  local numItems = elements:size()
  for i = 0, numItems - 1 do
    local element = elements[i]
    if element.onPostInit ~= nil then
      element:onPostInit(true)
    end
  end
  for i = 1, #self.UpdateOnLevel do
    local element = self.UpdateOnLevel[i]
    if element.onPostInit ~= nil then
      element:onPostInit(true)
    end
  end
  self:parent().ActivityButton:onPostInit()
end
function ActivityCenter:gotMsgTutorialInitialized(msg)
  self:Refresh()
end
function ActivityCenter:gotMsgTutorialComplete(msg)
  self:Refresh()
end
function ActivityCenter:gotMsgLevelChanged(msg)
  self:Refresh()
end
function ActivityCenter:gotMsgCreateStructure(msg)
  self:Refresh()
end
function ActivityCenter:gotMsgDestroyStructure(msg)
  self:Refresh()
end
function ActivityCenter:gotMsgContextBarStateChange(msg)
  if self.isVisible and msg.prevState == game.ContextBar_IDLE and msg.state == game.ContextBar_EXITING then
    self:Hide()
  end
end
function ActivityCenter:enableTouches(value, force)
  local touchComponents = ElementTools.FindAllComponents(self.Panel, function(component)
    local p = component:parent()
    return component.touchDown ~= nil and (force or p.isVisible)
  end)
  for i = 1, #touchComponents do
    touchComponents[i]:V("enabled"):SetInt(value)
  end
end
function ActivityCenter:onPostInit()
  self.properXOffset = self.Panel:V("xOffset"):GetFloat()
  self.startXOffset = self.properXOffset - self.Panel:absW()
  self.fader = ElementFader.New(self, {
    duration = 0.2,
    onUpdate = function(alpha)
      if self.disableTouches then
        self:enableTouches(0)
        self.disableTouches = false
      end
      self.Panel:V("xOffset"):SetFloat(self.startXOffset + self.Panel:absW() * alpha)
      local arrow = self.Arrow
      local totalAngle = arrow.openAngle - arrow.closeAngle
      self.Arrow:V("rotation"):SetFloat((self.Arrow.closeAngle + totalAngle * alpha) * math.pi / 180)
    end,
    onDone = function(fader, showing)
      self.isAnimating = false
      if showing then
        self:enableTouches(1)
        local elements = self.Panel:elements()
        local numItems = elements:size()
        for i = 0, numItems - 1 do
          local element = elements[i]
          if element.refresh ~= nil then
            element:refresh()
          end
        end
      end
    end
  })
  self.isAnimating = false
  self.isVisible = false
  self:V("IsOpen"):SetInt(0)
  self.Block:V("enabled"):SetInt(0)
  self:enableTouches(0, true)
  self.fader:Hide(true)
  self:SetupGenericListener(game.engineReceiver(), "game::msg::MsgContextBarStateChange", "gotMsgContextBarStateChange")
end
function ActivityCenter:onTick(dt)
  self.fader:tick(dt)
end
function ActivityCenter:getDisplayedElements()
  local allElements = self.Panel:elements()
  local elements = {}
  for i = 0, allElements:size() - 1 do
    local item = allElements[i]
    if item.isVisible then
      elements[#elements + 1] = item
    end
  end
  local numItems = #elements
  if numItems == 0 then
    return nil
  end
  return elements
end
function ActivityCenter:canDisplay()
  local elements = self:getDisplayedElements()
  return elements and game.tutorialCanShowActivityButton() and not game.inPaintMode()
end
function ActivityCenter:Show()
  if self.isAnimating then
    return
  end
  self:sort()
  self.startXOffset = self.properXOffset - self.Panel:absW()
  self.Panel:V("xOffset"):SetFloat(self.startXOffset)
  self.Block:V("enabled"):SetInt(1)
  self.isAnimating = true
  self.isVisible = true
  self:V("IsOpen"):SetInt(1)
  self.fader:Show()
  local panelPos = self:absY() + self.Panel:absH() * 0.5 + self.Panel:V("yOffset"):GetFloat()
  local halfScreenHeight = lua_sys.screenHeight() * 0.5
  local delta = panelPos - halfScreenHeight
  if delta > 0 then
    self.Panel:V("yOffset"):SetFloat(-delta)
  end
end
function ActivityCenter:Hide()
  self.Block:V("enabled"):SetInt(0)
  self.isAnimating = true
  self.isVisible = false
  self.disableTouches = true
  self:V("IsOpen"):SetInt(0)
  self.fader:Hide()
end
function ActivityCenter:sort()
  local elements = self:getDisplayedElements()
  local cellWidth = 0
  local cellHeight = 0
  if elements == nil then
    self.Panel:setSize(lua_sys.Vector2(BORDER_SIZE * 2, BORDER_SIZE * 2))
    return
  end
  local numItems = #elements
  local firstItem = elements[1]
  cellWidth = firstItem:absW()
  cellHeight = firstItem:absH() + BOTTOM_LABEL_SIZE
  local numColumns = math.min(#elements, NUM_COLUMNS)
  local numRows = math.ceil(numItems / NUM_COLUMNS)
  local panelWidth = numColumns * cellWidth + (numColumns - 1) * HPADDING + BORDER_SIZE * 2
  local panelHeight = numRows * cellHeight + (numRows - 1) * VPADDING + BORDER_SIZE * 2
  self.Panel:setSize(lua_sys.Vector2(panelWidth, panelHeight))
  local currentColumn = 0
  local currentRow = 0
  for i = 1, numItems do
    local item = elements[i]
    item:V("xOffset"):SetFloat(BORDER_SIZE + currentColumn * cellWidth + currentColumn * HPADDING)
    item:V("yOffset"):SetFloat(BORDER_SIZE + currentRow * cellHeight + currentRow * VPADDING)
    currentColumn = currentColumn + 1
    if currentColumn >= NUM_COLUMNS then
      currentColumn = 0
      currentRow = currentRow + 1
    end
  end
end
local PanelBlock = {}
function PanelBlock:onInit(element)
  element.isVisible = true
end
ActivityCenter.Panel.PanelBlock = PanelBlock
local Block = {}
function Block:onInit(element)
  self:V("passthrough"):SetInt(1)
end
function Block:onTouchUp()
  self:parent():Hide()
end
ActivityCenter.Block = Block
return ActivityCenter
