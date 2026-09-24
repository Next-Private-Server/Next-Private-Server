local FadeTransition = include("FadeTransition")
local Coroutines = include("Coroutines")
local Tooltip = {
  Sprite = {},
  Text = {},
  duration = 0.67
}
function Tooltip:onInit()
  self.FadeTransition = FadeTransition:new({
    duration = 0.33,
    ease = lua_sys.Linear_EaseNone,
    onDoneShow = function()
      self.isDoneShow = true
    end,
    onDoneHide = function()
      self.isDoneHide = true
    end,
    onUpdate = function(alpha)
      self:UpdateAlpha(alpha)
    end
  })
  self.FadeTransition:SetAlpha(0)
end
function Tooltip:onDestroy()
  KillCoroutine(self.showCo)
  self.showCo = nil
  KillCoroutine(self.hideCo)
  self.hideCo = nil
  KillCoroutine(self.doneShow)
  self.doneShow = nil
  KillCoroutine(self.doneHide)
  self.doneHide = nil
end
local ShowCo = function(tooltip)
  tooltip.isDoneShow = false
  while not tooltip.isDoneShow do
    KillCoroutine(tooltip.doneShow)
    tooltip.doneShow = coroutine.yield({
      game.engineReceiver(),
      game.M_MsgUpdate_GetMsgTypeId(),
      function(m)
        tooltip.FadeTransition:Tick(m.time)
        return true
      end
    })
  end
  tooltip.showCo = nil
  if tooltip.onDoneShow then
    tooltip:onDoneShow()
  end
end
function Tooltip:Show()
  self.FadeTransition:Show()
  KillCoroutine(self.doneHide)
  self.doneHide = nil
  KillCoroutine(self.hideCo)
  self.hideCo = nil
  KillCoroutine(self.doneShow)
  self.doneShow = nil
  KillCoroutine(self.showCo)
  self.showCo = RunIndyCoroutine(ShowCo, self)
end
local function HideCo(tooltip)
  Coroutines.WaitForSeconds(tooltip.duration)
  KillCoroutine(tooltip.showCo)
  tooltip.showCo = nil
  KillCoroutine(tooltip.doneShow)
  tooltip.doneShow = nil
  tooltip.FadeTransition:Hide()
  tooltip.isDoneHide = false
  while not tooltip.isDoneHide do
    KillCoroutine(tooltip.doneHide)
    tooltip.doneHide = coroutine.yield({
      game.engineReceiver(),
      game.M_MsgUpdate_GetMsgTypeId(),
      function(m)
        tooltip.FadeTransition:Tick(m.time)
        return true
      end
    })
  end
  tooltip.hideCo = nil
  if tooltip.onDoneHide then
    tooltip:onDoneHide()
  end
end
function Tooltip:Hide()
  KillCoroutine(self.hideCo)
  self.hideCo = RunIndyCoroutine(HideCo, self)
end
function Tooltip:UpdateAlpha(alpha)
  self.Sprite:GetVar("alpha"):SetFloat(math.min(0.9, alpha))
  self.Text:GetVar("alpha"):SetFloat(alpha)
end
function Tooltip:IsShowing()
  return self.showCo ~= nil or self.hideCo ~= nil
end
function Tooltip:onTick(dt)
  local x = self:absX()
  local y = self:absY()
  local w = self:absW()
  local h = self:absH()
  local xOffset = 0
  local yOffset = 0
  local extraOffset = 16 * game.hudScale()
  local sX = lua_sys.deviceMarginX() + extraOffset
  local sY = lua_sys.deviceMarginY() + extraOffset
  local sX2 = lua_sys.screenWidth() - lua_sys.deviceMarginX() - extraOffset
  local sY2 = lua_sys.screenHeight() - lua_sys.deviceMarginY() - extraOffset
  if x < sX then
    xOffset = sX - x
  end
  if y < sY then
    yOffset = sY - y
  end
  if sX2 < x + w then
    xOffset = sX2 - (x + w)
  end
  if sY2 < y + h then
    yOffset = sY2 - (y + h)
  end
  self:setPosition(lua_sys.Vector2(x + xOffset, y + yOffset))
end
return Tooltip
