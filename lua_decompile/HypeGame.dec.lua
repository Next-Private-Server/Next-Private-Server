local HypeGame = {
  HypeBar = {},
  MixBoard = {
    Sprite = {}
  },
  MixBoardUpper = {
    Sprite = {}
  },
  HoolaHandLeft = {
    Sprite = {}
  },
  HoolaHandRight = {
    Sprite = {}
  },
  SpinWheelLeft = {},
  SpinWheelRight = {},
  Tickets = {},
  Output = {},
  HypeButton = {
    Sprite = {}
  }
}
local BASE_LIGHT_SPRITE_NAMES = {
  "base_orange_01",
  "base_orange_02",
  "base_orange_03",
  "base_yellow_01",
  "base_yellow_02",
  "base_yellow_03",
  "base_green_01",
  "base_green_02",
  "base_green_03"
}
local MULTI_LIGHT_SPRITE_NAMES = {
  "multi_orange_01",
  "multi_orange_02",
  "multi_orange_03",
  "multi_yellow_01",
  "multi_yellow_02",
  "multi_yellow_03",
  "multi_green_01",
  "multi_green_02",
  "multi_green_03"
}
local DISC_LABELS = {
  "label_waveform",
  "label_pomily",
  "label_blitherphish",
  "label_lvx_lvmenz"
}
local EMOJIS = {
  "^_^",
  "=^_^=",
  "\\./",
  "?_?",
  "._.",
  ">.<",
  "[^_^]",
  "*_*"
}
local EMOJI_INDEXS_WAITING = {
  2,
  4,
  5,
  6,
  7
}
local EMOJI_INDEX_VICTORY = 3
local EMOJI_INDEX_HAPPY = 1
local EMOJI_INDEX_SAD = 8
local TARGET_SPIN_TIME_RIGHT = 3.25
local TARGET_SPIN_TIME_LEFT = 2.5
local HYPE_FLING_DELAY_TIME = 0.75
local HOOLA_DISC_RE_SPIN_DURATION = 0.5
local END_DELAY_TIME = 3
local HOOLA_ANIM_DELAY = 0.2167
local SOUND_RECOVER_TIME = 0.5
local WHEEL_INDEX_POSITIONS = {
  {
    1,
    3,
    5,
    7
  },
  {
    2,
    4,
    6
  },
  {8}
}
local DEFAULT_TICKET_TIER_AMOUNTS = {
  1,
  3,
  5,
  10
}
local DEFAULT_TICKET_TIER_AMOUNTS_LOCKED_BY_HYPE = {5, 10}
local DEMO_MODE = false
function HypeGame:onInit()
  self:SetupGenericListener(game.engineReceiver(), "game::msg::MsgHypeGameResult", "gotMsgHypeGameResult")
  self:SetupGenericListener(game.engineReceiver(), "game::msg::MsgHypeGameRewards", "gotMsgHypeGameRewards")
  self:SetupGenericListener(game.engineReceiver(), "game::msg::MsgNotificationDismissed", "gotMsgNotificationDismissed")
  self:SetupGenericListener(game.engineReceiver(), "game::msg::MsgPurchasedBundle", "gotMsgPurchasedBundle")
  self:SetupGenericListener(game.engineReceiver(), "game::msg::MsgFlyingIconLanded", "gotMsgFlyingIconLanded")
  self:SetupGenericListener(game.engineReceiver(), "sys::msg::MsgPopPopUpGlobal", "gotMsgPopPopUpGlobal")
  manager:setContext("BLANK")
  self.hypeGameScale = 1
  self.currentBaseLights = 1
  self.targetBaseLights = 0
  self.lowerBaseLights = 0
  self.upperBaseLights = 0
  self.baseLightsDirection = 1
  self.currentMultiLights = 1
  self.targetMultiLights = 0
  self.lowerMultiLights = 10
  self.upperMultiLights = 10
  self.multiLightsDirection = 1
  self.currentTime = -1000000
  self.stopTimeLeft = TARGET_SPIN_TIME_LEFT
  self.stopDelayLeft = 1
  self.stopTimeRight = TARGET_SPIN_TIME_RIGHT
  self.stopDelayRight = 1
  self.refreshHypeDelay = 10000000
  self.wheelsStopped = false
  self.currentTickets = game.clubboxContext():getLastHypeGameTicketAmount()
  self.targetBaseIndex = 1
  self.targetMultiIndex = 1
  self.currentEmoji = ""
  self.currentResult = ""
  self.ticketTierAmounts = DEFAULT_TICKET_TIER_AMOUNTS
  self.baseValues = {
    10,
    20,
    50
  }
  self.multiValues = {
    1,
    2,
    3
  }
  self.rewardHasClubboxUnlock = false
  self.waitingForResponse = false
  self.hypeUpdated = false
  self.hypeFlingSent = false
  self.handStartSpinTime = 0
  self.showClubboxUnlockPopup = false
  self.showedClubboxUnlockPopup = false
  self.showClubboxPrestigePopup = false
  self.showedClubboxPrestigePopup = false
  self.closePopup = false
  self.soundRecovery = SOUND_RECOVER_TIME
  self.currentPlayerTokens = game.playerClubboxTokens()
  self.targetPlayerTokens = self.currentPlayerTokens
