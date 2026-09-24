local Genes = include("Genes")
local MenuHelpers = include("MenuHelpers")
local MonsterBookInfoOwned = {
  InfoContent = {
    Text = {}
  },
  Animation = {
    Sprite = {}
  },
  TitleFrame = {
    Text = {}
  },
  StatsList = {},
  CostumesList = {}
}
function MonsterBookInfoOwned:onInit()
  self.context = ""
  local selectedMonsterView = self:root():GetElement("SelectedMonsterView")
  if selectedMonsterView then
    self.context = "BoM"
    local monsterId = selectedMonsterView("selectedMonst"):GetInt()
    self:SharedSetup(monsterId)
    collectgarbage("stop")
  end
  selectedMonsterView = self:root():GetElement("breeding_eggs_popup")
  if selectedMonsterView then
    self.context = "Breeding"
    local monsterId = selectedMonsterView("selectedMonster"):GetInt()
    self:SharedSetup(monsterId)
    collectgarbage("stop")
  end
end
function MonsterBookInfoOwned:Setup(monsterId)
  self:SharedSetup(monsterId)
  self.TitleFrame.Text:GetVar("text"):SetString(game.monsterTypeName(monsterId))
  self.InfoContent.Text:GetVar("text"):SetString(game.monsterTypeDescr(monsterId))
  self.Animation.Sprite:initMonsterAnimation(self.Animation)
  self.StatsList:populateMonsterStats()
  self.StatsList:setPositionBroadcast(true)
  self.CostumesList:setupCostumesList()
  self.CostumesList.Swiper:DoStoredScript("refresh")
  self.CostumesList:setPositionBroadcast(true)
  self:DoPostSetup()
end
function MonsterBookInfoOwned:SharedSetup(monsterId)
  self:GetVar("selectedMonster"):SetInt(monsterId)
  Genes.InitForMonsterId(monsterId, self:GetElement("ImageFrame"), {
    layer = "FrontPopUps",
    spacing = -2 * game.hudScale(),
    prefix = "geneItem",
    priority = -4,
    vAnchor = lua_sys.BOTTOM,
    offsetY = -4 * game.menuScaleY()
  })
  local numGenes = game.monsterTypeNumGenes(monsterId)
  self("numGenes"):SetInt(numGenes)
end
function MonsterBookInfoOwned:makeGenesInvis()
  local numGenes = self("numGenes"):GetInt()
  for i = 0, numGenes - 1 do
    local geneElement = self:GetElement("geneItem" .. i)
    geneElement:DoStoredScript("setInvis")
  end
end
function MonsterBookInfoOwned:makeGenesVis()
  local numGenes = self("numGenes"):GetInt()
  for i = 0, numGenes - 1 do
    local geneElement = self:GetElement("geneItem" .. i)
    geneElement:DoStoredScript("setVis")
  end
end
function MonsterBookInfoOwned:onPostInit()
  if self:HasVar("selectedMonster") and self:GetVar("selectedMonster"):GetInt() > 0 then
    self:DoPostSetup()
  end
end
function MonsterBookInfoOwned:DoPostSetup()
  if self.InfoContent:GetComponent("Text"):absH() <= self:GetElement("InfoContent"):absH() then
    self.ScrollBar.Sprite("visible"):SetInt(0)
    self.ScrollMarker.Marker("visible"):SetInt(0)
  end
  local buttons = {}
  local bioButton = self:GetElement("BioButton")
  bioButton:DoStoredScript("setVisible")
  table.insert(buttons, bioButton)
  local statsButton = self:GetElement("StatsButton")
  statsButton:DoStoredScript("setVisible")
  table.insert(buttons, statsButton)
  local costumesButton = self:GetElement("CostumesButton")
  if not game.battleTutActive() and game.getCostumeIdsForMonsterType(self:GetVar("selectedMonster"):GetInt(), true):size() > 1 then
    costumesButton:DoStoredScript("setVisible")
    table.insert(buttons, costumesButton)
  else
    costumesButton:DoStoredScript("setInvisible")
  end
  MenuHelpers.JustifyHorizontally(buttons, 225 * game.menuScaleX())
  self:DoStoredScript("showBio")
end
function MonsterBookInfoOwned:queuePop()
  local selectedMonsterView = self:root():GetElement("SelectedMonsterView")
  if selectedMonsterView then
    manager:hideContextBar()
    selectedMonsterView("selectedMonst"):SetInt(-1)
    self:root().MonsterList.Camera("enabled"):SetInt(1)
  end
  self:root():popPopUp()
