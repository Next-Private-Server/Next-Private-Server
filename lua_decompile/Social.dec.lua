local CARDS_PER_PAGE = -1
local MIN_CARD_SPACING = 8
local PANEL_MAX_WIDTH_RATIO = 2.25
local Social = {}
Social.Sorting = {}
Social.currentTab = ""
Social.filteredUsers = nil
Social.topIslands = nil
local sortButtons = {
  "SortAlpha",
  "SortActivity",
  "SortLevel",
  "SortTorches"
}
function Social.onInit(element)
  element:SetupGenericListener(game.engineReceiver(), "game::msg::MsgGameFriendsSynced", "gotMsgGameFriendsSynced")
  element:SetupGenericListener(game.engineReceiver(), "game::msg::MsgFriendsUpdated", "gotMsgFriendsUpdated")
  element:SetupGenericListener(game.engineReceiver(), "game::msg::MsgPlayerFriendCodeUpdated", "gotMsgPlayerFriendCodeUpdated")
  element:SetupGenericListener(game.engineReceiver(), "game::msg::MsgTop10IslandsUpdated", "gotMsgTop10IslandsUpdated")
  element:SetupGenericListener(game.engineReceiver(), "game::msg::MsgNoRankedIslands", "gotMsgNoRankedIslands")
  element:SetupGenericListener(game.engineReceiver(), "game::msg::MsgLightTorch", "gotMsgLightTorch")
  local panelElement = element:E("Panel")
  local ratio = panelElement:absW() / panelElement:absH()
  if ratio > PANEL_MAX_WIDTH_RATIO then
    panelElement:setSize(Vector2(panelElement:absH() * PANEL_MAX_WIDTH_RATIO, panelElement:absH()))
    panelElement:C("bg"):setSize(Vector2(panelElement:absH() * PANEL_MAX_WIDTH_RATIO, panelElement:absH()))
    panelElement:E("TopIslands"):E("List"):setSize(Vector2(panelElement:absH() * PANEL_MAX_WIDTH_RATIO - 36 * game.windowScaleY(), 170 * game.windowScaleY()))
  end
  local halfPanelW = panelElement:absW() * 0.5 - 10 * game.windowScaleY()
  local halfPanelH = panelElement:absH() * 0.5 - 8 * game.windowScaleY()
  local halfScreenW = (lua_sys.screenWidth() - lua_sys.deviceMarginX()) * 0.5
  local halfScreenH = (lua_sys.screenHeight() - lua_sys.deviceMarginY()) * 0.5
  local contextButtonSize = 70 * game.hudScale()
  local contextButtonXOffset = 3 * game.hudScale()
  local contextButtonYOffset = 12 * game.hudScale()
  local buttonOverlapX = halfPanelW - (halfScreenW - contextButtonSize - contextButtonXOffset)
  local buttonOverlapY = halfPanelH - (halfScreenH - contextButtonSize - contextButtonYOffset)
  if buttonOverlapX > 10 and buttonOverlapY > 10 then
    local nextButton = panelElement:E("NextButton")
    nextButton:GetVar("xOffset"):SetFloat(nextButton:GetVar("xOffset"):GetFloat() + buttonOverlapX)
    local pageLabel = panelElement:C("PageLabel")
    pageLabel:GetVar("xOffset"):SetFloat(pageLabel:GetVar("xOffset"):GetFloat() - buttonOverlapX)
  end
  local previousCard
  local spacing = 0
  for i = 1, 10 do
    local cardItem = menu:addTemplateElement("template_social_card", "cardItem" .. i, panelElement)
    cardItem:init()
    cardItem:setPositionBroadcast(true)
    if CARDS_PER_PAGE == -1 then
      CARDS_PER_PAGE = math.floor((panelElement:absW() - MIN_CARD_SPACING - 4 * game.windowScaleY()) / (cardItem:absW() + MIN_CARD_SPACING))
      local diff = panelElement:absW() - CARDS_PER_PAGE * cardItem:absW()
      spacing = diff / (CARDS_PER_PAGE + 1)
    end
    if previousCard == nil then
      cardItem:relativeTo(panelElement)
      cardItem:setRelativeObjectAnchors(lua_sys.LEFT, lua_sys.VCENTER)
      cardItem:setOrientation(lua_sys.MenuOrientation(spacing, -8 * game.windowScaleY(), -1, lua_sys.LEFT, lua_sys.VCENTER))
    else
      cardItem:relativeTo(previousCard)
      cardItem:setRelativeObjectAnchors(lua_sys.RIGHT, lua_sys.VCENTER)
      cardItem:setOrientation(lua_sys.MenuOrientation(spacing, 0, 0, lua_sys.LEFT, lua_sys.VCENTER))
    end
    if i >= CARDS_PER_PAGE then
      break
    end
    previousCard = cardItem
  end
  element:refreshTabAlerts()
