local MenuElementPositionOffsetTransition = {}
local OffsetOptions = {
  duration = 0,
  startX = 0,
  startY = 0,
  endX = 0,
  endY = 0,
  delay = 0,
  delayOnShow = 0,
  delayOnHide = 0
}
local OffsetTickOptions = {
  ease = 0,
  onDoneShow = function(e)
  end,
  onDoneHide = function(e)
  end,
  onUpdate = function(e, dt)
  end
}
function MenuElementPositionOffsetTransition.OnInit(element, options)
  options = options or {}
  local duration = options.duration or 0.33
  local startX = options.startX or 0
  local startY = options.startY or 0
  local endX = options.endX or 0
  local endY = options.endY or 0
  local delay = options.delay or 0
  local delayOnShow = options.delayOnShow or delay
  local delayOnHide = options.delayOnHide or delay
  element("offsetTransitionState"):SetInt(0)
  element("offsetTransitionRemainingTime"):SetFloat(0)
  element("offsetTransitionTotalTime"):SetFloat(duration)
  element("offsetTransitionStartX"):SetFloat(startX)
  element("offsetTransitionEndX"):SetFloat(endX)
  element("offsetTransitionStartY"):SetFloat(startY)
  element("offsetTransitionEndY"):SetFloat(endY)
  element("offsetTransitionDelayRemaining"):SetFloat(0)
  element("offsetTransitionDelayOnShow"):SetFloat(delayOnShow)
  element("offsetTransitionDelayOnHide"):SetFloat(delayOnHide)
end
function MenuElementPositionOffsetTransition.Show(element)
  element("offsetTransitionState"):SetInt(1)
  element("offsetTransitionDelayRemaining"):SetFloat(element("offsetTransitionDelayOnShow"):GetFloat())
  element("offsetTransitionRemainingTime"):SetFloat(element("offsetTransitionTotalTime"):GetFloat())
end
function MenuElementPositionOffsetTransition.Hide(element)
  element("offsetTransitionState"):SetInt(-1)
  element("offsetTransitionDelayRemaining"):SetFloat(element("offsetTransitionDelayOnHide"):GetFloat())
  element("offsetTransitionRemainingTime"):SetFloat(element("offsetTransitionTotalTime"):GetFloat())
end
function MenuElementPositionOffsetTransition.GetTransitionTime(element)
  return element("offsetTransitionRemainingTime"):GetFloat()
end
function MenuElementPositionOffsetTransition.OnTick(element, dt, options)
  dt = math.min(dt, 0.033)
  options = options or {}
  local ease = options.ease or lua_sys.Back_EaseIn
  local transitionTime = element("offsetTransitionRemainingTime"):GetFloat()
  if transitionTime > 0 then
    local delay = element("offsetTransitionDelayRemaining"):GetFloat()
    if delay > 0 then
      delay = math.max(0, delay - dt)
      element("offsetTransitionDelayRemaining"):SetFloat(delay)
      return
    end
    transitionTime = math.max(0, transitionTime - dt)
    element("offsetTransitionRemainingTime"):SetFloat(transitionTime)
    local offsetX = element("xOffset"):GetFloat()
    local offsetY = element("yOffset"):GetFloat()
    local transitionState = element("offsetTransitionState"):GetInt()
    if transitionState == 1 then
      local easedTime = 1 - ease(transitionTime, 0, 1, element("offsetTransitionTotalTime"):GetFloat())
      offsetX = lerp(element("offsetTransitionStartX"):GetFloat(), element("offsetTransitionEndX"):GetFloat(), easedTime)
      offsetY = lerp(element("offsetTransitionStartY"):GetFloat(), element("offsetTransitionEndY"):GetFloat(), easedTime)
    end
    if transitionState == -1 then
      local easedTime = 1 - ease(transitionTime, 0, 1, element("offsetTransitionTotalTime"):GetFloat())
      offsetX = lerp(element("offsetTransitionEndX"):GetFloat(), element("offsetTransitionStartX"):GetFloat(), easedTime)
      offsetY = lerp(element("offsetTransitionEndY"):GetFloat(), element("offsetTransitionStartY"):GetFloat(), easedTime)
    end
    element("xOffset"):SetFloat(offsetX)
    element("yOffset"):SetFloat(offsetY)
    if transitionTime <= 0 then
      if transitionState == -1 and options.onDoneHide then
        options.onDoneHide(element)
      end
      if transitionState == 1 and options.onDoneShow then
        options.onDoneShow(element)
      end
    elseif options.onUpdate then
      options.onUpdate(element, dt)
    end
  end
end
return MenuElementPositionOffsetTransition
