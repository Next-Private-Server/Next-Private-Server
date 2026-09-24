local NumberCounter = include("NumberCounter")
local FlyingIcon = include("FlyingIcon")
local OffsetTransition = include("OffsetTransition")
local TweenerPingPong = include("TweenerPingPong")
local MAX_MONSTER_LEVEL = 20
local MONSTER_BREEDING_LEVEL = 4
local BreedingFeedPopup = {
  FadedBG = {},
  Panel = {},
  FoodCounter = {
    Icon = {},
    Text = {}
  },
  DescriptionText = {
    Text = {}
  },
  MonsterAnim = {
    Sprite = {},
    Touch = {}
  },
  HappyEffect = {},
  ChompEffect = {},
  LevelUpEffect = {},
  XpBar = {
    LevelText = {},
    Sprite = {}
  }
}
function BreedingFeedPopup:CreateFoodParticle()
  self.foodParticleCounter = (self.foodParticleCounter or 0) + 1
  local name = "food_particle_" .. self.foodParticleCounter
  local foodParticle = menu:addTemplateElement("template_spritesheet", "food_particle_" .. self.foodParticleCounter, self)
  foodParticle:relativeTo(self)
  foodParticle:setRelativeObjectAnchors(lua_sys.LEFT, lua_sys.TOP)
  foodParticle:setOrientation(lua_sys.MenuOrientation(0, 0, 3, lua_sys.HCENTER, lua_sys.VCENTER))
  foodParticle:init()
  foodParticle:setPositionBroadcast(true)
  foodParticle.Sprite:GetVar("spriteName"):SetString("food")
  foodParticle.Sprite:GetVar("sheetName"):SetString("xml_resources/hud01.xml")
  foodParticle.Sprite:GetVar("size"):SetFloat(0.5 * game.hudScale())
  foodParticle.Sprite:GetVar("layer"):SetString("MidPopUps")
  foodParticle.Sprite:GetVar("alpha"):SetFloat(0)
  foodParticle.flyingIcon = FlyingIcon:new({
    srcX = self.FoodCounter.Icon:absX(),
    srcY = self.FoodCounter.Icon:absY(),
    destX = self.MonsterAnim.Sprite:absX() + self.MonsterAnim.Sprite:absW() * 0.5,
    destY = self.MonsterAnim.Sprite:absY() + self.MonsterAnim.Sprite:absH() * 0.5,
    onUpdate = function(icon, x, y, alpha)
      foodParticle:GetVar("xOffset"):SetFloat(x)
      foodParticle:GetVar("yOffset"):SetFloat(y)
      foodParticle.Sprite:GetVar("alpha"):SetFloat(alpha)
    end
  })
  table.insert(self.foodParticles, foodParticle)
  foodParticle.flyingIcon:Start()
end
local function SetupMonsterSquishTransition(controller, monsterAnim)
  local startScaleX = monsterAnim.Sprite:scale().x
  local startScaleY = monsterAnim.Sprite:scale().y
  monsterAnim.Transition = TweenerPingPong:new({
    active = false,
    onUpdate = function(target, t, tweener)
      if tweener.ping == 0 then
        target:setScale(lua_sys.Vector2(startScaleX * (1 + t * 0.15), startScaleY * (1 - t * 0.15)))
      else
        target:setScale(lua_sys.Vector2(startScaleX * (1 + t * 0.15), startScaleY * (1 - t * 0.15)))
      end
    end,
    onPing = function(tweener)
      tweener.ease = lua_sys.Elastic_EaseOut
      tweener.duration = 0.6
    end,
    onPong = function(tweener)
      if tweener.monsterId and tweener.monsterId > 0 then
        monsterAnim.Sprite:setScale(lua_sys.Vector2(startScaleX, startScaleY))
      end
      tweener.active = false
    end
  })
  monsterAnim.Transition.targets = {
    monsterAnim.Sprite
  }
  table.insert(controller.tickables, monsterAnim.Transition)
  function monsterAnim:PlaySquish(monsterId)
    if not self.Transition.active then
      self.Transition:Reset()
      self.Transition.active = true
      self.Transition.ease = lua_sys.Back_EaseOut
      self.Transition.loopTime = 0.3
      self.Transition.monsterId = monsterId
      lua_sys.playSoundFx("audio/sfx/item_select.wav")
      game.playMonsterSelectSound(monsterId, 0)
      controller.HappyEffect:start()
    end
  end
