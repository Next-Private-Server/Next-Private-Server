local MenuHelpers = require("MenuHelpers")
local info = {
  gene_air = {
    sprite = "gene_air",
    sheet = "xml_resources/hud02.xml"
  },
  gene_anniversary = {
    sprite = "gene_anniversary",
    sheet = "xml_resources/hud02.xml"
  },
  gene_arbour = {
    sprite = "gene_arbour",
    sheet = "xml_resources/hud02.xml"
  },
  gene_backtoschool = {
    sprite = "gene_backtoschool",
    sheet = "xml_resources/hud02.xml"
  },
  gene_bone = {
    sprite = "gene_bone",
    sheet = "xml_resources/hud02.xml"
  },
  gene_celestial = {
    sprite = "gene_celestial",
    sheet = "xml_resources/hud02.xml"
  },
  gene_cold = {
    sprite = "gene_cold",
    sheet = "xml_resources/hud02.xml"
  },
  gene_creation = {
    sprite = "gene_creation",
    sheet = "xml_resources/hud02.xml"
  },
  gene_crystal = {
    sprite = "gene_crystal",
    sheet = "xml_resources/hud02.xml"
  },
  gene_day_of_the_dead = {
    sprite = "gene_day_of_the_dead",
    sheet = "xml_resources/hud02.xml"
  },
  gene_dipster = {
    sprite = "gene_dipster",
    sheet = "xml_resources/hud02.xml"
  },
  gene_dream = {
    sprite = "gene_dream",
    sheet = "xml_resources/hud02.xml"
  },
  gene_earth = {
    sprite = "gene_earth",
    sheet = "xml_resources/hud02.xml"
  },
  gene_easter = {
    sprite = "gene_easter",
    sheet = "xml_resources/hud02.xml"
  },
  gene_ecto_plasma = {
    sprite = "gene_ecto_plasma",
    sheet = "xml_resources/hud02.xml"
  },
  gene_electricity = {
    sprite = "gene_electricity",
    sheet = "xml_resources/hud02.xml"
  },
  gene_explore = {
    sprite = "gene_explore",
    sheet = "xml_resources/hud02.xml"
  },
  gene_fairy = {
    sprite = "gene_fairy",
    sheet = "xml_resources/hud02.xml"
  },
  gene_fire = {
    sprite = "gene_fire",
    sheet = "xml_resources/hud02.xml"
  },
  gene_fireworks = {
    sprite = "gene_fireworks",
    sheet = "xml_resources/hud02.xml"
  },
  gene_halloween = {
    sprite = "gene_halloween",
    sheet = "xml_resources/hud02.xml"
  },
  gene_legendary = {
    sprite = "gene_legendary",
    sheet = "xml_resources/hud02.xml"
  },
  gene_light = {
    sprite = "gene_light",
    sheet = "xml_resources/hud02.xml"
  },
  gene_mech = {
    sprite = "gene_mech",
    sheet = "xml_resources/hud02.xml"
  },
  gene_mythical = {
    sprite = "gene_mythical",
    sheet = "xml_resources/hud02.xml"
  },
  gene_newyears = {
    sprite = "gene_newyears",
    sheet = "xml_resources/hud02.xml"
  },
  gene_plant = {
    sprite = "gene_plant",
    sheet = "xml_resources/hud02.xml"
  },
  gene_psychic = {
    sprite = "gene_psychic",
    sheet = "xml_resources/hud02.xml"
  },
  gene_shadow = {
    sprite = "gene_shadow",
    sheet = "xml_resources/hud02.xml"
  },
  gene_stpatrick = {
    sprite = "gene_stpatrick",
    sheet = "xml_resources/hud02.xml"
  },
  gene_summer = {
    sprite = "gene_summer",
    sheet = "xml_resources/hud02.xml"
  },
  gene_thanksgiving = {
    sprite = "gene_thanksgiving",
    sheet = "xml_resources/hud02.xml"
  },
  gene_toxic = {
    sprite = "gene_toxic",
    sheet = "xml_resources/hud02.xml"
  },
  gene_valentines = {
    sprite = "gene_valentines",
    sheet = "xml_resources/hud02.xml"
  },
  gene_water = {
    sprite = "gene_water",
    sheet = "xml_resources/hud02.xml"
  },
  gene_xmas = {
    sprite = "gene_xmas",
    sheet = "xml_resources/hud02.xml"
  },
  gene_titansoul = {
    sprite = "gene_titansoul",
    sheet = "xml_resources/hud02.xml"
  },
  gene_control = {
    sprite = "gene_control",
    sheet = "xml_resources/hud02.xml"
  },
  gene_hoax = {
    sprite = "gene_hoax",
    sheet = "xml_resources/hud02.xml"
  },
  gene_primordial_plant = {
    sprite = "gene_primordial_plant",
    sheet = "xml_resources/hud02.xml"
  },
  gene_primordial_air = {
    sprite = "gene_primordial_air",
    sheet = "xml_resources/hud02.xml"
  },
  gene_ruin = {
    sprite = "gene_ruin",
    sheet = "xml_resources/hud02.xml"
  },
  gene_abyss = {
    sprite = "gene_abyss",
    sheet = "xml_resources/hud02.xml"
  },
  gene_primordial_cold = {
    sprite = "gene_primordial_cold",
    sheet = "xml_resources/hud02.xml"
  },
  gene_primordial_water = {
    sprite = "gene_primordial_water",
    sheet = "xml_resources/hud02.xml"
  }
}
local monsterGenes0 = {}
monsterGenes0[815] = "gene_titansoul"
monsterGenes0[856] = "gene_primordial_plant"
monsterGenes0[883] = "gene_titansoul"
monsterGenes0[890] = "gene_primordial_air"
monsterGenes0[946] = "gene_primordial_cold"
monsterGenes0[966] = "gene_titansoul"
monsterGenes0[984] = "gene_primordial_water"
local paironormalGeneMap = {}
paironormalGeneMap["1"] = "gene_control"
paironormalGeneMap["2"] = "gene_hoax"
paironormalGeneMap["3"] = "gene_ruin"
paironormalGeneMap["4"] = "gene_abyss"
local function getGeneInfo(gene)
  return info[gene] or {
    sprite = "",
    sheet = "xml_resources/hud02.xml"
  }
