local MAX_ITEMS_PER_PAGE = 15
local ITEMS_PER_PAGE = 15
local ITEMS_PER_ROW = 5
local UserProfileEditor = {}
UserProfileEditor.PageNav = {Current = 1, Total = 1}
UserProfileEditor.allItems = nil
UserProfileEditor.filteredItems = nil
UserProfileEditor.currentTab = ""
UserProfileEditor.currentFavorites = {}
function UserProfileEditor.onInit(element)
  element:SetupGenericListener(game.engineReceiver(), "game::msg::MsgPlayerProfileUpdated", "gotMsgPlayerProfileUpdated")
  element:SetupGenericListener(game.engineReceiver(), "game::msg::MsgConfirmationSubmission", "gotMsgConfirmationSubmission")
  element:SetupGenericListener(game.engineReceiver(), "game::msg::MsgPlayerUpdated", "gotMsgPlayerUpdated")
  element:SetupGenericListener(game.engineReceiver(), "sys::msg::MsgPopPopUpGlobal", "gotMsgPopPopUpGlobal")
end
function UserProfileEditor.onPostInitLua(element)
  element("currentlySubmitting"):SetInt(0)
  local panelElement = element:E("Panel")
  local cardE = panelElement:E("Card")
  for i = 1, MAX_ITEMS_PER_PAGE do
    local item = menu:addTemplateElement("template_player_profile_item", "item" .. i, panelElement)
    item:init()
    item:setPositionBroadcast(true)
  end
  setAvatarItemLayout(element)
  UserProfileEditor.allItems = game.getSortedPlayerProfileItems()
  local playerProfile = game.playerProfile()
  cardE:SetView("EDIT", true)
  cardE:SetPlayerProfile(playerProfile, game.playerDisplayName())
  UserProfileEditor.currentFavorites.Moniker = playerProfile:getMonikerId()
  UserProfileEditor.currentFavorites.Monster1 = playerProfile:getFavMon1Id()
  UserProfileEditor.currentFavorites.Monster2 = playerProfile:getFavMon2Id()
  UserProfileEditor.currentFavorites.Monster3 = playerProfile:getFavMon3Id()
  UserProfileEditor.currentFavorites.Island = playerProfile:getFavIslandId()
  UserProfileEditor.selectTab(element, "TabAvatars")
end
function UserProfileEditor:gotMsgPlayerProfileUpdated(msg)
  game.popPopUp()
  manager:setContext("USER_PROFILE_MENU")
end
function UserProfileEditor:gotMsgPlayerUpdated(msg)
  if self("currentlySubmitting"):GetInt() == 1 then
    saveProfile(self)
  end
end
function UserProfileEditor:gotMsgConfirmationSubmission(msg)
  if msg.messageID == "CONFIRM_USER_PROFILE_SAVE" and msg.choice then
    self("currentlySubmitting"):SetInt(1)
    local socialCard = self:E("Panel"):E("Card")
    if game.playerDisplayName() ~= socialCard("DisplayNameText"):GetString() then
      game.setPlayerDisplayName(socialCard("DisplayNameText"):GetString())
    else
      saveProfile(self)
    end
  elseif msg.messageID == "CONFIRM_USER_PROFILE_CANCEL" and msg.choice then
    self("currentlySubmitting"):SetInt(0)
    game.popPopUp()
    manager:setContext("USER_PROFILE_MENU")
  end
end
function UserProfileEditor:gotMsgPopPopUpGlobal(msg)
  if msg.menuName == "user_profile_fav_select" or msg.menuName == "moniker_select" then
    self.currentFavorites[game.getPlayerProfileFavoriteSlot()] = game.getPlayerProfileFavoriteSlotItemId()
    game.setPlayerProfileFavoriteSlot("", 0)
    self:refreshItems()
  end
end
function saveProfile(element)
  local profile = game.playerProfile()
  local socialCard = element:E("Panel"):E("Card")
  local profilePic = socialCard:E("ProfilePic")
  profile:setMonikerId(UserProfileEditor.currentFavorites.Moniker)
  profile:setFavMon1Id(UserProfileEditor.currentFavorites.Monster1)
  profile:setFavMon2Id(UserProfileEditor.currentFavorites.Monster2)
  profile:setFavMon3Id(UserProfileEditor.currentFavorites.Monster3)
  profile:setFavIslandId(UserProfileEditor.currentFavorites.Island)
  profile:setAvatarId(profilePic.currentAvatarConfig.Avatar)
  profile:setFrameId(profilePic.currentAvatarConfig.Frame)
  profile:setBGId(profilePic.currentAvatarConfig.Background)
  profile:setCardId(socialCard.currentCardId)
  profile:setPhraseId(socialCard.currentPhraseId)
  game.setPlayerProfile(profile)
  element("currentlySubmitting"):SetInt(0)