end
function HypeGame:gotMsgHypeGameResult(msg)
  self.currentTickets = msg.tokens
  game.engineReceiver():Send(game.MsgHypeGameCurrentTicketsSet(self.currentTickets))
  local baseWheelValues = game.getHypeWheelValues(game.HypeWheelData_POINTS)
  for i = 0, baseWheelValues:size() - 1 do
    if baseWheelValues[i] * self.currentTickets == msg.points then
      self.targetBaseIndex = i + 1
      break
    end
  end
  local multiWheelValues = game.getHypeWheelValues(game.HypeWheelData_MULTIPLIER)
  for i = 0, multiWheelValues:size() - 1 do
    if multiWheelValues[i] == msg.multiplier then
      self.targetMultiIndex = i + 1
      break
    end
  end
  self.waitingForResponse = false
  self.hypeUpdated = true
  self.currentTime = 0
  self.HypeBar.Touch("enabled"):SetInt(0)
  self:E("CloseButton"):DoStoredScript("setInvisible")
  self:resetOuput()
  self:reset()
  self.targetPlayerTokens = self.targetPlayerTokens - self.currentTickets
  lua_sys.playSoundFx("audio/sfx/clubbox_menu_spin_seq_start.ogg")
end
function HypeGame:gotMsgNotificationDismissed(msg)
  if msg.messageID == "FAIL" or msg.messageID == "NOT_ENOUGH_CLUBBOX_TOKENS" then
    self:enablePlaying()
  end
end
function HypeGame:gotMsgPurchasedBundle(msg)
  game.showUnclaimedBundleIfExists()
end
function HypeGame:gotMsgFlyingIconLanded(msg)
  if msg.type == game.LootType_ClubboxTokens then
    self.targetPlayerTokens = game.playerClubboxTokens()
  end
end
function HypeGame:gotMsgHypeGameRewards(msg)
  self.rewardHasClubboxUnlock = false
  self.rewardHasCardPackReward = false
  local rewards = msg:rewards()
  if rewards:size() > 0 then
    for i = 0, rewards:size() - 1 do
      if rewards[i].type == game.LootType_ClubboxUnlock then
        self.rewardHasClubboxUnlock = true
      elseif rewards[i].type == game.LootType_CardPack then
        self.rewardHasCardPackReward = true
      end
    end
  end
end
function HypeGame:gotMsgPopPopUpGlobal(msg)
  if msg.menuName == "card_album_page_reward_collect" then
    return
  end
  if msg.menuName == "currency_suggest" then
    self:enablePlaying()
    return
  end
  if msg.menuName == "open_card_pack" then
    self.rewardHasCardPackReward = false
    if (game.player():currentlyActiveCardAlbum() == nil or game.player():currentlyActiveCardAlbum():hasUncollectedRewards() == false) and self.rewardHasClubboxUnlock then
      self.showClubboxUnlockPopup = true
      return
    end
  end
  if game.player():currentlyActiveCardAlbum() ~= nil and game.player():currentlyActiveCardAlbum():hasUncollectedRewards() then
    return
  end
  if self.rewardHasCardPackReward then
    return
  end
  if not self.showedClubboxUnlockPopup and self.rewardHasClubboxUnlock and msg.menuName == "popup_store_bundle_rewards" then
    self.showClubboxUnlockPopup = true
    return
  end
  local newPrestigeLevel = game.currentClubboxPrestigeLevel()
  if not self.showedClubboxPrestigePopup and self.currentPrestigeLevel ~= newPrestigeLevel then
    self.currentPrestigeLevel = newPrestigeLevel
    self.showClubboxPrestigePopup = true
    return
  end
  if (msg.menuName == "popup_notification" or msg.menuName == "hype_game_prestige") and (self.showedClubboxUnlockPopup or self.showedClubboxPrestigePopup) then
    self.closePopup = true
    return
  end