end
function Social.onPostInitLua(element)
  Social.loadFilterAndSorting(element, game.getLastFriendMenuTab())
end
function Social:gotMsgGameFriendsSynced(msg)
  self.filteredUsers = nil
  self:refreshFriendCards()
  self:updatePageNav()
  self:refreshTabAlerts()
end
function Social:gotMsgFriendsUpdated(msg)
  self.filteredUsers = nil
  self:refreshFriendCards()
  self:updatePageNav()
  self:refreshTabAlerts()
end
function Social:gotMsgPlayerFriendCodeUpdated(msg)
  self:updateFriendCode()
end
function Social:gotMsgTop10IslandsUpdated(msg)
  self.topIslands = game.getTop10Islands(Social.Sorting[Social.currentTab].Filters.Islands == "IslandsComposer")
  self:refreshTopIslands()
end
function Social:gotMsgNoRankedIslands(msg)
  self.topIslands = nil
  self:refreshTopIslands()
end
function Social:gotMsgLightTorch(msg)
  game.displayNotification("NOTIFICATION_TORCH_LIT")
  self.filteredUsers = nil
  self:refreshFriendCards()
  self:updatePageNav()
end
function Social.loadFilterAndSorting(element, payload)
  Social.Sorting.TabFriends = {
    Filters = {FavouritesOnly = false, TorchesOnly = false},
    Ascending = true,
    Method = "alpha",
    PageNav = {Current = -1, Total = 1}
  }
  Social.Sorting.TabTopIslands = {
    Filters = {
      Islands = "IslandsMain"
    },
    PageNav = {Current = -1, Total = 1}
  }
  Social.Sorting.TabRequests = {
    Filters = {RequestsIncoming = true},
    PageNav = {Current = -1, Total = 1}
  }
  local count = 0
  local selectedTab = ""
  for i in string.gmatch(payload, "([^|]+)") do
    if count == 0 then
      Social.Sorting.TabFriends.Filters.FavouritesOnly = i == "1"
    elseif count == 1 then
      Social.Sorting.TabFriends.Filters.TorchesOnly = i == "1"
    elseif count == 2 then
      Social.Sorting.TabFriends.Ascending = i == "1"
    elseif count == 3 then
      Social.Sorting.TabFriends.Method = i
    elseif count == 4 then
      Social.Sorting.TabFriends.PageNav.Current = tonumber(i)
    elseif count == 5 then
      Social.Sorting.TabTopIslands.Filters.Islands = i
    elseif count == 6 then
      Social.Sorting.TabTopIslands.PageNav.Current = tonumber(i)
    elseif count == 7 then
      Social.Sorting.TabRequests.Filters.RequestsIncoming = i == "1"
    elseif count == 8 then
      Social.Sorting.TabRequests.PageNav.Current = tonumber(i)
    elseif count == 9 then
      selectedTab = i
    else
      break
    end
    count = count + 1
  end
  if selectedTab == "" then
    selectedTab = "TabFriends"
  end
  Social.selectTab(element, selectedTab)
end
function Social.saveFilterAndSorting()
  local payload = ""
  payload = payload .. (Social.Sorting.TabFriends.Filters.FavouritesOnly and "1" or "0") .. "|"
  payload = payload .. (Social.Sorting.TabFriends.Filters.TorchesOnly and "1" or "0") .. "|"
  payload = payload .. (Social.Sorting.TabFriends.Ascending and "1" or "0") .. "|"
  payload = payload .. Social.Sorting.TabFriends.Method .. "|"
  payload = payload .. Social.Sorting.TabFriends.PageNav.Current .. "|"
  payload = payload .. Social.Sorting.TabTopIslands.Filters.Islands .. "|"
  payload = payload .. Social.Sorting.TabTopIslands.PageNav.Current .. "|"
  payload = payload .. (Social.Sorting.TabRequests.Filters.RequestsIncoming and "1" or "0") .. "|"
  payload = payload .. Social.Sorting.TabRequests.PageNav.Current .. "|"
  payload = payload .. Social.currentTab
  game.setLastFriendMenuTab(payload)
  return payload
