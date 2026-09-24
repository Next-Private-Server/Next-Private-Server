local MonsterEvolvePopup = {}
local FadeTransition = include("FadeTransition")
local c_monsterAnim, c_oldMonsterAnim, colorizeShader, colorizeShaderFactor
local function setupEvolve(element)
  local monsterId = element("MonsterID"):GetInt()
  local monsterData = game.getMonsterData(monsterId)
  costumeId = element("CostumeID"):GetInt()
  local monsterName = element:GetElement("MonsterName"):GetComponent("Text")
  monsterName("text"):SetString(monsterData:name())
  c_monsterAnim("animationName"):SetString("xml_bin/" .. monsterData:animationFile())
  c_monsterAnim("animation"):SetString("Store")
  if costumeId > 0 then
    game.applyCostumeToAnimComponent(c_monsterAnim, costumeId)
  end
  c_monsterAnim:DoStoredScript("reposition")
  local oldMonsterId = element("OldMonsterID"):GetInt()
  if oldMonsterId ~= 0 then
    local oldMonsterData = game.getMonsterData(oldMonsterId)
    c_oldMonsterAnim("animationName"):SetString("xml_bin/" .. oldMonsterData:animationFile())
    c_oldMonsterAnim("animation"):SetString("Store")
    if costumeId > 0 then
      game.applyCostumeToAnimComponent(c_oldMonsterAnim, costumeId)
    end
    c_oldMonsterAnim:DoStoredScript("reposition")
    c_oldMonsterAnim("visible"):SetInt(1)
    c_oldMonsterAnim.FadeTransition = FadeTransition:new({
      duration = 2,
      maxFade = 1,
      onDoneShow = function()
        c_oldMonsterAnim("visible"):SetInt(0)
        c_monsterAnim:setShader(colorizeShader)
        c_monsterAnim("visible"):SetInt(1)
        c_monsterAnim("alpha"):Set(1)
        c_monsterAnim.FadeTransition:Hide()
      end,
      onUpdate = function(alpha)
        c_oldMonsterAnim:GetVar("alpha"):SetFloat(alpha)
        colorizeShaderFactor:setFloat(alpha)
      end
    })
    c_oldMonsterAnim.FadeTransition:SetAlpha(0)
    c_oldMonsterAnim.FadeTransition:Show()
    c_monsterAnim("visible"):SetInt(0)
    c_monsterAnim.FadeTransition = FadeTransition:new({
      duration = 2,
      maxFade = 1,
      onUpdate = function(alpha)
        c_monsterAnim("alpha"):Set(alpha)
        colorizeShaderFactor:setFloat(alpha)
      end
    })
    c_monsterAnim.FadeTransition:SetAlpha(1)
  else
    c_oldMonsterAnim("visible"):SetInt(0)
  end
end
local function initializeChildren(element)
  c_monsterAnim = element:GetElement("MonsterAnim"):GetComponent("Sprite")
  c_oldMonsterAnim = element:GetElement("OldMonsterAnim"):GetComponent("Sprite")
end
function MonsterEvolvePopup.onInit(element)
  initializeChildren(element)
  element:addLuaFunction("setupEvolve", setupEvolve)
  colorizeShader = include("ShaderColorize")
  if colorizeShader then
    colorizeShaderFactor = colorizeShader:getUniform("u_Factor")
    colorizeShaderFactor:setFloat(0)
    c_oldMonsterAnim:setShader(colorizeShader)
  end
end
function MonsterEvolvePopup.onTick(element, dt)
  c_oldMonsterAnim.FadeTransition:Tick(dt)
  c_monsterAnim.FadeTransition:Tick(dt)
end
return MonsterEvolvePopup
