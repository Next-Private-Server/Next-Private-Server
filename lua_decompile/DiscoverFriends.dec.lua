local CARDS_PER_PAGE = -1
local MIN_CARD_SPACING = 16
local PANEL_MAX_WIDTH_RATIO = 2.5
local DiscoverFriends = {}
local tickLimiter = 0
function DiscoverFriends.onInit(element)
  element:SetupGenericListener(game.engineReceiver(), "game::msg::MsgFriendsDiscoverUpdated", "gotMsgFriendsDiscoverUpdated")
  local panelElement = element:E("Panel")
  local ratio = panelElement:absW() / panelElement:absH()
  if ratio > PANEL_MAX_WIDTH_RATIO then
    panelElement:setSize(Vector2(panelElement:absH() * PANEL_MAX_WIDTH_RATIO, panelElement:absH()))
    panelElement:C("bg"):setSize(Vector2(panelElement:absH() * PANEL_MAX_WIDTH_RATIO, panelElement:absH()))
  end
  local previousCard
  local spacing = 0
  for i = 1, 10 do
    local cardItem = menu:addTemplateElement("template_social_card", "cardItem" .. i, panelElement)
    cardItem:init()
    cardItem:setPositionBroadcast(true)
    cardItem:postInit()
    cardItem:SetView("DISCOVER", false)
    if CARDS_PER_PAGE == -1 then
      CARDS_PER_PAGE = math.floor(panelElement:absW() / (cardItem:absW() + MIN_CARD_SPACING))
      local diff = panelElement:absW() - CARDS_PER_PAGE * cardItem:absW()
      spacing = diff / (CARDS_PER_PAGE + 1)
    end
    if previousCard == nil then
      cardItem:relativeTo(panelElement)
      cardItem:setRelativeObjectAnchors(lua_sys.LEFT, lua_sys.VCENTER)
      cardItem:setOrientation(lua_sys.MenuOrientation(spacing, -8 * game.menuScaleX(), -1, lua_sys.LEFT, lua_sys.VCENTER))
    else
      cardItem:relativeTo(previousCard)
      cardItem:setRelativeObjectAnchors(lua_sys.RIGHT, lua_sys.VCENTER)
      cardItem:setOrientation(lua_sys.MenuOrientation(spacing, 0, 0, lua_sys.LEFT, lua_sys.VCENTER))
    end
    cardItem:Hide()
    if i >= CARDS_PER_PAGE then
      break
    end
    previousCard = cardItem
  end
  if 0 < game.getFriendDiscover():size() then
    element:refreshCards()
  else
    element:refreshFriendDiscover()
  end
end
function DiscoverFriends:gotMsgFriendsDiscoverUpdated(msg)
  self:refreshCards()
end
function DiscoverFriends.onTickLua(element, dt)
  tickLimiter = tickLimiter - dt
  if tickLimiter < 0 then
    tickLimiter = 1
    local refreshButton = element:E("Panel"):E("RefreshFriends")
    if game.canDiscoverFriendRefresh() then
      refreshButton:DoStoredScript("enable")
      refreshButton:C("Overlay")("visible"):SetInt(1)
      refreshButton:C("Text")("text"):SetString("")
    else
      refreshButton:DoStoredScript("disable")
      refreshButton:C("Overlay")("visible"):SetInt(0)
      local time = math.floor(game.discoverFriendRefreshTimeRemaining() / 1000) + 1
      refreshButton:C("Text")("text"):SetString(time)
    end
  end
end
function DiscoverFriends.refreshCards(element)
  local panelElement = element:E("Panel")
  local users = game.getFriendDiscover()
  local numItems = users:size()
  if numItems > 0 then
    panelElement:C("LoadingLabel")("visible"):SetInt(0)
  else
    panelElement:C("LoadingLabel")("visible"):SetInt(1)
    panelElement:C("LoadingLabel")("text"):SetString("FRIEND_DISCOVER_ERROR")
  end
  for i = 1, CARDS_PER_PAGE do
    local cardItem = panelElement:E("cardItem" .. i)
    if i <= numItems then
      cardItem:Show()
      cardItem:SetFriendObject(users[i - 1])
    else
      cardItem:Hide()
    end
  end
end
function DiscoverFriends.refreshFriendDiscover(element)
  local panelElement = element:E("Panel")
  for i = 1, CARDS_PER_PAGE do
    panelElement:E("cardItem" .. i):Hide()
  end
  panelElement:C("LoadingLabel")("visible"):SetInt(1)
  panelElement:C("LoadingLabel")("text"):SetString("STATUS_LOADING")
  panelElement:E("RefreshFriends"):DoStoredScript("disable")
  game.refreshFriendDiscover(CARDS_PER_PAGE)
end
return DiscoverFriends
