local Tweener = include("Tweener")
local MenuHelpers = include("MenuHelpers")
local ScrollingListHelper = include("ScrollingListHelper")
local function getEntryFromId(element, islandId)
  local targetEntry
  MenuHelpers.ForEachEntry(element, function(entry)
    if entry.islandId == islandId then
      targetEntry = entry
    end
  end)
  return targetEntry
end
local MENU_HORIZONTAL = 0
local MENU_VERTICAL = 1
local DragAndDropListHelper = {
  element = {},
  swiper = {},
  direction = MENU_HORIZONTAL,
  enabled = false,
  dragVelocity = {1, 12.5},
  idToIndex = {},
  indexToId = {},
  originalOrder = {},
  tickables = {},
  mappingSize = 0,
  draggedRelease = false,
  snapPos = 0,
  mousePos = 0,
  entryRelPos = 0,
  sVelocity = 0,
  draggedEntry = nil,
  prevDraggedEntry = nil,
  nextDraggedEntry = nil,
  prevDraggedId = -1,
  nextDraggedId = -1,
  draggedId = -1,
  dirty = false,
  onDirtyChanged = nil,
  onEntrySwapped = nil
}
function DragAndDropListHelper:new(obj)
  local obj = obj or {}
  obj.idToIndex = {}
  obj.indexToId = {}
  obj.originalOrder = {}
  obj.tickables = {}
  setmetatable(obj, self)
  self.__index = self
  return obj
end
function DragAndDropListHelper:Tick(dt)
  for _, v in pairs(self.tickables) do
    v:Tick(dt)
  end
  if not self.enabled then
    return
  end
  local offset = 0
  if self.swiper then
    self:updateSwiper()
    offset = -self.swiper:scrollOffset()
  end
  if self.draggedEntry then
    self.draggedEntry("listOffset"):SetFloat(offset + self.mousePos - self.entryRelPos)
    if self:canSwapPrevEntry() then
      self:swapPrevEntry()
    end
    if self:canSwapNextEntry() then
      self:swapNextEntry()
    end
  end
end
function DragAndDropListHelper:AddEntry(index, id)
  self.indexToId[index + 1] = id
  self.idToIndex[id] = index + 1
  self.mappingSize = self.mappingSize + 1
end
function DragAndDropListHelper:DeleteEntry(id)
  local indexToDelete = self.idToIndex[id]
  table.remove(self.indexToId, indexToDelete)
  table.remove(self.idToIndex, id)
  for i = indexToDelete + 1, self.mappingSize do
    local entryId = self.indexToId[i]
    self.indexToId[i - 1] = entryId
    self.idToIndex[entryId] = i - 1
  end
  self.mappingSize = self.mappingSize - 1
end
function DragAndDropListHelper:ResetOriginalOrder()
  self.originalOrder = {}
  for i, v in pairs(self.idToIndex) do
    self.originalOrder[i] = v
  end
  if self.dirty then
    self.dirty = false
    if self.onDirtyChanged then
      self.onDirtyChanged(self.dirty)
    end
  end
end
function DragAndDropListHelper:IsDirty()
  return self.dirty
end
function DragAndDropListHelper:CheckIfDirty()
  local dirty = false
  for i, v in pairs(self.idToIndex) do
    if self.originalOrder[i] ~= v then
      dirty = true
      break
    end
  end
  if self.dirty ~= dirty then
    self.dirty = dirty
    if self.onDirtyChanged then
      self.onDirtyChanged(self.dirty)
    end
  end
