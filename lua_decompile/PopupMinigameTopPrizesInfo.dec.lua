local RewardListUI = include("RewardListUI")
local PopupMinigameTopPrizesInfo = {
  Bg = {
    Sprite = {},
    Touch = {}
  },
  TitleFrame = {
    Sprite = {},
    Text = {}
  },
  Rewards = {}
}
local AUTOSCROLL_DELAY = 0
local AUTOSCROLL_SPEED = 15 * game.windowScaleY()
local START_AND_END_BUFFER = 15 * game.windowScaleY()
local HEIGHT_OFFSET = 60 * game.windowScaleY()
local WIDTH_OFFSET = 100 * game.windowScaleY()
local maxWidth = 410 * game.windowScaleY()
function PopupMinigameTopPrizesInfo:onPostInit()
  if self.Bg.Sprite:GetVar("width"):GetFloat() > maxWidth then
    self.Bg.Sprite:GetVar("width"):SetFloat(maxWidth)
    self.Rewards:GetVar("width"):SetFloat(maxWidth)
  end
  self.autoScrollEnabled = true
  self.autoScrollTimer = 0
  self.autoScrollDirection = -1
  local vars = {
    scale = 0.6 * game.windowScaleY() / game.hudScale(),
    layer = "FrontClipping"
  }
  local rewards
  local minigameContext = game.minigameContext()
  if minigameContext then
    if minigameContext:minigameId() == game.MinigameId_DIPSTER_DIG then
      rewards = {
        {
          type = game.LootType_Monster,
          id = 2069
        },
        {
          name = "MINIGAME_REWARD_COMMON_DIPSTERS",
          value = 1,
          animFile = "battle_buttons_anim.bin",
          animName = "minigame_dipsters"
        },
        {
          type = game.LootType_Monster,
          id = 2058
        },
        {
          type = game.LootType_CardPack,
          id = 5
        },
        {
          type = game.LootType_Monster,
          id = 2064
        },
        {
          type = game.LootType_CardPack,
          id = 4
        },
        {
          type = game.LootType_Structure,
          id = 2063
        },
        {
          type = game.LootType_ClubboxTokens,
          amount = 5
        }
      }
    else
      print("PopupMinigameTopPrizesInfo: UNSUPPORTED MINIGAME", minigameContext:minigameId())
    end
  end
  if rewards ~= nil then
    rewards = RewardListUI.ConvertToRewardsTable(rewards)
    for i = 1, #rewards do
      local rewardItem = menu:addTemplateElementEx("template_daily_cumulative_login_reward", "rewardSprite" .. i, self.Rewards, vars)
      rewardItem:Init(rewards[i], i, {variation = 0, hideAmounts = true})
      rewardItem:relativeTo(self.Rewards)
      rewardItem:setRelativeObjectAnchors(lua_sys.LEFT, lua_sys.VCENTER)
      rewardItem:calculatePosition()
      rewardItem:init()
      rewardItem:setPositionBroadcast(true)
      rewardItem:postInit()
      local isTop = i % 2 == 1
      local column = math.ceil(i / 2) - 1
      local x = column * WIDTH_OFFSET + START_AND_END_BUFFER
      local y = isTop and -HEIGHT_OFFSET or HEIGHT_OFFSET
      rewardItem:setOrientation(lua_sys.MenuOrientation(x, y, 0, lua_sys.LEFT, lua_sys.VCENTER))
      rewardItem:updateAlpha(1)
    end
    self.scrollLimit = self.Bg:absW() - math.ceil(#rewards * 0.5) * WIDTH_OFFSET
    self.Rewards:GetVar("xOffset"):SetFloat(0)
    local clippingPadding = 4 * game.windowScaleY()
    game.setClipping("FrontClipping", (self.Bg:absX() + clippingPadding) * lua_sys.deviceScaleX(), (self.Bg:absY() + clippingPadding) * lua_sys.deviceScaleY(), (self.Bg:absW() - clippingPadding * 2) * lua_sys.deviceScaleX(), (self.Bg:absH() - clippingPadding * 2) * lua_sys.deviceScaleY())
  end
  lua_sys.playSoundFx("audio/sfx/minigame01-prize_menu_open.ogg")
end
function PopupMinigameTopPrizesInfo:onTick(dt)
  if self.autoScrollEnabled and self.scrollLimit + AUTOSCROLL_SPEED < 0 then
    self.autoScrollTimer = self.autoScrollTimer + dt
    if self.autoScrollTimer >= AUTOSCROLL_DELAY then
      local maxOffset = self.scrollLimit
      local newOffset = self.Rewards:GetVar("xOffset"):GetFloat() + self.autoScrollDirection * AUTOSCROLL_SPEED * dt
      if maxOffset >= newOffset or newOffset ~= newOffset then
        newOffset = maxOffset
        self.autoScrollDirection = 1
      elseif newOffset >= 0 then
        newOffset = 0
        self.autoScrollDirection = -1
      end
      self.Rewards:GetVar("xOffset"):SetFloat(newOffset)
    end
  end
end
function PopupMinigameTopPrizesInfo:close()
  self:root():popPopUp()
end
function PopupMinigameTopPrizesInfo.Bg.Touch:onTouchDrag(element, x, y, relX, relY, dx, dy)
  local baseMenu = self:parent():parent()
  if baseMenu.scrollLimit < 0 and dx ~= 0 then
    local scrollOffset = baseMenu.Rewards:GetVar("xOffset"):GetFloat() + dx
    baseMenu.autoScrollDirection = dx / math.abs(dx)
    scrollOffset = lua_sys.clamp(scrollOffset, baseMenu.scrollLimit, 0)
    baseMenu.Rewards:GetVar("xOffset"):SetFloat(scrollOffset)
  end
end
function PopupMinigameTopPrizesInfo.Bg.Touch:onTouchDown(element, x, y)
  local baseMenu = self:parent():parent()
  baseMenu.autoScrollEnabled = false
end
function PopupMinigameTopPrizesInfo.Bg.Touch:onTouchUp(element, x, y)
  local baseMenu = self:parent():parent()
  baseMenu.autoScrollEnabled = true
  baseMenu.autoScrollTimer = 0
end
function PopupMinigameTopPrizesInfo.Bg.Touch:onTouchRelease(element, x, y)
  local baseMenu = self:parent():parent()
  baseMenu.autoScrollEnabled = true
  baseMenu.autoScrollTimer = 0
end
return PopupMinigameTopPrizesInfo
