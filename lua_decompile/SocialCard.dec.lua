local SocialCard = {}
SocialCard.View = ""
SocialCard.friendObject = nil
SocialCard.bbbId = nil
SocialCard.requestId = nil
SocialCard.requestType = nil
SocialCard.enabled = false
SocialCard.element = nil
SocialCard.waitingForConfirmationMessageId = ""
SocialCard.currentCardId = 1
SocialCard.currentPhraseId = 591
function SocialCard.onInit(element)
  SocialCard.element = element
  element("tickLimiter"):SetFloat(1)
  element:SetupGenericListener(game.engineReceiver(), "game::msg::MsgKeyGifted", "gotMsgKeyGifted")
  element:SetupGenericListener(game.engineReceiver(), "game::msg::MsgConfirmationSubmission", "gotMsgConfirmationSubmission")
  element:SetupGenericListener(game.engineReceiver(), "sys::msg::MsgKeyboardEntryResult", "gotMsgKeyboardEntryResult")
  element:SetupGenericListener(game.engineReceiver(), "game::msg::MsgTextEntrySubmission", "gotMsgTextEntrySubmission")
  element:SetupGenericListener(game.engineReceiver(), "game::msg::MsgPermission", "gotMsgPermission")
end
function SocialCard.onTickLua(element, dt)
  element("tickLimiter"):SetFloat(element("tickLimiter"):GetFloat() - dt)
  if element("tickLimiter"):GetFloat() < 0 then
    element("tickLimiter"):SetFloat(1)
    if SocialCard.View == "FRIENDS" and game.playerLevel() >= game.minKeyGiftingLevel() and 0 >= game.giftTimeRemaining() then
      SocialCard.element:E("SmallRightButton"):DoStoredScript("enable")
    end
  end
end
function SocialCard:gotMsgKeyGifted(msg)
  if SocialCard.View == "FRIENDS" then
    SocialCard.element:E("SmallRightButton"):DoStoredScript("disable")
    SocialCard.element:E("SmallRightButton").Touch("enabled"):SetInt(1)
  end
end
function SocialCard:gotMsgConfirmationSubmission(msg)
  if self.waitingForConfirmationMessageId == msg.messageID and msg.choice then
    if self.waitingForConfirmationMessageId == "CONFIRM_CANCEL_FRIEND_REQUEST" or self.waitingForConfirmationMessageId == "CONFIRM_DENY_FRIEND_REQUEST" then
      game.cancelFriendRequest(self.requestId)
    elseif self.waitingForConfirmationMessageId == "CONFIRM_SEND_FRIEND_KEY" then
      game.transferCodeBBBId(self.bbbId)
    elseif self.waitingForConfirmationMessageId == "CONFIRM_LIT_HIGHLIGHTED_TORCH" then
      game.instantLightFriendHighlightedTorch(self.bbbId)
    elseif self.waitingForConfirmationMessageId == "CONFIRM_TRAVEL_FRIENDS_ISLAND" then
      game.visitFriendBBBId(self.bbbId)
      self:root():popPopUp()
      manager:setContext(manager:getDefaultContext())
    end
  end
  self.waitingForConfirmationMessageId = ""
end
function SocialCard:gotMsgKeyboardEntryResult(msg)
  if game.getPopUp() == "user_profile_editor" and not msg.cancelled then
    self:SetDisplayName(msg.text)
  end
end
function SocialCard:gotMsgTextEntrySubmission(msg)
  if game.getPopUp() == "user_profile_editor" and msg.messageID == "DISPLAY_NAME" and msg.choice then
    self:SetDisplayName(msg.text)
  end
end
function SocialCard:gotMsgPermission(msg)
  if game.getPopUp() == "user_profile_editor" and msg.name == "DISPLAY_NAME" and msg.allowed then
    game.displayTextEntry(game.getLocalizedText("DISPLAY_NAME"), self("DisplayNameText"):GetString(), true, -1, 25, true, "DISPLAY_NAME")
  end
end
function SocialCard.SetPlayerProfile(element, playerProfile, displayName)
  SocialCard.SetData(element, nil, displayName, playerProfile:getLevel(), nil, nil, nil)
  SocialCard.SetCard(element, playerProfile:getCardId())
  SocialCard.SetPhrase(element, playerProfile:getPhraseId())
  element:E("ProfilePic"):SetAvatarData(playerProfile:getPlayerAvatar())
