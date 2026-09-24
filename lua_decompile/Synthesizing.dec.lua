local MenuHelpers = include("MenuHelpers")
local MenuElementPositionOffsetTransition = include("MenuElementPositionOffsetTransition")
local Tweener = include("Tweener")
local SynthShader = include("ShaderSynthesizer")
local sort = include("sort")
local Synthesizing = {
  MonsterSelect = {
    Sprite = {},
    SpriteBg = {},
    MonsterImage = {}
  },
  GaugeAnimation = {
    Sprite = {}
  },
  GaugeArm = {
    Sprite = {}
  },
  CritterSlotHolder = {
    Frame = {}
  },
  MonsterSelectPopup = {},
  startSynth = false
}
Synthesizing.monsterSelectGraphics = {}
Synthesizing.critterSlotGraphics = {}
function Synthesizing:onPostInit()
  self.gaugeArmTween = nil
  self.gaugeArmAngle = 0
  self.gaugePercent = 0
  self.numCritterSelect = 0
  self.numMonsterSelect = 0
  self.numGenes = 0
  self.selectedMonsterId = 0
  self.startSynth = false
  self:ShowCritterSelectPopup(0)
  self:ShowMonsterSelectPopup(0)
  self.gaugePosLayerName = "synth gauge face"
  self.initGaugePos = self:getGaugeAnimPos()
  self:SetNumGenes(3)
  self:rotateGauge(self.gaugeArmAngle)
  self.showRetry = false
  self.fiveGeneCooldownActive = false
  self:setGaugeShader()
  table.insert(self.monsterSelectGraphics, self.MonsterSelect:C("Sprite"))
  table.insert(self.monsterSelectGraphics, self.MonsterSelect:C("SpriteBg"))
  table.insert(self.monsterSelectGraphics, self.GaugeAnimation:C("Sprite"))
  table.insert(self.monsterSelectGraphics, self.GaugeArm:C("Sprite"))
  table.insert(self.monsterSelectGraphics, self.CritterSlotHolder:C("Frame"))
end
function Synthesizing:setGaugeShader()
  local animUtil = game.AnimUtil(self.GaugeAnimation.Sprite)
  animUtil:setShader("synth gauge gradient later", SynthShader)
  animUtil:resetAnim()
  if SynthShader then
    SynthShader:getUniform("u_percent"):setFloat(0)
  end
end
function Synthesizing:getGaugeAnimPos()
  local animUtil = game.AnimUtil(self.GaugeAnimation.Sprite)
  local pos = animUtil:getPos(self.gaugePosLayerName)
  local animScale = self.GaugeAnimation.Sprite:scale()
  local px = pos.x * animScale.x
  local py = pos.y * animScale.y
  return lua_sys.Vector2(px, py)
end
function Synthesizing:onMonsterFilterSelected(buttonElement, filterName)
  if self.filterName ~= filterName then
    local numGenes = self:filterNameToNumGenes(filterName)
    if game.synthesizerMaxInstability() < self:minInstabilityRequried(numGenes) then
      game.displayNotification("NOTIFICATION_SYNTHESIZER_UPGRADE_REQUIRED")
    else
      self:SetNumGenes(numGenes)
    end
  end
end
function Synthesizing:minInstabilityRequried(numGenes)
  local attunerGenes = game.attunerGeneDatas()
  local instabilities = {}
  for i = 0, numGenes - 1 do
    instabilities[i] = attunerGenes[i].instability
  end
  sort.stable_sort(instabilities)
  local minInstability = 1
  for i = 1, #instabilities do
    minInstability = minInstability * instabilities[i]
  end
  return minInstability
end
function Synthesizing:deselectAllGeneFilters()
  self.MonsterTripleGeneFilter:deselect()
  self.MonsterQuadGeneFilter:deselect()
  self.MonsterFiveGeneFilter:deselect()
