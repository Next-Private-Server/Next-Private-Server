local OffsetTransition = require("OffsetTransition")
local FadeTransition = require("FadeTransition")
local ClubboxUnlockFanfare = {
  Fade = {
    Touch = {}
  },
  BorderTop = {
    Sprite = {}
  },
  BorderBottom = {
    Sprite = {}
  },
  BGGradient = {
    Sprite = {}
  },
  BGPattern = {
    Sprite = {}
  },
  MonsterAnim = {
    Sprite = {}
  },
  MonsterName = {
    Text = {}
  },
  MonsterInfo = {
    Text = {}
  }
}
function ClubboxUnlockFanfare:onPostInit()
  self.tickables = {}
  local gradientSprite = self.BGGradient.Sprite
  gradientSprite:setScale(lua_sys.Vector2(lua_sys.screenWidth() / 1024, lua_sys.screenHeight() / 4))
  gradientSprite("layer"):SetString("FrontPopUps")
  gradientSprite("spriteName"):SetString("gfx/menu/gradient_bg_clubbox")
  local patternSprite = self.BGPattern.Sprite
  patternSprite:setScale(lua_sys.Vector2(lua_sys.screenWidth() / 128, lua_sys.screenHeight() / 128))
  patternSprite("layer"):SetString("FrontPopUps")
  patternSprite("alpha"):SetFloat(1)
  patternSprite("repeating"):SetInt(1)
  patternSprite:setShader(include("ShaderScrollingPattern"))
  patternSprite("spriteName"):SetString("gfx/menu/bg_symbols_clubbox")
  self.bgFadeTransition = FadeTransition:new({
    duration = 1.67,
    delayOnShow = 0.33,
    onUpdate = function(alpha)
      gradientSprite:GetVar("alpha"):SetFloat(alpha)
      patternSprite:GetVar("alpha"):SetFloat(alpha)
    end,
    onDoneHide = function()
      self:root():removePopUp(self:name())
    end
  })
  self.bgFadeTransition:SetAlpha(0)
  self.bgFadeTransition:Show()
  table.insert(self.tickables, self.bgFadeTransition)
  self.borderTransition = OffsetTransition:new({
    startY = -128 * game.hudScale(),
    endY = 0,
    duration = 1.67,
    ease = lua_sys.Quadratic_EaseIn,
    onUpdate = function(x, y)
      self.BorderTop:GetVar("yOffset"):SetFloat(y)
      self.BorderBottom:GetVar("yOffset"):SetFloat(-y)
    end
  })
  self.borderTransition:Show()
  table.insert(self.tickables, self.borderTransition)
  local monsterStartX = lua_sys.screenWidth() + self.MonsterAnim:absW() * 0.5
  self.monsterTransition = OffsetTransition:new({
    startX = monsterStartX,
    endX = lua_sys.screenWidth() * 2 / 3,
    duration = 1.67,
    delayOnShow = 0.33,
    onUpdate = function(x, y)
      self.MonsterAnim:GetVar("xOffset"):SetFloat(x)
    end
  })
  self.monsterTransition:SetOffset(monsterStartX, 0)
  self.monsterTransition:Show()
  table.insert(self.tickables, self.monsterTransition)
  self.textFadeTransition = FadeTransition:new({
    duration = 1.34,
    delayOnShow = 0.67,
    onUpdate = function(alpha)
      self.MonsterName.Text:GetVar("alpha"):SetFloat(alpha)
      self.MonsterInfo.Text:GetVar("alpha"):SetFloat(alpha)
    end
  })
  self.textFadeTransition:SetAlpha(0)
  self.textFadeTransition:Show()
  table.insert(self.tickables, self.textFadeTransition)
  function self.Fade.Touch.onTouchUp(c, e)
    if self.monsterTransition:GetTransitionTime() <= 0.1 then
      self:Hide()
    end
  end
end
function ClubboxUnlockFanfare:onTick(dt)
  for _, tickable in ipairs(self.tickables) do
    if tickable.Tick then
      tickable:Tick(dt)
    end
  end
end
function ClubboxUnlockFanfare:Init(monsterId, costumeId, isVariant)
  if monsterId == 52 and game.clubboxContext():actId() == 4 then
    self.MonsterAnim.Sprite:GetVar("animationName"):SetString("xml_bin/club01-04_monster_s05.bin")
    self.MonsterAnim.Sprite:GetVar("animation"):SetString("Idle")
    local descText = "JOINED_THE_SHOW"
    if costumeId == 612 then
      game.applyCostumeFileToAnimComponent(self.MonsterAnim.Sprite, "xml_bin/club01-04_costume_S05_06.bin")
    elseif costumeId == 613 then
      game.applyCostumeFileToAnimComponent(self.MonsterAnim.Sprite, "xml_bin/club01-04_costume_S05_07.bin")
    end
    if isVariant > 0 then
      descText = "NEW_COSTUME_UNLOCKED"
    end
    self.MonsterName.Text:GetVar("text"):SetString("CLUBBOX_MEMORY_DJ_NAME")
    self.MonsterInfo.Text:GetVar("text"):SetString(descText)
  else
    local monsterData = game.getMonsterData(monsterId)
    self.MonsterAnim.Sprite:GetVar("animationName"):SetString("xml_bin/" .. monsterData:animationFile())
    self.MonsterAnim.Sprite:GetVar("animation"):SetString(monsterData:animationCostumeMenuName())
    local descText = "JOINED_THE_SHOW"
    if costumeId > 0 then
      game.applyCostumeToAnimComponent(self.MonsterAnim.Sprite, costumeId)
    end
    if isVariant > 0 then
      descText = "NEW_COSTUME_UNLOCKED"
    end
    self.MonsterName.Text:GetVar("text"):SetString(monsterData:name())
    self.MonsterInfo.Text:GetVar("text"):SetString(descText)
  end
end
function ClubboxUnlockFanfare:Hide()
  self.bgFadeTransition:Hide()
  self.borderTransition:Hide()
  self.monsterTransition:Hide()
  self.textFadeTransition:Hide()
  self.Fade:Hide()
end
function ClubboxUnlockFanfare:queuePop()
  self:root():removePopUp(self:name())
end
return ClubboxUnlockFanfare
