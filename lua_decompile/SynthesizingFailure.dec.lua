local FadeTransition = include("FadeTransition")
local OffsetTransition = include("MenuElementPositionOffsetTransition")
local MenuHelpers = include("MenuHelpers")
local ViewGroup = include("ViewGroup")
local Pulser = include("Pulser")
local SynthesizingFailure = {}
local mainElement, flashSprite, colorizeShader, colorizeShaderFactor
local infoViewGroup = ViewGroup.new()
local gradientBG, scrollingBG, barTop, barBottom, continueLabel, critterHolder
local isPostReveal = false
local initScrollingBG = function(component, element)
  component:setScale(lua_sys.Vector2(lua_sys.screenWidth() / 128, lua_sys.screenHeight() / 128))
  component("layer"):SetString("FrontPopUps")
  component("alpha"):SetFloat(1)
  component("repeating"):SetInt(1)
  component:setShader(include("ShaderScrollingPattern"))
end
local function finishSequence()
  if flashSprite("visible"):GetInt() == 0 then
    flashSprite.FadeTransition:Show()
    flashSprite("visible"):SetInt(1)
    lua_sys.playSoundFx("audio/sfx/menu_click.wav")
  end
end
local function doReveal()
  infoViewGroup:show()
  OffsetTransition.Show(barTop)
  OffsetTransition.Show(barBottom)
  continueLabel.FadeTransition:Show()
  MenuHelpers.DoCelebrateEffect(mainElement, {playSound = false})
end
local function hideInfo()
  infoViewGroup:hide()
  continueLabel("visible"):SetInt(0)
end
local function update(element)
  element:DoStoredScript("populateCritters")
  flashSprite.FadeTransition:SetAlpha(0)
  flashSprite("visible"):SetInt(1)
  flashSprite.FadeTransition:Show()
end
local function populateCritters(element)
  local genes = game.attunerGenes()
  local availableGenes = {}
  table.insert(availableGenes, "_")
  for i = 0, genes:size() - 1 do
    table.insert(availableGenes, genes[i])
  end
  buttons = {}
  for i = 1, #availableGenes do
    local count = 0
    local string = element("reattunedCritters"):GetString()
    for i in string:gmatch(availableGenes[i]) do
      count = count + 1
    end
    if count > 0 then
      local vars = {scale = 0.45}
      local critterEntry = menu:addTemplateElementEx("template_critter_synthesizing_entry", "critterEntry" .. i, critterHolder, vars)
      if availableGenes[i] == "_" then
        critterEntry.gene = ""
      else
        critterEntry.gene = availableGenes[i]
      end
      critterEntry.num = count
      local xPos = 0
      local yPos = 10 * game.hudScale()
      critterEntry:setParent(critterHolder)
      critterEntry:relativeTo(critterHolder)
      critterEntry:setOrientation(lua_sys.MenuOrientation(xPos, yPos, 0, lua_sys.LEFT, lua_sys.VCENTER))
      critterEntry:setRelativeObjectAnchors(lua_sys.HCENTER, lua_sys.VCENTER)
      critterEntry:setOrientationPosition(lua_sys.Vector2(xPos, yPos))
      critterEntry:V("Layer"):SetString("FrontPopUps")
      critterEntry:setPositionBroadcast(false)
      critterEntry:init()
      critterEntry:showNum()
      critterEntry:setInvisible()
      critterEntry:disable()
      critterHolder:setPositionBroadcast(true)
      table.insert(buttons, critterEntry)
      infoViewGroup:add(critterEntry)
    end
  end
  MenuHelpers.CenterHorizontally(buttons)
end
function SynthesizingFailure.onInit(element)
  mainElement = element
  element:GetElement("Fade"):GetComponent("Touch"):addLuaFunction("onTouchUp", finishSequence)
  flashSprite = element:GetComponent("flash")
  flashSprite.FadeTransition = FadeTransition:new({
    duration = 0.33,
    maxFade = 1,
    onUpdate = function(alpha)
      flashSprite:GetVar("alpha"):SetFloat(alpha)
    end,
    onDoneShow = function()
      if isPostReveal then
        hideInfo()
      else
        doReveal()
      end
      flashSprite.FadeTransition:Hide()
    end,
    onDoneHide = function()
      if isPostReveal then
        mainElement:root():popPopUp()
      else
        flashSprite("visible"):SetInt(0)
        isPostReveal = true
      end
    end
  })
  colorizeShader = include("ShaderColorize")
  if colorizeShader then
    colorizeShaderFactor = colorizeShader:getUniform("u_Factor")
    colorizeShaderFactor:setFloat(0)
  end
  continueLabel = element:GetElement("ContinueLabel"):GetComponent("Text")
  continueLabel.FadeTransition = FadeTransition:new({
    delayOnShow = 4,
    duration = 1,
    maxFade = 1,
    onUpdate = function(alpha)
      continueLabel:GetVar("alpha"):SetFloat(alpha)
    end
  })
  continueLabel.FadeTransition:SetAlpha(0)
  gradientBG = element:GetElement("BGGradient"):GetComponent("Sprite")
  scrollingBG = element:GetElement("BGPattern"):GetComponent("Sprite")
  scrollingBG:addLuaFunction("onPostInit", initScrollingBG)
  gradientBG:setScale(lua_sys.Vector2(lua_sys.screenWidth() / 1024, lua_sys.screenHeight() / 4))
  gradientBG("layer"):SetString("FrontPopUps")
  local gradient, pattern
  gradient = "gfx/menu/gradient_bg_common"
  pattern = "gfx/menu/bg_symbols_common"
  gradientBG("spriteName"):SetString(gradient)
  scrollingBG("spriteName"):SetString(pattern)
  barTop = element:GetElement("BorderTop")
  OffsetTransition.OnInit(barTop, {
    startY = -128 * game.hudScale(),
    endY = 0,
    duration = 2
  })
  barBottom = element:GetElement("BorderBottom")
  OffsetTransition.OnInit(barBottom, {
    startY = 128 * game.hudScale(),
    endY = 0,
    duration = 2
  })
  critterHolder = element:E("Critters")
  element:addLuaFunction("populateCritters", populateCritters)
  infoViewGroup:add(gradientBG)
  infoViewGroup:add(scrollingBG)
  infoViewGroup:add(barTop:GetComponent("Sprite"))
  infoViewGroup:add(barBottom:GetComponent("Sprite"))
  infoViewGroup:add(element:E("FailureText2"):C("Text"))
  infoViewGroup:add(element:E("Tutorial"))
  infoViewGroup:hide()
  element("reattunedCritters"):SetString("")
  element:addLuaFunction("update", update)
end
function SynthesizingFailure.onPostInit(element)
  element:E("Tutorial"):setMeebImage("gfx/meeb_helper/helper_meeb_05")
  element:E("Tutorial"):setText("SYNTHESIS_TUTORIAL_FAILURE")
end
function SynthesizingFailure.onTick(element, dt)
  OffsetTransition.OnTick(barTop, dt)
  OffsetTransition.OnTick(barBottom, dt)
  if flashSprite("visible"):GetInt() == 1 then
    flashSprite.FadeTransition:Tick(dt)
  end
  continueLabel.FadeTransition:Tick(dt)
end
function SynthesizingFailure.queuePop(element)
  element:root():popPopUp()
end
return SynthesizingFailure
