local TweenerPingPong = include("TweenerPingPong")
local template_alert = {
  Sprite = {}
}
function template_alert:onPostInit()
  local pulseSize = self.Sprite:GetVar("size"):GetFloat()
  self.pulser = TweenerPingPong:new({
    loopTime = 0.5,
    ease = lua_sys.Quadratic_EaseIn,
    onUpdate = function(target, t)
      target:GetVar("size"):SetFloat(pulseSize * (1 + t * 0.25))
    end,
    targets = {
      self.Sprite
    }
  })
end
function template_alert:onTick(dt)
  if self.pulser then
    self.pulser:Tick(dt)
  end
end
return template_alert
