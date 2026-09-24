local ClubboxIslandCarousel = {
  IslandList = {
    NumIslands = 0,
    activeIndex = 0,
    carouselPosX = 0,
    carouselPosY = -100 * game.menuScaleX()
  },
  SelectIslandButton = {
    Touch = {}
  },
  LeftButton = {
    Touch = {}
  },
  RightButton = {
    Touch = {}
  }
}
local TAU = math.pi * 2
local RADIUS = 175 * game.menuScaleX()
local calculateAngle = function(x, y, carouselPosX, carouselPosY)
  local angle = math.deg(math.atan2(y - lua_sys.screenHeight() / 2 - carouselPosY, x - lua_sys.screenWidth() / 2 - carouselPosX)) + 180
  return angle
end
local function calculateIslandPositionScale(numIslands, i, relativeIndex, amount)
  local degreesBetween = 360 / numIslands
  local angle = TAU * -(i / numIslands)
  local xPosOrig = RADIUS * math.cos(angle)
  local yPosOrig = RADIUS * math.sin(angle)
  local zPosOrig = 0
  local rotAmount = 90 + degreesBetween * relativeIndex + amount
  local xPosRot = xPosOrig * math.cos(math.rad(rotAmount)) - yPosOrig * math.sin(math.rad(rotAmount))
  local yPosRot = xPosOrig * math.sin(math.rad(rotAmount)) + yPosOrig * math.cos(math.rad(rotAmount))
  local zPosRot = zPosOrig
  local xPos = xPosRot
  local yPos = yPosRot * math.cos(math.rad(72.5)) - zPosRot * math.sin(math.rad(72.5))
  local zPos = yPosRot * math.sin(math.rad(72.5)) + zPosRot * math.cos(math.rad(72.5))
  xPos = xPos / (3 / (3 + zPos / RADIUS))
  yPos = yPos / (3 / (3 + zPos / RADIUS))
  zPos = zPos / game.menuScaleX() / -8.75 - 20
  local islandScale = 3 / (3 + (40 + zPos)) * 2 + 1
  return xPos, yPos, zPos, islandScale
end
function ClubboxIslandCarousel:onInit()
  self.TransitionState = 0
  self.TransitionTime = 0
  self.spinning = false
  self.exiting = false
  self.isVisible = true
  self:SetupGenericListener(game.engineReceiver(), "sys::msg::MsgMouseScroll", "gotMsgMouseScroll")
end
function ClubboxIslandCarousel:getSelectedIsland()
  return self:parent().selectedIslandId
end
function ClubboxIslandCarousel:setSelectedIsland(islandId)
  local lastSelectedId = self:parent().selectedIslandId
  self:parent().selectedIslandId = islandId
  self.SelectIslandButton:refresh()
  if self.OnIslandUpdated then
    self:OnIslandUpdated(lastSelectedId, islandId)
  end
end
function ClubboxIslandCarousel:onPostInit()
  local curIsland = self:getSelectedIsland()
  local islands = game.clubboxAvailableOnIslands()
  self.IslandList:populate(islands, curIsland)
  self.SelectIslandButton:refresh()
  if not self.isVisible then
    self:setInvisible()
  end
end
function ClubboxIslandCarousel:gotMsgMouseScroll(msg)
  if not self.spinning then
    if msg.delta > 0 then
      self.spinning = true
      self.LeftButton.Touch:DoStoredScript("onTouchDown")
      self.LeftButton.Touch:DoStoredScript("onTouchUp")
    else
      self.spinning = true
      self.RightButton.Touch:DoStoredScript("onTouchDown")
      self.RightButton.Touch:DoStoredScript("onTouchUp")
    end
  end
end
function ClubboxIslandCarousel:setVisible()
  self.isVisible = true
  self.IslandList:setVisible()
  self.SelectIslandButton:setVisible()
  self.LeftButton:setVisible()
  self.RightButton:setVisible()
  self.SelectIslandButton:refresh()
end
function ClubboxIslandCarousel:setInvisible()
  self.isVisible = false
  self.IslandList:setInvisible()
  self.SelectIslandButton:setInvisible()
  self.LeftButton:setInvisible()
  self.RightButton:setInvisible()