end
function SocialCard.SetFriendObject(element, friendObject)
  SocialCard.friendObject = friendObject
  local friendRequestId, friendRequestType
  if SocialCard.friendObject:hasRequest() then
    local request = SocialCard.friendObject:getRequest()
    if request ~= nil then
      friendRequestId = request:requestId()
      friendRequestType = request:requestType()
    end
  end
  if SocialCard.friendObject:isFavorite() then
    element:E("FavoriteToggleButton"):C("Sprite")("spriteName"):SetString("favoritestar")
  else
    element:E("FavoriteToggleButton"):C("Sprite")("spriteName"):SetString("favoritestar_off")
  end
  SocialCard.SetData(element, SocialCard.friendObject:bbbId(), SocialCard.friendObject:displayName(), SocialCard.friendObject:level(), friendRequestId, friendRequestType, SocialCard.friendObject:lastLoginStr())
  element:E("ProfilePic"):SetAvatarData(friendObject:getPlayerAvatar())
  SocialCard.SetCard(element, friendObject:getProfile():getCardId())
  SocialCard.SetPhrase(element, friendObject:getProfile():getPhraseId())
end
function SocialCard.SetData(element, bbbid, displayName, level, requestId, requestType, lastLogin)
  SocialCard.bbbId = bbbid
  SocialCard.requestId = requestId
  SocialCard.requestType = requestType
  SocialCard.waitingForConfirmationMessageId = ""
  element:SetDisplayName(displayName)
  element:E("ProfilePic"):SetLevel(level)
  if lastLogin ~= nil then
    local time = game.compareToServerTime(lastLogin) * -1
    local totalHours = math.floor(time / 3600000)
    local timeText = ""
    local weeksInAMonth = 4.345
    if totalHours < 48 then
      timeText = select(1, game.getLocalizedText("LAST_LOGIN_HOURS"):gsub("XXX", totalHours))
    else
      local totalDays = math.floor(totalHours / 24)
      if totalDays < 14 then
        timeText = select(1, game.getLocalizedText("LAST_LOGIN_DAYS"):gsub("XXX", totalDays))
      else
        local totalWeeks = math.floor(totalDays / 7)
        if totalWeeks < weeksInAMonth * 2 then
          timeText = select(1, game.getLocalizedText("LAST_LOGIN_WEEKS"):gsub("XXX", totalWeeks))
        else
          local totalMonths = math.floor(totalWeeks / weeksInAMonth)
          if totalMonths < 3 then
            timeText = select(1, game.getLocalizedText("LAST_LOGIN_MONTHS"):gsub("XXX", totalMonths))
          else
            timeText = select(1, game.getLocalizedText("LAST_LOGIN_OVER_THREE_MONTHS"))
          end
        end
      end
    end
    SocialCard.SetActivityText(element, timeText)
  else
    element:E("Activity"):C("Text")("text"):SetString("")
  end
  if SocialCard.enabled then
    SocialCard.Show(element)
  end
end
function SocialCard.SetPlayerProfileItem(element, itemId)
  if element:E("ProfilePic"):SetPlayerProfileItem(itemId) then
    return true
  elseif SocialCard.SetCard(element, itemId) then
    return true
  elseif SocialCard.SetPhrase(element, itemId) then
    return true
  end
  return false
end
function SocialCard.SetCard(element, itemId)
  if itemId <= 0 then
    print("INVALID CARD: ItemId is 0")
    return false
  end
  local playerProfileItem = game.getPlayerProfileItem(itemId)
  if playerProfileItem:getItemType() == game.PlayerProfileItemType_CARD then
    SocialCard.currentCardId = itemId
    ApplyCard(element, playerProfileItem)
    return true
  else
    print("INVALID CARD: " .. itemId .. ". TYPE INVALID: " .. playerProfileItem:getItemType())
    return false
  end
end
function ApplyCard(element, playerProfileItem)
  local spriteElement = element:C("bg")
  local path = playerProfileItem:getAssetPath()
  spriteElement("spriteName"):SetString(path)
