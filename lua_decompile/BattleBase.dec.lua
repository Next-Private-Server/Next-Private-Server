local Battle = include("Battle")
local FadeTransition = include("FadeTransition")
local _QuitButton = {
  Touch = {}
}
local _HelpButton = {
  Touch = {}
}
local _SwapButton = {
  Touch = {}
}
local BasePlayerHUD = {}
function BasePlayerHUD:new(obj)
  local obj = obj or {}
  setmetatable(obj, self)
  self.__index = self
  return obj
end
local _ActionBar = {}
local _Status = {
  Sprite = {},
  Text = {}
}
local BattleBase = {
  QuitButton = _QuitButton,
  HelpButton = _HelpButton,
  SwapButton = _SwapButton,
  PlayerHUD = BasePlayerHUD:new({
    target = "PlayerHealthBar"
  }),
  OpponentHUD = BasePlayerHUD:new({
    target = "OpponentHealthBar"
  }),
  PlayerTeamAvatarView = {},
  OpponentTeamAvatarView = {},
  ActionBar = _ActionBar,
  Status = _Status,
  PlayerTeamPortraitView = {},
  OpponentTeamPortraitView = {}
}
function BattleBase:onInit()
  lua_sys.playMP3("audio/music/store_music")
end
function BattleBase:updatePortraits()
  self.PlayerHUD.ActivePlayerPortrait:DoStoredScript("refresh")
  self.OpponentHUD.ActiveOpponentPortrait:DoStoredScript("refresh")
  self.PlayerTeamPortraitView.member1:DoStoredScript("refresh")
  self.PlayerTeamPortraitView.member2:DoStoredScript("refresh")
  self.OpponentTeamPortraitView.member1:DoStoredScript("refresh")
  self.OpponentTeamPortraitView.member2:DoStoredScript("refresh")
end
function BattleBase:setPlayerTurn(teamId)
  if teamId == 0 then
    self.PlayerHUD:DoStoredScript("fadeIn")
    self.OpponentHUD:DoStoredScript("fadeOut")
  elseif teamId == 1 then
    self.PlayerHUD:DoStoredScript("fadeOut")
    self.OpponentHUD:DoStoredScript("fadeIn")
  end
end
function _QuitButton:onInit()
  self:super_onInit()
  self:SetupGenericListener(game.engineReceiver(), "game::msg::MsgConfirmationSubmission", "gotMsgConfirmationSubmission")
end
function _QuitButton:gotMsgConfirmationSubmission(msg)
  if msg.messageID == "EXIT_BATTLE" and msg.choice then
    Battle.Quit(self)
  end
end
function _QuitButton.Touch:onTouchUp(element)
  self:super_onTouchUp(element)
  element.Overlay:setColor(1, 1, 1)
  if game.getBattleClientData():getBattleCreateSettings().isPVP then
    if game.getBattleClientData():getBattleCreateSettings().isFriendVersus then
      game.displayConfirmation("EXIT_BATTLE", "BATTLE_FRIEND_EXIT_CONFIRMATION")
    else
      game.displayConfirmation("EXIT_BATTLE", "BATTLE_VERSUS_EXIT_CONFIRMATION")
    end
  else
    game.displayConfirmation("EXIT_BATTLE", "BATTLE_EXIT_CONFIRMATION")
  end
end
function _HelpButton.Touch:onTouchUp(element)
  self:super_onTouchUp(element)
  element.Overlay:setColor(1, 1, 1)
  if game.openHelpshiftFAQWithTag ~= nil then
    game.openHelpshiftFAQWithTag("battle-mode")
  end
end
function _SwapButton.Touch:onTouchUp(element)
  self:super_onTouchUp(element)
  element.Overlay:setColor(1, 1, 1)
  game.battleSystem():getViewReceiver():Send(game.MsgBattleAction(game.MsgBattleAction_Swap, -1))
end
function BasePlayerHUD:onInit()
  local fadeTarget = self:GetElement(self.target).TextBG.Sprite
  self.FadeTransition = FadeTransition:new({
    duration = 0.5,
    initialState = -1,
    onUpdate = function(alpha)
      fadeTarget:GetVar("alpha"):SetFloat(alpha)
    end
  })
end
function BasePlayerHUD:fadeIn()
  self.FadeTransition:Show()
end
function BasePlayerHUD:fadeOut()
  self.FadeTransition:Hide()
end
function BasePlayerHUD:onTick(dt)
  self.FadeTransition:Tick(dt)
end
function _ActionBar:onInit()
  self.transitionState = 0
  self.transitionTime = 0
  self.TRANSITION_TIME = 0.66
  self:GetVar("yOffset"):SetFloat(-200 * game.battleScale())
end
function _ActionBar:setVisible()
  self.transitionState = 1
  self.transitionTime = self.TRANSITION_TIME
  lua_sys.playSoundFx("audio/sfx/menu_slide.wav")
end
function _ActionBar:setInvisible(instant)
  if instant == 1 then
    self.transitionTime = 0
    self:GetVar("yOffset"):SetFloat(-200 * game.battleScale())
  else
    self.transitionState = -1
    self.transitionTime = self.TRANSITION_TIME
    lua_sys.playSoundFx("audio/sfx/menu_slide.wav")
  end
