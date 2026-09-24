local FlipCardBase = {}
local FadeTransition = include("FadeTransition")
local OffsetTransition = include("MenuElementPositionOffsetTransition")
local fadeTransitionDuration = 0.1
local CFlipQuitTouch = {}
local ECards = {}
FlipCardBase.topMargin = 68
FlipCardBase.bottomMargin = 13
FlipCardBase.boardHeight = 0
FlipCardBase.menuAnchor = 0
FlipCardBase.boardCenterOffsetX = 0
FlipCardBase.boardCenterOffsetY = 0
function CFlipQuitTouch:quitGame(element)
  game.displayConfirmation("QUIT_FLIP_CONF", "QUIT_FLIP_CONF_MSG")
end
FlipCardBase._CFlipQuitTouch = CFlipQuitTouch
ECards.NumCards = 0
ECards.curRevealed = 0
ECards.levelEndCalled = false
function ECards:updateComponents()
  local alpha = self:V("alpha"):GetFloat()
  for i = 0, self.NumCards - 1 do
    local cardEntry = self:E("cardEntry" .. i)
    if cardEntry ~= nil and cardEntry:E("CharacterImage").doFadeOut then
      cardEntry:E("CharacterImage"):V("alpha"):SetFloat(alpha)
      cardEntry:E("CharacterImage"):updateComponents()
    end
  end
end
function ECards:InitFadeTransition()
  self.FadeTransition = FadeTransition:new({
    duration = fadeTransitionDuration,
    maxFade = 1,
    onDoneHide = function(e)
      self:V("alpha"):SetFloat(0)
      self:updateComponents()
      self:StartCardOffsetTransition()
    end,
    onUpdate = function(alpha)
      self:V("alpha"):SetFloat(alpha)
      self:updateComponents()
    end
  })
  self.FadeTransition:SetAlpha(1)
  for i = 0, self.NumCards - 1 do
    local cardEntry = self:E("cardEntry" .. i)
    if cardEntry ~= nil and not cardEntry:E("CharacterImage").doFadeOut then
      cardEntry:E("CharacterImage"):InitColourTransition(fadeTransitionDuration, 1)
    end
  end
end
function ECards:StartCardOffsetTransition()
  for i = 0, self.NumCards - 1 do
    local cardEntry = self:E("cardEntry" .. i)
    if cardEntry ~= nil and not cardEntry:E("CharacterImage").doFadeOut then
      cardEntry:E("CharacterImage"):StartCardOffsetTransition()
    end
  end
end
function ECards:startEndLevelSequence()
  self.FadeTransition:Hide()
  for i = 0, self.NumCards - 1 do
    local cardEntry = self:E("cardEntry" .. i)
    if cardEntry ~= nil and not cardEntry:E("CharacterImage").doFadeOut then
      cardEntry:E("CharacterImage"):StartColourTransition()
    end
  end
end
function ECards:tickEndLevelSequence(dt)
  self.FadeTransition:Tick(dt)
  for i = 0, self.NumCards - 1 do
    local cardEntry = self:E("cardEntry" .. i)
    if cardEntry ~= nil and not cardEntry:E("CharacterImage").doFadeOut then
      cardEntry:E("CharacterImage"):tickColourTransition(dt)
    end
  end
end
function ECards:onDoneEndLevelCardOffset(cardInd)
  if not self.levelEndCalled then
    self.levelEndCalled = true
    game.playFlipcardSelectSound(cardInd)
    self:parent():ShowFlyingIconToHud(cardInd)
  end