end
function Synthesizing:SetNumGenes(numGenes)
  local critterHolder = self.CritterSlots
  for i = 0, self.numGenes - 1 do
    local entry = critterHolder:E("critterSlotEntry" .. i)
    critterHolder:RemoveElement(entry)
  end
  if self:isMonsterRequired() then
    critterHolder:RemoveElement(critterHolder:E("plus"))
  end
  self.numGenes = numGenes
  self.numCritterSlots = numGenes
  local cost = game.synthersizerCost(self.numGenes)
  self.Cost:C("Text"):V("text"):SetString(tostring(cost))
  self.selectedMonsterId = 0
  self:populateCritterSlots(self.numCritterSlots)
  if self:isMonsterRequired() then
    self.MonsterSelect:C("Sprite"):V("visible"):SetInt(1)
    self.MonsterSelect:C("SpriteBg"):V("visible"):SetInt(1)
    self.MonsterSelect:V("disabled"):SetInt(0)
  else
    self.MonsterSelect:C("Sprite"):V("visible"):SetInt(0)
    self.MonsterSelect:C("SpriteBg"):V("visible"):SetInt(0)
    self.MonsterSelect:V("disabled"):SetInt(1)
  end
  self.MonsterSelect:C("MonsterImage"):V("visible"):SetInt(0)
  self.instability = 0
  self.instability = self:getInstability()
  self:updateGauge()
  self.filterName = self:numGenesToFilterName(numGenes)
  self:deselectAllGeneFilters()
  self:E(self.filterName):select()
  if numGenes == 5 and 0 < game.synthesisFiveGeneCooldownRemaining() then
    self.fiveGeneCooldownActive = true
    self:disableMonsterSelect(true)
  elseif self.fiveGeneCooldownActive then
    self.fiveGeneCooldownActive = false
    self:disableMonsterSelect(false)
  end
end
function Synthesizing:disableMonsterSelect(disable)
  local shader
  local cooldownText = self.FiveGeneCooldownText
  local cooldownTime = self.FiveGeneCooldownTime
  local timeLeft = game.synthesisFiveGeneCooldownRemaining()
  cooldownTime:C("Text"):V("text"):SetString(game.timeToString(timeLeft))
  if disable then
    shader = include("ShaderDesaturate")
    self.Description:C("Text"):V("visible"):SetInt(0)
    cooldownText:C("Text"):V("visible"):SetInt(1)
    cooldownTime:C("Text"):V("visible"):SetInt(1)
    local buttons = {}
    table.insert(buttons, cooldownText)
    table.insert(buttons, cooldownTime)
    MenuHelpers.CenterHorizontally(buttons)
    self.MonsterSelect:V("disabled"):SetInt(1)
    self.Tutorial:setInvisible()
  else
    self.Description:C("Text"):V("visible"):SetInt(1)
    cooldownText:C("Text"):V("visible"):SetInt(0)
    cooldownTime:C("Text"):V("visible"):SetInt(0)
    self.MonsterSelect:V("disabled"):SetInt(0)
    self.Tutorial:setVisible()
  end
  for i = 1, #self.monsterSelectGraphics do
    self.monsterSelectGraphics[i]:setShader(shader)
  end
  for i = 1, #self.critterSlotGraphics do
    self.critterSlotGraphics[i]:setShader(shader)
  end
  if disable then
    local colorizeShader = include("ShaderColorize")
    local animUtil = game.AnimUtil(self.GaugeAnimation.Sprite)
    animUtil:setShader("synth gauge gradient later", colorizeShader)
    animUtil:resetAnim()
    if colorizeShader then
      colorizeShader:getUniform("u_Factor"):setFloat(1)
      colorizeShader:getUniform("u_TargetColor"):setVec3(lua_sys.Vector3(0.5, 0.5, 0.5))
    end
  else
    self:setGaugeShader()
  end
