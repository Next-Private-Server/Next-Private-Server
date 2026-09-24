local ShaderShinyWorld = include("ShaderShinyWorld")
local USE_SHINY_EFFECT = true
local DEFAULT_REVEAL_SPEED = 0.4
local CardAppearance = {
  [game.CardRarity_Unknown] = {str = "Unknown"},
  [game.CardRarity_OneStar] = {
    str = "One Star",
    starSprite = "star_01",
    revealAnim = "reveal_02",
    revealDelay = DEFAULT_REVEAL_SPEED,
    lockedStarSprite = "star_locked_01",
    revealSound = "audio/sfx/sticker_reveal_flip_1star.ogg"
  },
  [game.CardRarity_TwoStar] = {
    str = "Two Star",
    starSprite = "star_02",
    revealDelay = DEFAULT_REVEAL_SPEED,
    revealAnim = "reveal_02",
    lockedStarSprite = "star_locked_02",
    revealSound = "audio/sfx/sticker_reveal_flip_2star.ogg"
  },
  [game.CardRarity_ThreeStar] = {
    str = "Three Star",
    starSprite = "star_03",
    revealAnim = "reveal_02",
    revealDelay = DEFAULT_REVEAL_SPEED,
    lockedStarSprite = "star_locked_03",
    revealSound = "audio/sfx/sticker_reveal_flip_3star.ogg"
  },
  [game.CardRarity_FourStar] = {
    str = "Four Star",
    starSprite = "star_04",
    revealAnim = "reveal_02",
    revealDelay = DEFAULT_REVEAL_SPEED,
    lockedStarSprite = "star_locked_04",
    revealSound = "audio/sfx/sticker_reveal_flip_4star.ogg"
  },
  [game.CardRarity_FiveStar] = {
    str = "Five Star",
    starSprite = "star_05",
    revealAnim = "reveal_04",
    revealDelay = 1.25,
    shiny = true,
    lockedStarSprite = "star_locked_05",
    revealSound = "audio/sfx/sticker_reveal_flip_5star.ogg"
  },
  [game.CardRarity_FourStarGold] = {
    str = "Four Star Gold",
    starSprite = "star_04",
    cardBackSprite = "frame_epic_back",
    cardFrameSprite = "frame_epic",
    glowSprite = "gfx/menu/stickers/epic_sticker_glow",
    revealAnim = "reveal_05",
    revealDelay = 2.5,
    lockedStarSprite = "star_locked_04",
    cardLockedFrameSprite = "frame_epic_locked",
    revealSound = "audio/sfx/sticker_reveal_flip_4stargold.ogg"
  },
  [game.CardRarity_FiveStarGold] = {
    str = "Five Star Gold",
    starSprite = "star_05",
    cardBackSprite = "frame_epic_back",
    cardFrameSprite = "frame_epic",
    glowSprite = "gfx/menu/stickers/epic_sticker_glow",
    revealAnim = "reveal_05",
    revealDelay = 2.5,
    shiny = true,
    lockedStarSprite = "star_locked_05",
    cardLockedFrameSprite = "frame_epic_locked",
    revealSound = "audio/sfx/sticker_reveal_flip_5stargold.ogg"
  }
}
local function getCardAppearance(rarity)
  rarity = rarity or game.CardRarity_Unknown
  local appearance = CardAppearance[rarity] or CardAppearance[game.CardRarity_Unknown]
  if appearance.showRevealFX == nil then
  end
  if appearance.shiny == nil then
  end
  return {
    str = appearance.str,
    starSprite = appearance.starSprite or "star_01",
    cardBackSprite = appearance.cardBackSprite or "frame_back",
    cardFrameSprite = appearance.cardFrameSprite or "frame",
    maskSprite = appearance.maskSprite or "gfx/menu/stickers/sticker_MASK",
    glowSprite = appearance.glowSprite or "gfx/menu/stickers/base_sticker_glow",
    revealAnim = appearance.revealAnim or "reveal_01",
    revealDelay = appearance.revealDelay or 1,
    showRevealFX = appearance.showRevealFX,
    shiny = appearance.shiny,
    lockedStarSprite = appearance.lockedStarSprite or "star_locked_01",
    cardLockedFrameSprite = appearance.cardLockedFrameSprite or "frame_common_locked",
    revealSound = appearance.revealSound
  }
