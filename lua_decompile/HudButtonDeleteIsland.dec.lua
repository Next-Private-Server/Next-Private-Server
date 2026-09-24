local HudButtonDeleteIsland = {
  Button = {
    Overlay = {},
    Text = {},
    Touch = {}
  }
}
function HudButtonDeleteIsland:SetVisibility(visible)
  if visible then
    self.Button:setVisible()
  else
    self.Button:setInvisible()
  end
  local val = visible and 1 or 0
  self.Button.Overlay("visible"):SetInt(val)
  self.Button.hidden = not visible
  self.hidden = not visible
end
function HudButtonDeleteIsland:onInit()
  self:setSearchChildren(false)
end
function HudButtonDeleteIsland:onPostInit()
  self:setSize(lua_sys.Vector2(self.Button:absW(), self.Button:absH()))
end
function HudButtonDeleteIsland:hide()
  self:SetVisibility(false)
end
function HudButtonDeleteIsland:show()
  self:SetVisibility(true)
end
function HudButtonDeleteIsland:SetClipRect(x, y, w, h)
  self.Button:SetClipRect(x, y, w, h)
  self.Button.Overlay:setClipRect(x, y, w, h)
  self.Button.Touch:setClipRect(x, y, w, h)
end
return HudButtonDeleteIsland