end
function ECards:populate()
  self:parent():E("coinCounter"):DoStoredScript("updateText")
  self:parent():E("diamondCounter"):DoStoredScript("updateText")
  self:parent():E("foodCounter"):DoStoredScript("updateText")
  self:parent():E("keysCounter"):DoStoredScript("updateText")
  self:parent():E("shardCounter"):DoStoredScript("updateText")
  self:parent():E("xpCounter"):DoStoredScript("updateText")
  self.levelEndCalled = false
  self.curRevealed = 0
  for i = 0, self.NumCards - 1 do
    local cardEntry = self:E("cardEntry" .. i)
    if cardEntry ~= nil then
      self:RemoveElement(cardEntry)
    end
  end
  local scaleFactor = game.getFlipCardScale()
  local cards = game.getFlipCards()
  for i = 0, cards:size() - 1 do
    local cardEntry = menu:addTemplateElement("template_flip_card_entry", "cardEntry" .. i, self)
    cardEntry("CardInd"):SetInt(i)
    cardEntry("ScaleFactor"):SetFloat(scaleFactor)
    cardEntry:setParent(self)
    cardEntry:relativeTo(self)
    cardEntry:setScale(lua_sys.Vector2(scaleFactor, scaleFactor))
    local pos = game.getFlipCardPos(i)
    cardEntry:setOrientation(lua_sys.MenuOrientation(self:parent().boardCenterOffsetX / scaleFactor + pos.x * scaleFactor, self:parent().boardCenterOffsetY / scaleFactor + pos.y * scaleFactor, 10, lua_sys.HCENTER, lua_sys.VCENTER))
    cardEntry:setRelativeObjectAnchors(lua_sys.HCENTER, lua_sys.VCENTER)
    cardEntry:setPositionBroadcast(false)
    cardEntry:init()
  end
  self:setPositionBroadcast(true)
  self:postInit()
  self.NumCards = cards:size()
  self:parent():E("Title"):C("Text"):V("text"):SetString(game.getLocalizedText("LEVEL") .. " " .. game.curFlipLevel() .. "/" .. game.getFlipLevels())
  if game.limitFlipMismatches() then
    self:parent():E("Mismatches"):C("Text"):V("text"):SetString(game.getLocalizedText("FLIP_MISMATCHES_REMAINING") .. " " .. game.curFlipMismatches())
    self:parent():E("Mismatches"):C("Text"):V("visible"):SetInt(1)
  end
  self:InitFadeTransition()
end
FlipCardBase._ECards = ECards
FlipCardBase.eCards = nil
FlipCardBase.displayTimer = 0
FlipCardBase.levelTimer = 0
FlipCardBase.cRewardParticle = nil
function FlipCardBase:nextLevel()
  self.levelTimer = 0.5
end
function FlipCardBase:disableCards()
  for i = 0, self.eCards.NumCards - 1 do
    self.eCards:E("cardEntry" .. i):E("CharacterImage"):C("Touch"):V("enabled"):SetInt(0)
  end
  self.displayTimer = 1
  self:E("Mismatches"):C("Text"):V("text"):SetString(game.getLocalizedText("FLIP_MISMATCHES_REMAINING") .. " " .. game.curFlipMismatches())
end
function ECards:tomNookIsAJerk()
  if game.isQABuild() then
    for i = 0, self.NumCards - 1 do
      local cardEntry = self:E("cardEntry" .. i)
      if cardEntry ~= nil then
        cardEntry:E("CharacterImage"):someCrapTest()
      end
    end
  end
end
FlipCardBase.newVal = 0
FlipCardBase.curRewardElement = nil
function FlipCardBase:ShowFlyingIconToHud(cardInd)
  self.cRewardParticle = self:E("RewardParticle")
  local startX = lua_sys.screenWidth() / 2 + self.boardCenterOffsetX
  local startY = lua_sys.screenHeight() / 2 + self.boardCenterOffsetY
  local curName = game.getFlipEmbeddedSprite()
  self.curRewardElement = self:E(curName .. "Counter")
  local textVal = self.curRewardElement:C("Text"):V("text"):GetString():gsub("%,", "")
  local oldVal = tonumber(textVal)
  if oldVal ~= nil then
    self.newVal = oldVal + game.getFlipcardAmt(cardInd)
  else
    self.newVal = nil
  end
  local goalX = self.curRewardElement:absX() + self.curRewardElement:absW() / 2
  local goalY = self.curRewardElement:absY() + self.curRewardElement:absH() / 2
  OffsetTransition.OnInit(self.cRewardParticle, {
    startX = startX,
    startY = startY,
    endX = goalX,
    endY = goalY,
    duration = 0.5
  })
  self:E("Title"):C("Text"):V("text"):SetString("FLIP_LEVEL_COMPLETE")
  self:E("Mismatches"):C("Text"):V("visible"):SetInt(0)
  self:E("coinCounter"):DoStoredScript("show")
  self:E("diamondCounter"):DoStoredScript("show")
  self:E("foodCounter"):DoStoredScript("show")
  self:E("keysCounter"):DoStoredScript("show")
  self:E("shardCounter"):DoStoredScript("show")
  self:E("xpCounter"):DoStoredScript("show")
  self.cRewardParticle:C("Sprite"):V("spriteName"):SetString(curName)
  self.cRewardParticle:C("Sprite"):V("visible"):SetInt(1)
  OffsetTransition.Show(self.cRewardParticle)