end
function BreedingFeedPopup:Setup(monster)
  self.monster = monster
  local monsterData = self.monster:data()
  local animFile = monsterData:animationFile()
  if monsterData:isModal() then
    local currentMode = game.player():getActiveIsland():islandMode()
    modalMonsterData = game.getModalMonsterData(monsterData, currentMode)
    animFile = modalMonsterData:animationFile()
  end
  self.MonsterAnim.Sprite:GetVar("animationName"):SetString("xml_bin/" .. animFile)
  self.MonsterAnim.Sprite:GetVar("animation"):SetString("Store")
  local costumeId = monster:getEquippedCostume()
  if costumeId > 0 then
    game.applyCostumeToAnimComponent(self.MonsterAnim.Sprite, costumeId)
  end
  self.MonsterAnim.Sprite:GetVar("offsetCenter"):SetInt(1)
  self.counter = NumberCounter:new(game.playerFood())
  self.FoodCounter.Text:GetVar("text"):SetString(game.commaizeNumber(game.playerFood()))
  self.XpBar.LevelText:GetVar("text"):SetString(game.getLocalizedText("LEVEL") .. " " .. self.monster:level())
  if self.monster then
    self.targetXpPercentage = self.monster:timesFed() / 4
    self.targetLevel = self.monster:level()
    if self.feedCostElement then
      self.feedCostElement:GetComponent("Text"):GetVar("text"):SetString("-" .. game.commaizeNumber(self.monster:foodRequired()))
    end
  end
  self.currentXpPercentage = self.targetXpPercentage
  self.currentLevel = self.targetLevel
  self.targetXpAccumulated = self.currentLevel + self.currentXpPercentage - 1
  self.currentXpAccumulated = self.targetXpAccumulated
  self:updateXpBar()
end
function BreedingFeedPopup:onInit()
  self.tickables = {}
  self:setSearchChildren(false)
  self.pendingUpdates = {}
  self.processingUpdates = false
  self.foodParticleCounter = 0
  self.foodParticles = {}
  manager:setContext("BREED_FEED")
  function self.Panel.onDoneHide()
    self:root():popPopUp()
  end
  self.FoodCounter.offsetTransition = OffsetTransition:new({
    startX = -200 * BreedingMenuScaleX(),
    endX = 32 * BreedingMenuScaleX(),
    ease = lua_sys.Quadratic_EaseIn,
    onUpdate = function(x, y)
      self.FoodCounter:GetVar("xOffset"):SetFloat(x)
    end
  })
  self.FoodCounter.offsetTransition:Show()
  self.FoodCounter.offsetTransition:Tick(0)
  self:SetupGenericListener(game.engineReceiver(), "game::msg::MsgContextBarStateChange", "gotMsgContextBarStateChange")
  self:SetupGenericListener(game.engineReceiver(), "game::msg::MsgPlayerUpdated", "gotMsgPlayerUpdated")
  self:SetupGenericListener(game.engineReceiver(), "game::msg::MsgMonsterUpdated", "gotMsgMonsterUpdated")
  self:SetupGenericListener(game.engineReceiver(), "game::msg::MsgMonsterLevelUp", "gotMsgMonsterLevelUp")
end
function BreedingFeedPopup:onPostInit()
  SetupMonsterSquishTransition(self, self.MonsterAnim)
  function self.MonsterAnim.Touch.onTouchUp()
    if not self.MonsterAnim.Transition.active then
      self.MonsterAnim:PlaySquish(self.monster:data():monsterId())
    end
  end
end
function BreedingFeedPopup:gotMsgContextBarStateChange(msg)
  if msg.state == game.ContextBar_ENTERING and manager:getContext() == "BREED_FEED" then
    if self.monster and self.monster:level() >= MAX_MONSTER_LEVEL then
      manager:setButtonVisible("btn_feed", false)
    else
      local feedButton = manager:getButton("btn_feed")
      if feedButton then
        self.feedCostElement = feedButton:GetElement("attachedTemplate")
      end
    end
    self:updateMonster()
  end
end
function BreedingFeedPopup:gotMsgPlayerUpdated(msg)
  if self.counter then
    self.counter:setNumber(game.playerFood())
  end
