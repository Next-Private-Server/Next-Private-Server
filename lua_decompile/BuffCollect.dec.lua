local OldOffsetTransition = include("MenuElementPositionOffsetTransition")
local FadeTransition = include("FadeTransition")
local MenuHelpers = include("MenuHelpers")
local ScrollingPatternShader = include("ShaderScrollingPattern")
local root
local RewardsBehaviour = {
  Faders = {},
  Fade = {
    Touch = {}
  },
  Flash = {}
}
local BuffCollect = {Rewards = RewardsBehaviour}
function BuffCollect:onInit()
  root = self
  self("BuffId"):SetInt(0)
end
function BuffCollect:queuePop()
  if self.Rewards.isShowing then
    self.Rewards:Hide()
    return
  end
  self:Hide()
end
function BuffCollect:Show()
  self.Fade:Show()
  lua_sys.playSoundFx("audio/sfx/menu_slide.wav")
  local rewards = {}
  table.insert(rewards, {
    id = self("BuffId"):GetInt(),
    type = game.LootType_Buff,
    amount = 1
  })
  self.Rewards:Show(rewards)
end
function BuffCollect:Hide()
  self.Fade:Hide()
  lua_sys.playSoundFx("audio/sfx/menu_slide.wav")
end
function RewardsBehaviour:onInit()
  self.isShowing = false
  self.isDoneSequence = false
  self.sequenceTimeRemaining = 0
  local width = lua_sys.screenWidth()
  local height = 220 * game.hudScale()
  local bgSprite = self.RewardsBG.Sprite
  bgSprite:GetVar("spriteName"):SetString("gfx/menu/gradient_bg_titansoul")
  bgSprite:setScale(lua_sys.Vector2(width / 1024, height / 4))
  bgSprite:GetVar("layer"):SetString("Tutorial")
  bgSprite:GetVar("repeating"):SetInt(1)
  local bgPattern = self.RewardsBG.Pattern
  bgPattern:GetVar("spriteName"):SetString("gfx/menu/bg_symbols_titansoul")
  bgPattern:setScale(lua_sys.Vector2(width / 128, height / 128))
  bgPattern:GetVar("layer"):SetString("Tutorial")
  bgPattern:GetVar("repeating"):SetInt(1)
  bgPattern:GetVar("additive"):SetInt(1)
  bgPattern.maxFade = 0.2
  if ScrollingPatternShader then
    ScrollingPatternShader:getUniform("u_TexParams"):setVec4(lua_sys.Vector4(1, 1, 8 * (width / height), 8))
  end
  bgPattern:setShader(ScrollingPatternShader)
  table.insert(self.Faders, bgSprite)
  table.insert(self.Faders, bgPattern)
  self.ContinueLabel.Text.FadeTransition = FadeTransition:new({
    delayOnShow = 1,
    duration = 1,
    maxFade = 1,
    onUpdate = function(alpha)
      self.ContinueLabel.Text:GetVar("alpha"):SetFloat(alpha)
    end
  })
  self.ContinueLabel.Text.FadeTransition:SetAlpha(0)
  local transitionDuration = 0.5
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
      self:Cleanup()
      root:root():popPopUp()
    end,
    onUpdate = function(alpha)
      for _, fader in ipairs(self.Faders) do
        local maxA = math.min(alpha, fader.maxFade or 1)
        fader:GetVar("alpha"):SetFloat(maxA)
        if fader.updateAlpha then
          fader:updateAlpha(maxA)
        end
      end
      if self.items then
        for _, rewardItem in ipairs(self.items) do
          rewardItem:GetVar("alpha"):SetFloat(alpha)
          if rewardItem.updateAlpha then
            rewardItem:updateAlpha(alpha)
          end
        end
      end
    end
  })
  self.FadeTransition:SetAlpha(0)
  self.Flash.FadeTransition = FadeTransition:new({
    duration = 0.33,
    maxFade = 1,
    delayOnHide = 0.16,
    onUpdate = function(alpha)
      self.Flash:GetVar("alpha"):SetFloat(alpha)
    end,
    onDoneShow = function(t)
      t:Hide()
    end,
    onDoneHide = function()
      self.Flash("visible"):SetInt(0)
    end
  })
  self.Flash.FadeTransition:SetAlpha(0)
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
  if self.Flash("visible"):GetInt() == 1 then
    self.Flash.FadeTransition:Tick(dt)
  end
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
function RewardsBehaviour:Show(rewards)
  self.isDoneSequence = false
  self.sequenceTimeRemaining = 2
  self:Cleanup()
  local function createReward(idx, rewardData)
    local rewardItem = menu:addTemplateElement("template_daily_cumulative_login_reward", "rewardItem" .. idx, self)
    rewardItem:Init(rewardData, idx)
    rewardItem:setParent(self)
    rewardItem:relativeTo(self)
    rewardItem:setOrientation(lua_sys.MenuOrientation(0, -16 * game.hudScale(), 10, lua_sys.LEFT, lua_sys.VCENTER))
    rewardItem:setRelativeObjectAnchors(lua_sys.HCENTER, lua_sys.VCENTER)
    rewardItem:calculatePosition()
    rewardItem:init()
    rewardItem:setPositionBroadcast(true)
    rewardItem:postInit()
    table.insert(self.items, rewardItem)
  end
  local function showRewards()
    self.items = {}
    local idx = 0
    if rewards then
      for i, r in ipairs(rewards) do
        createReward(idx + (i - 1), r)
      end
      MenuHelpers.CenterHorizontally(self.items)
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
  end
  self.FadeTransition:Show()
  self.isShowing = true
  local showFlash = false
  if showFlash then
    self.Flash:GetVar("visible"):SetInt(1)
    function self.Flash.FadeTransition.onDoneShow(t)
      showRewards()
      t:Hide()
    end
    self.Flash.FadeTransition:Show()
  else
    showRewards()
  end
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
function RewardsBehaviour:Cleanup()
  if self.items then
    for _, v in ipairs(self.items) do
      self:RemoveElement(v)
    end
  end
  self.items = {}
end
function RewardsBehaviour.Fade.Touch:onTouchUp(element, x, y)
  if root.Rewards.isDoneSequence then
    self:GetVar("enabled"):SetInt(0)
    root.Rewards:Hide()
  end
end
return BuffCollect
