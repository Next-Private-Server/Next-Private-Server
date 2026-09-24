local Spiral = {
  x = 0,
  y = 0,
  state = 0,
  remainingTime = 0,
  duration = 0.33,
  centerX = 0,
  centerY = 0,
  startRadians = math.pi * 2,
  endRadians = 0,
  factorStart = 1,
  factorEnd = 0,
  delayRemaining = 0,
  delayOnShow = 0,
  delayOnHide = 0,
  ease = lua_sys.Linear_EaseNone,
  easeR = lua_sys.Linear_EaseNone,
  onDoneShow = nil,
  onDoneHide = nil,
  onUpdate = nil,
  onDoneDelay = nil
}
function Spiral:new(obj)
  local obj = obj or {}
  setmetatable(obj, self)
  self.__index = self
  return obj
end
function Spiral:Show()
  self.state = 1
  self.remainingTime = self.duration
  self.delayRemaining = self.delayOnShow
end
function Spiral:Hide()
  self.state = -1
  self.remainingTime = self.duration
  self.delayRemaining = self.delayOnHide
end
function Spiral:GetTransitionTime()
  return self.remainingTime
end
function Spiral:SetOffset(x, y)
  self.x = x
  self.y = y
  if self.onUpdate then
    self.onUpdate(x, y, self)
  end
end
function Spiral:Tick(dt)
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
    local easedTime = 1 - self.ease(self.remainingTime, 0, 1, self.duration)
    local radians = 0
    if self.state == 1 then
      radians = lerp(self.startRadians, self.endRadians, easedTime)
    elseif self.state == -1 then
      radians = lerp(self.endRadians, self.startRadians, easedTime)
    end
    local fT = 1 - self.easeR(self.remainingTime, 0, 1, self.duration)
    local f = lerp(self.factorStart, self.factorEnd, fT) * radians
    local x = self.centerX + f * math.cos(radians)
    local y = self.centerY + f * math.sin(radians)
    self:SetOffset(x, y)
    if self.remainingTime <= 0 then
      if self.state == -1 and self.onDoneHide then
        self:onDoneHide()
      end
      if self.state == 1 and self.onDoneShow then
        self:onDoneShow()
      end
      self.state = 0
    end
  end
end
return Spiral