end
function DragAndDropListHelper:onEntryTouchDown(selectedEntry, id, pos)
  if not self.enabled then
    return
  end
  self.draggedId = id
  self.draggedEntry = getEntryFromId(self.element, id)
  if self.draggedEntry == nil then
    return
  end
  if self.draggedEntry ~= selectedEntry then
    self.draggedEntry = nil
    return
  end
  self.snapPos = self.draggedEntry("listOffset"):GetFloat()
  self.prevDraggedId = self.indexToId[self.idToIndex[id] - 1]
  self.prevDraggedEntry = getEntryFromId(self.element, self.prevDraggedId)
  self.nextDraggedId = self.indexToId[self.idToIndex[id] + 1]
  self.nextDraggedEntry = getEntryFromId(self.element, self.nextDraggedId)
  self.draggedEntry:setOrientationPriority(-10)
  local offset = 0
  if self.swiper then
    self.swiper:GetVar("mode"):SetInt(MenuSwipeComponent_SwipeModeDisabled)
    offset = -self.swiper:scrollOffset()
  end
  self.entryRelPos = offset + pos - self.draggedEntry("listOffset"):GetFloat()
  self.mousePos = pos
end
function DragAndDropListHelper:onEntryTouchDrag(pos)
  if not self.enabled or not self.draggedEntry then
    return
  end
  self.mousePos = pos
  if not self.swiper then
    return
  end
  if self.direction == MENU_VERTICAL then
    if pos < 2 * self.draggedEntry:absH() then
      self.sVelocity = self:computeDragVelocity(-1, -pos, -2 * self.draggedEntry:absH(), 0)
    elseif pos > lua_sys.screenHeight() - 2 * self.draggedEntry:absH() then
      self.sVelocity = self:computeDragVelocity(1, pos, lua_sys.screenHeight() - 2 * self.draggedEntry:absH(), lua_sys.screenHeight())
    else
      self.sVelocity = 0
    end
  elseif self.direction == MENU_HORIZONTAL then
    if pos < self.draggedEntry:absW() then
      self.sVelocity = self:computeDragVelocity(-1, -pos, -self.draggedEntry:absW(), 0)
    elseif pos > lua_sys.screenWidth() - self.draggedEntry:absW() then
      self.sVelocity = self:computeDragVelocity(1, pos, lua_sys.screenWidth() - self.draggedEntry:absW(), lua_sys.screenWidth())
    else
      self.sVelocity = 0
    end
  end
end
function DragAndDropListHelper:onEntryTouchUp()
  if self.draggedEntry then
    self.draggedEntry("listOffset"):SetFloat(self.snapPos)
    self.draggedEntry:setOrientationPriority(-1)
  end
  self.draggedEntry = nil
  self.prevDraggedEntry = nil
  self.nextDraggedEntry = nil
  self.sVelocity = 0
  self.draggedRelease = true
  self:CheckIfDirty()
end
function DragAndDropListHelper:swapPrevEntry()
  self.snapPos = self.prevDraggedEntry("listOffset"):GetFloat()
  local tweener = self:createTweeningEntry(self.prevDraggedEntry, -1)
  self:swapWithDragged(self.prevDraggedId, -1)
  tweener.id = "TweenerPrev" .. self.prevDraggedId
  self.nextDraggedId = self.prevDraggedId
  self.nextDraggedEntry = self.prevDraggedEntry
  self.prevDraggedId = self.indexToId[self.idToIndex[self.draggedId] - 1]
  self.prevDraggedEntry = getEntryFromId(self.element, self.prevDraggedId)
  self.tickables[tweener.id] = tweener
  tweener:activate()
  if self.onEntrySwapped then
    self.onEntrySwapped()
  end
end
function DragAndDropListHelper:swapNextEntry()
  self.snapPos = self.nextDraggedEntry("listOffset"):GetFloat()
  local tweener = self:createTweeningEntry(self.nextDraggedEntry, 1)
  self:swapWithDragged(self.nextDraggedId, 1)
  tweener.id = "TweenerNext" .. self.nextDraggedId
  self.prevDraggedId = self.nextDraggedId
  self.prevDraggedEntry = self.nextDraggedEntry
  self.nextDraggedId = self.indexToId[self.idToIndex[self.draggedId] + 1]
  self.nextDraggedEntry = getEntryFromId(self.element, self.nextDraggedId)
  self.tickables[tweener.id] = tweener
  tweener:activate()
  if self.onEntrySwapped then
    self.onEntrySwapped()
  end