end
local function getZeroGene(monsterId)
  local seasonalSigil = include("Seasons").GetSeasonalSigilFromMonster(monsterId)
  if #seasonalSigil > 0 then
    return seasonalSigil
  end
  return monsterGenes0[monsterId]
end
local function getSingleGeneInfo(gene)
  local fullGene = game.geneFilename(gene)
  return getGeneInfo(fullGene)
end
local function getGeneInfos(geneString)
  local infos = {}
  for i = 1, #geneString do
    local gene = geneString:sub(i, i)
    local fullGene = game.geneFilename(gene)
    table.insert(infos, getGeneInfo(fullGene))
  end
  return infos
end
local getFullGenes = function(geneString)
  local fullGenes = {}
  for i = 1, #geneString do
    local gene = geneString:sub(i, i)
    local fullGene = game.geneFilename(gene)
    if fullGene and #fullGene > 0 then
      table.insert(fullGenes, fullGene)
    end
  end
  return fullGenes
end
local function getPaironormalGeneInfos(monsterData)
  local infos = {}
  local genes = monsterData:sortedGenes()
  if #genes > 0 then
    for i = 1, #genes do
      local gene = genes:sub(i, i)
      local fullGene = paironormalGeneMap[gene]
      table.insert(infos, getGeneInfo(fullGene))
    end
  else
    local fullGene = getZeroGene(monsterData:monsterId())
    if fullGene and #fullGene > 0 then
      table.insert(infos, getGeneInfo(fullGene))
    end
  end
  return infos
end
local function getPaironormalFullGenes(monsterData)
  local fullGenes = {}
  local geneLetters = monsterData:sortedGenes()
  if #geneLetters > 0 then
    for i = 1, #geneLetters do
      local gene = geneLetters:sub(i, i)
      local fullGene = paironormalGeneMap[gene]
      table.insert(fullGenes, fullGene)
    end
  else
    local fullGene = getZeroGene(monsterData:monsterId())
    if fullGene and #fullGene > 0 then
      table.insert(fullGenes, fullGene)
    end
  end
  return fullGenes
end
local function getGeneInfosForMonsterData(monsterData)
  if monsterData:isPaironormal() then
    return getPaironormalGeneInfos(monsterData)
  end
  local infos = {}
  local genes = monsterData:sortedGenes()
  if #genes > 0 then
    infos = getGeneInfos(genes)
  else
    local fullGene = getZeroGene(monsterData:monsterId())
    if fullGene and #fullGene > 0 then
      table.insert(infos, getGeneInfo(fullGene))
    end
  end
  return infos
