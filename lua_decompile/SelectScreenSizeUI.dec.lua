local MenuHelpers = include("MenuHelpers")
local ScrollingListHelper = include("ScrollingListHelper")
local SelectScreenSizeUI = {}
local screenResolutions = {
  {1024, 768},
  {1280, 800},
  {1280, 1024},
  {1366, 768},
  {1440, 900},
  {1600, 900},
  {1920, 1080}
}
function SelectScreenSizeUI.onPostInit(element)
  SelectScreenSizeUI.Show(element)
end
function SelectScreenSizeUI.queuePop(element)
  SelectScreenSizeUI.Hide(element)
end
function SelectScreenSizeUI.Show(element)
  element.BG:Show()
  element:GetElement("Fade"):DoStoredScript("show")
  lua_sys.playSoundFx("audio/sfx/menu_slide.wav")
  element.SMP_LIST("scrollOffset"):SetFloat(0)
  element.SMP_LIST.Swiper:DoStoredScript("setScrollOffset")
end
function SelectScreenSizeUI.Hide(element)
  local newSelectedWidth = element.BG("NewWindowWidth"):GetInt()
  local newSelectedHeight = element.BG("NewWindowHeight"):GetInt()
  local changeScreenSize = newSelectedWidth > 0 and newSelectedHeight > 0 and game.isWindowSizeEnabled(newSelectedWidth, newSelectedHeight)
  if changeScreenSize then
    game.setWindowSize(newSelectedWidth, newSelectedHeight)
  end
  element.BG:Hide()
  element:GetElement("Fade"):DoStoredScript("hide")
  lua_sys.playSoundFx("audio/sfx/menu_slide.wav")
end
function SelectScreenSizeUI.ContentInit(element)
  element("NewWindowWidth"):SetInt(0)
  element("NewWindowHeight"):SetInt(0)
  element.SMP_LIST:DoStoredScript("populate")
end
function SelectScreenSizeUI.SwiperOnInit(component, element)
  component("smoothMode"):SetInt(1)
end
function SelectScreenSizeUI.SwiperOnTick(component, element, dt)
  ScrollingListHelper.SwiperTick(component, element, dt)
  local scrollOffset = element("scrollOffset"):GetFloat()
  local scrollMarker = element:parent():GetElement("SMP_SCROLLMARKER")
  local originalYOffset = scrollMarker("originalYOffset"):GetInt()
  local markerMovementHeight = element:parent():GetElement("SMP_SCROLLBAR"):absH() - 2 * originalYOffset - scrollMarker:absH()
  local scrollMarkerYOffset = -(scrollOffset / component:scrollSize()) * markerMovementHeight
  scrollMarkerYOffset = lua_sys.clamp(scrollMarkerYOffset, 0, markerMovementHeight)
  scrollMarker("yOffset"):SetInt(originalYOffset + scrollMarkerYOffset)
end
function SelectScreenSizeUI.SwiperRefresh(component, element)
  ScrollingListHelper.SwiperRefresh(component, element)
end
function SelectScreenSizeUI.SwiperSetScrollOffset(component, element)
  local offset = element("scrollOffset"):GetFloat()
  component:setScrollOffset(offset)
end
function SelectScreenSizeUI.SwiperSetScrollOffsetToMarker(component, element)
  local scrollmarker = element:parent():GetElement("SMP_SCROLLMARKER")
  component:setScrollOffset(scrollmarker("scrollOffset"):GetFloat())
end
function SelectScreenSizeUI.ScrollMarkerOnInit(element)
  element("scrollOffset"):SetFloat(0)
  element("originalYOffset"):SetInt(element("yOffset"):GetInt())
end
function SelectScreenSizeUI.ListOnInit(element)
  element("NewSelectedEntry"):SetString("")
  element("CurrentSelectedEntry"):SetString("")
  ScrollingListHelper.ListInit(element, {
    direction = lua_sys.MenuSwipeComponent_SwipeDirectionVertical,
    spacing = 5 * game.menuScaleY()
  })
