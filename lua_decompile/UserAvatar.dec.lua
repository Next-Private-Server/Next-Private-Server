local TARGET_LENGTH = 60
local UserAvatar = {}
UserAvatar.defaultAvatarConfig = {
  Type = 3,
  Info = 1,
  Background = 3,
  Avatar = 2,
  Frame = 9
}
UserAvatar.currentAvatarConfig = {}
local shader
UserAvatar.isVisible = true
function UserAvatar.onInit(element)
  element("current_level"):SetInt(99)
  element("scale"):SetFloat(element:templateVars().scale)
  element("originalScale"):SetFloat(element:templateVars().scale)
  element("isVisible"):SetInt(1)
  element("isBattleMode"):SetInt(0)
  element("textScale"):SetFloat(1)
  element("colorPercent"):SetFloat(1)
  UserAvatar.currentAvatarConfig.Type = UserAvatar.defaultAvatarConfig.Type
  UserAvatar.currentAvatarConfig.Info = UserAvatar.defaultAvatarConfig.Info
  UserAvatar.SetBackground(element, UserAvatar.defaultAvatarConfig.Background)
  UserAvatar.SetFrame(element, UserAvatar.defaultAvatarConfig.Frame)
  UserAvatar.SetAvatar(element, UserAvatar.defaultAvatarConfig.Avatar)
end
function UserAvatar.onPostInit(element)
  shader = game.getShader("ShaderSocialAvatarMask")
  if shader == nil then
    shader = game.createShader()
    shader:setVertexShaderSource("shaders/vertex_additive.glsl")
    shader:setFragmentShaderSource("shaders/frag_masking.glsl")
    shader:addSamplerUniform("u_MaskTexture", 2, "gfx/menu/social/Avatar_mask")
    shader:addVec3Uniform("u_TargetColor", lua_sys.Vector3(1, 1, 1))
    shader:link()
    if shader:isLinked() then
      game.putShader("ShaderSocialAvatarMask", shader)
    else
      print("Error linking shader!")
      game.destroyShader(shader)
      shader = nil
    end
  end
  if shader then
    element:C("BackgroundSprite"):setShader(shader)
    element:C("AvatarSprite"):setShader(shader)
  end
end
function UserAvatar.SetAvatarData(element, avatarData)
  UserAvatar.currentAvatarConfig.Type = avatarData:getType()
  UserAvatar.currentAvatarConfig.Info = tonumber(avatarData:getInfo())
  UserAvatar.currentAvatarConfig.Background = avatarData:getBackground()
  UserAvatar.currentAvatarConfig.Avatar = avatarData:getAvatar()
  UserAvatar.currentAvatarConfig.Frame = avatarData:getFrame()
  UserAvatar.Refresh(element)
end
function UserAvatar.SetScale(element, scale)
  element("originalScale"):SetFloat(scale)
  UserAvatar.SetTempScale(element, scale)
end
function UserAvatar.SetTempScale(element, scale)
  element("scale"):SetFloat(scale)
  element:E("Level"):C("Icon")("size"):SetFloat(0.25 * scale)
  UserAvatar.SetLevel(element, element("current_level"):GetInt())
  UserAvatar.Refresh(element)
end
function UserAvatar.SetPlayerProfileItem(element, itemId)
  if itemId <= 0 then
    print("INVALID PROFILE ITEM: ItemId is 0")
    return false
  end
  local playerProfileItem = game.getPlayerProfileItem(itemId)
  if playerProfileItem:getItemType() == game.PlayerProfileItemType_BACKGROUND then
    ApplyBackground(element, playerProfileItem)
    UserAvatar.currentAvatarConfig.Background = itemId
    return true
  elseif playerProfileItem:getItemType() == game.PlayerProfileItemType_PREMIUM or playerProfileItem:getItemType() == game.PlayerProfileItemType_AVATAR then
    ApplyAvatar(element, playerProfileItem)
    UserAvatar.currentAvatarConfig.Avatar = itemId
    return true
  elseif playerProfileItem:getItemType() == game.PlayerProfileItemType_FRAME then
    ApplyFrame(element, playerProfileItem)
    UserAvatar.currentAvatarConfig.Frame = itemId
    return true
  else
    return false
  end
