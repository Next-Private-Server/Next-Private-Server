local template_ClubboxPerfSlider = {
  CategoryIcon = {},
  EditIcon = {},
  VolumeControl = {},
  Alert = {},
  propInd = -1,
  visible = 0
}
function template_ClubboxPerfSlider:onInit()
  self("disabled"):SetInt(0)
end
function template_ClubboxPerfSlider:setVisible()
  self.visible = 1
  self.CategoryIcon:setVisible()
  self.VolumeControl:setVisible()
end
function template_ClubboxPerfSlider:setInvisible()
  self.visible = 0
  self.CategoryIcon:setInvisible()
  self.VolumeControl:setInvisible()
  self.Alert:setInvisible()
end
function template_ClubboxPerfSlider:isUnlocked()
  return self.propInd ~= -1 and game.clubboxPropUnlocked(self.propInd)
end
function template_ClubboxPerfSlider:enable()
  if self:isUnlocked() then
    self("disabled"):SetInt(0)
    if self.visible == 1 then
      self.CategoryIcon.Touch("enabled"):SetInt(1)
    end
  end
end
function template_ClubboxPerfSlider:disable()
  self("disabled"):SetInt(1)
  self.CategoryIcon.Touch("enabled"):SetInt(0)
end
return template_ClubboxPerfSlider
