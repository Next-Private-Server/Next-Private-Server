local MenuHelpers = include("MenuHelpers")
local ScrollingListHelper = {}
local scrollMarkerElement
function ScrollingListHelper.ListInit(element, options)
  options = options or {}
  local direction = options.direction or lua_sys.MenuSwipeComponent_SwipeDirectionHorizontal
  local padding = options.padding or 16 * game.hudScale()
  local mode = options.mode or lua_sys.MenuSwipeComponent_SwipeModeFree
  local tSteps = options.tSteps or 25
  local spacing = options.spacing or 8 * game.hudScale()
  local alwaysBounce = options.alwaysBounce or 1
  element("numEntries"):SetInt(0)
  element("totalSize"):SetFloat(0)
  element.minSize = 0
  element("scrollOffset"):SetFloat(0)
  element("updateScrolling"):SetInt(1)
  element("direction"):SetInt(direction)
  element("padding"):SetFloat(padding)
  element("spacing"):SetFloat(spacing)
  element("mode"):SetInt(mode)
  element("tSteps"):SetFloat(tSteps)
  element("alwaysBounce"):SetInt(alwaysBounce)
end
function ScrollingListHelper.ListClear(element)
  MenuHelpers.ForEachEntry(element, function(entry)
    element:RemoveElement(entry)
  end)
  element("numEntries"):SetInt(0)
  element("totalSize"):SetFloat(0)
end
local ListCreateEntryName = function(element)
  return "entry" .. element("numEntries"):GetInt()
end
ScrollingListHelper.ListCreateEntryName = ListCreateEntryName
local ListAddEntry = function(element, entry, priority)
  priority = priority or -1
  if entry then
    local offset = element("totalSize"):GetFloat()
    local numEntries = element("numEntries"):GetInt()
    if numEntries > 0 then
      local panelSpacing = element("spacing"):GetFloat()
      offset = offset + panelSpacing
    end
    entry("listOffset"):SetFloat(offset)
    local direction = element("direction"):GetInt()
    if direction == lua_sys.MenuSwipeComponent_SwipeDirectionHorizontal then
      entry:setOrientation(lua_sys.MenuOrientation(offset, 0, priority, lua_sys.LEFT, lua_sys.VCENTER))
      entry:setRelativeObjectAnchors(lua_sys.LEFT, lua_sys.VCENTER)
    else
      entry:setOrientation(lua_sys.MenuOrientation(0, offset, priority, lua_sys.HCENTER, lua_sys.TOP))
      entry:setRelativeObjectAnchors(lua_sys.HCENTER, lua_sys.TOP)
    end
    entry:init()
    entry:setPositionBroadcast(true)
    entry:postInit()
    if direction == lua_sys.MenuSwipeComponent_SwipeDirectionHorizontal then
      offset = offset + entry:absW()
      if element.minSize == 0 or entry:absW() < element.minSize then
        element.minSize = entry:absW()
      end
    else
      offset = offset + entry:absH()
      if element.minSize == 0 or entry:absH() < element.minSize then
        element.minSize = entry:absH()
      end
    end
    element("totalSize"):SetFloat(offset)
    element("numEntries"):SetInt(numEntries + 1)
  end
end
ScrollingListHelper.ListAddEntry = ListAddEntry
function ScrollingListHelper.ListPopulate(element, count, createFunc)
  if element("numEntries"):GetInt() == 0 then
    local padding = element("padding"):GetFloat()
    local panelSpacing = element("spacing"):GetFloat()
    element("totalSize"):SetFloat(panelSpacing + padding)
  end
  for i = 0, count - 1 do
    local entryName = ListCreateEntryName(element)
    local entry = createFunc(i, entryName)
    ListAddEntry(element, entry)
  end
  element:setPositionBroadcast(true)
  element.Swiper:DoStoredScript("refresh")
end
function ScrollingListHelper.ListTick(element, dt)
  local updateScrolling = element("updateScrolling"):GetInt() == 1
  if updateScrolling then
    do
      local direction = element("direction"):GetInt()
      local scrollOffset = element("scrollOffset"):GetFloat()
      MenuHelpers.ForEachEntry(element, function(entry)
        if direction == lua_sys.MenuSwipeComponent_SwipeDirectionHorizontal then
          entry("xOffset"):SetFloat(scrollOffset + entry("listOffset"):GetFloat())
        else
          entry("yOffset"):SetFloat(scrollOffset + entry("listOffset"):GetFloat())
        end
      end)
    end
  end
  return updateScrolling
end
function ScrollingListHelper.GetCurrentOffset(component, element)
  return element("scrollOffset"):GetFloat()
end
function ScrollingListHelper.SetCurrentOffset(component, element, offset)
  component:setScrollOffset(offset)
end
function ScrollingListHelper.GetContentSize(component, element)
  return element("totalSize"):GetFloat()
end
function ScrollingListHelper.GetViewSize(component, element)
  local direction = element("direction"):GetInt()
  local padding = element("padding"):GetFloat()
  local viewSize
  if direction == lua_sys.MenuSwipeComponent_SwipeDirectionHorizontal then
    viewSize = element:absW() - padding
  else
    viewSize = element:absH() - padding
  end
  return viewSize