end
function UserAvatar.SetBackground(element, itemId)
  if itemId <= 0 then
    print("INVALID BACKGROUND: ItemId is 0")
    return false
  end
  local playerProfileItem = game.getPlayerProfileItem(itemId)
  if playerProfileItem:getItemType() == game.PlayerProfileItemType_BACKGROUND then
    UserAvatar.currentAvatarConfig.Background = itemId
    ApplyBackground(element, playerProfileItem)
    return true
  else
    print("INVALID BACKGROUND: " .. itemId .. ". TYPE INVALID: " .. playerProfileItem:getItemType())
    return false
  end
end
function ApplyBackground(element, playerProfileItem)
  local spriteElement = element:C("BackgroundSprite")
  local assetPath = playerProfileItem:getAssetPath()
  if assetPath ~= "" then
    spriteElement:setScale(lua_sys.Vector2(1, 1))
    spriteElement("spriteName"):SetString(playerProfileItem:getAssetPath())
    spriteElement:setColor(1, 1, 1)
    element("bgColorCode"):SetString("#FFFFFF")
  end
  local colorCode = playerProfileItem:getColorCode()
  if colorCode ~= "" then
    local palette = include("ColourPalette")
    spriteElement:setScale(lua_sys.Vector2(1, 1))
    spriteElement("spriteName"):SetString("__BUILTIN__WHITE_TEXTURE")
    spriteElement:setColor(palette:getRGBFloatsWithMultiplier(colorCode, element("colorPercent"):GetFloat()))
    element("bgColorCode"):SetString(colorCode)
  end
  local scale = TARGET_LENGTH * element("scale"):GetFloat() / spriteElement:absW()
  spriteElement:setScale(lua_sys.Vector2(scale, scale))
end
function UserAvatar.SetAvatar(element, itemId)
  if itemId <= 0 then
    print("INVALID AVATAR: ItemId is 0")
    return false
  end
  local playerProfileItem = game.getPlayerProfileItem(itemId)
  if playerProfileItem:getItemType() == game.PlayerProfileItemType_PREMIUM or playerProfileItem:getItemType() == game.PlayerProfileItemType_AVATAR then
    UserAvatar.currentAvatarConfig.Avatar = itemId
    ApplyAvatar(element, playerProfileItem)
    return true
  else
    print("INVALID AVATAR: " .. itemId .. ". TYPE INVALID: " .. playerProfileItem:getItemType())
    return false
  end
end
function ApplyAvatar(element, playerProfileItem)
  local spriteElement = element:C("AvatarSprite")
  local scale = TARGET_LENGTH * element("scale"):GetFloat() / 140
  if playerProfileItem:getItemType() == game.PlayerProfileItemType_PREMIUM then
    scale = TARGET_LENGTH * element("scale"):GetFloat() / 256
    element:C("FrameSprite")("visible"):SetInt(0)
    spriteElement:setShader(nil)
  else
    element:C("FrameSprite")("visible"):SetInt(element("isVisible"):GetInt())
    if shader then
      spriteElement:setShader(shader)
    end
  end
  spriteElement:setScale(lua_sys.Vector2(scale, scale))
  spriteElement("spriteName"):SetString(playerProfileItem:getAssetPath())
end
function UserAvatar.SetFrame(element, itemId)
  if itemId <= 0 then
    print("INVALID FRAME: ItemId is 0")
    return false
  end
  local playerProfileItem = game.getPlayerProfileItem(itemId)
  if playerProfileItem:getItemType() == game.PlayerProfileItemType_FRAME then
    UserAvatar.currentAvatarConfig.Frame = itemId
    ApplyFrame(element, playerProfileItem)
    return true
  else
    print("INVALID FRAME: " .. itemId .. ". TYPE INVALID: " .. playerProfileItem:getItemType())
    return false
  end
end
function ApplyFrame(element, playerProfileItem)
  local spriteElement = element:C("FrameSprite")
  local scale = TARGET_LENGTH * element("scale"):GetFloat() / 256
  spriteElement:setScale(lua_sys.Vector2(scale, scale))
  spriteElement("spriteName"):SetString(playerProfileItem:getAssetPath())
