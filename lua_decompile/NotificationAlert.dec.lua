local RewardProperties = include("RewardProperties")
local NotificationAlert = {
  Base = {},
  Icon = {},
  Text = {}
}
local FADE_IN_DURATION_SEC = 0.25
local FADE_OUT_DURATION_SEC = 0.5
function NotificationAlert:onInit()
  self.TTL = 3
  self.OriginalTTL = 3
end
function NotificationAlert:onTick(dt)
  self.TTL = self.TTL - dt
  if self:isFadingIn() then
    local diff = self.OriginalTTL - self.TTL
    self:setAlpha(diff / FADE_IN_DURATION_SEC)
  elseif self:isFadingOut() then
    self:setAlpha(self.TTL / FADE_OUT_DURATION_SEC)
  else
    self:setAlpha(1)
  end
end
function NotificationAlert:isFadingIn()
  return self.TTL >= self.OriginalTTL - FADE_IN_DURATION_SEC
end
function NotificationAlert:isFadingOut()
  return self.TTL <= FADE_OUT_DURATION_SEC
end
function NotificationAlert:isAlmostDoneFadeOut()
  if not self:isFadingOut() then
    return false
  end
  local diff = FADE_OUT_DURATION_SEC - (FADE_OUT_DURATION_SEC - self.TTL)
  local fadeOutCap = FADE_OUT_DURATION_SEC * 0.333
  return diff <= fadeOutCap
end
function NotificationAlert:fromLootResult(lootResult)
  self.Icon:loadLootRewardData(lootResult)
  self.Text("text"):SetString("x" .. lootResult.amount)
  self:setAlpha(0)
end
function NotificationAlert:setAlpha(value)
  self.Base("alpha"):SetFloat(value)
  self.Icon:SetAlpha(value)
  self.Text("alpha"):SetFloat(value)
end
function NotificationAlert:setTTL(value, fadeInDelay)
  self.TTL = value + fadeInDelay
  self.OriginalTTL = value
end
return NotificationAlert