end
function BreedingFeedPopup:gotMsgMonsterUpdated(msg)
  if self.monster and msg.id_ == self.monster:uniqueId() and self.feedCostElement then
    self.feedCostElement:GetComponent("Text"):GetVar("text"):SetString("-" .. game.commaizeNumber(self.monster:foodRequired()))
  end
end
function BreedingFeedPopup:gotMsgMonsterLevelUp(msg)
  if self.monster and msg.id == self.monster:uniqueId() and self.monster:level() >= MAX_MONSTER_LEVEL then
    manager:setButtonVisible("btn_feed", false)
  end
end
function BreedingFeedPopup:updateMonster()
  if self.monster then
    self.targetXpPercentage = self.monster:timesFed() / 4
    self.targetLevel = self.monster:level()
    if self.feedCostElement then
      self.feedCostElement:GetComponent("Text"):GetVar("text"):SetString("-" .. game.commaizeNumber(self.monster:foodRequired()))
    end
  end
end
function BreedingFeedPopup:updateXpBar()
  local fullMaskW = self.XpBar.Sprite:GetVar("FullMaskW"):GetFloat()
  if self.XpBar.Sprite:GetVar("isSourceRotated"):GetInt() == 1 then
    self.XpBar.Sprite:GetVar("maskHeight"):SetInt(fullMaskW * self.currentXpPercentage)
  else
    self.XpBar.Sprite:GetVar("maskWidth"):SetInt(fullMaskW * self.currentXpPercentage)
  end
end
function BreedingFeedPopup:processNextUpdate()
  if #self.pendingUpdates > 0 and not self.processingUpdates then
    local update = table.remove(self.pendingUpdates, 1)
    self.processingUpdates = true
    self.targetXpPercentage = update.targetXpPercentage
    self.targetLevel = update.targetLevel
    self.isUpdatingXp = true
    return true
  else
    return false
  end
end
local XP_ANIMATION_SPEED = 1
function BreedingFeedPopup:onTick(dt)
  dt = math.min(dt, 0.033)
  for _, tickable in ipairs(self.tickables) do
    if tickable.Tick then
      tickable:Tick(dt)
    end
  end
  if self.counter and self.counter:tick(dt) then
    self.FoodCounter.Text:GetVar("text"):SetString(game.commaizeNumber(self.counter.curNum))
  end
  self.FoodCounter.offsetTransition:Tick(dt)
  for _, foodParticle in ipairs(self.foodParticles) do
    foodParticle.flyingIcon:Tick(dt)
  end
  for i = #self.foodParticles, 1, -1 do
    local foodParticle = self.foodParticles[i]
    if foodParticle.flyingIcon:IsDone() then
      self.ChompEffect:start()
      self.targetXpAccumulated = self.targetXpAccumulated + 0.25
      table.remove(self.foodParticles, i)
      self:RemoveElement(foodParticle)
    end
  end
  if self.currentXpAccumulated < self.targetXpAccumulated then
    local xpDelta = math.min(XP_ANIMATION_SPEED * dt, self.targetXpAccumulated - self.currentXpAccumulated)
    self.currentXpAccumulated = math.min(self.currentXpAccumulated + xpDelta, self.targetXpAccumulated)
    local newLevel = math.floor(self.currentXpAccumulated) + 1
    local newXpPercentage = self.currentXpAccumulated - math.floor(self.currentXpAccumulated)
    if newLevel > self.currentLevel then
      self.currentLevel = newLevel
      self.LevelUpEffect:start()
      self.XpBar.LevelText:GetVar("text"):SetString(game.getLocalizedText("LEVEL") .. " " .. self.currentLevel)
      if self.currentLevel >= MONSTER_BREEDING_LEVEL then
        self.DescriptionText.Text:GetVar("text"):SetString("BREEDING_FEED_READY")
      end
    end
    self.currentXpPercentage = newXpPercentage
    self:updateXpBar()
  end
end
function BreedingFeedPopup:queuePop()
  manager:setContext("BREED_MENU_V2")
  self.Panel:Hide()
  self.FadedBG:Hide()
  self.FoodCounter.offsetTransition:Hide()
end
function BreedingFeedPopup:feedMonster()
  if self.monster and self.monster:level() < MAX_MONSTER_LEVEL and game.clearPurchase(game.CurrencyType_Food, self.monster:foodRequired(), game.PurchaseType_FEED_MONSTER_breed_menu, self.monster:entityId()) then
    self.monster:feed()
    self:CreateFoodParticle()
  end
end
return BreedingFeedPopup
