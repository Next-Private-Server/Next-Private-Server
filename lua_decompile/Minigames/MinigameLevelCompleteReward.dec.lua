local MinigameLevelCompleteReward = {
  FadedBG = {
    Touch = {}
  },
  Banner = {
    Anim = {}
  },
  TitleText = {},
  Reward = {},
  TapText = {}
}
local BANNER_UNFURL_DELAY = 0.866
local FADE_IN_DELAY = 0.25
function MinigameLevelCompleteReward:onPostInit()
  self.isTransitioning = true
  self.isHiding = false
  self.effectShown = false
  self.isTopReward = false
  self:SetAlpha(0)
  function self.FadedBG.onDoneShow(e)
    self.isTransitioning = false
  end
  function self.FadedBG.onDoneHide(e)
    self:root():removePopUp(self:name())
    game.pushPopUp("minigame_new_level_overlay")
    local cardAlbum = game.player():currentlyActiveCardAlbum()
    if cardAlbum ~= nil then
      if cardAlbum:hasUncollectedCardPacks() then
        game.pushPopUp("open_card_pack")
      elseif cardAlbum:hasUncollectedPageRewards() then
        game.pushPopUp("card_album_page_reward_collect")
      elseif cardAlbum:hasUncollectedAlbumRewards() then
        game.pushPopUp("card_album_reward_collect")
      end
    end
  end
  function self.FadedBG.updateAlpha(e, alpha)
    e.Sprite("alpha"):SetFloat(alpha)
    if self.isHiding then
      local alpha2 = alpha / e.maxFade
      self.Banner.Anim:GetVar("alpha"):SetFloat(alpha2)
      self.Banner.Anim:setColor(alpha2, alpha2, alpha2)
      self:SetAlpha(alpha2)
    end
  end
  function self.FadedBG.Touch.onTouchUp(e, x, y)
    if not self.isTransitioning and not self.isHiding then
      self.isTransitioning = true
      self.isHiding = true
      e:parent():Hide()
    end
  end
  self.showDelay = -BANNER_UNFURL_DELAY + FADE_IN_DELAY
  self.effectDelay = -BANNER_UNFURL_DELAY
end
function MinigameLevelCompleteReward:onTick(dt)
  self.showDelay = self.showDelay + dt
  if self.showDelay <= 0 then
    self:SetAlpha(0)
  elseif self.showDelay <= FADE_IN_DELAY then
    self:SetAlpha(self.showDelay / FADE_IN_DELAY)
  end
  if self.isTopReward and not self.effectShown then
    self.effectDelay = self.effectDelay + dt
    if 0 >= self.effectDelay then
      self.effectShown = true
      game.playEffect("particles/Clubbox/FX_WinLrgConfetti.efkefc", lua_sys.screenWidth() * 0.5, lua_sys.screenHeight() * 0.5, "FrontPopUps", 0.001, 6 * game.windowScaleY())
      game.playEffect("particles/Clubbox/FX_WinLrgConfetti.efkefc", lua_sys.screenWidth() * 0.5, lua_sys.screenHeight() * 0.75, "FrontPopUps", 0.001, 3 * game.windowScaleY())
    end
  end
end
function MinigameLevelCompleteReward:SetAlpha(alpha)
  self.TitleText("alpha"):SetFloat(alpha)
  self.TapText("alpha"):SetFloat(alpha)
  if self.rewardItem then
    self.rewardItem:updateAlpha(alpha)
  end
end
function MinigameLevelCompleteReward:Setup(reward, isTopReward)
  self.isTopReward = isTopReward
  local vars = {
    scale = 0.8 * game.windowScaleY() / game.hudScale(),
    layer = "FrontPopUps"
  }
  self.rewardItem = menu:addTemplateElementEx("template_daily_cumulative_login_reward", "rewardSprite", self.Reward, vars)
  self.rewardItem:Init(reward, 1, {variation = 1})
  self.rewardItem:setParent(self.Reward)
  self.rewardItem:relativeTo(self.Reward)
  self.rewardItem:setOrientation(lua_sys.MenuOrientation(0, 0, 0, lua_sys.HCENTER, lua_sys.VCENTER))
  self.rewardItem:setRelativeObjectAnchors(lua_sys.HCENTER, lua_sys.VCENTER)
  self.rewardItem:calculatePosition()
  self.rewardItem:init()
  self.rewardItem:setPositionBroadcast(true)
  self.rewardItem:postInit()
  if self.isTopReward then
    lua_sys.playSoundFx("audio/sfx/minigame01-prize_reveal_major.ogg")
  else
    lua_sys.playSoundFx("audio/sfx/minigame01-prize_reveal_minor.ogg")
  end
end
return MinigameLevelCompleteReward
