local ElementTools = include("ElementTools")
local ElementFader = {
  autoTick = false,
  duration = 0.33,
  maxFade = 1,
  delayOnShow = 0,
  delayOnHide = 0,
  startVisible = false,
  ease = lua_sys.Quadratic_EaseIn,
  onDone = function(fader, showing)
  end,
  onUpdate = function(alpha, dt, fader)
  end,
  onUpdateComponent = function(component, alpha, fader)
  end
}
ElementFader.__index = ElementFader
function ElementFader.New(element, options)
  if options == nil then
    options = {}
  end
  local elementFader = setmetatable(options, ElementFader)
  elementFader:Init(element)
  return elementFader
end
function ElementFader:Init(element)
  self.root = element
  if self.autoTick then
    function element.ElementFaderUpdate(e, msgUpdate)
      self:tick(msgUpdate.time)
    end
    element:SetupGenericListener(game.engineReceiver(), "sys::msg::MsgUpdate", "ElementFaderUpdate")
  end
  local oldOnDestroy = self.root.onDestroy
  function self.root.onDestroy(e)
    self.components = {}
    if oldOnDestroy then
      oldOnDestroy(e)
    end
  end
  self.fadeTransitionStartAlpha = 0
  self.fadeTransitionStartAlpha = 0
  self.fadeTransitionTargetAlpha = 0
  self.fadeTransitionRemainingTime = 0
  self.fadeTransitionDelayRemaining = 0
  self.currentAlpha = 0
  if self.startVisible then
    self.currentAlpha = 1
  end
  self.components = ElementTools.FindAllComponents(element, function(component)
    return component:HasVar("alpha") and not component.ignoreFade and component:V("alpha"):GetFloat() ~= self.currentAlpha
  end, true)
  self:SetAlpha(self.currentAlpha)
end
function ElementFader:Show(instant)
  if instant or self.duration <= 0 then
    self:Stop(false)
    self:SetAlpha(self.maxFade)
    if self.onDone then
      self.onDone(self, true)
    end
  else
    self.fadeTransitionStartAlpha = self.currentAlpha
    self.fadeTransitionTargetAlpha = self.maxFade
    self.fadeTransitionRemainingTime = self.duration
    self.fadeTransitionDelayRemaining = self.delayOnShow
    self:SetAlpha(self.currentAlpha)
  end
end
function ElementFader:Hide(instant)
  if instant or self.duration <= 0 then
    self:Stop(false)
    self:SetAlpha(0)
    if self.onDone then
      self.onDone(self, false)
    end
  else
    self.fadeTransitionStartAlpha = self.currentAlpha
    self.fadeTransitionTargetAlpha = 0
    self.fadeTransitionRemainingTime = self.duration
    self.fadeTransitionDelayRemaining = self.delayOnHide
    self:SetAlpha(self.currentAlpha)
  end
end
function ElementFader:GetTransitionTime()
  return self.fadeTransitionRemainingTime
end
function ElementFader:SetAlpha(value)
  self.currentAlpha = value
  for _, component in ipairs(self.components) do
    local maxFade = component.maxFade or 1
    component:V("alpha"):SetFloat(value * maxFade)
  end
  if self.onUpdateComponent then
    for _, component in ipairs(self.components) do
      self.onUpdateComponent(component, value, self)
    end
  end
end
function ElementFader:Stop(finish)
  self.fadeTransitionRemainingTime = 0
  if finish then
    self:SetAlpha(self.fadeTransitionTargetAlpha)
  end
end
function ElementFader:tick(dt)
  dt = math.min(dt, 0.033)
  local ease = self.ease
  local transitionTime = self.fadeTransitionRemainingTime
  if transitionTime > 0 then
    local delay = self.fadeTransitionDelayRemaining
    if delay > 0 then
      delay = math.max(0, delay - dt)
      self.fadeTransitionDelayRemaining = delay
      self:SetAlpha(self.currentAlpha)
      return
    end
    transitionTime = math.max(0, transitionTime - dt)
    self.fadeTransitionRemainingTime = transitionTime
    local easedTime = 1 - ease(transitionTime, 0, 1, self.duration)
    local alpha = lerp(self.fadeTransitionStartAlpha, self.fadeTransitionTargetAlpha, easedTime)
    self:SetAlpha(alpha)
    if self.onUpdate then
      self.onUpdate(alpha, dt, self)
    end
    if transitionTime <= 0 and self.onDone then
      self.onDone(self, self.fadeTransitionTargetAlpha ~= 0)
    end
  end
end
return ElementFader
