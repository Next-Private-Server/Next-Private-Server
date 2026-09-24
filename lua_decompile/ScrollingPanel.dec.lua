local MenuHelpers = include("MenuHelpers")
local Layouts = include("Layouts")
local ScrollingList = {
  Swiper = {},
  Touch = {}
}
local ScrollMarker = {
  Marker = {},
  Touch = {}
}
local ScrollingPanel = {
  ScrollingList = ScrollingList,
  ScrollBar = {
    Sprite = {}
  },
  ScrollMarker = ScrollMarker
}
function ScrollingList:Init(options)
  options = options or {}
  self.direction = options.direction or lua_sys.MenuSwipeComponent_SwipeDirectionVertical
  self.mode = options.mode or lua_sys.MenuSwipeComponent_SwipeModeFree
  self.tSteps = options.tSteps or 25
  self.spacing = options.spacing or 8 * game.hudScale()
  self.alwaysBounce = options.alwaysBounce or 1
  self.numEntries = 0
  self.totalSize = 0
  self.scrollOffset = 0
  self.updateScrolling = true
  self.layout = options.layout or Layouts.VerticalLayout:new()
end
function ScrollingList:Clear()
  MenuHelpers.ForEachEntry(self, function(entry)
    self:RemoveElement(entry)
  end)
  self.numEntries = 0
  self.totalSize = 0
end
function ScrollingList:CreateEntryName()
  return "entry" .. self.numEntries
end
function ScrollingList:Populate(count, createFunc)
  local function RefreshSwiper()
    if self.Swiper then
      self.Swiper:GetVar("direction"):SetInt(self.direction)
      self.Swiper:GetVar("mode"):SetInt(self.mode)
      self.Swiper:GetVar("tSteps"):SetFloat(self.tSteps)
      self.Swiper:GetVar("mouseScrollSpeed"):SetFloat(self.totalSize / (self.numEntries * 4))
      local viewSize
      if self.direction == lua_sys.MenuSwipeComponent_SwipeDirectionHorizontal then
        viewSize = self:absW()
      else
        viewSize = self:absH()
      end
      self.Swiper:setScrollSize(math.max(0, self.totalSize - viewSize))
      if self.alwaysBounce == 1 then
        self.Swiper:listenToTouches(self)
        self.Touch:GetVar("enabled"):SetInt(1)
      elseif viewSize > self.totalSize then
        self.Swiper:setScrollOffset((viewSize - self.totalSize) * 0.5)
        self.Touch:GetVar("enabled"):SetInt(0)
      else
        self.Swiper:listenToTouches(self)
        self.Touch:GetVar("enabled"):SetInt(1)
      end
    end
  end
  if self.numEntries == 0 then
    self.totalSize = self.spacing
  end
  for i = 0, count - 1 do
    local entry = createFunc(i, self:CreateEntryName())
    if entry then
      entry:init()
      entry:setPositionBroadcast(true)
      entry:postInit()
      self.numEntries = self.numEntries + 1
    end
  end
  if self.layout then
    self.totalSize = self.layout:Apply(self)
  else
    print("no layout!")
  end
  self:setPositionBroadcast(true)
  RefreshSwiper()
end
function ScrollingList:Tick(dt)
  if self.updateScrolling then
    local scrollOffsetX = 0
    local scrollOffsetY = 0
    if self.direction == lua_sys.MenuSwipeComponent_SwipeDirectionHorizontal then
      scrollOffsetX = self.scrollOffset
    else
      scrollOffsetY = self.scrollOffset
    end
    if self.layout then
      self.layout:SetOffset(self, scrollOffsetX, scrollOffsetY)
    end
  end
  if self.Swiper then
    self.scrollOffset = self.Swiper:scrollOffset()
  end
  local clipX = self:absX()
  local clipY = self:absY()
  local clipW = self:absW()
  local clipH = self:absH()
  MenuHelpers.ForEachEntry(self, function(entry)
    entry:setClipping(clipX, clipY, clipW, clipH)
  end)
end
function ScrollingList.Swiper:onInit(element)
  self:GetVar("smoothMode"):SetInt(1)
end
function ScrollingList.Touch:onInit(element)
  self:GetVar("singleTouch"):SetInt(1)
