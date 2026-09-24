local OldOffsetTransition = include("MenuElementPositionOffsetTransition")
local FadeTransition = include("FadeTransition")
local MenuHelpers = include("MenuHelpers")
local ScrollingPatternShader = include("ShaderScrollingPattern")
local ShaderOutline = include("ShaderOutline")
local Tweener = include("Tweener")
local ShaderShiny = include("ShaderShinyFont1")
local root
local CloseButtonBehaviour = {}
local CollectButtonBehaviour = {
  Touch = {}
}
local RewardsBehaviour = {
  Faders = {},
  Fade = {
    Touch = {}
  },
  Flash = {}
}
local TestPanelBehaviour = {}
local DCL = {
  MainPanel = {
    CloseButton = CloseButtonBehaviour,
    HelpButton = {},
    CatchUpButton = {},
    Layout = {
      Sprite = {},
      Reveal = {},
      Shadow = {}
    },
    TitleFrame = {
      Sprite = {}
    },
    TitleText = {
      Text = {}
    },
    CollectButton = CollectButtonBehaviour,
    NextCollectMessage = {},
    NextCollectFrame = {},
    Tooltip = {},
    CompletedMessage = {
      Text = {}
    },
    CompletedMessageDetails = {
      Text = {}
    }
  },
  Rewards = RewardsBehaviour,
  ViewButton = {
    Sprite = {},
    Touch = {}
  },
  QA_TestPanel = TestPanelBehaviour
}
local playerState
function DCL:onInit()
  root = self
  _G.dcl_popup = self
  self:RefreshState()
  self:SetupGenericListener(game.engineReceiver(), "game::msg::MsgUpdatePlayerDailyCumulativeLogin", "gotMsgUpdatePlayerDailyCumulativeLogin")
  self:SetupGenericListener(game.engineReceiver(), "game::msg::MsgConfirmationSubmission", "gotMsgConfirmationSubmission")
end
function DCL:onPostInit()
  if game.hasQuest("FIRST_COLOSSAL_CALENDAR_VISIT") then
    game.displayNotification("FIRST_COLOSSAL_CALENDAR_VISIT")
  end
  if not game.isQABuild() and not game.isDebugBuild() then
    self:RemoveElement(self.QA_TestPanel)
  end
  self:Show()
end
function DCL:onDestroy()
  _G.dcl_popup = nil
end
function DCL:onTick(dt)
  if self.MainPanel.NextCollectMessage.Text:GetVar("visible"):GetInt() == 1 then
    local timeRemaining = (playerState:nextCollect() - game.serverTime()) / 1000
    if timeRemaining > 0 then
      local txt = LOC("NEXT_COLLECT_MESSAGE")
      txt = txt:gsub("%${TIME}", game.timeToString(timeRemaining))
      self.MainPanel.NextCollectMessage.Text:GetVar("text"):SetString(txt)
    else
      self.MainPanel.NextCollectMessage.Text:GetVar("visible"):SetInt(0)
      self.MainPanel.NextCollectFrame.Sprite:GetVar("visible"):SetInt(0)
      self.MainPanel.CollectButton:setVisible()
      self.MainPanel.CatchUpButton:setInvisible()
    end
  end
end
function DCL:queuePop()
  if self.Rewards.isShowing then
    self.Rewards:Hide()
    return
  end
  self:Hide()
end
function DCL:Show()
  self.Fade:Show()
  self.MainPanel:Show()
  lua_sys.playSoundFx("audio/sfx/menu_slide.wav")
end
function DCL:Hide()
  self.MainPanel:Hide()
  self.Fade:Hide()
  lua_sys.playSoundFx("audio/sfx/menu_slide.wav")
