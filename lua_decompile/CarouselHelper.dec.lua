local TransitionStates = {
  MovingLeft = -1,
  MovingRight = 1,
  SnapBack = -2,
  Idle = 0
}
local CarouselHelper = {
  TransitionState = TransitionStates.Idle,
  TransitionTime = 0,
  spinning = false,
  exiting = false,
  isVisible = true,
  scaleMin = 0.5,
  scaleMax = 1,
  radius = 175 * game.menuScaleX(),
  focalLength = 3,
  verticalBias = 0,
  tiltAngle = 72.5,
  onActiveChanged = nil,
  onEnableButtons = nil,
  onSetVisible = nil,
  DragEntry = false,
  StartAngle = 0,
  CurrentAngle = 0,
  DragStartIndex = 1,
  DragOffset = 0,
  SnapEntryToPosition = false,
  SnapTransitionTime = 0,
  activeIndex = 1,
  touchStartTimer = 99
}
local TAU = math.pi * 2
local TILT_ANGLE = math.rad(72.5)
local TILT_SIN = math.sin(TILT_ANGLE)
local TILT_COS = math.cos(TILT_ANGLE)
function CarouselHelper:new(obj)
  obj = obj or {}
  setmetatable(obj, self)
  self.__index = self
  obj:Init()
  return obj
end
function CarouselHelper:Init()
  assert(self.Element, "CarouselHelper: must provide Element")
  assert(self.entries, "CarouselHelper: must provide entries")
  assert(self.radius > 0, "CarouselHelper: radius must be greater than zero")
  self:SetAngle(self.tiltAngle)
  for i, entry in ipairs(self.entries) do
    if entry.Touch then
      do
        local currentOnTouchDown = entry.Touch.onTouchDown
        function entry.Touch.onTouchDown(component, element, x, y)
          if currentOnTouchDown then
            currentOnTouchDown(component, element, x, y)
          end
          self:entryTouched(x, y)
        end
        local currentOnTouchDrag = entry.Touch.onTouchDrag
        function entry.Touch.onTouchDrag(component, element, x, y)
          if currentOnTouchDrag then
            currentOnTouchDrag(component, element, x, y)
          end
          self:entryDragged(x, y)
        end
        local currentOnTouchUp = entry.Touch.onTouchUp
        function entry.Touch.onTouchUp(component, element)
          if currentOnTouchUp then
            currentOnTouchUp(component, element)
          end
          self:entrySelected(i)
        end
        local currentOnTouchRelease = entry.Touch.onTouchRelease
        function entry.Touch.onTouchRelease(component, element)
          if currentOnTouchRelease then
            currentOnTouchRelease(component, element)
          end
          self:entryReleased()
        end
      end
    end
  end
  self.Element:setPositionBroadcast(true)
  self:UpdateEntries(self.activeIndex, 0)
end
function CarouselHelper:SetAngle(angle)
  TILT_ANGLE = math.rad(angle)
  TILT_SIN = math.sin(TILT_ANGLE)
  TILT_COS = math.cos(TILT_ANGLE)
end
function CarouselHelper:_calculateAngle(x, y)
  local posX = self.Element:absX()
  local posY = self.Element:absY()
  local centerX = posX + self.Element:absW() * 0.5
  local centerY = posY + self.Element:absH() * 0.5
  return math.deg(math.atan2(y - centerY, x - centerX)) + 180
