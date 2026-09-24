local ClubboxFunctions = {}
function ClubboxFunctions.ShowClubboxMixer()
  if game.getPopUp() ~= "clubbox_customization" then
    manager:setContext("BLANK")
    game.pushPopUp("clubbox_customization")
  end
end
function ClubboxFunctions.ShowClubboxHypeGame()
  game.pushPopUp("hype_game")
end
function ClubboxFunctions.GetClubboxController()
  local clubbox = game.clubboxContext()
  if clubbox then
    return clubbox:controller()
  end
end
function ClubboxFunctions.GetClubboxProp(propName)
  local clubbox = game.clubboxContext()
  if clubbox then
    local controller = clubbox:controller()
    if controller then
      local prop = controller:getPropByName(propName)
      if prop then
        local propIndex = controller:propIndexFromName(propName)
        return prop, propIndex
      else
        print("couldn't find prop!", propName)
      end
    end
  end
end
function ClubboxFunctions.SetupWubScreen(propName, layerName)
  local prop, propIndex = ClubboxFunctions.GetClubboxProp(propName)
  if prop then
    local anim = prop:getCurrentVariantAnim()
    if anim then
      local animUtil = game.AnimUtil(anim)
      local shader = dofile("scripts/ShaderClubboxScreen.lua")
      if shader then
        animUtil:setShader(layerName, shader)
        animUtil:resetAnim()
        return true
      end
    end
  end
  return false
end
function ClubboxFunctions.SetNextVariant(propName)
  local clubbox = game.clubboxContext()
  if not clubbox then
    return
  end
  local prop, propIndex = ClubboxFunctions.GetClubboxProp(propName)
  if prop and propIndex then
    local numVariants = prop:numVariants()
    local currentVariant = prop:getCurVariant()
    local nextVariant = currentVariant
    repeat
      if nextVariant >= numVariants - 1 then
        nextVariant = -1
      else
        nextVariant = nextVariant + 1
      end
      if clubbox:variantUnlocked(propIndex, nextVariant) then
        break
      end
    until nextVariant ~= currentVariant
    if nextVariant ~= currentVariant then
      prop:setVariant(nextVariant)
    end
  end
end
function ClubboxFunctions.SetNextVariantOnPick()
  ClubboxFunctions.SetNextVariant(ClubboxPick.name)
end
function ClubboxFunctions.IsScreenFxEnabled()
  local TOGGLE_SCREEN_FX_KEY = "enableClubboxScreenFx"
  return (tonumber(game.getLocalSettings():get(TOGGLE_SCREEN_FX_KEY)) or 1) == 1
end
function ClubboxFunctions.OnPickDJ()
  local actId = game.clubboxContext():actId()
  local actData = game.getClubboxActData(actId)
  local topHype = game.player():curClubboxTopHype(actId)
  if topHype < actData:mixerUnlocksAt() then
    return
  end
  if game.clubboxContext():mode() == game.ClubboxMode_MEMORY then
    ClubboxFunctions.ShowClubboxMixer()
  else
    ClubboxFunctions.ShowClubboxHypeGame()
  end
end
return ClubboxFunctions
