local SteppedSlider = {
  Background = {},
  Label = {
    Text = {}
  },
  Slider = {
    Sprite = {},
    Touch = {}
  }
}
local stepData = {
  0.5,
  0.6,
  0.7,
  0.8,
  0.9,
  1,
  1.1,
  1.2
}
local initialStepIndex = 6
function SteppedSlider:onInit()
  self:setSearchChildren(false)
end
function SteppedSlider:getSliderWidth()
  local knobWidth = self.Slider.Sprite:absW()
  local totalSliderWidth = self.Slider:absW() - knobWidth
  return totalSliderWidth
end
function SteppedSlider:setOffsetForIndex(stepIndex)
  if stepIndex < 1 or stepIndex > #self.steps then
    return
  end
  local stepOffset = self:getSliderWidth() / (#self.steps - 1)
  local offset = stepOffset * (stepIndex - 1)
  self.Slider.Sprite("xOffset"):SetInt(offset)
end
function SteppedSlider:onPostInit()
  self.steps = stepData
  self.currentStepIndex = initialStepIndex
  function self.onStepChanged(stepValue)
    self.Label.Text("text"):SetString("UI Scale: " .. tostring(stepValue))
  end
  self:setOffsetForIndex(self.currentStepIndex)
  self.onStepChanged(self.steps[self.currentStepIndex])
  local function snapToClosestStep(localX)
    local stepOffset = self:getSliderWidth() / (#self.steps - 1)
    local closestStepIndex = 1
    local closestDistance = math.huge
    for i = 1, #self.steps do
      local stepPosition = stepOffset * (i - 1)
      local distance = math.abs(localX - stepPosition)
      if closestDistance > distance then
        closestDistance = distance
        closestStepIndex = i
      end
    end
    if closestStepIndex ~= self.currentStepIndex then
      self.currentStepIndex = closestStepIndex
      if self.onStepChanged then
        self.onStepChanged(self.steps[self.currentStepIndex])
      end
    end
    self:setOffsetForIndex(self.currentStepIndex)
  end
  local draggingKnob = false
  function self.Slider.Touch.onTouchDown(component, element, x, y)
    local sliderAbsX = self.Slider:absX()
    local localX = x - sliderAbsX
    local knobWidth = self.Slider.Sprite:absW()
    local knobX = self.Slider.Sprite("xOffset"):GetInt()
    if localX >= knobX and localX <= knobX + knobWidth then
      draggingKnob = true
    else
      draggingKnob = false
      snapToClosestStep(localX)
    end
  end
  function self.Slider.Touch.onTouchDrag(component, element, x, y, dx, dy)
    if not draggingKnob then
      return
    end
    local sliderAbsX = self.Slider:absX()
    local localX = x - sliderAbsX
    snapToClosestStep(localX)
  end
  function self.Slider.Touch.onTouchUp(component, element, x, y)
    draggingKnob = false
  end
  function self.Slider.Touch.onTouchRelease(component, element, x, y)
    draggingKnob = false
  end
end
function SteppedSlider:getStepValue()
  return self.steps[self.currentStepIndex]
end
function SteppedSlider:setStepValue(stepValue)
  local closestStepIndex = 1
  local closestDistance = math.huge
  for i, v in ipairs(self.steps) do
    local distance = math.abs(v - stepValue)
    if closestDistance > distance then
      closestDistance = distance
      closestStepIndex = i
    end
  end
  self.currentStepIndex = closestStepIndex
  self:setOffsetForIndex(self.currentStepIndex)
  if self.onStepChanged then
    self.onStepChanged(self.steps[self.currentStepIndex])
  end
end
return SteppedSlider