end
function DCL:RefreshState()
  local calendarId = 0
  local awakener = game.FindAwakener()
  if awakener then
    calendarId = awakener:getCalendarId()
  end
  playerState = game.player():getDailyCumulativeLogin()
  local calendar = game.getDailyCumulativeLoginData(calendarId)
  if 0 < calendar.id and playerState:calendar() == calendarId then
    local rewardIdx = playerState:reward()
    local reward = calendar:getReward(rewardIdx)
    local nextCollect = playerState:nextCollect()
    if 0 < nextCollect - game.serverTime() then
      self.MainPanel.TitleFrame.Sprite:GetVar("visible"):SetInt(1)
      self.MainPanel.TitleText.Text:GetVar("visible"):SetInt(1)
      print("show next collect!")
      self.MainPanel.NextCollectMessage.Text:GetVar("visible"):SetInt(1)
      self.MainPanel.NextCollectFrame.Sprite:GetVar("visible"):SetInt(1)
      self.MainPanel.CollectButton:setInvisible()
      self.MainPanel.CloseButton:setVisible()
      self.MainPanel.CloseButton:GetVar("xOffset"):SetFloat(4 * game.hudScale())
      self.MainPanel.HelpButton:setVisible()
      if playerState:catchUpDaysUsed() < playerState:catchUpDaysTotal() then
        self.MainPanel.CatchUpButton:setVisible()
      else
        self.MainPanel.CatchUpButton:setInvisible()
      end
    else
      self.MainPanel.TitleFrame.Sprite:GetVar("visible"):SetInt(1)
      self.MainPanel.TitleText.Text:GetVar("visible"):SetInt(1)
      self.MainPanel.NextCollectMessage.Text:GetVar("visible"):SetInt(0)
      self.MainPanel.NextCollectFrame.Sprite:GetVar("visible"):SetInt(0)
      self.MainPanel.CollectButton:setVisible()
      self.MainPanel.CloseButton:setVisible()
      self.MainPanel.CloseButton:GetVar("xOffset"):SetFloat(4 * game.hudScale())
      self.MainPanel.HelpButton:setVisible()
      self.MainPanel.CatchUpButton:setInvisible()
    end
    self.MainPanel.CompletedMessage.Text:GetVar("visible"):SetInt(0)
    self.MainPanel.CompletedMessageDetails.Text:GetVar("visible"):SetInt(0)
  else
    self.MainPanel.TitleFrame.Sprite:GetVar("visible"):SetInt(0)
    self.MainPanel.TitleText.Text:GetVar("visible"):SetInt(0)
    self.MainPanel.CollectButton:setInvisible()
    self.MainPanel.CloseButton:setVisible()
    self.MainPanel.CloseButton:GetVar("xOffset"):SetFloat(4 * game.hudScale())
    self.MainPanel.HelpButton:setInvisible()
    self.MainPanel.CatchUpButton:setInvisible()
    self.MainPanel.NextCollectMessage.Text:GetVar("visible"):SetInt(0)
    self.MainPanel.NextCollectFrame.Sprite:GetVar("visible"):SetInt(0)
    self.MainPanel.CompletedMessage.Text:GetVar("visible"):SetInt(1)
    self.MainPanel.CompletedMessageDetails.Text:GetVar("visible"):SetInt(1)
  end
end
function DCL:HideButtons()
  self.MainPanel.CollectButton:setInvisible()
  self.MainPanel.CloseButton:setInvisible()
  self.MainPanel.HelpButton:setInvisible()
  self.MainPanel.CatchUpButton:setInvisible()
end
function CloseButtonBehaviour:onClose()
  root:Hide()
end
function DCL:gotMsgUpdatePlayerDailyCumulativeLogin(msg)
  print("Got Server Response:", msg:success())
  if msg:success() then
    local rewards = msg:rewards()
    if msg:completed() then
      self.MainPanel:PlayRevealEffect(function()
        self.Rewards:ShowCompletion()
      end)
    elseif rewards:size() > 0 then
      do
        local data = {}
        for i = 0, rewards:size() - 1 do
          local reward = rewards[i]
          table.insert(data, {
            id = reward.id,
            type = reward.type,
            amount = reward.amount
          })
        end
        self.MainPanel:PlayRevealEffect(function()
          self.Rewards:Show(data)
        end)
      end
    else
      self:RefreshState()
      self.MainPanel:populate()
    end
  else
    self:root():popPopUp()
    game.displayNotification("PROBLEM_CLAIMING_REWARD")
  end
end
function DCL:gotMsgConfirmationSubmission(msg)
  print("=== Got msg:", msg.messageID, msg.choice)
  if msg.messageID == "GET_DIAMONDS" and msg.choice == false then
    self:RefreshState()
  end
end
function DCL.MainPanel:onInit()
  self.isShowingTooltip = false
  self.willShowTooltip = false
  self.tooltipDelay = 0
  self.hideTooltip = false
  if ShaderOutline then
    ShaderOutline:getUniform("tintA"):setColor(0, 0, 0, 1)
    ShaderOutline:getUniform("tintB"):setColor(0.05, 0.05, 0.05, 1)
  end
end
function DCL.MainPanel:onPostInit()
  self:populate()
end
local outlineColor = lua_sys.Vector4()
function DCL.MainPanel:onTick(dt)
  dt = math.min(dt, 0.033)
  if not self.isShowingTooltip and self.willShowTooltip and self.tooltipDelay > 0 then
    self.tooltipDelay = self.tooltipDelay - dt
    if self.tooltipDelay <= 0 then
      self.willShowTooltip = false
      self.Tooltip:Show()
      self.isShowingTooltip = true
    end
  end
  if (self.isShowingTooltip or self.willShowTooltip) and self.hideTooltip then
    self.Tooltip:Hide()
    self.isShowingTooltip = false
  end
  self.hideTooltip = false
end
function DCL.MainPanel:Show()
  self:GetVar("xOffset"):SetFloat(0)
  self:GetVar("yOffset"):SetFloat(0)
end
function DCL.MainPanel:Hide()
  self:GetVar("xOffset"):SetFloat(0)
  self:GetVar("yOffset"):SetFloat(lua_sys.screenHeight() * 2)
  self:onDoneHide()
end
function DCL.MainPanel:onDoneHide()
  if root.Rewards.isCompletion or not root.Rewards.isShowing then
    root:root():popPopUp()
  end