end
local Card = {
  Text = {},
  Sprite = {},
  SelectedSprite = {},
  Touch = {},
  FX = {}
}
local fragShinyCard = [[
	precision mediump float;			// Set the default precision to medium. We don't need as high of a precision in the fragment shader.

	uniform lowp sampler2D u_Texture;	// The input texture.
	uniform lowp sampler2D u_alpha;		// The alpha image
	varying lowp vec4 v_Color;			// This is the color from the vertex shader interpolated across the triangle per fragment.
	varying vec2 v_TexCoordinate;		// Interpolated texture coordinate per fragment.
	varying vec3 v_WorldPosition;

	uniform vec4 u_ClipRect; // = vec4(100, 100, 200, 200); // clip is in viewport space; y = 0 is bottom of screen 
	uniform float u_Time;
	uniform vec3 u_Resolution;

	uniform lowp sampler2D u_MaskTexture;
	uniform float u_Factor;
	uniform vec3 u_TargetColor;

	//same as frag_masking, but with offset and scale
	//so we can adjust the placement of the image within the mask
	uniform vec2 u_ImageOffset;
	uniform vec2 u_ImageScale;


	float getClipping(vec2 position, vec4 clipRect)
	{
		vec2 inside = step(clipRect.xy, position.xy) * step(position.xy, clipRect.zw);
		return inside.x * inside.y;
	}

	vec4 applyShine(vec4 color, float baseAlpha)
	{
		vec2 uv = v_WorldPosition.xy / u_Resolution.xy;

		float angle = 0.7;
		float normalizedPos = cos(angle) * uv.x + sin(angle) * uv.y;

		float location = mod(u_Time * 0.2, 2.0);

		float width = 0.08;
		float softness = 1.0;
		float brightness = 1.0;
		float gloss = 1.0;

		float normalized = 1.0 - clamp(abs((normalizedPos - location) / width), 0.0, 1.0);
		float shinePower = smoothstep(0.0, softness*2.0, normalized);
		vec3 reflectColor = mix(vec3(1.0), color.rgb * 10.0, gloss);

		color.rgb += baseAlpha * (shinePower / 2.0) * brightness * reflectColor;

		return color;
	}

	void main()
	{	
		float clipping = getClipping(gl_FragCoord.xy, u_ClipRect);
		float mask = texture2D(u_MaskTexture, v_TexCoordinate).r;
		
		vec2 imageUV = v_TexCoordinate * u_ImageScale + u_ImageOffset;

		vec4 textureSample = texture2D(u_Texture, imageUV);
		vec4 alphaSample = texture2D(u_alpha, imageUV);
		vec4 base = vec4(textureSample.rgb, alphaSample.a);
		
		vec4 targetColor = vec4(u_TargetColor * base.a, base.a); //premult target color

		vec4 mixedColor = mix(v_Color * base, targetColor, u_Factor);

		//apply shinyness
		mixedColor = applyShine(mixedColor, base.a);
						
		gl_FragColor = mixedColor * mask * clipping;
	}
]]
local function getCardMaskShader(variationId, isShiny)
  local shaderName = "ShaderCardMask" .. tostring(variationId)
  local shader = game.getShader(shaderName)
  if shader == nil then
    shader = game.createShader()
    shader:setVertexShaderSource("shaders/vertex_extra.glsl")
    if isShiny then
      shader:setFragmentShaderSource(fragShinyCard, lua_sys.GlShader_SourceType_String)
    else
      shader:setFragmentShaderSource("shaders/frag_masking.glsl")
    end
    shader:addTimeUniform()
    shader:addVec3Uniform("u_Resolution", lua_sys.Vector3(1920, 1280, 0))
    shader:addSamplerUniform("u_MaskTexture", 2, "gfx/menu/stickers/sticker_MASK")
    shader:addVec3Uniform("u_TargetColor", lua_sys.Vector3(1, 1, 1))
    local imageWidth = 196
    local imageHeight = 256
    local maskWidth = 196
    local maskHeight = 256
    local scaleX = maskWidth / imageWidth
    local scaleY = maskHeight / imageHeight
    shader:addVec2Uniform("u_ImageScale", lua_sys.Vector2(scaleX, scaleY))
    local offsetX = (1 - scaleX) / 2
    local offsetY = (1 - scaleY) / 2
    shader:addVec2Uniform("u_ImageOffset", lua_sys.Vector2(offsetX, offsetY))
    shader:link()
    if shader:isLinked() then
      game.putShader(shaderName, shader)
    else
      print("Error linking shader!")
      game.destroyShader(shader)
      shader = nil
    end
  end
  return shader
end
function Card:onInit()
  self:setSearchChildren(false)
