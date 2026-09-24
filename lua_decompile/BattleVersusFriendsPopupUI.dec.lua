local OffsetTransition = include("MenuElementPositionOffsetTransition")
local FadeTransition = include("FadeTransition")
local MenuHelpers = include("MenuHelpers")
local TRANSITION_DURATION = 0.66
local BattleVersusFriendsPopupUI = {}
function BattleVersusFriendsPopupUI.onInit(element)
  local versusCampaignId = game.getBattleVersusCampaignId()
  element("campaignId"):SetInt(versusCampaignId)
  element("showingSeasonInfo"):SetInt(1)
  element("transitioning"):SetInt(0)
  element("checkTimer"):SetInt(1)
  OffsetTransition.OnInit(element:GetElement("Frame"), {
    startY = lua_sys.screenHeight() * 2,
    endY = 0 * game.hudScale(),
    duration = TRANSITION_DURATION
  })
  OffsetTransition.Show(element:GetElement("Frame"))
  lua_sys.playSoundFx("audio/sfx/menu_slide.wav")
  local fadeTarget = element:GetElement("FadeLayer"):GetComponent("Sprite")
  element.FadeTransition = FadeTransition:new({
    duration = TRANSITION_DURATION,
    onUpdate = function(alpha)
      fadeTarget:GetVar("alpha"):SetFloat(alpha)
    end
  })
end
function BattleVersusFriendsPopupUI.onPostInit(element)
  MenuHelpers.CenterHorizontally({
    element:GetElement("SeasonCard")
  })
  local targetCard = element:GetElement("SeasonCard")
  local originalOffsetX = targetCard("xOffset"):GetFloat()
  local originalOffsetY = targetCard("yOffset"):GetFloat()
  targetCard("originalOffsetX"):SetFloat(originalOffsetX)
  targetCard("originalOffsetY"):SetFloat(originalOffsetY)
  local infoPane = element:GetElement("InfoPane")
  infoPane:DoStoredScript("show")
  local infoPaneBG = element:GetElement("InfoPane"):GetElement("BG")
  local offsetX = infoPaneBG("xOffset"):GetFloat() - infoPaneBG:absW() * 0.5 - targetCard:absW()
  local options = {
    duration = 0.05,
    startX = originalOffsetX,
    startY = originalOffsetY,
    endX = offsetX,
    endY = originalOffsetY
  }
  OffsetTransition.OnInit(targetCard, options)
  OffsetTransition.Show(targetCard)
  element("transitioning"):SetInt(1)
  local campaignId = element("campaignId"):GetInt()
  if campaignId > 0 then
    if game.getBattleVersusPlayerData(campaignId):hasCompletedSeason() then
      element.SeasonCard:DoStoredScript("lockCard")
    end
  else
    game.closeContextPopup()
  end
end
function BattleVersusFriendsPopupUI.onTick(element, dt)
  local options = {
    ease = lua_sys.Quadratic_EaseIn,
    onDoneHide = function(e)
      e:root():popPopUp()
    end
  }
  OffsetTransition.OnTick(element:GetElement("Frame"), dt, options)
  local isTransitioning = element("transitioning"):GetInt() == 1
  if isTransitioning then
    element.FadeTransition:Tick(dt)
    local targetCard
    if element("showingSeasonInfo"):GetInt() == 1 then
      targetCard = element:GetElement("SeasonCard")
    end
    if targetCard then
      options = {
        ease = lua_sys.Quadratic_EaseIn,
        onDoneHide = function(e)
          e:setOrientation(lua_sys.MenuOrientation(e("xOffset"):GetFloat(), e("yOffset"):GetFloat(), -2, lua_sys.LEFT, lua_sys.VCENTER))
          element("showingSeasonInfo"):SetInt(0)
          element.SeasonCard.Touch("enabled"):SetInt(1)
          manager:setContext("BATTLE_VERSUS_FRIENDS_MENU")
          element("transitioning"):SetInt(0)
          element("checkTimer"):SetInt(1)
        end
      }
      OffsetTransition.OnTick(targetCard, dt, options)
    end
  end
  if element("checkTimer"):GetInt() == 1 then
    local campaignId = element("campaignId"):GetInt()
    if not game.isBattleCampaignActive(campaignId) then
      element("checkTimer"):SetInt(0)
      game.updateBattleVersusStatus()
      game.closeContextPopup()
    end
  end
