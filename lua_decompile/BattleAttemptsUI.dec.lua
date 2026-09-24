local MenuHelpers = include("MenuHelpers")
local BattleAttemptsUI = {}
function BattleAttemptsUI.onInit(element)
  if not element:HasVar("currentAttempts") then
    element("currentAttempts"):SetInt(0)
  end
  if not element:HasVar("totalAttempts") then
    element("totalAttempts"):SetInt(game.BattleVersusPlayerData_TOTAL_ATTEMPTS)
  end
end
function BattleAttemptsUI.onPostInit(element)
  local campaignId = element:GetVar("CampaignId"):GetInt()
  if campaignId > 0 and game.hasBattleVersusPlayerData(campaignId) then
    element:GetVar("isRefreshing"):SetInt(0)
    element:SetupGenericListener(game.engineReceiver(), "game::msg::MsgBattleAttemptsRefreshed", "gotMsgBattleAttemptsRefreshed")
    local battleVersusPlayerData = game.getBattleVersusPlayerData(campaignId)
    local attempts = battleVersusPlayerData:attempts()
    element:GetVar("currentAttempts"):SetInt(attempts)
    element:DoStoredScript("populate")
    element:DoStoredScript("refreshUI")
  else
    element.LabelText("visible"):SetInt(0)
    element.TimerText("visible"):SetInt(0)
  end
end
function BattleAttemptsUI.gotMsgBattleAttemptsRefreshed(element, msg)
  if msg:campaignId() == element("CampaignId"):GetInt() then
    local currentAttempts = msg:attempts()
    element("currentAttempts"):SetInt(currentAttempts)
    element:DoStoredScript("refreshUI")
    element("isRefreshing"):SetInt(0)
  end
end
function BattleAttemptsUI.onTick(element, dt)
  local campaignId = element("CampaignId"):GetInt()
  if campaignId > 0 and game.hasBattleVersusPlayerData(campaignId) then
    local battleVersusPlayerData = game.getBattleVersusPlayerData(campaignId)
    local attempts = battleVersusPlayerData:attempts()
    if attempts == 0 then
      local secsRemaining = battleVersusPlayerData:secsUntilAttemptsRefresh()
      if secsRemaining <= 0 and element("isRefreshing"):GetInt() == 0 then
        element("isRefreshing"):SetInt(1)
        game.battleVersusRefillAttempts(campaignId, false)
      end
      element.TimerText("text"):SetString(game.timeToString(secsRemaining))
      element.TimerText("visible"):SetInt(1)
      if 0 < element("TopLabel"):GetInt() then
        MenuHelpers.CenterHorizontally({
          element.TimerText
        })
      end
    end
  end
end
function BattleAttemptsUI.populate(element)
  local xOffset = 0
  local yOffset = 6 * game.menuScaleX()
  local numAttempts = element("totalAttempts"):GetInt()
  for i = 0, numAttempts - 1 do
    local entry = menu:addTemplateElement("template_battle_attempts_entry", "entry" .. i, element)
    entry:setOrientation(lua_sys.MenuOrientation(xOffset, yOffset, 0, lua_sys.LEFT, lua_sys.VCENTER))
    entry:setRelativeObjectAnchors(lua_sys.HCENTER, lua_sys.VCENTER)
    entry:init()
    entry:postInit()
  end
end
function BattleAttemptsUI.refreshUI(element)
  local currentAttempts = element("currentAttempts"):GetInt()
  if currentAttempts > 0 then
    element.LabelText("text"):SetString("BATTLE_VERSUS_ATTEMPTS_AVAILABLE")
    element.TimerText("visible"):SetInt(0)
    MenuHelpers.ForEachEntry(element, function(entry, i)
      entry:DoStoredScript("show")
      if i < currentAttempts then
        entry:DoStoredScript("enable")
      else
        entry:DoStoredScript("disable")
      end
    end)
    do
      local targets = {}
      if element("TopLabel"):GetInt() == 0 then
        table.insert(targets, element:GetComponent("LabelText"))
        table.insert(targets, MenuHelpers.CreateSpacer(4 * game.menuScaleX(), 0))
      end
      MenuHelpers.ForEachEntry(element, function(entry)
        table.insert(targets, entry)
      end)
      MenuHelpers.CenterHorizontally(targets)
    end
  else
    element.LabelText("text"):SetString("BATTLE_VERSUS_ATTEMPTS_MORE_AVAILABLE_IN")
    element.TimerText("visible"):SetInt(1)
    MenuHelpers.ForEachEntry(element, function(entry, i)
      entry:DoStoredScript("hide")
    end)
    local targets = {}
    if element("TopLabel"):GetInt() == 0 then
      table.insert(targets, element:GetComponent("LabelText"))
      table.insert(targets, MenuHelpers.CreateSpacer(4 * game.menuScaleX(), 0))
    end
    table.insert(targets, element:GetComponent("TimerText"))
    MenuHelpers.CenterHorizontally(targets)
  end
end
return BattleAttemptsUI