end
function Card:Setup(cardData, isNew, isLocked)
  if not self.animUtil then
    self.animUtil = game.AnimUtil(self.Sprite)
  end
  self.isLocked = isLocked
  self.isNew = isNew
  local cardAlbum = game.player():currentlyActiveCardAlbum()
  local cardAlbumId = cardAlbum:cardAlbumId()
  local cardAlbumData = game.getCardAlbumData(cardAlbumId)
  local cardNumber = cardAlbumData:getCardNumber(cardData.id)
  self.cardData = cardData
  self.Text("text"):SetString(tostring(cardNumber))
  local textLayerName = "text_placeholder"
  if self.animUtil and self.animUtil:hasLayer(textLayerName) then
    local textBoxSize = self.animUtil:getSize(textLayerName)
    if self.isLocked then
      self.Text:V("font"):Set(game.getTutorialFont())
      self.animUtil:setTintMapping(textLayerName, 0.56, 0.42, 0.13)
    else
      self.Text:V("font"):Set(game.getTitleFont())
      self.animUtil:setTintMapping(textLayerName, 1, 1, 1)
    end
    self.Text:GetVar("size"):SetFloat(0.75)
    self.Text:setSize(textBoxSize)
    self.animUtil:clearAttachedGfx()
    self.animUtil:attachMenuText(textLayerName, self.Text)
  end
  self.appearance = getCardAppearance(cardData.rarity)
  local stickerSheet = "stickers_sheet_01.xml"
  if self.isLocked then
    self.Sprite("animation"):SetString("sticker_locked")
    self.animUtil:addRemap("Stars", stickerSheet, self.appearance.lockedStarSprite)
    self.animUtil:addRemap("Frame", stickerSheet, self.appearance.cardLockedFrameSprite)
    self.animUtil:setShader("Frame", nil)
    self.animUtil:addRemap("SPRITE", "empty.xml", "empty")
  else
    local cardAssetPath = "gfx/menu/cards/sticker_" .. cardNumber
    if cardAlbumId > 1 then
      cardAssetPath = string.format("gfx/menu/cards/album_%02d/sticker_%03d", cardAlbumId, cardNumber)
    end
    self.animUtil:addRemap("SPRITE", cardAssetPath, "")
    self.animUtil:addRemap("MASK GLOW", "gfx/menu/stickers/sticker_MASK", "")
    local shaderVariationId = USE_SHINY_EFFECT and self.appearance.shiny and 2 or 1
    self.animUtil:setShader("SPRITE", getCardMaskShader(shaderVariationId, USE_SHINY_EFFECT and self.appearance.shiny))
    self.animUtil:addRemap("Stars", stickerSheet, self.appearance.starSprite)
    self.animUtil:addRemap("Stars GLOW", stickerSheet, self.appearance.starSprite)
    self.animUtil:addRemap("Stickerback", stickerSheet, self.appearance.cardBackSprite)
    self.animUtil:addRemap("Frame", stickerSheet, self.appearance.cardFrameSprite)
    self.animUtil:addRemap("Frame GLOW", stickerSheet, self.appearance.cardFrameSprite)
    if USE_SHINY_EFFECT and self.appearance.shiny then
      self.animUtil:setShader("Frame", ShaderShinyWorld)
    else
      self.animUtil:setShader("Frame", nil)
    end
  end
  self:setNew(isNew, false)
  self.animUtil:resetAnim()
  self:update()
end
local textPosX = 0
local textPosY = 0
function Card:update()
  local scaleX = 1
  local scaleY = 1
  local layerName = "Frame"
  if self.animUtil and self.animUtil:hasLayer(layerName) then
    local layerSize = self.animUtil:getSize(layerName)
    local worldPos = self.animUtil:getWorldPos(layerName)
    local worldScale = self.animUtil:getWorldScale(layerName)
    local width = layerSize.x * worldScale.x * scaleX
    local height = layerSize.y * worldScale.y * scaleY
    local posX = worldPos.x + layerSize.x * worldScale.x * (1 - scaleX) * 0.5
    local posY = worldPos.y + layerSize.y * worldScale.y * (1 - scaleY) * 0.5
    self:setSize(Vector2(width, height))
    self:setPosition(Vector2(posX, posY))
  end
end
function Card:onTick(dt)
  self:update()
end
function Card:setInvisible()
  self.Sprite("animation"):SetString("invisible")
  self.Sprite("visible"):SetInt(0)
  self.SelectedSprite("visible"):SetInt(0)
  self.Text("visible"):SetInt(0)
  self.Touch("enabled"):SetInt(0)
end
function Card:setVisible()
  self.Sprite("animation"):SetString("shown_01")
  self.Sprite("visible"):SetInt(1)
  self.Text("visible"):SetInt(1)
  self.Touch("enabled"):SetInt(1)
end
function Card:deselect()
  self.SelectedSprite("visible"):SetInt(0)
end
function Card:select()
  self.SelectedSprite("visible"):SetInt(1)
end
function Card:setNew(isNew, doReset)
  self.isNew = isNew
  if isNew then
    self.animUtil:addRemap("new_sticker", "stickers_sheet_01.xml", "new_sticker")
    self.animUtil:addRemap("new_sticker GLOW", "stickers_sheet_01.xml", "new_sticker")
  else
    self.animUtil:addRemap("new_sticker", "empty.xml", "empty")
    self.animUtil:addRemap("new_sticker GLOW", "empty.xml", "empty")
  end
  if doReset then
    self.animUtil:resetAnim()
  end
end
function Card:playRevealAnimation()
  local revealAnim = self.appearance and self.appearance.revealAnim or "reveal_01"
  self.Sprite("animation"):SetString(revealAnim)
end
function Card:hideStars()
  self.animUtil:addRemap("Stars", "stickers_sheet_01.xml", self.appearance.lockedStarSprite)
  self.animUtil:setTintMapping("Stars", 1, 1, 1, 0.5)
  self.animUtil:resetAnim()
end
return Card
