local MenuHelpers = include("MenuHelpers")
local ClubboxOver = {
  FadedBG = {},
  bg = {
    Sprite = {}
  },
  TitleFrame = {
    Sprite = {},
    LeftEnd = {},
    RightEnd = {}
  },
  TitleLabel = {},
  Notification = {
    Text = {}
  },
  InfoBg = {
    HypeBlob = {
      HypeIcon = {},
      HypeCount = {}
    },
    RewardBlob = {
      RewardIcon = {},
      RewardCount = {}
    }
  }
}
function ClubboxOver.InfoBg.HypeBlob:onPostInit()
  self:refreshSize()
end
function ClubboxOver.InfoBg.HypeBlob:refreshSize()
  self:setSize(Vector2(self.HypeIcon:absW() + self.HypeCount:absW(), self.HypeIcon:absH()))
end
function ClubboxOver.InfoBg.HypeBlob.HypeCount:updateText()
  local actId = self:parent():parent():parent()("actId"):GetInt()
  local curHype = game.player():curClubboxHype(actId)
  local hypeText = game.getLocalizedText("CLUBBOX_END_HYPE_GENERATED")
  hypeText = hypeText:gsub("%${HYPE}", curHype)
  self("text"):SetString(hypeText)
  self:parent():refreshSize()
end
function ClubboxOver.InfoBg.RewardBlob:onPostInit()
  self:refreshSize()
end
function ClubboxOver.InfoBg.RewardBlob:refreshSize()
  self:setSize(Vector2(self.RewardIcon:absW() + self.RewardCount:absW(), self.RewardIcon:absH()))
end
function ClubboxOver.InfoBg.RewardBlob.RewardCount:updateText()
  local actId = self:parent():parent():parent()("actId"):GetInt()
  local rewardTrackId = game.clubboxActRewardTrackId(actId)
  local rewardTrackData = game.getRewardTrackData(rewardTrackId)
  local currentHype = game.clubboxCurHype(actId)
  local prestigeLevel = game.clubboxPrestigeLevel(actId)
  local showPrestige = prestigeLevel > 0
  local rewardTrackLevelData = game.getRewardTrackLevelData(rewardTrackId, currentHype, true)
  local earnedTier = 0
  local totalLevels = 0
  local rewardText = game.getLocalizedText("CLUBBOX_END_EARNED_REWARDS")
  if showPrestige then
    rewardText = game.getLocalizedText("CLUBBOX_END_EARNED_REWARDS_PRESTIGE")
  end
  if rewardTrackLevelData:size() ~= 0 then
    totalLevels = rewardTrackData.totalLevels
    earnedTier = rewardTrackLevelData[0].level - 1
  else
    print("Invalid Reward Track: " .. rewardTrackId)
  end
  rewardText = rewardText:gsub("%${EARNED_TIER}", earnedTier)
  rewardText = rewardText:gsub("%${MAX_TIER}", totalLevels)
  self("text"):SetString(rewardText)
  self:parent():refreshSize()
end
function ClubboxOver:updateHypebar()
  local actId = self("actId"):GetInt()
  local prestigeLevel = game.clubboxPrestigeLevel(actId)
  local showPrestige = prestigeLevel > 0
  if showPrestige then
    self.bg.Sprite("spriteName"):SetString("gfx/clubbox/clubbox_textbox_9S_prestige")
    self.TitleFrame.Sprite("spriteName"):SetString("gfx/clubbox/clubbox_currency_frame_9S_prestige")
    self.TitleFrame.RightEnd("spriteName"):SetString("header_right_prestige")
    self.TitleFrame.LeftEnd("spriteName"):SetString("header_left_prestige")
    self.InfoBg.RewardBlob.RewardIcon("spriteName"):SetString("icon_hype_progress_prestige")
  end
  self.Poster.Sprite("spriteName"):SetString(game.getClubboxActPosterIcon(actId))
  self.Poster.Sprite("sheetName"):SetString("xml_resources/" .. game.getClubboxActPosterSheet(actId))
  self.InfoBg.HypeBlob.HypeCount:updateText()
  self.InfoBg.RewardBlob.RewardCount:updateText()
end
return ClubboxOver
