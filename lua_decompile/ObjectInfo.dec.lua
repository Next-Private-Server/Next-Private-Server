local SharedObjectInfo = include("SharedObjectInfo")
local ObjectInfo = SharedObjectInfo:new({
  BlackCover = {
    Sprite = {}
  },
  LikesButton = {
    Label = {},
    Touch = {}
  }
})
function ObjectInfo.BlackCover.Sprite:onInit(element)
  self("topHeight"):SetFloat(1)
  self("bottomHeight"):SetFloat(1)
  self("leftWidth"):SetFloat(1)
  self("rightWidth"):SetFloat(1)
  self("size"):SetFloat(0.5)
  self("includeBorder"):SetInt(1)
  self("spriteName"):SetString("__BUILTIN__WHITE_TEXTURE")
  self:setColor(0, 0, 0)
  self("layer"):SetString("ContextBar")
end
function ObjectInfo.LikesButton.Touch:onTouchUp(element)
  self:super_onTouchUp(element)
  element:parent().currentView = 2
  element:parent():refreshView()
end
function ObjectInfo.LikesButton.Touch:onTouchRelease(element)
  self:super_onTouchRelease(element)
  element:parent().currentView = 2
  element:parent():refreshView()
end
return ObjectInfo
