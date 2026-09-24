local OffsetTransition = include("MenuElementPositionOffsetTransition")
local MenuHelpers = include("MenuHelpers")
local BattleVersusResultsUI = {}
function BattleVersusResultsUI.queuePop(element)
  BattleVersusResultsUI.hide(element)
end
function BattleVersusResultsUI.onInit(element)
  element("addStar"):SetInt(0)
  element("addStar_timer"):SetFloat(0)
  element("addTier"):SetInt(0)
  element("showStreak"):SetInt(0)
  element:SetupGenericListener(game.engineReceiver(), "game::msg::MsgBattleVersusResult", "gotMsgBattleVersusResult")
  element:SetupGenericListener(game.engineReceiver(), "game::msg::MsgBattleError", "gotMsgBattleError")
  local bg = element:GetElement("Bg")
  if bg then
    function bg.onDoneShow(e)
      local result = element("win"):GetInt()
      if result == 1 then
        lua_sys.playSoundFx("audio/sfx/battlemode_win.wav")
        game.playEffect("particles/FX_Colossingum_Victory.efkefc", lua_sys.screenWidth() * 0.5, lua_sys.screenHeight(), e:C("Sprite")("layer"):GetString(), 0.001, 8 * game.windowScaleY())
      else
        lua_sys.playSoundFx("audio/sfx/battlemode_lose.wav")
      end
    end
    function bg.onDoneHide(e)
      e:root():popPopUp()
    end
  end
end
function BattleVersusResultsUI.onTick(element, dt)
  local countdown = element("addStar_timer"):GetFloat()
  if countdown > 0 then
    countdown = countdown - dt
    element("addStar_timer"):SetFloat(countdown)
  else
    local tierElement = element:GetElement("Tier")
    local addStar = element("addStar"):GetInt()
    local currentStars = tierElement("currentStars"):GetInt()
    local totalStars = tierElement("totalStars"):GetInt()
    if addStar > 0 and currentStars ~= totalStars then
      element("addStar_timer"):SetFloat(1.7)
      addStar = addStar - 1
      element("addStar"):SetInt(addStar)
      local targetStar = tierElement["star" .. currentStars]
      targetStar:DoStoredScript("blink")
      tierElement("currentStars"):SetInt(currentStars + 1)
      if element("showStreak"):GetInt() == 1 then
        element.Streak.Text("visible"):SetInt(1)
        MenuHelpers.DoUnlockEffect(element:GetElement("Streak"))
      end
      element("showStreak"):SetInt(1)
    else
      local addTier = element("addTier"):GetInt()
      if addTier > 0 then
        MenuHelpers.DoCelebrateEffect(element)
        local newTier = element("newTier"):GetInt()
        local tierName = "Tier ${TIER}"
        tierName = tierName:gsub("%${TIER}", newTier)
        tierElement("tierName"):SetString(tierName)
        tierElement("currentStars"):SetInt(0)
        if newTier == 1 then
          tierElement("totalStars"):SetInt(0)
        else
          tierElement("totalStars"):SetInt(element("newTotalStars"):GetInt())
        end
        tierElement:DoStoredScript("populate")
        tierElement:DoStoredScript("update")
        tierElement:DoStoredScript("center")
        local text = LOC("BATTLE_VERSUS_GAIN_TIER")
        element.Bg.ResultText("text"):SetString(text)
        element("addTier"):SetInt(0)
      end
    end
  end
end
function BattleVersusResultsUI.show(element)
  local bg = element:GetElement("Bg")
  if bg then
    bg:Show()
  end
  lua_sys.playSoundFx("audio/sfx/menu_slide.wav")
end
function BattleVersusResultsUI.hide(element)
  local bg = element:GetElement("Bg")
  if bg then
    bg:Hide()
  end
  lua_sys.playSoundFx("audio/sfx/menu_slide.wav")
