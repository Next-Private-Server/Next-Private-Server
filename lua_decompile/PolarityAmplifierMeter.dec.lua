local PolarityAmplifierMeter = {
  FullSprite = {},
  FillSprite = {}
}
function PolarityAmplifierMeter:setFill(percent)
  local fill = self.FillSprite
  percent = lua_sys.clamp(percent, 0, 1)
  if percent == 0 then
    fill:V("visible"):SetInt(0)
  elseif percent == 1 then
    fill:V("visible"):SetInt(0)
    self.FullSprite:V("visible"):SetInt(1)
  else
    fill:V("visible"):SetInt(1)
    local fillImageBufferPercent = 0.07
    local maskPercent = fillImageBufferPercent + (1 - 2 * fillImageBufferPercent) * percent
    local maskWidth = fill("maskWidth"):GetFloat()
    local newMaskWidth = maskWidth * maskPercent
    fill("maskWidth"):SetFloat(newMaskWidth)
  end
end
return PolarityAmplifierMeter