end
function Social.selectTab(element, tab)
  if Social.currentTab ~= tab then
    Social.currentTab = tab
    Social.refreshMenu(element)
    Social.saveFilterAndSorting()
  end
  local panelElement = element:E("Panel")
  panelElement:E("TabFriends"):DoStoredScript("deselectTab")
  panelElement:E("TabTopIslands"):DoStoredScript("deselectTab")
  panelElement:E("TabRequests"):DoStoredScript("deselectTab")
  panelElement:E(Social.currentTab):DoStoredScript("selectTab")
end
function Social.refreshTabAlerts(element)
  local panelElement = element:E("Panel")
  panelElement:E("TabFriends"):E("Alert"):DoStoredScript("setInvisible")
  panelElement:E("TabTopIslands"):E("Alert"):DoStoredScript("setInvisible")
  if game.hasIncomingFriendRequest() then
    panelElement:E("TabRequests"):E("Alert"):DoStoredScript("setVisible")
  else
    panelElement:E("TabRequests"):E("Alert"):DoStoredScript("setInvisible")
  end
end
function Social.refreshMenu(element)
  Social.filteredUsers = nil
  Social.refreshFriendCards(element)
  Social.updatePageNav(element)
  local panelElement = element:E("Panel")
  local topIslands = panelElement:E("TopIslands")
  local previousNumItems = topIslands("NumEntries"):GetInt()
  if previousNumItems > 0 then
    for i = 1, previousNumItems do
      topIslands:RemoveElement(topIslands:E("topIslandEntry" .. i))
    end
  end
  if Social.currentTab == "TabFriends" then
    panelElement:E("FriendCode"):DoStoredScript("setVisible")
    panelElement:E("RequestsIncoming"):DoStoredScript("setInvisible")
    panelElement:E("RequestsSent"):DoStoredScript("setInvisible")
    panelElement:E("IslandsMain"):DoStoredScript("setInvisible")
    panelElement:E("IslandsComposer"):DoStoredScript("setInvisible")
    panelElement:E("IslandsTribal"):DoStoredScript("setInvisible")
    panelElement:E("IslandVoting"):DoStoredScript("setInvisible")
    panelElement:E("TopIslands"):DoStoredScript("hide")
    panelElement:C("IslandResetInfo"):DoStoredScript("hide")
    panelElement:E("InviteFriends"):DoStoredScript("setVisible")
    panelElement:E("FindFriends"):DoStoredScript("setVisible")
    panelElement:C("FilterIcon")("visible"):SetInt(1)
    panelElement:C("SortIcon")("visible"):SetInt(1)
    panelElement:E("FilterFavourites"):DoStoredScript("setVisible")
    panelElement:E("FilterTorch"):DoStoredScript("setVisible")
    for i = 1, #sortButtons do
      panelElement:E(sortButtons[i]):DoStoredScript("setVisible")
    end
    panelElement:C("FriendCountLabel"):DoStoredScript("show")
    panelElement:E("FilterFavourites"):DoStoredScript(Social.Sorting[Social.currentTab].Filters.FavouritesOnly and "select" or "deselect")
    panelElement:E("FilterTorch"):DoStoredScript(Social.Sorting[Social.currentTab].Filters.TorchesOnly and "select" or "deselect")
    local isAlphaSort = Social.Sorting[Social.currentTab].Method == "alpha"
    local isActivitySort = Social.Sorting[Social.currentTab].Method == "activity"
    local isLevelSort = Social.Sorting[Social.currentTab].Method == "level"
    local isTorchesSort = Social.Sorting[Social.currentTab].Method == "torches"
    panelElement:E("SortAlpha"):DoStoredScript(isAlphaSort and "select" or "deselect")
    panelElement:E("SortActivity"):DoStoredScript(isActivitySort and "select" or "deselect")
    panelElement:E("SortLevel"):DoStoredScript(isLevelSort and "select" or "deselect")
    panelElement:E("SortTorches"):DoStoredScript(isTorchesSort and "select" or "deselect")
    if isAlphaSort then
      panelElement:E("SortAlpha"):DoStoredScript(Social.Sorting[Social.currentTab].Ascending and "setAscend" or "setDescend")
    elseif isActivitySort then
      panelElement:E("SortActivity"):DoStoredScript(Social.Sorting[Social.currentTab].Ascending and "setAscend" or "setDescend")
    elseif isLevelSort then
      panelElement:E("SortLevel"):DoStoredScript(Social.Sorting[Social.currentTab].Ascending and "setAscend" or "setDescend")
    elseif isTorchesSort then
      panelElement:E("SortTorches"):DoStoredScript(Social.Sorting[Social.currentTab].Ascending and "setAscend" or "setDescend")
    end
  elseif Social.currentTab == "TabRequests" then
    panelElement:E("FriendCode"):DoStoredScript("setVisible")
    panelElement:E("RequestsIncoming"):DoStoredScript("setVisible")
    panelElement:E("RequestsSent"):DoStoredScript("setVisible")
    panelElement:E("IslandsMain"):DoStoredScript("setInvisible")
    panelElement:E("IslandsComposer"):DoStoredScript("setInvisible")
    panelElement:E("IslandsTribal"):DoStoredScript("setInvisible")
    panelElement:E("IslandVoting"):DoStoredScript("setInvisible")
    panelElement:E("TopIslands"):DoStoredScript("hide")
    panelElement:C("IslandResetInfo"):DoStoredScript("hide")
    panelElement:E("InviteFriends"):DoStoredScript("setVisible")
    panelElement:E("FindFriends"):DoStoredScript("setVisible")
    panelElement:C("FilterIcon")("visible"):SetInt(0)
    panelElement:C("SortIcon")("visible"):SetInt(0)
    panelElement:E("FilterFavourites"):DoStoredScript("setInvisible")
    panelElement:E("FilterTorch"):DoStoredScript("setInvisible")
    for i = 1, #sortButtons do
      panelElement:E(sortButtons[i]):DoStoredScript("setInvisible")
    end
    local filterName = Social.Sorting[Social.currentTab].Filters.RequestsIncoming and "RequestsIncoming" or "RequestsSent"
    local buttonTabs = {
      "RequestsIncoming",
      "RequestsSent"
    }
    for i = 1, #buttonTabs do
      local button = panelElement:E(buttonTabs[i])
      if buttonTabs[i] == filterName then
        button:C("UpSprite")("spriteName"):SetString("gfx/menu/button_vert_square01_green")
        button:C("Touch")("enabled"):SetInt(0)
      else
        button:C("UpSprite")("spriteName"):SetString("gfx/menu/button_vert_square01")
        button:C("Touch")("enabled"):SetInt(1)
      end
    end
    panelElement:C("FriendCountLabel"):DoStoredScript("show")
  elseif Social.currentTab == "TabTopIslands" then
    panelElement:E("FriendCode"):DoStoredScript("setInvisible")
    panelElement:E("RequestsIncoming"):DoStoredScript("setInvisible")
    panelElement:E("RequestsSent"):DoStoredScript("setInvisible")
    panelElement:E("IslandsMain"):DoStoredScript("setVisible")
    panelElement:E("IslandsComposer"):DoStoredScript("setVisible")
    panelElement:E("IslandsTribal"):DoStoredScript("setVisible")
    panelElement:E("IslandVoting"):DoStoredScript("setVisible")
    panelElement:E("TopIslands"):DoStoredScript("show")
    panelElement:C("IslandResetInfo"):DoStoredScript("show")
    panelElement:C("NoFriendsLabel")("visible"):SetInt(0)
    panelElement:E("InviteFriends"):DoStoredScript("setInvisible")
    panelElement:E("FindFriends"):DoStoredScript("setInvisible")
    panelElement:C("FilterIcon")("visible"):SetInt(0)
    panelElement:C("SortIcon")("visible"):SetInt(0)
    panelElement:E("FilterFavourites"):DoStoredScript("setInvisible")
    panelElement:E("FilterTorch"):DoStoredScript("setInvisible")
    for i = 1, #sortButtons do
      panelElement:E(sortButtons[i]):DoStoredScript("setInvisible")
    end
    Social.onIslandFilterSelected(element, Social.Sorting[Social.currentTab].Filters.Islands)
    panelElement:C("FriendCountLabel"):DoStoredScript("hide")
  else
    panelElement:E("FriendCode"):DoStoredScript("setInvisible")
    panelElement:E("RequestsIncoming"):DoStoredScript("setInvisible")
    panelElement:E("RequestsSent"):DoStoredScript("setInvisible")
    panelElement:E("IslandsMain"):DoStoredScript("setInvisible")
    panelElement:E("IslandsComposer"):DoStoredScript("setInvisible")
    panelElement:E("IslandsTribal"):DoStoredScript("setInvisible")
    panelElement:E("IslandVoting"):DoStoredScript("setInvisible")
    panelElement:E("TopIslands"):DoStoredScript("hide")
    panelElement:C("IslandResetInfo"):DoStoredScript("hide")
    panelElement:C("NoFriendsLabel")("visible"):SetInt(0)
    panelElement:E("InviteFriends"):DoStoredScript("setInvisible")
    panelElement:E("FindFriends"):DoStoredScript("setInvisible")
    panelElement:C("FilterIcon")("visible"):SetInt(0)
    panelElement:C("SortIcon")("visible"):SetInt(0)
    panelElement:E("FilterFavourites"):DoStoredScript("setInvisible")
    panelElement:E("FilterTorch"):DoStoredScript("setInvisible")
    for i = 1, #sortButtons do
      panelElement:E(sortButtons[i]):DoStoredScript("setInvisible")
    end
    panelElement:C("FriendCountLabel"):DoStoredScript("hide")
  end
  if Social.currentTab ~= "TabTopIslands" then
    local friendCountLabel = panelElement:C("FriendCountLabel")
    friendCountLabel("text"):SetString(game.currentFriendCount() .. "/" .. game.maxFriendCount())
    if game.canAddMoreFriends() then
      friendCountLabel:setColor(1, 1, 1)
      panelElement:E("InviteFriends"):DoStoredScript("enable")
      panelElement:E("FindFriends"):DoStoredScript("enable")
    else
      friendCountLabel:setColor(1, 0, 0)
      panelElement:E("InviteFriends"):DoStoredScript("disable")
      panelElement:E("InviteFriends").Touch("enabled"):SetInt(1)
      panelElement:E("FindFriends"):DoStoredScript("disable")
      panelElement:E("FindFriends").Touch("enabled"):SetInt(1)
    end
  end
