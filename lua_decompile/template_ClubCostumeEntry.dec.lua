local template_ClubCostumeEntry = {variantInd = -1, highlighted = 0}
function template_ClubCostumeEntry:onInit()
  self("disabled"):SetInt(0)
end
function template_ClubCostumeEntry:onPostInit()
  self:disable()
end
function template_ClubCostumeEntry:refresh()
  self.CostumeName:refresh()
  if game.clubboxVariantUnlocked(self:parent().selectedPropInd, self.variantInd) then
    self:enable()
  else
    self:disable()
  end
end
function template_ClubCostumeEntry:setVisible()
  self.CostumeBg:setVisible()
  self.CostumeIcon:setVisible()
  self.CostumeName:setVisible()
end
function template_ClubCostumeEntry:setInvisible()
  self.CostumeBg:setInvisible()
  self.CostumeIcon:setInvisible()
  self.CostumeName:setInvisible()
end
function template_ClubCostumeEntry:highlight()
  self.highlighted = 1
  self.CostumeName:highlight()
end
function template_ClubCostumeEntry:unhighlight()
  self.highlighted = 0
  self.CostumeName:unhighlight()
end
function template_ClubCostumeEntry:enable()
  if self:isUnlocked() then
    self("disabled"):SetInt(0)
    self.CostumeBg:enable()
    self.CostumeIcon:enable()
    self.CostumeName:enable()
    if self.highlighted == 1 then
      self:highlight()
    else
      self:unhighlight()
    end
  end
end
function template_ClubCostumeEntry:disable()
  self("disabled"):SetInt(1)
  self.CostumeBg:disable()
  self.CostumeIcon:disable()
  self.CostumeName:disable()
end
function template_ClubCostumeEntry:isUnlocked()
  return game.clubboxVariantUnlocked(self:parent().selectedPropInd, self.variantInd)
end
return template_ClubCostumeEntry