end
local number_cache = {}
local decoration_settings = {}
decoration_settings[1] = {
  Deco01 = {
    sprite = "plant_BG_deco_upper_left",
    sheet = "xml_resources/colossal_calendar_plant_sheet.xml"
  },
  Deco02 = {
    sprite = "plant_BG_deco_lower_left",
    sheet = "xml_resources/colossal_calendar_plant_sheet.xml"
  },
  Deco03 = {
    sprite = "plant_BG_deco_upper_right",
    sheet = "xml_resources/colossal_calendar_plant_sheet.xml"
  },
  MoteParticle = "particles/particle_motes.psi",
  MoteImage = "gfx/particles/particle_mote",
  NumberOffsets = {
    piece_08 = {x = 0, y = 8},
    piece_09 = {x = 6, y = -8},
    piece_11 = {x = -4, y = 9},
    piece_14 = {x = 4, y = 11},
    piece_16 = {x = -2, y = 18},
    piece_18 = {x = 0, y = 10},
    piece_21 = {x = 0, y = 8},
    piece_22 = {x = 0, y = 8},
    piece_24 = {x = -12, y = -8},
    piece_28 = {x = -11, y = 18}
  }
}
decoration_settings[2] = {
  Deco01 = {
    sprite = "plant_BG_deco_upper_left",
    sheet = "xml_resources/colossal_calendar_cold_sheet.xml"
  },
  Deco02 = {
    sprite = "plant_BG_deco_lower_left",
    sheet = "xml_resources/colossal_calendar_cold_sheet.xml"
  },
  Deco03 = {
    sprite = "plant_BG_deco_upper_right",
    sheet = "xml_resources/colossal_calendar_cold_sheet.xml"
  },
  MoteParticle = "particles/particle_snow.psi",
  MoteImage = "gfx/particles/particle_snowflake",
  NumberOffsets = {
    piece_07 = {x = 0, y = 14},
    piece_08 = {x = -4, y = 16},
    piece_09 = {x = 6, y = -8},
    piece_11 = {x = -4, y = 9},
    piece_13 = {x = 6, y = 4},
    piece_14 = {x = 4, y = 11},
    piece_16 = {x = -2, y = 18},
    piece_18 = {x = 0, y = 10},
    piece_21 = {x = 0, y = 4},
    piece_22 = {x = 0, y = 8},
    piece_23 = {x = -4, y = 8},
    piece_24 = {x = -6, y = 0},
    piece_25 = {x = -4, y = 8},
    piece_26 = {x = 6, y = 0},
    piece_28 = {x = -6, y = 4}
  }
}
decoration_settings[3] = {
  Deco01 = {
    sprite = "plant_BG_deco_upper_left",
    sheet = "xml_resources/colossal_calendar_air_sheet.xml"
  },
  Deco02 = {
    sprite = "plant_BG_deco_lower_left",
    sheet = "xml_resources/colossal_calendar_air_sheet.xml"
  },
  Deco03 = {
    sprite = "plant_BG_deco_upper_right",
    sheet = "xml_resources/colossal_calendar_air_sheet.xml"
  },
  NumberOffsets = {
    piece_05 = {x = 0, y = 4},
    piece_06 = {x = -6, y = 0},
    piece_08 = {x = 0, y = 8},
    piece_09 = {x = -4, y = 4},
    piece_11 = {x = 0, y = 9},
    piece_12 = {x = -16, y = 10},
    piece_14 = {x = 4, y = 11},
    piece_16 = {x = -2, y = 18},
    piece_18 = {x = 0, y = 10},
    piece_21 = {x = -6, y = 2},
    piece_22 = {x = -8, y = -8},
    piece_24 = {x = -6, y = -8},
    piece_25 = {x = -16, y = 12},
    piece_27 = {x = 8, y = 14},
    piece_28 = {x = -6, y = 4},
    piece_special_01 = {x = -12, y = 0},
    piece_special_03 = {x = 8, y = 8}
  }
}
decoration_settings[4] = {
  Deco01 = {
    sprite = "water_BG_deco_upper_left",
    sheet = "xml_resources/colossal_calendar_water_sheet.xml"
  },
  Deco02 = {
    sprite = "water_BG_deco_lower_left",
    sheet = "xml_resources/colossal_calendar_water_sheet.xml"
  },
  Deco03 = {
    sprite = "water_BG_deco_upper_right",
    sheet = "xml_resources/colossal_calendar_water_sheet.xml"
  },
  MoteParticle = "particles/particle_motes.psi",
  MoteImage = "gfx/particles/particle_bubble",
  NumberOffsets = {
    piece_02 = {x = 0, y = 8},
    piece_08 = {x = 0, y = 8},
    piece_11 = {x = 0, y = 14},
    piece_13 = {x = -6, y = 2},
    piece_14 = {x = 0, y = -6},
    piece_17 = {x = -6, y = 10},
    piece_19 = {x = -10, y = 0},
    piece_21 = {x = -8, y = 8},
    piece_special_03 = {x = -4, y = 8}
  }
}
decoration_settings[5] = {
  Deco01 = {
    sprite = "earth_BG_deco_upper_left",
    sheet = "xml_resources/colossal_calendar_earth_sheet.xml"
  },
  Deco02 = {
    sprite = "earth_BG_deco_lower_left",
    sheet = "xml_resources/colossal_calendar_earth_sheet.xml"
  },
  Deco03 = {
    sprite = "earth_BG_deco_upper_right",
    sheet = "xml_resources/colossal_calendar_earth_sheet.xml"
  },
  MoteParticle = "particles/particle_motes.psi",
  MoteImage = "gfx/particles/particle_mote",
  NumberOffsets = {
    piece_07 = {x = 0, y = 8},
    piece_08 = {x = 0, y = 8},
    piece_11 = {x = 0, y = 8},
    piece_13 = {x = -10, y = 0},
    piece_16 = {x = -10, y = 10},
    piece_17 = {x = 0, y = 8},
    piece_23 = {x = 0, y = 8}
  }
}
function DCL.MainPanel:setupBackground(calendarId)
  local settings = decoration_settings[calendarId]
  if settings then
    self.Decorations.Deco01:GetVar("spriteName"):SetString(settings.Deco01.sprite)
    self.Decorations.Deco01:GetVar("sheetName"):SetString(settings.Deco01.sheet)
    self.Decorations.Deco02:GetVar("spriteName"):SetString(settings.Deco02.sprite)
    self.Decorations.Deco02:GetVar("sheetName"):SetString(settings.Deco02.sheet)
    self.Decorations.Deco03:GetVar("spriteName"):SetString(settings.Deco03.sprite)
    self.Decorations.Deco03:GetVar("sheetName"):SetString(settings.Deco03.sheet)
    if settings.MoteParticle and settings.MoteImage then
      self.Decorations.MotesLeft.Particles:GetVar("psi"):SetString(settings.MoteParticle)
      self.Decorations.MotesLeft.Particles:GetVar("image"):SetString(settings.MoteImage)
      self.Decorations.MotesRight.Particles:GetVar("psi"):SetString(settings.MoteParticle)
      self.Decorations.MotesRight.Particles:GetVar("image"):SetString(settings.MoteImage)
    end
  end
