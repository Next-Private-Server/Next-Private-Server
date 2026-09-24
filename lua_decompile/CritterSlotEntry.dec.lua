local CritterSlotEntry = {
  Bg = {},
  Sprite = {},
  Touch = {},
  Text = {}
}
function CritterSlotEntry:onInit()
  self.disabled = false
  self.touchDisabled = false
  self.textR = 1
  self.textG = 1
  self.textB = 1
end
function CritterSlotEntry:update()
  self.Sprite:V("visible"):SetInt(1)
  if self.gene == "" then
    if self.selectionDisabled then
      self.Bg:V("spriteName"):SetString("critter_portrait_square_empty")
      self.Sprite:V("visible"):SetInt(0)
    else
      self.Bg:V("spriteName"):SetString("portrait_square")
      self.Sprite:V("spriteName"):SetString("critter_portrait_square_plus")
    end
    self.Text:V("text"):SetString("")
  else
    if self.selectionDisabled then
      self.Bg:V("spriteName"):SetString("portrait_square_tinted")
    else
      self.Bg:V("spriteName"):SetString("portrait_square")
    end
    self.Sprite:V("spriteName"):SetString(game.critterSprite(self.gene))
    if self.num ~= nil and self.required ~= nil then
      if self.num < self.required then
        self.textG = 0
        self.textB = 0
      else
        self.textG = 1
        self.textB = 1
      end
      self.Text:setColor(self.textR, self.textG, self.textB)
      local text = self.num .. "/" .. self.required
      self.Text:V("text"):SetString(text)
    end
  end
end
function CritterSlotEntry:disableSelection()
  self.selectionDisabled = true
  self:update()
end
function CritterSlotEntry:enableSelection()
  self.selectionDisabled = false
  self:update()
end
function CritterSlotEntry:disableTouch()
  self.touchDisabled = true
end
function CritterSlotEntry:enableTouch()
  self.touchDisabled = false
end
return CritterSlotEntry