end
function setFavoritesItemLayout(element)
  local panelElement = element:E("Panel")
  panelElement:E("Favorites"):DoStoredScript("setVisible")
  local monikerE = panelElement:E("Moniker")
  if game.playerLevel() < 30 then
    monikerE:DoStoredScript("setInvisible")
  else
    monikerE:DoStoredScript("setVisible")
  end
end
function setAvatarItemLayout(element)
  local panelElement = element:E("Panel")
  TARGET_WIDTH = 40 * game.windowScaleY()
  local scale = 0
  local previousItem
  local spacingX = 10 * game.windowScaleY()
  local spacingY = 10 * game.windowScaleY()
  for i = 1, MAX_ITEMS_PER_PAGE do
    local item = panelElement:E("item" .. i)
    item:setSize(lua_sys.Vector2(TARGET_WIDTH, TARGET_WIDTH))
    item("TargetLength"):SetFloat(TARGET_WIDTH)
    local itemSprite = item:C("Sprite")
    itemSprite:setScale(lua_sys.Vector2(1, 1))
    if scale == 0 then
      local scaleW = TARGET_WIDTH / itemSprite:absW()
      local scaleH = TARGET_WIDTH / itemSprite:absH()
      scale = math.min(scaleW, scaleH)
    end
    itemSprite:setScale(lua_sys.Vector2(scale, scale))
    if previousItem == nil then
      item:relativeTo(panelElement:C("ItemBackdrop"))
      item:setRelativeObjectAnchors(lua_sys.LEFT, lua_sys.TOP)
      item:setOrientation(lua_sys.MenuOrientation(spacingX * 0.5, 20 * game.windowScaleY() + spacingY * 0.5, -2, lua_sys.LEFT, lua_sys.TOP))
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
end
function setPhraseLayout(element)
  local panelElement = element:E("Panel")
  TARGET_WIDTH = 120 * game.windowScaleY()
  local scale = 0
  local previousItem
  local spacingX = 6 * game.windowScaleY()
  local spacingY = 4 * game.windowScaleY()
  for i = 1, MAX_ITEMS_PER_PAGE do
    local item = panelElement:E("item" .. i)
    item("TargetLength"):SetFloat(TARGET_WIDTH)
    local itemSprite = item:C("Sprite")
    if scale == 0 then
      itemSprite:setScale(lua_sys.Vector2(1, 1))
      scale = TARGET_WIDTH / itemSprite:absW()
    end
    itemSprite:setScale(lua_sys.Vector2(scale, scale))
    item:setSize(lua_sys.Vector2(itemSprite:absW(), itemSprite:absH()))
    if previousItem == nil then
      item:relativeTo(panelElement:C("ItemBackdrop"))
      item:setRelativeObjectAnchors(lua_sys.LEFT, lua_sys.TOP)
      item:setOrientation(lua_sys.MenuOrientation(spacingX * 0.5, 20 * game.windowScaleY() + spacingY * 0.5, -2, lua_sys.LEFT, lua_sys.TOP))
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
end
function setCardLayout(element)
  local panelElement = element:E("Panel")
  TARGET_WIDTH = 40 * game.windowScaleY()
  local scale = 0
  local previousItem
  local spacingX = 10 * game.windowScaleY()
  local spacingY = 10 * game.windowScaleY()
  for i = 1, MAX_ITEMS_PER_PAGE do
    local item = panelElement:E("item" .. i)
    item("TargetLength"):SetFloat(TARGET_WIDTH)
    local itemSprite = item:C("Sprite")
    if scale == 0 then
      itemSprite:setScale(lua_sys.Vector2(1, 1))
      scale = TARGET_WIDTH / itemSprite:absW()
    end
    itemSprite:setScale(lua_sys.Vector2(scale, scale))
    item:setSize(lua_sys.Vector2(itemSprite:absW(), itemSprite:absH()))
    if previousItem == nil then
      item:relativeTo(panelElement:C("ItemBackdrop"))
      item:setRelativeObjectAnchors(lua_sys.LEFT, lua_sys.TOP)
      item:setOrientation(lua_sys.MenuOrientation(spacingX * 0.5, 20 * game.windowScaleY() + spacingY * 0.5, -2, lua_sys.LEFT, lua_sys.TOP))
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
end
function updatePageSizes(element)
  if UserProfileEditor.currentTab == "TabPremiumAvatars" or UserProfileEditor.currentTab == "TabAvatars" or UserProfileEditor.currentTab == "TabFrames" or UserProfileEditor.currentTab == "TabBackgrounds" then
    ITEMS_PER_PAGE = 15
    ITEMS_PER_ROW = 5
  elseif UserProfileEditor.currentTab == "TabCards" then
    ITEMS_PER_PAGE = 10
    ITEMS_PER_ROW = 5
  elseif UserProfileEditor.currentTab == "TabPhrases" then
    ITEMS_PER_PAGE = 12
    ITEMS_PER_ROW = 2
  elseif UserProfileEditor.currentTab == "TabFavorites" then
    ITEMS_PER_PAGE = 1
    ITEMS_PER_ROW = 1
  end
