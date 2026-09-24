local ScrollingListHelper = include("ScrollingListHelper")
local RewardListUI = {
  Swiper = {},
  Touch = {}
}
local AUTOSCROLL_DELAY = 0
local AUTOSCROLL_SPEED = 40
function RewardListUI:onInit()
  self.alpha = 1
  self.items = {}
  self.hasCardPackReward = false
  self.hasClubboxUnlock = false
  self.hasCurIslandThemeUnlock = false
  ScrollingListHelper.ListInit(self, {
    direction = lua_sys.MenuSwipeComponent_SwipeDirectionHortizontal,
    alwaysBounce = 0
  })
  self.autoScrollEnabled = true
  self.autoScrollTimer = 0
  self.autoScrollDirection = -1
end
local GetTestRewards = function()
  local rewards = {}
  table.insert(rewards, {
    id = 0,
    type = 4,
    amount = 500
  })
  table.insert(rewards, {
    id = 0,
    type = 4,
    amount = 500
  })
  table.insert(rewards, {
    type = 11,
    id = 64,
    amount = 1
  })
  table.insert(rewards, {
    type = 12,
    id = 2,
    amount = 1
  })
  table.insert(rewards, {
    type = 14,
    id = 23,
    amount = 1
  })
  table.insert(rewards, {
    type = 13,
    id = 23,
    amount = 1
  })
  table.insert(rewards, {type = 8, amount = 25})
  return rewards
end
local isTypeEqual = function(a, b)
  return a.type == b.type
end
local rewardProps = {
  [game.LootType_Diamonds] = {order = 1, canGroup = isTypeEqual},
  [game.LootType_Relics] = {order = 2, canGroup = isTypeEqual},
  [game.LootType_ClubboxTokens] = {order = 3, canGroup = isTypeEqual},
  [game.LootType_MinigameTokens] = {order = 4, canGroup = isTypeEqual},
  [game.LootType_Shards] = {order = 5, canGroup = isTypeEqual},
  [game.LootType_EggWildcards] = {order = 6, canGroup = isTypeEqual},
  [game.LootType_Keys] = {order = 7, canGroup = isTypeEqual},
  [game.LootType_Coins] = {order = 8, canGroup = isTypeEqual},
  [game.LootType_Food] = {order = 9, canGroup = isTypeEqual},
  [game.LootType_Starpower] = {order = 10, canGroup = isTypeEqual},
  [game.LootType_Medals] = {order = 11, canGroup = isTypeEqual},
  [game.LootType_Xp] = {order = 12, canGroup = isTypeEqual},
  [game.LootType_Monster] = {
    order = 13,
    canGroup = function(a, b)
      return false
    end
  },
  [game.LootType_Costume] = {
    order = 14,
    canGroup = function(a, b)
      return false
    end
  },
  [game.LootType_Structure] = {
    order = 15,
    canGroup = function(a, b)
      return false
    end
  },
  [game.LootType_IslandTheme] = {
    order = 16,
    canGroup = function(a, b)
      return false
    end
  },
  [game.LootType_Buff] = {
    order = 17,
    canGroup = function(a, b)
      return false
    end
  },
  [game.LootType_ClubboxUnlock] = {
    order = 18,
    canGroup = function(a, b)
      return false
    end
  },
  [game.LootType_CardPack] = {
    order = 19,
    canGroup = function(a, b)
      return isTypeEqual(a, b) and a.id == b.id
    end
  }
}
function RewardListUI.CanBeGrouped(reward1, reward2)
  local f = rewardProps[reward1.type]
  if f and f.canGroup then
    return f.canGroup(reward1, reward2)
  end
  return false
end
function RewardListUI.GroupRewards(rewards)
  local i = 1
  while i <= #rewards do
    local j = 1
    while j <= #rewards do
      if i ~= j and RewardListUI.CanBeGrouped(rewards[i], rewards[j]) then
        rewards[i].amount = rewards[i].amount + rewards[j].amount
        table.remove(rewards, j)
      else
        j = j + 1
      end
    end
    i = i + 1
  end
end
function RewardListUI.SortRewards(rewards)
  table.sort(rewards, function(a, b)
    local aId = a.id or 0
    local bId = b.id or 0
    if a.type == b.type then
      return aId < bId
    end
    local aProps = rewardProps[a.type]
    local bProps = rewardProps[b.type]
    if aProps == nil then
      return false
    end
    if bProps == nil then
      return true
    end
    if aProps.order == bProps.order then
      return aId < bId
    end
    return aProps.order < bProps.order
  end)