end
function ClubboxIslandCarousel.IslandList:onInit()
  self.DragIsland = false
  self.StartAngle = 0
  self.CurrentAngle = 0
  self.DragStartIndex = 0
  self.DragOffset = 0
  self.SnapIslandToPosition = false
  self.SnapTransitionTime = 0
end
function ClubboxIslandCarousel.IslandList:setVisible()
  for i = 0, self.NumIslands - 1 do
    local entry = self:GetElement("islandEntry" .. i)
    if entry then
      entry:setVisible()
    end
  end
end
function ClubboxIslandCarousel.IslandList:setInvisible()
  for i = 0, self.NumIslands - 1 do
    local entry = self:GetElement("islandEntry" .. i)
    if entry then
      entry:setInvisible()
    end
  end
end
function ClubboxIslandCarousel.IslandList:populate(islands, curIsland)
  for i = 0, self.NumIslands - 1 do
    self:RemoveElement(self:GetElement("islandEntry" .. i))
  end
  self.NumIslands = islands:size()
  local activeIndex = 0
  for i = 0, self.NumIslands - 1 do
    if islands[i] == curIsland then
      activeIndex = i
    end
  end
  self.activeIndex = activeIndex
  for i = 0, self.NumIslands - 1 do
    local islandEntry = menu:addTemplateElement("template_clubbox_islands_entry", "islandEntry" .. i, self)
    islandEntry("IslandId"):SetInt(islands[i])
    if islands[i] == curIsland then
      islandEntry("IslandActive"):SetInt(1)
    else
      islandEntry("IslandActive"):SetInt(0)
    end
    local xPos, yPos, zPos, islandScale = calculateIslandPositionScale(self.NumIslands, i, activeIndex, 0)
    islandEntry("IslandScale"):SetFloat(islandScale)
    islandEntry:setParent(self)
    islandEntry:relativeTo(self)
    islandEntry:setOrientation(lua_sys.MenuOrientation(xPos + self.carouselPosX, yPos + self.carouselPosY, zPos / 3, lua_sys.HCENTER, lua_sys.VCENTER))
    islandEntry:setRelativeObjectAnchors(lua_sys.HCENTER, lua_sys.VCENTER)
    islandEntry:setPositionBroadcast(false)
    islandEntry:init()
    islandEntry:postInit()
    local entryTouch = islandEntry.Touch
    function entryTouch.onTouchDown(component, element, x, y)
      self:islandTouched(x, y)
    end
    function entryTouch.onTouchDrag(component, element, x, y)
      self:islandDragged(x, y)
    end
    function entryTouch.onTouchUp(component, element)
      self:islandReleased()
    end
    function entryTouch.onTouchRelease(component, element)
      self:islandReleased()
    end
  end
  self:setPositionBroadcast(true)
end
function ClubboxIslandCarousel.IslandList:onTick(dt)
  local carousel = self:parent()
  local numIslands = self.NumIslands
  local amount = 0
  local degreesBetween = 360 / numIslands
  if self.DragIsland or self.SnapIslandToPosition then
    self:HandleDrag(dt)
  end
  local transitionState = carousel.TransitionState
  local transitionTime = carousel.TransitionTime
  if transitionState ~= 0 and dt <= 0.5 or (transitionState == 0 or transitionState == -2) and transitionTime > 0 and dt <= 0.5 then
    transitionTime = math.max(0, transitionTime - dt)
    if transitionState == -1 or transitionState == -2 then
      amount = -(degreesBetween - transitionTime * 4 * degreesBetween)
    else
      amount = -(transitionTime * 4 * degreesBetween) - degreesBetween
    end
    self:UpdateIslands(self.activeIndex + 1, amount, dt)
    carousel.TransitionTime = transitionTime
    if transitionTime == 0 then
      if transitionState == -2 then
        transitionState = 0
      end
      if transitionState ~= 0 then
        transitionTime = 0.25
      end
      if transitionState == 0 then
        self:EnableButtons(true)
        carousel.spinning = false
      end
      local activeIndex = self.activeIndex
      local oldIndex = activeIndex
      if transitionState == -1 then
        if activeIndex == 0 then
          activeIndex = self.NumIslands - 1
        else
          activeIndex = activeIndex - 1
        end
      elseif transitionState == 1 then
        if activeIndex == numIslands - 1 then
          activeIndex = 0
        else
          activeIndex = activeIndex + 1
        end
      end
      self:UpdateActiveIslandEntry(oldIndex, activeIndex)
      carousel.TransitionTime = transitionTime
      carousel.TransitionState = transitionState
    end
  end
