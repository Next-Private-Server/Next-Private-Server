local MonsterProperties = include("MonsterProperties")
local template_ClubboxPerfEditor = {
  PerfEditorBg = {},
  PerformerListView = {
    Prop0 = {},
    Prop1 = {},
    Prop2 = {},
    Prop3 = {},
    Prop4 = {},
    Prop5 = {}
  },
  CostumeView = {
    Variant0 = {},
    Variant1 = {},
    Variant2 = {},
    Variant3 = {},
    MonsterAvatar = {
      Anim = {}
    },
    selectedPropInd = -1,
    selectedVariantInd = -1,
    maxNumVariants = 4
  },
  OptionsView = {
    BackButton = {},
    ToggleScreenFx = {}
  }
}
function template_ClubboxPerfEditor:onInit()
  self.PerformerListView:populateProps()
end
function template_ClubboxPerfEditor:onPostInit()
  self:setPerformerView(false)
end
function template_ClubboxPerfEditor:setPerformerView(playSound)
  if playSound == nil then
    playSound = true or playSound
  end
  self.PerformerListView:setVisible()
  self.CostumeView:setInvisible()
  self.OptionsView:setVisible(false)
  if playSound then
    lua_sys.playSoundFx("audio/sfx/clubbox_menu_changetab.wav")
  end
end
function template_ClubboxPerfEditor:setCostumeView()
  self.PerformerListView:setInvisible()
  self.CostumeView:setVisible()
  self.OptionsView:setVisible(false)
  self.CostumeView.selectedVariantInd = game.activeClubboxPropVariant(self.CostumeView.selectedPropInd)
  self.CostumeView:updateCostumeView()
  lua_sys.playSoundFx("audio/sfx/clubbox_menu_changetab.wav")
end
function template_ClubboxPerfEditor:setOptionsView()
  self.PerformerListView:setInvisible()
  self.CostumeView:setInvisible()
  self.OptionsView:setVisible(true)
  lua_sys.playSoundFx("audio/sfx/clubbox_menu_changetab.wav")
end
function template_ClubboxPerfEditor:disablePropSwitching()
  self.PerformerListView:disablePropSwitching()
  self.CostumeView:disablePropSwitching()
end
function template_ClubboxPerfEditor:enablePropSwitching()
  self.PerformerListView:enablePropSwitching()
  self.CostumeView:enablePropSwitching()
end
function template_ClubboxPerfEditor:SetupNotifications(newUnlockedPerformers)
  local monsterProps = game.clubboxMonsterPerformers()
  for i = 0, monsterProps:size() - 1 do
    local propControl = self:GetElement("Prop" .. i)
    if propControl then
      local monsterId = game.clubboxPropMonster(propControl.propInd)
      for _, v in ipairs(newUnlockedPerformers) do
        if v.monsterId == monsterId then
          propControl.Alert.Sprite:GetVar("visible"):SetInt(1)
          break
        end
      end
    end
  end
end
function template_ClubboxPerfEditor.PerformerListView:populateProps()
  local propControl
  local propControlInd = 0
  while true do
    propControl = self:GetElement("Prop" .. propControlInd)
    if propControl ~= nil then
      propControl.propInd = -1
      propControlInd = propControlInd + 1
    else
      break
    end
  end
  local monsterProps = game.clubboxMonsterPerformers()
  local djHoolaInd = game.getDJHoolaPropInd()
  propControlInd = 0
  local propControl = self:GetElement("Prop" .. propControlInd)
  if propControl ~= nil then
    if djHoolaInd ~= -1 then
      propControl.propInd = djHoolaInd
      propControlInd = propControlInd + 1
    end
    for i = 0, monsterProps:size() - 1 do
      propControl = self:GetElement("Prop" .. propControlInd)
      if propControl ~= nil then
        if djHoolaInd ~= monsterProps[i] then
          propControl.propInd = monsterProps[i]
          propControlInd = propControlInd + 1
        else
        end
      else
        break
      end
    end
  end
end
function template_ClubboxPerfEditor.PerformerListView:setVisible()
  local ind = 0
  while true do
    local propControl = self:GetElement("Prop" .. ind)
    if propControl ~= nil then
      propControl:setVisible()
      ind = ind + 1
    else
      break
    end
  end
end
function template_ClubboxPerfEditor.PerformerListView:setInvisible()
  local ind = 0
  while true do
    local propControl = self:GetElement("Prop" .. ind)
    if propControl ~= nil then
      propControl:setInvisible()
      ind = ind + 1
    else
      break
    end
  end