end
function Synthesizing:numGenesToFilterName(numGenes)
  if numGenes == 3 then
    return "MonsterTripleGeneFilter"
  elseif numGenes == 4 then
    return "MonsterQuadGeneFilter"
  elseif numGenes == 5 then
    return "MonsterFiveGeneFilter"
  end
end
function Synthesizing:filterNameToNumGenes(filterName)
  if filterName == "MonsterTripleGeneFilter" then
    return 3
  elseif filterName == "MonsterQuadGeneFilter" then
    return 4
  elseif filterName == "MonsterFiveGeneFilter" then
    return 5
  end
end
function Synthesizing:selectedAllCritters()
  for i = 0, self.numCritterSlots - 1 do
    local entry = self.CritterSlots:E("critterSlotEntry" .. i)
    if entry.gene == "" then
      return false
    end
  end
  return true
end
function Synthesizing:updateGauge()
  local percent = 0
  if self:selectedAllCritters() == true then
    local base = game.synthesizerBasePercentage(self.numGenes)
    local stability = self.instability / game.synthesizerMaxInstability()
    local chance = base * (game.synthesizerChanceVar() - stability)
    percent = 1 - chance
  end
  percent = math.min(percent, 1)
  percent = math.max(percent, 0)
  local angle = percent * 180
  if SynthShader then
    SynthShader:getUniform("u_percent"):setFloat(percent)
  end
  local anim = self.GaugeAnimation.Sprite
  local warningThreshold = 0.9
  if warningThreshold <= self.gaugePercent and percent < warningThreshold then
    anim:GetVar("animation"):SetString("gauge_hot_outro")
  elseif warningThreshold > self.gaugePercent and percent >= warningThreshold then
    anim:GetVar("animation"):SetString("gauge_hot_intro")
    lua_sys.playSoundFx("audio/sfx/structure_synthesizer_meterfull.wav")
  end
  self:animateGauge(angle)
  self.gaugePercent = percent
  self:updateGaugeTutorial()
end
function Synthesizing:updateGaugeTutorial()
  local tutorialText = "SYNTHESIS_TUTORIAL_DEFAULT"
  local meebImage = "gfx/meeb_helper/helper_meeb_01"
  if self:selectedAllCritters() then
    tutorialText = "SYNTHESIS_TUTORIAL_HIGH_STABILITY"
    meebImage = "gfx/meeb_helper/helper_meeb_02"
    if self.gaugePercent >= 0.9 then
      tutorialText = "SYNTHESIS_TUTORIAL_LOW_STABILITY"
      meebImage = "gfx/meeb_helper/helper_meeb_04"
    elseif self.gaugePercent >= 0.6 then
      tutorialText = "SYNTHESIS_TUTORIAL_MEDIUM_STABILITY"
      meebImage = "gfx/meeb_helper/helper_meeb_03"
    end
  end
  self.Tutorial:setText(tutorialText)
  self.Tutorial:setMeebImage(meebImage)
end
function Synthesizing:getInstability()
  local instability = 0
  for i = 0, self.numCritterSlots - 1 do
    local entry = self.CritterSlots:E("critterSlotEntry" .. i)
    if entry.gene ~= "" then
      if instability == 0 then
        instability = 1
      end
      local data = game.attunerGeneData(entry.gene)
      instability = instability * data.instability
    end
  end
  return instability
end
function Synthesizing:animateGauge(angle)
  local minDuration = 0.25
  local maxDuration = 0.5
  local duration = math.abs(angle - self.gaugeArmAngle) / 180 * (maxDuration - minDuration) + minDuration
  self.gaugeArmTween = Tweener:new({
    delay = 0,
    duration = duration,
    initialValue = self.gaugeArmAngle,
    targetValue = angle,
    ease = lua_sys.Back_EaseIn,
    onUpdate = function(value)
      value = math.min(value, 190)
      value = math.max(value, -10)
      self.gaugeArmAngle = value
      self:rotateGauge(value)
    end
  })
  self.gaugeArmTween:activate()