end
function ScrollMarker:onInit()
  self.originalXOffset = self:GetVar("xOffset"):GetInt()
  self.originalYOffset = self:GetVar("yOffset"):GetInt()
end
function ScrollMarker:Init(scrollingList, scrollBar)
  self.scrollingList = scrollingList
  self.scrollBar = scrollBar
  self.scrollOffset = 0
end
function ScrollMarker:onTick(dt)
  local scrollingList = self.scrollingList
  local scrollBar = self.scrollBar
  if scrollingList.direction == lua_sys.MenuSwipeComponent_SwipeDirectionHorizontal then
    local markerMovementWidth = scrollBar:absW() - 2 * self.originalXOffset - self:absW()
    local scrollMarkerXOffset = 0
    local scrollSize = scrollingList.Swiper:GetVar("scrollSize"):GetFloat()
    if scrollSize > 0 then
      scrollMarkerXOffset = -(scrollingList.scrollOffset / scrollSize) * markerMovementWidth
      scrollMarkerXOffset = lua_sys.clamp(scrollMarkerXOffset, 0, markerMovementWidth)
    end
    self:GetVar("xOffset"):SetFloat(self.originalXOffset + scrollMarkerXOffset)
  else
    local markerMovementHeight = scrollBar:absH() - 2 * self.originalYOffset - self:absH()
    local scrollMarkerYOffset = 0
    local scrollSize = scrollingList.Swiper:GetVar("scrollSize"):GetFloat()
    if scrollSize > 0 then
      scrollMarkerYOffset = -(scrollingList.scrollOffset / scrollSize) * markerMovementHeight
      scrollMarkerYOffset = lua_sys.clamp(scrollMarkerYOffset, 0, markerMovementHeight)
    end
    self:GetVar("yOffset"):SetFloat(self.originalYOffset + scrollMarkerYOffset)
  end
end
function ScrollMarker.Touch:onTouchDrag(e, x, y)
  local scrollingList = e.scrollingList
  local scrollBar = e.scrollBar
  if scrollingList and scrollBar then
    if scrollingList.direction == lua_sys.MenuSwipeComponent_SwipeDirectionHorizontal then
      local startOffset = x - scrollBar:absX() - e.originalXOffset
      local scrollSize = scrollingList.totalSize - scrollingList:absW()
      e.scrollOffset = scrollSize * (-(startOffset - e.originalXOffset) / (scrollBar:absW() - 2 * e.originalXOffset - e:absW()))
      e.scrollOffset = lua_sys.clamp(e.scrollOffset, -scrollSize, 0)
      scrollingList.scrollOffset = e.scrollOffset
      scrollingList.Swiper:setScrollOffset(e.scrollOffset)
    else
      local startOffset = y - scrollBar:absY() - e.originalYOffset
      local scrollSize = scrollingList.totalSize - scrollingList:absH()
      e.scrollOffset = scrollSize * (-(startOffset - e.originalYOffset) / (scrollBar:absH() - 2 * e.originalYOffset - e:absH()))
      e.scrollOffset = lua_sys.clamp(e.scrollOffset, -scrollSize, 0)
      scrollingList.scrollOffset = e.scrollOffset
      scrollingList.Swiper:setScrollOffset(e.scrollOffset)
    end
  end
end
function ScrollingPanel:new(obj)
  obj = obj or {}
  setmetatable(obj, self)
  self.__index = self
  return obj
end
function ScrollingPanel:onInit()
  self:Init()
end
function ScrollingPanel:Init(options)
  self.ScrollingList:Init(options)
  self.ScrollMarker:Init(self)
end
function ScrollingPanel:onTick(dt)
  self:Tick(dt)
end
function ScrollingPanel:Tick(dt)
  self.ScrollingList:Tick(dt)
end
function ScrollingPanel:enableScrollBar(enable)
  self.ScrollBar.Sprite:GetVar("visible"):SetInt(enable and 1 or 0)
  self.ScrollMarker.Marker:GetVar("visible"):SetInt(enable and 1 or 0)
  self.ScrollMarker.Touch:GetVar("enabled"):SetInt(enable and 1 or 0)
end
return ScrollingPanel
