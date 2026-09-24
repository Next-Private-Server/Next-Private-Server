local RewardProperties = include("RewardProperties")
local ClubboxProgress = {
  Bg = {
    Sprite = {},
    Touch = {}
  },
  TitleFrame = {
    Sprite = {},
    RightSpeaker = {},
    LeftSpeaker = {},
    Text = {}
  },
  TimeFrame = {
    Text = {}
  },
  HypeBlob = {
    Icon = {},
    Text = {}
  },
  RewardBlob = {
    Icon = {},
    Text = {}
  },
  SideBar = {
    Bg = {},
    Poster = {},
    TopPrize1 = {
      Anim = {},
      Text = {}
    },
    TopPrize2 = {
      Anim = {},
      Text = {}
    },
    TopPrizeText = {}
  },
  PathMap = {}
}
local START_AND_END_BUFFER = 52 * game.windowScaleY()
local HEIGHT_OFFSET = 50 * game.windowScaleY()
local WIDTH_OFFSET = HEIGHT_OFFSET * 2
function ClubboxProgress:onPostInit()
  self.curClubboxAct = game.existingClubboxAct()
  self.rewardTrackId = game.clubboxActRewardTrackId(self.curClubboxAct)
  self.currentHype = game.clubboxCurHype(self.curClubboxAct)
  local clubboxStartTopHype = game.clubboxStartTopHype(self.curClubboxAct)
  local rewardTrackData = game.getRewardTrackData(self.rewardTrackId)
  local endReward
  local earnedTier = 0
  local currentLevelPosX = 0
  local prestigeLevel = game.currentClubboxPrestigeLevel()
  local showPrestige = prestigeLevel > 0
  local prestigePointsOffset = prestigeLevel * rewardTrackData.totalPoints
  if showPrestige then
    self.Bg.Sprite("spriteName"):SetString("gfx/clubbox/clubbox_textbox_9S_prestige")
    self.TitleFrame.Sprite("spriteName"):SetString("gfx/clubbox/clubbox_currency_frame_9S_prestige")
    self.TitleFrame.RightSpeaker("spriteName"):SetString("header_right_prestige")
    self.TitleFrame.LeftSpeaker("spriteName"):SetString("header_left_prestige")
    self.RewardBlob.Icon("spriteName"):SetString("icon_hype_progress_prestige")
  end
  for i = 0, rewardTrackData.levels:size() - 1 do
    local data = rewardTrackData.levels[i]
    if data.sub_level == 0 then
      if endReward == nil or endReward.level < data.level then
        endReward = data
      end
      local entity = menu:addTemplateElement("template_clubbox_progress_node", "ClubboxProgressNode" .. data.level, self.PathMap)
      entity:relativeTo(self.PathMap)
      entity:setRelativeObjectAnchors(lua_sys.LEFT, lua_sys.VCENTER)
      entity:templateVars().layer = "FrontClipping"
      entity:init()
      entity:setPositionBroadcast(true)
      entity:postInit()
      local isTopPath = data.level % 2 == 1
      local isTopBottomDirectionPath = 2 > (data.level - 1) % 4
      if not isTopBottomDirectionPath then
        isTopPath = not isTopPath
      end
      local column = math.ceil(data.level / 2) - 1
      local x = column * WIDTH_OFFSET + START_AND_END_BUFFER
      local y = isTopPath and -HEIGHT_OFFSET or HEIGHT_OFFSET
      entity:setOrientation(lua_sys.MenuOrientation(x, y, 0, lua_sys.HCENTER, lua_sys.VCENTER))
      local rewards
      if showPrestige then
        rewards = data:prestigeRewards()
      else
        rewards = data:rewards(false)
      end
      if rewards:size() >= 1 then
        local rewardData = rewards[0]
        local mainSprite = entity:E("Main")
        mainSprite:loadLootRewardData(rewardData)
        if rewardData.type == game.LootType_ClubboxUnlock then
          mainSprite:setSprite(rewardData:getExtraString("progress_icon"), "xml_resources/battle_buttons.xml")
        elseif rewardData.type == game.LootType_ClubboxTokens then
          mainSprite:setSprite("button_clubbox_tokens", "xml_resources/battle_buttons.xml")
        end
        local appearance = RewardProperties:getRewardAppearance({
          id = rewardData.id,
          type = rewardData.type,
          amount = rewardData.amount,
          reward_anim = rewardData:getExtraString("reward_anim"),
          text_id = rewardData:getExtraString("text_id")
        }, {
          variation = rewardData:getExtraBool("box_filled") and 1 or 0
        })
        if appearance then
          entity.TooltipText = appearance.name
        end
        local altSprite = entity:E("Alt")
        if rewards:size() > 1 then
          local rewardIndex = 1
          entity.TooltipTextSmall = ""
          while rewardIndex < rewards:size() do
            rewardData = rewards[rewardIndex]
            if rewardIndex == 1 then
              altSprite:loadLootRewardData(rewardData)
              if rewardData.type == game.LootType_ClubboxUnlock then
                altSprite:setSprite(rewardData:getExtraString("progress_icon"), "xml_resources/battle_buttons.xml")
              elseif rewardData.type == game.LootType_ClubboxTokens then
                altSprite:setSprite("button_clubbox_tokens", "xml_resources/battle_buttons.xml")
              end
            end
            local appearance = RewardProperties:getRewardAppearance({
              id = rewardData.id,
              type = rewardData.type,
              amount = rewardData.amount,
              reward_anim = rewardData:getExtraString("reward_anim"),
              text_id = rewardData:getExtraString("text_id")
            }, {
              variation = rewardData:getExtraBool("box_filled") and 1 or 0
            })
            if appearance then
              if rewardIndex > 1 then
                entity.TooltipTextSmall = entity.TooltipTextSmall .. [[


]]
              end
              entity.TooltipTextSmall = entity.TooltipTextSmall .. appearance.name
            end
            rewardIndex = rewardIndex + 1
          end
        else
          entity:C("TouchSmall")("enabled"):SetInt(0)
          altSprite:Hide()
        end
      end
      local isLocked = false
      if self.currentHype < data.startPoints + prestigePointsOffset then
        entity:C("Base")("spriteName"):SetString("gfx/clubbox/prize_slot_grey_9s")
        isLocked = true
      elseif self.currentHype >= data.startPoints + data.points + prestigePointsOffset then
        entity:C("Base")("spriteName"):SetString("gfx/clubbox/prize_slot_teal_9s")
        earnedTier = data.level
        currentLevelPosX = x
      else
        currentLevelPosX = x
        entity:C("Base")("spriteName"):SetString("gfx/clubbox/prize_slot_yellow_9s")
      end
      if 1 < data.level then
        local edge = menu:addTemplateElement("template_clubbox_progress_edge", "ClubboxProgressEdge" .. data.level, self.PathMap)
        edge:relativeTo(entity)
        edge:templateVars().layer = "FrontClipping"
        edge:init()
        edge:setPositionBroadcast(true)
        edge:postInit()
        local edgeSprite = edge:C("Sprite")
        if isLocked then
          edgeSprite("spriteName"):Set("wire_01")
        else
          local spriteName = "electric_beam_0" .. math.random(1, 3)
          if showPrestige then
            spriteName = spriteName .. "_prestige"
          end
          edgeSprite("spriteName"):Set(spriteName)
        end
        if isTopPath then
          if isTopBottomDirectionPath then
            edgeSprite("rotation"):SetFloat(0.5 * math.pi)
            edge:setRelativeObjectAnchors(lua_sys.LEFT, lua_sys.VCENTER)
            edge:setOrientation(lua_sys.MenuOrientation(0, 0, 0, lua_sys.RIGHT, lua_sys.VCENTER))
          else
            edge:setRelativeObjectAnchors(lua_sys.HCENTER, lua_sys.BOTTOM)
            edge:setOrientation(lua_sys.MenuOrientation(0, -8 * game.windowScaleY(), 0, lua_sys.HCENTER, lua_sys.TOP))
          end
        elseif isTopBottomDirectionPath then
          edge:setRelativeObjectAnchors(lua_sys.HCENTER, lua_sys.TOP)
          edge:setOrientation(lua_sys.MenuOrientation(0, -8 * game.windowScaleY(), 0, lua_sys.HCENTER, lua_sys.BOTTOM))
        else
          edgeSprite("rotation"):SetFloat(0.5 * math.pi)
          edge:setRelativeObjectAnchors(lua_sys.LEFT, lua_sys.VCENTER)
          edge:setOrientation(lua_sys.MenuOrientation(0, 0, 0, lua_sys.RIGHT, lua_sys.VCENTER))
        end
      end
    end
  end
  self.scrollLimit = math.ceil(endReward.level * 0.5) * WIDTH_OFFSET * -1 + lua_sys.screenWidth() - lua_sys.deviceMarginX() - self.SideBar:absW() - self.Bg:GetVar("xOffset"):GetFloat() * 0.5 - START_AND_END_BUFFER
  currentLevelPosX = lua_sys.clamp(-currentLevelPosX + (self.Bg:absW() - WIDTH_OFFSET) * 0.5, self.scrollLimit, 0)
  self.PathMap:GetVar("xOffset"):SetFloat(currentLevelPosX)
  local clippingPadding = 18 * game.windowScaleY()
  game.setClipping("FrontClipping", (self.Bg:absX() + clippingPadding) * lua_sys.deviceScaleX(), (self.Bg:absY() + clippingPadding) * lua_sys.deviceScaleY(), (self.Bg:absW() - clippingPadding * 2) * lua_sys.deviceScaleX(), (self.Bg:absH() - clippingPadding * 2) * lua_sys.deviceScaleY())
  self.SideBar.Poster("size"):SetInt(1)
  self.SideBar.Poster("spriteName"):SetString(game.getClubboxActPosterIcon(self.curClubboxAct))
  self.SideBar.Poster("sheetName"):SetString("xml_resources/" .. game.getClubboxActPosterSheet(self.curClubboxAct))
  local scale = 0.7 * self.SideBar.Bg:absW() / self.SideBar.Poster:absW()
  self.SideBar.Poster("size"):SetFloat(scale)
  self.SideBar.TopPrize1.Anim:V("animationName"):SetString("xml_bin/" .. game.getClubboxActTopPrize1AnimFile(self.curClubboxAct))
  self.SideBar.TopPrize1.Anim:V("animation"):SetString(game.getClubboxActTopPrize1AnimName(self.curClubboxAct))
  self.SideBar.TopPrize1.Text:V("text"):SetString(game.getClubboxActTopPrize1Desc(self.curClubboxAct))
  self.SideBar.TopPrize2.Anim:V("animationName"):SetString("xml_bin/" .. game.getClubboxActTopPrize2AnimFile(self.curClubboxAct))
  self.SideBar.TopPrize2.Anim:V("animation"):SetString(game.getClubboxActTopPrize2AnimName(self.curClubboxAct))
  self.SideBar.TopPrize2.Text:V("text"):SetString(game.getClubboxActTopPrize2Desc(self.curClubboxAct))
  local hypeText = game.getLocalizedText("CLUBBOX_END_HYPE_GENERATED")
  hypeText = hypeText:gsub("%${HYPE}", self.currentHype)
  self.HypeBlob.Text("text"):SetString(hypeText)
  self.RewardBlob.Text("text"):SetString(earnedTier .. "/" .. rewardTrackData.totalLevels)
end
function ClubboxProgress:onTick(dt)
  self.TimeFrame.Text:GetVar("text"):SetString(game.timeToString(game.clubboxShortestTimeAvail(), true))
end
function ClubboxProgress:close()
  self:root():popPopUp()
end
function ClubboxProgress.Bg.Touch:onTouchDrag(element, x, y, relX, relY, dx, dy)
  local scrollOffset = self:parent():parent().PathMap:GetVar("xOffset"):GetFloat() + dx
  scrollOffset = lua_sys.clamp(scrollOffset, self:parent():parent().scrollLimit, 0)
  self:parent():parent().PathMap:GetVar("xOffset"):SetFloat(scrollOffset)
end
return ClubboxProgress
