local CritterSynthesizingEntry = {
  Bg = {},
  Sprite = {},
  Touch = {},
  Text = {}
}
function CritterSynthesizingEntry:onInit()
  self.disabled = false
  self.touchDisabled = false
  self.isShowingNum = false
end
function CritterSynthesizingEntry:showNum()
  self.isShowingNum = true
  self.Text:V("visible"):SetInt(1)
  self.Text:V("text"):SetString(tostring(self.num))
end
function CritterSynthesizingEntry:setInvisible()
  self.Bg:V("visible"):SetInt(0)
  self.Sprite:V("visible"):SetInt(0)
  self.Text:V("visible"):SetInt(0)
end
function CritterSynthesizingEntry:setVisible()
  self.Bg:V("visible"):SetInt(1)
  self.Sprite:V("visible"):SetInt(1)
  if self.isShowingNum then
    self.Text:V("visible"):SetInt(1)
  end
end
function CritterSynthesizingEntry:disable()
  self.disabled = true
end
return CritterSynthesizingEntry