end
function MonsterBookInfoOwned:showBio()
  self.InfoContent.Text("visible"):SetInt(1)
  self.InfoFrame.Touch("enabled"):SetInt(1)
  self.BioButton:DoStoredScript("disable")
  self.BioButton.UpSprite:setColor(1, 1, 1)
  self.StatsButton:DoStoredScript("enable")
  self.StatsButton.UpSprite:setColor(0.5, 0.5, 0.5)
  if self.CostumesButton.UpSprite("visible"):GetInt() == 1 then
    self.CostumesButton:DoStoredScript("enable")
    self.CostumesButton.UpSprite:setColor(0.5, 0.5, 0.5)
  end
  self.InfoFrame.Swiper:DoStoredScript("refresh")
  self.ScrollMarker("scrollSize"):SetFloat(self.InfoFrame("scrollSize"):GetFloat())
  if self.InfoContent:GetComponent("Text"):absH() > self.InfoContent:absH() then
    self.ScrollBar:DoStoredScript("setVisible")
    self.ScrollMarker:DoStoredScript("setVisible")
  else
    self.ScrollBar:DoStoredScript("setInvisible")
    self.ScrollMarker:DoStoredScript("setInvisible")
  end
  self:DoStoredScript("makeGenesVis")
  if self.CostumesList("NewSelectedEntryID"):GetInt() ~= -1 then
    self.CostumesList:DoStoredScript("unequipCostume")
  end
  self.StatsList:DoStoredScript("hideStats")
  self.CostumesList:DoStoredScript("setInvisible")
end
function MonsterBookInfoOwned:showStats()
  self.InfoContent.Text("visible"):SetInt(0)
  self.InfoFrame.Touch("enabled"):SetInt(0)
  self.BioButton:DoStoredScript("enable")
  self.BioButton.UpSprite:setColor(0.5, 0.5, 0.5)
  self.ScrollBar:DoStoredScript("setInvisible")
  self.ScrollMarker:DoStoredScript("setInvisible")
  self.StatsButton:DoStoredScript("disable")
  self.StatsButton.UpSprite:setColor(1, 1, 1)
  if self.CostumesButton.UpSprite("visible"):GetInt() == 1 then
    self.CostumesButton:DoStoredScript("enable")
    self.CostumesButton.UpSprite:setColor(0.5, 0.5, 0.5)
  end
  self:DoStoredScript("makeGenesVis")
  if self.CostumesList("NewSelectedEntryID"):GetInt() ~= -1 then
    self.CostumesList:DoStoredScript("unequipCostume")
  end
  self.StatsList:DoStoredScript("showStats")
  self.CostumesList:DoStoredScript("setInvisible")
end
function MonsterBookInfoOwned:showCostumes()
  self.InfoContent.Text("visible"):SetInt(0)
  self.InfoFrame.Touch("enabled"):SetInt(1)
  self.BioButton:DoStoredScript("enable")
  self.BioButton.UpSprite:setColor(0.5, 0.5, 0.5)
  self.ScrollBar.Sprite("visible"):SetInt(0)
  self.ScrollMarker.Marker("visible"):SetInt(0)
  self.StatsButton:DoStoredScript("enable")
  self.StatsButton.UpSprite:setColor(0.5, 0.5, 0.5)
  self.CostumesButton:DoStoredScript("disable")
  self.CostumesButton.UpSprite:setColor(1, 1, 1)
  self.StatsList:DoStoredScript("hideStats")
  self.CostumesList:DoStoredScript("setVisible")
  self.CostumesList.Swiper:DoStoredScript("refresh")
  self.ScrollMarker("scrollSize"):SetFloat(self.CostumesList("scrollSize"):GetFloat())
  if self.CostumesList("contentHeight"):GetInt() > self.InfoContent:absH() then
    self.ScrollBar:DoStoredScript("setVisible")
    self.ScrollMarker:DoStoredScript("setVisible")
  else
    self.ScrollBar:DoStoredScript("setInvisible")
    self.ScrollMarker:DoStoredScript("setInvisible")
  end
  self:DoStoredScript("makeGenesInvis")
  self.CostumesList:DoStoredScript("selectNewEntry")
end
function MonsterBookInfoOwned.Animation.Sprite:onInit(element)
  if element:parent():HasVar("selectedMonster") and element:parent():GetVar("selectedMonster"):GetInt() > 0 then
    self:initMonsterAnimation(element)
  end
