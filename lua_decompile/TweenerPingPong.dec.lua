local TweenerPingPong = {
  currentTime = 0,
  loopTime = 0.25,
  active = true,
  ping = 0,
  ease = lua_sys.Linear_EaseNone,
  onUpdate = function(target, t, tweener)
    target:GetVar("size"):SetFloat(0.6 * game.hudScale() * (1 + t * 0.25))
  end,
  onPing = nil,
  onPong = nil,
  targets = {}
}
function TweenerPingPong:new(obj)
  local obj = obj or {}
  setmetatable(obj, self)
  self.__index = self
  self.targets = {}
  return obj
end
function TweenerPingPong:Reset()
  self.currentTime = 0
  self.ping = 0
end
function TweenerPingPong:Tick(dt)
  if self.active and self.loopTime > 0.033 then
    dt = math.min(dt, 0.033)
    self.currentTime = self.currentTime + dt
    local doPing = false
    local doPong = false
    if self.currentTime >= self.loopTime then
      self.currentTime = self.currentTime - self.loopTime
      self.ping = math.abs(self.ping - 1)
      if self.ping == 1 then
        doPing = true
      else
        doPong = true
      end
    end
    local v = math.abs(self.ping - self.ease(self.currentTime, 0, 1, self.loopTime))
    for i = 1, #self.targets do
      self.onUpdate(self.targets[i], v, self)
    end
    if doPing and self.onPing then
      self:onPing()
    end
    if doPong and self.onPong then
      self:onPong()
    end
  end
end
return TweenerPingPong
