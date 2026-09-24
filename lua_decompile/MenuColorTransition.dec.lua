local MenuColorTransition = {}
function MenuColorTransition.OnInit(target, options)
  options = options or {}
  local duration = options.duration or 0.33
  local maxFade = options.maxFade or 1
  local delay = options.delay or 0
  local delayOnShow = options.delayOnShow or delay
  local delayOnHide = options.delayOnHide or delay
  local r = target("red"):GetFloat()
  local g = target("green"):GetFloat()
  local b = target("blue"):GetFloat()
  target("startRed"):SetFloat(r)
  target("startGreen"):SetFloat(g)
  target("startBlue"):SetFloat(b)
  target("fadeTransitionTargetR"):SetFloat(0)
  target("fadeTransitionTargetG"):SetFloat(0)
  target("fadeTransitionTargetB"):SetFloat(0)
  target("fadeTransitionRemainingTime"):SetFloat(0)
  target("fadeTransitionTotalTime"):SetFloat(duration)
  target("fadeTransitionMaxFade"):SetFloat(maxFade)
  target("fadeTransitionDelayRemaining"):SetFloat(0)
  target("fadeTransitionDelayOnShow"):SetFloat(delayOnShow)
  target("fadeTransitionDelayOnHide"):SetFloat(delayOnHide)
end
function MenuColorTransition.Show(target)
  target("startRed"):SetFloat(target("red"):GetFloat())
  target("startGreen"):SetFloat(target("green"):GetFloat())
  target("startBlue"):SetFloat(target("blue"):GetFloat())
  target("fadeTransitionTargetR"):SetFloat(target("fadeTransitionMaxFade"):GetFloat())
  target("fadeTransitionTargetG"):SetFloat(target("fadeTransitionMaxFade"):GetFloat())
  target("fadeTransitionTargetB"):SetFloat(target("fadeTransitionMaxFade"):GetFloat())
  target("fadeTransitionRemainingTime"):SetFloat(target("fadeTransitionTotalTime"):GetFloat())
  target("fadeTransitionDelayRemaining"):SetFloat(target("fadeTransitionDelayOnShow"):GetFloat())
end
function MenuColorTransition.Hide(target)
  target("startRed"):SetFloat(target("red"):GetFloat())
  target("startGreen"):SetFloat(target("green"):GetFloat())
  target("startBlue"):SetFloat(target("blue"):GetFloat())
  target("fadeTransitionTargetR"):SetFloat(0)
  target("fadeTransitionTargetG"):SetFloat(0)
  target("fadeTransitionTargetB"):SetFloat(0)
  target("fadeTransitionRemainingTime"):SetFloat(target("fadeTransitionTotalTime"):GetFloat())
  target("fadeTransitionDelayRemaining"):SetFloat(target("fadeTransitionDelayOnHide"):GetFloat())
end
function MenuColorTransition.OnTick(target, dt, options)
  dt = math.min(dt, 0.033)
  options = options or {}
  local ease = options.ease or lua_sys.Quadratic_EaseIn
  local transitionTime = target("fadeTransitionRemainingTime"):GetFloat()
  if transitionTime > 0 then
    local delay = target("fadeTransitionDelayRemaining"):GetFloat()
    if delay > 0 then
      delay = math.max(0, delay - dt)
      target("fadeTransitionDelayRemaining"):SetFloat(delay)
      return
    end
    transitionTime = math.max(0, transitionTime - dt)
    target("fadeTransitionRemainingTime"):SetFloat(transitionTime)
    local easedTime = 1 - ease(transitionTime, 0, 1, target("fadeTransitionTotalTime"):GetFloat())
    local startR = target("startRed"):GetFloat()
    local startG = target("startGreen"):GetFloat()
    local startB = target("startBlue"):GetFloat()
    local targetR = target("fadeTransitionTargetR"):GetFloat()
    local targetG = target("fadeTransitionTargetG"):GetFloat()
    local targetB = target("fadeTransitionTargetB"):GetFloat()
    local r = lerp(startR, targetR, easedTime)
    local g = lerp(startG, targetG, easedTime)
    local b = lerp(startB, targetB, easedTime)
    target("red"):SetFloat(r)
    target("green"):SetFloat(g)
    target("blue"):SetFloat(b)
    if transitionTime <= 0 then
      if targetR == 0 and targetG == 0 and targetB == 0 and options.onDoneHide then
        options.onDoneHide(target)
      elseif targetR > 0 and targetG > 0 and targetB > 0 and options.onDoneShow then
        options.onDoneShow(target)
      end
    elseif options.onUpdate then
      options.onUpdate(target, dt)
    end
  end
end
return MenuColorTransition