end
function UserProfileEditor.selectTab(element, tab)
  if UserProfileEditor.currentTab ~= tab then
    UserProfileEditor.currentTab = tab
    UserProfileEditor.PageNav.Current = -1
    updatePageSizes(element)
    UserProfileEditor.refreshMenu(element)
  end
  local panelElement = element:E("Panel")
  panelElement:E("TabFavorites"):DoStoredScript("deselectTab")
  panelElement:E("TabPremiumAvatars"):DoStoredScript("deselectTab")
  panelElement:E("TabAvatars"):DoStoredScript("deselectTab")
  panelElement:E("TabFrames"):DoStoredScript("deselectTab")
  panelElement:E("TabBackgrounds"):DoStoredScript("deselectTab")
  panelElement:E("TabCards"):DoStoredScript("deselectTab")
  panelElement:E("TabPhrases"):DoStoredScript("deselectTab")
  panelElement:E(UserProfileEditor.currentTab):DoStoredScript("selectTab")
  panelElement:E("Moniker"):DoStoredScript("setInvisible")
  panelElement:E("Favorites"):DoStoredScript("setInvisible")
  local groupLabel = panelElement:C("TypeLabel")
  groupLabel("text"):SetString("")
  groupLabel("width"):SetFloat(72 * game.windowScaleY())
  groupLabel("size"):SetFloat(0.2 * game.windowScaleY())
  if UserProfileEditor.currentTab == "TabPremiumAvatars" then
    groupLabel("text"):SetString("PROFILE_EDITOR_PREMIUM")
    setAvatarItemLayout(element)
  elseif UserProfileEditor.currentTab == "TabAvatars" then
    groupLabel("text"):SetString("PROFILE_EDITOR_AVATARS")
    setAvatarItemLayout(element)
  elseif UserProfileEditor.currentTab == "TabFrames" then
    groupLabel("text"):SetString("PROFILE_EDITOR_FRAMES")
    setAvatarItemLayout(element)
  elseif UserProfileEditor.currentTab == "TabBackgrounds" then
    groupLabel("text"):SetString("PROFILE_EDITOR_BACKGROUNDS")
    setAvatarItemLayout(element)
  elseif UserProfileEditor.currentTab == "TabCards" then
    groupLabel("text"):SetString("PROFILE_EDITOR_CARDS")
    setCardLayout(element)
  elseif UserProfileEditor.currentTab == "TabPhrases" then
    groupLabel("text"):SetString("PROFILE_EDITOR_PHRASES")
    setPhraseLayout(element)
  elseif UserProfileEditor.currentTab == "TabFavorites" then
    groupLabel("text"):SetString("PROFILE_EDITOR_FAVORITES")
    setFavoritesItemLayout(element)
  end
