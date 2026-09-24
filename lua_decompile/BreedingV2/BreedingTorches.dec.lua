local MenuHelpers = include("MenuHelpers")
local BreedingTorches = {
  BG = {},
  Touch = {}
}
function BreedingTorches:SetupTorches(containerElement)
  if game.playerLevel() < game.torchUnlockLevel() then
    local currentSize = containerElement.BG:size()
    containerElement.BG:setSize(lua_sys.Vector2(currentSize.x, 8 * BreedingMenuScaleX()))
    containerElement.BG:GetVar("visible"):SetInt(0)
    containerElement.Touch:GetVar("enabled"):SetInt(0)
    return
  end
  local torches = {}
  local maxTorches = game.StoreContext_getMaxNumTorches()
  local numPurchasedTorches = game.numTorchesTotal()
  local numLitTorches = game.numLitTorches()
  local numPermaLitTorches = game.numPermaLitTorches()
  for i = 1, maxTorches do
    if i > 1 then
      table.insert(torches, MenuHelpers.CreateSpacer(self:templateVars().torchSpacing, 0))
    end
    local torch = menu:addTemplateElement("template_spritesheet", "torch_" .. i, containerElement)
    torch:relativeTo(containerElement)
    torch:setOrientation(lua_sys.MenuOrientation(0, 0, -2, lua_sys.LEFT, lua_sys.VCENTER))
    torch:setRelativeObjectAnchors(lua_sys.HCENTER, lua_sys.VCENTER)
    local spriteName = "torch_icon_off"
    if i <= numPermaLitTorches then
      spriteName = "torch_icon_infinite_small"
    elseif i <= numLitTorches then
      spriteName = "torch_icon"
    elseif i <= numPurchasedTorches then
      spriteName = "torch_icon_grey"
    end
    torch.Sprite:GetVar("spriteName"):SetString(spriteName)
    torch.Sprite:GetVar("sheetName"):SetString("xml_resources/breeding_menu.xml")
    torch.Sprite:GetVar("size"):SetFloat(self:templateVars().torchScale)
    torch.Sprite:GetVar("layer"):SetString("MidPopUps")
    torch:setPositionBroadcast(true)
    table.insert(torches, torch)
  end
  MenuHelpers.CenterHorizontally(torches)
  return torches
end
function BreedingTorches:onPostInit()
  self.torches = self:SetupTorches(self)
end
local createTooltip = function(name, parentElement, tooltipText, onDoneHide)
  local tooltip = menu:addTemplateElement("template_tooltip", name, parentElement)
  tooltip:relativeTo(parentElement)
  tooltip:setOrientation(lua_sys.MenuOrientation(0, 0, -1, lua_sys.HCENTER, lua_sys.BOTTOM))
  tooltip:setRelativeObjectAnchors(lua_sys.HCENTER, lua_sys.TOP)
  tooltip:init()
  tooltip:setPositionBroadcast(true)
  tooltip.Text:GetVar("text"):SetString(tooltipText)
  tooltip.Sprite:setSize(lua_sys.Vector2(tooltip.Text:absW() + 8 * BreedingMenuScaleX(), tooltip.Text:absH() + 8 * game.menuScaleY()))
  function tooltip.onDoneHide()
    parentElement:RemoveElement(tooltip)
    if onDoneHide then
      onDoneHide()
    end
  end
  return tooltip
end
function BreedingTorches.Touch:onTouchDown(element)
  local torchTooltipText = LOC("BREEDING_TORCH_TOOLTIP")
  if not element.tooltip then
    element.tooltip = createTooltip("tooltip_" .. element:name(), element, torchTooltipText, function()
      element.tooltip = nil
    end)
  end
  element.tooltip:Show()
end
function BreedingTorches.Touch:onTouchUp(element)
  if element.tooltip then
    element.tooltip:Hide()
  end
end
function BreedingTorches.Touch:onTouchRelease(element)
  if element.tooltip then
    element.tooltip:Hide()
  end
end
return BreedingTorches