end
function HypeGame:onPostInit()
  self.HypeBar.isHypeGameBar = true
  local animUtil = game.AnimUtil(self.MixBoard.Sprite)
  local mixBoardRatio = self.MixBoard.Sprite:absW() / self.MixBoard.Sprite:absH()
  local screenRatio = lua_sys.screenWidth() / lua_sys.screenHeight()
  if mixBoardRatio > screenRatio then
    self.hypeGameScale = lua_sys.screenHeight() / self.MixBoard.Sprite:absH()
  else
    self.hypeGameScale = lua_sys.screenWidth() / self.MixBoard.Sprite:absW()
  end
  self.MixBoard.Sprite:setScale(Vector2(self.hypeGameScale, self.hypeGameScale))
  self.MixBoard.Sprite("animation"):SetString("clubbox")
  self.MixBoardUpper.Sprite:setScale(Vector2(self.hypeGameScale, self.hypeGameScale))
  self.MixBoardUpper.Sprite("animation"):SetString("clubbox_upper_layer")
  self.HoolaHandLeft.Sprite:setScale(Vector2(self.hypeGameScale, self.hypeGameScale))
  self.HoolaHandLeft.Sprite("animation"):SetString("hoola_hand_left")
  self.HoolaHandLeft.Sprite("visible"):SetFloat(0)
  self.HoolaHandRight.Sprite:setScale(Vector2(self.hypeGameScale, self.hypeGameScale))
  self.HoolaHandRight.Sprite("animation"):SetString("hoola_hand_right")
  self.HoolaHandRight.Sprite("visible"):SetFloat(0)
  local textureSize = 256
  local bgSprite = self:E("Bg"):C("Sprite")
  bgSprite:setScale(Vector2(lua_sys.screenWidth() / textureSize, lua_sys.screenHeight() / textureSize))
  bgSprite:GetVar("repeating"):SetInt(1)
  bgSprite:setShader(include("ShaderRepeating"))
  local prestigeLevel = game.clubboxPrestigeLevel(game.existingClubboxAct())
  local showPrestige = prestigeLevel > 0
  if showPrestige then
    self.SpinWheelLeft:setDisc("gfx/clubbox/hype/record_gold")
  else
    self.SpinWheelLeft:setDisc("gfx/clubbox/hype/record_default")
  end
  self.SpinWheelLeft:setDiscLabel("gfx/clubbox/hype/" .. DISC_LABELS[game.existingClubboxAct()])
  self.SpinWheelLeft:setWheelScale(self.hypeGameScale)
  local layerPos = animUtil:getPos("record_default_left")
  self.SpinWheelLeft("xOffset"):SetFloat(layerPos.x * self.hypeGameScale)
  self.SpinWheelLeft("yOffset"):SetFloat(layerPos.y * self.hypeGameScale)
  self.MixBoard.Sprite:AddRemap("record_default_left", "gfx/empty")
  if showPrestige then
    self.SpinWheelRight:setDisc("gfx/clubbox/hype/record_gold")
  else
    self.SpinWheelRight:setDisc("gfx/clubbox/hype/record_default")
  end
  self.SpinWheelRight:setDiscLabel("gfx/clubbox/hype/label_clubbox")
  self.SpinWheelRight:setWheelScale(self.hypeGameScale)
  layerPos = animUtil:getPos("record_default_right")
  self.SpinWheelRight("xOffset"):SetFloat(layerPos.x * self.hypeGameScale)
  self.SpinWheelRight("yOffset"):SetFloat(layerPos.y * self.hypeGameScale)
  self.MixBoard.Sprite:AddRemap("record_default_right", "gfx/empty")
  local minusButton = self:E("MinusButton")
  layerPos = animUtil:getPos("button_minus")
  minusButton:C("Sprite")("size"):SetFloat(self.hypeGameScale)
  minusButton("xOffset"):SetFloat(layerPos.x * self.hypeGameScale + minusButton:absW() * 0.5)
  minusButton("yOffset"):SetFloat(-(layerPos.y * self.hypeGameScale + minusButton:absH()))
  local plusButton = self:E("PlusButton")
  layerPos = animUtil:getPos("button_plus")
  plusButton:C("Sprite")("size"):SetFloat(self.hypeGameScale)
  plusButton("xOffset"):SetFloat(layerPos.x * self.hypeGameScale + plusButton:absW() * 0.5)
  plusButton("yOffset"):SetFloat(-(layerPos.y * self.hypeGameScale + plusButton:absH()))
  layerPos = animUtil:getPos("button_hype")
  self.HypeButton.Sprite("size"):SetFloat(self.hypeGameScale)
  self.HypeButton("xOffset"):SetFloat(layerPos.x * self.hypeGameScale + self.HypeButton:absW() * 0.5)
  self.HypeButton("yOffset"):SetFloat(-(layerPos.y * self.hypeGameScale + self.HypeButton:absH()))
  local baseHigh = self:C("BaseHigh")
  baseHigh("size"):SetFloat(0.9 * self.hypeGameScale)
  baseHigh("xOffset"):SetFloat(76 * self.hypeGameScale)
  baseHigh("yOffset"):SetFloat(-4 * self.hypeGameScale)
  local baseMid = self:C("BaseMid")
  baseMid("size"):SetFloat(0.9 * self.hypeGameScale)
  baseMid("xOffset"):SetFloat(76 * self.hypeGameScale)
  baseMid("yOffset"):SetFloat(74 * self.hypeGameScale)
  local baseLow = self:C("BaseLow")
  baseLow("size"):SetFloat(0.9 * self.hypeGameScale)
  baseLow("xOffset"):SetFloat(76 * self.hypeGameScale)
  baseLow("yOffset"):SetFloat(152 * self.hypeGameScale)
  local multHigh = self:C("MultHigh")
  multHigh("size"):SetFloat(0.9 * self.hypeGameScale)
  multHigh("xOffset"):SetFloat(76 * self.hypeGameScale)
  multHigh("yOffset"):SetFloat(-4 * self.hypeGameScale)
  local multMid = self:C("MultMid")
  multMid("size"):SetFloat(0.9 * self.hypeGameScale)
  multMid("xOffset"):SetFloat(76 * self.hypeGameScale)
  multMid("yOffset"):SetFloat(74 * self.hypeGameScale)
  local multLow = self:C("MultLow")
  multLow("size"):SetFloat(0.9 * self.hypeGameScale)
  multLow("xOffset"):SetFloat(76 * self.hypeGameScale)
  multLow("yOffset"):SetFloat(152 * self.hypeGameScale)
  self.Tickets("size"):SetFloat(self.hypeGameScale)
  self.Tickets("yOffset"):SetFloat(-110 * self.hypeGameScale)
  self.Output("size"):SetFloat(self.hypeGameScale)
  self.Output("yOffset"):SetFloat(240 * self.hypeGameScale)
  self:E("TokenCounter"):C("Text")("text"):SetString(game.localizeInt(self.currentPlayerTokens))
  animUtil = game.AnimUtil(self.MixBoard.Sprite)
  animUtil:addRemap("button_minus", "clubbox_menu.xml", "empty")
  animUtil:addRemap("button_plus", "clubbox_menu.xml", "empty")
  animUtil:addRemap("button_hype", "clubbox_menu.xml", "empty")
  self.currentPrestigeLevel = game.currentClubboxPrestigeLevel()
  self:refreshLights(false)
  self:enablePlaying()
  self:resetOuput()
  self:reset()