end
function UserProfileEditor.refreshMenu(element)
  local typeLookingFor
  UserProfileEditor.filteredItems = {}
  if UserProfileEditor.currentTab == "TabPremiumAvatars" then
    typeLookingFor = game.PlayerProfileItemType_PREMIUM
  elseif UserProfileEditor.currentTab == "TabAvatars" then
    typeLookingFor = game.PlayerProfileItemType_AVATAR
  elseif UserProfileEditor.currentTab == "TabFrames" then
    typeLookingFor = game.PlayerProfileItemType_FRAME
  elseif UserProfileEditor.currentTab == "TabBackgrounds" then
    typeLookingFor = game.PlayerProfileItemType_BACKGROUND
  elseif UserProfileEditor.currentTab == "TabCards" then
    typeLookingFor = game.PlayerProfileItemType_CARD
  elseif UserProfileEditor.currentTab == "TabPhrases" then
    typeLookingFor = game.PlayerProfileItemType_PHRASE
  elseif UserProfileEditor.currentTab == "TabFavorites" then
    typeLookingFor = nil
  end
  if typeLookingFor ~= nil then
    local typeFound = false
    for i = 0, UserProfileEditor.allItems:size() - 1 do
      local item = UserProfileEditor.allItems[i]
      if typeLookingFor == item:getItemType() then
        table.insert(UserProfileEditor.filteredItems, item)
        typeFound = true
      elseif typeFound then
        break
      end
    end
  end
  UserProfileEditor.refreshItems(element)
  UserProfileEditor.updatePageNav(element)