end
function BattleVersusFriendsPopupUI.queuePop(element)
  print("== Closing Versus Season Info ==")
  element.FadeTransition:Hide()
  local infoPane = element:GetElement("InfoPane")
  infoPane:DoStoredScript("hide")
  print("== Closing Battle Versus Popup! ==")
  OffsetTransition.Hide(element:GetElement("Frame"))
end
local function showInfo(element, targetCard)
  element.SeasonCard.Touch("enabled"):SetInt(0)
  element.FadeTransition:Show()
  local infoPane = element:GetElement("InfoPane")
  infoPane:DoStoredScript("refresh")
  infoPane:DoStoredScript("show")
  local originalOffsetX = targetCard("xOffset"):GetFloat()
  local originalOffsetY = targetCard("yOffset"):GetFloat()
  targetCard("originalOffsetX"):SetFloat(originalOffsetX)
  targetCard("originalOffsetY"):SetFloat(originalOffsetY)
  targetCard:setOrientation(lua_sys.MenuOrientation(originalOffsetX, originalOffsetY, -18, lua_sys.LEFT, lua_sys.VCENTER))
  local infoPaneBG = element:GetElement("InfoPane"):GetElement("BG")
  local offsetX = infoPaneBG("xOffset"):GetFloat() - infoPaneBG:absW() * 0.5 - targetCard:absW()
  local options = {
    duration = TRANSITION_DURATION,
    startX = originalOffsetX,
    startY = originalOffsetY,
    endX = offsetX,
    endY = originalOffsetY
  }
  OffsetTransition.OnInit(targetCard, options)
  OffsetTransition.Show(targetCard)
  manager:setButtonImg("btn_close", "button_back")
  manager:setButtonLabel("btn_close", "BACK")
  element("transitioning"):SetInt(1)
  lua_sys.playSoundFx("audio/sfx/menu_slide.wav")
end
local function hideInfo(element, targetCard)
  element.FadeTransition:Hide()
  local infoPane = element:GetElement("InfoPane")
  infoPane:DoStoredScript("hide")
  local targetOffsetX = targetCard("originalOffsetX"):GetFloat()
  local targetOffsetY = targetCard("originalOffsetY"):GetFloat()
  local options = {
    duration = TRANSITION_DURATION,
    startX = targetOffsetX,
    startY = targetOffsetY,
    endX = targetCard("xOffset"):GetFloat(),
    endY = targetCard("yOffset"):GetFloat()
  }
  OffsetTransition.OnInit(targetCard, options)
  OffsetTransition.Hide(targetCard)
  element("transitioning"):SetInt(1)
  lua_sys.playSoundFx("audio/sfx/menu_slide.wav")
end
function BattleVersusFriendsPopupUI.showSeasonInfo(element)
  if element("showingSeasonInfo"):GetInt() == 1 then
    return
  end
  local campaignId = game.getBattleVersusCampaignId()
  if not game.getBattleVersusPlayerData(campaignId):hasCompletedSeason() then
    showInfo(element, element:GetElement("SeasonCard"))
    element("showingSeasonInfo"):SetInt(1)
  else
    game.displayNotification("NOTIFICATION_BATTLE_VERSUS_DO_CHAMPIONS")
  end
end
function BattleVersusFriendsPopupUI.hideSeasonInfo(element)
  hideInfo(element, element:GetElement("SeasonCard"))
end
function BattleVersusFriendsPopupUI.seasonCardOnInit(element)
  element("isHidden"):SetInt(0)