end
function RewardListUI.ConvertToRewardsTable(rewards)
  if type(rewards) ~= "table" then
    local tableRewards = {}
    for i = 0, rewards:size() - 1 do
      do
        local mailId = 0
        if rewards[i].getExtraLong then
          mailId = rewards[i]:getExtraLong("mail_id")
        end
        local isBoxFilled = false
        if rewards[i].getExtraBool then
          isBoxFilled = rewards[i]:getExtraBool("box_filled")
        end
        local function getExtraBool(reward, key)
          if key == "box_filled" then
            return isBoxFilled
          end
          return false
        end
        local function getExtraLong(reward, key)
          if key == "mail_id" then
            return mailId
          end
          return 0
        end
        table.insert(tableRewards, {
          type = rewards[i].type,
          id = rewards[i].id,
          amount = rewards[i].amount,
          getExtraBool = getExtraBool,
          getExtraLong = getExtraLong
        })
      end
    end
    rewards = tableRewards
  end
  return rewards
end
function RewardListUI:GetCurrentOffset()
  return ScrollingListHelper.GetCurrentOffset(self.Swiper, self)
end
function RewardListUI:SetCurrentOffset(offset)
  return ScrollingListHelper.SetCurrentOffset(self.Swiper, self, offset)
end
function RewardListUI:GetContentSize()
  return ScrollingListHelper.GetContentSize(self.Swiper, self)
end
function RewardListUI:GetViewSize()
  return ScrollingListHelper.GetViewSize(self.Swiper, self)
end
function RewardListUI:populate(rewards, options)
  rewards = rewards or GetTestRewards()
  rewards = RewardListUI.ConvertToRewardsTable(rewards)
  RewardListUI.GroupRewards(rewards)
  RewardListUI.SortRewards(rewards)
  options = options or {}
  local function createFunc(idx, entryName)
    idx = idx + 1
    local rewardData = rewards[idx]
    local vars = {
      scale = self:templateVars().scale,
      layer = self:templateVars().layer
    }
    local rewardItem = menu:addTemplateElementEx("template_daily_cumulative_login_reward", entryName, self, vars)
    rewardItem:Init(rewardData, idx, options)
    rewardItem:setParent(self)
    rewardItem:relativeTo(self)
    rewardItem:setOrientation(lua_sys.MenuOrientation(0, -16 * game.hudScale(), 0, lua_sys.LEFT, lua_sys.VCENTER))
    rewardItem:setRelativeObjectAnchors(lua_sys.HCENTER, lua_sys.VCENTER)
    rewardItem:calculatePosition()
    rewardItem:init()
    rewardItem:setPositionBroadcast(true)
    rewardItem:postInit()
    if rewardItem.SoundFile then
      game.playSound(rewardItem.SoundFile)
    end
    if rewardData.type == game.LootType_CardPack then
      self.hasCardPackReward = true
    elseif rewardData.type == game.LootType_ClubboxUnlock then
      self.hasClubboxUnlock = true
    elseif rewardData.type == game.LootType_IslandTheme then
      local themeId = rewardData.id
      local islandId = game.islandIdForIslandTheme(themeId)
      if islandId == game.currentIsland() and themeId ~= game.worldContext():currentlyLoadedThemeId() then
        self.hasCurIslandThemeUnlock = true
      end
    end
    table.insert(self.items, rewardItem)
    return rewardItem
  end
  ScrollingListHelper.ListPopulate(self, #rewards, createFunc)
end
function RewardListUI:onTick(dt)
  if self.autoScrollEnabled then
    self.autoScrollTimer = self.autoScrollTimer + dt
    if self.autoScrollTimer >= AUTOSCROLL_DELAY then
      local currentOffset = self:GetCurrentOffset()
      local contentSize = self:GetContentSize()
      local viewSize = self:GetViewSize()
      if viewSize < contentSize - AUTOSCROLL_SPEED then
        local maxOffset = contentSize - viewSize
        local newOffset = currentOffset + self.autoScrollDirection * AUTOSCROLL_SPEED * dt
        if newOffset <= -maxOffset then
          newOffset = -maxOffset
          self.autoScrollDirection = 1
        elseif newOffset >= 0 then
          newOffset = 0
          self.autoScrollDirection = -1
        end
        self:SetCurrentOffset(newOffset)
      end
    end
  end
  ScrollingListHelper.ListTick(self, dt)
  local clipX = self:absX()
  local clipY = self:absY()
  local clipW = self:absW()
  local clipH = self:absH()
  for i, item in ipairs(self.items) do
    item:updateAlpha(self.alpha)
    item:updateClippingEx(clipX, clipY, clipW, clipH)
  end
end
function RewardListUI.Swiper:refresh(element)
  ScrollingListHelper.SwiperRefresh(self, element)
end
function RewardListUI.Swiper:onTick(element, dt)
  ScrollingListHelper.SwiperTick(self, element, dt)
end
function RewardListUI.Touch:onTouchDown(element, x, y)
  element.autoScrollEnabled = false
end
function RewardListUI.Touch:onTouchUp(element, x, y)
  element.autoScrollEnabled = true
  element.autoScrollTimer = 0
end
function RewardListUI.Touch:onTouchRelease(element, x, y)
  print("Enable auto scroll")
  element.autoScrollEnabled = true
  element.autoScrollTimer = 0
end
return RewardListUI