end
function Social.updateFriendCode(element)
  element:E("Panel"):E("FriendCode"):C("Text")("text"):SetString(game.getLocalizedText("FRIEND_CODE_USER") .. " " .. game.playerFriendCode())
end
function Social.refreshFriendCards(element)
  local panelElement = element:E("Panel")
  if Social.currentTab ~= "TabFriends" and Social.currentTab ~= "TabRequests" then
    Social.Sorting[Social.currentTab].PageNav.Total = 0
    for i = 1, CARDS_PER_PAGE do
      panelElement:E("cardItem" .. i):Hide()
    end
    return
  end
  if Social.filteredUsers == nil then
    Social.filteredUsers = Social.getFilteredFriends()
  end
  local numItems = #Social.filteredUsers
  if Social.Sorting[Social.currentTab].PageNav.Current == -1 then
    Social.Sorting[Social.currentTab].PageNav.Current = 0
  end
  Social.Sorting[Social.currentTab].PageNav.Total = math.ceil(numItems / CARDS_PER_PAGE)
  if Social.Sorting[Social.currentTab].PageNav.Current >= Social.Sorting[Social.currentTab].PageNav.Total then
    Social.Sorting[Social.currentTab].PageNav.Current = Social.Sorting[Social.currentTab].PageNav.Total - 1
  end
  local startItemIndex = Social.Sorting[Social.currentTab].PageNav.Current * CARDS_PER_PAGE
  local noFriendsLabel = panelElement:C("NoFriendsLabel")
  if numItems == 0 then
    noFriendsLabel("visible"):SetInt(1)
    if Social.currentTab == "TabFriends" then
      if Social.Sorting[Social.currentTab].Filters.FavouritesOnly and Social.Sorting[Social.currentTab].Filters.TorchesOnly then
        noFriendsLabel("text"):SetString("NOTIFICATION_NO_UNLIT_TORCH_FAV_FRIENDS")
      elseif Social.Sorting[Social.currentTab].Filters.FavouritesOnly then
        noFriendsLabel("text"):SetString("NOTIFICATION_NO_FAV_FRIENDS")
      elseif Social.Sorting[Social.currentTab].Filters.TorchesOnly then
        noFriendsLabel("text"):SetString("NOTIFICATION_NO_UNLIT_TORCH_FRIENDS")
      else
        noFriendsLabel("text"):SetString("NOTIFICATION_NO_FRIENDS")
      end
    elseif Social.currentTab == "TabRequests" then
      if Social.Sorting[Social.currentTab].Filters.RequestsIncoming then
        noFriendsLabel("text"):SetString("NOTIFICATION_NO_INCOMING_FRIEND_REQUESTS")
      else
        noFriendsLabel("text"):SetString("NOTIFICATION_NO_OUTGOING_FRIEND_REQUESTS")
      end
    end
  else
    noFriendsLabel("visible"):SetInt(0)
  end
  local isTorchesSort = Social.Sorting[Social.currentTab].Method == "torches"
  for i = 1, CARDS_PER_PAGE do
    local itemIndex = startItemIndex + i
    local cardItem = panelElement:E("cardItem" .. i)
    if Social.currentTab == "TabFriends" then
      cardItem:SetView("FRIENDS", false)
    elseif Social.currentTab == "TabRequests" then
      cardItem:SetView("REQUESTS", false)
    end
    if itemIndex > 0 and numItems >= itemIndex then
      cardItem:Show()
      local friendObject = Social.filteredUsers[itemIndex]
      cardItem:SetFriendObject(friendObject)
      if isTorchesSort then
        local text = game.getLocalizedText("FRIEND_THEY_LIT_TORCHES")
        text = select(1, text:gsub("%%numTorchesLitByFriend%%", friendObject:numTorchesLitByFriend()))
        cardItem:SetActivityText(text)
      end
    else
      cardItem:Hide()
    end
  end
