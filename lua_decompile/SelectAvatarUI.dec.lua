local MenuHelpers = include("MenuHelpers")
local SelectAvatarUI = {}
function SelectAvatarUI.onPostInit(element)
  SelectAvatarUI.Show(element)
end
function SelectAvatarUI.queuePop(element)
  SelectAvatarUI.Hide(element)
end
function SelectAvatarUI.Show(element)
  element.BG:Show()
  element:GetElement("Fade"):DoStoredScript("show")
  lua_sys.playSoundFx("audio/sfx/menu_slide.wav")
end
function SelectAvatarUI.Hide(element)
  local currentType = element.BG("CurrentAvatarType"):GetInt()
  local selectedType = element.BG("SelectedAvatarType"):GetInt()
  local currentInfo = element.BG("CurrentAvatarInfo"):GetString()
  local selectedInfo = element.BG("SelectedAvatarInfo"):GetString()
  if currentType ~= selectedType or currentInfo ~= selectedInfo then
    game.setPlayerAvatar(selectedType, selectedInfo)
  end
  element.BG:Hide()
  element:GetElement("Fade"):DoStoredScript("hide")
  lua_sys.playSoundFx("audio/sfx/menu_slide.wav")
end
local function Populate(element)
  local extras = 1
  local entriesPerRow = element("EntriesPerRow"):GetInt()
  local entriesPerPage = element("EntriesPerPage"):GetInt()
  local currentPage = element("CurrentPage"):GetInt()
  local selectedType = element("SelectedAvatarType"):GetInt()
  local selectedInfo = element("SelectedAvatarInfo"):GetString()
  local monsterIds = game.getAllMonsterPortraitIds()
  local numMonikers = game.numMonikersAvail()
  MenuHelpers.ForEachEntry(element, function(e)
    element:RemoveElement(e)
  end)
  local offsetY = 36 * game.menuScaleY()
  local rowSpacing = 48 * game.menuScaleY()
  local row = {}
  local count = 0
  local function addEntry(type, info)
    local entryName = "entry" .. count
    local entry = menu:addTemplateElement("template_select_avatar_entry", entryName, element)
    entry("Type"):SetInt(type)
    entry("Info"):SetString(info)
    entry:setParent(element)
    entry:setOrientation(lua_sys.MenuOrientation(0, offsetY, -1, lua_sys.LEFT, lua_sys.TOP))
    entry:setRelativeObjectAnchors(lua_sys.HCENTER, lua_sys.TOP)
    entry:init()
    entry:setPositionBroadcast(true)
    entry:postInit()
    if type == selectedType and info == selectedInfo then
      entry:DoStoredScript("Select")
      element("CurrentSelectedEntryName"):SetString(entryName)
    end
    table.insert(row, entry)
    count = count + 1
    if count % entriesPerRow == 0 then
      MenuHelpers.CenterHorizontally(row)
      offsetY = offsetY + rowSpacing
      row = {}
    end
  end
  if currentPage == 0 then
    addEntry(0, "0")
  end
  local startOffset = currentPage * entriesPerPage
  if currentPage > 0 then
    startOffset = startOffset - extras
  end
  local type = 0
  local idx = startOffset
  if idx >= monsterIds:size() then
    idx = idx - monsterIds:size()
    type = 2
  end
  while entriesPerPage > count do
    if type == 0 and idx >= monsterIds:size() then
      type = 2
      idx = 0
    end
    if type == 2 and numMonikers <= idx then
      break
    end
    if type == 0 then
      local info = tostring(monsterIds[idx])
      addEntry(type, info)
    elseif type == 2 then
      local info = tostring(idx + 30)
      addEntry(type, info)
    end
    idx = idx + 1
  end
  MenuHelpers.CenterHorizontally(row)
  if currentPage == 0 then
    element.LeftButton:DoStoredScript("disable")
  else
    element.LeftButton:DoStoredScript("enable")
  end
  local totalPages = math.ceil((monsterIds:size() + numMonikers + extras) / entriesPerPage)
  if currentPage == totalPages - 1 then
    element.RightButton:DoStoredScript("disable")
  else
    element.RightButton:DoStoredScript("enable")
  end
  element.PageText("size"):SetFloat(0.3 * game.menuScaleY())
  element.PageText("text"):SetString(currentPage + 1 .. "/" .. totalPages)
  element.PageText("autoScale"):SetInt(1)
  element:calculatePosition()
end
function SelectAvatarUI.ContentInit(element)
  local extras = 1
  element("CurrentSelectedEntryName"):SetString("")
  element("NewSelectedEntryName"):SetString("")
  local entriesPerRow = 5
  element("EntriesPerRow"):SetInt(entriesPerRow)
  local entriesPerPage = 20
  element("EntriesPerPage"):SetInt(entriesPerPage)
  local avatar = game.getPlayerAvatar()
  local selectedType = avatar:getType()
  local selectedInfo = avatar:getInfo()
  element("CurrentAvatarType"):SetInt(selectedType)
  element("CurrentAvatarInfo"):SetString(selectedInfo)
  element("SelectedAvatarType"):SetInt(selectedType)
  element("SelectedAvatarInfo"):SetString(selectedInfo)
  game.clearMonsterPortraitIds()
  local monsterIds = game.getAllMonsterPortraitIds()
  local page = 0
  if selectedType == 0 then
    selectedInfo = tonumber(selectedInfo)
    if selectedInfo > 0 then
      for i = 1, monsterIds:size() - 1 do
        if selectedInfo == monsterIds[i] then
          page = math.floor((i + extras) / entriesPerPage)
          break
        end
      end
    end
  elseif selectedType == 2 then
    selectedInfo = tonumber(selectedInfo)
    local id = selectedInfo - 29
    page = math.floor((id + extras + monsterIds:size()) / entriesPerPage)
  end
  element("CurrentPage"):SetInt(page)
  Populate(element)
end
function SelectAvatarUI.NextPage(element)
  local page = element("CurrentPage"):GetInt() + 1
  element("CurrentPage"):SetInt(page)
  Populate(element)
end
function SelectAvatarUI.PreviousPage(element)
  local page = element("CurrentPage"):GetInt() - 1
  element("CurrentPage"):SetInt(page)
  Populate(element)
end
function SelectAvatarUI.OnEntrySelected(element)
  local newSelectedName = element("NewSelectedEntryName"):GetString()
  local newSelectedEntry = element:GetElement(newSelectedName)
  if newSelectedEntry then
    local newType = newSelectedEntry("Type"):GetInt()
    local newInfo = newSelectedEntry("Info"):GetString()
    local type = element("SelectedAvatarType"):GetInt()
    local info = element("SelectedAvatarInfo"):GetString()
    if newType ~= type or newInfo ~= info then
      local currentSelectedName = element("CurrentSelectedEntryName"):GetString()
      local currentSelectedEntry = element:GetElement(currentSelectedName)
      if currentSelectedEntry then
        currentSelectedEntry:DoStoredScript("Unselect")
      end
      element("SelectedAvatarType"):SetInt(newType)
      element("SelectedAvatarInfo"):SetString(newInfo)
      element("CurrentSelectedEntryName"):SetString(newSelectedName)
      newSelectedEntry:DoStoredScript("Select")
    end
  end
end
return SelectAvatarUI