end
function CarouselHelper:_calculateEntryPositionScale(i, relativeIndex, amount)
  local numEntries = #self.entries
  local degreesBetween = 360 / numEntries
  local angle = TAU * -(i / numEntries)
  local xPosOrig = self.radius * math.cos(angle)
  local yPosOrig = self.radius * math.sin(angle)
  local rotAmount = math.rad(90 + degreesBetween * relativeIndex + amount)
  local rotAmountSin = math.sin(rotAmount)
  local rotAmountCos = math.cos(rotAmount)
  local xPosRot = xPosOrig * rotAmountCos - yPosOrig * rotAmountSin
  local yPosRot = xPosOrig * rotAmountSin + yPosOrig * rotAmountCos
  local xPos = xPosRot
  local yPos = yPosRot * TILT_COS
  local zPos = yPosRot * TILT_SIN
  local focalLength = self.focalLength or 3
  local perspective = focalLength / (focalLength + zPos / self.radius)
  xPos = xPos / perspective
  yPos = yPos / perspective
  local zNorm = (zPos + self.radius) / (2 * self.radius)
  zNorm = math.max(0, math.min(1, zNorm))
  local scale = self.scaleMin + (self.scaleMax - self.scaleMin) * zNorm
  yPos = yPos + self.verticalBias
  return xPos, yPos, zNorm, scale
end
function CarouselHelper:gotMsgMouseScroll(msg)
  if not self.spinning then
    if msg.delta > 0 then
      self.spinning = true
      self:StartMovement(-1)
      self:StopMovement()
    else
      self.spinning = true
      self:StartMovement(1)
      self:StopMovement()
    end
  end
end
function CarouselHelper:Tick(dt)
  if self.DragEntry or self.SnapEntryToPosition then
    self:HandleDrag(dt)
  end
  local transitionState = self.TransitionState
  local transitionTime = self.TransitionTime
  self.touchStartTimer = self.touchStartTimer + dt
  if transitionState ~= TransitionStates.Idle and dt <= 0.5 or (transitionState == TransitionStates.Idle or transitionState == TransitionStates.SnapBack) and transitionTime > 0 and dt <= 0.5 then
    transitionTime = math.max(0, transitionTime - dt)
    local numEntries = #self.entries
    local degreesBetween = 360 / numEntries
    local amount = 0
    if transitionState == TransitionStates.MovingLeft or transitionState == TransitionStates.SnapBack then
      amount = -(degreesBetween - transitionTime * 4 * degreesBetween)
    else
      amount = -(transitionTime * 4 * degreesBetween) - degreesBetween
    end
    self:UpdateEntries(self.activeIndex + 1, amount)
    self.TransitionTime = transitionTime
    if transitionTime == 0 then
      if transitionState == TransitionStates.SnapBack then
        transitionState = TransitionStates.Idle
      end
      if transitionState ~= TransitionStates.Idle then
        transitionTime = 0.25
      end
      if transitionState == TransitionStates.Idle then
        self:EnableButtons(true)
        self.spinning = false
      end
      local activeIndex = self.activeIndex
      local oldIndex = activeIndex
      if transitionState == TransitionStates.MovingLeft then
        activeIndex = self:previousIndex()
      elseif transitionState == TransitionStates.MovingRight then
        activeIndex = self:nextIndex()
      end
      self:UpdateActiveEntry(oldIndex, activeIndex)
      self.TransitionTime = transitionTime
      self.TransitionState = transitionState
    end
  end
end
function CarouselHelper:EnableButtons(enable)
  if self.onEnableButtons then
    self.onEnableButtons(enable)
  end
end
function CarouselHelper:SetVisible(enable)
  if self.onSetVisible then
    self.onSetVisible(enable)
  end
end
function CarouselHelper:UpdateActiveEntry(oldIndex, newIndex)
  if oldIndex == newIndex then
    return
  end
  local lastIndex = self.activeIndex
  self.activeIndex = newIndex
  print("Update Active:", oldIndex, "->", newIndex)
  if self.onActiveChanged then
    self.onActiveChanged(lastIndex, self.activeIndex, self.entries[self.activeIndex])
  end
end
function CarouselHelper:UpdateEntries(relativeIndex, amount)
  for i, entry in ipairs(self.entries) do
    local xPos, yPos, zPos, scale = self:_calculateEntryPositionScale(i, relativeIndex, amount)
    entry:setOrientationPosition(lua_sys.Vector2(xPos, yPos))
    entry:setOrientationPriority(-zPos)
    if entry.SetScale then
      entry:SetScale(scale)
    end
  end
