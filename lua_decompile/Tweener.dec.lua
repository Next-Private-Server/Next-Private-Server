local Tweener = {
  remainingTime = 0,
  remainingDelay = 0,
  delay = 0,
  initialValue = 0,
  targetValue = 1,
  duration = 0.33,
  ease = lua_sys.Quadratic_EaseIn,
  onUpdate = nil,
  onDone = nil,
  onPostDelay = nil,
  value = 0
}
function Tweener:new(obj)
  local obj = obj or {}
  setmetatable(obj, self)
  self.__index = self
  return obj
end
function Tweener:activate()
  self.value = self.initialValue
  self.remainingDelay = self.delay
  self.remainingTime = self.duration
  if self.onUpdate then
    self.onUpdate(self.value)
  end
end
function Tweener:isActive()
  return self.remainingDelay > 0 or 0 < self.remainingTime
end
function Tweener:Tick(dt)
  dt = math.min(dt, 0.033)
  if self.remainingDelay > 0 then
    self.remainingDelay = math.max(0, self.remainingDelay - dt)
    if self.remainingDelay > 0 then
      return
    elseif self.onPostDelay then
      self.onPostDelay()
    end
  end
  if 0 < self.remainingTime then
    self.remainingTime = math.max(0, self.remainingTime - dt)
    local easedTime = 1 - self.ease(self.remainingTime, 0, 1, self.duration)
    local initial = self.initialValue
    local target = self.targetValue
    self.value = lerp(initial, target, easedTime)
    if self.onUpdate then
      self.onUpdate(self.value)
    end
    if 0 >= self.remainingTime and self.onDone then
      self.onDone()
    end
  end
end
Tweener.tick = Tweener.Tick
return Tweener