end
function SelectScreenSizeUI.ListPopulate(element)
  ScrollingListHelper.ListClear(element)
  local function createFunc(idx, itemName)
    local resolution = screenResolutions[idx + 1]
    local resolutionEntry = menu:addTemplateElement("template_screen_resolution_entry", itemName, element)
    resolutionEntry("List"):SetString("SMP_LIST")
    resolutionEntry("windowWidth"):SetInt(resolution[1])
    resolutionEntry("windowHeight"):SetInt(resolution[2])
    resolutionEntry:init()
    resolutionEntry.Text("font"):SetString(game.getTextFont())
    resolutionEntry.Text("text"):SetString(resolution[1] .. " x " .. resolution[2])
    if game.isCurrentWindowSize(resolution[1], resolution[2]) == true then
      resolutionEntry:DoStoredScript("Select")
      element("NewSelectedEntry"):SetString(itemName)
      element("CurrentSelectedEntry"):SetString(itemName)
    elseif game.isWindowSizeEnabled(resolution[1], resolution[2]) then
      resolutionEntry:DoStoredScript("Unselect")
    else
      resolutionEntry:DoStoredScript("Disable")
    end
    return resolutionEntry
  end
  ScrollingListHelper.ListPopulate(element, #screenResolutions, createFunc)
  local newSelectedEntry = element.SMP_LIST:GetElement(element("CurrentSelectedEntry"):GetString())
  if newSelectedEntry then
    local scrollSize = element.SMP_LIST("totalSize"):GetFloat() - (element.SMP_LIST:absH() - element.SMP_LIST("padding"):GetFloat())
    local scrollOffset = newSelectedEntry("listOffset"):GetFloat()
    if scrollOffset < element.SMP_LIST("totalSize"):GetFloat() / 2 then
      scrollOffset = 0
    end
    scrollOffset = lua_sys.clamp(-1 * scrollOffset, -scrollSize, 0)
    element.SMP_LIST("scrollOffset"):SetFloat(scrollOffset)
    element.SMP_LIST.Swiper:DoStoredScript("setSwiperScrollOffset")
  end
end
function SelectScreenSizeUI.ListSelectNewEntry(element)
  local newSelectedEntryId = element("NewSelectedEntry"):GetString()
  local currentEntryId = element("CurrentSelectedEntry"):GetString()
  print("newSelectedEntryId", newSelectedEntryId)
  print("currentEntryId", currentEntryId)
  local newSelectedEntry = element:parent():GetElement(newSelectedEntryId)
  if newSelectedEntry and newSelectedEntryId ~= currentEntryId then
    local newWindowWidth = newSelectedEntry("windowWidth"):GetInt()
    local newWindowHeight = newSelectedEntry("windowHeight"):GetInt()
    if game.isWindowSizeEnabled(newWindowWidth, newWindowHeight) or game.isCurrentWindowSize(newWindowWidth, newWindowHeight) then
      local currentSelectedEntry = element:GetElement(currentEntryId)
      if currentSelectedEntry then
        currentSelectedEntry:DoStoredScript("Unselect")
      end
      element:parent().BG("NewWindowWidth"):SetInt(newWindowWidth)
      element:parent().BG("NewWindowHeight"):SetInt(newWindowHeight)
      element("CurrentSelectedEntry"):SetString(newSelectedEntryId)
      newSelectedEntry:DoStoredScript("Select")
    end
  end
end
function SelectScreenSizeUI.ListOnTick(element, dt)
  ScrollingListHelper.ListTick(element, dt)
  MenuHelpers.ForEachEntry(element, function(entry)
    entry("clipX"):SetFloat(element:absX())
    entry("clipY"):SetFloat(element:absY())
    entry("clipW"):SetFloat(element:absW())
    entry("clipH"):SetFloat(element:absH())
    entry:DoStoredScript("updateClipping")
  end)
end
function SelectScreenSizeUI.ScrollMarkerOnTouchDrag(component, element, x, y)
  local listElement = element:parent():GetElement("SMP_LIST")
  local scrollBarElement = element:parent():GetElement("SMP_SCROLLBAR")
  local originalYOffset = element("originalYOffset"):GetInt()
  local fromTopOfMarkerRange = y - scrollBarElement:absY() - originalYOffset
  local scrollSize = listElement("totalSize"):GetFloat() - (listElement:absH() - listElement("padding"):GetFloat())
  local scrollOffset = scrollSize * (-(fromTopOfMarkerRange - originalYOffset) / (scrollBarElement:absH() - 2 * originalYOffset - element:absH()))
  scrollOffset = lua_sys.clamp(scrollOffset, -scrollSize, 0)
  element("scrollOffset"):SetFloat(scrollOffset)
  listElement.Swiper:DoStoredScript("setScrollOffsetToMarker")
end
return SelectScreenSizeUI
