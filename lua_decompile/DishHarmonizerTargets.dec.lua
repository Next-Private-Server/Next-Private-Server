local MenuHelpers = include("MenuHelpers")
local MenuElementPositionOffsetTransition = include("MenuElementPositionOffsetTransition")
local DishHarmonizerTargets = {
  bg = {},
  TwoGeneTargets = {},
  ThreeGeneTargets = {},
  TargetMeter2Gene = {},
  TargetMeter3Gene = {},
  TargetMeterPrimordial = {}
}
function DishHarmonizerTargets:onInit()
  self:SetupGenericListener(game.engineReceiver(), "game::msg::MsgConfirmationSubmission", "gotMsgConfirmationSubmission")
  self:SetupGenericListener(game.engineReceiver(), "game::msg::MsgDishHarmonizerDataUpdated", "gotMsgDishHarmonizerDataUpdated")
  MenuElementPositionOffsetTransition.OnInit(self:E("bg"), {
    startY = lua_sys.screenHeight() * 2,
    endY = -15 * game.menuScaleY(),
    duration = 0.66
  })
end
function DishHarmonizerTargets:onPostInit()
  self:populateGeneTargets(self.TwoGeneTargets, 2)
  self:populateGeneTargets(self.ThreeGeneTargets, 3)
  self:updateMeter(2)
  self:updateMeter(3)
  self:updateMeter(4)
  local hidePrimordialMeter = false
  local dishHarmonizer = game.SelectedObject()
  local primordialReqs = dishHarmonizer:primordialRequirements()
  for i = 0, primordialReqs:size() - 1 do
    if game.hasOrHasEverHadMonsterOnActiveIsland(primordialReqs[i]) == false then
      hidePrimordialMeter = true
      break
    end
  end
  local primordialId = dishHarmonizer:getPrimordial(game.MonsterRarity_Common)
  if game.player():getActiveIsland():monsterTypeCount(primordialId) ~= 0 then
    hidePrimordialMeter = true
  end
  local buyback = game.player():getActiveIsland():getBuyback()
  if buyback and buyback.entityId == game.monsterTypeEntityId(primordialId) then
    hidePrimordialMeter = true
  end
  local idx = 0
  local nursery = game.FindNursery(idx)
  while nursery do
    local monsterId = nursery:getMonsterInEgg()
    if monsterId == primordialId then
      hidePrimordialMeter = true
      break
    end
    idx = idx + 1
    nursery = game.FindNursery(idx)
  end
  if hidePrimordialMeter then
    self.TargetMeterPrimordial:hide()
  end
  self:Show()
end
function DishHarmonizerTargets:onTick(dt)
  local options = {
    ease = lua_sys.Quadratic_EaseIn,
    onDoneHide = function(e)
      e:root():popPopUp()
      manager:setContext("DISH_HARMONIZER_MENU")
    end
  }
  MenuElementPositionOffsetTransition.OnTick(self:E("bg"), dt, options)
end
function DishHarmonizerTargets:Show()
  MenuElementPositionOffsetTransition.Show(self:E("bg"))
  lua_sys.playSoundFx("audio/sfx/structure_dishharmonizer_menu_open.ogg")
end
function DishHarmonizerTargets:Hide()
  MenuElementPositionOffsetTransition.Hide(self:E("bg"))
  self:E("Fade"):DoStoredScript("Hide")
  lua_sys.playSoundFx("audio/sfx/menu_slide.wav")
end
function DishHarmonizerTargets:queuePop()
  self:Hide()
end
function DishHarmonizerTargets:populateGeneTargets(root, numGenes)
  local dishHarmonizer = game.SelectedObject()
  local monsters = dishHarmonizer:monsterTargets(numGenes)
  local target = dishHarmonizer:getMonsterTarget(numGenes)
  local entries = {}
  table.insert(entries, MenuHelpers.CreateSpacer(5 * game.menuScaleX(), 0))
  for i = 0, monsters:size() - 1 do
    local entry = menu:addTemplateElementEx("template_dish_harmonizer_target_entry", "target" .. i + 1, root)
    table.insert(entries, entry)
    entry:relativeTo(root)
    entry:setRelativeObjectAnchors(lua_sys.HCENTER, lua_sys.VCENTER)
    entry:setOrientation(lua_sys.MenuOrientation(0, 0, -1, lua_sys.LEFT, lua_sys.VCENTER))
    entry:V("MonsterID"):SetInt(monsters[i])
    entry:V("NumGenes"):SetInt(numGenes)
    entry:init()
    entry:setPositionBroadcast(true)
    entry:postInit()
    if target == monsters[i] then
      entry:select()
    end
    if i < monsters:size() - 1 then
      table.insert(entries, MenuHelpers.CreateSpacer(3 * game.menuScaleX(), 0))
    end
  end
  MenuHelpers.CenterHorizontally(entries)
end
function DishHarmonizerTargets:TargetSelected(element)
  self.selectedTarget = element
  local dishHarmonizer = game.SelectedObject()
  local numGenes = element:V("NumGenes"):GetInt()
  if dishHarmonizer:hasMonsterTarget(numGenes) and dishHarmonizer:getMonsterTargetPercentage(numGenes) > 0 then
    game.displayConfirmation("CHANGE_GENE_TARGET", "CONFIRM_CHANGE_DISH_HARMONIZER_TARGET")
  else
    self:updateTarget(self.selectedTarget)
  end
end
function DishHarmonizerTargets:gotMsgConfirmationSubmission(msg)
  if msg.messageID == "CHANGE_GENE_TARGET" and msg.choice == true then
    self:updateTarget(self.selectedTarget)
  end
end
function DishHarmonizerTargets:updateTarget(element)
  local dishHarmonizer = game.SelectedObject()
  local numGenes = element:V("NumGenes"):GetInt()
  if element.isSelected then
    element:unSelect()
    dishHarmonizer:updateTarget(numGenes, 0)
  else
    if numGenes == 2 then
      for i = 1, 4 do
        local entry = self.TwoGeneTargets:E("target" .. i)
        entry:unSelect()
      end
    else
      for i = 1, 6 do
        local entry = self.ThreeGeneTargets:E("target" .. i)
        entry:unSelect()
      end
    end
    element:select()
    dishHarmonizer:updateTarget(numGenes, element:V("MonsterID"):GetInt())
  end
  lua_sys.playSoundFx("audio/sfx/structure_dishharmonizer_menu_selectmonster.ogg")
end
function DishHarmonizerTargets:updateMeter(numGenes)
  local dishHarmonizer = game.SelectedObject()
  if numGenes == 2 then
    self.TargetMeter2Gene:setFill(dishHarmonizer:getMonsterTargetPercentage(numGenes))
  elseif numGenes == 3 then
    self.TargetMeter3Gene:setFill(dishHarmonizer:getMonsterTargetPercentage(numGenes))
  else
    self.TargetMeterPrimordial:setFill(dishHarmonizer:getMonsterTargetPercentage(numGenes))
  end
end
function DishHarmonizerTargets:gotMsgDishHarmonizerDataUpdated(msg)
  local numGenes = self.selectedTarget:V("NumGenes"):GetInt()
  self:updateMeter(numGenes)
end
return DishHarmonizerTargets
