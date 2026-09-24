local ITEMS_PER_ROW = 6
local ITEMS_PER_PAGE = 3 * ITEMS_PER_ROW
local UserProfileFavSelector = {}
UserProfileFavSelector.PageNav = {Current = 0, Total = 1}
UserProfileFavSelector.selectedSlot = ""
UserProfileFavSelector.selectedId = 0
UserProfileFavSelector.allItems = nil
function UserProfileFavSelector.onInit(element)
  game.hideContextBar()
end
function UserProfileFavSelector.closePopup(element)
  game.popPopUp()
  game.showContextBar()
end
function UserProfileFavSelector.onPostInitLua(element)
  local panelElement = element:E("Panel")
  local targetWidth = 60 * game.windowScaleY()
  local previousItem
  local spacingX = 5 * game.windowScaleY()
  local spacingY = 5 * game.windowScaleY()
  for i = 1, ITEMS_PER_PAGE do
    local item = menu:addTemplateElement("template_player_profile_fav_item", "item" .. i, panelElement)
    item("layer"):SetString("FrontPopUps")
    item:init()
    item:setPositionBroadcast(true)
    item("TargetLength"):SetFloat(targetWidth)
    local itemSprite = item:C("Sprite")
    itemSprite("spriteName"):SetString("gfx/breeding/monster_portrait_blank")
    itemSprite:DoStoredScript("refreshSize")
    item:setSize(lua_sys.Vector2(targetWidth, targetWidth))
    item:setSize(lua_sys.Vector2(itemSprite:absW(), itemSprite:absH()))
    if previousItem == nil then
      item:relativeTo(panelElement)
      item:setRelativeObjectAnchors(lua_sys.LEFT, lua_sys.TOP)
      item:setOrientation(lua_sys.MenuOrientation(spacingX * 1.5, spacingY * 3, -1, lua_sys.LEFT, lua_sys.TOP))
    elseif (i - 1) % ITEMS_PER_ROW == 0 then
      item:relativeTo(panelElement:E("item" .. i - ITEMS_PER_ROW))
      item:setRelativeObjectAnchors(lua_sys.RIGHT, lua_sys.BOTTOM)
      item:setOrientation(lua_sys.MenuOrientation(0, spacingY, 0, lua_sys.RIGHT, lua_sys.TOP))
    else
      item:relativeTo(previousItem)
      item:setRelativeObjectAnchors(lua_sys.RIGHT, lua_sys.VCENTER)
      item:setOrientation(lua_sys.MenuOrientation(spacingX, 0, 0, lua_sys.LEFT, lua_sys.VCENTER))
    end
    previousItem = item
  end
  UserProfileFavSelector.selectedSlot = game.getPlayerProfileFavoriteSlot()
  if UserProfileFavSelector.selectedSlot == "Island" then
    UserProfileFavSelector.allItems = game.islandAllOwnedSorting()
  else
    game.clearMonsterPortraitIds()
    UserProfileFavSelector.allItems = game.getAllMonsterPortraitIds()
  end
  UserProfileFavSelector.selectedId = game.getPlayerProfileFavoriteSlotItemId()
  for i = 0, UserProfileFavSelector.allItems:size() - 1 do
    if UserProfileFavSelector.selectedId == UserProfileFavSelector.allItems[i] then
      UserProfileFavSelector.PageNav.Current = math.floor(i / ITEMS_PER_PAGE)
      break
    end
  end
  UserProfileFavSelector.refreshMenu(element)
end
function UserProfileFavSelector.refreshMenu(element)
  UserProfileFavSelector.refreshItems(element)
  UserProfileFavSelector.updatePageNav(element)