end
function MonsterBookInfoOwned.Animation.Sprite:initMonsterAnimation(element)
  local monsterType = element:parent():GetVar("selectedMonster"):GetInt()
  local monsterData = game.getMonsterData(monsterType)
  local animFile = game.monsterTypeGfxName(monsterType)
  if monsterData:isModal() then
    local currentMode = game.player():getActiveIsland():islandMode()
    modalMonsterData = game.getModalMonsterData(monsterData, currentMode)
    animFile = modalMonsterData:animationFile()
  end
  self("animationName"):SetString("xml_bin/" .. animFile)
  local awakenedMonsterType = false
  if game.IsBoxMonsterFromType(monsterType) or monsterData:isTitansoul() then
    awakenedMonsterType = true
  end
  if awakenedMonsterType and game.hasOrHasEverHadMonsterOnBookOfMonstersIsland(monsterType) then
    local islandType = game.getBookOfMonstersIslandType()
    if game.isAmberIsland(islandType) then
      self("animation"):SetString("Store")
      self:setScale(Vector2(0.75 * game.menuScaleX(), 0.75 * game.menuScaleX()))
      element:setOrientationPosition(Vector2(self:size().x / 2, self:size().y / 2 + 15 * game.hudScale()))
    elseif islandType == game.IslandType_GOLD and monsterData:isEpicMonster() and monsterData:isWubbox() then
      local entityId = monsterData:entityId()
      if entityId == 1525 then
        self("animation"):SetString("01-F_EPIC_Dance_Plant_01")
      elseif entityId == 1526 then
        self("animation"):SetString("01-F_EPIC_Dance_Cold_01")
      elseif entityId == 1527 then
        self("animation"):SetString("01-F_EPIC_Dance_Air_01")
      elseif entityId == 1528 then
        self("animation"):SetString("01-F_EPIC_Dance_Water_01")
      elseif entityId == 1529 then
        self("animation"):SetString("01-F_EPIC_Dance_Earth_01")
      else
        self("animation"):SetString("01-F_EPIC_Dance_Default_01")
      end
      local scale = 270 / self:size().y
      self:setScale(Vector2(scale * game.menuScaleX(), scale * game.menuScaleX()))
      element:setOrientationPosition(Vector2(self:size().x / 2, self:size().y / 2 + self:size().y / 4))
    else
      self("animation"):SetString("Activate")
      self("pingpong"):SetInt(1)
      local scale = 265 / self:size().y
      self:setScale(Vector2(scale * game.menuScaleX(), scale * game.menuScaleX()))
      element:setOrientationPosition(Vector2(self:size().x / 2, self:size().y / 2 + 85 * game.composerScale()))
    end
  else
    self("animation"):SetString(game.objectStoreAnim())
    local scale = 112.5 / self:size().y
    self:setScale(Vector2(scale * game.menuScaleX(), scale * game.menuScaleX()))
    element:setOrientationPosition(Vector2(self:size().x / 2, self:size().y / 2 + 15 * game.hudScale()))
  end
  self("layer"):SetString("FrontPopUps")