end
function FlipCardBase:ResetHud()
  self:E("coinCounter"):DoStoredScript("hide")
  self:E("diamondCounter"):DoStoredScript("hide")
  self:E("foodCounter"):DoStoredScript("hide")
  self:E("keysCounter"):DoStoredScript("hide")
  self:E("shardCounter"):DoStoredScript("hide")
  self:E("xpCounter"):DoStoredScript("hide")
  self:E("PrizeTier"):C("Icon"):V("spriteName"):SetString("emote01")
end
function FlipCardBase:onInit()
  self.boardCenterOffsetX = 0
  self.boardHeight = lua_sys.screenHeight() - (self.topMargin * game.menuScaleY() + self.bottomMargin)
  self.menuAnchor = lua_sys.screenHeight() / 2
  self.boardCenterOffsetY = -self.menuAnchor + self.topMargin * game.menuScaleY() + self.boardHeight / 2
  self.eCards = self:E("Cards")
  self.eCards.updateComponents = ECards.updateComponents
  self.eCards.InitFadeTransition = ECards.InitFadeTransition
  self.eCards.startEndLevelSequence = ECards.startEndLevelSequence
  self.eCards.tickEndLevelSequence = ECards.tickEndLevelSequence
  self.eCards.populate = ECards.populate
  self.eCards.StartCardOffsetTransition = ECards.StartCardOffsetTransition
  self.eCards.onDoneEndLevelCardOffset = ECards.onDoneEndLevelCardOffset
  self.eCards.tomNookIsAJerk = ECards.tomNookIsAJerk
  self.eCards.NumCards = 0
  self.eCards:populate()
  self.levelTimer = 0
  self:E("QuitButton"):C("Touch").quitGame = CFlipQuitTouch.quitGame
end
function FlipCardBase:enableCards()
  self.eCards.curRevealed = 0
  for i = 0, self.eCards.NumCards - 1 do
    if self.eCards:E("cardEntry" .. i):E("CharacterImage"):C("Sprite"):V("spriteName"):GetString() == "gfx/breeding/monster_portrait_random" then
      self.eCards:E("cardEntry" .. i):E("CharacterImage"):C("Touch"):V("enabled"):SetInt(1)
    end
  end
end
function FlipCardBase:onTick(dt)
  local timer = self.displayTimer
  if timer > 0 then
    timer = timer - dt
    if timer <= 0 then
      game.resetCardMatch()
      self:enableCards()
    end
  end
  self.displayTimer = timer
  timer = self.levelTimer
  if timer > 0 then
    timer = timer - dt
    if timer <= 0 then
      self:ResetHud()
      self.eCards:populate()
    end
  end
  self.levelTimer = timer
  self.eCards:tickEndLevelSequence(dt)
  if self.cRewardParticle ~= nil then
    OffsetTransition.OnTick(self.cRewardParticle, dt, {
      ease = lua_sys.Cubic_EaseIn,
      onDoneShow = function(e)
        self.cRewardParticle:C("Sprite"):V("visible"):SetInt(0)
        if self.curRewardElement ~= nil and self.newVal ~= nil then
          self.curRewardElement:C("Text"):V("text"):SetString(game.commaizeNumber(self.newVal))
        end
        game.flipgameEndlevelComplete()
      end
    })
  end
end
return FlipCardBase
