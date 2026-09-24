local template_rewardentry = {
  Text = {},
  Sprite = {},
  AnimSprite = {}
}
function template_rewardentry:setInvisible()
  self.Text:V("visible"):SetInt(0)
  self.Sprite:V("visible"):SetInt(0)
  self.AnimSprite:V("visible"):SetInt(0)
end
function template_rewardentry:setVisible()
  self.Text:V("visible"):SetInt(1)
  self.Sprite:V("visible"):SetInt(1)
  self.AnimSprite:V("visible"):SetInt(1)
end
local rewardIds = {
  RewardCoins = game.StoreContext_TYPE_COINS,
  RewardDiamonds = game.StoreContext_TYPE_DIAMOND,
  RewardXp = game.StoreContext_TYPE_XP,
  RewardFood = game.StoreContext_TYPE_FOOD,
  RewardShards = game.StoreContext_TYPE_ETH_CURRENCY,
  RewardEntity = "entity",
  RewardKeys = game.StoreContext_TYPE_KEYS,
  RewardRelics = game.StoreContext_TYPE_RELICS,
  RewardStarpower = game.StoreContext_TYPE_STARPOWER
}
function template_rewardentry.Text:onInit(element)
  self("font"):Set(game.getTextFont())
  self("size"):SetFloat(0.19 * game.menuScaleX())
  self("alignment"):SetInt(lua_sys.MenuTextComponent_TEXT_RIGHT_ALIGNED)
  self("text"):SetString(element("RewardAmount"):GetString())
  self("layer"):SetString("Clipping")
  local type = rewardIds[element("RewardId"):GetString()]
  game.StoreContext_setCurrencyTypeColour(type, self)
end
function template_rewardentry.Sprite:onInit(element)
  if element("RewardId"):GetString() ~= "RewardEntity" then
    local spriteName = rewardIds[element("RewardId"):GetString()]
    if spriteName ~= nil then
      local typeStr = spriteName
      local currencyType = game.StoreContext_StoreTypeToCurrency(typeStr)
      local currencyProps = require("Currencies"):getProps(currencyType)
      currencyProps:applyToSpriteSheet(self)
      currencyProps:normalizeSizeH(self, 0.15 * game.menuScaleX())
      self("layer"):SetString("Clipping")
    end
  end
end
function template_rewardentry.AnimSprite:onInit(element)
  if element("RewardId"):GetString() == "RewardEntity" then
    local entityId = tonumber(element("RewardAmount"):GetString())
    if entityId then
      local animFile = game.getEntityAnimationFileFromEntId(entityId)
      local animName = game.getEntityAnimationNameFromEntId(entityId)
      if animFile ~= nil and animName ~= nil then
        self("animationName"):SetString("xml_bin/" .. animFile)
        self("animation"):SetString(animName)
        self:setScale(Vector2(0.25 * game.menuScaleX(), 0.25 * game.menuScaleX()))
        self("layer"):SetString("Clipping")
        element:setOrientationPosition(Vector2(self:size().x * 0.5 - 3 * game.menuScaleX(), self:size().y * 0.5 + 25 * game.menuScaleX()))
      end
    end
    element.Text("visible"):SetInt(0)
  end
end
return template_rewardentry
