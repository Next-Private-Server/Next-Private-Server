local DEFAULT_START_SCALE = 1
local DEFAULT_SCALE_INCREASE = 0.5
local DEFAULT_START_FADE_TIME = 0.9
local DEFAULT_TOTAL_TIME = 1.25
local DEFAULT_TOTAL_Y_MOVEMENT = -160
local MAX_DELTA = 0.033
local CIRCULAR_PRIORITY = 0.1
local CIRCULAR_PRIORITY_OFFSET = 0.01
local currentCircularPriority = CIRCULAR_PRIORITY
local FloatingNumber = {
  x = 0,
  y = 0,
  totalOffset = DEFAULT_TOTAL_Y_MOVEMENT,
  scaleInitial = DEFAULT_START_SCALE,
  scaleIncrease = DEFAULT_SCALE_INCREASE,
  scale = DEFAULT_START_SCALE,
  delay = 1,
  totalTime = DEFAULT_TOTAL_TIME,
  fadeStartTime = DEFAULT_START_FADE_TIME,
  timeSoFar = 0,
  onUpdate = nil,
  onComplete = nil
}
function FloatingNumber:new(obj)
  local obj = obj or {}
  setmetatable(obj, self)
  self.__index = self
  return obj
end
function FloatingNumber:Start()
  self.timeSoFar = 0
  self:Tick(0)
  return self
end
function FloatingNumber:Tick(dt)
  dt = math.min(dt, MAX_DELTA)
  self.timeSoFar = self.timeSoFar + dt
  local activeTime = self.timeSoFar - self.delay
  if activeTime < 0 then
    local currentScale = lua_sys.Back_EaseOut(self.timeSoFar, 0, self.scaleInitial, self.delay)
    local spawnOffsetY = 32 * game.hudScale()
    local currentYOffset = lua_sys.Quadratic_EaseOut(self.timeSoFar, spawnOffsetY, -spawnOffsetY, self.delay)
    if self.onUpdate then
      self:onUpdate(self.x, self.y + currentYOffset, currentScale * self.scale, 1)
    end
    return
  end
  activeTime = math.min(activeTime, self.totalTime)
  local percentage = math.max(0, math.min(activeTime / self.totalTime, 1))
  local currentScale = (self.scaleInitial + self.scaleIncrease * percentage) * self.scale
  local currentY = self.y + self.totalOffset * percentage
  local alpha = 1
  if self.timeSoFar > self.fadeStartTime then
    local fadeTimeSoFar = activeTime - self.fadeStartTime
    alpha = 1 - fadeTimeSoFar / (self.totalTime - self.fadeStartTime)
    alpha = math.max(0, math.min(alpha, 1))
  end
  if self.onUpdate then
    self:onUpdate(self.x, currentY, currentScale, alpha)
  end
  if self:IsDone() and self.onComplete then
    self:onComplete()
  end
end
function FloatingNumber:IsDone()
  return self.timeSoFar - self.delay >= self.totalTime
end
local counter = 0
function FloatingNumber.Create(props)
  props = props or {}
  local parent = props.parent or game.topPopUp()
  local auto = props.auto == nil and true or props.auto
  local function generateName()
    counter = counter + 1
    return "floating_number_" .. counter
  end
  local name = props.name or generateName()
  local text = props.text
  if props.number then
    text = "+" .. game.commaizeNumber(props.number)
  end
  text = text or "+0"
  local fontName = props.fontName or "font_main_MSM"
  local scale = props.scale or 1
  local layer = props.layer or "HUD"
  local delay = props.delay or 1
  local priority = props.priority or currentCircularPriority
  currentCircularPriority = currentCircularPriority - CIRCULAR_PRIORITY_OFFSET
  if currentCircularPriority < 0 then
    currentCircularPriority = currentCircularPriority + CIRCULAR_PRIORITY
  end
  local x = props.x or lua_sys.screenWidth() * 0.5
  local y = props.y or lua_sys.screenHeight() * 0.5
  local element = menu:addTemplateElement("template_text", name, parent)
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
  element:setOrientation(lua_sys.MenuOrientation(x, y, priority, lua_sys.HCENTER, lua_sys.VCENTER))
  element:init()
  element:setPositionBroadcast(true)
  element:postInit()
  local textComponent = element.Text
  textComponent:GetVar("multiline"):SetInt(0)
  textComponent:GetVar("text"):SetString(text)
  textComponent:GetVar("font"):SetString(fontName)
  textComponent:GetVar("layer"):SetString(layer)
  textComponent:GetVar("alpha"):SetFloat(1)
  if props.color then
    textComponent:setColor(props.color.r or 1, props.color.g or 1, props.color.b or 1)
  end
  local floatingNumber = FloatingNumber:new({
    x = x,
    y = y,
    scale = scale,
    delay = delay,
    onUpdate = function(e, curX, curY, curScale, alpha)
      element:GetVar("xOffset"):SetFloat(curX)
      element:GetVar("yOffset"):SetFloat(curY)
      textComponent:GetVar("size"):SetFloat(curScale)
      textComponent:GetVar("alpha"):SetFloat(alpha)
    end,
    onComplete = onCompleteFn
  })
  floatingNumber.element = element
  if auto then
    function floatingNumber.element.onTick(element, dt)
      floatingNumber:Tick(dt)
    end
    floatingNumber.element:setHasOnTick(true)
    floatingNumber:Start()
  end
  return floatingNumber
end
return FloatingNumber