end
function ClubboxIslandCarousel.IslandList:EnableButtons(enable)
  local carousel = self:parent()
  local enableScript = enable and "enable" or "disable"
  carousel.LeftButton:DoStoredScript(enableScript)
  carousel.RightButton:DoStoredScript(enableScript)
end
function ClubboxIslandCarousel.IslandList:UpdateActiveIslandEntry(oldIndex, newIndex)
  local carousel = self:parent()
  if oldIndex == newIndex then
    return
  end
  local oldEntry = self:GetElement("islandEntry" .. oldIndex)
  oldEntry.Overlay:setColor(0.5, 0.5, 0.5)
  local nextActiveEntry = self:GetElement("islandEntry" .. newIndex)
  local nextActiveIsland = nextActiveEntry("IslandId"):GetInt()
  if not game.isIslandOwned(nextActiveIsland) then
    if not game.hasNecessaryPrevIslandsToUnlock(nextActiveIsland) then
      nextActiveEntry.Overlay:setColor(0.5, 0.5, 0.5)
    elseif not game.canUnlockIsland(nextActiveIsland) then
      nextActiveEntry.Overlay:setColor(0.5, 0.5, 0.5)
    else
      nextActiveEntry.Overlay:setColor(1, 1, 1)
    end
  else
    nextActiveEntry.Overlay:setColor(1, 1, 1)
  end
  self.activeIndex = newIndex
  carousel:setSelectedIsland(nextActiveIsland)
end
function ClubboxIslandCarousel.IslandList:UpdateIslands(relativeIndex, amount, dt)
  local numIslands = self.NumIslands
  for i = 0, numIslands - 1 do
    local xPos, yPos, zPos, islandScale = calculateIslandPositionScale(self.NumIslands, i, relativeIndex, amount)
    local islandEntry = self:GetElement("islandEntry" .. i)
    islandEntry:setOrientationPosition(lua_sys.Vector2(xPos + self.carouselPosX, yPos + self.carouselPosY))
    islandEntry:setOrientationPriority(zPos / 2)
    islandEntry.Overlay("size"):SetFloat(0.2 * game.menuScaleX() * islandScale)
    islandEntry.Lock("size"):SetFloat(0.35 * game.menuScaleX() * islandScale)
  end
end
function ClubboxIslandCarousel.IslandList:HandleDrag(dt)
  local numIslands = self.NumIslands
  local amount = 0
  local degreesBetween = 360 / numIslands
  local activeIndex = self.activeIndex
  local newActiveIndex = activeIndex
  local relativeIndex = activeIndex
  if self.SnapIslandToPosition then
    local transitionTime = math.max(0, self.SnapTransitionTime - dt)
    local dragOffset = self.DragOffset
    if dragOffset > 0 then
      amount = dragOffset - dragOffset * (1 - transitionTime)
    else
      amount = dragOffset + -dragOffset * (1 - transitionTime)
    end
    self.SnapTransitionTime = transitionTime
    if transitionTime == 0 then
      self.SnapIslandToPosition = false
      self:EnableButtons(true)
    end
  else
    amount = self.CurrentAngle - self.StartAngle
    newActiveIndex = self.DragStartIndex
    if amount ~= 0 then
      newActiveIndex = newActiveIndex + lua_sys.Math.Round(amount / degreesBetween)
    end
    relativeIndex = self.DragStartIndex
    if newActiveIndex > numIslands - 1 then
      newActiveIndex = newActiveIndex - numIslands
    end
    if newActiveIndex < 0 then
      newActiveIndex = newActiveIndex + numIslands
    end
  end
  self:UpdateIslands(relativeIndex, amount, dt)
  self:UpdateActiveIslandEntry(activeIndex, newActiveIndex)
end
function ClubboxIslandCarousel.IslandList:islandTouched(x, y)
  if not self.SnapIslandToPosition then
    local angle = calculateAngle(x, y, self.carouselPosX, self.carouselPosY)
    self.StartAngle = angle
    self.CurrentAngle = angle
    self.DragStartIndex = self.activeIndex
    self.DragIsland = true
    self:EnableButtons(false)
  end