end
function HypeGame:onTick(dt)
  self.currentTime = self.currentTime + dt
  if not self.wheelsStopped then
    if self.currentTime >= self.stopTimeLeft then
      self.stopDelayLeft = self.stopDelayLeft - dt
      if self.HoolaHandLeft.Sprite("visible"):GetFloat() == 0 or self.HoolaHandLeft.Sprite("animation"):GetString() ~= "hoola_hand_left" then
        self.HoolaHandLeft.Sprite("animation"):SetString("hoola_hand_left")
        local animUtil = game.AnimUtil(self.HoolaHandLeft.Sprite)
        animUtil:resetAnim()
        self.HoolaHandLeft.Sprite("visible"):SetFloat(1)
        game.setClubboxPlayRate(0)
        self.stopDelayLeft = HOOLA_ANIM_DELAY - dt
      end
      if not self.wheelsStopped and self.stopDelayLeft <= 0 and not self.SpinWheelLeft:isStopped() then
        self.SpinWheelLeft:stopDiscs()
        self.targetBaseLights = self.targetBaseIndex * 3
        lua_sys.playSoundFx(string.format("audio/sfx/clubbox_menu_spin_basepoints_level%02d.ogg", self.targetMultiIndex))
        self.currentResult = self.baseValues[self.targetBaseIndex] .. "*??=??"
      end
    end
    if self.currentTime >= self.stopTimeRight then
      self.stopDelayRight = self.stopDelayRight - dt
      if self.HoolaHandRight.Sprite("visible"):GetFloat() == 0 or self.HoolaHandRight.Sprite("animation"):GetString() ~= "hoola_hand_right" then
        self.HoolaHandRight.Sprite("animation"):SetString("hoola_hand_right")
        local animUtil = game.AnimUtil(self.HoolaHandRight.Sprite)
        animUtil:resetAnim()
        self.HoolaHandRight.Sprite("visible"):SetFloat(1)
        self.stopDelayRight = HOOLA_ANIM_DELAY - dt
      end
      if not self.wheelsStopped and 0 >= self.stopDelayRight and not self.SpinWheelRight:isStopped() then
        self.SpinWheelRight:stopDiscs()
        self.targetMultiLights = self.targetMultiIndex * 3
        lua_sys.playSoundFx(string.format("audio/sfx/clubbox_menu_spin_mult_level%02d.ogg", self.targetMultiIndex))
      end
    end
  end
  if self.currentTime > 0 and self.stopDelayLeft <= 0 and 0 >= self.stopDelayRight then
    if not self.wheelsStopped then
      self.wheelsStopped = true
      if self.targetBaseIndex == 3 and self.targetMultiIndex == 3 or self.targetBaseIndex == 2 and self.targetMultiIndex == 3 or self.targetBaseIndex == 3 and self.targetMultiIndex == 2 then
        game.playEffect("particles/Clubbox/FX_WinLrgConfetti.efkefc", lua_sys.screenWidth() * 0.5, lua_sys.screenHeight() * 0.5, "FrontPopUps", 0.001, 6 * game.windowScaleY())
        lua_sys.playSoundFx("audio/sfx/clubbox_menu_spin_seq_crit.ogg")
      end
      if self.targetBaseIndex == 1 and self.targetMultiIndex == 1 then
        self.currentEmoji = EMOJIS[EMOJI_INDEX_SAD]
      elseif self.targetBaseIndex == 3 and self.targetMultiIndex == 3 then
        self.currentEmoji = EMOJIS[EMOJI_INDEX_VICTORY]
      else
        self.currentEmoji = EMOJIS[EMOJI_INDEX_HAPPY]
      end
      self:setOutput(self.targetBaseIndex, self.targetMultiIndex)
    end
    if self.currentTime >= math.max(self.stopTimeLeft, self.stopTimeRight) + HYPE_FLING_DELAY_TIME and not self.hypeFlingSent then
      local startX = self.Output:absX() + self.Output:absW() * 0.5
      local startY = self.Output:absY() + self.Output:absH() * 0.5
      local endX = self.HypeBar:absX() + self.HypeBar:absW() * 0.5
      local endY = self.HypeBar:absY() + self.HypeBar:absH() * 0.5
      game.showFlyingHypeIconToHypeBar(startX, startY, endX, endY)
      lua_sys.playSoundFx("audio/sfx/clubbox_collect_ticket.ogg")
      self.hypeFlingSent = true
      self.refreshHypeDelay = 0.65
    end
    if self.hypeFlingSent then
      self.refreshHypeDelay = self.refreshHypeDelay - dt
      if 0 > self.refreshHypeDelay then
        self.refreshHypeDelay = 1000000
        self.HypeBar:refreshHypePoints()
      end
    end
    if self.currentTime >= math.max(self.stopTimeLeft, self.stopTimeRight) + END_DELAY_TIME - HOOLA_DISC_RE_SPIN_DURATION and self.currentTime < math.max(self.stopTimeLeft, self.stopTimeRight) + END_DELAY_TIME then
      local backSpeed = -200
      local frontSpeed = 400
      local frontDelay = 0.32
      if self.handStartSpinTime == 0 then
        self.HoolaHandLeft.Sprite("animation"):SetString("hoola_hand_spin_left")
        self.HoolaHandRight.Sprite("animation"):SetString("hoola_hand_spin_right")
        self.SpinWheelLeft.currentVelocity = backSpeed * 0.5
        self.SpinWheelLeft.targetVelocity = backSpeed
        self.SpinWheelRight.currentVelocity = backSpeed * 0.5
        self.SpinWheelRight.targetVelocity = backSpeed
      end
      if frontDelay < self.handStartSpinTime and self.SpinWheelLeft.targetVelocity == backSpeed then
        self.SpinWheelLeft.currentVelocity = frontSpeed
        self.SpinWheelLeft.targetVelocity = frontSpeed
        self.SpinWheelRight.currentVelocity = frontSpeed
        self.SpinWheelRight.targetVelocity = frontSpeed
        lua_sys.playSoundFx("audio/sfx/clubbox_menu_spin_seq_end.ogg")
        self.soundRecovery = 0
      end
      self.handStartSpinTime = self.handStartSpinTime + dt
    end
    if self.currentTime >= math.max(self.stopTimeLeft, self.stopTimeRight) + END_DELAY_TIME then
      self:enablePlaying()
      self:reset()
    end
  end
  if self.soundRecovery < SOUND_RECOVER_TIME then
    self.soundRecovery = self.soundRecovery + dt
    if self.soundRecovery < SOUND_RECOVER_TIME then
      local rate = math.floor(self.soundRecovery / SOUND_RECOVER_TIME * 100) * 0.01
      game.setClubboxPlayRate(rate)
    else
      game.setClubboxPlayRate(1)
    end
  end
  if self.currentTime >= 0 and not self.wheelsStopped then
    if self.stopDelayLeft > 0 then
      self.targetBaseLights = self.targetBaseLights + self.baseLightsDirection * (dt * 32)
      if self.targetBaseLights >= self.upperBaseLights then
        self.baseLightsDirection = -1
        self.lowerBaseLights = math.random(1, self.upperBaseLights - 1)
      elseif self.targetBaseLights <= self.lowerBaseLights then
        self.baseLightsDirection = 1
        self.upperBaseLights = math.random(2, 10)
      end
    end
    if 0 < self.stopDelayRight then
      self.targetMultiLights = self.targetMultiLights + self.multiLightsDirection * (dt * 32)
      if self.targetMultiLights >= self.upperMultiLights then
        self.multiLightsDirection = -1
        self.lowerMultiLights = math.random(1, self.upperMultiLights - 1)
      elseif self.targetMultiLights <= self.lowerMultiLights then
        self.multiLightsDirection = 1
        self.upperMultiLights = math.random(2, 10)
      end
    end
    self:refreshLights(false)
    if self.currentTime < self.stopTimeLeft then
      local rate = 1 + math.floor(self.SpinWheelLeft:speedToIdleRatio() * 2.5) * 0.01
      game.setClubboxPlayRate(rate)
    end
  end
  if self.currentResult ~= "" then
    if not self.wheelsStopped and 2 > math.floor(self.currentTime) % 4 then
      self.Output("text"):SetString(self.currentEmoji)
    else
      self.Output("text"):SetString(self.currentResult)
    end
  end
  if self.showClubboxUnlockPopup then
    self.showClubboxUnlockPopup = false
    self.showedClubboxUnlockPopup = true
    if not game.disableClubboxUnlockNotif() then
      game.displayNotification("NOTIFICATION_CLUBBOX_ITEM_UNLOCKED")
    end
  elseif self.showClubboxPrestigePopup then
    self.showClubboxPrestigePopup = false
    self.showedClubboxPrestigePopup = true
    if not game.disableClubboxUnlockNotif() then
      game.pushPopUp("hype_game_prestige")
    end
  end
  if self.closePopup then
    self.closePopup = false
    self:close()
    manager:setContext("CLUBBOX_DEFAULT")
  end
  if self.currentPlayerTokens ~= self.targetPlayerTokens then
    local rate = 20 * dt
    local diff = self.targetPlayerTokens - self.currentPlayerTokens
    if rate > math.abs(diff) then
      self.currentPlayerTokens = self.targetPlayerTokens
    else
      self.currentPlayerTokens = self.currentPlayerTokens + rate * diff / math.abs(diff)
    end
    self:E("TokenCounter"):C("Text")("text"):SetString(game.localizeInt(math.floor(self.currentPlayerTokens)))
  end