end
function MonsterBookInfoOwned.StatsList:populateMonsterStats()
  if not self:parent():HasVar("selectedMonster") or self:parent():GetVar("selectedMonster"):GetInt() <= 0 then
    return
  end
  local selectedMonster = self:parent():GetVar("selectedMonster"):GetInt()
  local previous, statsArray
  local monsterData = game.getMonsterData(selectedMonster)
  if game.getBookOfMonstersIslandType() == game.IslandType_UNDERLING or game.getBookOfMonstersIslandType() == game.IslandType_CELESTIAL then
    statsArray = {
      "template_stat_store_species",
      "template_stat_store_class",
      "template_stat_underlingrate"
    }
  elseif game.getBookOfMonstersIslandType() == game.IslandType_MAGICAL_NEXUS then
    statsArray = {
      "template_stat_store_species",
      "template_stat_store_class"
    }
  elseif game.getBookOfMonstersIslandTypeIsEtherealIslet() then
    statsArray = {
      "template_stat_store_species",
      "template_stat_store_class",
      "template_stat_store_coinrate",
      "template_stat_store_maxcoins"
    }
  elseif monsterData:isTitansoul() then
    statsArray = {
      "template_stat_store_species",
      "template_stat_store_class",
      "template_stat_store_beds"
    }
  elseif game.getBookOfMonstersIslandType() == game.IslandType_PAIRONORMAL then
    local island = game.player():getIslandWithId(game.getBookOfMonstersIslandType())
    if island and island:islandMode() == 1 then
      statsArray = {
        "template_stat_store_species",
        "template_stat_store_class",
        "template_stat_store_beds",
        "template_stat_underlingrate"
      }
    else
      print("showing major stats")
      statsArray = {
        "template_stat_store_species",
        "template_stat_store_class",
        "template_stat_store_beds",
        "template_stat_paironormal_currency_rate",
        "template_stat_paironormal_max_currency"
      }
    end
  elseif game.getBookOfMonstersIslandType() == game.IslandType_GOLD then
    statsArray = {
      "template_stat_store_species",
      "template_stat_store_class"
    }
  else
    statsArray = {
      "template_stat_store_species",
      "template_stat_store_class",
      "template_stat_store_beds",
      "template_stat_store_coinrate",
      "template_stat_store_maxcoins"
    }
  end
  for i = 1, #statsArray do
    local statEntry = self:GetElement("statEntry" .. i)
    if statEntry == nil then
      statEntry = menu:addTemplateElement(statsArray[i], "statEntry" .. i, self)
      if previous == nil then
        statEntry:relativeTo(self)
        statEntry:setOrientation(lua_sys.MenuOrientation(0, 0, -2, lua_sys.HCENTER, lua_sys.TOP))
        statEntry:setRelativeObjectAnchors(lua_sys.HCENTER, lua_sys.TOP)
      else
        statEntry:relativeTo(previous)
        statEntry:setOrientation(lua_sys.MenuOrientation(0, 0, 0, lua_sys.HCENTER, lua_sys.TOP))
        statEntry:setRelativeObjectAnchors(lua_sys.HCENTER, lua_sys.BOTTOM)
      end
      previous = statEntry
      statEntry("monsterID"):SetInt(selectedMonster)
      statEntry:init()
      statEntry:setPositionBroadcast(true)
      statEntry:postInit()
    else
      statEntry:DoStoredScript("repopulate")
    end
  end
  self("NumStats"):SetInt(#statsArray)
end
function MonsterBookInfoOwned.CostumesList:onInit()
  if self:parent():HasVar("selectedMonster") and self:parent():GetVar("selectedMonster"):GetInt() > 0 then
    self:setupCostumesList()
  end
end
function MonsterBookInfoOwned.CostumesList:setupCostumesList()
  local costumes = game.getCostumeIdsForMonsterType(self:parent():GetVar("selectedMonster"):GetInt(), true)
  local previous
  self("NewSelectedEntry"):SetString("")
  self("NewSelectedEntryID"):SetInt(-1)
  local bad_ids = {
    295,
    299,
    300,
    301,
    302,
    303,
    304,
    305,
    306,
    466,
    467,
    468,
    469,
    470,
    471,
    472,
    473,
    474
  }
  local bad_set = {}
  for _, id in ipairs(bad_ids) do
    bad_set[id] = true
  end
  local idx = 0
  for i = 0, costumes:size() - 1 do
    local costumeId = costumes[i]
    if costumeId ~= 0 and not bad_set[costumeId] then
      local costumeEntry = menu:addTemplateElement("template_bom_costume_entry", "costumeEntry" .. idx, self)
      local costumeData = game.getCostumeData(costumeId)
      costumeEntry("costumeId"):SetInt(costumeId)
      costumeEntry("costumeName"):SetString(LOC(costumeData.name))
      costumeEntry("monsterType"):SetInt(self:parent():GetVar("selectedMonster"):GetInt())
      costumeEntry("locked"):SetInt(0)
      costumeEntry("timedAvail"):SetInt(0)
      costumeEntry("timedSale"):SetInt(0)
      if previous == nil then
        self("NewSelectedEntry"):SetString(costumeEntry:name())
        self("NewSelectedEntryID"):SetInt(costumeEntry("costumeId"):GetInt())
        costumeEntry("selected"):SetInt(1)
        costumeEntry:relativeTo(self)
        costumeEntry:setOrientation(lua_sys.MenuOrientation(0, 0, 0, lua_sys.HCENTER, lua_sys.TOP))
        costumeEntry:setRelativeObjectAnchors(lua_sys.HCENTER, lua_sys.TOP)
      else
        costumeEntry("selected"):SetInt(0)
        costumeEntry:relativeTo(previous)
        costumeEntry:setOrientation(lua_sys.MenuOrientation(0, 0, 0, lua_sys.HCENTER, lua_sys.TOP))
        costumeEntry:setRelativeObjectAnchors(lua_sys.HCENTER, lua_sys.BOTTOM)
      end
      previous = costumeEntry
      costumeEntry:init()
      costumeEntry:setPositionBroadcast(true)
      idx = idx + 1
    end
  end
  self("numCostumes"):SetInt(idx)
  if self:parent():GetElement("costumeEntry0") ~= nil then
    self("contentHeight"):SetInt(self("numCostumes"):GetInt() * (self:parent():GetElement("costumeEntry0"):absH() + 0))
  else
    self("contentHeight"):SetInt(0)
  end
  self("scrollSize"):SetFloat(0)
end
return MonsterBookInfoOwned