end
function Social.getFilteredFriends()
  local items = {}
  local allUsers
  if Social.currentTab == "TabFriends" then
    allUsers = game.getFriends()
  elseif Social.currentTab == "TabRequests" then
    allUsers = game.getFriendRequests()
  else
    return items
  end
  if allUsers == nil or allUsers:size() == 0 then
    return items
  end
  for i = 0, allUsers:size() - 1 do
    local user = allUsers[i]
    local shouldAdd = true
    if Social.currentTab == "TabFriends" then
      if Social.Sorting[Social.currentTab].Filters.FavouritesOnly and shouldAdd then
        shouldAdd = user:isFavorite()
      end
      if Social.Sorting[Social.currentTab].Filters.TorchesOnly then
        shouldAdd = shouldAdd and user:hasUnlitTorches()
      end
    elseif Social.currentTab == "TabRequests" and shouldAdd then
      shouldAdd = Social.Sorting[Social.currentTab].Filters.RequestsIncoming == (user:getRequest():requestType() == "follow_me")
    end
    if shouldAdd then
      table.insert(items, user)
    end
  end
  local isAlphaSort = Social.Sorting[Social.currentTab].Method == "alpha"
  local isActivitySort = Social.Sorting[Social.currentTab].Method == "activity"
  local isLevelSort = Social.Sorting[Social.currentTab].Method == "level"
  local isTorchesSort = Social.Sorting[Social.currentTab].Method == "torches"
  if #items > 1 then
    table.sort(items, function(a, b)
      if isActivitySort and a:lastLogin() ~= b:lastLogin() then
        if Social.Sorting[Social.currentTab].Ascending then
          return a:lastLogin() > b:lastLogin()
        else
          return a:lastLogin() < b:lastLogin()
        end
      end
      if isLevelSort and a:level() ~= b:level() then
        if Social.Sorting[Social.currentTab].Ascending then
          return a:level() < b:level()
        else
          return a:level() > b:level()
        end
      end
      if isTorchesSort and a:numTorchesLitByFriend() ~= b:numTorchesLitByFriend() then
        if Social.Sorting[Social.currentTab].Ascending then
          return a:numTorchesLitByFriend() < b:numTorchesLitByFriend()
        else
          return a:numTorchesLitByFriend() > b:numTorchesLitByFriend()
        end
      end
      if Social.Sorting[Social.currentTab].Ascending then
        return a:displayName():lower() < b:displayName():lower()
      else
        return a:displayName():lower() > b:displayName():lower()
      end
    end)
  end
  return items