end
function DragAndDropListHelper:updateSwiper()
  if self.draggedRelease then
    self.swiper:GetVar("mode"):SetInt(MenuSwipeComponent_SwipeModeFree)
    self.draggedRelease = false
  end
  if -self.swiper:scrollOffset() + self.sVelocity < 0 or -self.swiper:scrollOffset() + self.sVelocity > self.swiper:scrollSize() then
    self.sVelocity = 0
  end
  self.swiper:setScrollOffset(self.swiper:scrollOffset() - self.sVelocity)
end
function DragAndDropListHelper:canSwapPrevEntry()
  if self.direction == MENU_VERTICAL then
    return self.prevDraggedEntry and (not self.tickables["TweenerNext" .. self.prevDraggedId] or self.tickables["TweenerNext" .. self.prevDraggedId].remainingTime <= 0) and self.draggedEntry("listOffset"):GetFloat() + self.draggedEntry:absH() * 0.5 < self.prevDraggedEntry("listOffset"):GetFloat() + self.prevDraggedEntry:absH()
  elseif self.direction == MENU_HORIZONTAL then
    return self.prevDraggedEntry and (not self.tickables["TweenerNext" .. self.prevDraggedId] or self.tickables["TweenerNext" .. self.prevDraggedId].remainingTime <= 0) and self.draggedEntry("listOffset"):GetFloat() + self.draggedEntry:absW() * 0.5 < self.prevDraggedEntry("listOffset"):GetFloat() + self.prevDraggedEntry:absW()
  end
end
function DragAndDropListHelper:canSwapNextEntry()
  if self.direction == MENU_VERTICAL then
    return self.nextDraggedEntry and (not self.tickables["TweenerPrev" .. self.nextDraggedId] or self.tickables["TweenerPrev" .. self.nextDraggedId].remainingTime <= 0) and self.draggedEntry("listOffset"):GetFloat() + self.draggedEntry:absH() * 0.5 > self.nextDraggedEntry("listOffset"):GetFloat()
  elseif self.direction == MENU_HORIZONTAL then
    return self.nextDraggedEntry and (not self.tickables["TweenerPrev" .. self.nextDraggedId] or self.tickables["TweenerPrev" .. self.nextDraggedId].remainingTime <= 0) and self.draggedEntry("listOffset"):GetFloat() + self.draggedEntry:absW() * 0.5 > self.nextDraggedEntry("listOffset"):GetFloat()
  end
end
function DragAndDropListHelper:createTweeningEntry(entry, pos)
  local offset = 0
  if self.direction == MENU_VERTICAL then
    offset = entry:absH()
  elseif self.direction == MENU_HORIZONTAL then
    offset = entry:absW()
  end
  local startLerp = entry("listOffset"):GetFloat()
  local endLerp = entry("listOffset"):GetFloat() + -pos * offset
  local lerpingEntry = entry
  local tweener = Tweener:new({
    duration = 0.1,
    initialValue = 0,
    targetValue = 1,
    ease = lua_sys.Linear_EaseNone,
    onUpdate = function(value)
      local dx = lerp(startLerp, endLerp, value)
      lerpingEntry("listOffset"):SetFloat(dx)
    end
  })
  return tweener
end
function DragAndDropListHelper:swapWithDragged(otherId, pos)
  self.idToIndex[self.draggedId] = self.idToIndex[self.draggedId] - -pos * 1
  self.idToIndex[otherId] = self.idToIndex[otherId] + -pos * 1
  self.indexToId[self.idToIndex[self.draggedId]] = self.draggedId
  self.indexToId[self.idToIndex[otherId]] = otherId
end
function DragAndDropListHelper:computeDragVelocity(direction, value, rangeStart, rangeEnd)
  return direction * (self.dragVelocity[1] + (self.dragVelocity[2] - self.dragVelocity[1]) / (rangeEnd - rangeStart) * (value - rangeStart))
end
return DragAndDropListHelper
