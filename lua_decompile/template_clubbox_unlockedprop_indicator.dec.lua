local ClubboxPropData = include("ClubboxPropData")
local TweenerPingPong = include("TweenerPingPong")
local template_clubbox_unlockedprop_indicator = {
  Sprite = {}
}
local function checkIndicator(topHype)
  local actId = game.existingClubboxAct()
  local lastHype = tonumber(game.getLocalSettings():get("ClubboxSeenTopHype" .. actId)) or 0
  local newUnlockedProps, newUnlockedPerformers = ClubboxPropData:GetUnlockedProps(actId, lastHype, topHype)
  return #newUnlockedPerformers > 0 or #newUnlockedProps > 0
end
function template_clubbox_unlockedprop_indicator:onPostInit()
  local actId = game.existingClubboxAct()
  local clubbox = game.player():getPlayerClubbox(actId)
  self.hasIndicator = clubbox and checkIndicator(clubbox:topAchievedHype())
  self.Sprite("visible"):SetInt(self.hasIndicator and 1 or 0)
  self.isVisible = true
  self:SetupGenericListener(game.engineReceiver(), "game::msg::MsgClubboxHypeUpdated", "gotMsgClubboxHypeUpdated")
  local pulseSize = self.Sprite:GetVar("size"):GetFloat()
  self.pulser = TweenerPingPong:new({
    loopTime = 0.5,
    ease = lua_sys.Quadratic_EaseIn,
    onUpdate = function(target, t)
      target:GetVar("size"):SetFloat(pulseSize * (1 + t * 0.25))
    end,
    targets = {
      self.Sprite
    }
  })
end
function template_clubbox_unlockedprop_indicator:onTick(dt)
  if self.pulser then
    self.pulser:Tick(dt)
  end
end
function template_clubbox_unlockedprop_indicator:gotMsgClubboxHypeUpdated(msg)
  self.hasIndicator = checkIndicator(msg.topHype)
  if self.hasIndicator and self.isVisible then
    self.Sprite("visible"):SetInt(1)
  else
    self.Sprite("visible"):SetInt(0)
  end
end
function template_clubbox_unlockedprop_indicator:SetVisible()
  self.isVisible = true
  if self.hasIndicator then
    self.Sprite("visible"):SetInt(1)
  else
    self.Sprite("visible"):SetInt(0)
  end
end
function template_clubbox_unlockedprop_indicator:SetInvisible()
  self.isVisible = false
  self.Sprite("visible"):SetInt(0)
end
function template_clubbox_unlockedprop_indicator:SetEnabled()
  self.Sprite:setColor(1, 1, 1)
end
function template_clubbox_unlockedprop_indicator:SetDisabled()
  self.Sprite:setColor(0.5, 0.5, 0.5)
end
return template_clubbox_unlockedprop_indicator