end
function DCL.MainPanel:populate()
  for _, v in ipairs(number_cache) do
    local e = self.Layout:GetElement(v)
    self.Layout:RemoveElement(e)
  end
  number_cache = {}
  self.isFinalPiece = false
  local calendarId = 0
  local awakener = game.FindAwakener()
  if awakener then
    calendarId = awakener:getCalendarId()
  end
  local calendarData = game.getDailyCumulativeLoginData(calendarId)
  if calendarData and 0 < calendarData.id and calendarId >= playerState:calendar() then
    self:setupBackground(calendarData.id)
    local settings = decoration_settings[calendarId] or {}
    local number_offsets = settings.NumberOffsets or {}
    if calendarData.layout ~= "" then
      print("using layout:", calendarData.layout)
      self.Layout.Sprite:GetVar("animationName"):SetString("xml_bin/" .. calendarData.layout)
      self.Layout.Sprite:GetVar("animation"):SetString("calendar_idle")
      self.Layout.Reveal:GetVar("animationName"):SetString("xml_bin/" .. calendarData.layout)
      self.Layout.Reveal:GetVar("visible"):SetInt(0)
      self.Layout.Shadow:GetVar("animationName"):SetString("xml_bin/" .. calendarData.layout)
      self.Layout.Shadow:GetVar("visible"):SetInt(0)
    end
    local animUtil = game.AnimUtil(self.Layout.Sprite)
    for idx = 0, calendarData:getNumRewards() do
      local rewardData = calendarData:getReward(idx)
      local node = rewardData.layoutNode
      if animUtil:hasLayer(node) then
        local pos = animUtil:getPos(node)
        if calendarData.id > playerState:calendar() or idx >= playerState:reward() then
          animUtil:setShader(node, ShaderOutline)
          if calendarData.id == playerState:calendar() and idx == playerState:reward() then
            self.targetNode = node
            if idx == calendarData:getNumRewards() - 1 then
              self.isFinalPiece = true
            end
          end
          local position = animUtil:getPos(node)
          local size = animUtil:getSize(node)
          local animScale = self.Layout.Sprite:scale()
          if not number_offsets[node] then
            local offset = {x = 0, y = 0}
          end
          local px = (position.x + offset.x + size.x * 0.5) * animScale.x
          local py = (position.y + offset.y + size.y * 0.5) * animScale.y
          local numberName = node .. "_number"
          local numberItem = menu:addTemplateElement("template_daily_cumulative_login_number", numberName, self.Layout)
          numberItem:relativeTo(self.Layout)
          numberItem:setOrientation(lua_sys.MenuOrientation(0, 0, 0, lua_sys.HCENTER, lua_sys.VCENTER))
          numberItem:setRelativeObjectAnchors(lua_sys.HCENTER, lua_sys.VCENTER)
          numberItem:calculatePosition()
          numberItem:init()
          numberItem:setPositionBroadcast(true)
          numberItem:postInit()
          numberItem:GetVar("xOffset"):SetFloat(px)
          numberItem:GetVar("yOffset"):SetFloat(py)
          numberItem.Number.Text:GetVar("text"):SetString("" .. idx + 1)
          if node:find("special") then
            numberItem.Number.Text:setColor(0.34, 0.72, 0)
            numberItem.Number.Text:GetVar("size"):SetFloat(0.375 * game.hudScale())
          elseif node:find("final") then
            if ShaderShiny then
              numberItem.Number.Text:setShader(ShaderShiny)
            end
            numberItem.Number.Text:setColor(1, 0.64, 0)
            numberItem.Number.Text:GetVar("size"):SetFloat(0.6 * game.hudScale())
          else
            numberItem.Number.Text:setColor(0.45, 0.45, 0.45)
            numberItem.Number.Text:GetVar("size"):SetFloat(0.25 * game.hudScale())
          end
          table.insert(number_cache, numberName)
        else
          animUtil:setShader(node, nil)
        end
      end
    end
    animUtil:resetAnim()
  elseif calendarData and 0 < calendarData.id then
    self:setupBackground(calendarData.id)
    if calendarData.layout ~= "" then
      print("using layout:", calendarData.layout)
      self.Layout.Sprite:GetVar("animationName"):SetString("xml_bin/" .. calendarData.layout)
    end
    self.Layout.Sprite:GetVar("animation"):SetString("calendar_complete")
    local animUtil = game.AnimUtil(self.Layout.Sprite)
    animUtil:setTime(2)
  else
    print("No calendar?")
  end
