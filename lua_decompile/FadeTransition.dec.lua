local FadeTransition = {
  alpha = 0,
  startAlpha = 0,
  targetAlpha = 0,
  remainingTime = 0,
  duration = 0.33,
  minFade = 0,
  maxFade = 1,
  delayRemaining = 0,
  delayOnShow = 0,
  delayOnHide = 0,
  ease = lua_sys.Quadratic_EaseIn,
  onDoneShow = nil,
  onDoneHide = nil,
  onUpdate = nil
}
function FadeTransition:new(obj)
  local obj = obj or {}
  setmetatable(obj, self)
  self.__index = self
  return obj
end
function FadeTransition:Show()
  self.startAlpha = self.alpha
  self.targetAlpha = self.maxFade
  self.remainingTime = self.duration
  self.delayRemaining = self.delayOnShow
end
function FadeTransition:Hide()
  self.startAlpha = self.alpha
  self.targetAlpha = self.minFade
  self.remainingTime = self.duration
  self.delayRemaining = self.delayOnHide
end
function FadeTransition:Cancel()
  self.remainingTime = 0
end
function FadeTransition:GetTransitionTime()
  return self.remainingTime
end
function FadeTransition:SetAlpha(alpha)
  self.alpha = alpha
  if self.onUpdate then
    self.onUpdate(alpha, self)
  end
end
function FadeTransition:Tick(dt)
  dt = math.min(dt, 0.033)
  if self.remainingTime > 0 then
    if 0 < self.delayRemaining then
      self.delayRemaining = math.max(0, self.delayRemaining - dt)
      return
    end
    self.remainingTime = math.max(0, self.remainingTime - dt)
    local easedTime = 1 - self.ease(self.remainingTime, 0, 1, self.duration)
    self:SetAlpha(lerp(self.startAlpha, self.targetAlpha, easedTime))
    if self.remainingTime <= 0 then
      if self.targetAlpha == 0 and self.onDoneHide then
        self:onDoneHide()
      elseif 0 < self.targetAlpha and self.onDoneShow then
        self:onDoneShow()
      end
    end
  end
end
return FadeTransition
