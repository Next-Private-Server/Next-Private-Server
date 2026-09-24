local OffsetTransition = include("MenuElementPositionOffsetTransition")
local MenuHelpers = include("MenuHelpers")
local ScrollingListHelper = include("ScrollingListHelper")
local CostumeTeleportUnlockUI = {}
local rewardListElement
local function populate(element)
  local battleClientData = game.getBattleClientData()
  local data = battleClientData:dequeueCostumeTeleportUnlockPopup()
  local rewardsTitle = LOC("COSTUME_TELEPORT_UNLOCK_TITLE")
  element:parent().Title.Text("text"):SetString(rewardsTitle)
  local rewardsText = LOC("COSTUME_TELEPORT_UNLOCK_DESC")
  element:parent().RewardsText.Text("text"):SetString(rewardsText)
  local function createFunc(idx, itemName)
    local costumeId = data.costumes[idx]
    print("create costume reward:", costumeId)
    local costumeData = game.getCostumeData(costumeId)
    local item = menu:addTemplateElement("template_battle_campaign_reward_entry", itemName, element)
    item("ItemTitle"):SetString("UNLOCKED_COSTUME")
    item("ItemTitle2"):SetString(costumeData.name)
    item("AnimationFile"):SetString(game.getMonsterAnimationFileFromType(costumeData.monsterId))
    item("AnimationName"):SetString(game.getMonsterAnimationNameFromType(costumeData.monsterId))
    item("CostumeId"):SetInt(costumeId)
    item("BgAnimationFile"):SetString("glow.bin")
    item("BgAnimationName"):SetString("glow")
    item("TintR"):SetFloat(1)
    item("TintG"):SetFloat(1)
    item("TintB"):SetFloat(1)
    return item
  end
  ScrollingListHelper.ListPopulate(element, data.costumes:size(), createFunc)
end
function CostumeTeleportUnlockUI.onInit(element)
  rewardListElement = element:GetElement("Rewards")
  ScrollingListHelper.ListInit(rewardListElement, {
    direction = lua_sys.MenuSwipeComponent_SwipeDirectionHorizontal,
    alwaysBounce = 0
  })
  populate(rewardListElement)
  OffsetTransition.OnInit(element:GetElement("Bg"), {
    startY = lua_sys.screenHeight() * 2,
    endY = -16 * game.menuScaleY(),
    duration = 0.66
  })
  CostumeTeleportUnlockUI.show(element)
end
function CostumeTeleportUnlockUI.queuePop(element)
  CostumeTeleportUnlockUI.hide(element)
end
function CostumeTeleportUnlockUI.onTick(element, dt)
  local options = {
    ease = lua_sys.Quadratic_EaseIn,
    onDoneShow = function(e)
      MenuHelpers.DoCelebrateEffect(element)
    end,
    onDoneHide = function(e)
      e:root():popPopUp()
    end
  }
  OffsetTransition.OnTick(element:GetElement("Bg"), dt, options)
  ScrollingListHelper.ListTick(rewardListElement, dt)
  MenuHelpers.ForEachEntry(rewardListElement, function(entry)
    entry("clipX"):SetFloat(rewardListElement:absX())
    entry("clipY"):SetFloat(rewardListElement:absY())
    entry("clipW"):SetFloat(rewardListElement:absW())
    entry("clipH"):SetFloat(rewardListElement:absH())
    entry:DoStoredScript("updateClipping")
  end)
end
function CostumeTeleportUnlockUI.show(element)
  OffsetTransition.Show(element:GetElement("Bg"))
  lua_sys.playSoundFx("audio/sfx/menu_slide.wav")
end
function CostumeTeleportUnlockUI.hide(element)
  OffsetTransition.Hide(element:GetElement("Bg"))
  lua_sys.playSoundFx("audio/sfx/menu_slide.wav")
end
return CostumeTeleportUnlockUI