end
function DCL.MainPanel:PlayRevealEffect(onDoneShow)
  local animUtil = game.AnimUtil(self.Layout.Sprite)
  local position = animUtil:getPos(self.targetNode)
  local size = animUtil:getSize(self.targetNode)
  self.Layout.Reveal:GetVar("visible"):SetInt(1)
  self.Layout.Reveal:GetVar("animation"):SetString("calendar_" .. self.targetNode)
  local revealAnimUtil = game.AnimUtil(self.Layout.Reveal)
  revealAnimUtil:setTime(0.88)
  self.Layout.Spiral = include("Spiral"):new({
    centerX = position.x + size.x * 0.5,
    centerY = position.y + size.y * 0.5,
    duration = 3,
    startRadians = math.pi * 4.5,
    factorStart = 20 * game.hudScale(),
    ease = lua_sys.Linear_EaseNone,
    easeR = lua_sys.Quadratic_EaseIn,
    onUpdate = function(x, y, t)
      self.Layout.Reveal:GetVar("xOffset"):SetFloat(x)
      self.Layout.Reveal:GetVar("yOffset"):SetFloat(y)
    end,
    onDoneShow = function()
      self.Layout.Reveal:GetVar("animation"):SetString("calendar_" .. self.targetNode)
      lua_sys.playSoundFx("audio/sfx/colossalcalendar_unlockpiece.wav")
      animUtil:setShader(self.targetNode, nil)
      animUtil:resetAnim()
      local numberElement = self.Layout:GetElement(self.targetNode .. "_number")
      self.Layout:RemoveElement(numberElement)
      self.Layout.Tweener:activate()
    end
  })
  self.Layout.Tweener = Tweener:new({
    duration = 2.5,
    onDone = function()
      self.Layout.Reveal:GetVar("visible"):SetInt(0)
      if self.isFinalPiece then
        self.Layout.Sprite:GetVar("animation"):SetString("calendar_complete")
        lua_sys.playSoundFx("audio/sfx/colossalcalendar_complete.wav")
        self.isFinalPiece = false
        self.Layout.Tweener:activate()
      elseif onDoneShow then
        onDoneShow()
      end
    end
  })
  self.Layout.Shadow:GetVar("visible"):SetInt(1)
  self.Layout.Shadow:GetVar("animation"):SetString("calendar_" .. self.targetNode)
  local shadowAnimUtil = game.AnimUtil(self.Layout.Reveal)
  shadowAnimUtil:setTime(0.88)
  local shadowStartScale = 0.45 * game.menuScaleY() * 1.5
  local shadowStartOffsetX = 0
  local shadowStartOffsetY = 32
  self.Layout.ShadowTween = Tweener:new({
    duration = self.Layout.Spiral.duration - 0.5,
    onUpdate = function(easedTime)
      local x = self.Layout.Spiral.x
      local y = self.Layout.Spiral.y
      local shadowScale = lerp(shadowStartScale, 0.45 * game.menuScaleY(), easedTime)
      local shadowOffsetX = lerp(shadowStartOffsetX, 0, easedTime)
      local shadowX = x + shadowOffsetX
      local shadowOffsetY = lerp(shadowStartOffsetY, 0, easedTime)
      local shadowY = y + shadowOffsetY
      self.Layout.Shadow:GetVar("xOffset"):SetFloat(shadowX)
      self.Layout.Shadow:GetVar("yOffset"):SetFloat(shadowY)
    end,
    onDone = function()
      self.Layout.Shadow:GetVar("visible"):SetInt(0)
    end
  })
  self.Layout.Spiral:Show()
  self.Layout.Spiral:Tick(0)
  self.Layout.ShadowTween:activate()
  self.Layout.ShadowTween:Tick(0)
end
function DCL.MainPanel.Layout:onTick(dt)
  if self.Spiral then
    self.Spiral:Tick(dt)
  end
  if self.Tweener then
    self.Tweener:Tick(dt)
  end
  if self.ShadowTween then
    self.ShadowTween:Tick(dt)
  end
end
function CollectButtonBehaviour.Touch:onTouchUp(element, x, y)
  self:super_onTouchUp(element, x, y)
  root:HideButtons()
  root.ViewButton.Sprite:GetVar("visible"):SetInt(0)
  root.ViewButton.Touch:GetVar("enabled"):SetInt(0)
  game.collectDailyCumulativeReward(0)