end
function Social.onSocialSortSelected(element, buttonElement, filterName)
  if filterName == "favourites" then
    Social.Sorting[Social.currentTab].PageNav.Current = -1
    if buttonElement.isSelected then
      buttonElement:DoStoredScript("deselect")
    else
      buttonElement:DoStoredScript("select")
    end
    Social.Sorting[Social.currentTab].Filters.FavouritesOnly = buttonElement.isSelected
  elseif filterName == "torch" then
    Social.Sorting[Social.currentTab].PageNav.Current = -1
    if buttonElement.isSelected then
      buttonElement:DoStoredScript("deselect")
    else
      buttonElement:DoStoredScript("select")
    end
    Social.Sorting[Social.currentTab].Filters.TorchesOnly = buttonElement.isSelected
  elseif Social.Sorting[Social.currentTab].Method ~= filterName then
    Social.Sorting[Social.currentTab].Method = filterName
    Social.Sorting[Social.currentTab].Ascending = true
    local panelElement = element:E("Panel")
    for i = 1, #sortButtons do
      panelElement:E(sortButtons[i]):DoStoredScript("deselect")
    end
    buttonElement:DoStoredScript("select")
  else
    Social.Sorting[Social.currentTab].Ascending = not Social.Sorting[Social.currentTab].Ascending
  end
  Social.saveFilterAndSorting()
  Social.filteredUsers = nil
  Social.refreshFriendCards(element)
  Social.updatePageNav(element)