end
function BattleVersusFriendsPopupUI.seasonCardOnPostInit(element)
  local campaignId = game.getBattleVersusCampaignId()
  local campaignData = game.getBattleCampaignData(campaignId)
  local battleVersusPlayerData = game.getBattleVersusPlayerData(campaignId)
  local completed = battleVersusPlayerData:hasCompletedSeason()
  if completed then
    element("completed"):SetInt(1)
  else
    element("completed"):SetInt(0)
  end
  local bgAnimFile = campaignData.bgAnimFile
  local bgAnimName = campaignData.bgAnim
  if bgAnimFile ~= "" and bgAnimName ~= "" then
    element("showBG"):SetInt(1)
  else
    element("showBG"):SetInt(0)
  end
  local fgAnimFile = campaignData.animFile
  local fgAnimName = campaignData.anim
  if fgAnimFile ~= "" and fgAnimName ~= "" then
    element("showFG"):SetInt(1)
  else
    element("showFG"):SetInt(0)
  end
  local requirementsText = campaignData.requirements.description
  if completed or string.len(requirementsText) == 0 then
    element("showRequirements"):SetInt(0)
    element.RequirementsTitle.Text("visible"):SetInt(0)
    element.RequirementsLabel.Text("visible"):SetInt(0)
    element.RequirementsIcon.Sprite("visible"):SetInt(0)
  else
    element("showRequirements"):SetInt(1)
    element.RequirementsTitle.Text("text"):SetString("BATTLE_CAMPAIGN_TEAM_REQUIRES")
    element.RequirementsLabel.Text("text"):SetString(requirementsText)
  end
  local currentTier = battleVersusPlayerData:tier()
  if currentTier < 0 then
    currentTier = 0
  end
  local currentStars = battleVersusPlayerData:stars()
  local tierData = campaignData.tiers[currentTier]
  local tierText = LOC("BATTLE_VERSUS_TIER")
  tierText = tierText:gsub("%${TIER}", tostring(campaignData.numSeasonTiers - currentTier + 1))
  element.Tier("tierName"):SetString(tierText)
  element.Tier("currentStars"):SetInt(currentStars)
  element.Tier("totalStars"):SetInt(tierData.stars)
  if completed then
    local statusText = LOC("BATTLE_VERSUS_STATUS_COMPLETED")
    element.StatusLabel.Text("text"):SetString(statusText)
  else
    element.StatusLabel.Text("text"):SetString("BATTLE_CAMPAIGN_STATUS_EVENT")
    element.Sticker.BG("visible"):SetInt(0)
    element.Sticker.Icon("visible"):SetInt(0)
  end
end
function BattleVersusFriendsPopupUI.seasonCardOnTick(element, dt)
  local hidden = element("isHidden"):GetInt() == 1
  local completed = element("completed"):GetInt() == 1
  if not hidden and not completed then
    local campaignId = element:parent()("campaignId"):GetInt()
    local secsRemaining = game.getBattleCampaignSecsRemaining(campaignId)
    if secsRemaining > 0 then
      element.StatusLabel.Text("text"):SetString(game.timeToString(secsRemaining))
    else
      element.StatusLabel.Text("text"):SetString("BATTLE_CAMPAIGN_STATUS_EXPIRED")
    end
  end
end
function BattleVersusFriendsPopupUI.seasonCardShow(element)
  element("isHidden"):SetInt(0)
  element.Sprite("visible"):SetInt(1)
  element.Header.Sprite("visible"):SetInt(1)
  element.TitleFrame.Text("visible"):SetInt(1)
  element.StatusLabel.Text("visible"):SetInt(1)
  local completed = element("completed"):GetInt() == 1
  if completed then
    element.Sticker.BG("visible"):SetInt(1)
    element.Sticker.Icon("visible"):SetInt(1)
  end
  local showRequirements = element("showRequirements"):GetInt() == 1
  if not completed and showRequirements then
    element.RequirementsTitle.Text("visible"):SetInt(1)
    element.RequirementsLabel.Text("visible"):SetInt(1)
    element.RequirementsIcon.Sprite("visible"):SetInt(1)
  end
  element.Tier:DoStoredScript("show")
  if element("showBG"):GetInt() == 1 then
    element.BackgroundAnimation.Sprite("visible"):SetInt(1)
  end
  if element("showFG"):GetInt() == 1 then
    element.ForegroundAnimation.Sprite("visible"):SetInt(1)
  end
end
function BattleVersusFriendsPopupUI.seasonCardHide(element)
  element("isHidden"):SetInt(1)
  element.Sprite("visible"):SetInt(0)
  element.Header.Sprite("visible"):SetInt(0)
  element.TitleFrame.Text("visible"):SetInt(0)
  element.StatusLabel.Text("visible"):SetInt(0)
  element.Sticker.BG("visible"):SetInt(0)
  element.Sticker.Icon("visible"):SetInt(0)
  element.RequirementsTitle.Text("visible"):SetInt(0)
  element.RequirementsLabel.Text("visible"):SetInt(0)
  element.RequirementsIcon.Sprite("visible"):SetInt(0)
  element.Tier:DoStoredScript("hide")
  element.BackgroundAnimation.Sprite("visible"):SetInt(0)
  element.ForegroundAnimation.Sprite("visible"):SetInt(0)
end
function BattleVersusFriendsPopupUI.lockCard(element)
  print("locking", element:name())
  element("locked"):SetInt(1)
end
return BattleVersusFriendsPopupUI