end
function SocialCard.SetPhrase(element, itemId)
  if itemId <= 0 then
    print("INVALID PHRASE: ItemId is 0")
    return false
  end
  local playerProfileItem = game.getPlayerProfileItem(itemId)
  if playerProfileItem:getItemType() == game.PlayerProfileItemType_PHRASE then
    SocialCard.currentPhraseId = itemId
    ApplyPhrase(element, playerProfileItem)
    return true
  else
    print("INVALID PHRASE: " .. itemId .. ". TYPE INVALID: " .. playerProfileItem:getItemType())
    return false
  end
end
function SocialCard.SetDisplayName(element, displayName)
  element("DisplayNameText"):SetString(displayName)
  if string.len(displayName) > 14 then
    displayName = string.sub(displayName, 0, 13) .. "..."
  end
  SocialCard:SetText(element:E("DisplayName"):C("Text"), displayName, 60 * element:templateVars().scale, 0.25 * element:templateVars().scale)
end
function ApplyPhrase(element, playerProfileItem)
  local path = playerProfileItem:getTextId()
  SocialCard:SetText(element:E("Phrase"):C("Text"), path, 66 * element:templateVars().scale, 0.2 * element:templateVars().scale)
end
function SocialCard.Hide(element)
  SocialCard.enabled = false
  element:C("bg")("visible"):SetInt(0)
  element:E("DisplayName"):DoStoredScript("hide")
  element:E("Phrase"):DoStoredScript("hide")
  element:E("Activity"):C("Text")("visible"):SetInt(0)
  element:E("FavoriteToggleButton"):DoStoredScript("setInvisible")
  element:E("EditIcon"):DoStoredScript("setInvisible")
  element:E("ProfilePic"):DoStoredScript("hide")
  element:E("SmallLeftButton"):DoStoredScript("setInvisible")
  element:E("SmallRightButton"):DoStoredScript("setInvisible")
  element:E("LargeButton"):DoStoredScript("setInvisible")
  element:C("Touch")("enabled"):SetInt(0)
