local FlyingIcon = include("FlyingIcon")
local FloatingNumber = include("FloatingNumber")
local RewardProperties = include("RewardProperties")
local MinigameRewards = {}
local delayOnStart = 0.66
local layer = "FrontPopUps"
local shouldShowText = function(rewardType)
  if rewardType == game.LootType_CardPack then
    return false
  end
  return true
end
function MinigameRewards:ShowReward(x, y, scale, rewardType, rewardId, rewardAmount)
  local rewardData = {
    type = rewardType,
    id = rewardId,
    amount = rewardAmount
  }
  local appearance = RewardProperties:getRewardAppearance(rewardData)
  if appearance then
    do
      local iconName = appearance.iconName
      if type(iconName) == "function" then
        iconName = iconName()
      end
      local floatingNumber
      if shouldShowText(rewardData.type) then
        floatingNumber = FloatingNumber.Create({
          parent = floatingNumber or game.minigameContext():menu(),
          x = x,
          y = y,
          layer = layer,
          delay = delayOnStart,
          number = rewardAmount,
          color = appearance.tint,
          scale = scale
        })
      end
      local iconSize = appearance.iconScale or 0.65 * game.hudScale()
      local iconStartX = x - (floatingNumber and floatingNumber.element.Text:absW() * 0.5 or 0)
      local iconStartY = y
      local flyingIcon = FlyingIcon.Create({
        parent = game.minigameContext():menu(),
        layer = layer,
        spriteName = iconName,
        sheetName = appearance.iconSheet,
        size = iconSize,
        delayOnStart = delayOnStart,
        srcX = iconStartX,
        srcY = iconStartY,
        destX = appearance.iconDestX,
        destY = appearance.iconDestY,
        collectSound = appearance.soundFile,
        onComplete = appearance.onComplete or nil,
        onUpdate = function(icon, _x, _y, _a, progress)
          if progress == 0 then
            local totalTime = icon.delayOnStart
            local curTime = icon.delayOnStart - icon.remainingDelayTime
            local currentXOffset = _x
            local spawnOffsetY = 32 * game.hudScale()
            local currentYOffset = iconStartY + lua_sys.Quadratic_EaseOut(curTime, spawnOffsetY, -spawnOffsetY, totalTime)
            local currentSize = lua_sys.Back_EaseOut(curTime, 0, iconSize, totalTime)
            if floatingNumber then
              currentXOffset = 0
              currentYOffset = 0
              icon.srcX = currentXOffset
              icon.srcY = currentYOffset
              icon:CalculateControlPoints()
            end
            icon.element:GetVar("xOffset"):SetFloat(currentXOffset)
            icon.element:GetVar("yOffset"):SetFloat(currentYOffset)
            icon.element.Sprite:GetVar("alpha"):SetFloat(_a)
            icon.element.Sprite:GetVar("size"):SetFloat(currentSize)
          else
            if icon.isAttached then
              icon.element:relativeTo(game.minigameContext():menu())
              icon.element:setRelativeObjectAnchors(lua_sys.TOP, lua_sys.LEFT)
              icon.element:setOrientationAnchors(lua_sys.HCENTER, lua_sys.VCENTER)
              icon.srcX = iconStartX - (floatingNumber and floatingNumber.element.Text:absW() * 0.5 or 0)
              icon.srcY = iconStartY
              icon.isAttached = false
              _x = icon.srcX
              _y = icon.srcY
            end
            icon.element:GetVar("xOffset"):SetFloat(_x)
            icon.element:GetVar("yOffset"):SetFloat(_y)
            icon.element.Sprite:GetVar("alpha"):SetFloat(_a)
            local newSize = lua_sys.Quadratic_EaseOut(progress, iconSize, -iconSize * 0.5, 1)
            icon.element.Sprite:GetVar("size"):SetFloat(newSize)
          end
        end
      })
      if floatingNumber then
        flyingIcon.element:relativeTo(floatingNumber.element)
        flyingIcon.element:setOrientationAnchors(lua_sys.RIGHT, lua_sys.VCENTER)
        flyingIcon.element:setRelativeObjectAnchors(lua_sys.LEFT, lua_sys.VCENTER)
        flyingIcon.isAttached = true
      end
    end
  end
end
return MinigameRewards
