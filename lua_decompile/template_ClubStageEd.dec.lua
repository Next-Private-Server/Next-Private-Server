local template_ClubStageEd = {
  maxNumProps = 3,
  StageEditorBg0 = {},
  StageEditorBg1 = {},
  StageEditorBg2 = {},
  CloseButton = {
    Touch = {}
  }
}
function template_ClubStageEd:onInit()
  self("selectedProp"):SetInt(0)
  for buttonId = 0, self.maxNumProps - 1 do
    local propControl = self:GetElement("StageEditorBg" .. buttonId)
    if propControl ~= nil then
      propControl.buttonId = buttonId
      local icon = game.getStageEdButtonIcon(buttonId)
      if icon ~= "" then
        propControl.Icon("spriteName"):SetString(icon)
        propControl.Icon("sheetName"):SetString("xml_resources/" .. game.getStageEdButtonSheet(buttonId))
      else
        propControl:SetInvisible()
      end
      propControl.activeVariantInd = game.getStageEditorActiveVariant(buttonId)
    end
  end
  local propControl0 = self:GetElement("StageEditorBg0")
  local propControl1 = self:GetElement("StageEditorBg1")
  self:setSize(lua_sys.Vector2(propControl0:size().x * 3 + propControl1("xOffset"):GetInt() * 2, propControl0:size().y))
end
function template_ClubStageEd:disablePropSwitching()
end
function template_ClubStageEd:enablePropSwitching()
end
function template_ClubStageEd:closeCustomizeMenu()
  self:parent():closeCustomizeMenu()
end
function template_ClubStageEd:SetupNotifications(newUnlockedProps)
  for buttonId = 0, self.maxNumProps - 1 do
    local propControl = self:GetElement("StageEditorBg" .. buttonId)
    if propControl then
      local icon = game.getStageEdButtonIcon(buttonId)
      for k, v in ipairs(newUnlockedProps) do
        if v.customizeIcon == icon then
          propControl.Alert:StartAlert()
          break
        end
      end
    end
  end
end
return template_ClubStageEd