end
function DCL.ViewButton:onPostInit()
  self.inViewMode = false
  self:Refresh()
end
function DCL.ViewButton:Refresh()
  if self.inViewMode then
    self.Sprite:GetVar("spriteName"):SetString("button_show_hud")
  else
    self.Sprite:GetVar("spriteName"):SetString("button_hide_hud")
  end
end
function DCL.ViewButton.Touch:onTouchUp(element, x, y)
  element.inViewMode = not element.inViewMode
  element:Refresh()
  if element.inViewMode then
    root:HideButtons()
    root.MainPanel.TitleFrame.Sprite:GetVar("visible"):SetInt(0)
    root.MainPanel.TitleText.Text:GetVar("visible"):SetInt(0)
    root.MainPanel.NextCollectMessage.Text:GetVar("visible"):SetInt(0)
    root.MainPanel.NextCollectFrame.Sprite:GetVar("visible"):SetInt(0)
    root.MainPanel.CompletedMessage.Text:GetVar("visible"):SetInt(0)
    root.MainPanel.CompletedMessageDetails.Text:GetVar("visible"):SetInt(0)
  else
    root:RefreshState()
  end
end
function RewardsBehaviour:onInit()
  self.isShowing = false
  self.isDoneSequence = false
  self.sequenceTimeRemaining = 0
  local width = lua_sys.screenWidth()
  local height = 220 * game.hudScale()
  local bgSprite = self.RewardsBG.Sprite
  bgSprite:GetVar("spriteName"):SetString("gfx/menu/gradient_bg_colosseye")
  bgSprite:setScale(lua_sys.Vector2(width / 1024, height / 4))
  bgSprite:GetVar("layer"):SetString("Tutorial")
  bgSprite:GetVar("repeating"):SetInt(1)
  local bgPattern = self.RewardsBG.Pattern
  bgPattern:GetVar("spriteName"):SetString("gfx/menu/bg_symbols_colosseye")
  bgPattern:setScale(lua_sys.Vector2(width / 128, height / 128))
  bgPattern:GetVar("layer"):SetString("Tutorial")
  bgPattern:GetVar("repeating"):SetInt(1)
  bgPattern:GetVar("additive"):SetInt(1)
  bgPattern.maxFade = 0.8
  if ScrollingPatternShader then
    ScrollingPatternShader:getUniform("u_TexParams"):setVec4(lua_sys.Vector4(1, 1, 8 * (width / height), 8))
  end
  bgPattern:setShader(ScrollingPatternShader)
  table.insert(self.Faders, bgSprite)
  table.insert(self.Faders, bgPattern)
  table.insert(self.Faders, self.ClaimInfo.Text)
  self.ContinueLabel.Text.FadeTransition = FadeTransition:new({
    delayOnShow = 1,
    duration = 1,
    maxFade = 1,
    onUpdate = function(alpha)
      self.ContinueLabel.Text:GetVar("alpha"):SetFloat(alpha)
    end
  })
  self.ContinueLabel.Text.FadeTransition:SetAlpha(0)
  local transitionDuration = 0.5
  local function initBar(e, startX, endX)
    e:GetVar("xOffset"):SetFloat(startX)
    OldOffsetTransition.OnInit(e, {
      startX = startX,
      endX = endX,
      duration = transitionDuration
    })
    table.insert(self.Faders, e.Sprite)
  end
  initBar(self.RewardsTopBar, lua_sys.screenWidth(), 0)
  initBar(self.RewardsBottomBar, -lua_sys.screenWidth(), 0)
  self.FadeTransition = FadeTransition:new({
    duration = transitionDuration,
    ease = lua_sys.Quadratic_EaseIn,
    onDoneHide = function()
      for _, fader in ipairs(self.Faders) do
        fader:GetVar("visible"):SetInt(0)
      end
      self:Cleanup()
    end,
    onUpdate = function(alpha)
      for _, fader in ipairs(self.Faders) do
        local maxA = math.min(alpha, fader.maxFade or 1)
        fader:GetVar("alpha"):SetFloat(maxA)
        if fader.updateAlpha then
          fader:updateAlpha(maxA)
        end
      end
      if self.items then
        for _, rewardItem in ipairs(self.items) do
          rewardItem:GetVar("alpha"):SetFloat(alpha)
          if rewardItem.updateAlpha then
            rewardItem:updateAlpha(alpha)
          end
        end
      end
    end
  })
  self.FadeTransition:SetAlpha(0)
  self.Flash.FadeTransition = FadeTransition:new({
    duration = 0.33,
    maxFade = 1,
    delayOnHide = 0.16,
    onUpdate = function(alpha)
      self.Flash:GetVar("alpha"):SetFloat(alpha)
    end,
    onDoneShow = function(t)
      t:Hide()
    end,
    onDoneHide = function()
      self.Flash("visible"):SetInt(0)
    end
  })
  self.Flash.FadeTransition:SetAlpha(0)
end
function RewardsBehaviour:onDestroy()
  local shader = game.getShader("ShaderScrollingPattern")
  if shader then
    shader:getUniform("u_TexParams"):setVec4(lua_sys.Vector4(128 * game.hudScale() / lua_sys.screenWidth(), 128 * game.hudScale() / lua_sys.screenHeight(), 3, 3))
  end