end
function UserProfileEditor.refreshItems(element)
  local panelElement = element:E("Panel")
  local numItems = #UserProfileEditor.filteredItems
  local selectedItemId = getSelectedItemIdForTab(element)
  if UserProfileEditor.PageNav.Current == -1 then
    UserProfileEditor.PageNav.Current = 0
    for i = 1, #UserProfileEditor.filteredItems do
      if selectedItemId == UserProfileEditor.filteredItems[i]:getItemId() then
        UserProfileEditor.PageNav.Current = math.floor((i - 1) / ITEMS_PER_PAGE)
        break
      end
    end
  end
  UserProfileEditor.PageNav.Total = math.ceil(numItems / ITEMS_PER_PAGE)
  if UserProfileEditor.PageNav.Current >= UserProfileEditor.PageNav.Total then
    UserProfileEditor.PageNav.Current = UserProfileEditor.PageNav.Total - 1
  end
  local warningFadedBG = panelElement:E("WarningFadedBG")
  local warningText = panelElement:C("WarningText")
  if numItems == 0 and UserProfileEditor.currentTab ~= "TabFavorites" then
    warningText("visible"):SetInt(1)
    if UserProfileEditor.currentTab == "TabPremiumAvatars" then
      warningText("text"):SetString("PROFILE_EDITOR_NO_PREMIUM_ITEMS")
    else
      warningText("text"):SetString("PROFILE_EDITOR_NO_ITEMS")
    end
  elseif UserProfileEditor.currentTab == "TabFrames" or UserProfileEditor.currentTab == "TabBackgrounds" then
    local socialCard = element:E("Panel"):E("Card")
    local profilePic = socialCard:E("ProfilePic")
    local playerProfileItem = game.getPlayerProfileItem(profilePic.currentAvatarConfig.Avatar)
    if playerProfileItem:getItemType() == game.PlayerProfileItemType_PREMIUM then
      warningText("visible"):SetInt(1)
      warningFadedBG:DoStoredScript("show")
      if UserProfileEditor.currentTab == "TabFrames" then
        warningText("text"):SetString("PLAYER_PROFILE_FRAME_WARNING")
      elseif UserProfileEditor.currentTab == "TabBackgrounds" then
        warningText("text"):SetString("PLAYER_PROFILE_BACKGROUND_WARNING")
      end
    else
      warningText("visible"):SetInt(0)
      warningFadedBG:DoStoredScript("hide")
    end
  else
    warningText("visible"):SetInt(0)
    warningFadedBG:DoStoredScript("hide")
  end
  local startItemIndex = UserProfileEditor.PageNav.Current * ITEMS_PER_PAGE
  local palette = include("ColourPalette")
  local lastGoodSprite = ""
  for i = 1, MAX_ITEMS_PER_PAGE do
    local itemIndex = startItemIndex + i
    local item = panelElement:E("item" .. i)
    if itemIndex > 0 and numItems >= itemIndex and i <= ITEMS_PER_PAGE then
      local playerItem = UserProfileEditor.filteredItems[itemIndex]
      item:DoStoredScript("setVisible")
      local itemId = playerItem:getItemId()
      item("ItemId"):SetInt(itemId)
      if itemId == selectedItemId then
        item:DoStoredScript("select")
      else
        item:DoStoredScript("deselect")
      end
      local sprite = item:C("Sprite")
      local text = item:C("Text")
      if UserProfileEditor.currentTab == "TabPhrases" then
        sprite("spriteName"):SetString("gfx/menu/social/PurpleBanner")
        lastGoodSprite = "gfx/menu/social/PurpleBanner"
        sprite:setColor(1, 1, 1)
        text("visible"):SetInt(1)
        text("text"):SetString("")
        text("width"):SetFloat(100 * game.windowScaleY())
        text("size"):SetFloat(0.25 * game.windowScaleY())
        text("text"):SetString(playerItem:getTextId())
      else
        local assetPath = playerItem:getAssetPath()
        if assetPath ~= "" then
          sprite("spriteName"):SetString(assetPath)
          lastGoodSprite = assetPath
          sprite:setColor(1, 1, 1)
        end
        local colorCode = playerItem:getColorCode()
        if colorCode ~= "" then
          sprite("spriteName"):SetString("__BUILTIN__WHITE_TEXTURE")
          lastGoodSprite = "__BUILTIN__WHITE_TEXTURE"
          sprite:setColor(palette:getRGBFloats(colorCode))
        end
        text("visible"):SetInt(0)
      end
    else
      item:DoStoredScript("setInvisible")
      if lastGoodSprite ~= "" then
        item:C("Sprite")("spriteName"):SetString(lastGoodSprite)
      end
    end
  end
  if UserProfileEditor.currentTab == "TabFavorites" then
    local monikerE = panelElement:E("Moniker")
    if game.playerLevel() >= 30 then
      if 0 < UserProfileEditor.currentFavorites.Moniker then
        monikerE:C("Text")("text"):SetString(game.getMonikerText(UserProfileEditor.currentFavorites.Moniker))
      else
        monikerE:C("Text")("text"):SetString(game.getMonikerText(game.playerLevel()))
      end
    end
    local favoritesE = panelElement:E("Favorites")
    local MonsterPortraits = include("MonsterPortraits")
    local image = ""
    if 0 >= UserProfileEditor.currentFavorites.Monster1 then
      image = "gfx/breeding/monster_portrait_blank"
    else
      image = MonsterPortraits:getDefaultMonsterPortrait(UserProfileEditor.currentFavorites.Monster1)
    end
    favoritesE:E("Monster1"):C("Sprite")("spriteName"):SetString(image)
    if 0 >= UserProfileEditor.currentFavorites.Monster2 then
      image = "gfx/breeding/monster_portrait_blank"
    else
      image = MonsterPortraits:getDefaultMonsterPortrait(UserProfileEditor.currentFavorites.Monster2)
    end
    favoritesE:E("Monster2"):C("Sprite")("spriteName"):SetString(image)
    if 0 >= UserProfileEditor.currentFavorites.Monster3 then
      image = "gfx/breeding/monster_portrait_blank"
    else
      image = MonsterPortraits:getDefaultMonsterPortrait(UserProfileEditor.currentFavorites.Monster3)
    end
    favoritesE:E("Monster3"):C("Sprite")("spriteName"):SetString(image)
    local sheet = ""
    if 0 >= UserProfileEditor.currentFavorites.Island then
      image = "islands_button_isl01"
      sheet = "xml_resources/island_buttons01.xml"
    else
      image = game.islandIconSpriteForId(UserProfileEditor.currentFavorites.Island)
      sheet = "xml_resources/" .. game.islandIconSheetForId(UserProfileEditor.currentFavorites.Island)
    end
    favoritesE:E("Island"):C("Sprite")("spriteName"):SetString(image)
    favoritesE:E("Island"):C("Sprite")("sheetName"):SetString(sheet)
  end
end
function getSelectedItemIdForTab(element)
  local socialCard = element:E("Panel"):E("Card")
  local profilePic = socialCard:E("ProfilePic")
  local selectedItemId = 0
  if UserProfileEditor.currentTab == "TabPremiumAvatars" or UserProfileEditor.currentTab == "TabAvatars" then
    selectedItemId = profilePic.currentAvatarConfig.Avatar
  elseif UserProfileEditor.currentTab == "TabFrames" then
    selectedItemId = profilePic.currentAvatarConfig.Frame
  elseif UserProfileEditor.currentTab == "TabBackgrounds" then
    selectedItemId = profilePic.currentAvatarConfig.Background
  elseif UserProfileEditor.currentTab == "TabCards" then
    selectedItemId = socialCard.currentCardId
  elseif UserProfileEditor.currentTab == "TabPhrases" then
    selectedItemId = socialCard.currentPhraseId
  end
  return selectedItemId