end
local function getGeneInfosForUserMonsterId(monsterId, overrideReattunedGenes)
  local monster = game.GetMonster(monsterId)
  local monsterData = monster:data()
  if monsterData:isPaironormal() then
    return getPaironormalGeneInfos(monsterData)
  end
  local infos = {}
  local genes = monsterData:sortedGenes()
  if #genes > 0 then
    infos = getGeneInfos(genes)
    for i = 1, #infos do
      if overrideReattunedGenes ~= nil then
        if string.find(overrideReattunedGenes, genes:sub(i, i)) then
          infos[i].reattuned = true
        end
      elseif string.find(monster:reattunedGenes(), genes:sub(i, i)) then
        infos[i].reattuned = true
      end
      infos[i].gene = genes:sub(i, i)
    end
  else
    local fullGene = getZeroGene(monsterId)
    if fullGene and #fullGene > 0 then
      table.insert(infos, getGeneInfo(fullGene))
    end
  end
  return infos
end
local function getGeneInfosForMonsterId(monsterId)
  local monsterData = game.getMonsterData(monsterId)
  return getGeneInfosForMonsterData(monsterData)
end
local function getGeneInfosForMonster(monster)
  local monsterData = monster:data()
  return getGeneInfosForMonsterData(monsterData)
end
local function getFullGenesForMonsterData(monsterData)
  if monsterData:isPaironormal() then
    return getPaironormalFullGenes(monsterData)
  end
  local fullGenes = {}
  local geneLetters = monsterData:sortedGenes()
  if #geneLetters > 0 then
    fullGenes = getFullGenes(geneLetters)
  else
    local fullGene = getZeroGene(monsterData:monsterId())
    if fullGene and #fullGene > 0 then
      table.insert(fullGenes, fullGene)
    end
  end
  return fullGenes
end
local function getFullGenesForMonsterId(monsterId)
  local monsterData = game.getMonsterData(monsterId)
  return getFullGenesForMonsterData(monsterData)
end
local function getFullGenesForMonster(monster)
  local monsterData = monster:data()
  return getFullGenesForMonsterData(monsterData)
end
local function _setup(parent, infos, options)
  options = options or {}
  local size = options.size or 0.5 * game.hudScale()
  local spacing = options.spacing or 0
  local layer = options.layer or "HUD"
  local useFlags = options.useFlags or 0
  local prefix = options.prefix or "entry"
  local priority = options.priority or 0
  local hAnchor = options.hAnchor or lua_sys.HCENTER
  local vAnchor = options.vAnchor or lua_sys.VCENTER
  local offsetY = options.offsetY or 0
  if #infos > 4 then
    size = size * 0.8
  end
  local items = {}
  local width = 0
  local height = 0
  local function createGene(geneInfo, i)
    local template = "template_gene"
    if geneInfo.reattuned then
      template = "template_reattuned_gene"
    end
    local item = menu:addTemplateElement(template, prefix .. i, parent)
    item("SpriteName"):SetString(geneInfo.sprite)
    if useFlags == 1 then
      item("SheetName"):SetString("xml_resources/flags01.xml")
    else
      item("SheetName"):SetString(geneInfo.sheet)
    end
    item("Size"):SetFloat(size)
    item("Layer"):SetString(layer)
    if geneInfo.reattuned then
      item("Gene"):SetString(geneInfo.gene)
      item("Reattuned"):SetInt(1)
    else
      item("Reattuned"):SetInt(0)
    end
    if i > 0 then
      width = width + spacing
      table.insert(items, MenuHelpers.CreateSpacer(spacing, 0))
    end
    item:setRelativeObjectAnchors(hAnchor, vAnchor)
    item:setOrientation(lua_sys.MenuOrientation(0, offsetY, priority, lua_sys.LEFT, lua_sys.VCENTER))
    item:init()
    item:setPositionBroadcast(true)
    item:postInit()
    width = width + item:absW()
    local itemHeight = item:absH()
    if itemHeight > height then
      height = itemHeight
    end
    table.insert(items, item)
  end
  for i = 1, #infos do
    createGene(infos[i], i - 1)
  end
  return items, width, height
