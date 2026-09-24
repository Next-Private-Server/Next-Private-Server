local template_ClubboxActEntry = {
  Spotlight = {},
  Poster = {},
  Touch = {},
  index = -1,
  actId = 0
}
function template_ClubboxActEntry:refresh()
  self.Poster:refresh(self)
end
function template_ClubboxActEntry:setVisible()
  self.Poster:setVisible(self)
  self:refresh()
end
function template_ClubboxActEntry:setInvisible()
  self.Spotlight:setInvisible()
  self.Poster:setInvisible(self)
  self.Touch:disable(self)
end
function template_ClubboxActEntry:disable()
  self.Poster:disable(self)
  self.Touch:disable(self)
end
function template_ClubboxActEntry:enable()
  self.Poster:enable(self)
  self.Touch:enable(self)
end
function template_ClubboxActEntry:showAsSelected()
  self.Spotlight:setVisible(self)
  local scale = self.currentScale or 1
  if scale ~= 1 then
    self.Poster("size"):SetFloat(self.Poster("originalSize"):GetFloat())
  end
end
function template_ClubboxActEntry:showAsDeselected()
  self.Spotlight:setInvisible(self)
  local scale = self.currentScale or 1
  if scale ~= 1 then
    self.Poster("size"):SetFloat(self.Poster("originalSize"):GetFloat() * 0.75)
  end
end
function template_ClubboxActEntry.Touch:onTouchDown(element)
end
function template_ClubboxActEntry.Touch:onTouchUp(element)
  if element.actId ~= 0 then
    element:parent().selectedIndex = element.index - 1
    element:parent():refreshSelection()
  end
end
function template_ClubboxActEntry.Touch:onTouchRelease(element)
end
function template_ClubboxActEntry:SetAct(actId)
  self.actId = actId
  self:refresh()
end
function template_ClubboxActEntry:SetScale(scale)
  self.currentScale = scale
  self.Poster("size"):SetFloat(self:templateVars().spriteScale * self.currentScale)
  local spotlightBaseScale = 0.7 * (screenHeight() / 320)
  self.Spotlight("size"):SetFloat(spotlightBaseScale * self.currentScale)
end
return template_ClubboxActEntry