end
function UserAvatar.Refresh(element)
  local setDefault = true
  if UserAvatar.currentAvatarConfig.Type == 0 then
    if 0 < UserAvatar.currentAvatarConfig.Info then
      local avatarPlayerProfileItem = game.getNewMonsterPlayerProfileItem(UserAvatar.currentAvatarConfig.Info)
      UserAvatar.currentAvatarConfig.Type = 3
      UserAvatar.SetAvatar(element, avatarPlayerProfileItem:getItemId())
      UserAvatar.SetBackground(element, UserAvatar.defaultAvatarConfig.Background)
      UserAvatar.SetFrame(element, UserAvatar.defaultAvatarConfig.Frame)
      setDefault = false
    end
  elseif UserAvatar.currentAvatarConfig.Type == 2 then
    if UserAvatar.currentAvatarConfig.Info >= 30 then
      local avatarPlayerProfileItem = game.getNewMonikerPlayerProfileItem(UserAvatar.currentAvatarConfig.Info)
      UserAvatar.currentAvatarConfig.Type = 3
      UserAvatar.SetAvatar(element, avatarPlayerProfileItem:getItemId())
      UserAvatar.SetBackground(element, UserAvatar.defaultAvatarConfig.Background)
      setDefault = false
    end
  elseif UserAvatar.currentAvatarConfig.Type == 3 then
    UserAvatar.SetBackground(element, UserAvatar.currentAvatarConfig.Background)
    UserAvatar.SetFrame(element, UserAvatar.currentAvatarConfig.Frame)
    UserAvatar.SetAvatar(element, UserAvatar.currentAvatarConfig.Avatar)
    setDefault = false
  end
  if setDefault then
    UserAvatar.SetBackground(element, UserAvatar.defaultAvatarConfig.Background)
    UserAvatar.SetFrame(element, UserAvatar.defaultAvatarConfig.Frame)
    UserAvatar.SetAvatar(element, UserAvatar.defaultAvatarConfig.Avatar)
  end
end
function UserAvatar.SetLevel(element, level)
  element("current_level"):SetInt(level)
  local scale = element("textScale"):GetFloat() * element("scale"):GetFloat()
  local levelText = element:E("Level"):C("Text")
  levelText("text"):SetString("")
  levelText:setSize(Vector2(14 * scale, 14 * scale))
  levelText("size"):SetFloat(0.2 * scale)
  if level >= game.maxPlayerLevel() or element("isBattleMode"):GetInt() == 1 and level >= game.maxPlayerBattleLevel() then
    levelText("text"):SetString("AVATAR_MAX_LEVEL")
  else
    levelText("text"):SetString(level)
  end
end
function UserAvatar.setColorPercent(element, percent)
  element("colorPercent"):SetFloat(percent)
  element:C("AvatarSprite"):setColor(percent, percent, percent)
  element:C("FrameSprite"):setColor(percent, percent, percent)
  local levelE = element:E("Level")
  levelE:C("Icon"):setColor(percent, percent, percent)
  local palette = include("ColourPalette")
  if game.isBattleIsland() then
    levelE:C("Text"):setColor(palette:getRGBFloatsWithMultiplier(palette.BATTLE_XP_STAR_LEVEL_HUD, percent))
  else
    levelE:C("Text"):setColor(palette:getRGBFloatsWithMultiplier(palette.XP_STAR_LEVEL_HUD, percent))
  end
  element:C("BackgroundSprite"):setColor(palette:getRGBFloatsWithMultiplier(element("bgColorCode"):GetString(), percent))
end
function UserAvatar:setAlpha(percent)
  self:C("AvatarSprite")("alpha"):SetFloat(percent)
  self:C("FrameSprite")("alpha"):SetFloat(percent)
  self:E("Level"):C("Icon")("alpha"):SetFloat(percent)
  self:E("Level"):C("Text")("alpha"):SetFloat(percent)
  self:C("BackgroundSprite")("alpha"):SetFloat(percent)
  self:setColorPercent(percent)
end
return UserAvatar
