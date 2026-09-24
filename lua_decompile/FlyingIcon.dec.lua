local TOTAL_TIME_SECS = 0.6
local FADE_PERCENT = 0.1
local MAX_DELTA = 0.033
local FADE_IN_THRESHOLD = 0.1
local FADE_OUT_THRESHOLD = 0.9
local FlyingIcon = {
  srcX = 0,
  srcY = 0,
  destX = 0,
  destY = 0,
  controlX = 0,
  controlY = 0,
  totalTime = TOTAL_TIME_SECS,
  timeToFade = TOTAL_TIME_SECS * FADE_PERCENT,
  remainingTime = 0,
  ease = lua_sys.Cubic_EaseInOut,
  onUpdate = nil,
  onComplete = nil,
  delayOnStart = 0,
  remainingDelayTime = 0,
  doJitter = true
}
function FlyingIcon:new(obj)
  local obj = obj or {}
  setmetatable(obj, self)
  self.__index = self
  return obj
end
function FlyingIcon:CalculateControlPoints()
  local dx = self.destX - self.srcX
  local dy = self.destY - self.srcY
  local distance = math.sqrt(dx * dx + dy * dy)
  local curveHeight = math.min(100, distance / 2)
  self.controlX = (self.srcX + self.destX) / 2
  self.controlY = self.srcY < self.destY and self.srcY - curveHeight or self.destY - curveHeight
end
function FlyingIcon:Start()
  self:CalculateControlPoints()
  self.remainingDelayTime = self.delayOnStart
  self.remainingTime = self.totalTime
  self:Tick(0)
  return self
end
function FlyingIcon:CalculatePosition(t)
  local oneMinusT = 1 - t
  local oneMinusT2 = oneMinusT * oneMinusT
  local t2 = t * t
  return oneMinusT2 * self.srcX + 2 * oneMinusT * t * self.controlX + t2 * self.destX, oneMinusT2 * self.srcY + 2 * oneMinusT * t * self.controlY + t2 * self.destY
end
function FlyingIcon:CalculateAlpha(progress)
  if progress < FADE_IN_THRESHOLD and self.delayOnStart == 0 then
    return self.ease(progress * self.totalTime, 0, 1, self.timeToFade)
  elseif progress > FADE_OUT_THRESHOLD then
    local fadeProgress = (progress - FADE_OUT_THRESHOLD) * 10 * self.timeToFade
    return self.ease(fadeProgress, 1, -1, self.timeToFade)
  end
  return 1
end
local makeJitter = function(radius, minFreq, maxFreq)
  minFreq = minFreq or 2
  maxFreq = (maxFreq or 4) - minFreq
  local phaseX = math.random() * math.pi * 2
  local phaseY = math.random() * math.pi * 2
  local freqX = minFreq + math.random() * maxFreq
  local freqY = minFreq + math.random() * maxFreq
  return function(t)
    local x = math.sin(t * freqX + phaseX) * radius
    local y = math.sin(t * freqY + phaseY) * radius
    return x, y
  end
end
function FlyingIcon:Tick(dt)
  dt = math.min(dt, MAX_DELTA)
  if self.delayOnStart > 0 and 0 < self.remainingDelayTime then
    self.remainingDelayTime = self.remainingDelayTime - dt
    if self.doJitter then
      if not self.jitter then
        self.jitter = makeJitter(8)
      end
      local jitterX, jitterY = self.jitter(self.delayOnStart - self.remainingDelayTime)
      local alpha = self.ease(self.remainingDelayTime, 0, 1, self.timeToFade)
      if self.onUpdate then
        self:onUpdate(self.srcX + jitterX, self.srcY + jitterY, alpha, 0)
      end
      if 0 >= self.remainingDelayTime then
        self.srcX = self.srcX + jitterX
        self.srcY = self.srcY + jitterY
      end
    else
      local alpha = self.ease(self.remainingDelayTime, 0, 1, self.timeToFade)
      if self.onUpdate then
        self:onUpdate(self.srcX, self.srcY, alpha, 0)
      end
    end
    return
  end
  if self:IsDone() then
    return
  end
  self.remainingTime = math.max(self.remainingTime - dt, 0)
  local progress = 1 - self.remainingTime / self.totalTime
  local newX, newY = self:CalculatePosition(progress)
  local newAlpha = self:CalculateAlpha(progress)
  if self.onUpdate then
    self:onUpdate(newX, newY, newAlpha, progress)
  end
  if self:IsDone() and self.onComplete then
    self:onComplete()
  end
end
function FlyingIcon:IsDone()
  return self.remainingTime <= 0
end
local counter = 0
function FlyingIcon.Create(props)
  props = props or {}
  local parent = props.parent or game.topPopUp()
  local auto = props.auto == nil and true or props.auto
  local function generateName()
    counter = counter + 1
    return "flying_icon_" .. counter
  end
  local name = props.name or generateName()
  local spriteName = props.spriteName or "food"
  local sheetName = props.sheetName or "xml_resources/hud01.xml"
  local size = props.size or 0.5 * game.hudScale()
  local layer = props.layer or "HUD"
  local priority = props.priority or 0
  local delayOnStart = props.delayOnStart or 0
  local srcX = props.srcX or lua_sys.screenWidth() * 0.5
  local srcY = props.srcY or lua_sys.screenHeight() * 0.5
  local destX = props.destX or lua_sys.screenWidth() - 32 * game.hudScale()
  local destY = props.destY or 32 * game.hudScale()
  local element = menu:addTemplateElement("template_spritesheet", name, parent)
  if props.parent then
    element:relativeTo(parent)
    element:setRelativeObjectAnchors(lua_sys.LEFT, lua_sys.TOP)
  end
  local onCompleteFn = props.onComplete
  if auto then
    function onCompleteFn(e)
      if props.onComplete then
        props.onComplete(e)
      end
      menu:RemoveElement(element)
    end
  end
  element:setOrientation(lua_sys.MenuOrientation(0, 0, priority, lua_sys.HCENTER, lua_sys.VCENTER))
  element:init()
  element:setPositionBroadcast(true)
  element.Sprite:GetVar("spriteName"):SetString(spriteName)
  element.Sprite:GetVar("sheetName"):SetString(sheetName)
  element.Sprite:GetVar("size"):SetFloat(size)
  element.Sprite:GetVar("layer"):SetString(layer)
  element.Sprite:GetVar("alpha"):SetFloat(0)
  local startSize = size
  local function onUpdateFn(fi, x, y, a, progress)
    element:GetVar("xOffset"):SetFloat(x)
    element:GetVar("yOffset"):SetFloat(y)
    element.Sprite:GetVar("alpha"):SetFloat(a)
    local newSize = lua_sys.Quadratic_EaseOut(progress, startSize, -startSize * 0.25, 1)
    element.Sprite:GetVar("size"):SetFloat(newSize)
  end
  local flyingIcon = FlyingIcon:new({
    srcX = srcX,
    srcY = srcY,
    destX = destX,
    destY = destY,
    delayOnStart = delayOnStart,
    onUpdate = props.onUpdate or onUpdateFn,
    onComplete = onCompleteFn
  })
  flyingIcon.element = element
  if auto then
    function flyingIcon.element.onTick(element, dt)
      flyingIcon:Tick(dt)
    end
    flyingIcon.element:setHasOnTick(true)
    flyingIcon:Start()
  end
  return flyingIcon
end
return FlyingIcon
