local OldOffsetTransition = include("MenuElementPositionOffsetTransition")
local FadeTransition = include("FadeTransition")
local MenuHelpers = include("MenuHelpers")
local ScrollingPatternShader = include("ShaderScrollingPattern")
local FlyingIcon = include("FlyingIcon")
local root
local transitionDuration = 0.5
local RewardsBehaviour = {
  Faders = {},
  Fade = {
    Touch = {}
  }
}
local StoreBundleRewardsPopupUI = {
  Rewards = RewardsBehaviour,
  Contents = {},
  Title = {
    Text = {}
  }
}
function StoreBundleRewardsPopupUI:Show(contents)
  self.Rewards:Show(contents)
  self.FadeTransition:Show()
  lua_sys.playSoundFx("audio/sfx/menu_slide.wav")
end
function StoreBundleRewardsPopupUI:Hide()
  self.Contents.autoScrollEnabled = false
  self.endTriggers = {}
  local currentOffset = self.Contents:GetCurrentOffset()
  local contentSize = self.Contents:GetContentSize()
  local viewSize = self.Contents:GetViewSize()
  local idx = 0
  for _, v in ipairs(self.Contents.items) do
    do
      local x = v:absX()
      if 0 < x + v:absH() and viewSize > x then
        table.insert(self.endTriggers, {
          delay = math.max(idx * 0.45, 0.01),
          func = function()
            v:SetVisible(false)
            lua_sys.playSoundFx(string.format("audio/sfx/bundlereward_particlesplash_%02d.ogg", math.random(1, 3)))
            v.ParticleSplash.Sprite("visible"):SetInt(1)
            v.ParticleSplash.Sprite:Play()
            if v.appearance.iconName and v.appearance.iconSheet then
              local amount = v.data.amount or 1
              local c = 0.1
              for i = 1, math.min(10, amount) do
                local spreadX = amount == 1 and 0 or (math.random() * 2 - 1) * 32 * game.hudScale()
                local spreadY = amount == 1 and 0 or (math.random() * 2 - 1) * 32 * game.hudScale()
                local iconName = v.appearance.iconName
                if type(iconName) == "function" then
                  iconName = iconName()
                end
                FlyingIcon.Create({
                  parent = menu,
                  layer = "Tutorial",
                  spriteName = iconName,
                  sheetName = v.appearance.iconSheet,
                  size = v.appearance.iconScale,
                  delayOnStart = 0.25 + idx * 0.3 + i * c,
                  srcX = v:absX() + v:absW() * 0.5 + spreadX,
                  srcY = v:absY() + v:absH() * 0.5 + spreadY,
                  destX = v.appearance.iconDestX,
                  destY = v.appearance.iconDestY,
                  collectSound = v.appearance.soundFile,
                  onComplete = i == 1 and v.appearance.onComplete or nil
                })
                c = c - 0.005
              end
            end
          end
        })
        idx = idx + 1
      end
    end
  end
end
function StoreBundleRewardsPopupUI:Close()
  self:root():removePopUp(self:name())
  if self.Contents.hasCurIslandThemeUnlock then
    game.loadWorldContext()
  elseif game.player():currentlyActiveCardAlbum() ~= nil then
    local cardAlbum = game.player():currentlyActiveCardAlbum()
    if cardAlbum:hasUncollectedCardPacks() then
      game.pushPopUp("open_card_pack")
    elseif cardAlbum:hasUncollectedPageRewards() then
      game.pushPopUp("card_album_page_reward_collect")
    elseif cardAlbum:hasUncollectedAlbumRewards() then
      game.pushPopUp("card_album_reward_collect")
    elseif game.hasDoubleEncoreRewardTrackAvailable() then
      game.pushPopUp("popup_extra_encore_rewards")
    end
  elseif game.hasDoubleEncoreRewardTrackAvailable() then
    game.pushPopUp("popup_extra_encore_rewards")
  end
end
function StoreBundleRewardsPopupUI:onInit()
  root = self
  self.FadeTransition = FadeTransition:new({
    duration = transitionDuration,
    ease = lua_sys.Quadratic_EaseIn,
    onDoneHide = function()
      self:Close()
    end,
    onUpdate = function(alpha)
      self.Title.Text:GetVar("alpha"):SetFloat(alpha)
      self.Contents.alpha = alpha
    end
  })
  self.FadeTransition:SetAlpha(0)
