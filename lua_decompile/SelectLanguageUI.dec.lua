local MenuHelpers = include("MenuHelpers")
local ScrollingListHelper = include("ScrollingListHelper")
local SelectLanguageUI = {}
function SelectLanguageUI.onPostInit(element)
  SelectLanguageUI.Show(element)
end
function SelectLanguageUI.queuePop(element)
  SelectLanguageUI.Hide(element)
end
function SelectLanguageUI.Show(element)
  element.BG:Show()
  element:GetElement("Fade"):DoStoredScript("show")
  lua_sys.playSoundFx("audio/sfx/menu_slide.wav")
  element.SMP_LIST("scrollOffset"):SetFloat(0)
  element.SMP_LIST.Swiper:DoStoredScript("setScrollOffset")
end
function SelectLanguageUI.Hide(element)
  local newSelectedLanguage = element.BG("NewSelectedLanguage"):GetString()
  local currentLanguage = game.currentLanguage()
  print("newSelectedLanguage:", newSelectedLanguage)
  print("currentLanguage:", currentLanguage)
  if currentLanguage ~= newSelectedLanguage then
    game.logEvent("set_language", "prev_lang", currentLanguage, "new_lang", newSelectedLanguage)
    game.setCurrentLanguage(newSelectedLanguage)
  end
  element.BG:Hide()
  element:GetElement("Fade"):DoStoredScript("hide")
  lua_sys.playSoundFx("audio/sfx/menu_slide.wav")
end
function SelectLanguageUI.ContentInit(element)
  local currentLanguage = game.currentLanguage()
  element("NewSelectedLanguage"):SetString(currentLanguage)
  element.SMP_LIST:DoStoredScript("populate")
end
function SelectLanguageUI.SwiperOnInit(component, element)
  component("smoothMode"):SetInt(1)
end
function SelectLanguageUI.SwiperOnTick(component, element, dt)
  ScrollingListHelper.SwiperTick(component, element, dt)
  local scrollOffset = element("scrollOffset"):GetFloat()
  local scrollMarker = element:parent():GetElement("SMP_SCROLLMARKER")
  local originalYOffset = scrollMarker("originalYOffset"):GetInt()
  local markerMovementHeight = element:parent():GetElement("SMP_SCROLLBAR"):absH() - 2 * originalYOffset - scrollMarker:absH()
  local scrollMarkerYOffset = -(scrollOffset / component:scrollSize()) * markerMovementHeight
  scrollMarkerYOffset = lua_sys.clamp(scrollMarkerYOffset, 0, markerMovementHeight)
  scrollMarker("yOffset"):SetInt(originalYOffset + scrollMarkerYOffset)
end
function SelectLanguageUI.SwiperRefresh(component, element)
  ScrollingListHelper.SwiperRefresh(component, element)
end
function SelectLanguageUI.SwiperSetScrollOffset(component, element)
  local offset = element("scrollOffset"):GetFloat()
  component:setScrollOffset(offset)
end
function SelectLanguageUI.SwiperSetScrollOffsetToMarker(component, element)
  local scrollmarker = element:parent():GetElement("SMP_SCROLLMARKER")
  component:setScrollOffset(scrollmarker("scrollOffset"):GetFloat())
end
function SelectLanguageUI.ScrollMarkerOnInit(element)
  element("scrollOffset"):SetFloat(0)
  element("originalYOffset"):SetInt(element("yOffset"):GetInt())
end
function SelectLanguageUI.ListOnInit(element)
  element("NewSelectedEntry"):SetString("")
  element("CurrentSelectedEntry"):SetString("")
  ScrollingListHelper.ListInit(element, {
    direction = lua_sys.MenuSwipeComponent_SwipeDirectionVertical,
    spacing = 5 * game.menuScaleY()
  })
end
function SelectLanguageUI.ListPopulate(element)
  ScrollingListHelper.ListClear(element)
  local currentLanguage = game.currentLanguage()
  local supportedLanguages = game.getSupportedLanguages()
  local numLanguages = supportedLanguages:size()
  local function createFunc(idx, itemName)
    local language = supportedLanguages[idx]
    local languageEntry = menu:addTemplateElement("template_language_entry", itemName, element)
    languageEntry("List"):SetString("SMP_LIST")
    languageEntry("Info"):SetString(language)
    languageEntry:init()
    languageEntry.Text("font"):SetString(game.getTextFont())
    languageEntry.Text("text"):SetString(game.localizedUpper("LANGUAGE_" .. language:upper()))
    if currentLanguage == language then
      languageEntry:DoStoredScript("Select")
      element("NewSelectedEntry"):SetString(itemName)
      element("CurrentSelectedEntry"):SetString(itemName)
    else
      languageEntry:DoStoredScript("Unselect")
    end
    return languageEntry
  end
  ScrollingListHelper.ListPopulate(element, numLanguages, createFunc)
  local newSelectedEntry = element.SMP_LIST:GetElement(element("CurrentSelectedEntry"):GetString())
  if newSelectedEntry then
    local scrollSize = element.SMP_LIST("totalSize"):GetFloat() - (element.SMP_LIST:absH() - element.SMP_LIST("padding"):GetFloat())
    local scrollOffset = newSelectedEntry("listOffset"):GetFloat()
    scrollOffset = -(scrollOffset - element.SMP_LIST:absH() / 2 + newSelectedEntry:absH() / 2)
    scrollOffset = lua_sys.clamp(scrollOffset, -scrollSize, 0)
    element.SMP_LIST("scrollOffset"):SetFloat(scrollOffset)
    element.SMP_LIST.Swiper:DoStoredScript("setSwiperScrollOffset")
  end
end
function SelectLanguageUI.ListSelectNewEntry(element)
  local newSelectedEntryId = element("NewSelectedEntry"):GetString()
  local currentEntryId = element("CurrentSelectedEntry"):GetString()
  print("newSelectedEntryId", newSelectedEntryId)
  print("currentEntryId", currentEntryId)
  local newSelectedEntry = element:parent():GetElement(newSelectedEntryId)
  if newSelectedEntry and newSelectedEntryId ~= currentEntryId then
    local newLanguage = newSelectedEntry("Info"):GetString()
    local currentSelectedEntry = element:GetElement(currentEntryId)
    if currentSelectedEntry then
      currentSelectedEntry:DoStoredScript("Unselect")
    end
    element:parent().BG("NewSelectedLanguage"):SetString(newLanguage)
    element("CurrentSelectedEntry"):SetString(newSelectedEntryId)
    newSelectedEntry:DoStoredScript("Select")
  end
end
function SelectLanguageUI.ListOnTick(element, dt)
  ScrollingListHelper.ListTick(element, dt)
  MenuHelpers.ForEachEntry(element, function(entry)
    entry("clipX"):SetFloat(element:absX())
    entry("clipY"):SetFloat(element:absY())
    entry("clipW"):SetFloat(element:absW())
    entry("clipH"):SetFloat(element:absH())
    entry:DoStoredScript("updateClipping")
  end)
end
function SelectLanguageUI.ScrollMarkerOnInit(element)
  element("scrollOffset"):SetFloat(0)
  element("originalYOffset"):SetInt(element("yOffset"):GetInt())
end
function SelectLanguageUI.ScrollMarkerOnTouchDrag(component, element, x, y)
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
return SelectLanguageUI