end
function template_ClubboxPerfEditor.PerformerListView:disablePropSwitching()
  print("template_ClubboxPerfEditor.PerformerListView:disablePropSwitching()")
  local ind = 0
  while true do
    local propControl = self:GetElement("Prop" .. ind)
    if propControl ~= nil then
      print("Call Prop" .. ind .. ":disable()")
      propControl:disable()
      ind = ind + 1
    else
      break
    end
  end
end
function template_ClubboxPerfEditor.PerformerListView:enablePropSwitching()
  local ind = 0
  while true do
    local propControl = self:GetElement("Prop" .. ind)
    if propControl ~= nil then
      propControl:enable()
      ind = ind + 1
    else
      break
    end
  end
end
function template_ClubboxPerfEditor.CostumeView:setInvisible()
  self.BackButton:setInvisible()
  local ind = 0
  while true do
    local control = self:GetElement("Variant" .. ind)
    if control ~= nil then
      control:setInvisible()
      ind = ind + 1
    else
      break
    end
  end
  self.MonsterAvatar:setInvisible()
end
function template_ClubboxPerfEditor.CostumeView:setVisible()
  self.BackButton:setVisible()
  local ind = 0
  while true do
    local control = self:GetElement("Variant" .. ind)
    if control ~= nil then
      control:setVisible()
      ind = ind + 1
    else
      break
    end
  end
  self.MonsterAvatar:setVisible()
  self:populateVariants()
  self:refreshAvatar()
end
function template_ClubboxPerfEditor.CostumeView:disablePropSwitching()
  print("template_ClubboxPerfEditor.CostumeView:disablePropSwitching()")
  self.BackButton:disable()
  local ind = 0
  while true do
    local varControl = self:GetElement("Variant" .. ind)
    if varControl ~= nil then
      print("Call Variant" .. ind .. ":disable()")
      varControl:disable()
      ind = ind + 1
    else
      break
    end
  end
end
function template_ClubboxPerfEditor.CostumeView:enablePropSwitching()
  self.BackButton:enable()
  local ind = 0
  while true do
    local varControl = self:GetElement("Variant" .. ind)
    if varControl ~= nil then
      varControl:enable()
      ind = ind + 1
    else
      break
    end
  end
end
function template_ClubboxPerfEditor.CostumeView:selectProp()
  self:populateVariants()
  self:refreshAvatar()
  self:parent():setCostumeView()
end
function template_ClubboxPerfEditor.CostumeView:selectVariant()
  game.activateClubboxVariant(self.selectedPropInd, self.selectedVariantInd)
  self:parent():parent():startCooldown()
  self:updateCostumeView()
  lua_sys.playSoundFx("audio/sfx/clubbox_menu_costume_change.wav")
end
function template_ClubboxPerfEditor.CostumeView:updateCostumeView()
  self:highlightSelectedVariant()
  self:applyCostumeToPreview()
end
function template_ClubboxPerfEditor.CostumeView:highlightSelectedVariant()
  if self.selectedPropInd ~= -1 then
    for i = 0, self.maxNumVariants - 1 do
      local variantControl = self.CostumeView:GetElement("Variant" .. i)
      if variantControl ~= nil then
        if variantControl.variantInd == self.selectedVariantInd then
          variantControl:highlight()
        else
          variantControl:unhighlight()
        end
      end
    end
  end
end
function template_ClubboxPerfEditor.CostumeView:applyCostumeToPreview()
  local costumeId = game.clubboxVariantCostumeId(self.selectedPropInd, self.selectedVariantInd)
  if costumeId == 612 then
    game.applyCostumeFileToAnimComponent(self.MonsterAvatar.Anim, "xml_bin/club01-04_costume_S05_06.bin")
    self.MonsterAvatar.Anim("visible"):SetInt(1)
  elseif costumeId == 613 then
    game.applyCostumeFileToAnimComponent(self.MonsterAvatar.Anim, "xml_bin/club01-04_costume_S05_07.bin")
    self.MonsterAvatar.Anim("visible"):SetInt(1)
  elseif costumeId >= 0 then
    game.applyCostumeToAnimComponent(self.MonsterAvatar.Anim, costumeId)
    self.MonsterAvatar.Anim("visible"):SetInt(1)
  else
    self.MonsterAvatar.Anim("visible"):SetInt(0)
  end
  local padding = 10 * game.hudScale()
  self.MonsterAvatar.Anim:setClipRect(self:absX() + padding, self:absY() + padding, self:absW() - padding * 2, self:absH() - padding * 2)
