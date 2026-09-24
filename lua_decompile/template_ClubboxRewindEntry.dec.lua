local template_ClubboxRewindEntry = {
  Poster = {},
  Touch = {},
  index = -1,
  actId = 0
}
function template_ClubboxRewindEntry:setVisible()
  self.Poster("visible"):SetInt(0)
end
function template_ClubboxRewindEntry:setInvisible()
  self.Poster("visible"):SetInt(0)
  self.Touch:component("enabled"):SetInt(0)
end
function template_ClubboxRewindEntry:disable()
  self.Poster:setColor(0.5, 0.5, 0.5)
end
function template_ClubboxRewindEntry:enable()
  self.Poster:setColor(1, 1, 1)
end
function template_ClubboxRewindEntry.Touch:onTouchDown(element)
end
function template_ClubboxRewindEntry.Touch:onTouchUp(element)
  if element.actId > 0 then
    element:parent().selectedIndex = element.index - 1
    element:parent():refreshSelection()
  end
end
function template_ClubboxRewindEntry.Touch:onTouchRelease(element)
end
function template_ClubboxRewindEntry:SetAct(actId)
  self.actId = actId
  local sheet = game.getClubboxActPosterSheet(self.actId)
  local sprite = game.getClubboxActPosterIcon(self.actId)
  print("SetAct", sheet, sprite)
  local animUtil = game.AnimUtil(self.Poster)
  animUtil:addRemap("poster", sheet, sprite)
  animUtil:resetAnim()
end
function template_ClubboxRewindEntry:SetScale(scale)
  scale = scale * self:templateVars().scale
  self.Poster:setScale(Vector2(scale, scale))
end
return template_ClubboxRewindEntry