end
function Social.onRequestsFilterSelected(element, filterName)
  local requestsIncoming = filterName == "RequestsIncoming"
  if requestsIncoming ~= Social.Sorting[Social.currentTab].Filters.RequestsIncoming then
    Social.Sorting[Social.currentTab].Filters.RequestsIncoming = requestsIncoming
    Social.saveFilterAndSorting()
    local buttonTabs = {
      "RequestsIncoming",
      "RequestsSent"
    }
    local panelElement = element:E("Panel")
    for i = 1, #buttonTabs do
      local button = panelElement:E(buttonTabs[i])
      if buttonTabs[i] == filterName then
        button:C("UpSprite")("spriteName"):SetString("gfx/menu/button_vert_square01_green")
        button:C("Touch")("enabled"):SetInt(0)
      else
        button:C("UpSprite")("spriteName"):SetString("gfx/menu/button_vert_square01")
        button:C("Touch")("enabled"):SetInt(1)
      end
    end
    Social.filteredUsers = nil
    Social.refreshFriendCards(element)
    Social.updatePageNav(element)
  end
end
function Social.refreshTopIslands(element)
  local panelElement = element:E("Panel")
  local topIslands = panelElement:E("TopIslands")
  local topIslandsList = topIslands:E("List")
  local scrollMarker = topIslands:E("ScrollMarker")
  local scrollBar = topIslands:E("ScrollBar")
  local swiper = topIslandsList:C("Swiper")
  local isComposer = Social.Sorting[Social.currentTab].Filters.Islands == "IslandsComposer"
  local isTribal = Social.Sorting[Social.currentTab].Filters.Islands == "IslandsTribal"
  local previousNumItems = topIslands("NumEntries"):GetInt()
  if previousNumItems > 0 then
    for i = 1, previousNumItems do
      topIslands:RemoveElement(topIslands:E("topIslandEntry" .. i))
    end
  end
  local numItems = 0
  if Social.currentTab == "TabTopIslands" then
    if isTribal then
      numItems = game.getTopTribeSize()
    elseif Social.topIslands ~= nil then
      numItems = Social.topIslands:size()
    end
    local noFriendsLabel = panelElement:C("NoFriendsLabel")
    if numItems == 0 then
      noFriendsLabel("visible"):SetInt(1)
      noFriendsLabel("text"):SetString("NOTIFICATION_NO_RANKED_ISLANDS")
    else
      noFriendsLabel("visible"):SetInt(0)
    end
  end
  topIslands("NumEntries"):SetInt(numItems)
  if numItems > 0 then
    local listWidth = topIslandsList:absW()
    local previous
    for i = 1, numItems do
      local topIslandEntry = menu:addTemplateElement("template_topislandsentry_new", "topIslandEntry" .. i, topIslands)
      topIslandEntry:setSize(Vector2(listWidth, topIslandEntry:absH()))
      if previous == nil then
        topIslandEntry:relativeTo(topIslands)
        topIslandEntry:setOrientation(lua_sys.MenuOrientation(0, 1, -1, lua_sys.HCENTER, lua_sys.TOP))
        topIslandEntry:setRelativeObjectAnchors(lua_sys.HCENTER, lua_sys.TOP)
      else
        topIslandEntry:relativeTo(previous)
        topIslandEntry:setOrientation(lua_sys.MenuOrientation(0, 0, 0, lua_sys.HCENTER, lua_sys.TOP))
        topIslandEntry:setRelativeObjectAnchors(lua_sys.HCENTER, lua_sys.BOTTOM)
      end
      previous = topIslandEntry
      topIslandEntry:init()
      topIslandEntry:postInit()
      topIslandEntry:setPositionBroadcast(true)
      if isTribal then
        topIslandEntry:SetTribalIslandInfo(i - 1)
      else
        topIslandEntry:SetIslandInfo(Social.topIslands[i - 1], isComposer)
      end
    end
    local totalHeight = numItems * topIslands:E("topIslandEntry1"):absH()
    if totalHeight > topIslands:absH() then
      scrollBar:C("Sprite")("visible"):SetInt(1)
      scrollMarker:C("Marker")("visible"):SetInt(1)
      scrollMarker:C("Touch")("enabled"):SetInt(1)
      swiper:setScrollSize(totalHeight - topIslands:absH())
      swiper:setScrollOffset(0)
    else
      scrollBar:C("Sprite")("visible"):SetInt(0)
      scrollMarker:C("Marker")("visible"):SetInt(0)
      scrollMarker:C("Touch")("enabled"):SetInt(0)
      swiper:setScrollSize(0)
      swiper:setScrollOffset(0)
    end
  else
    scrollBar:C("Sprite")("visible"):SetInt(0)
    scrollMarker:C("Marker")("visible"):SetInt(0)
    scrollMarker:C("Touch")("enabled"):SetInt(0)
    swiper:setScrollSize(0)
  end
  topIslandsList("scrollSize"):SetFloat(swiper:scrollSize())
