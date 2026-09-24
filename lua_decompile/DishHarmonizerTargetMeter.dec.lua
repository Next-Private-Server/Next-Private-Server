local Tweener = include("Tweener")
local DishHarmonizerTargetMeter = {
  Frame = {},
  FrameFull = {},
  CenterFull = {},
  Genes = {},
  Fill = {},
  Text = {}
}
function DishHarmonizerTargetMeter:onInit()
  self.fillYOffset = 8 * self:templateVars().scale
  self.Fill:V("yOffset"):SetInt(self.fillYOffset)
  self.Text:V("yOffset"):SetInt(-4 * self:templateVars().scale)
end
function DishHarmonizerTargetMeter:setFill(percent)
  local fill = self.Fill
  percent = lua_sys.clamp(percent, 0, 1)
  self.percent = percent
  self.Text:V("text"):SetString(self:round(percent * 100) .. "%")
  if percent < 1 and percent > 0.9 then
    percent = percent - 0.04
  end
  if percent < 1 and percent > 0.1 then
    percent = percent + 0.04
  end
  percent = lua_sys.clamp(percent, 0, 1)
  fill("maskY"):SetFloat(self:V("fillMaskY"):GetFloat())
  fill("maskHeight"):SetFloat(self:V("fillMaskHeight"):GetFloat())
  local maskHeight = self:V("fillMaskHeight"):GetFloat()
  local newMaskHeight = maskHeight * percent
  local heightDiff = maskHeight - newMaskHeight
  local maskY = self:V("fillMaskY"):GetFloat()
  local newMaskY = maskY + heightDiff
  local sizeY = self:V("fillSizeY"):GetFloat()
  fill("maskY"):SetFloat(newMaskY)
  fill("maskHeight"):SetFloat(newMaskHeight)
  fill("yOffset"):SetFloat(self.fillYOffset - sizeY * (1 - percent))
  if percent == 1 then
    self.FrameFull:V("visible"):SetInt(1)
    self.CenterFull:V("visible"):SetInt(1)
  else
    self.FrameFull:V("visible"):SetInt(0)
    self.CenterFull:V("visible"):SetInt(0)
  end
end
function DishHarmonizerTargetMeter:fillTo(percent, delay, duration)
  self.Fill.FillTween = Tweener:new({
    delay = delay,
    duration = duration,
    initialValue = self.percent,
    targetValue = percent,
    onUpdate = function(value)
      self:setFill(value)
    end,
    onPostDelay = function()
    end
  })
  self.Fill.FillTween:activate()
end
function DishHarmonizerTargetMeter:round(x)
  if not (x >= 0) or not math.floor(x + 0.5) then
  end
  return (math.ceil(x - 0.5))
end
function DishHarmonizerTargetMeter:onTick(dt)
  if self.Fill.FillTween ~= nil then
    self.Fill.FillTween:Tick(dt)
  end
end
function DishHarmonizerTargetMeter:hide()
  self.Frame:V("visible"):SetInt(0)
  self.FrameFull:V("visible"):SetInt(0)
  self.CenterFull:V("visible"):SetInt(0)
  self.Genes:V("visible"):SetInt(0)
  self.Fill:V("visible"):SetInt(0)
  self.Text:V("visible"):SetInt(0)
end
return DishHarmonizerTargetMeter