end
function UserProfileEditor.selectItem(element, itemId)
  if element:E("Panel"):E("Card"):SetPlayerProfileItem(itemId) then
    UserProfileEditor.refreshItems(element)
  end
end
function UserProfileEditor.OnFavouriteItemSelected(element, slot)
  game.setPlayerProfileFavoriteSlot(slot, UserProfileEditor.currentFavorites[slot])
  game.pushPopUp("user_profile_fav_select")
end
function UserProfileEditor.updatePageNav(element)
  local panelElement = element:E("Panel")
  local previousButton = panelElement:E("PreviousButton")
  local nextButton = panelElement:E("NextButton")
  local pageLabel = panelElement:C("PageLabel")
  local firstButton = panelElement:E("FirstPageButton")
  local lastButton = panelElement:E("LastPageButton")
  if UserProfileEditor.PageNav.Total ~= UserProfileEditor.PageNav.Total or UserProfileEditor.PageNav.Current ~= UserProfileEditor.PageNav.Current then
    firstButton:DoStoredScript("hide")
    previousButton:DoStoredScript("hide")
    pageLabel:DoStoredScript("hide")
    nextButton:DoStoredScript("hide")
    lastButton:DoStoredScript("hide")
    return
  end
  pageLabel("text"):SetString(UserProfileEditor.PageNav.Current + 1 .. "/" .. UserProfileEditor.PageNav.Total)
  pageLabel:setSize(Vector2(12 * game.windowScaleY(), 6 * game.windowScaleY()))
  pageLabel("size"):SetFloat(0.18 * game.windowScaleY())
  if UserProfileEditor.PageNav.Total >= 1 then
    firstButton:DoStoredScript("show")
    previousButton:DoStoredScript("show")
    pageLabel:DoStoredScript("show")
    nextButton:DoStoredScript("show")
    lastButton:DoStoredScript("show")
  else
    firstButton:DoStoredScript("hide")
    previousButton:DoStoredScript("hide")
    pageLabel:DoStoredScript("hide")
    nextButton:DoStoredScript("hide")
    lastButton:DoStoredScript("hide")
    return
  end
  if UserProfileEditor.PageNav.Current <= 0 then
    firstButton:DoStoredScript("disable")
    previousButton:DoStoredScript("disable")
  else
    firstButton:DoStoredScript("enable")
    previousButton:DoStoredScript("enable")
  end
  if UserProfileEditor.PageNav.Current + 1 >= UserProfileEditor.PageNav.Total then
    nextButton:DoStoredScript("disable")
    lastButton:DoStoredScript("disable")
  else
    nextButton:DoStoredScript("enable")
    lastButton:DoStoredScript("enable")
  end
end
function UserProfileEditor.previousPage(element)
  if UserProfileEditor.PageNav.Current < 1 then
    return
  end
  UserProfileEditor.PageNav.Current = UserProfileEditor.PageNav.Current - 1
  UserProfileEditor.updatePageNav(element)
  UserProfileEditor.refreshItems(element)
end
function UserProfileEditor.nextPage(element)
  if UserProfileEditor.PageNav.Current >= UserProfileEditor.PageNav.Total then
    return
  end
  UserProfileEditor.PageNav.Current = UserProfileEditor.PageNav.Current + 1
  UserProfileEditor.updatePageNav(element)
  UserProfileEditor.refreshItems(element)
end
function UserProfileEditor.firstPage(element)
  if UserProfileEditor.PageNav.Current < 1 then
    return
  end
  UserProfileEditor.PageNav.Current = 0
  UserProfileEditor.updatePageNav(element)
  UserProfileEditor.refreshItems(element)
end
function UserProfileEditor.lastPage(element)
  if UserProfileEditor.PageNav.Current >= UserProfileEditor.PageNav.Total then
    return
  end
  UserProfileEditor.PageNav.Current = UserProfileEditor.PageNav.Total - 1
  UserProfileEditor.updatePageNav(element)
  UserProfileEditor.refreshItems(element)
end
return UserProfileEditor