end
function _ActionBar:onTick(dt)
  if self.transitionTime > 0 then
    self.transitionTime = math.max(0, self.transitionTime - dt)
    local offsetY = self:GetVar("yOffset"):GetFloat()
    if self.transitionState == -1 then
      local easedTime = 1 - lua_sys.Back_EaseIn(self.transitionTime, 0, 1, self.TRANSITION_TIME)
      offsetY = lerp(10 * game.battleScale(), -200 * game.battleScale(), easedTime)
    end
    if self.transitionState == 1 then
      local easedTime = 1 - lua_sys.Back_EaseIn(self.transitionTime, 0, 1, self.TRANSITION_TIME)
      offsetY = lerp(-200 * game.battleScale(), 10 * game.battleScale(), easedTime)
    end
    self:GetVar("yOffset"):SetFloat(offsetY)
  end
end
function _ActionBar:resetActions()
  for i = 0, 3 do
    local actionButton = self:GetElement("ActionButton" .. i)
    actionButton:setInvisible()
  end
end
function _ActionBar:doTutorialCheck()
  if game.tutorialDisableFirstAttackButton() then
    self:GetElement("ActionButton0"):setDisabled()
  else
    self:GetElement("ActionButton0"):setEnabled()
  end
end
function _ActionBar:updateAction(componentIdx, text, unlocked, iconSprite, iconSpriteSheet, elemental, elementalResistance)
  local actionButtonId = "ActionButton" .. componentIdx
  local actionButton = self:GetElement(actionButtonId)
  if actionButton then
    actionButton("elementalResistance"):SetFloat(elementalResistance)
    actionButton:DoStoredScript("setVisible")
    if unlocked == 1 then
      actionButton:DoStoredScript("setUnlocked")
    else
      actionButton:DoStoredScript("setLocked")
    end
    actionButton.ActionName("size"):SetFloat(0.25 * game.battleScale())
    actionButton.ActionName("text"):SetString("")
    actionButton.ActionName("text"):SetString(text)
    actionButton.Icon("spriteName"):SetString(iconSprite)
    actionButton.Icon("sheetName"):SetString(iconSpriteSheet)
    actionButton.ActionTypeName("size"):SetFloat(0.16 * game.battleScale())
    if elemental == 1 then
      actionButton.ActionTypeName("text"):SetString("BATTLE_ACTION_ELEMENTAL")
    else
      actionButton.ActionTypeName("text"):SetString("BATTLE_ACTION_REGULAR")
    end
    actionButton:DoStoredScript("updateElementalResistance")
    if componentIdx == 0 and game.tutorialDisableFirstAttackButton() then
      actionButton:DoStoredScript("setDisabled")
    end
  end
end
function _Status:onInit()
  self.FadeTime = 0
  self.transitionState = -1
  self.transitionTime = 0
  self.TRANSITION_TIME = 0.5
end
function _Status:showAction(name, elemental, team)
  print("Elemental:", elemental)
  self.Text:GetVar("text"):SetString(name)
  self.Text:GetVar("size"):SetFloat(0.5 * game.menuScaleX())
  self.FadeTime = 1.5
  self:setSize(lua_sys.Vector2(self.Text:absW() + 64 * game.menuScaleX(), 56 * game.menuScaleY()))
  self.Sprite:GetVar("alpha"):SetFloat(1)
  if team == 0 then
    self:GetVar("xOffset"):SetFloat(-220 * game.menuScaleX())
    self.transitionState = 1
    self.transitionTime = self.TRANSITION_TIME
  elseif team == 1 then
    self:GetVar("xOffset"):SetFloat(220 * game.menuScaleX())
    self.transitionState = -1
    self.transitionTime = self.TRANSITION_TIME
  end
end
function _Status:onTick(dt)
  if self.transitionTime > 0 then
    self.transitionTime = math.max(0, self.transitionTime - dt)
    local offsetX = self:GetVar("xOffset"):GetFloat()
    local easedTime = 1 - lua_sys.Back_EaseIn(self.transitionTime, 0, 1, self.TRANSITION_TIME)
    if self.transitionState == -1 then
      offsetX = lerp(220 * game.menuScaleX(), 0, easedTime)
    end
    if self.transitionState == 1 then
      offsetX = lerp(-220 * game.menuScaleX(), 0, easedTime)
    end
    self:GetVar("xOffset"):SetFloat(offsetX)
  end
  local t = self.FadeTime
  if t > 0 then
    t = t - dt
    if t < 0 then
      t = 0
    end
    self.FadeTime = t
    local fadeTime = 0.33
    if t > fadeTime then
      self.Text:GetVar("alpha"):SetFloat(1)
      self.Sprite:GetVar("alpha"):SetFloat(1)
    else
      self.Text:GetVar("alpha"):SetFloat(t / fadeTime)
      self.Sprite:GetVar("alpha"):SetFloat(t / fadeTime)
    end
  end
end
return BattleBase