end
function HypeGame:queuePop()
  if not self:isRunning() then
    self.closePopup = true
  end
end
function HypeGame:reset()
  self:refreshEnabledTicketAmounts()
  if DEMO_MODE then
    self.currentTickets = self.ticketTierAmounts[math.random(1, #self.ticketTierAmounts)]
    game.engineReceiver():Send(game.MsgHypeGameCurrentTicketsSet(self.currentTickets))
    self.targetBaseIndex = math.random(1, 3)
    self.targetMultiIndex = math.random(1, 3)
    self.currentTime = 0
    self.HypeBar.Touch("enabled"):SetInt(0)
    self.HypeButton.Sprite("spriteName"):Set("button_hype_grey")
    self:resetOuput()
  end
  self.upperBaseLights = math.random(2, 10)
  self.lowerBaseLights = math.random(1, self.upperBaseLights - 1)
  self.baseLightsDirection = 1
  self.upperMultiLights = math.random(2, 10)
  self.lowerMultiLights = math.random(1, self.upperMultiLights - 1)
  self.multiLightsDirection = 1
  self:setTickets(math.floor(self.currentTickets))
  local multiWheelValues = game.getHypeWheelValues(game.HypeWheelData_MULTIPLIER)
  self.multiValues = {}
  for i = 0, multiWheelValues:size() - 1 do
    table.insert(self.multiValues, multiWheelValues[i])
  end
  self:C("MultHigh")("text"):SetString("*" .. self.multiValues[3])
  self:C("MultMid")("text"):SetString("*" .. self.multiValues[2])
  self:C("MultLow")("text"):SetString("*" .. self.multiValues[1])
  self.wheelsStopped = false
  self.hypeFlingSent = false
  self.handStartSpinTime = 0
  self.SpinWheelLeft:resetIdleDiscSpeed()
  self.SpinWheelRight:resetIdleDiscSpeed()
  local numbers = {}
  for i = 1, 8 do
    for j, indexes in ipairs(WHEEL_INDEX_POSITIONS) do
      for _, index in ipairs(indexes) do
        if index == i then
          table.insert(numbers, "x" .. self.multiValues[j])
          break
        end
      end
      if i <= #numbers then
        break
      end
    end
  end
  self.SpinWheelRight:setDiscNumberValues(numbers)
  if self.currentTime == 0 then
    self.SpinWheelLeft:resetDiscSpeed()
    self.stopTimeLeft = TARGET_SPIN_TIME_LEFT
    self.stopDelayLeft = 1
    local baseTarget = self.SpinWheelLeft:findBestIndex(WHEEL_INDEX_POSITIONS[self.targetBaseIndex], self.stopTimeLeft + HOOLA_ANIM_DELAY)
    self.stopTimeLeft = self.SpinWheelLeft:setTargetIndex(baseTarget, self.stopTimeLeft + HOOLA_ANIM_DELAY) - HOOLA_ANIM_DELAY
    self.SpinWheelRight:resetDiscSpeed()
    self.stopTimeRight = TARGET_SPIN_TIME_RIGHT
    self.stopDelayRight = 1
    local multiTarget = self.SpinWheelRight:findBestIndex(WHEEL_INDEX_POSITIONS[self.targetMultiIndex], self.stopTimeRight + HOOLA_ANIM_DELAY)
    self.stopTimeRight = self.SpinWheelRight:setTargetIndex(multiTarget, self.stopTimeRight + HOOLA_ANIM_DELAY) - HOOLA_ANIM_DELAY
  end
end
function HypeGame:resetOuput()
  self.currentResult = ""
  self.currentEmoji = EMOJIS[EMOJI_INDEXS_WAITING[math.random(#EMOJI_INDEXS_WAITING)]]
  self.Output("text"):SetString(self.currentEmoji)
end
function HypeGame:refreshLights(force)
  local animUtil = game.AnimUtil(self.MixBoard.Sprite)
  if force or self.currentBaseLights ~= math.floor(self.targetBaseLights) then
    self.currentBaseLights = math.floor(self.targetBaseLights)
    for i = 1, 9 do
      if i > self.currentBaseLights then
        animUtil:addRemap(BASE_LIGHT_SPRITE_NAMES[i], "clubbox_menu.xml", "empty")
      elseif i > 6 then
        animUtil:addRemap(BASE_LIGHT_SPRITE_NAMES[i], "clubbox_menu.xml", "light_green")
      elseif i > 3 then
        animUtil:addRemap(BASE_LIGHT_SPRITE_NAMES[i], "clubbox_menu.xml", "light_yellow")
      else
        animUtil:addRemap(BASE_LIGHT_SPRITE_NAMES[i], "clubbox_menu.xml", "light_orange")
      end
    end
  end
  if force or self.currentMultiLights ~= math.floor(self.targetMultiLights) then
    self.currentMultiLights = math.floor(self.targetMultiLights)
    for i = 1, 9 do
      if i > self.currentMultiLights then
        animUtil:addRemap(MULTI_LIGHT_SPRITE_NAMES[i], "clubbox_menu.xml", "empty")
      elseif i > 6 then
        animUtil:addRemap(MULTI_LIGHT_SPRITE_NAMES[i], "clubbox_menu.xml", "light_green")
      elseif i > 3 then
        animUtil:addRemap(MULTI_LIGHT_SPRITE_NAMES[i], "clubbox_menu.xml", "light_yellow")
      else
        animUtil:addRemap(MULTI_LIGHT_SPRITE_NAMES[i], "clubbox_menu.xml", "light_orange")
      end
    end
  end
end
function HypeGame:changeTickets(delta)
  if self:isRunning() then
    return
  end
  self:refreshEnabledTicketAmounts()
  local currentTicketIndex = 1
  for i = 1, #self.ticketTierAmounts do
    if self.ticketTierAmounts[i] == self.currentTickets then
      currentTicketIndex = i
      break
    end
  end
  currentTicketIndex = currentTicketIndex + delta
  if currentTicketIndex <= 0 then
    currentTicketIndex = currentTicketIndex + #self.ticketTierAmounts
  elseif currentTicketIndex > #self.ticketTierAmounts then
    currentTicketIndex = currentTicketIndex - #self.ticketTierAmounts
  end
  self:setTickets(self.ticketTierAmounts[currentTicketIndex])
  lua_sys.playSoundFx("audio/sfx/clubbox_menu_spin_setticket_x" .. self.ticketTierAmounts[currentTicketIndex] .. ".wav")
end
function HypeGame:setTickets(count)
  self.currentTickets = math.min(math.max(count, self.ticketTierAmounts[1]), self.ticketTierAmounts[#self.ticketTierAmounts])
  game.clubboxContext():setLastHypeGameTicketAmount(self.currentTickets)
  game.engineReceiver():Send(game.MsgHypeGameCurrentTicketsSet(self.currentTickets))
  local baseWheelValues = game.getHypeWheelValues(game.HypeWheelData_POINTS)
  self.baseValues = {}
  for i = 0, baseWheelValues:size() - 1 do
    table.insert(self.baseValues, baseWheelValues[i] * self.currentTickets)
  end
  self:C("BaseHigh")("text"):SetString(self.baseValues[3])
  self:C("BaseMid")("text"):SetString(self.baseValues[2])
  self:C("BaseLow")("text"):SetString(self.baseValues[1])
  local numbers = {}
  for i = 1, 8 do
    for j, indexes in ipairs(WHEEL_INDEX_POSITIONS) do
      for _, index in ipairs(indexes) do
        if index == i then
          table.insert(numbers, self.baseValues[j])
          break
        end
      end
      if i <= #numbers then
        break
      end
    end
  end
  self.SpinWheelLeft:setDiscNumberValues(numbers)
  self.Tickets("text"):SetString("#*" .. self.currentTickets)
end
function HypeGame:spinIt()
  lua_sys.playSoundFx("audio/sfx/clubbox_menu_tap_select_small.wav")
  if self:isRunning() or self.waitingForResponse then
    return
  end
  self.waitingForResponse = true
  game.engineReceiver():Send(game.MsgHypeGameSpinButtonTouched())
  game.requestClubboxHypeGame(self.currentTickets)
end
function HypeGame:enablePlaying()
  self.waitingForResponse = false
  self.currentTime = -1000000
  self.HypeBar.Touch("enabled"):SetInt(1)
  self.HypeButton.Sprite("spriteName"):Set("button_hype")
  self:E("CloseButton"):DoStoredScript("setVisible")
end
function HypeGame:isRunning()
  return DEMO_MODE or self.currentTime >= 0
end
function HypeGame:buttonDisabled()
  return self:isRunning() or self.waitingForResponse
end
function HypeGame:setOutput(baseIndex, multiIndex)
  local base = self.baseValues[baseIndex]
  local mult = self.multiValues[multiIndex]
  self.targetBaseLights = baseIndex * 3
  self.targetMultiLights = multiIndex * 3
  self:refreshLights(false)
  self.currentResult = base .. "*" .. mult .. "=" .. base * mult
end
function HypeGame:refreshEnabledTicketAmounts()
  local currentHypeLevel = self.HypeBar:getHighestLevel() - 1
  if self.HypeBar.curClubboxAct == nil then
    return
  end
  self.ticketTierAmounts = {}
  for i = 1, #DEFAULT_TICKET_TIER_AMOUNTS do
    local canAdd = true
    for j = 1, #DEFAULT_TICKET_TIER_AMOUNTS_LOCKED_BY_HYPE do
      if DEFAULT_TICKET_TIER_AMOUNTS[i] == DEFAULT_TICKET_TIER_AMOUNTS_LOCKED_BY_HYPE[j] and currentHypeLevel < DEFAULT_TICKET_TIER_AMOUNTS_LOCKED_BY_HYPE[j] then
        canAdd = false
        break
      end
    end
    if canAdd then
      table.insert(self.ticketTierAmounts, DEFAULT_TICKET_TIER_AMOUNTS[i])
    end
  end
end
function HypeGame:onDestroy()
  if self.hypeUpdated then
    self.hypeUpdated = false
    game.triggerClubboxHypeUpdated()
    game.setClubboxPlayRate(1)
  end
end
return HypeGame
