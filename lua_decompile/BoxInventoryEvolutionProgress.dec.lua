local BoxInventoryEvolutionProgress = {
  Sprite = {},
  Touch = {}
}
local evoData = {}
table.insert(evoData, {entityId = 1525, icon = "gene_plant"})
table.insert(evoData, {entityId = 1526, icon = "gene_cold"})
table.insert(evoData, {entityId = 1527, icon = "gene_air"})
table.insert(evoData, {entityId = 1528, icon = "gene_water"})
table.insert(evoData, {entityId = 1529, icon = "gene_earth"})
function BoxInventoryEvolutionProgress:onInit()
  self.entityId = game.selectedEntityId()
  self.IsVisible = false
  for _, value in ipairs(evoData) do
    if value.entityId == self.entityId then
      self.IsVisible = true
      break
    end
  end
  if self.IsVisible then
    self:Populate()
  else
    self:Hide()
  end
end
function BoxInventoryEvolutionProgress:onPostInit()
end
function BoxInventoryEvolutionProgress:Hide()
  self.Sprite("visible"):SetInt(0)
  self.Touch("active"):SetInt(0)
end
function BoxInventoryEvolutionProgress:Populate()
  local function createFunc(idx, entryName)
    local entry = menu:addTemplateElement("template_box_inventory_evolution_progress_entry", entryName, self)
    entry.icon = evoData[idx].icon
    return entry
  end
  local monsterData = game.getMonsterByEntityId(self.entityId)
  local offset = 28 * game.hudScale()
  for i = 1, #evoData do
    local entry = createFunc(i, "entry" .. i - 1)
    entry:setOrientation(lua_sys.MenuOrientation(0, offset, 0, lua_sys.HCENTER, lua_sys.TOP))
    entry:setRelativeObjectAnchors(lua_sys.HCENTER, lua_sys.TOP)
    entry:init()
    entry:setPositionBroadcast(true)
    entry:postInit()
    local evolvesInto = monsterData:evolvesInto()
    if game.selectedObjectIsActiveBoxMonster() then
      if self.entityId >= evoData[i].entityId then
        entry:setCompleted()
      elseif evolvesInto == evoData[i].entityId then
        entry:setCurrent()
      else
        entry:setDisabled()
      end
    elseif evoData[i].entityId == 1525 then
      entry:setCurrent()
    else
      entry:setDisabled()
    end
    offset = offset + entry:absH()
  end
  self:setPositionBroadcast(true)
end
return BoxInventoryEvolutionProgress