end
function BattleVersusResultsUI.gotMsgBattleVersusResult(element, msg)
  print("Got MsgBattleVersusResult")
  local campaignId = msg:campaign()
  local campaignData = game.getBattleCampaignData(campaignId)
  if msg:win() == 1 then
    element("win"):SetInt(1)
    element.Bg.TitleText("text"):SetString("BATTLE_VICTORY")
  else
    element("win"):SetInt(0)
    element.Bg.TitleText("text"):SetString("BATTLE_DEFEAT")
    element.Bg.Defeat:DoStoredScript("show")
  end
  element.Streak.Text("visible"):SetInt(0)
  local tierElement = element:GetElement("Tier")
  if msg:lastTier() == msg:newTier() and 0 < msg:championsRank() then
    element.Bg.ResultText("yOffset"):SetFloat(0)
    tierElement:DoStoredScript("hide")
    if msg:win() == 1 then
      local text = LOC("BATTLE_VERSUS_NEW_CHAMPION_RANK")
      text = text:gsub("%${RANK}", msg:championsRank())
      element.Bg.ResultText("text"):SetString(text)
      local rewardMedals = msg:rewardMedals()
      local rewardXp = msg:rewardXp()
      element.Rewards.Medals.Value.Text("text"):SetString(rewardMedals)
      element.Rewards.XP.Value.Text("text"):SetString(rewardXp)
    else
      element.Bg.ResultText("text"):SetString("BATTLE_TRY_AGAIN")
      element.Rewards:DoStoredScript("hide")
    end
  else
    local tierData = campaignData.tiers[msg:lastTier()]
    local seasonTiers = {}
    local numSeasonTiers = 0
    for idx = campaignData.tiers:size() - 1, 0, -1 do
      local tier = campaignData.tiers[idx]
      if not tier:isChampionTier() then
        seasonTiers[numSeasonTiers] = idx + 2
        numSeasonTiers = numSeasonTiers + 1
      end
    end
    seasonTiers[numSeasonTiers] = 1
    if msg:win() == 1 then
      local tierName = LOC("BATTLE_VERSUS_SEASON_TIER")
      tierName = tierName:gsub("%${TIER}", seasonTiers[msg:lastTier()])
      tierElement("tierName"):SetString(tierName)
      local text = LOC("BATTLE_VERSUS_GAIN_STAR")
      element.Bg.ResultText("text"):SetString(text)
      element("addStar"):SetInt(1)
      if 1 < msg:newStreak() then
        element("addStar"):SetInt(2)
      end
      element("addStar_timer"):SetFloat(0.35)
      tierElement("currentStars"):SetInt(msg:lastStars())
      tierElement("totalStars"):SetInt(tierData.stars)
      if msg:newTier() > msg:lastTier() then
        local newTier = seasonTiers[msg:newTier()]
        element("newTier"):SetInt(newTier)
        if newTier > 1 then
          element("newStars"):SetInt(msg:newStars())
          local newTierData = campaignData.tiers[msg:newTier()]
          element("newTotalStars"):SetInt(newTierData.stars)
        end
        element("addTier"):SetInt(1)
      end
      tierElement:DoStoredScript("populate")
      tierElement:DoStoredScript("update")
      tierElement:DoStoredScript("center")
      local rewardMedals = msg:rewardMedals()
      local rewardXp = msg:rewardXp()
      element.Rewards.Medals.Value.Text("text"):SetString(rewardMedals)
      element.Rewards.XP.Value.Text("text"):SetString(rewardXp)
    else
      element.Bg.ResultText("text"):SetString("BATTLE_TRY_AGAIN")
      element.Rewards:DoStoredScript("hide")
      local tierName = LOC("BATTLE_VERSUS_SEASON_TIER")
      tierName = tierName:gsub("%${TIER}", seasonTiers[msg:newTier()])
      tierElement("tierName"):SetString(tierName)
      tierElement("currentStars"):SetInt(msg:newStars())
      local newTierData = campaignData.tiers[msg:newTier()]
      tierElement("totalStars"):SetInt(newTierData.stars)
      tierElement:DoStoredScript("populate")
      tierElement:DoStoredScript("update")
      tierElement:DoStoredScript("center")
    end
  end
  element:DoStoredScript("show")
end
function BattleVersusResultsUI.gotMsgBattleError(element, msg)
  element:SetupGenericListener(game.engineReceiver(), "game::msg::MsgNotificationDismissed", "gotMsgNotificationDismissed")
  local errorMsg = LOC("MSG_BATTLE_ERROR") .. [[

err:(]] .. msg:error() .. ")"
  game.displayNotification(errorMsg)
end
function BattleVersusResultsUI.gotMsgNotificationDismissed(element, msg)
  game.loadWorldContext()
end
return BattleVersusResultsUI