end
function SocialCard.Show(element)
  SocialCard.enabled = true
  element:C("bg")("visible"):SetInt(1)
  element:E("DisplayName"):DoStoredScript("show")
  element:E("Phrase"):DoStoredScript("show")
  element:E("Activity"):C("Text")("visible"):SetInt(1)
  element:E("ProfilePic"):DoStoredScript("show")
  element:E("EditIcon"):DoStoredScript("setInvisible")
  element:C("Touch")("enabled"):SetInt(1)
  local smallLeftButton = element:E("SmallLeftButton")
  local smallRightButton = element:E("SmallRightButton")
  local largeButton = element:E("LargeButton")
  smallLeftButton:DoStoredScript("enable")
  smallRightButton:DoStoredScript("enable")
  largeButton:DoStoredScript("enable")
  if SocialCard.View == "FRIENDS" then
    element:E("FavoriteToggleButton"):DoStoredScript("setVisible")
    element:E("DisplayName")("xOffset"):SetInt(-8 * element:templateVars().scale)
    smallLeftButton:DoStoredScript("setVisible")
    smallLeftButton:C("Overlay")("spriteName"):SetString("button_light_torch")
    smallLeftButton:C("Overlay")("sheetName"):SetString("xml_resources/context_buttons.xml")
    if SocialCard.friendObject == nil or not SocialCard.friendObject:hasUnlitTorches() then
      smallLeftButton:DoStoredScript("disable")
      smallLeftButton.Touch("enabled"):SetInt(1)
    elseif SocialCard.friendObject:hasUnlitHighlightedTorches() then
      smallLeftButton:C("Overlay")("spriteName"):SetString("button_light_torch_highlight")
    else
      smallLeftButton:C("Overlay")("spriteName"):SetString("button_light_torch")
    end
    smallRightButton:DoStoredScript("setVisible")
    smallRightButton:C("Overlay")("spriteName"):SetString("keys")
    smallRightButton:C("Overlay")("sheetName"):SetString("xml_resources/hud01.xml")
    if game.giftTimeRemaining() >= 0 or game.playerLevel() < game.minKeyGiftingLevel() then
      smallRightButton:DoStoredScript("disable")
      smallRightButton.Touch("enabled"):SetInt(1)
    end
    largeButton:DoStoredScript("setInvisible")
  elseif SocialCard.View == "REQUESTS" then
    element:E("FavoriteToggleButton"):DoStoredScript("setInvisible")
    element:E("DisplayName")("xOffset"):SetInt(0)
    smallLeftButton:C("Overlay")("spriteName"):SetString("button_yes")
    smallLeftButton:C("Overlay")("sheetName"):SetString("xml_resources/context_buttons.xml")
    smallRightButton:C("Overlay")("spriteName"):SetString("button_no")
    smallRightButton:C("Overlay")("sheetName"):SetString("xml_resources/context_buttons.xml")
    largeButton:DoStoredScript("enable")
    largeButton:C("Text")("text"):SetString("PENDING")
    if SocialCard.requestType ~= nil then
      if SocialCard.requestType == "follow_me" then
        smallLeftButton:DoStoredScript("setVisible")
        smallRightButton:DoStoredScript("setVisible")
        largeButton:DoStoredScript("setInvisible")
        if game.canAddMoreFriends() then
          smallLeftButton:DoStoredScript("enable")
        else
          smallLeftButton:DoStoredScript("disable")
          smallLeftButton.Touch("enabled"):SetInt(1)
        end
      else
        smallLeftButton:DoStoredScript("setInvisible")
        smallRightButton:DoStoredScript("setInvisible")
        largeButton:DoStoredScript("setVisible")
        largeButton:C("Overlay")("visible"):SetInt(0)
      end
    end
  elseif SocialCard.View == "DISCOVER" or SocialCard.View == "DISCOVER_PROFILE_VIEW" then
    if SocialCard.View == "DISCOVER_PROFILE_VIEW" then
      element:C("Touch")("enabled"):SetInt(0)
    end
    element:E("FavoriteToggleButton"):DoStoredScript("setInvisible")
    element:E("DisplayName")("xOffset"):SetInt(0)
    smallLeftButton:DoStoredScript("setInvisible")
    smallRightButton:DoStoredScript("setInvisible")
    largeButton:DoStoredScript("setVisible")
    largeButton:DoStoredScript("enable")
    largeButton:C("Overlay")("visible"):SetInt(1)
    largeButton:C("UpSprite")("spriteName"):SetString("gfx/menu/button_vert_square01_green")
    largeButton:C("Overlay")("visible"):SetInt(0)
    largeButton:C("Text")("text"):SetString("ADD_FRIEND")
    if SocialCard.friendObject ~= nil and SocialCard.friendObject:hasRequest() then
      largeButton:DoStoredScript("disable")
      largeButton:C("UpSprite")("spriteName"):SetString("gfx/menu/button_vert_square01")
      largeButton:C("Text")("text"):SetString("SOCIAL_REQUESTS_SENT")
    end
  elseif SocialCard.View == "PLAYER_PROFILE_VIEW" then
    element:C("Touch")("enabled"):SetInt(0)
    element:E("FavoriteToggleButton"):DoStoredScript("setInvisible")
    element:E("DisplayName")("xOffset"):SetInt(0)
    smallLeftButton:DoStoredScript("setInvisible")
    smallRightButton:DoStoredScript("setInvisible")
    largeButton:DoStoredScript("setVisible")
    largeButton:DoStoredScript("enable")
    largeButton:C("UpSprite")("spriteName"):SetString("gfx/menu/button_vert_square01_green")
    largeButton:C("Overlay")("visible"):SetInt(0)
    largeButton:C("Text")("text"):SetString("PROFILE_EDITOR_EDIT")
    element:E("Activity"):C("Text")("visible"):SetInt(0)
  elseif SocialCard.View == "FRIEND_PROFILE_VIEW" then
    element:C("Touch")("enabled"):SetInt(0)
    element:E("FavoriteToggleButton"):DoStoredScript("setVisible")
    element:E("DisplayName")("xOffset"):SetInt(-8 * element:templateVars().scale)
    smallLeftButton:DoStoredScript("setInvisible")
    smallRightButton:DoStoredScript("setInvisible")
    largeButton:DoStoredScript("setVisible")
    largeButton:DoStoredScript("enable")
    largeButton:C("UpSprite")("spriteName"):SetString("gfx/menu/button_vert_square01_green")
    largeButton:C("Overlay")("visible"):SetInt(0)
    largeButton:C("Text")("text"):SetString("VISIT")
  elseif SocialCard.View == "EDIT" then
    element:C("Touch")("enabled"):SetInt(0)
    element:E("FavoriteToggleButton"):DoStoredScript("setInvisible")
    element:E("EditIcon"):DoStoredScript("setVisible")
    element:E("DisplayName")("xOffset"):SetInt(-8 * element:templateVars().scale)
    local palette = include("ColourPalette")
    element:E("DisplayName"):C("Text"):setColor(palette:getRGBFloats(palette.TITLE_YELLOW))
    element:E("DisplayName"):C("Touch")("enabled"):SetInt(1)
    smallLeftButton:DoStoredScript("setInvisible")
    smallRightButton:DoStoredScript("setInvisible")
    largeButton:DoStoredScript("setVisible")
    largeButton:DoStoredScript("disable")
    largeButton:C("UpSprite")("spriteName"):SetString("gfx/menu/button_vert_square01_green")
    largeButton:C("Overlay")("visible"):SetInt(0)
    largeButton:C("Text")("text"):SetString("")
    element:E("Activity"):C("Text")("visible"):SetInt(0)
  else
    element:C("Touch")("enabled"):SetInt(0)
    element:E("FavoriteToggleButton"):DoStoredScript("setInvisible")
    element:E("DisplayName")("xOffset"):SetInt(0)
    smallLeftButton:DoStoredScript("setInvisible")
    smallRightButton:DoStoredScript("setInvisible")
    largeButton:DoStoredScript("setInvisible")
  end
  SocialCard:RefreshButtonScale(smallLeftButton)
  SocialCard:RefreshButtonScale(smallRightButton)
  SocialCard:RefreshButtonScale(largeButton)
