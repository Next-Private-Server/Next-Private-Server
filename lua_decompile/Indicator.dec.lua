local Indicator = {
  Sprite = {}
}
local transitionState = 1
local transitionTime = 1
function Indicator:onTick(dt)
  if transitionState ~= 0 and dt <= 0.5 then
    self.Sprite:V("size"):SetFloat(0.6 * game.hudScale() * transitionTime)
    if transitionTime <= 1 then
      transitionState = 1
    elseif transitionTime >= 1.25 then
      transitionState = 2
    end
    if transitionState == 1 then
      transitionTime = transitionTime + dt
    else
      transitionTime = transitionTime - dt
    end
  end
end
function Indicator:Show()
  transitionState = 1
  self.Sprite("visible"):SetInt(1)
end
function Indicator:Hide()
  transitionState = 0
  self.Sprite("visible"):SetInt(0)
end
function Indicator:SetEnabled()
  self.Sprite:setColor(1, 1, 1)
end
function Indicator:SetDisabled()
  self.Sprite:setColor(0.5, 0.5, 0.5)
end
function Indicator:SetAlpha(alpha)
  self.Sprite:V("alpha"):SetFloat(alpha)
end
return Indicator
