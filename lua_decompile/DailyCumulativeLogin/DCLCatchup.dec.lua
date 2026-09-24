local root
local DCLCatchup = {
  Fade = {},
  BG = {
    CloseButton = {},
    Contents = {},
    CatchUp = {
      BuyButton = {
        Touch = {}
      }
    }
  }
}
local catchUpPrice = function()
  local playerState = game.player():getDailyCumulativeLogin()
  local diamondCost = game.PlayerDailyCumulativeLogin_catchUpBaseCost() + playerState:catchUpDaysUsed()
  return diamondCost
end
local catchUpDaysRemaining = function()
  local playerState = game.player():getDailyCumulativeLogin()
  return playerState:catchUpDaysTotal() - playerState:catchUpDaysUsed()
end
function DCLCatchup:onInit()
  root = self
end
function DCLCatchup:onPostInit()
  local txt = LOC("CATCHUP_DAYS_REMAINING")
  txt = txt:gsub("%${DAYS}", catchUpDaysRemaining())
  txt = txt:gsub("%${MAX}", game.PlayerDailyCumulativeLogin_catchUpMaxDays())
  self.BG.Contents.Text:GetVar("text"):SetString(txt)
  self.BG.CatchUp.BuyPrice.Text:GetVar("text"):SetString(catchUpPrice())
  self:Show()
end
function DCLCatchup:queuePop()
  self:Hide()
end
function DCLCatchup:Show()
  self.BG:Show()
  self.Fade:Show()
  lua_sys.playSoundFx("audio/sfx/menu_slide.wav")
end
function DCLCatchup:Hide()
  self.BG:Hide()
  self.Fade:Hide()
  lua_sys.playSoundFx("audio/sfx/menu_slide.wav")
end
function DCLCatchup.BG.CloseButton:onClose()
  root:Hide()
end
function DCLCatchup.BG.CatchUp.BuyButton.Touch:onTouchUp(element, x, y)
  self:super_onTouchUp(element, x, y)
  game.collectDailyCumulativeReward(catchUpPrice())
  _G.dcl_popup:HideButtons()
  root:Hide()
end
return DCLCatchup
