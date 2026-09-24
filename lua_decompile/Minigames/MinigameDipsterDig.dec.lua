local MinigameHelpers = include("Minigames/MinigameHelpers")
local MinigameDipsterDig = {
  Title = {
    BarBackingSprite = {},
    BarSprite = {},
    Text = {}
  },
  DiscoveredCounter = {
    BackingSprite = {},
    Text = {}
  }
}
local LEVEL_COMPLETE_PRIZE_DELAY = 1
function MinigameDipsterDig:onPostInit()
  self:SetupGenericListener(game.engineReceiver(), "game::msg::minigame::MsgMinigameRefreshState", "gotMsgMinigameRefreshState")
  self:SetupGenericListener(game.engineReceiver(), "game::msg::minigame::MsgDipsterDigAction", "gotMsgDipsterDigAction")
  self:SetupGenericListener(game.engineReceiver(), "game::msg::minigame::MsgMinigameLevelCompleteReward", "gotMsgMinigameLevelCompleteReward")
  self.levelCompletePrizeDelay = 999999
  self.levelCompleteReward = nil
  self.levelCompleteRewardIsTopReward = false
  self.tryToShowDipsterPlacementInfo = false
  self.dipsterPlacementInfoDelay = 999999
  self:reload()
end
function MinigameDipsterDig:onTick(dt)
  if self.levelCompleteReward then
    self.levelCompletePrizeDelay = self.levelCompletePrizeDelay - dt
    if self.levelCompletePrizeDelay < 0 then
      self.levelCompletePrizeDelay = 999999
      MinigameHelpers:showLevelCompleteReward(self.levelCompleteReward, self.levelCompleteRewardIsTopReward)
      self.tryToShowDipsterPlacementInfo = self.levelCompleteReward.type == game.LootType_Monster
      self.dipsterPlacementInfoDelay = 1
      self.levelCompleteReward = nil
    end
  elseif self.tryToShowDipsterPlacementInfo then
    self.dipsterPlacementInfoDelay = self.dipsterPlacementInfoDelay - dt
    if 0 > self.dipsterPlacementInfoDelay then
      if game.getTopPopUpName() == "minigame_new_level_overlay" then
        self.tryToShowDipsterPlacementInfo = false
        self.dipsterPlacementInfoDelay = 999999
        game.showHowToIfNotSeen("dipster_placement_info", "dipster_placement_how_it_works")
      else
        self.dipsterPlacementInfoDelay = 0.5
      end
    end
  end
end
function MinigameDipsterDig:reload()
  self:refreshText()
end
function MinigameDipsterDig:refreshText()
  local minigameContext = game.minigameContext()
  if minigameContext then
    local dipsterMinigame = minigameContext:getCurrentDipsterDigPlayerMinigame()
    if dipsterMinigame then
      local discovered = dipsterMinigame:numberOfDiscoveredEntities()
      local total = dipsterMinigame:totalNumberOfEntities()
      self.DiscoveredCounter.Text("text"):SetString(discovered .. "/" .. total)
      local percentage = discovered / total
      self.DiscoveredCounter.BarSprite:V("maskWidth"):SetFloat(self.DiscoveredCounter.BarSprite:V("FullMaskW"):GetInt() * clamp(percentage, 0, 1))
    end
  end
end
function MinigameDipsterDig:gotMsgMinigameRefreshState(msg)
  self:reload()
end
function MinigameDipsterDig:gotMsgDipsterDigAction(msg)
  if msg.entityRevealed then
    self:refreshText()
  end
end
function MinigameDipsterDig:gotMsgMinigameLevelCompleteReward(msg)
  self.levelCompleteReward = msg:reward()
  self.levelCompleteRewardIsTopReward = msg.isTopReward
  self.levelCompletePrizeDelay = LEVEL_COMPLETE_PRIZE_DELAY
end
return MinigameDipsterDig
