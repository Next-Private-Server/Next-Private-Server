local ScrollingListHelper = include("ScrollingListHelper")
local MenuHelpers = include("MenuHelpers")
local DragAndDropListHelper = include("DragAndDropListHelper")
local Tweener = include("Tweener")
local MapIslandList = {
  Swiper = {},
  Touch = {}
}
local SCROLL_TRANSITION_TIME = 0.33
function MapIslandList:onInit()
  self.alpha = 1
  ScrollingListHelper.ListInit(self, {
    direction = lua_sys.MenuSwipeComponent_SwipeDirectionVertical,
    alwaysBounce = 1,
    padding = 0,
    spacing = 0
  })
  self.Swiper:GetVar("smoothMode"):SetInt(1)
  self.startScrollOffset = 0
  self.targetScrollOffset = 0
  self.scrollTransitionTime = 0
  self.inSortingMode = false
  self.sVelocityY = 0
  self.dragDy = 0
  self.mouseY = 0
  self.entryRelY = 0
  self.draggedRelease = false
  self.numEntries = 0
  self.DragAndDropHelper = DragAndDropListHelper:new({
    element = self,
    swiper = self.Swiper,
    direction = 1
  })
  self.dirty = false
  self.orderReset = false
end
local function getEntryFromId(element, islandId)
  local targetEntry
  MenuHelpers.ForEachEntry(element, function(entry)
    if entry.islandId == islandId then
      targetEntry = entry
    end
  end)
  return targetEntry
end
function MapIslandList:Disable()
  MenuHelpers.ForEachEntry(self, function(entry)
    entry.Touch:GetVar("enabled"):SetInt(0)
    if self.inSortingMode then
      entry.UpButton.Touch:GetVar("enabled"):SetInt(0)
      entry.DownButton.Touch:GetVar("enabled"):SetInt(0)
    end
  end)
  self.Swiper:GetVar("mode"):SetInt(MenuSwipeComponent_SwipeModeDisabled)
end
function MapIslandList:Enable()
  MenuHelpers.ForEachEntry(self, function(entry)
    entry.Touch:GetVar("enabled"):SetInt(1)
    if self.inSortingMode then
      entry.UpButton.Touch:GetVar("enabled"):SetInt(1)
      entry.DownButton.Touch:GetVar("enabled"):SetInt(1)
    end
  end)
  self.Swiper:GetVar("mode"):SetInt(MenuSwipeComponent_SwipeModeFree)
end
function MapIslandList:CenterScrollingList(islandId, animate)
  if animate == nil then
    animate = true
  end
  local targetEntry = getEntryFromId(self, islandId)
  if not targetEntry then
    print("ERROR: could not find island entry with id:", islandId)
    return
  end
  local scrollOffset = targetEntry:GetVar("listOffset"):GetFloat() - lua_sys.screenHeight() * 0.5 + targetEntry:absH() * 0.5 + self:GetVar("yOffset"):GetFloat()
  scrollOffset = math.max(scrollOffset, 0)
  scrollOffset = math.min(scrollOffset, self.Swiper:scrollSize())
  self.targetScrollOffset = -scrollOffset
  if animate then
    self.startScrollOffset = self.Swiper:scrollOffset()
    self.scrollTransitionTime = SCROLL_TRANSITION_TIME
  else
    self.Swiper:setScrollOffset(self.targetScrollOffset)
  end
end
function MapIslandList:SelectIsland(islandId, animate, motionMode)
  if animate == nil then
    animate = true
  end
  if motionMode == nil then
    motionMode = false
  end
  local targetEntry = getEntryFromId(self, islandId)
  if not targetEntry then
    print("ERROR: could not find island entry with id:", islandId)
    return
  end
  if not self.currentlySelected or self.currentlySelected ~= targetEntry then
    if self.currentlySelected then
      self.currentlySelected:SetSelected(false)
    end
    self.currentlySelected = targetEntry
    self.currentlySelected:SetSelected(true)
  end
  if self.inSortingMode or motionMode then
    return
  end
  self:CenterScrollingList(islandId, animate)
