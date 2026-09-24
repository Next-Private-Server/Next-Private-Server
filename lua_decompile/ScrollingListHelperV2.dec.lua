local ScrollingListHelperV2 = {
  direction = lua_sys.MenuSwipeComponent_SwipeDirectionHorizontal,
  padding = 16 * game.hudScale(),
  mode = lua_sys.MenuSwipeComponent_SwipeModeFree,
  tSteps = 25,
  spacing = 8 * game.hudScale(),
  alwaysBounce = false,
  listenToEntryTouches = false,
  entries = {},
  contentSize = 0,
  minSize = 0,
  scrollOffset = 0,
  updateScrolling = true,
  centerContents = true
}
function ScrollingListHelperV2:new(obj)
  local obj = obj or {}
  setmetatable(obj, self)
  self.__index = self
  obj:Init()
  return obj
end
function ScrollingListHelperV2:Init()
  if not self.Element then
    print("Must define a Element!")
    return
  end
  if not self.Element.Swiper then
    print("Must define a Swiper Component!")
    return
  end
  if not self.Element.Touch then
    print("Must define a Touch Component!")
    return
  end
  self:Refresh()
end
function ScrollingListHelperV2:Refresh()
  self.offsets = {}
  self.contentSize = self.padding
  for k, v in ipairs(self.entries) do
    if not v.hidden then
      local offset = self.contentSize
      if k > 1 then
        offset = offset + self.spacing
      end
      self.offsets[k] = offset
      if self.direction == lua_sys.MenuSwipeComponent_SwipeDirectionHorizontal then
        offset = offset + v:absW()
        if self.minSize == 0 or v:absW() < self.minSize then
          self.minSize = v:absW()
        end
      else
        offset = offset + v:absH()
        if self.minSize == 0 or v:absH() < self.minSize then
          self.minSize = v:absH()
        end
      end
      if self.listenToEntryTouches then
        self.Element.Swiper:listenToTouches(v)
      end
      self.contentSize = offset
    end
  end
  self.contentSize = self.contentSize + self.padding
  self.Element.Swiper("direction"):SetInt(self.direction)
  self.Element.Swiper("mode"):SetInt(self.mode)
  self.Element.Swiper("tSteps"):SetFloat(self.tSteps)
  self.Element.Swiper("mouseScrollSpeed"):SetFloat((self.minSize + self.padding * 2) / 3 / self.contentSize * 100)
  local viewSize = self:GetViewSize()
  self.Element.Swiper:setScrollSize(math.max(0, self.contentSize - viewSize))
  if self.alwaysBounce then
    self.Element.Swiper:listenToTouches(self.Element)
    self.Element.Touch("enabled"):SetInt(1)
  elseif viewSize > self.contentSize then
    if self.centerContents then
      self.Element.Swiper:setScrollOffset((viewSize - self.contentSize) * 0.5)
    else
      self.Element.Swiper:setScrollOffset(0)
    end
    self.Element.Touch("enabled"):SetInt(0)
  else
    self.Element.Swiper:listenToTouches(self.Element)
    self.Element.Touch("enabled"):SetInt(1)
  end
end
function ScrollingListHelperV2:Tick(dt)
  if self.updateScrolling then
    for k, v in ipairs(self.entries) do
      if not v.hidden then
        local listOffset = self.offsets[k] or 0
        if self.direction == lua_sys.MenuSwipeComponent_SwipeDirectionHorizontal then
          v("xOffset"):SetFloat(self.scrollOffset + listOffset)
        else
          v("yOffset"):SetFloat(self.scrollOffset + listOffset)
        end
      end
    end
  end
  if self.Element and self.Element.Swiper then
    self.scrollOffset = self.Element.Swiper:scrollOffset()
  end
end
function ScrollingListHelperV2:GetCurrentOffset()
  return self.scrollOffset
end
function ScrollingListHelperV2:SetCurrentOffset(offset)
  if self.Element and self.Element.Swiper then
    self.Element.Swiper:setScrollOffset(offset)
  else
    self.scrollOffset = offset
  end
end
function ScrollingListHelperV2:GetContentSize()
  return self.contentSize
end
function ScrollingListHelperV2:GetViewSize()
  if self.Element then
    if self.direction == lua_sys.MenuSwipeComponent_SwipeDirectionHorizontal then
      return self.Element:absW()
    else
      return self.Element:absH()
    end
  end
  return 0
end
function ScrollingListHelperV2:GetScrollSize()
  if self.Element and self.Element.Swiper then
    return self.Element.Swiper:scrollSize()
  end
  return math.max(0, self:GetContentSize() - self:GetViewSize())
end
function ScrollingListHelperV2:RemoveEntry(entry)
  for i = #self.entries, 1, -1 do
    if self.entries[i] == entry then
      table.remove(self.entries, i)
      break
    end
  end
  self:Refresh()
end
return ScrollingListHelperV2