end
function UserProfileFavSelector.refreshItems(element)
  local panelElement = element:E("Panel")
  local numItems = UserProfileFavSelector.allItems:size()
  UserProfileFavSelector.PageNav.Total = math.ceil(numItems / ITEMS_PER_PAGE)
  if UserProfileFavSelector.PageNav.Current >= UserProfileFavSelector.PageNav.Total then
    UserProfileFavSelector.PageNav.Current = UserProfileFavSelector.PageNav.Total - 1
  end
  local startItemIndex = UserProfileFavSelector.PageNav.Current * ITEMS_PER_PAGE
  local MonsterPortraits = include("MonsterPortraits")
  local image = ""
  for i = 1, ITEMS_PER_PAGE do
    local itemIndex = startItemIndex + i
    local item = panelElement:E("item" .. i)
    if itemIndex > 0 and numItems >= itemIndex then
      local itemId = UserProfileFavSelector.allItems[itemIndex - 1]
      item:DoStoredScript("setVisible")
      item("ItemId"):SetInt(itemId)
      local sprite = item:C("Sprite")
      local sheetSprite = item:C("SheetSprite")
      if UserProfileFavSelector.selectedSlot == "Island" then
        sheetSprite("sheetName"):SetString("xml_resources/" .. game.islandIconSheetForId(itemId))
        sheetSprite("spriteName"):SetString(game.islandIconSpriteForId(itemId))
        sheetSprite:DoStoredScript("refreshSize")
        sheetSprite("visible"):SetInt(1)
        sprite("visible"):SetInt(0)
      else
        image = MonsterPortraits:getDefaultMonsterPortrait(itemId)
        sprite("spriteName"):SetString(image)
        sprite:DoStoredScript("refreshSize")
        sprite("visible"):SetInt(1)
        sheetSprite("visible"):SetInt(0)
      end
      if itemId == UserProfileFavSelector.selectedId then
        item:DoStoredScript("select")
      else
        item:DoStoredScript("deselect")
      end
    else
      item:DoStoredScript("setInvisible")
    end
  end
end
function UserProfileFavSelector.selectItem(element, itemId)
  game.setPlayerProfileFavoriteSlot(UserProfileFavSelector.selectedSlot, itemId)
  element:closePopup()
end
function UserProfileFavSelector.updatePageNav(element)
  local panelElement = element:E("Panel")
  local previousButton = panelElement:E("PreviousButton")
  local nextButton = panelElement:E("NextButton")
  local pageLabel = panelElement:C("PageLabel")
  pageLabel("text"):SetString(UserProfileFavSelector.PageNav.Current + 1 .. "/" .. UserProfileFavSelector.PageNav.Total)
  pageLabel:setSize(Vector2(12 * game.windowScaleY(), 6 * game.windowScaleY()))
  pageLabel("size"):SetFloat(0.18 * game.windowScaleY())
  if 1 <= UserProfileFavSelector.PageNav.Total then
    previousButton:DoStoredScript("show")
    pageLabel:DoStoredScript("show")
    nextButton:DoStoredScript("show")
  else
    previousButton:DoStoredScript("hide")
    pageLabel:DoStoredScript("hide")
    nextButton:DoStoredScript("hide")
    return
  end
  if UserProfileFavSelector.PageNav.Current <= 0 then
    previousButton:DoStoredScript("disable")
  else
    previousButton:DoStoredScript("enable")
  end
  if UserProfileFavSelector.PageNav.Current + 1 >= UserProfileFavSelector.PageNav.Total then
    nextButton:DoStoredScript("disable")
  else
    nextButton:DoStoredScript("enable")
  end
end
function UserProfileFavSelector.previousPage(element)
  if UserProfileFavSelector.PageNav.Current < 1 then
    return
  end
  UserProfileFavSelector.PageNav.Current = UserProfileFavSelector.PageNav.Current - 1
  UserProfileFavSelector.updatePageNav(element)
  UserProfileFavSelector.refreshItems(element)
end
function UserProfileFavSelector.nextPage(element)
  if UserProfileFavSelector.PageNav.Current >= UserProfileFavSelector.PageNav.Total then
    return
  end
  UserProfileFavSelector.PageNav.Current = UserProfileFavSelector.PageNav.Current + 1
  UserProfileFavSelector.updatePageNav(element)
  UserProfileFavSelector.refreshItems(element)
end
return UserProfileFavSelector