end
function CarouselHelper:HandleDrag(dt)
  local amount = 0
  local numEntries = #self.entries
  local degreesBetween = 360 / numEntries
  local activeIndex = self.activeIndex
  local newActiveIndex = activeIndex
  local relativeIndex = activeIndex
  if self.SnapEntryToPosition then
    local transitionTime = math.max(0, self.SnapTransitionTime - dt)
    local dragOffset = self.DragOffset
    if dragOffset > 0 then
      amount = dragOffset - dragOffset * (1 - transitionTime)
    else
      amount = dragOffset + -dragOffset * (1 - transitionTime)
    end
    self.SnapTransitionTime = transitionTime
    if transitionTime == 0 then
      self.SnapEntryToPosition = false
      self:EnableButtons(true)
    end
  else
    amount = self.CurrentAngle - self.StartAngle
    local moveSteps = lua_sys.Math.Round(amount / degreesBetween)
    newActiveIndex = (self.DragStartIndex + moveSteps - 1 + numEntries) % numEntries + 1
    relativeIndex = self.DragStartIndex
  end
  self:UpdateEntries(relativeIndex, amount)
  self:UpdateActiveEntry(activeIndex, newActiveIndex)
end
function CarouselHelper:entryTouched(x, y)
  if not self.SnapEntryToPosition then
    local angle = self:_calculateAngle(x, y)
    self.StartAngle = angle
    self.CurrentAngle = angle
    self.DragStartIndex = self.activeIndex
    self.DragEntry = true
    self:EnableButtons(false)
  end
  self.touchStartTimer = 0
end
function CarouselHelper:entryDragged(x, y)
  self.CurrentAngle = self:_calculateAngle(x, y)
end
function CarouselHelper:entryReleased()
  local activeEntry = self.entries[self.activeIndex]
  local x = activeEntry:position().x + activeEntry:size().x / 2
  local y = activeEntry:position().y + activeEntry:size().y / 2
  local currentAngle = self:_calculateAngle(x, y)
  currentAngle = currentAngle - 270
  local numEntries = #self.entries
  local degreesBetween = 360 / numEntries
  local transitionTime = math.abs(currentAngle / degreesBetween * 0.25)
  self.DragOffset = currentAngle
  self.SnapTransitionTime = transitionTime
  self.SnapEntryToPosition = true
  self.DragEntry = false
end
function CarouselHelper:entrySelected(index)
  if self.touchStartTimer > 0.3 or math.abs(self.CurrentAngle - self.StartAngle) > 5 then
    self:entryReleased()
    return
  end
  self:SetSelectedIndex(index)
end
function CarouselHelper:SetSelectedIndex(index)
  local activeEntry = self.entries[index]
  local x = activeEntry:position().x + activeEntry:size().x / 2
  local y = activeEntry:position().y + activeEntry:size().y / 2
  self.DragOffset = self:_calculateAngle(x, y)
  self.SnapTransitionTime = 0
  self.SnapEntryToPosition = true
  self.DragEntry = false
  self:UpdateEntries(self.activeIndex, 0)
  self:UpdateActiveEntry(self.activeIndex, index)
end
function CarouselHelper:StartMovement(direction)
  local lastIndex = self.activeIndex
  if direction == -1 then
    self.activeIndex = self:previousIndex()
    self:UpdateActiveEntry(lastIndex, self.activeIndex)
    self.TransitionState = -1
    self.TransitionTime = 0.25
  end
  if direction == 1 then
    self.activeIndex = self:nextIndex()
    self:UpdateActiveEntry(lastIndex, self.activeIndex)
    self.TransitionState = 1
    self.TransitionTime = 0.25
  end
end
function CarouselHelper:StopMovement()
  if self.TransitionState == TransitionStates.MovingLeft then
    self.TransitionState = -2
  else
    self.TransitionState = 0
  end
end
function CarouselHelper:previousIndex()
  return (self.activeIndex - 2 + #self.entries) % #self.entries + 1
end
function CarouselHelper:nextIndex()
  return self.activeIndex % #self.entries + 1
end
return CarouselHelper