end
function StoreBundleRewardsPopupUI:Setup(contents)
  self.Contents:populate(contents, {variation = 1})
  self:Show(contents)
end
function StoreBundleRewardsPopupUI:queuePop()
  self:Hide()
end
function StoreBundleRewardsPopupUI:onDestroy()
end
function StoreBundleRewardsPopupUI:onTick(dt)
  dt = math.min(dt, 0.033)
  self.FadeTransition:Tick(dt)
  if self.endTriggers then
    local active = 0
    for k, v in ipairs(self.endTriggers) do
      if 0 < v.delay then
        active = active + 1
        v.delay = v.delay - dt
        if 0 >= v.delay then
          v.func()
        end
      end
    end
    if active == 0 then
      self.endTimer = 1
      self.endTriggers = nil
    end
  end
  if self.endTimer and 0 < self.endTimer then
    self.endTimer = self.endTimer - dt
    if 0 >= self.endTimer then
      lua_sys.playSoundFx("audio/sfx/menu_slide.wav")
      self.Rewards:Hide()
      self.FadeTransition:Hide()
    end
  end
end
function RewardsBehaviour:onInit()
  self.isShowing = false
  self.isDoneSequence = false
  self.sequenceTimeRemaining = 0
  local width = lua_sys.screenWidth()
  local height = 220 * game.hudScale()
  self:SetBGSpites("gfx/menu/gradient_bg_general", "gfx/menu/bg_symbols_m")
  if ScrollingPatternShader then
    ScrollingPatternShader:getUniform("u_TexParams"):setVec4(lua_sys.Vector4(1, 1, 8 * (width / height), 8))
  end
  self.RewardsBG.Pattern:setShader(ScrollingPatternShader)
  table.insert(self.Faders, self.RewardsBG.Sprite)
  table.insert(self.Faders, self.RewardsBG.Pattern)
  table.insert(self.Faders, self.ClaimInfo.Text)
  self.ContinueLabel.Text.FadeTransition = FadeTransition:new({
    delayOnShow = 1,
    duration = 1,
    maxFade = 1,
    onUpdate = function(alpha)
      self.ContinueLabel.Text:GetVar("alpha"):SetFloat(alpha)
    end
  })
  self.ContinueLabel.Text.FadeTransition:SetAlpha(0)
  local function initBar(e, startX, endX)
    e:GetVar("xOffset"):SetFloat(startX)
    OldOffsetTransition.OnInit(e, {
      startX = startX,
      endX = endX,
      duration = transitionDuration
    })
    table.insert(self.Faders, e.Sprite)
  end
  initBar(self.RewardsTopBar, lua_sys.screenWidth(), 0)
  initBar(self.RewardsBottomBar, -lua_sys.screenWidth(), 0)
  self.FadeTransition = FadeTransition:new({
    duration = transitionDuration,
    ease = lua_sys.Quadratic_EaseIn,
    onDoneHide = function()
      for _, fader in ipairs(self.Faders) do
        fader:GetVar("visible"):SetInt(0)
      end
    end,
    onUpdate = function(alpha)
      for _, fader in ipairs(self.Faders) do
        local maxA = math.min(alpha, fader.maxFade or 1)
        fader:GetVar("alpha"):SetFloat(maxA)
        if fader.updateAlpha then
          fader:updateAlpha(maxA)
        end
      end
    end
  })
  self.FadeTransition:SetAlpha(0)
end
function RewardsBehaviour:onDestroy()
  local shader = game.getShader("ShaderScrollingPattern")
  if shader then
    shader:getUniform("u_TexParams"):setVec4(lua_sys.Vector4(128 * game.hudScale() / lua_sys.screenWidth(), 128 * game.hudScale() / lua_sys.screenHeight(), 3, 3))
  end
