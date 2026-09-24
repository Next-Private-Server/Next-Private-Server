local Pulser = {}
local PulserProto = {
  activate = function(pulse)
    pulse.remainingTime = pulse.duration
  end,
  isActive = function(pulse)
    return pulse.remainingTime > 0
  end,
  tick = function(pulse, dt)
    if pulse.remainingTime > 0 then
      dt = math.min(dt, 0.033)
      pulse.remainingTime = math.max(0, pulse.remainingTime - dt)
      local halfDuration = pulse.duration * 0.5
      local easedTime = halfDuration < pulse.remainingTime and pulse.ease(pulse.duration - pulse.remainingTime, 0, 1, halfDuration) or pulse.ease(pulse.remainingTime, 0, 1, halfDuration)
      local startScale = pulse.initialScale
      local targetScale = pulse.scale
      local scale = lerp(startScale, targetScale, easedTime)
      if pulse.onUpdate then
        pulse.onUpdate(scale)
      end
      if pulse.remainingTime <= 0 and pulse.onDone then
        pulse.onDone()
      end
    end
  end,
  Tick = function(pulse, dt)
    pulse:tick(dt)
  end
}
function Pulser.new(options)
  options = options or {}
  local pulse = {
    remainingTime = 0,
    initialScale = options.initialScale or 1,
    scale = options.scale or 2,
    duration = options.duration or 0.66,
    ease = options.ease or lua_sys.Quadratic_EaseIn,
    onUpdate = options.onUpdate,
    onDone = options.onDone
  }
  setmetatable(pulse, {__index = PulserProto})
  return pulse
end
return Pulser