end
function Social.onIslandFilterSelected(element, filterName)
  Social.Sorting[Social.currentTab].Filters.Islands = filterName
  Social.saveFilterAndSorting()
  local buttonTabs = {
    "IslandsMain",
    "IslandsComposer",
    "IslandsTribal"
  }
  local panelElement = element:E("Panel")
  for i = 1, #buttonTabs do
    local button = panelElement:E(buttonTabs[i])
    if buttonTabs[i] == Social.Sorting[Social.currentTab].Filters.Islands then
      button:C("UpSprite")("spriteName"):SetString("gfx/menu/button_vert_square01_green")
      button:C("Touch")("enabled"):SetInt(0)
    else
      button:C("UpSprite")("spriteName"):SetString("gfx/menu/button_vert_square01")
      button:C("Touch")("enabled"):SetInt(1)
    end
  end
  if Social.Sorting[Social.currentTab].Filters.Islands == "IslandsMain" then
    game.refreshTop10Islands(false)
  elseif Social.Sorting[Social.currentTab].Filters.Islands == "IslandsComposer" then
    game.refreshTop10Islands(true)
  elseif Social.Sorting[Social.currentTab].Filters.Islands == "IslandsTribal" then
    Social.topIslands = nil
    Social.refreshTopIslands(element)
  end
end
function Social.updatePageNav(element)
  local panelElement = element:E("Panel")
  local previousButton = panelElement:E("PreviousButton")
  local nextButton = panelElement:E("NextButton")
  local pageLabel = panelElement:C("PageLabel")
  pageLabel("text"):SetString(Social.Sorting[Social.currentTab].PageNav.Current + 1 .. "/" .. Social.Sorting[Social.currentTab].PageNav.Total)
  pageLabel:setSize(Vector2(12 * game.windowScaleY(), 6 * game.windowScaleY()))
  pageLabel("size"):SetFloat(0.18 * game.windowScaleY())
  if 1 <= Social.Sorting[Social.currentTab].PageNav.Total then
    previousButton:DoStoredScript("show")
    pageLabel:DoStoredScript("show")
    nextButton:DoStoredScript("show")
  else
    previousButton:DoStoredScript("hide")
    pageLabel:DoStoredScript("hide")
    nextButton:DoStoredScript("hide")
    return
  end
  if Social.Sorting[Social.currentTab].PageNav.Current <= 0 then
    previousButton:DoStoredScript("disable")
  else
    previousButton:DoStoredScript("enable")
  end
  if Social.Sorting[Social.currentTab].PageNav.Current + 1 >= Social.Sorting[Social.currentTab].PageNav.Total then
    nextButton:DoStoredScript("disable")
  else
    nextButton:DoStoredScript("enable")
  end
end
function Social.previousPage(element)
  if Social.Sorting[Social.currentTab].PageNav.Current < 1 then
    return
  end
  Social.Sorting[Social.currentTab].PageNav.Current = Social.Sorting[Social.currentTab].PageNav.Current - 1
  Social.updatePageNav(element)
  Social.refreshFriendCards(element)
  Social.saveFilterAndSorting()
end
function Social.nextPage(element)
  if Social.Sorting[Social.currentTab].PageNav.Current >= Social.Sorting[Social.currentTab].PageNav.Total then
    return
  end
  Social.Sorting[Social.currentTab].PageNav.Current = Social.Sorting[Social.currentTab].PageNav.Current + 1
  Social.updatePageNav(element)
  Social.refreshFriendCards(element)
  Social.saveFilterAndSorting()
end
function Social.onVisitRandomIsland(element)
  game.logEvent("friends_menu", "action", "visit_random_island_click")
  local type = 0
  if Social.Sorting[Social.currentTab].Filters.Islands == "IslandsComposer" then
    type = 1
  elseif Social.Sorting[Social.currentTab].Filters.Islands == "IslandsTribal" then
    type = 2
  end
  game.visitRandomUser(type)
end
return Social