end
function RewardsBehaviour:onTick(dt)
  dt = math.min(dt, 0.033)
  local function tickBar(e, dt)
    OldOffsetTransition.OnTick(e, dt, {
      ease = lua_sys.Quadratic_EaseIn
    })
  end
  tickBar(self.RewardsTopBar, dt)
  tickBar(self.RewardsBottomBar, dt)
  self.FadeTransition:Tick(dt)
  if self.isShowing and not self.isDoneSequence then
    self.sequenceTimeRemaining = self.sequenceTimeRemaining - dt
    if self.sequenceTimeRemaining <= 0 then
      self.isDoneSequence = true
      self.Fade.Touch:GetVar("enabled"):SetInt(1)
      self.ContinueLabel.Text.FadeTransition:Show()
    end
  end
  self.ContinueLabel.Text.FadeTransition:Tick(dt)
end
function RewardsBehaviour:SetBGSpites(gradianSprite, patternSprite)
  local width = lua_sys.screenWidth()
  local height = 220 * game.hudScale()
  local bgSprite = self.RewardsBG.Sprite
  bgSprite:GetVar("spriteName"):SetString(gradianSprite)
  bgSprite:setScale(lua_sys.Vector2(width / 1024, height / 4))
  bgSprite:GetVar("layer"):SetString("Tutorial")
  bgSprite:GetVar("repeating"):SetInt(1)
  local bgPattern = self.RewardsBG.Pattern
  bgPattern:GetVar("spriteName"):SetString(patternSprite)
  bgPattern:setScale(lua_sys.Vector2(width / 128, height / 128))
  bgPattern:GetVar("layer"):SetString("Tutorial")
  bgPattern:GetVar("repeating"):SetInt(1)
  bgPattern.maxFade = 0.8
end
function RewardsBehaviour:Show(rewards)
  self.isDoneSequence = false
  self.sequenceTimeRemaining = 1
  local function showRewards()
    local showClaimInfo = false
    local claimFromMarket = false
    local claimFromMail = false
    local idx = 0
    if rewards then
      local startIndex, numRewards
      if type(rewards) == "table" then
        startIndex = 1
        numRewards = #rewards + 1
      else
        startIndex = 0
        numRewards = rewards:size()
      end
      for i = startIndex, numRewards - 1 do
        r = rewards[i]
        if r.type == game.LootType_Monster or r.type == game.LootType_Structure or r.type == game.LootType_Costume then
          showClaimInfo = true
          if r.type == game.LootType_Monster then
            local monsterData = game.getMonsterByEntityId(r.id)
            if r.getExtraBool and r:getExtraBool("box_filled") then
              claimFromMail = true
            elseif r.getExtraLong and 0 < r:getExtraLong("mail_id") then
              claimFromMail = true
            elseif monsterData and monsterData:getExtraInt("activated") == 1 then
              claimFromMail = true
            else
              claimFromMarket = true
            end
          else
            claimFromMarket = true
          end
        end
      end
    end
    local function showBar(e)
      OldOffsetTransition.Show(e)
    end
    self.Fade:Show()
    showBar(self.RewardsTopBar)
    showBar(self.RewardsBottomBar)
    for _, fader in ipairs(self.Faders) do
      fader:GetVar("visible"):SetInt(1)
    end
    if showClaimInfo then
      self.ClaimInfo.Text:GetVar("visible"):SetInt(1)
      local claimMsg = "CLAIM_REWARDS_FROM_MARKET"
      if claimFromMail and claimFromMarket then
        claimMsg = "CLAIM_REWARDS_FROM_MARKET_AND_MAIL"
      elseif claimFromMail then
        claimMsg = "CLAIM_REWARDS_FROM_MAIL"
      end
      self.ClaimInfo.Text:GetVar("text"):SetString(claimMsg)
    else
      self.ClaimInfo.Text:GetVar("visible"):SetInt(0)
    end
  end
  self.FadeTransition:Show()
  self.isShowing = true
  showRewards()
end
function RewardsBehaviour:Hide()
  self.isShowing = false
  local function hideBar(e)
    OldOffsetTransition.Hide(e)
  end
  self.Fade:Hide()
  hideBar(self.RewardsTopBar)
  hideBar(self.RewardsBottomBar)
  self.FadeTransition:Hide()
  self.ContinueLabel.Text.FadeTransition:Hide()
end
function RewardsBehaviour.Fade.Touch:onTouchUp(element, x, y)
  if self.isExiting then
    return
  end
  if root.Rewards.isDoneSequence then
    self.isExiting = true
    root:Hide()
  end
end
return StoreBundleRewardsPopupUI
