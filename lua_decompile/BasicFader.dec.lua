local FadeTransition = include("FadeTransition")
local BasicFader = {
  Touch = {},
  Sprite = {}
}
function BasicFader:onInit()
  self:Init()
end
function BasicFader:Init()
  local duration = self.duration or 0.66
  local maxFade = self.maxFade or 0.5
  self.Touch:GetVar("enabled"):SetInt(0)
  self.FadeTransition = FadeTransition:new({
    duration = duration,
    maxFade = maxFade,
    ease = lua_sys.Linear_EaseNone,
    onDoneShow = function()
      if self.onDoneShow then
        self:onDoneShow()
      end
    end,
    onDoneHide = function()
      self.Touch:GetVar("enabled"):SetInt(0)
      if self.onDoneHide then
        self:onDoneHide()
      end
    end,
    onUpdate = function(alpha)
      self:updateAlpha(alpha)
    end
  })
end
function BasicFader:onTick(dt)
  self.FadeTransition:Tick(dt)
end
function BasicFader:updateAlpha(alpha)
  self.Sprite("alpha"):SetFloat(alpha)
end
function BasicFader:Show()
  self.Touch:GetVar("enabled"):SetInt(1)
  self.FadeTransition:Show()
end
function BasicFader:show()
  self:Show()
end
function BasicFader:Hide()
  self.FadeTransition:Hide()
end
function BasicFader:hide()
  self:Hide()
end
return BasicFader
