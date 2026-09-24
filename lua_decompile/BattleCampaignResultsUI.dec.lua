local OffsetTransition = include("MenuElementPositionOffsetTransition")
local MenuHelpers = include("MenuHelpers")
local BattleCampaignResultsUI = {}
function BattleCampaignResultsUI.queuePop(element)
  element:DoStoredScript("hide")
end
function BattleCampaignResultsUI.onInit(element)
  function element.Bg.onDoneShow(e)
    local result = element("win"):GetInt()
    if result == 1 then
      lua_sys.playSoundFx("audio/sfx/battlemode_win.wav")
      game.playEffect("particles/FX_Colossingum_Victory.efkefc", lua_sys.screenWidth() * 0.5, lua_sys.screenHeight(), e:C("Sprite")("layer"):GetString(), 0.001, 8 * game.windowScaleY())
    else
      lua_sys.playSoundFx("audio/sfx/battlemode_lose.wav")
    end
  end
  function element.Bg.onDoneHide(e)
    e:root():popPopUp()
  end
end
function BattleCampaignResultsUI.onTick(element, dt)
end
function BattleCampaignResultsUI.show(element)
  element.Bg:Show()
end
function BattleCampaignResultsUI.hide(element)
  element.Bg:Hide()
end
function BattleCampaignResultsUI.SetResult(element, campaignId, result)
  print("Setting Result:" .. result)
  element("win"):SetInt(result)
  element("gotResponse"):SetInt(0)
  if result == 1 then
    element.Bg.TitleText("text"):SetString("BATTLE_VICTORY")
    element.Bg.Victory:DoStoredScript("show")
    element:SetupGenericListener(game.engineReceiver(), "game::msg::MsgBattleRewards", "gotMsgBattleRewards")
    element:SetupGenericListener(game.engineReceiver(), "game::msg::MsgBattleError", "gotMsgBattleError")
  else
    element.Bg.TitleText("text"):SetString("BATTLE_DEFEAT")
    element.Bg.Defeat:DoStoredScript("show")
    element:DoStoredScript("show")
  end
end
function BattleCampaignResultsUI.gotMsgBattleRewards(element, msg)
  local text = ""
  if msg:campaign() ~= 0 then
    local campaignData = game.getBattleCampaignData(msg:campaign())
    text = game.getLocalizedText("BATTLE_CAMPAIGN_BATTLES_COMPLETED")
    local progress = game.getBattlePlayerData():getCampaignProgress(campaignData.id)
    text = text:gsub("%${COMPLETED}", progress .. "/" .. campaignData.battles:size())
  end
  element.Bg.Victory.CampaignText("text"):SetString(text)
  local root = element.Bg:GetElement("Victory")
  local rewardsArray = {
    "battle_xp",
    "medals",
    "coins",
    "diamond",
    "costume",
    "trophy"
  }
  local rewardValuesArray = {
    msg:xp(),
    msg:medals(),
    msg:coins(),
    msg:diamonds(),
    msg:costume(),
    msg:trophies()
  }
  local offsetY = 36 * game.menuScaleY()
  local entries = {}
  local rewardItems = 0
  for i = 1, #rewardValuesArray do
    if rewardValuesArray[i] ~= 0 then
      local rewardEntry = menu:addTemplateElement("template_battle_reward", "rewardEntry" .. rewardItems, root)
      table.insert(entries, rewardEntry)
      rewardEntry:relativeTo(root)
      rewardEntry:setRelativeObjectAnchors(lua_sys.HCENTER, lua_sys.VCENTER)
      rewardEntry:setOrientation(lua_sys.MenuOrientation(0, offsetY, -1, lua_sys.LEFT, lua_sys.VCENTER))
      if rewardsArray[i] == "costume" then
        rewardEntry("Icon"):SetString(rewardsArray[i])
        rewardEntry("CurrencyType"):SetString("")
      elseif rewardsArray[i] == "trophy" then
        rewardEntry("Icon"):SetString(rewardsArray[i])
        rewardEntry("CurrencyType"):SetString("")
      else
        rewardEntry("Icon"):SetString(game.StoreContext_getSpriteFromCurrencyTypeStr(rewardsArray[i]))
        rewardEntry("CurrencyType"):SetString(rewardsArray[i])
      end
      rewardEntry("Amount"):SetInt(rewardValuesArray[i])
      rewardEntry:init()
      rewardEntry:setPositionBroadcast(true)
      rewardEntry:postInit()
      rewardItems = rewardItems + 1
    end
  end
  MenuHelpers.CenterHorizontally(entries)
  element("gotResponse"):SetInt(1)
  element:DoStoredScript("show")
end
function BattleCampaignResultsUI.gotMsgBattleError(element, msg)
  element:SetupGenericListener(game.engineReceiver(), "game::msg::MsgNotificationDismissed", "gotMsgNotificationDismissed")
  local errorMsg = LOC("MSG_BATTLE_ERROR") .. [[

err:(]] .. msg:error() .. ")"
  game.displayNotification(errorMsg)
end
function BattleCampaignResultsUI.gotMsgNotificationDismissed(element, msg)
  game.loadWorldContext()
end
return BattleCampaignResultsUI