end
function ScrollingListHelper.SwiperRefresh(component, element, scrollBarSprite, scrollMarkerSprite)
  local direction = element("direction"):GetInt()
  local padding = element("padding"):GetFloat()
  local contentSize = element("totalSize"):GetFloat()
  local mode = element("mode"):GetInt()
  local tSteps = element("tSteps"):GetFloat()
  local alwaysBounce = element("alwaysBounce"):GetInt()
  component("direction"):SetInt(direction)
  component("mode"):SetInt(mode)
  component("tSteps"):SetFloat(tSteps)
  component("mouseScrollSpeed"):SetFloat((element.minSize + padding * 2) / 3 / contentSize * 100)
  local viewSize
  if direction == lua_sys.MenuSwipeComponent_SwipeDirectionHorizontal then
    viewSize = element:absW() - padding
  else
    viewSize = element:absH() - padding
  end
  component:setScrollSize(math.max(0, contentSize - viewSize))
  if alwaysBounce == 1 then
    component:listenToTouches(element)
    element.Touch("enabled"):SetInt(1)
  elseif contentSize < viewSize then
    component:setScrollOffset((viewSize - contentSize) * 0.5)
    element.Touch("enabled"):SetInt(0)
    if scrollBarSprite ~= nil then
      scrollBarSprite("visible"):SetInt(0)
    end
    if scrollMarkerSprite ~= nil then
      scrollMarkerSprite("visible"):SetInt(0)
    end
  else
    component:listenToTouches(element)
    element.Touch("enabled"):SetInt(1)
  end
end
function ScrollingListHelper.SwiperTick(component, element, dt)
  local scrollOffset = component:scrollOffset()
  element("scrollOffset"):SetFloat(scrollOffset)
end
function ScrollingListHelper.ScrollMarkerOnInit(component, element, listElementName, scrollBarElementName)
  component("originalYOffset"):SetInt(element("yOffset"):GetInt())
  component("listElementName"):SetString(listElementName)
  component("scrollBarElementName"):SetString(scrollBarElementName)
end
function ScrollingListHelper.ScrollMarkerOnTouchDrag(component, element, x, y)
  scrollMarkerElement = element
  local listElementName = component("listElementName"):GetString()
  local listElement = element:parent():GetElement(listElementName)
  local scrollBarElementName = component("scrollBarElementName"):GetString()
  local scrollBarElement = element:parent():GetElement(scrollBarElementName)
  local originalYOffset = component("originalYOffset"):GetInt()
  local fromTopOfMarkerRange = y - scrollBarElement:absY() - originalYOffset
  local scrollSize = listElement("totalSize"):GetFloat() - (listElement:absH() - listElement("padding"):GetFloat())
  local scrollOffset = scrollSize * (-(fromTopOfMarkerRange - originalYOffset) / (scrollBarElement:absH() - 2 * originalYOffset - element:absH()))
  scrollOffset = lua_sys.clamp(scrollOffset, -scrollSize, 0)
  listElement.Swiper:setScrollOffset(scrollOffset)
end
function ScrollingListHelper.ScrollMarkerOnTick(component, element, dt)
  local listElementName = component("listElementName"):GetString()
  local listElement = element:parent():GetElement(listElementName)
  local scrollBarElementName = component("scrollBarElementName"):GetString()
  local scrollBarElement = element:parent():GetElement(scrollBarElementName)
  local scrollOffset = listElement("scrollOffset"):GetFloat()
  local originalYOffset = component("originalYOffset"):GetInt()
  local markerMovementHeight = scrollBarElement:absH() - 2 * originalYOffset - element:absH()
  local scrollSize = listElement.Swiper("scrollSize"):GetFloat()
  local scrollMarkerYOffset = 0
  if scrollSize > 0 then
    scrollMarkerYOffset = -(scrollOffset / scrollSize) * markerMovementHeight
    scrollMarkerYOffset = lua_sys.clamp(scrollMarkerYOffset, 0, markerMovementHeight)
  end
  element("yOffset"):SetInt(originalYOffset + scrollMarkerYOffset)
end
function ScrollingListHelper.CommonListSwiper(scrollBarName, scrollMarkerName)
  return {
    onInit = function(component, element)
      component("smoothMode"):SetInt(1)
    end,
    refresh = ScrollingListHelper.SwiperRefresh,
    onTick = function(component, element, dt)
      ScrollingListHelper.SwiperTick(component, element, dt)
      if scrollBarName and scrollMarkerName then
        local scrollOffset = element("scrollOffset"):GetFloat()
        local scrollMarker = element:parent():GetElement(scrollMarkerName)
        local originalYOffset = scrollMarker("originalYOffset"):GetInt()
        local markerMovementHeight = element:parent():GetElement(scrollBarName):absH() - 2 * originalYOffset - scrollMarker:absH()
        local scrollMarkerYOffset = -(scrollOffset / component:scrollSize()) * markerMovementHeight
        scrollMarkerYOffset = lua_sys.clamp(scrollMarkerYOffset, 0, markerMovementHeight)
        scrollMarker("yOffset"):SetInt(originalYOffset + scrollMarkerYOffset)
      end
    end,
    setScrollOffsetToMarker = function(component, element)
      local scrollmarker = element:parent():GetElement(scrollMarkerName)
      component:setScrollOffset(scrollmarker("scrollOffset"):GetFloat())
    end
  }
end
return ScrollingListHelper