end
local Genes = {}
Genes.GetGeneInfo = getGeneInfo
Genes.GetSingleGeneInfo = getSingleGeneInfo
Genes.GetGeneInfos = getGeneInfos
Genes.GetGeneInfosForMonsterId = getGeneInfosForMonsterId
Genes.GetFullGenesForMonster = getFullGenesForMonster
function Genes.InitForGeneString(geneString, parent, options)
  local items
  local width = 0
  local height = 0
  local infos = getGeneInfos(geneString)
  if infos then
    items, width, height = _setup(parent, infos, options)
    MenuHelpers.CenterHorizontally(items)
  end
  return items, width, height
end
function Genes.InitForMonsterId(monsterId, parent, options)
  local items
  local width = 0
  local height = 0
  local infos = getGeneInfosForMonsterId(monsterId)
  if infos then
    items, width, height = _setup(parent, infos, options)
    MenuHelpers.CenterHorizontally(items)
  end
  return items, width, height
end
function Genes:onPostInit()
  if self("populated"):GetInt() == 0 then
    self:populate()
  end
end
function Genes:populate()
  if self("populated"):GetInt() == 1 then
    return
  end
  local options = {
    layer = self:HasVar("Layer") and self("Layer"):GetString() or "HUD",
    size = self:HasVar("Size") and self("Size"):GetFloat() or 0.5 * game.hudScale(),
    spacing = self:HasVar("Spacing") and self("Spacing"):GetFloat() or 0,
    useFlags = self:HasVar("useFlags") and self("useFlags"):GetInt() or 0
  }
  local infos
  if self:HasVar("GeneString") then
    infos = getGeneInfos(self("GeneString"):GetString())
  elseif self:HasVar("MonsterId") then
    infos = getGeneInfosForMonsterId(self("MonsterId"):GetInt())
  elseif self:HasVar("UserMonsterId") then
    local overrideReattunedGenes
    if self:HasVar("OverrideReattunedGenes") then
      overrideReattunedGenes = self("OverrideReattunedGenes"):GetString()
    end
    infos = getGeneInfosForUserMonsterId(self("UserMonsterId"):GetInt(), overrideReattunedGenes)
  end
  if infos then
    local items, width, height = _setup(self, infos, options)
    self:setSize(Vector2(width, height))
    MenuHelpers.CenterHorizontally(items)
    self("populated"):SetInt(1)
    if self("visible"):GetInt() == 0 then
      self:hide()
    end
    if self:HasVar("alpha") then
      self:update()
    end
    if self:HasVar("clipX") then
      self:updateClipping()
    end
  end
end
function Genes:repopulate()
  MenuHelpers.ForEachEntry(self, function(entry)
    self:RemoveElement(entry)
  end)
  self:populate()
  self:calculatePosition()
end
function Genes:Show()
  self("visible"):SetInt(1)
  MenuHelpers.ForEachEntry(self, function(entry)
    entry:Show()
  end)
end
Genes.show = Genes.Show
function Genes:setVisible()
  self:Show()
end
function Genes:Hide()
  self("visible"):SetInt(0)
  MenuHelpers.ForEachEntry(self, function(entry)
    entry:Hide()
  end)
end
function Genes:setInvisible()
  self:Hide()
end
Genes.hide = Genes.Hide
function Genes:update()
  local alpha = self("alpha"):GetFloat()
  MenuHelpers.ForEachEntry(self, function(entry)
    entry:SetAlpha(alpha)
  end)
end
function Genes:enable()
  MenuHelpers.ForEachEntry(self, function(entry)
    entry:SetColor(1, 1, 1)
  end)
end
function Genes:disable()
  MenuHelpers.ForEachEntry(self, function(entry)
    entry:SetColor(0.5, 0.5, 0.5)
  end)
end
function Genes:SetColor(r, g, b)
  MenuHelpers.ForEachEntry(self, function(entry)
    entry:SetColor(r, g, b)
  end)
end
function Genes:updateClipping()
  MenuHelpers.ForEachEntry(self, function(entry)
    entry:UpdateClipping(self)
  end)
end
function Genes:setClipping(x, y, w, h)
  self("clipX"):SetInt(x)
  self("clipY"):SetInt(y)
  self("clipW"):SetInt(w)
  self("clipH"):SetInt(h)
  self:updateClipping()
end
return Genes