end
function MapIslandList:SortingMode(openSortingMode)
  self.inSortingMode = openSortingMode
  self.DragAndDropHelper.enabled = openSortingMode
  if not self.inSortingMode then
    self:DeselectIsland()
  end
  MenuHelpers.ForEachEntry(self, function(entry)
    if openSortingMode then
      entry.UpButton:setVisible()
      entry.DownButton:setVisible()
      entry:hideInfo()
    else
      entry.UpButton:setInvisible()
      entry.DownButton:setInvisible()
      entry:showInfo()
    end
  end)
end
function MapIslandList:DeselectIsland()
  if self.currentlySelected then
    self.currentlySelected:SetSelected(false)
    self.currentlySelected = nil
  end
end
function MapIslandList:Populate(islands, isMirrorMode)
  self.isMirrorMode = isMirrorMode
  self:DeselectIsland()
  ScrollingListHelper.ListClear(self)
  local function selectItem(element)
    local lastSelected = self.currentlySelected
    if self.currentlySelected then
      self.currentlySelected:SetSelected(false)
    end
    if lastSelected == element then
      self.currentlySelected = nil
      if self.OnEntryDeselected and not self.inSortingMode then
        self.OnEntryDeselected()
      end
    else
      self.currentlySelected = element
    end
    if self.currentlySelected then
      self.currentlySelected:SetSelected(true)
      if self.OnEntrySelected and not self.inSortingMode then
        self.OnEntrySelected(self.currentlySelected.islandId)
      elseif self.OnEntrySelected then
        lua_sys.playSoundFx("audio/sfx/menu_click.wav")
      end
    end
  end
  local function onSortButtonUp(enable)
    MenuHelpers.ForEachEntry(self, function(entry)
      entry.Touch:GetVar("enabled"):SetInt(enable)
      entry.UpButton.Touch:GetVar("enabled"):SetInt(enable)
      entry.DownButton.Touch:GetVar("enabled"):SetInt(enable)
    end)
  end
  local function moveIslands(islandId, numIslandsBelow)
    local targetEntry = getEntryFromId(self, islandId)
    local otherIslandId = self.DragAndDropHelper.indexToId[self.DragAndDropHelper.idToIndex[islandId] + numIslandsBelow]
    local otherEntry = getEntryFromId(self, otherIslandId)
    if targetEntry and otherEntry then
      do
        local startLerp = targetEntry("listOffset"):GetFloat()
        local endLerp = otherEntry("listOffset"):GetFloat()
        local scrollOffset = -(self.Swiper:scrollOffset() + otherEntry:absH() * -numIslandsBelow)
        scrollOffset = math.max(scrollOffset, 0)
        scrollOffset = math.min(scrollOffset, self.Swiper:scrollSize())
        self.targetScrollOffset = -scrollOffset
        self.startScrollOffset = self.Swiper:scrollOffset()
        local tweener = Tweener:new({
          duration = 0.67,
          initialValue = 0,
          targetValue = 1,
          ease = lua_sys.Quadratic_EaseInOut,
          onUpdate = function(value)
            local dx = lerp(startLerp, endLerp, value)
            targetEntry("listOffset"):SetFloat(dx)
            dx = lerp(endLerp, startLerp, value)
            otherEntry("listOffset"):SetFloat(dx)
            dx = lerp(self.startScrollOffset, self.targetScrollOffset, value)
            self.Swiper:setScrollOffset(dx)
          end,
          onDone = function()
            otherEntry:setOrientationPriority(-1)
            onSortButtonUp(1)
            self.Swiper:GetVar("mode"):SetInt(MenuSwipeComponent_SwipeModeFree)
          end
        })
        tweener.id = "IslandMoveTweener"
        self.DragAndDropHelper.tickables[tweener.id] = tweener
        tweener:activate()
        self.Swiper:GetVar("mode"):SetInt(MenuSwipeComponent_SwipeModeDisabled)
        onSortButtonUp(0)
        otherEntry:setOrientationPriority(10)
        self.DragAndDropHelper.idToIndex[islandId] = self.DragAndDropHelper.idToIndex[islandId] + numIslandsBelow
        self.DragAndDropHelper.idToIndex[otherIslandId] = self.DragAndDropHelper.idToIndex[otherIslandId] - numIslandsBelow
        self.DragAndDropHelper.indexToId[self.DragAndDropHelper.idToIndex[islandId]] = islandId
        self.DragAndDropHelper.indexToId[self.DragAndDropHelper.idToIndex[otherIslandId]] = otherIslandId
        self.DragAndDropHelper:CheckIfDirty()
        self:onEntrySwapped()
      end
    end
  end
  local function moveUp(islandId)
    moveIslands(islandId, -1)
  end
  local function moveDown(islandId)
    moveIslands(islandId, 1)
  end
  local function tDrag(islandId, x, y, dx, dy)
    self.DragAndDropHelper:onEntryTouchDrag(y)
  end
  local function tDown(islandId, x, y)
    if not self.DragAndDropHelper.tickables.IslandMoveTweener or self.DragAndDropHelper.tickables.IslandMoveTweener.remainingTime <= 0 then
      self.DragAndDropHelper:onEntryTouchDown(self.currentlySelected, islandId, y)
    end
  end
  local function tUp()
    self.DragAndDropHelper:onEntryTouchUp()
  end
  local function createFunc(idx, entryName)
    local mapEntry = menu:addTemplateElement("template_map_list_entry", entryName, self)
    local islandId = islands[idx]
    self.DragAndDropHelper:AddEntry(idx, islandId)
    mapEntry:setParent(self)
    mapEntry:relativeTo(self)
    mapEntry:setOrientation(lua_sys.MenuOrientation(0, 0, 0, lua_sys.LEFT, lua_sys.VCENTER))
    mapEntry:setRelativeObjectAnchors(lua_sys.HCENTER, lua_sys.VCENTER)
    mapEntry:calculatePosition()
    mapEntry:init()
    mapEntry:Setup(islandId, self.isMirrorMode, selectItem, moveUp, moveDown, tDrag, tDown, tUp)
    mapEntry:setPositionBroadcast(true)
    mapEntry:postInit()
    return mapEntry
  end
  ScrollingListHelper.ListPopulate(self, islands:size(), createFunc)
  self.DragAndDropHelper:ResetOriginalOrder()
  function self.DragAndDropHelper.onDirtyChanged(dirty)
    self.dirty = dirty
    if self.OnDirtyChanged then
      self.OnDirtyChanged(dirty)
    end
  end
  function self.DragAndDropHelper.onEntrySwapped()
    self:onEntrySwapped()
  end
  self.numEntries = islands:size()
