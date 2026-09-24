local ScrollingListHelper = include("ScrollingListHelper")
local BattleCampaignProgressUI = {}
function BattleCampaignProgressUI.Populate(element)
  print("Populating Campaign Progress Info!")
  ScrollingListHelper.ListClear(element)
  local campaignId = game.getBattleClientData():getSelectedCampaignId()
  local campaignData = game.getBattleCampaignData(campaignId)
  local function createFunc(idx, itemName)
    local entry = menu:addTemplateElement("template_battle_campaign_progressinfo_entry", itemName, element)
    entry("CampaignId"):SetInt(campaignId)
    entry("BattleId"):SetInt(idx)
    entry("Layer"):SetString("MidPopUps")
    return entry
  end
  ScrollingListHelper.ListPopulate(element, campaignData.battles:size(), createFunc)
end
return BattleCampaignProgressUI