end
function Synthesizing:rotateGauge(angle)
  local angleInRad = math.rad(angle - 90)
  local arm = self.GaugeArm
  local pivot = arm:absH() / 2 - 16 * game.hudScale()
  local pos = self:getGaugeAnimPos()
  pos.y = pos.y + self.GaugeAnimation:V("yOffset"):GetFloat()
  local offsetX = pos.x - self.initGaugePos.x
  local offsetY = pos.y - self.initGaugePos.y - 5 * game.hudScale()
  local origin = lua_sys.Vector2(0, -pivot)
  local cos = math.cos(angleInRad)
  local sin = math.sin(angleInRad)
  local xPosRot = origin.x * cos - origin.y * sin
  local yPosRot = origin.x * sin + origin.y * cos
  arm:setOrientationPosition(lua_sys.Vector2(xPosRot + offsetX, yPosRot + offsetY + arm:absH() / 2))
  self.GaugeArm:C("Sprite"):V("rotation"):SetFloat(angleInRad)
end
function Synthesizing:animateGaugeArm()
  local animUtil = game.AnimUtil(self.GaugeAnimation.Sprite)
  local angle = self.gaugeArmAngle + animUtil:getRotation("arm node")
  self:rotateGauge(angle)
end
function Synthesizing:MonsterSlotSelected(slot)
  self.selectedMonsterSlot = slot
  self.selectedMonsterSlotPreviousMonsterId = self.selectedMonsterSlot.monsterId
  self.selectedMonsterSlot.monsterId = 0
  self:ShowMonsterSelectPopup(1)
  self.MonsterSelectPopup:V("NumGenes"):SetInt(self.numGenes - 1)
end
function Synthesizing:ShowMonsterSelectPopup(show)
  if show == 1 then
    self.MonsterSelectPopup:V("Refresh"):SetInt(1)
    self.MonsterSelectPopup:Show()
  else
    self.MonsterSelectPopup:Hide()
  end
end
function Synthesizing:MonsterSelected(monsterId)
  print("monster selected ", monsterId)
  self.selectedMonsterId = monsterId
  self:SetMonsterSlotImage(monsterId)
  self:resetCritterSlots()
  local monsterType = game.monsterTypeId(monsterId)
  local genes = game.monsterTypeGenes(monsterType)
  for i = 1, self.numGenes do
    local slot = self.CritterSlots:E("critterSlotEntry" .. i - 1)
    slot.gene = genes:sub(i, i)
    if i == 5 then
      local monsters = game.creatableMonstersWithGenes(genes, 5)
      if 1 <= monsters:size() then
        local quintGenes = game.monsterTypeGenes(monsters[0])
        print("quintGenes " .. quintGenes)
        for j = 1, #quintGenes do
          local quintGene = quintGenes:sub(j, j)
          print("test " .. quintGene)
          if genes:find(quintGene) == nil then
            print("did not find " .. quintGene)
            slot.gene = quintGene
          end
        end
      end
      slot.num = game.numCrittersWithGene(slot.gene)
      slot.required = game.synthesizerGenesRequired(self.numGenes)
      if slot.num >= slot.required then
        slot:disableTouch()
      else
        slot:enableTouch()
      end
      slot:update()
    elseif i <= #genes then
      slot.num = game.numCrittersWithGene(slot.gene)
      slot.required = game.synthesizerGenesRequired(self.numGenes) - 1
      if slot.num >= slot.required then
        slot:disableTouch()
      else
        slot:enableTouch()
      end
      slot:update()
    else
      slot:enableSelection()
      slot:enableTouch()
    end
  end
  self.instability = self:getInstability()
  self:updateGauge()
