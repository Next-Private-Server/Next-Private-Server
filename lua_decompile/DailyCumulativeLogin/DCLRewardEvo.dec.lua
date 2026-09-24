local MenuHelpers = include("MenuHelpers")
local FadeTransition = include("FadeTransition")
local ANIMS = {
  "colosseye_closed_idle_01",
  "colosseye_closed_idle_02",
  "colosseye_closed_idle_03",
  "colosseye_closed_idle_04"
}
local getStructureAlias = function(entityId, idx, total)
  local structureData = game.getStructureByEntityId(entityId)
  if structureData then
    local alias = LOC("STRUCTURE_AWAKENER_ISLAND")
    local island = structureData:getExtraString("island")
    if island then
      alias = alias:gsub("%${ISLAND}", LOC(island))
    end
    local txt = LOC("AWAKENER_PROGRESS")
    txt = txt:gsub("%${NAME}", LOC(alias))
    txt = txt:gsub("%${CURRENT}", tostring(idx))
    txt = txt:gsub("%${TOTAL}", tostring(total))
    return txt
  end
  return game.entityName(entityId)
end
local function getRewardAppearance()
  local awakener = game.FindAwakener()
  local entityId = awakener:entityId()
  local playerState = game.player():getDailyCumulativeLogin()
  local calendarId = playerState:calendar()
  local calendarData = game.getDailyCumulativeLoginData(calendarId)
  local rewardIdx = playerState:reward()
  local pre = math.floor((rewardIdx - 1) / math.floor(calendarData:getNumRewards() / #ANIMS))
  local post = math.floor(rewardIdx / math.floor(calendarData:getNumRewards() / #ANIMS))
  return {
    name = getStructureAlias(entityId, post, #ANIMS),
    value = 1,
    animFile = game.entityAnimFile(entityId),
    preAnimName = ANIMS[pre + 1],
    postAnimName = ANIMS[post + 1],
    bgAnimFile = "glow.bin",
    bgAnimName = "glow",
    animOffsetY = 36 * game.menuScaleX(),
    getTargetUI = function()
      return manager:getButton("btn_market")
    end,
    iconName = "button_castle",
    iconSheet = "xml_resources/hud03.xml",
    particleFile = "particles/particle_diamond_get.psi",
    particleImage = "gfx/particles/particle_star"
  }
end
local DCLRewardEvo = {
  AnimPre = {},
  AnimPost = {}
}
function DCLRewardEvo:Init(idx)
  self.idx = idx
  local appearance = getRewardAppearance()
  self.ItemTitle = appearance.name or ""
  self.AnimationFile = appearance.animFile or ""
  self.PreAnimationName = appearance.preAnimName or ""
  self.PostAnimationName = appearance.postAnimName or ""
  self.CostumeId = appearance.costumeId or 0
  self.BgAnimationFile = appearance.bgAnimFile or ""
  self.BgAnimationName = appearance.bgAnimName or ""
  if not appearance.tint then
    local tint = {
      r = 1,
      g = 1,
      b = 1
    }
  end
  self.TintR = tint.r
  self.TintG = tint.g
  self.TintB = tint.b
  self.appearance = appearance
end
function DCLRewardEvo:onPostInit()
  local offsetY = self.appearance.animOffsetY or 0
  self.AnimPre.Sprite:setOrientationPosition(lua_sys.Vector2(0, offsetY))
  self.AnimPost.Sprite:setOrientationPosition(lua_sys.Vector2(0, offsetY))
  self.FadeTransition = FadeTransition:new({
    delayOnHide = 1,
    duration = 2,
    maxFade = 1,
    onUpdate = function(alpha)
      self.AnimPre.Sprite:GetVar("alpha"):SetFloat(alpha)
      self.AnimPre.Sprite:setColor(1, 1, 1)
    end
  })
  self.FadeTransition:SetAlpha(1)
  self.FadeTransition:Hide()
  self:updateAlpha(0)
end
function DCLRewardEvo:onTick(dt)
  self.FadeTransition:Tick(dt)
end
function DCLRewardEvo:updateClipping()
  MenuHelpers.SetClipFrom(self.Touch, self)
  MenuHelpers.SetClipFrom(self.AnimPre.Sprite, self)
  MenuHelpers.SetClipFrom(self.AnimPost.Sprite, self)
  MenuHelpers.SetClipFrom(self.AnimPost.SpriteBG, self)
  MenuHelpers.SetClipFrom(self.NameFrame.Text, self)
end
function DCLRewardEvo:updateAlpha(alpha)
  local combined = alpha * self.FadeTransition.alpha
  self.AnimPre.Sprite:GetVar("alpha"):SetFloat(combined)
  self.AnimPre.Sprite:setColor(1, 1, 1)
  self.AnimPost.Sprite:GetVar("alpha"):SetFloat(alpha)
  self.AnimPost.Sprite:setColor(alpha, alpha, alpha)
  self.AnimPost.SpriteBG:GetVar("alpha"):SetFloat(alpha)
  self.AnimPost.SpriteBG:setColor(alpha, alpha, alpha)
  self.NameFrame.Text:GetVar("alpha"):SetFloat(alpha)
end
return DCLRewardEvo