end
function SocialCard:RefreshButtonScale(element)
  local overlay = element:C("Overlay")
  local upSprite = element:C("UpSprite")
  local buttonHeight = upSprite:absH()
  local iconHeight = overlay:absH()
  local iconScale = overlay("size"):GetFloat()
  local newIconScale = buttonHeight * 0.7 / iconHeight * iconScale
  overlay("size"):SetFloat(newIconScale)
  element.scaleRatio = newIconScale / upSprite("width"):GetFloat()
end
function SocialCard.SetActivityText(element, text)
  SocialCard:SetText(element:E("Activity"):C("Text"), text, 72 * element:templateVars().scale, 0.2 * element:templateVars().scale)
end
function SocialCard:SetText(component, text, width, size)
  component("text"):SetString("")
  component:setSize(Vector2(width, 14))
  component("size"):SetFloat(size)
  component("text"):SetString(text)
end
function SocialCard.SetView(element, view, updateCard)
  if SocialCard.View ~= view then
    SocialCard.View = view
    if updateCard then
      SocialCard.Show(element)
    end
  end
end
function SocialCard.OnCardClicked(element)
  if SocialCard.friendObject ~= nil then
    game.selectFriend(SocialCard.friendObject:userId())
    game.setPlayerProfileReturningMenu(game.getPopUp())
    manager:setContext("USER_PROFILE_MENU")
    game.popPopUp()
  end
end
function SocialCard.OnFavouriteButton(element)
  if SocialCard.friendObject ~= nil then
    if SocialCard.friendObject:isFavorite() then
      element:E("FavoriteToggleButton"):C("Sprite")("spriteName"):SetString("favoritestar_off")
      SocialCard.friendObject:setFavorite(false)
    else
      element:E("FavoriteToggleButton"):C("Sprite")("spriteName"):SetString("favoritestar")
      SocialCard.friendObject:setFavorite(true)
    end
    if SocialCard.View == "FRIENDS" then
      element:parent():parent():refreshMenu()
    end
  end