end
function Synthesizing:SetMonsterSlotImage(monsterId)
  if monsterId == 0 then
    self.MonsterSelect.Sprite:V("visible"):SetInt(1)
    self.MonsterSelect.MonsterImage:V("visible"):SetInt(0)
  else
    self.MonsterSelect.MonsterImage:V("spriteName"):SetString("gfx/breeding/" .. game.getPortraitName(monsterId))
    self.MonsterSelect.MonsterImage:V("size"):SetFloat(0.75 * game.hudScale())
    self.MonsterSelect.MonsterImage:V("visible"):SetInt(1)
    self.MonsterSelect.Sprite:V("visible"):SetInt(0)
  end
end
function Synthesizing:populateCritterSlots(num)
  local critterHolder = self.CritterSlots
  buttons = {}
  local critterEntry
  self.critterSlotGraphics = {}
  for i = 0, num - 1 do
    critterEntry = menu:addTemplateElement("template_critter_slot_entry", "critterSlotEntry" .. i, critterHolder)
    critterEntry.gene = ""
    critterEntry:setParent(critterHolder)
    critterEntry:relativeTo(critterHolder)
    critterEntry:setOrientation(lua_sys.MenuOrientation(0, 0, -1, lua_sys.LEFT, lua_sys.VCENTER))
    critterEntry:setRelativeObjectAnchors(lua_sys.HCENTER, lua_sys.VCENTER)
    critterEntry:setOrientationPosition(lua_sys.Vector2(0, 0))
    critterEntry:setPositionBroadcast(false)
    critterEntry:init()
    critterHolder:setPositionBroadcast(true)
    if self:isMonsterRequired() then
      critterEntry:disableTouch()
      critterEntry:disableSelection()
      if i == num - 1 then
        local plus = menu:addTemplateElement("template_plus", "plus", critterHolder)
        plus:relativeTo(critterHolder)
        plus:setRelativeObjectAnchors(lua_sys.HCENTER, lua_sys.VCENTER)
        plus:setOrientation(lua_sys.MenuOrientation(0, 0, -1, lua_sys.LEFT, lua_sys.VCENTER))
        plus:V("Layer"):SetString("MidPopUps")
        plus:init()
        plus:setPositionBroadcast(true)
        table.insert(buttons, plus)
        table.insert(self.critterSlotGraphics, plus:C("Sprite"))
      end
    end
    table.insert(buttons, critterEntry)
    table.insert(self.critterSlotGraphics, critterEntry:C("Bg"))
  end
  MenuHelpers.CenterHorizontally(buttons)
end
function Synthesizing:CritterSlotSelected(slot)
  if slot.selectionDisabled then
    game.pushPopUp("popup_not_enough_critters")
    if game.getPopUp() == "popup_not_enough_critters" then
      game.topPopUp():V("gene"):SetString(slot.gene)
    end
  else
    self.selectedCritterSlot = slot
    self.selectedCritterSlotPreviousGene = self.selectedCritterSlot.gene
    self.selectedCritterSlot.gene = ""
    self:ShowCritterSelectPopup(1)
  end
end
function Synthesizing:ShowCritterSelectPopup(show)
  self.PopupFadedBG:C("Sprite"):V("visible"):SetInt(show)
  self.PopupFadedBG:C("Touch"):V("enabled"):SetInt(show)
  self.CritterTypePopup:C("Text"):V("visible"):SetInt(show)
  self.CritterTypePopup:C("Frame"):V("visible"):SetInt(show)
  self.CritterTypePopup:C("NoCritterText"):V("visible"):SetInt(0)
  if show == 0 then
    for i = 0, self.numCritterSelect - 1 do
      local entry = self.CritterTypePopup:E("critterEntry" .. i)
      entry:setInvisible()
      entry:disable()
    end
  else
    self:populateCritters()
    if self.numCritterSelect == 0 then
      self.CritterTypePopup:C("Text"):V("visible"):SetInt(0)
      self.CritterTypePopup:C("NoCritterText"):V("visible"):SetInt(1)
    end
  end