end
function ClubboxIslandCarousel.IslandList:islandDragged(x, y)
  self.CurrentAngle = calculateAngle(x, y, self.carouselPosX, self.carouselPosY)
end
function ClubboxIslandCarousel.IslandList:islandReleased()
  local activeEntry = self:GetElement("islandEntry" .. self.activeIndex)
  local x = activeEntry:position().x + activeEntry:size().x / 2
  local y = activeEntry:position().y + activeEntry:size().y / 2
  local currentAngle = calculateAngle(x, y, self.carouselPosX, self.carouselPosY)
  currentAngle = currentAngle - 270
  local numIslands = self.NumIslands
  local degreesBetween = 360 / numIslands
  local transitionTime = math.abs(currentAngle / degreesBetween * 0.25)
  self.DragOffset = currentAngle
  self.SnapTransitionTime = transitionTime
  self.SnapIslandToPosition = true
  self.DragIsland = false
end
function ClubboxIslandCarousel.SelectIslandButton:refresh()
  local carousel = self:parent()
  local selectedIslandId = carousel:getSelectedIsland()
  if selectedIslandId == 0 then
    self:disable()
  elseif not game.isIslandOwned(selectedIslandId) then
    self:disable()
  else
    self:enable()
  end
end
function ClubboxIslandCarousel.SelectIslandButton.Touch:onTouchUp(element)
  self:super_onTouchUp(element)
  element:parent():parent():parent():advanceToConfirmation()
end
function ClubboxIslandCarousel.LeftButton.Touch:onTouchDown(element)
  self:super_onTouchDown(element)
  local carousel = element:parent()
  local activeIndex = carousel.IslandList.activeIndex
  local oldEntry = carousel.IslandList:GetElement("islandEntry" .. activeIndex)
  oldEntry.Overlay:setColor(0.5, 0.5, 0.5)
  if activeIndex == 0 then
    activeIndex = carousel.IslandList.NumIslands - 1
  else
    activeIndex = activeIndex - 1
  end
  local islandEntry = carousel.IslandList:GetElement("islandEntry" .. activeIndex)
  islandEntry.Overlay:setColor(1, 1, 1)
  carousel:setSelectedIsland(islandEntry("IslandId"):GetInt())
  carousel.IslandList.activeIndex = activeIndex
  carousel.RightButton:disable()
  carousel.TransitionState = -1
  carousel.TransitionTime = 0.25
end
function ClubboxIslandCarousel.LeftButton.Touch:onTouchUp(element)
  self:super_onTouchUp(element)
  element:disable()
  local carousel = element:parent()
  carousel.TransitionState = -2
end
function ClubboxIslandCarousel.LeftButton.Touch:onTouchRelease(element)
  self:super_onTouchRelease(element)
  element:disable()
  local carousel = element:parent()
  carousel.TransitionState = -2
end
function ClubboxIslandCarousel.RightButton.Touch:onTouchDown(element)
  self:super_onTouchDown(element)
  local carousel = element:parent()
  local activeIndex = carousel.IslandList.activeIndex
  local numIslands = carousel.IslandList.NumIslands
  local oldEntry = carousel.IslandList:GetElement("islandEntry" .. activeIndex)
  oldEntry.Overlay:setColor(0.5, 0.5, 0.5)
  if activeIndex == numIslands - 1 then
    activeIndex = 0
  else
    activeIndex = activeIndex + 1
  end
  local islandEntry = carousel.IslandList:GetElement("islandEntry" .. activeIndex)
  local island = islandEntry("IslandId"):GetInt()
  islandEntry.Overlay:setColor(1, 1, 1)
  carousel:setSelectedIsland(island)
  carousel.IslandList.activeIndex = activeIndex
  carousel.LeftButton:disable()
  carousel.TransitionState = 1
  carousel.TransitionTime = 0.25
end
function ClubboxIslandCarousel.RightButton.Touch:onTouchUp(element)
  self:super_onTouchUp(element)
  element:disable()
  local carousel = element:parent()
  carousel.TransitionState = 0
end
function ClubboxIslandCarousel.RightButton.Touch:onTouchRelease(element)
  self:super_onTouchRelease(element)
  element:disable()
  local carousel = element:parent()
  carousel.TransitionState = 0
end
return ClubboxIslandCarousel