end
function SocialCard.OnSmallLeftButtonUp(element)
  if SocialCard.View == "FRIENDS" then
    if SocialCard.friendObject == nil or not SocialCard.friendObject:hasUnlitTorches() then
      game.displayNotification("FRIEND_NO_UNLIT_TORCHES")
    elseif SocialCard.friendObject:hasUnlitHighlightedTorches() then
      SocialCard.waitingForConfirmationMessageId = "CONFIRM_LIT_HIGHLIGHTED_TORCH"
      local text = game.getLocalizedText(SocialCard.waitingForConfirmationMessageId)
      text = text .. [[


]]
      text = text .. select(1, game.getLocalizedText("FRIEND_I_LIT_TORCHES"):gsub("%%numTorchesLitByMe%%", SocialCard.friendObject:numTorchesLitByMe())) .. "\n"
      text = text .. select(1, game.getLocalizedText("FRIEND_THEY_LIT_TORCHES"):gsub("%%numTorchesLitByFriend%%", SocialCard.friendObject:numTorchesLitByFriend()))
      game.displayConfirmation(SocialCard.waitingForConfirmationMessageId, text, "button_light_torch_highlight", "xml_resources/context_buttons.xml")
      game.popUpManagerTopPopUp():E("Sprite"):C("Sprite")("size"):SetFloat(0.4 * game.hudScale())
    else
      SocialCard.waitingForConfirmationMessageId = "CONFIRM_TRAVEL_FRIENDS_ISLAND"
      local text = game.getLocalizedText(SocialCard.waitingForConfirmationMessageId)
      text = text .. [[


]]
      text = text .. select(1, game.getLocalizedText("FRIEND_I_LIT_TORCHES"):gsub("%%numTorchesLitByMe%%", SocialCard.friendObject:numTorchesLitByMe())) .. "\n"
      text = text .. select(1, game.getLocalizedText("FRIEND_THEY_LIT_TORCHES"):gsub("%%numTorchesLitByFriend%%", SocialCard.friendObject:numTorchesLitByFriend()))
      game.displayConfirmation(SocialCard.waitingForConfirmationMessageId, text)
    end
  elseif SocialCard.View == "REQUESTS" then
    if game.canAddMoreFriends() then
      game.acceptFriendRequest(SocialCard.requestId)
    else
      game.displayNotification("NOTIFICATION_TOO_MANY_FRIENDS")
    end
  end
end
function SocialCard.OnSmallRightButton(element)
  if SocialCard.View == "FRIENDS" then
    if game.playerLevel() < game.minKeyGiftingLevel() then
      game.displayNotification("KEY_GIFT_ERROR_LOW_LEVEL")
    elseif game.giftTimeRemaining() >= 0 then
      game.pushPopUp("popup_key_gift_cooldown")
    else
      SocialCard.waitingForConfirmationMessageId = "CONFIRM_SEND_FRIEND_KEY"
      game.displayConfirmation(SocialCard.waitingForConfirmationMessageId, SocialCard.waitingForConfirmationMessageId)
    end
  elseif SocialCard.View == "REQUESTS" then
    SocialCard.waitingForConfirmationMessageId = "CONFIRM_DENY_FRIEND_REQUEST"
    game.displayConfirmation(SocialCard.waitingForConfirmationMessageId, SocialCard.waitingForConfirmationMessageId)
  end
end
function SocialCard.OnLargeButton(element)
  if SocialCard.View == "REQUESTS" then
    SocialCard.waitingForConfirmationMessageId = "CONFIRM_CANCEL_FRIEND_REQUEST"
    game.displayConfirmation(SocialCard.waitingForConfirmationMessageId, SocialCard.waitingForConfirmationMessageId)
  elseif SocialCard.View == "DISCOVER" or SocialCard.View == "DISCOVER_PROFILE_VIEW" then
    if SocialCard.friendObject ~= nil and game.canAddMoreFriends() then
      game.requestFriend(SocialCard.friendObject:getFriendCode())
      SocialCard.friendObject:setHasRequest(true)
      local largeButton = element:E("LargeButton")
      largeButton:DoStoredScript("disable")
      largeButton:C("UpSprite")("spriteName"):SetString("gfx/menu/button_vert_square01")
      largeButton:C("Text")("text"):SetString("SOCIAL_REQUESTS_SENT")
    end
  elseif SocialCard.View == "PLAYER_PROFILE_VIEW" then
    game.popPopUp()
    manager:setContext("USER_PROFILE_EDITOR_MENU")
  elseif SocialCard.View == "FRIEND_PROFILE_VIEW" and SocialCard.friendObject ~= nil then
    game.visitFriendBBBId(SocialCard.bbbId)
    element:root():popPopUp()
    manager:setContext(manager:getDefaultContext())
  end
end
return SocialCard