end
function template_ClubboxPerfEditor.CostumeView:populateVariants()
  if self.selectedPropInd ~= -1 then
    local numVariants = game.clubboxNumVariantsInProp(self.selectedPropInd)
    for i = 0, self.maxNumVariants - 1 do
      local variantControl = self.CostumeView:GetElement("Variant" .. i)
      if variantControl ~= nil then
        if i == 0 then
          variantControl.variantInd = -1
          variantControl:setVisible()
          variantControl:refresh()
        elseif numVariants > i - 1 and game.clubboxVariantUnlocked(self.selectedPropInd, i - 1) then
          variantControl.variantInd = i - 1
          variantControl:setVisible()
          variantControl:refresh()
        else
          variantControl:setInvisible()
        end
      end
    end
  end
end
function template_ClubboxPerfEditor.CostumeView.MonsterAvatar:setInvisible()
  self.Anim("visible"):SetInt(0)
end
function template_ClubboxPerfEditor.CostumeView.MonsterAvatar:setVisible()
  self.Anim("visible"):SetInt(1)
end
function template_ClubboxPerfEditor.CostumeView:onPostInit(element)
  self.MonsterAvatar:setSize(Vector2(self:absW() * 0.5, self:absH()))
end
local scaleAnimToTarget = function(anim, targetW, targetH)
  anim:setScale(Vector2(1, 1))
  local w = anim:absW()
  local h = anim:absH()
  local scaleW = targetW / w
  local scaleH = targetH / h
  local scale = scaleW > scaleH and scaleH or scaleW
  anim:setScale(Vector2(scale, scale))
end
function template_ClubboxPerfEditor.CostumeView:refreshAvatar()
  if self.selectedPropInd ~= -1 then
    local act = game.clubboxContext():actId()
    local monsterId = game.clubboxPropMonster(self.selectedPropInd)
    local entityId = game.monsterTypeEntityId(monsterId)
    if act == 4 and monsterId == 52 then
      local animationFile = "xml_bin/club01-04_monster_s05.bin"
      local animationName = "Idle"
      self.MonsterAvatar.Anim("animationName"):SetString(animationFile)
      self.MonsterAvatar.Anim("animation"):SetString(animationName)
      local targetWidth = self.MonsterAvatar:absW() * 0.8
      local targetHeight = self.MonsterAvatar:absH() * 0.8
      scaleAnimToTarget(self.MonsterAvatar.Anim, targetWidth, targetHeight)
      self.MonsterAvatar.Anim("yOffset"):SetFloat(-20 * game.windowScaleY())
      self:applyCostumeToPreview()
    else
      self.MonsterAvatar.Anim("xOffset"):SetFloat(0)
      self.MonsterAvatar.Anim("yOffset"):SetFloat(0)
      local animationFile = "xml_bin/" .. game.getMonsterAnimationFileFromType(monsterId)
      self.MonsterAvatar.Anim("animationName"):SetString(animationFile)
      local animationName = game.getEntityData(entityId):animationCostumeMenuName()
      self.MonsterAvatar.Anim("animation"):SetString(animationName)
      local targetWidth = self.MonsterAvatar:absW() * 0.8
      local targetHeight = self.MonsterAvatar:absH() * 0.8
      if animationName == "Idle" then
        MonsterProperties.scaleIdle(monsterId, self.MonsterAvatar.Anim, targetWidth, targetHeight)
      else
        scaleAnimToTarget(self.MonsterAvatar.Anim, targetWidth, targetHeight)
      end
      self:applyCostumeToPreview()
    end
  end
end
function template_ClubboxPerfEditor.OptionsView:onPostInit()
  local TOGGLE_SCREEN_FX_KEY = "enableClubboxScreenFx"
  function self.ToggleScreenFx.OnToggled(toggle)
    if toggle:IsToggled() then
      print("Screen FX: On")
      game.getLocalSettings():set(TOGGLE_SCREEN_FX_KEY, "1")
    else
      print("Screen FX: Off")
      game.getLocalSettings():set(TOGGLE_SCREEN_FX_KEY, "0")
    end
    lua_sys.playSoundFx("audio/sfx/item_select.wav")
  end
  local toggleState = tonumber(game.getLocalSettings():get(TOGGLE_SCREEN_FX_KEY)) or 1
  self.ToggleScreenFx:SetToggled(toggleState == 1)
end
function template_ClubboxPerfEditor.OptionsView:setVisible(visible)
  if visible then
    self.BackButton:setVisible()
  else
    self.BackButton:setInvisible()
  end
  self.ToggleScreenFx:SetVisible(visible)
end
return template_ClubboxPerfEditor