end
function Synthesizing:populateCritters()
  local critterHolder = self.CritterTypePopup
  local critterEntry
  for i = 0, self.numCritterSelect - 1 do
    local entry = critterHolder:E("critterEntry" .. i)
    critterHolder:RemoveElement(entry)
  end
  local availableGenes = self:getAvailableGenes()
  local num = #availableGenes
  self.numCritterSelect = num
  local buttons = {}
  for i = 0, num - 1 do
    critterEntry = menu:addTemplateElement("template_critter_synthesizing_entry", "critterEntry" .. i, critterHolder)
    critterEntry.gene = availableGenes[i + 1]
    local xPos = 0
    local yPos = 10 * game.hudScale()
    critterEntry:setParent(critterHolder)
    critterEntry:relativeTo(critterHolder)
    critterEntry:setOrientation(lua_sys.MenuOrientation(xPos, yPos, -1, lua_sys.LEFT, lua_sys.VCENTER))
    critterEntry:setRelativeObjectAnchors(lua_sys.HCENTER, lua_sys.VCENTER)
    critterEntry:setOrientationPosition(lua_sys.Vector2(xPos, yPos))
    critterEntry:V("Layer"):SetString("MidFrontPopUps")
    critterEntry:setPositionBroadcast(false)
    critterEntry:init()
    critterHolder:setPositionBroadcast(true)
    if i > 0 then
      table.insert(buttons, MenuHelpers.CreateSpacer(5 * game.hudScale(), 0))
    end
    table.insert(buttons, critterEntry)
  end
  MenuHelpers.CenterHorizontally(buttons)
end
function Synthesizing:getAvailableGenes()
  local attunerGenes = game.attunerGenes()
  local usableGenes = {}
  local index = 1
  for i = 0, attunerGenes:size() - 1 do
    if self:canUseGene(attunerGenes[i]) then
      usableGenes[index] = attunerGenes[i]
      index = index + 1
    end
  end
  return usableGenes
end
function Synthesizing:canUseGene(gene)
  if game.numCrittersWithGene(gene) == 0 then
    return false
  end
  local slotGenes = self:getSlotGenes()
  if string.find(slotGenes, gene) then
    return false
  end
  local matchAllGenes = false
  if self.selectedMonsterId ~= 0 then
    local monsterType = game.monsterTypeId(self.selectedMonsterId)
    local mosnterGenes = game.monsterTypeGenes(monsterType)
    if string.find(mosnterGenes, gene) then
      return true
    end
    for i = 1, #slotGenes do
      if string.find(mosnterGenes, slotGenes:sub(i, i)) == nil then
        return false
      end
    end
    matchAllGenes = true
  end
  local genes = slotGenes .. gene
  local result = game.canCreateMonsterWithGenes(genes, self.numGenes, matchAllGenes)
  return result
end
function Synthesizing:getSlotGenes()
  local genes = ""
  for i = 0, self.numCritterSlots - 1 do
    local entry = self.CritterSlots:E("critterSlotEntry" .. i)
    genes = genes .. entry.gene
  end
  return genes
end
function Synthesizing:resetCritterSlots()
  for i = 0, self.numCritterSlots - 1 do
    local entry = self.CritterSlots:E("critterSlotEntry" .. i)
    entry.gene = ""
    entry:update()
  end
end
function Synthesizing:CritterSelected(gene)
  if gene ~= "" then
    local instability = self:getInstability() * game.attunerGeneData(gene).instability
    if instability > game.synthesizerMaxInstability() then
      game.displayNotification("NOTIFICATION_CRITTER_MAKES_UNSTABLE_COMBO")
    else
      self.selectedCritterSlot.gene = gene
      self.selectedCritterSlot.num = game.numCrittersWithGene(gene)
      self.selectedCritterSlot.required = game.synthesizerGenesRequired(self.numGenes)
      self.selectedCritterSlot:update()
      self:ShowCritterSelectPopup(0)
      lua_sys.playSoundFx("audio/sfx/structure_synthesizer_addcritter.wav")
      self.instability = self:getInstability()
      self:updateGauge()
    end
  else
    self.selectedCritterSlot.gene = self.selectedCritterSlotPreviousGene
  end
