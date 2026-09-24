local OffsetTransition = {
  x = 0,
  y = 0,
  state = 0,
  remainingTime = 0,
  duration = 0.33,
  startX = 0,
  startY = 0,
  endX = 0,
  endY = 0,
  delayRemaining = 0,
  delayOnShow = 0,
  delayOnHide = 0,
  ease = lua_sys.Back_EaseIn,
  easeX = nil,
  easeY = nil,
  onDoneShow = nil,
  onDoneHide = nil,
  onUpdate = nil,
  onDoneDelay = nil
}
function OffsetTransition:new(obj)
  local obj = obj or {}
  setmetatable(obj, self)
  self.__index = self
  return obj
end
function OffsetTransition:Show()
  self.state = 1
  self.remainingTime = self.duration
  self.delayRemaining = self.delayOnShow
end
function OffsetTransition:Hide()
  self.state = -1
  self.remainingTime = self.duration
  self.delayRemaining = self.delayOnHide
end
function OffsetTransition:Cancel()
  self.remainingTime = 0
end
function OffsetTransition:GetTransitionTime()
  return self.remainingTime
end
function OffsetTransition:SetOffset(x, y)
  self.x = x
  self.y = y
  if self.onUpdate then
    self.onUpdate(x, y, self)
  end
end
function OffsetTransition:Tick(dt)
  dt = math.min(dt, 0.033)
  if self.remainingTime > 0 then
    if 0 < self.delayRemaining then
      self.delayRemaining = math.max(0, self.delayRemaining - dt)
      if 0 >= self.delayRemaining then
        if self.onDoneDelay then
          self:onDoneDelay()
        end
      else
        return
      end
    end
    self.remainingTime = math.max(0, self.remainingTime - dt)
    local easeX = self.easeX or self.ease
    local easeY = self.easeY or self.ease
    local easedTimeX = 1 - easeX(self.remainingTime, 0, 1, self.duration)
    local easedTimeY = 1 - easeY(self.remainingTime, 0, 1, self.duration)
    if self.state == 1 then
      local x = lerp(self.startX, self.endX, easedTimeX)
      local y = lerp(self.startY, self.endY, easedTimeY)
      self:SetOffset(x, y)
    elseif self.state == -1 then
      local x = lerp(self.endX, self.startX, easedTimeX)
      local y = lerp(self.endY, self.startY, easedTimeY)
      self:SetOffset(x, y)
    end
    if self.remainingTime <= 0 then
      local lastState = self.state
      self.state = 0
      if lastState == -1 and self.onDoneHide then
        self:onDoneHide()
      end
      if lastState == 1 and self.onDoneShow then
        self:onDoneShow()
      end
    end
  end
end
return OffsetTransition