end
function RewardsBehaviour:onTick(dt)
  dt = math.min(dt, 0.033)
  local function tickBar(e, dt)
    OldOffsetTransition.OnTick(e, dt, {
      ease = lua_sys.Quadratic_EaseIn
    })
  end
  tickBar(self.RewardsTopBar, dt)
  tickBar(self.RewardsBottomBar, dt)
  self.FadeTransition:Tick(dt)
  if self.Flash("visible"):GetInt() == 1 then
    self.Flash.FadeTransition:Tick(dt)
  end
  if self.isShowing and not self.isDoneSequence then
    self.sequenceTimeRemaining = self.sequenceTimeRemaining - dt
    if self.sequenceTimeRemaining <= 0 then
      self.isDoneSequence = true
      self.Fade.Touch:GetVar("enabled"):SetInt(1)
      self.ContinueLabel.Text.FadeTransition:Show()
    end
  end
  self.ContinueLabel.Text.FadeTransition:Tick(dt)
end
function RewardsBehaviour:ShowCompletion()
  local awakener = game.FindAwakener()
  if awakener then
    local rewards = {}
    table.insert(rewards, {
      id = awakener:entityId(),
      type = 12,
      amount = 1
    })
    self:Show(rewards, true)
  end
end
function RewardsBehaviour:Show(rewards, isCompletion)
  self.isDoneSequence = false
  self.sequenceTimeRemaining = 2
  self.isCompletion = isCompletion
  self:Cleanup()
  local function createReward(idx, rewardData)
    local rewardItem = menu:addTemplateElement("template_daily_cumulative_login_reward", "rewardItem" .. idx, self)
    rewardItem:Init(rewardData, idx)
    rewardItem:setParent(self)
    rewardItem:relativeTo(self)
    rewardItem:setOrientation(lua_sys.MenuOrientation(0, -16 * game.hudScale(), 10, lua_sys.LEFT, lua_sys.VCENTER))
    rewardItem:setRelativeObjectAnchors(lua_sys.HCENTER, lua_sys.VCENTER)
    rewardItem:calculatePosition()
    rewardItem:init()
    rewardItem:setPositionBroadcast(true)
    rewardItem:postInit()
    table.insert(self.items, rewardItem)
  end
  local function createRewardEvo(idx)
    local rewardItem = menu:addTemplateElement("template_daily_cumulative_login_reward_evo", "rewardItem" .. idx, self)
    rewardItem:Init(idx)
    rewardItem:setParent(self)
    rewardItem:relativeTo(self)
    rewardItem:setOrientation(lua_sys.MenuOrientation(0, -16 * game.hudScale(), 10, lua_sys.LEFT, lua_sys.VCENTER))
    rewardItem:setRelativeObjectAnchors(lua_sys.HCENTER, lua_sys.VCENTER)
    rewardItem:calculatePosition()
    rewardItem:init()
    rewardItem:setPositionBroadcast(true)
    rewardItem:postInit()
    table.insert(self.items, rewardItem)
  end
  local isEvoDay = function()
    local currentCalendarId = 0
    local awakener = game.FindAwakener()
    if awakener then
      currentCalendarId = awakener:getCalendarId()
    end
    local playerState = game.player():getDailyCumulativeLogin()
    local calendarId = playerState:calendar()
    local calendarData = game.getDailyCumulativeLoginData(calendarId)
    local rewardIdx = playerState:reward()
    return currentCalendarId == calendarId and math.floor(rewardIdx % math.floor(calendarData:getNumRewards() / 4)) == 0
  end
  local function showRewards()
    local showClaimInfo = false
    local claimFromMarket = false
    local claimFromMail = false
    self.items = {}
    local idx = 0
    print("isEvoDay?", isEvoDay())
    if isEvoDay() then
      createRewardEvo(#rewards)
      idx = idx + 1
    end
    if rewards then
      for i, r in ipairs(rewards) do
        createReward(idx + (i - 1), r)
        if r.type == game.LootType_Monster or r.type == game.LootType_Structure or r.type == game.LootType_Costume then
          showClaimInfo = true
          if r.type == game.LootType_Monster then
            local monsterData = game.getMonsterByEntityId(r.id)
            if monsterData and monsterData:getExtraInt("activated") == 1 then
              claimFromMail = true
            else
              claimFromMarket = true
            end
          else
            claimFromMarket = true
          end
        end
      end
      MenuHelpers.CenterHorizontally(self.items)
    end
    local function showBar(e)
      OldOffsetTransition.Show(e)
    end
    self.Fade:Show()
    showBar(self.RewardsTopBar)
    showBar(self.RewardsBottomBar)
    for _, fader in ipairs(self.Faders) do
      fader:GetVar("visible"):SetInt(1)
    end
    if not showClaimInfo then
      self.ClaimInfo.Text:GetVar("visible"):SetInt(0)
    else
      self.ClaimInfo.Text:GetVar("visible"):SetInt(1)
      if self.isCompletion then
        self.ClaimInfo.Text:GetVar("text"):SetString("COLOSSEYE_ACTIVATED")
      else
        local claimMsg = "CLAIM_REWARDS_FROM_MARKET"
        if claimFromMail and claimFromMarket then
          claimMsg = "CLAIM_REWARDS_FROM_MARKET_AND_MAIL"
        elseif claimFromMail then
          claimMsg = "CLAIM_REWARDS_FROM_MAIL"
        end
        self.ClaimInfo.Text:GetVar("text"):SetString(claimMsg)
      end
    end
  end
  self.FadeTransition:Show()
  self.isShowing = true
  local showFlash = false
  if showFlash then
    self.Flash:GetVar("visible"):SetInt(1)
    function self.Flash.FadeTransition.onDoneShow(t)
      showRewards()
      t:Hide()
    end
    self.Flash.FadeTransition:Show()
  else
    showRewards()
  end
end
function RewardsBehaviour:Hide()
  self.isShowing = false
  if self.isCompletion then
    root:Hide()
    local awakener = game.FindAwakener()
    if awakener then
      local IslandAwakening = include("IslandAwakening")
      local currentIsland = game.currentIsland()
      local activeIslandTheme = game.getActiveIslandTheme(currentIsland)
      if IslandAwakening.HasCutscene(currentIsland, activeIslandTheme) then
        awakener:setStatus(1)
        IslandAwakening.PlayShowCutscene(currentIsland, activeIslandTheme)
      end
    end
  else
    local function hideBar(e)
      OldOffsetTransition.Hide(e)
    end
    self.Fade:Hide()
    hideBar(self.RewardsTopBar)
    hideBar(self.RewardsBottomBar)
    self.FadeTransition:Hide()
    root:RefreshState()
    root.MainPanel:populate()
    self.ContinueLabel.Text.FadeTransition:Hide()
    root.ViewButton.Sprite:GetVar("visible"):SetInt(1)
    root.ViewButton.Touch:GetVar("enabled"):SetInt(1)
  end
end
function RewardsBehaviour:Cleanup()
  if self.items then
    for _, v in ipairs(self.items) do
      self:RemoveElement(v)
    end
  end
  self.items = {}
end
function RewardsBehaviour.Fade.Touch:onTouchUp(element, x, y)
  if root.Rewards.isDoneSequence then
    self:GetVar("enabled"):SetInt(0)
    root.Rewards:Hide()
  end
end
function DCL:DoRewardTest()
  print("Do Reward Test!")
  local rewards = {}
  table.insert(rewards, {
    id = 0,
    type = 4,
    amount = 500
  })
  table.insert(rewards, {
    id = 64,
    type = 11,
    amount = 500
  })
  table.insert(rewards, {
    id = 2,
    type = 12,
    amount = 1
  })
  table.insert(rewards, {
    id = 23,
    type = 14,
    amount = 1
  })
  table.insert(rewards, {
    id = 23,
    type = 13,
    amount = 1
  })
  local list = game.M_int()
  list:push_back(1)
end
function DCL:DoPuzzleTest()
  root.MainPanel:PlayRevealEffect(function()
    print("done!")
  end)
end
function TestPanelBehaviour:onPostInit()
  local playerState = game.player():getDailyCumulativeLogin()
  self.calendarId = playerState:calendar()
  self.calendarData = game.getDailyCumulativeLoginData(self.calendarId)
  self.rewardIdx = playerState:reward()
  function self.Up.Touch.onTouchUp()
    if self.rewardIdx + 1 >= self.calendarData:getNumRewards() then
      local nextCalendar = game.getDailyCumulativeLoginData(self.calendarId + 1)
      if nextCalendar.id > 0 then
        self.calendarId = nextCalendar.id
        self.calendarData = game.getDailyCumulativeLoginData(self.calendarId)
        self.rewardIdx = 0
      end
    else
      self.rewardIdx = self.rewardIdx + 1
    end
    self:refresh()
  end
  function self.Down.Touch.onTouchUp()
    if self.rewardIdx - 1 < 0 then
      local previousCalendar = game.getDailyCumulativeLoginData(self.calendarId - 1)
      if 0 < previousCalendar.id then
        self.calendarId = previousCalendar.id
        self.calendarData = game.getDailyCumulativeLoginData(self.calendarId)
        self.rewardIdx = previousCalendar:getNumRewards() - 1
      end
    else
      self.rewardIdx = self.rewardIdx - 1
    end
    self:refresh()
  end
  function self.Info.Touch.onTouchUp()
    game.resetCalendar(self.calendarId, self.rewardIdx)
  end
  self:SetupGenericListener(game.engineReceiver(), "game::msg::MsgUpdatePlayerDailyCumulativeLogin", "gotMsgUpdatePlayerDailyCumulativeLoginAlso")
  self:refresh()
end
function TestPanelBehaviour:refresh()
  self.Info.Label:GetVar("text"):SetString("Day\n" .. tostring(self.rewardIdx + 1) .. "/" .. self.calendarData:getNumRewards())
end
function TestPanelBehaviour:gotMsgUpdatePlayerDailyCumulativeLoginAlso(msg)
  local playerState = game.player():getDailyCumulativeLogin()
  self.calendarId = playerState:calendar()
  self.calendarData = game.getDailyCumulativeLoginData(self.calendarId)
  self.rewardIdx = playerState:reward()
  self:refresh()
end
return DCL
