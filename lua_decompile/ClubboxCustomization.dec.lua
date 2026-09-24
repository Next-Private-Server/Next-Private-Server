local ClubboxPropData = include("ClubboxPropData")
local Coroutines = include("Coroutines")
local ClubboxCustomization = {
  transitionState = 1,
  transitionTime = 0,
  cooldown = 0,
  choice = "none",
  FadedBG = {},
  bg = {},
  PerformerEditor = {},
  StageEditor = {}
}
function ClubboxCustomization:onInit()
  self("transitionState"):SetInt(1)
  self("transitionTime"):SetFloat(0)
  self("choice"):SetString("none")
  lua_sys.playSoundFx("audio/sfx/clubbox_menu_enter.wav")
end
function ClubboxCustomization:onPostInit()
  local bgWidth = self:GetElement("bg"):absW()
  self:GetElement("PerformerEditor")("xOffset"):SetInt(bgWidth * -0.615)
  self.actId = game.clubboxContext():actId()
  self.playerClubboxData = game.player():getPlayerClubbox(self.actId)
  local lastHype = tonumber(game.getLocalSettings():get("ClubboxSeenTopHype" .. self.actId)) or 0
  local newUnlockedProps, newUnlockedPerformers = ClubboxPropData:GetUnlockedProps(self.actId, lastHype, self.playerClubboxData:topAchievedHype())
  self.PerformerEditor:SetupNotifications(newUnlockedPerformers)
  self.StageEditor:SetupNotifications(newUnlockedProps)
end
function ClubboxCustomization:startCooldown()
  self:disablePropSwitching()
  RunIndyCoroutine(self.StartCooldownCo, self, true)
end
function ClubboxCustomization:StartCooldownCo()
  Coroutines.WaitForSeconds(game.clubboxMixerboardMaxCooldown())
  self:enablePropSwitching()
end
function ClubboxCustomization:disablePropSwitching()
  self.PerformerEditor:disablePropSwitching()
  self.StageEditor:disablePropSwitching()
end
function ClubboxCustomization:enablePropSwitching()
  self.PerformerEditor:enablePropSwitching()
  self.StageEditor:enablePropSwitching()
end
function ClubboxCustomization:onTick(dt)
  local transitionState = self("transitionState"):GetInt()
  if transitionState ~= 0 then
    local transitionTime = self("transitionTime"):GetFloat()
    self:DoStoredScript("TickTransition")
    if transitionState == 1 then
      transitionTime = transitionTime + dt * 3
    elseif transitionState == 2 then
      transitionTime = transitionTime - dt * 3
    end
    transitionTime = clamp(transitionTime, 0, 1)
    self("transitionTime"):SetFloat(transitionTime)
    if transitionTime >= 1 then
      self("transitionState"):SetInt(0)
      self("transitionTime"):SetFloat(1)
      self:DoStoredScript("TickTransition")
    elseif transitionTime <= 0 then
      manager:setContext("CLUBBOX_DEFAULT")
      if self("choice"):GetString() == "true" then
        self:root():popPopUp()
      else
        self:root():popPopUp()
      end
      game.getLocalSettings():set("ClubboxSeenTopHype" .. self.actId, tostring(self.playerClubboxData:topAchievedHype()))
    end
  end
end
function ClubboxCustomization:TickTransition()
  local transitionTime = self("transitionTime"):GetFloat()
  self.bg("yOffset"):SetFloat(lua_sys.screenHeight() * 0.5 - self.bg("bottomOffset"):GetInt() + -0.5 * lua_sys.screenHeight() * (1 / transitionTime))
end
function ClubboxCustomization:queuePop()
  self("transitionState"):SetInt(2)
end
function ClubboxCustomization:closeCustomizeMenu()
  if not game.disableClubboxMixerExit() then
    game.saveClubboxCustomizations()
    self("transitionState"):SetInt(2)
    self("choice"):SetString("false")
    lua_sys.playSoundFx("audio/sfx/clubbox_menu_exit.wav")
  end
end
return ClubboxCustomization
