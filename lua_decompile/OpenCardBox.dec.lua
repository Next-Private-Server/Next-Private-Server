local OpenCardBox = {
  Fade = {
    Touch = {}
  },
  Layout = {
    Sprite = {}
  }
}
function OpenCardBox:onPostInit()
  self:SetupGenericListener(self.Layout.Sprite:GetReceiver(), "sys::msg::MsgAnimationFinished", "gotMsgAnimationFinished")
end
local packRemaps = {
  [game.CardPackType_Common] = "sticker_pack_common_sheet.xml",
  [game.CardPackType_Uncommon] = "sticker_pack_uncommon_sheet.xml",
  [game.CardPackType_Rare] = "sticker_pack_rare_sheet.xml",
  [game.CardPackType_Epic] = "sticker_pack_epic_sheet.xml",
  [game.CardPackType_Legendary] = "sticker_pack_legendary_sheet.xml"
}
function OpenCardBox:Setup(rewards)
  print("Setup pack anim")
  local animUtil = game.AnimUtil(self.Layout.Sprite)
  local tier = 1
  local packId = 1
  for i, reward in ipairs(rewards) do
    print("Reward " .. i .. ":", reward.type, reward.id, reward.amount)
    if tier < 2 and reward.id == game.CardPackType_Rare then
      print("Found rare, setting tier to 2")
      tier = 2
    end
    if tier < 3 and reward.id == game.CardPackType_Legendary then
      print("Found legendary, setting tier to 3")
      tier = 3
    end
    for j = 1, reward.amount do
      local remap = packRemaps[reward.id]
      if remap then
        animUtil:addRemap("PACK" .. packId, remap, "pack")
        animUtil:addRemap("Pack_Top " .. packId, remap, "tear")
      end
      packId = packId + 1
    end
  end
  print("Box tier:", tier)
  self.Layout.Sprite:GetVar("animation"):SetString("tier_" .. tier)
  lua_sys.playSoundFx("audio/sfx/sticker_mysterybox_open.ogg")
end
function OpenCardBox:gotMsgAnimationFinished(msg)
  print("Animation finished, closing pack popup")
  self:queuePop()
  game.pushPopUp("open_card_pack")
end
function OpenCardBox:queuePop()
  self:root():removePopUp(self:name())
end
function OpenCardBox:skip()
  self:root():removePopUp(self:name())
  game.pushPopUp("open_card_pack")
end
return OpenCardBox
