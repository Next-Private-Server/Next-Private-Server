local BoxInventoryEvolutionProgressEntry = {
  Sprite = {},
  ToolTip = {
    Text = {}
  },
  Checkmark = {
    Sprite = {}
  }
}
function BoxInventoryEvolutionProgressEntry:onInit()
  self.isCompleted = false
  self.isDisabled = false
end
function BoxInventoryEvolutionProgressEntry:setCompleted()
  self.isCompleted = true
  self.Checkmark.Sprite:GetVar("visible"):SetInt(1)
  self.Sprite:setColor(1, 1, 1)
  self.ToolTip.Text:GetVar("text"):SetString("TOOLTIP_GOLD_EPIC_WUBBOX_POWERUP01")
end
function BoxInventoryEvolutionProgressEntry:setCurrent()
  self.ToolTip.Text:GetVar("text"):SetString("TOOLTIP_GOLD_EPIC_WUBBOX_POWERUP02")
end
function BoxInventoryEvolutionProgressEntry:setDisabled()
  self.isDisabled = true
  self.Checkmark.Sprite:GetVar("visible"):SetInt(0)
  self.Sprite:setColor(0.5, 0.5, 0.5)
  self.ToolTip.Text:GetVar("text"):SetString("TOOLTIP_GOLD_EPIC_WUBBOX_POWERUP03")
end
return BoxInventoryEvolutionProgressEntry