end
function MapIslandList:onEntrySwapped()
  self.orderReset = false
end
function MapIslandList:SortEntries(islands)
  for i = 0, islands:size() - 1 do
    local id = islands[i]
    local entry = getEntryFromId(self, id)
    if entry then
      entry("listOffset"):SetFloat(entry:absH() * i + self("padding"):GetFloat())
      self.DragAndDropHelper.idToIndex[id] = i + 1
      self.DragAndDropHelper.indexToId[i + 1] = id
    end
  end
  self.DragAndDropHelper:CheckIfDirty()
end
function MapIslandList:GetCustomSortingList()
  local list = ""
  for _, id in pairs(self.DragAndDropHelper.indexToId) do
    list = list .. id .. ", "
  end
  return list
end
function MapIslandList:GetIdToIndexMap()
  return self.DragAndDropHelper.idToIndex
end
function MapIslandList:GetIndexToIdMap()
  return self.DragAndDropHelper.indexToId
end
function MapIslandList:onTick(dt)
  if self.scrollTransitionTime > 0 then
    dt = math.min(dt, 0.033)
    self.scrollTransitionTime = math.max(self.scrollTransitionTime - dt, 0)
    local scrollOffset = lerp(self.startScrollOffset, self.targetScrollOffset, 1 - self.scrollTransitionTime / SCROLL_TRANSITION_TIME)
    self.Swiper:setScrollOffset(scrollOffset)
  end
  self.DragAndDropHelper:Tick(dt)
  ScrollingListHelper.ListTick(self, dt)
end
function MapIslandList.Swiper:refresh(element)
  ScrollingListHelper.SwiperRefresh(self, element)
end
function MapIslandList.Swiper:onTick(element, dt)
  ScrollingListHelper.SwiperTick(self, element, dt)
end
return MapIslandList
