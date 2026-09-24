local OffsetTransition = include("OffsetTransition")
local BasicPanel = {}
function BasicPanel:onInit()
  self:Init()
end
function BasicPanel:Init()
  if not self.OffsetTransition then
    self.OffsetTransition = OffsetTransition:new({
      startX = self.startX or 0,
      startY = self.startY or 0,
      endX = self.endX or 0,
      endY = self.endY or 6 * game.hudScale(),
      duration = self.duration or 0.66,
      ease = lua_sys.Quadratic_EaseIn,
      onUpdate = function(x, y)
        self:GetVar("xOffset"):SetFloat(x)
        self:GetVar("yOffset"):SetFloat(y)
      end,
      onDoneShow = function()
        if self.onDoneShow then
          self:onDoneShow()
        end
      end,
      onDoneHide = function()
        if self.onDoneHide then
          self:onDoneHide()
        end
      end
    })
  end
end
function BasicPanel:onTick(dt)
  self.OffsetTransition:Tick(dt)
end
function BasicPanel:Show()
  self.OffsetTransition:Show()
end
function BasicPanel:Hide()
  self.OffsetTransition:Hide()
end
return BasicPanel