end
function Synthesizing:StartSynthesizing()
  local cost = game.synthersizerCost(self.numGenes)
  if self:selectedAllCritters() == false then
    if self:isMonsterRequired() then
      game.displayNotification("NOTIFICATION_SYNTHESIZER_SELECT_MONSTER_AND_CRITTERS")
    else
      local text = LOC("NOTIFICATION_SYNTHESIZER_SELECT_CRITTERS")
      text = text:gsub("%${NUM}", self.numGenes)
      game.displayNotification(text)
    end
  elseif game.clearPurchase(game.CurrencyType_Shards, cost, game.PurchaseType_START_SYNTHESIS, self.numGenes) then
    if self:hasRequiredCritters() == false then
      game.displayNotification("NOTIFICATION_SYNTHESIZER_NOT_ENOUGH_CRITTERS")
    else
      self.startSynth = true
      game.popPopUp()
    end
  end
end
function Synthesizing:getGenesForSynthesis()
  local genes = ""
  local slotGenes = self:getSlotGenes()
  if self.selectedMonsterId ~= 0 then
    local monsterType = game.monsterTypeId(self.selectedMonsterId)
    local mosnterGenes = game.monsterTypeGenes(monsterType)
    for i = 1, #slotGenes do
      if string.find(mosnterGenes, slotGenes:sub(i, i)) == nil then
        genes = slotGenes:sub(i, i)
      end
    end
  else
    genes = slotGenes
  end
  return genes
end
function Synthesizing:isMonsterRequired()
  return self.numGenes > 3
end
function Synthesizing:hasRequiredCritters()
  local genes = self:getSlotGenes()
  local monsterType = game.monsterTypeId(self.selectedMonsterId)
  local playerMonsterGenes = game.monsterTypeGenes(monsterType)
  for i = 1, #genes do
    local gene = genes:sub(i, i)
    local num = game.numCrittersWithGene(gene)
    local required = game.synthesizerGenesRequired(self.numGenes)
    if string.find(playerMonsterGenes, gene) then
      required = required - 1
    end
    if num < required then
      return false
    end
  end
  return true
end
function Synthesizing:ShowRetry()
  self.showRetry = true
  manager:setContext("BLANK")
  self:Hide()
end
function Synthesizing:onInit()
  MenuElementPositionOffsetTransition.OnInit(self.bg, {
    startY = lua_sys.screenHeight() * 2,
    endY = -6 * game.hudScale(),
    duration = 0.66
  })
  self:Show()
end
function Synthesizing:onTick(dt)
  local options = {
    ease = lua_sys.Quadratic_EaseIn,
    onDoneHide = function(e)
      e:root():popPopUp()
      if self.startSynth == true then
        local genes = self:getGenesForSynthesis()
        game.startSynthesizing(genes, self.selectedMonsterId)
      end
      if self.showRetry then
        manager:setContext("RETRY_SYNTHESIS")
      end
    end
  }
  MenuElementPositionOffsetTransition.OnTick(self.bg, dt, options)
  if self.gaugeArmTween ~= nil then
    self.gaugeArmTween:Tick(dt)
  end
  if self.fiveGeneCooldownActive and game.synthesisFiveGeneCooldownRemaining() == 0 then
    self.fiveGeneCooldownActive = false
    self:disableMonsterSelect(false)
  end
  self:animateGaugeArm()
end
function Synthesizing:Show()
  MenuElementPositionOffsetTransition.Show(self.bg)
  lua_sys.playSoundFx("audio/sfx/menu_slide.wav")
end
function Synthesizing:Hide()
  MenuElementPositionOffsetTransition.Hide(self.bg)
  self.Fade:Hide()
  lua_sys.playSoundFx("audio/sfx/menu_slide.wav")
end
function Synthesizing:queuePop()
  self:Hide()
end
return Synthesizing
