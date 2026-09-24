local MeebHelper = {}
function MeebHelper:setMeebImage(image)
  self:C("Meeb"):V("spriteName"):SetString(image)
end
function MeebHelper:setText(text)
  self:C("Text"):V("text"):SetString(text)
end
function MeebHelper:setVisible()
  self:setVisibility(1)
end
function MeebHelper:setInvisible()
  self:setVisibility(0)
end
function MeebHelper:setVisibility(show)
  self:C("Meeb"):V("visible"):SetInt(show)
  self:C("Bubble"):V("visible"):SetInt(show)
  self:C("Text"):V("visible"):SetInt(show)
  self:C("BubbleDots"):V("visible"):SetInt(show)
end
return MeebHelper
