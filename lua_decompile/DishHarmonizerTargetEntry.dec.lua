local DishHarmonizerTargetEntry = {
  Sprite = {},
  SelectedSprite = {},
  Touch = {}
}
function DishHarmonizerTargetEntry:onInit()
  self.isSelected = false
end
function DishHarmonizerTargetEntry:onPostInit()
end
function DishHarmonizerTargetEntry:grey()
  self.Sprite:setColor(0.5, 0.5, 0.5)
  self.SelectedSprite:setColor(0.5, 0.5, 0.5)
end
function DishHarmonizerTargetEntry:unGrey()
  self.Sprite:setColor(1, 1, 1)
  self.SelectedSprite:setColor(1, 1, 1)
end
function DishHarmonizerTargetEntry:select()
  self.SelectedSprite:V("visible"):SetInt(1)
  self.isSelected = true
end
function DishHarmonizerTargetEntry:unSelect()
  self.SelectedSprite:V("visible"):SetInt(0)
  self.isSelected = false
end
return DishHarmonizerTargetEntry
