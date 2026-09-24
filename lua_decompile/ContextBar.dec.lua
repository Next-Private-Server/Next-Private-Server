local BreedingRules = include("BreedingRules")
local CostumesHelper = include("CostumesHelper")
local ReportMenu = include("ReportMenu")
local ContextBar = {}
local luaPointer
local textScale = 0.5
local TOUCH_DELAY = 0.5
local currentTouchDelay = 0
local lastUnlinkMessage = ""
function ContextBar.onInit(element)
  luaPointer = _G[element:root():getLuaPointer()]
  element("origTextScale"):SetFloat(1)
  element:populate()
  element("allowClick"):SetInt(1)
  element("collectAllVisible"):SetInt(-1)
  element("collectAllEnabled"):SetInt(-1)
  element("showingTimer"):SetInt(-1)
  element("flyUpEase"):SetInt(0)
  element("bounceDownEase"):SetInt(0)
  element("curEaseTime"):SetFloat(0)
  element("bounceCount"):SetInt(0)
  element("maxBounceCount"):SetInt(game.numCollectAllEventPulses())
  element:SetupGenericListener(game.engineReceiver(), "game::msg::MsgPlacementInfo", "gotMsgPlacementInfo")
  element:SetupGenericListener(game.engineReceiver(), "game::msg::MsgPlacementInfoFail", "gotMsgPlacementInfoFail")
  element:SetupGenericListener(game.engineReceiver(), "game::msg::MsgPlacementImageFail", "gotMsgPlacementImageFail")
  element:SetupGenericListener(game.engineReceiver(), "game::msg::MsgUpdateMailNotification", "gotMsgUpdateMailNotification")
  element:SetupGenericListener(game.engineReceiver(), "game::msg::MsgConfirmationSubmission", "gotMsgConfirmationSubmission")
  element:SetupGenericListener(game.engineReceiver(), "game::msg::MsgMonsterTrainingStatusUpdated", "gotMsgMonsterTrainingStatusUpdated")
  element:SetupGenericListener(game.engineReceiver(), "game::msg::MsgPermission", "gotMsgPermission")
  element:SetupGenericListener(game.engineReceiver(), "game::msg::MsgTutorialInitialized", "gotMsgTutorialInitialized")
  element:SetupGenericListener(game.engineReceiver(), "game::msg::MsgSoulLinkRemoved", "gotMsgSoulLinkRemoved")
  element:SetupGenericListener(game.engineReceiver(), "game::msg::MsgIslandModeChanged", "gotMsgIslandModeChanged")
  element:SetupGenericListener(game.engineReceiver(), "game::msg::MsgClubboxHypeUpdated", "gotMsgClubboxHypeUpdated")
  if game.showCollectBounce() and element("maxBounceCount"):GetInt() ~= 0 then
    element:startCollectAllEventBounce()
  end
end
function ContextBar.populate(element)
  element("numItems"):SetInt(luaPointer:numCurrentItems())
  local numItems = element("numItems"):GetInt()
  local rootItem, previous
  for i = 0, numItems - 1 do
    local emptyItem = menu:addTemplateElement("template_barbutton", "barItem" .. i, element)
    emptyItem("SheetName"):SetString(luaPointer:getSheetName())
    emptyItem("ButtonSheetName"):SetString(luaPointer:getSheetForButton(i))
    emptyItem("UpSpriteName"):SetString(luaPointer:getUpSprite())
    emptyItem("ButtonImageName"):SetString(luaPointer:getImageForButton(i))
    emptyItem("ButtonLabelText"):SetString(luaPointer:getLabelForButton(i))
    emptyItem("ClickSound"):SetString(luaPointer:getClickSoundForButton(i))
    emptyItem("ButtonScale"):SetFloat(luaPointer:getScaleForButton(i))
    emptyItem("ButtonHFlip"):SetInt(luaPointer:getHFlipForButton(i))
    emptyItem("ButtonVFlip"):SetInt(luaPointer:getVFlipForButton(i))
    emptyItem("AttachedTemplate"):SetString(luaPointer:getAttachedTemplateForButton(i))
    emptyItem("FunctionName"):SetString(luaPointer:getFunctionForButton(i))
    emptyItem("ProxyFunctionName"):SetString("proxyFunctionHandler")
    emptyItem("ButtonMapping"):SetString(luaPointer:getButtonMappingForButton(i))
    emptyItem("ReactToTouches"):SetInt(1)
    emptyItem("TextScale"):SetFloat(textScale)
    emptyItem:setParent(element)
    emptyItem:setRelativeObjectAnchors(luaPointer:getHAnchor(), luaPointer:getVAnchor())
    if previous == nil then
      emptyItem:relativeTo(element)
      emptyItem:setOrientation(lua_sys.MenuOrientation(-200, -200, 5, luaPointer:getHAnchor(), luaPointer:getVAnchor()))
      rootItem = emptyItem
    else
      emptyItem:relativeTo(element)
      emptyItem:setOrientation(lua_sys.MenuOrientation(previous("xOffset"):GetInt(), previous("yOffset"):GetInt(), 5, luaPointer:getHAnchor(), luaPointer:getVAnchor()))
    end
    previous = emptyItem
    emptyItem:init()
    emptyItem:postInit()
    emptyItem:setPositionBroadcast(true)
    luaPointer:setBarElement(i, emptyItem)
    if emptyItem("FunctionName"):GetString() == "" then
      manager:rightShiftFrom(luaPointer:getIdForButton(i), true)
    end
  end
  if rootItem then
    local contextInfo = menu:addTemplateElement("template_contextinfo", "InfoElement", element)
    contextInfo("titleScale"):SetFloat(0.6)
    contextInfo:setParent(element)
    contextInfo:setOrientation(lua_sys.MenuOrientation(-1000, -600, 2, luaPointer:getHAnchor(), luaPointer:getVAnchor()))
    contextInfo:setRelativeObjectAnchors(luaPointer:getHAnchor(), luaPointer:getVAnchor())
    contextInfo:init()
    contextInfo:setPositionBroadcast(true)
  end
  element:DoStoredScript(manager:getOnInitFunction())
end
function ContextBar.repopulate(element)
  for i = 0, element("numItems"):GetInt() - 1 do
    element:RemoveElement(element:GetElement("barItem" .. i))
  end
  if element:GetElement("InfoElement") then
    element:RemoveElement(element:GetElement("InfoElement"))
  end
  element:populate()
end
local allowSpammingFunctions = {
  feed_monster = true,
  tribal_feed_monster_ethereal = true,
  tribal_feed_monster_diamonds = true,
  tribal_feed_monster_coins = true,
  tribal_feed_monster_food = true,
  collect_currency = true,
  mute_object = true,
  unmute_object = true,
  breeding_feed_monster = true
}
function ContextBar.proxyFunctionHandler(element)
  if element("FunctionName") ~= nil and element("FunctionName"):type() ~= lua_sys.Variable_VAR_TYPE_NONE and element("FunctionName"):GetString() ~= "" then
    local functionName = element("FunctionName"):GetString()
    local allowSpamming = allowSpammingFunctions[functionName] or false
    if currentTouchDelay <= 0 or allowSpamming then
      if not allowSpamming then
        currentTouchDelay = TOUCH_DELAY
      end
      element:DoStoredScript(functionName)
      element("FunctionName"):SetString("")
    end
  end
end
function ContextBar.startCollectAllEventBounce(element)
  element("flyUpEase"):SetInt(1)
  element("bounceCount"):SetInt(0)
end
function ContextBar.stopCollectAllEventBounce(element)
  element("flyUpEase"):SetInt(0)
  element("bounceDownEase"):SetInt(0)
  element("bounceCount"):SetInt(0)
  local button = manager:getButton("btn_collect_all")
  if button ~= nil then
    local scale = button("ButtonScale"):GetFloat()
    local ease = 0.5
    button.UpSprite("size"):SetFloat(ease * scale)
    button.ButtonImage("size"):SetFloat(ease * scale)
    button.ButtonLabel("size"):SetFloat(ease * scale * element("origTextScale"):GetFloat())
    local templ = button:GetElement("attachedTemplate")
    if templ ~= nil then
      templ("setNewScale"):SetFloat(ease * 2)
    end
  end
  element("bounceCount"):SetInt(0)
  game.setCollectBounceSeen()
end
function ContextBar.CollectAllHide(element)
  element("collectAllVisible"):SetInt(0)
  element("collectAllEnabled"):SetInt(0)
  element("showingTimer"):SetInt(0)
  manager:setButtonVisible("btn_collect_all", false)
end
function ContextBar.CollectAllEnable(element)
  element("collectAllVisible"):SetInt(1)
  element("collectAllEnabled"):SetInt(1)
  element("showingTimer"):SetInt(0)
  manager:setButtonVisible("btn_collect_all", true)
  manager:setButtonEnabled("btn_collect_all", true)
end
function ContextBar.CollectAllDisableWithTimer(element)
  element("collectAllVisible"):SetInt(1)
  element("collectAllEnabled"):SetInt(0)
  element("showingTimer"):SetInt(1)
  manager:setButtonVisible("btn_collect_all", true)
  manager:setButtonEnabled("btn_collect_all", false)
  local button = manager:getButton("btn_collect_all")
  if button ~= nil then
    button("ReactToTouches"):SetInt(0)
    button.Touch("enabled"):SetInt(1)
  end
end
function ContextBar.CollectAllDisableNoTimer(element)
  element("collectAllVisible"):SetInt(1)
  element("collectAllEnabled"):SetInt(0)
  element("showingTimer"):SetInt(0)
  manager:setButtonVisible("btn_collect_all", true)
  manager:setButtonEnabled("btn_collect_all", false)
  local button = manager:getButton("btn_collect_all")
  if button ~= nil then
    button("ReactToTouches"):SetInt(0)
    button.Touch("enabled"):SetInt(1)
  end
end
function ContextBar.onTick(element, dt)
  if currentTouchDelay > 0 then
    currentTouchDelay = currentTouchDelay - dt
  end
  if manager:getContext() == "DEFAULT" or manager:getContext() == "ETHEREAL_DEFAULT" or manager:getContext() == "PAIRONORMAL_DEFAULT" or manager:getContext() == "SHUGGA_DEFAULT" then
    if element("collectAllVisible"):GetInt() == 1 then
      if element("collectAllEnabled"):GetInt() == 1 and game.collectAllDisabled() then
        if game.showCollectAllTimer() then
          element:CollectAllDisableWithTimer()
        else
          element:CollectAllDisableNoTimer()
        end
      elseif element("collectAllEnabled"):GetInt() == 0 and not game.collectAllDisabled() then
        element:CollectAllEnable()
      end
      if element("collectAllEnabled"):GetInt() == 1 then
        if element("flyUpEase"):GetInt() == 1 or element("bounceDownEase"):GetInt() == 1 then
          local button = manager:getButton("btn_collect_all")
          if button ~= nil then
            local buttonState = button("ButtonState"):GetInt()
            if buttonState == game.BUTTON_PRESSED then
              element:stopCollectAllEventBounce()
            end
          end
        end
        if element("flyUpEase"):GetInt() == 1 then
          if element("curEaseTime"):GetFloat() < 0.4 then
            local button = manager:getButton("btn_collect_all")
            if button ~= nil then
              local scale = button("ButtonScale"):GetFloat()
              local ease = lua_sys.Exponential_EaseOut(element:GetVar("curEaseTime"):GetFloat(), 0.5, 0.1, 0.4)
              button.UpSprite("size"):SetFloat(ease * scale)
              button.ButtonImage("size"):SetFloat(ease * scale)
              button.ButtonLabel("size"):SetFloat(ease * scale * element("origTextScale"):GetFloat())
              local templ = button:GetElement("attachedTemplate")
              if templ ~= nil then
                templ("setNewScale"):SetFloat(ease * 2)
              end
            end
            element("curEaseTime"):SetFloat(element("curEaseTime"):GetFloat() + dt)
          else
            element("flyUpEase"):SetInt(0)
            element("bounceDownEase"):SetInt(1)
            element("curEaseTime"):SetFloat(0)
          end
        elseif element("bounceDownEase"):GetInt() == 1 then
          if element("curEaseTime"):GetFloat() < 1.2 then
            local button = manager:getButton("btn_collect_all")
            if button ~= nil then
              local scale = button("ButtonScale"):GetFloat()
              local ease = lua_sys.Bounce_EaseOut(element("curEaseTime"):GetFloat(), 0.6, -0.1, 1.2)
              button.UpSprite("size"):SetFloat(ease * scale)
              button.ButtonImage("size"):SetFloat(ease * scale)
              button.ButtonLabel("size"):SetFloat(ease * scale * element("origTextScale"):GetFloat())
              local templ = button:GetElement("attachedTemplate")
              if templ ~= nil then
                templ("setNewScale"):SetFloat(ease * 2)
              end
            end
            element("curEaseTime"):SetFloat(element("curEaseTime"):GetFloat() + dt)
          else
            element("bounceDownEase"):SetInt(0)
            element("flyUpEase"):SetInt(1)
            element("curEaseTime"):SetFloat(0)
            local bounceCount = element("bounceCount"):GetInt() + 1
            element("bounceCount"):SetInt(bounceCount)
            if 0 <= element("maxBounceCount"):GetInt() and bounceCount >= element("maxBounceCount"):GetInt() then
              element:stopCollectAllEventBounce()
            end
          end
        end
      end
    elseif game.collectAllUnlocked() then
      if not game.collectAllDisabled() then
        element:CollectAllEnable()
      elseif game.showCollectAllTimer() then
        element:CollectAllDisableWithTimer()
      else
        element:CollectAllDisableNoTimer()
      end
    end
  elseif manager:getContext() == "NURSERY_OCCUPIED" then
    if game.eggReadyToHatch() then
      manager:setButtonVisible("btn_hatch", false)
      manager:setButtonVisible("btn_reduceTime", false)
    end
  elseif manager:getContext() == "BREEDING_OCCUPIED" then
    if game.isBreedingFinished() then
      manager:setButtonVisible("btn_finish", false)
      manager:setButtonVisible("btn_reduceTime", false)
    end
  elseif manager:getContext() == "SYNTHESIZER_SYNTHESIZING" then
    if game.synthesizerHasEggToCollect() then
      manager:setButtonVisible("btn_finish", false)
      manager:setButtonVisible("btn_reduceTime", false)
    end
  elseif manager:getContext() == "ATTUNER_ATTUNING" then
    if game.isAttuningComplete() then
      manager:setButtonVisible("btn_finish", false)
      manager:setButtonVisible("btn_reduceTime", false)
    end
  elseif manager:getContext() == "DISH_HARMONIZER_HARMONIZING" then
    if game:SelectedObject() and game:SelectedObject():isDishHarmonizer() and game:SelectedObject():isDishHarmonizingComplete() then
      manager:setButtonVisible("btn_finish", false)
      manager:setButtonVisible("btn_reduceTime", false)
    end
  elseif manager:getContext() == "FUGUE_FUGUING" then
    if game:SelectedObject() and game:SelectedObject():isFugue() and game:SelectedObject():isFuguingComplete() then
      manager:setButtonVisible("btn_finish", false)
      manager:setButtonVisible("btn_reduceTime", false)
    end
  elseif manager:getContext() == "DESTRUCTABLE_OBJECT" then
    if 0 > game.timeLeftToDestoryObstacle() then
      manager:setButtonVisible("btn_remove", false)
      manager:setButtonVisible("btn_reduceTime", false)
    end
  elseif manager:getContext() == "BAKERY" then
    if 0 >= game.timeLeftToBake() then
      manager:setButtonVisible("btn_finish", false)
      manager:setButtonVisible("btn_reduceTime", false)
    end
  elseif manager:getContext() == "UPGRADING_CASTLE" then
    if 0 >= game.timeLeftToBuild() then
      manager:setButtonVisible("btn_speedup", false)
      manager:setButtonVisible("btn_reduceTime", false)
    end
  elseif manager:getContext() == "BUILDING_OBJECT" then
    if 0 >= game.timeLeftToBuild() then
      if manager:isButtonVisible("btn_move") then
        manager:rightShiftFrom("btn_move", true)
      end
      manager:setButtonVisible("btn_speedup", false)
      manager:setButtonVisible("btn_reduceTime", false)
    end
  elseif manager:getContext() == "TORCH_DAILY_LIT" then
    if game.changeTorchToUnlitContextBar() then
      manager:setContext("TORCH_UNLIT")
    end
  elseif manager:getContext() == "BATTLE_MONSTER_TRAINING" then
    local uniqueMonsterId = game.selectedMonsterId()
    if uniqueMonsterId ~= 0 then
      local isTraining = game.isMonsterTraining(uniqueMonsterId) and 0 < game.getTrainingSecsRemaining(uniqueMonsterId)
      if not isTraining then
        manager:setButtonVisible("btn_speedup", false)
        manager:setButtonVisible("btn_reduceTime", false)
      elseif isTraining then
        if not game.battleTutActive() then
          if not manager:isButtonEnabled("btn_speedup") or not manager:isButtonEnabled("btn_reduceTime") then
            manager:setButtonVisible("btn_speedup", true)
            manager:setButtonVisible("btn_reduceTime", true)
            element:hide_video_oninit()
          end
        else
          manager:setButtonVisible("btn_reduceTime", false)
        end
      end
    end
  elseif manager:getContext() == "BATTLE_GYM_INVENTORY_SELECTED" then
    local monsterId = game.getSelectedGymMonsterID()
    if monsterId > 0 and 0 >= game.getTrainingSecsRemaining(monsterId) then
      manager:setButtonImgWithSheet("btn_finish", "button_yes", "xml_resources/context_buttons.xml")
      manager:setButtonLabel("btn_finish", "CONTEXTBAR_BATTLE_GYM_FINISH_LABEL")
    end
  end
end
function ContextBar.gotMsgConfirmationSubmission(element, msg)
  if manager:getContext() == "CASTLE" then
    if msg.messageID == "CASTLE_UPGRADE_PERFORMANCE" and msg.choice == true then
      game.upgradeObject()
    end
  elseif manager:getContext() == "BAKERY_IDLE" or manager:getContext() == "BAKERY_IDLE_NO_UPGRADE" then
    if msg.messageID == "REBAKERY_PURCHASE" and msg.choice == true then
      game.rebake()
      manager:setContext("BAKERY")
    end
  elseif manager:getContext() == "MONSTER_INFO" then
    if msg.messageID == "CONFIRM_SOUL_UNLINK_SELL" and msg.choice == true then
      lastUnlinkMessage = "CONFIRM_SOUL_UNLINK_SELL"
      game.RemoveSoulLink(game.selectedMonsterId())
    end
  elseif manager:getContext() == "MONSTER" then
    if msg.messageID == "CONFIRM_SOUL_UNLINK_TELEPORT" and msg.choice == true then
      lastUnlinkMessage = "CONFIRM_SOUL_UNLINK_TELEPORT"
      game.RemoveSoulLink(game.selectedMonsterId())
    elseif msg.messageID == "CONFIRM_SOUL_UNLINK_TRANSPOSE" and msg.choice == true then
      lastUnlinkMessage = "CONFIRM_SOUL_UNLINK_TRANSPOSE"
      game.RemoveSoulLink(game.selectedMonsterId())
    end
  elseif manager:getContext() == "MOVE_VOLUME_MENU" then
    if msg.messageID == "CONFIRM_SOUL_UNLINK_STORAGE" and msg.choice == true then
      lastUnlinkMessage = "CONFIRM_SOUL_UNLINK_STORAGE"
      game.RemoveSoulLink(game.selectedMonsterId())
    end
  elseif manager:getContext() == "INACTIVE_FUGUE" and msg.messageID == "UPGRADE_FUGUE" then
    if msg.choice == true then
      game.upgradeObject(true)
    else
      game.deselectSelectedObject()
      manager:setContext(manager:getDefaultContext())
    end
  end
end
function ContextBar.gotMsgSoulLinkRemoved(element, msg)
  if manager:getContext() == "MONSTER_INFO" and lastUnlinkMessage == "CONFIRM_SOUL_UNLINK_SELL" then
    element:sell_object(element)
  elseif lastUnlinkMessage == "CONFIRM_SOUL_UNLINK_STORAGE" then
    element:storage_object(element)
  elseif manager:getContext() == "MONSTER" and lastUnlinkMessage == "CONFIRM_SOUL_UNLINK_TELEPORT" then
    element:show_teleport_menu(element)
  elseif manager:getContext() == "MONSTER" and lastUnlinkMessage == "CONFIRM_SOUL_UNLINK_TRANSPOSE" then
    manager:insertButton("btn_collect", "button_collect", "CONTEXTBAR_COLLECT_LABEL", "collect_currency", "template_collectinfo")
    element:show_transpose_menu(element)
  end
  lastUnlinkMessage = ""
end
function ContextBar.hide_video_oninit(element)
  if game.tutorialDisableExtraFeatures() then
    manager:setButtonEnabled("btn_reduceTime", false)
  end
  if manager:getContext() == "UPGRADING_BATTLE_HOTEL" and game.isBattleIslandMuted() then
    manager:changeButton("btn_mute", "button_unmute", "CONTEXTBAR_UNMUTE_LABEL", "unmute_battle_island")
  end
  if game.checkPlacementAvailable ~= nil and game.checkPlacementAvailable("shared_rewarded") == false then
    manager:rightShiftFrom("btn_reduceTime", true)
  end
end
function ContextBar.show_options(element)
  manager:setContext("OPTIONS")
end
function ContextBar.show_friend_options(element)
  manager:setContext("FRIEND_OPTIONS")
end
function ContextBar.show_market(element)
  if not game.disableMarketButton() then
    game.loadStoreContext()
  elseif game.battleTutActive() then
    game.displayNotification("NOTIFICATION_FINISH_BATTLE_TUTORIAL")
  elseif game.disableMarketButton() then
    game.displayNotification("TUTORIAL_LOCKED_FEATURE")
  end
end
function ContextBar.show_friends(element)
  game.checkGamePermission("FRIENDS", "popup_permission_friends")
end
function ContextBar.show_tribal_menu(element)
  manager:setContext("TRIBAL_MENU")
end
function ContextBar.show_book(element)
  if game.getPopUp() ~= "book_o_monsters" then
    local activeIsland = game.player():getActiveIsland()
    local islandId = activeIsland:id()
    game.setBookOfMonstersIslandId(islandId, activeIsland:islandMode())
    game.logEvent("book_o_monsters", "island", tostring(game.currentIslandType()), "source", "context_bar")
    manager:setContext("BLANK")
    game.pushPopUp("book_o_monsters")
    game.topPopUp()("FromWorld"):SetInt(1)
  end
end
function ContextBar.show_map(element)
  if game.mapVersion() == 2 then
    local friendMode = false
    game.loadMapContext(friendMode)
  elseif game.getPopUp() ~= "island_select" then
    manager:touchSafeSetContextImmediate("ISLAND_MAP")
    game.pushPopUp("island_select")
  end
end
function ContextBar.show_friend_map(element)
  if game.mapVersion() == 2 then
    local friendMode = true
    game.loadMapContext(friendMode)
  elseif game.getPopUp() ~= "friend_island_select" then
    manager:setContext("FRIEND_MAP")
    manager:setReserveState("FRIEND_DEFAULT")
  end
end
function ContextBar.islandmap_oninit(element)
end
function ContextBar.friendmap_oninit(element)
  if game.getPopUp() ~= "friend_island_select" then
    game.pushPopUp("friend_island_select")
  end
end
function ContextBar.show_admin_map(element)
  if game.mapVersion() == 2 then
    local friendMode = true
    game.loadMapContext(friendMode)
  elseif game.getPopUp() ~= "friend_island_select" then
    manager:setContext("BLANK")
    game.pushPopUp("friend_island_select")
  end
end
function ContextBar.show_info(element)
  manager:setReserveState(manager:getContext())
  manager:setContext("MONSTER_INFO")
end
function ContextBar.show_rank_help(element)
  game.displayNotification("RANK_HELP_DESC")
end
function ContextBar.show_underling_info(element)
  manager:setReserveState(manager:getContext())
  manager:setContext("UNDERLING_INFO")
end
function ContextBar.show_nexus_info(element)
  manager:setReserveState(manager:getContext())
  manager:setContext("NEXUS_INFO")
end
function ContextBar.show_box_info(element)
  manager:setReserveState(manager:getContext())
  if game.isUnderlingIsland() or game.isCelestialIsland() or game.isAmberIsland() then
    manager:setContext("UNDERLING_INFO")
  else
    manager:setContext("MONSTER_BOX_INFO")
  end
end
function ContextBar.show_box_help(element)
  if game.openHelpshiftFAQWithTag ~= nil then
    if game.isUnderlingIsland() or game.isCelestialIsland() or game.isAmberIsland() then
      if game.selectedMonsterIsZapMonster() then
        if game.isCelestialIsland() then
          game.openHelpshiftFAQWithTag("celestial")
        elseif game.isAmberIsland() then
          game.openHelpshiftFAQWithTag("amber")
        else
          game.openHelpshiftFAQWithTag("wublin")
        end
      else
        game.openHelpshiftFAQWithTag("wublin")
      end
    else
      game.openHelpshiftFAQWithTag("wubbox")
    end
  end
end
function ContextBar.show_clubbox_help(element)
  if game.openHelpshiftFAQWithTag ~= nil then
    game.openHelpshiftFAQWithTag("clubbox")
  end
end
function ContextBar.show_underling_evolution_help(element)
  if game.openHelpshiftFAQWithTag ~= nil then
    if game.isCelestialIsland() then
      game.openHelpshiftFAQWithTag("ascend-celestial")
    else
      game.openHelpshiftFAQWithTag("evolve-wublin")
    end
  end
end
function ContextBar.show_box_gold_help(element)
  if game.openHelpshiftFAQWithTag ~= nil then
    game.openHelpshiftFAQWithTag("gold")
  end
end
function ContextBar.show_happytree_info(element)
  manager:setReserveState(manager:getContext())
  manager:setContext("HAPPY_TREE_INFO")
end
function ContextBar.play_memory_minigame(element)
  manager:setReserveState(manager:getContext())
  game.playFlipMinigame()
end
function ContextBar.show_mail(element)
  if not game.disableMailboxButton() then
    game.setNewMail(false)
    manager:setReserveState(manager:getContext())
    manager:setContext("MAIL")
  elseif game.battleTutActive() then
    game.displayNotification("NOTIFICATION_FINISH_BATTLE_TUTORIAL")
  end
end
function ContextBar.friend_show_info(element)
  manager:setReserveState(manager:getContext())
  manager:setContext("FRIEND_MONSTER_INFO")
end
function ContextBar.sell_object(element)
  if game.selectedObjIsMonster() and game.isMonsterSoulLinked(game.selectedMonsterId()) then
    game.displayConfirmation("CONFIRM_SOUL_UNLINK_SELL", game.removeSoulLinkText())
  elseif game.SelectedObject():isTitansoul() and game.SelectedObject():numSoulLinks() > 0 then
    game.displayNotification("NOTIFCATION_UNLINK_MONSTERS_TO_SELL")
  else
    game.popPopUp()
    game.sellObject()
  end
end
function ContextBar.admin_destroy_object(element)
  game.popPopUp()
  game.adminDestroyObject()
end
function ContextBar.move_oninit(element)
  if game.isSelectedObjectPlaceable() == false then
    manager:setButtonEnabled("btn_confirm", false)
  end
  game.pushPopUp("showgrid_popup")
end
function ContextBar.move_object(element)
  local context = game.worldContext()
  if context and context:moveSelectedObject() then
    local selectedObj = context:selectedObject()
    if selectedObj:isTile() then
      manager:setContext("MOVE_PATH_MENU")
    elseif selectedObj:isDecoration() then
      manager:setContext("MOVE_SCALE_MENU")
    elseif selectedObj:isMonster() then
      if game.isMonsterTraining(game.selectedMonsterId()) then
        manager:setContext("MOVE_BANNER")
      elseif game.monsterBeingEvolved(game.selectedMonsterId()) then
        manager:setContext("MOVE_BANNER")
      elseif game.isAmberIsland() and game.isInactiveBoxMonster(game.selectedMonsterId()) then
        manager:setContext("MOVE_BANNER")
      elseif selectedObj:isMultiMonster() then
        local multiMonster = context:selectedMultiMonster()
        local activeMode = game.player():getActiveIsland():islandMode()
        if not multiMonster:isModeActivated(activeMode) then
          manager:setContext("MOVE")
        elseif multiMonster:isFuguing() then
          manager:setContext("MOVE_BANNER")
        else
          manager:setContext("MOVE_VOLUME_MENU")
        end
      elseif game.currentIslandType() == game.IslandType_ETHEREAL_WORKSHOP and game.FindAttuner():isReattuningMonster(game.selectedMonsterId()) then
        manager:setContext("MOVE_BANNER")
      else
        manager:setContext("MOVE_VOLUME_MENU")
      end
    elseif selectedObj:isAwakener() then
      manager:setContext("MOVE_VOLUME_MENU_AWAKENER")
    else
      manager:setContext("MOVE")
    end
  end
end
function ContextBar.composer_monster_move_object(element)
  if game.moveObject() then
    if game.composerIsBuddy() then
      manager:setContext("MOVE_COMPOSER_BUDDY_MENU")
    else
      manager:setContext("MOVE_VOLUME_MENU")
    end
  end
end
function ContextBar.show_paint(element)
  if game.hasPaintSavedState() then
    game.pushPopUp("popup_paint_restore_save_confirm")
  elseif game.paintMode(false) then
    manager:setContext("PAINT_MENU")
  end
end
function ContextBar.paint_oninit(element)
  if game.getPopUp() ~= "paint_ui" then
    game.startDecorationScale()
    game.pushPopUp("paint_ui")
  end
end
function ContextBar.light_buddy(element)
  game.buddyLight()
  manager:setContext("MOVE_BUDDY_MENU")
end
function ContextBar.storage_object(element)
  if game.selectedObjIsMonster() and game.isMonsterSoulLinked(game.selectedMonsterId()) then
    game.displayConfirmation("CONFIRM_SOUL_UNLINK_STORAGE", game.removeSoulLinkText())
  else
    game.putSelectedObjectInStorage()
  end
end
function ContextBar.list_stored_monsters(element)
  game.popPopUp()
  manager:setReserveState(manager:getContext())
  manager:setContext("HOTEL_INVENTORY")
end
function ContextBar.recording_studio_oninit(element)
  if game.MicrophoneSupported() == false then
    manager:rightShiftFrom("btn_list", true)
  end
  if game.isEtherealIsland() then
    manager:setButtonImg("btn_sell", "button_sell_shard")
  else
    manager:setButtonImg("btn_sell", "button_sell")
  end
end
function ContextBar.recording_monster_select(element)
  game.popPopUp()
  manager:setReserveState(manager:getContext())
  if game.NumRecordingDevices() > 0 then
    manager:setContext("STUDIO_SELECT")
  else
    game.displayNotification("NO_RECORDING_DEVICES")
  end
end
function ContextBar.recording_options_oninit(element)
  if game.getPopUp() ~= "recording_monster_list" then
    game.pushPopUp("recording_monster_list")
  end
end
function ContextBar.clear_island_recording(element)
  if game.getPopUp() ~= "delete_recordings_confirmation" then
    game.pushPopUp("delete_recordings_confirmation")
  end
end
function ContextBar.show_compose(element)
  game.loadComposerContext()
end
function ContextBar.hotel_oninit(element)
  if game.isEtherealIsland() then
    manager:setButtonImg("btn_sell", "button_sell_shard")
  else
    manager:setButtonImg("btn_sell", "button_sell")
  end
  if game.structureUpgradeIsFree() then
    manager:rightShiftFrom("btn_upgrade", true)
  end
end
function ContextBar.torch_oninit(element)
  if not game.isQABuild() then
    manager:rightShiftFrom("btn_qa_unlight", true)
  end
  if game.isEtherealIsland() then
    manager:setButtonImg("btn_sell", "button_sell_shard")
  else
    manager:setButtonImg("btn_sell", "button_sell")
  end
  if game.hasMaxTorches() then
    manager:rightShiftFrom("btn_buy_another", true)
  end
  if game.getActiveIslandLightTorchFlag() == true then
    manager:changeButton("btn_flag", "button_light_torch_highlight", "CONTEXTBAR_UNFLAG_LABEL", "unflag_light_island_torch")
  end
end
function ContextBar.light_torch(element)
  game.lightSelectedTorch()
end
function ContextBar.permalight_torch(element)
  game.permalightSelectedTorch()
end
function ContextBar.unlight_torch(element)
  game.unlightSelectedTorch()
end
function ContextBar.flag_light_island_torch(element)
  if not game.getUsedTorchFlag() then
    game.displayNotification("FLAG_TORCH_TUTORIAL", "FLAG_TORCH_TUTORIAL")
  elseif game.getActiveIslandLightTorchFlag() then
    game.setActiveIslandLightTorchFlag(false)
    manager:changeButton("btn_flag", "button_light_torch_highlight", "CONTEXTBAR_UNFLAG_LABEL", "unflag_light_island_torch")
  else
    local islandNames = game.getLightTorchIslands()
    if islandNames ~= nil and islandNames:size() > 0 then
      local text = LOC("TORCH_HIGHLIGHT_WARNING"):gsub("${NEW_ISLAND}", LOC(game.getActiveIslandName())):gsub("${OLD_ISLAND}", LOC(islandNames[0]))
      game.displayConfirmation("TORCH_HIGHLIGHT_WARNING", text)
    else
      game.setActiveIslandLightTorchFlag(true)
      manager:changeButton("btn_flag", "button_light_torch_highlight", "CONTEXTBAR_UNFLAG_LABEL", "unflag_light_island_torch")
    end
  end
end
function ContextBar.unflag_light_island_torch(element)
  game.setActiveIslandLightTorchFlag(false)
  manager:changeButton("btn_flag", "button_light_torch_unhighlight", "CONTEXTBAR_FLAG_LABEL", "flag_light_island_torch")
end
function ContextBar.hotel_inv_oninit(element)
  if game.getPopUp() ~= "hotel_list" then
    game.pushPopUp("hotel_list")
  end
end
function ContextBar.underling_list_oninit(element)
  if game.getPopUp() ~= "underling_list" then
    game.pushPopUp("underling_list")
  end
end
function ContextBar.list_stored_objects(element)
  game.popPopUp()
  manager:setReserveState(manager:getContext())
  manager:setContext("STORAGE_INVENTORY")
end
function ContextBar.storage_oninit(element)
  if game.isEtherealIsland() then
    manager:setButtonImg("btn_sell", "button_sell_shard")
  else
    manager:setButtonImg("btn_sell", "button_sell")
  end
  if game.structureUpgradeIsFree() then
    manager:rightShiftFrom("btn_upgrade", true)
  end
end
function ContextBar.storage_inv_oninit(element)
  if game.getPopUp() ~= "storage_list" then
    game.pushPopUp("storage_list")
  end
end
function ContextBar.close_storage_item(element)
  game.topPopUp():DoStoredScript("deselect")
end
function ContextBar.close_storage(element)
  manager:setContext(manager:reserveState())
  game.setSelectedWarehouseItemID("-1")
  game.popPopUp()
end
function ContextBar.stored_monster_oninit(element)
  if game.isEtherealIsland() then
    manager:setButtonImg("btn_sell", "button_sell_shard")
  elseif game.isAmberIsland() then
    manager:setButtonImg("btn_sell", "button_sell_relics")
  else
    manager:setButtonImg("btn_sell", "button_sell")
  end
  local monsters = game.getMonstersInHotel()
  if monsters:size() == 1 and game.monsterCount() == 0 then
    manager:setButtonEnabled("btn_sell", false)
    local sellButton = manager:getButton("btn_sell")
    if sellButton ~= nil then
      sellButton("ReactToTouches"):SetInt(0)
      manager:setButtonFunction("btn_sell", "show_sell_locked_message")
      sellButton.Touch("enabled"):SetInt(1)
    end
  end
  local selectedMonsterData = game.getMonsterData(game.monsterTypeId(game.getSelectedHotelMonsterID()))
  if selectedMonsterData:isTitansoul() then
    manager:rightShiftFrom("btn_sell", true)
  end
end
function ContextBar.stored_deco_oninit(element)
  if game.isEtherealIsland() then
    manager:setButtonImg("btn_sell", "button_sell_shard")
  else
    manager:setButtonImg("btn_sell", "button_sell")
  end
end
function ContextBar.close_hotel_item(element)
  game.topPopUp():DoStoredScript("deselect")
end
function ContextBar.close_hotel(element)
  manager:setContext(manager:reserveState())
  game.setSelectedHotelMonsterID("-1")
  game.popPopUp()
end
function ContextBar.close_underlinglist(element)
  manager:setContext(manager:reserveState())
  game.popPopUp()
  game.popupBreedMenu()
end
function ContextBar.list_fuzer_objects(element)
  game.popPopUp()
  manager:setReserveState(manager:getContext())
  manager:setContext("FUZER_INVENTORY")
end
function ContextBar.create_fuzer_objects(element)
  game.popPopUp()
  manager:setReserveState(manager:getContext())
  manager:setContext("FUZER_CREATE")
end
function ContextBar.speed_up_buddy(element)
  local diamonds = game.diamondsRequiredToComplete(game.timeLeftToFuze())
  if diamonds > 0 then
    game.showSpeedUpMessage("FUZE_SPEEDUP", "SPEED_UP_GLOWBES", game.timeLeftToFuze(), 0)
  end
end
function ContextBar.speed_up_buddy_video(element)
  if game.timeLeftToFuze() > 0 then
    game.showSpeedUpMessage("FUZE_SPEEDUP_VIDEO", "SPEED_UP_GLOWBES_VIDEO", game.timeLeftToFuze(), 1)
  end
end
function ContextBar.happy_tree_oninit(element)
  if game.isEtherealIsland() then
    manager:setButtonImg("btn_sell", "button_sell_shard")
  else
    manager:setButtonImg("btn_sell", "button_sell")
  end
end
function ContextBar.fuzer_oninit(element)
  if game.isEtherealIsland() then
    manager:setButtonImg("btn_sell", "button_sell_shard")
  else
    manager:setButtonImg("btn_sell", "button_sell")
  end
  if game.isFuzing() then
    manager:changeButton("btn_list", "button_finish", "CONTEXTBAR_SPEED_LABEL", "speed_up_buddy")
    if lua_sys.getPlatformName() ~= "pc" then
      manager:changeButton("btn_create", "button_finish_video", "CONTEXTBAR_SPEED_LABEL", "speed_up_buddy_video")
    else
      manager:rightShiftFrom("btn_create", true)
    end
    if game.playerLevel() < 4 then
      manager:setButtonEnabled("btn_create", false)
    end
    if game.checkPlacementAvailable ~= nil and game.checkPlacementAvailable("shared_rewarded") == false then
      manager:setButtonEnabled("btn_create", false)
    end
    manager:setButtonEnabled("btn_sell", false)
    manager:rightShiftFrom("btn_place", true)
  else
    manager:setReserveState(manager:getContext())
    if game.numFuzerBuddies() == 0 then
      manager:rightShiftFrom("btn_list", true)
    end
  end
  local showSale = game.showShortenedFuzingPromoTag() and game.playerLevel() >= 4
  local button = manager:getButton("btn_create")
  if button ~= nil then
    local conjureIndicator = button:GetElement("attachedTemplate")
    if conjureIndicator ~= nil then
      if showSale then
        conjureIndicator:SetVisible()
      else
        conjureIndicator:SetInvisible()
      end
    end
  end
  button = manager:getButton("btn_place")
  if button ~= nil then
    local fuzeIndicator = button:GetElement("attachedTemplate")
    if fuzeIndicator ~= nil then
      if showSale then
        fuzeIndicator:SetVisible()
      else
        fuzeIndicator:SetInvisible()
      end
    end
  end
end
function ContextBar.close_fuzer_item(element)
  game.topPopUp():DoStoredScript("deselect")
end
function ContextBar.fuzer_inv_oninit(element)
  local button = manager:getButton("btn_place")
  if button ~= nil then
    local fuzeIndicator = button:GetElement("attachedTemplate")
    if fuzeIndicator ~= nil then
      local showSale = game.showShortenedFuzingPromoTag() and game.playerLevel() >= 4
      if showSale then
        fuzeIndicator:SetVisible()
      else
        fuzeIndicator:SetInvisible()
      end
    end
  end
  if game.getPopUp() ~= "fuzer_list" then
    game.pushPopUp("fuzer_list")
  end
end
function ContextBar.fuzer_create_oninit(element)
  if game.getPopUp() ~= "fuzer_create" then
    game.pushPopUp("fuzer_create")
  end
end
function ContextBar.place_hotel(element)
  if game.enoughBedsAvailToPlaceSelectedHotelMonster() then
    game.popPopUp()
    manager:setContext("MOVE_SCALE_MENU")
    game.placeStoredMonster()
  else
    game.displayNotification("NOTIFICATION_NOT_ENOUGH_BEDS")
  end
end
function ContextBar.place_decoration(element)
  game.popPopUp()
  manager:setContext("MOVE_SCALE_MENU")
  game.placeStoredDecoration()
end
function ContextBar.sell_stored_decoration(element)
  game.sellStoredDecoration()
end
function ContextBar.sell_stored_monster(element)
  game.sellStoredMonster()
end
function ContextBar.place_buddy(element)
  game.popPopUp()
  manager:setContext("MOVE_BUDDY_MENU")
  game.placeStoredBuddy()
end
function ContextBar.fuze_buddies(element)
  if game.showShortenedFuzingPromoDesc() then
    game.pushPopUp("popup_fuzer_event_notice")
    game.topPopUp():V("exitOption"):SetInt(1)
    game.setShowedShortenedFuzingPromoDesc()
  else
    game.fuzeBuddies()
  end
end
function ContextBar.view_box_inventory(element)
  if game.isObjectSelected() then
    manager:setContext("BOX_INVENTORY_MENU")
  end
end
function ContextBar.box_inventory_oninit(element)
  local isInactiveBox = game.isInactiveBoxMonster(game.selectedMonsterId())
  local isZapMonster = game.selectedMonsterIsZapMonster()
  if game.numEggsInInventory() < game.minNumEggsRequiredInUnderling() then
    if isInactiveBox then
      if isZapMonster then
        manager:setButtonImg("btn_powerup", "button_fill_wild")
      else
        manager:setButtonImg("btn_powerup", "button_buy_all")
      end
    elseif game.selectedIsEvolvableMonsterType() and not game.isWubboxType(game.selectedMonsterTypeId()) then
      manager:setButtonImg("btn_powerup", "button_fill_wild")
    end
    manager:setButtonLabel("btn_powerup", "CONTEXTBAR_PURCHASE_BOX_FILL_LABEL")
    manager:setButtonFunction("btn_powerup", "purchase_fill_box")
  elseif isInactiveBox then
    if isZapMonster then
      if game.isCelestialIsland() then
        manager:setButtonImg("btn_powerup", "button_revive")
        manager:setButtonLabel("btn_powerup", "WAKE_UP_CELESTIAL")
      elseif game.isAmberIsland() then
        manager:setButtonImg("btn_powerup", "button_to_nursery")
        manager:setButtonLabel("btn_powerup", "CONTEXTBAR_INCUBATE_LABEL")
      else
        manager:setButtonImg("btn_powerup", "button_wakeup")
        manager:setButtonLabel("btn_powerup", "WAKE_UP_UNDERLING")
      end
    else
      manager:setButtonImg("btn_powerup", "button_power_up")
      manager:setButtonLabel("btn_powerup", "CONTEXTBAR_POWERUP_LABEL")
    end
    manager:setButtonFunction("btn_powerup", "powerup_box")
  elseif game.selectedIsEvolvableMonsterType() then
    local button = manager:getButton("btn_powerup")
    if button ~= nil then
      if game.isCelestialIsland() then
        manager:setButtonImg("btn_powerup", "button_ascension")
        manager:changeAttachedTemplate("btn_powerup", "template_lockedPowerupIndicator")
        if game.celestialEvoPowerupUnlocked() then
          if button:GetElement("attachedTemplate") ~= nil then
            button:GetElement("attachedTemplate"):SetInvisible()
          end
          manager:setButtonLabel("btn_powerup", "CONTEXTBAR_AWAKEN_LABEL")
          manager:setButtonFunction("btn_powerup", "powerup_box")
        else
          manager:setButtonLabel("btn_powerup", "UNLOCK_UNDERLING_EVOLUTION")
          manager:setButtonFunction("btn_powerup", "unlockCelestialPowerup")
        end
      elseif game.onGoldIsland() then
        if button:GetElement("attachedTemplate") ~= nil then
          button:GetElement("attachedTemplate"):SetInvisible()
        end
        manager:setButtonImg("btn_powerup", "button_power_up")
        manager:setButtonLabel("btn_powerup", "CONTEXTBAR_POWERUP_LABEL")
        manager:setButtonFunction("btn_powerup", "powerup_box")
      else
        if button:GetElement("attachedTemplate") ~= nil then
          button:GetElement("attachedTemplate"):SetInvisible()
        end
        local rarity = game.monsterRarity(game.selectedMonsterId())
        if rarity == game.MonsterRarity_Common then
          manager:setButtonImg("btn_powerup", "button_evolve")
        elseif rarity == game.MonsterRarity_Rare then
          manager:setButtonImg("btn_powerup", "button_evolve_rare_epic")
        end
        manager:setButtonLabel("btn_powerup", "EVOLVE_WUBLIN")
        manager:setButtonFunction("btn_powerup", "powerup_box")
      end
    end
  end
  local earlyAwakenButton = manager:getButton("early_waken")
  if earlyAwakenButton ~= nil then
    if not isInactiveBox and game.selectedIsEvolvableMonsterType() and game.isCelestialIsland() and game.underlingEvolutionUnlocked() then
      if not game.selectedMonsterEarlyAwakenEnabled() then
        manager:setButtonEnabled("early_waken", false)
        earlyAwakenButton("ReactToTouches"):SetInt(0)
        manager:setButtonFunction("early_waken", "earlyAwakenDisabled")
        earlyAwakenButton.Touch("enabled"):SetInt(1)
      elseif game.numEggsInInventory() == game.numEggsRequiredInUnderling() then
        manager:rightShiftFrom("early_waken", true)
      end
    else
      manager:rightShiftFrom("early_waken", true)
    end
  end
  if game.getPopUp() ~= "box_inventory" then
    game.pushPopUp("box_inventory")
  end
end
function ContextBar.powerup_box(element)
  if not game.isInactiveBoxMonster(game.selectedMonsterId()) then
    local numCostumes = game.numPurchasedCostumes(game.selectedMonsterId())
    if numCostumes > 0 then
      game.popPopUp()
      if game.isCelestialIsland() then
        local txt = game.getLocalizedText("ASCEND_CONFIRMATION_WITH_COSTUMES")
        txt = txt:gsub("%${NUM_COSTUMES}", numCostumes)
        game.displayConfirmation("EVOLVE_UNDERLING_" .. game.selectedMonsterId(), txt)
      else
        local txt = game.getLocalizedText("EVOLVE_CONFIRMATION_WITH_COSTUMES")
        txt = txt:gsub("%${NUM_COSTUMES}", numCostumes)
        game.displayConfirmation("EVOLVE_UNDERLING_" .. game.selectedMonsterId(), txt)
      end
    elseif game.activateBoxMonster() then
      game.popPopUp()
      if game.currentIsland() == game.IslandType_GOLD then
        manager:setContext("GOLD_MONSTER")
      else
        manager:setContext("MONSTER")
      end
    end
  elseif game.activateBoxMonster() then
    game.popPopUp()
    if game.currentIsland() == game.IslandType_GOLD then
      manager:setContext("GOLD_MONSTER")
    else
      manager:setContext("MONSTER")
    end
  end
end
function ContextBar.purchase_fill_box(element)
  local numCostumes = game.numPurchasedCostumes(game.selectedMonsterId())
  if numCostumes > 0 then
    local txt = game.getLocalizedText("FILL_CONFIRMATION_WITH_COSTUMES")
    txt = txt:gsub("%${NUM_COSTUMES}", numCostumes)
    game.displayConfirmation("FILL_UNDERLING_" .. game.selectedMonsterId(), txt)
  else
    game.purchaseFillBoxMonster()
  end
end
function ContextBar.flip_object(element)
  game.flipObject()
end
function ContextBar.collect_currency(element)
  game.collectFromMonster()
end
function ContextBar.mute_object(element)
  game.muteObject(true)
  manager:changeButton("btn_mute", "button_unmute", "CONTEXTBAR_UNMUTE_LABEL", "unmute_object")
  if (game.selectedObjType() == game.SpecificEntityType_CASTLE or game.selectedObjType() == game.SpecificEntityType_NUCLEUS or game.selectedObjType() == game.SpecificEntityType_DISH_HARMONIZER) and game.allMuted(true) then
    manager:changeButton("btn_mute_all", "button_unmute_all", "CONTEXTBAR_UNMUTE_ALL_LABEL", "unmute_all")
  end
end
function ContextBar.unmute_object(element)
  game.muteObject(false)
  manager:changeButton("btn_mute", "button_mute", "CONTEXTBAR_MUTE_LABEL", "mute_object")
  if game.selectedObjType() == game.SpecificEntityType_CASTLE or game.selectedObjType() == game.SpecificEntityType_NUCLEUS or game.selectedObjType() == game.SpecificEntityType_DISH_HARMONIZER then
    manager:changeButton("btn_mute_all", "button_mute_all", "CONTEXTBAR_MUTE_ALL_LABEL", "mute_all")
  end
end
function ContextBar.mute_all(element)
  game.muteIsland(true)
  local canMute = game.canMuteStructure()
  if canMute == false then
    manager:changeButton("btn_mute_all", "button_unmute_all", "CONTEXTBAR_UNMUTE_ALL_LABEL", "unmute_all")
  else
    manager:changeButton("btn_mute", "button_unmute", "CONTEXTBAR_UNMUTE_LABEL", "unmute_object")
    manager:changeButton("btn_mute_all", "button_unmute_all", "CONTEXTBAR_UNMUTE_ALL_LABEL", "unmute_all")
  end
end
function ContextBar.unmute_all(element)
  game.muteIsland(false)
  local canMute = game.canMuteStructure()
  if canMute == false then
    manager:changeButton("btn_mute_all", "button_mute_all", "CONTEXTBAR_MUTE_ALL_LABEL", "mute_all")
  else
    manager:changeButton("btn_mute", "button_mute", "CONTEXTBAR_MUTE_LABEL", "mute_object")
    manager:changeButton("btn_mute_all", "button_mute_all", "CONTEXTBAR_MUTE_ALL_LABEL", "mute_all")
  end
end
function ContextBar.awakener_mute_object(element)
  if manager:isButtonEnabled("btn_mute") then
    game.muteObject(true)
    manager:changeButton("btn_mute", "button_unmute", "CONTEXTBAR_UNMUTE_LABEL", "awakener_unmute_object")
  end
end
function ContextBar.awakener_unmute_object(element)
  if manager:isButtonEnabled("btn_mute") then
    game.muteObject(false)
    manager:changeButton("btn_mute", "button_mute", "CONTEXTBAR_MUTE_LABEL", "awakener_mute_object")
  end
end
function ContextBar.feed_monster(element)
  game.feedMonster()
end
function ContextBar.tribal_feed_monster_food(element)
  game.tribalFeedMonster(game.Currencies_CurrencyTypeToServerKey(game.CurrencyType_Food))
end
function ContextBar.tribal_feed_monster_coins(element)
  game.tribalFeedMonster(game.Currencies_CurrencyTypeToServerKey(game.CurrencyType_Coins))
end
function ContextBar.tribal_feed_monster_ethereal(element)
  game.tribalFeedMonster(game.Currencies_CurrencyTypeToServerKey(game.CurrencyType_Shards))
end
function ContextBar.tribal_feed_monster_diamonds(element)
  game.tribalFeedMonster(game.Currencies_CurrencyTypeToServerKey(game.CurrencyType_Diamonds))
end
function ContextBar.food_select(element)
end
function ContextBar.speed_up_object(element)
  if game.diamondsRequiredToComplete(game.timeLeftToBuild()) > 0 then
    game.showSpeedUpMessage("BUILD_OBJECT_SPEEDUP", "SPEED_UP_BUILD_OBJECT", game.timeLeftToBuild(), 0)
  end
end
function ContextBar.speed_up_object_video(element)
  if game.timeLeftToBuild() > 0 then
    game.showSpeedUpMessage("BUILD_OBJECT_SPEEDUP_VIDEO", "SPEED_UP_BUILD_OBJECT_VIDEO", game.timeLeftToBuild(), 1)
  end
end
function ContextBar.upgrade_object(element)
  game.upgradeObject()
  print("upgrade object")
end
function ContextBar.upgrade_castle(element)
  if game.structureUpgradeRequiresWarning() then
    game.displayConfirmation("CASTLE_UPGRADE_PERFORMANCE", "CASTLE_UPGRADE_PERFORMANCE_WARNING")
  else
    game.upgradeObject()
  end
end
function ContextBar.breed_monsters(element)
  game.triggerBreedRequest()
end
function ContextBar.test_breed_monsters(element)
  game.triggerTestBreedRequest()
end
function ContextBar.test_breed_select(element)
  manager:setReserveState(manager:getContext())
  game.topPopUp():root():popPopUp()
  if game.getPopUp() ~= "test_select_egg" then
    game.pushPopUp("test_select_egg")
  end
end
function ContextBar.destructable_oninit(element)
  if game.isBelowRequiredLevelForObject() ~= 0 or game.tutorialDisableExtraFeatures() then
    manager:setButtonEnabled("btn_remove", false)
    local removeButton = manager:getButton("btn_remove")
    if removeButton ~= nil then
      removeButton.Touch("enabled"):SetInt(1)
      removeButton("ReactToTouches"):SetInt(0)
    end
  end
end
function ContextBar.remove_object(element)
  if game.tutorialDisableExtraFeatures() then
    game.displayNotification("TUTORIAL_LOCKED_FEATURE")
  elseif game.isBelowRequiredLevelForObject() ~= 0 then
    local txt = game.getLocalizedText("NOTIFICATION_REQUIRES_LEVEL")
    txt = select(1, txt:gsub("XXX", tostring(game.isBelowRequiredLevelForObject())))
    game.displayNotification(txt)
  else
    game.clearObstacle()
  end
end
function ContextBar.finish_remove_object(element)
  if game.diamondsRequiredToComplete(game.timeLeftToDestoryObstacle()) > 0 then
    game.showSpeedUpMessage("DESTROY_OBSTACLE_SPEEDUP", "SPEED_UP_DESTROY_OBSTACLE", game.timeLeftToDestoryObstacle(), 0)
  end
end
function ContextBar.finish_remove_object_video(element)
  if game.timeLeftToDestoryObstacle() > 0 then
    game.showSpeedUpMessage("DESTROY_OBSTACLE_SPEEDUP_VIDEO", "SPEED_UP_DESTROY_OBSTACLE_VIDEO", game.timeLeftToDestoryObstacle(), 1)
  end
end
function ContextBar.mail_oninit(element)
  if game.getPopUp() ~= "mail" then
    game.pushPopUp("mail")
    game.loadNewsFlash("mailbox")
  end
end
function ContextBar.goals_oninit(element)
  if game.disableMenuBackButton() then
    manager:setButtonEnabled("btn_close", false)
  end
  if game.getPopUp() ~= "goals" then
    game.pushPopUp("goals")
  end
end
function ContextBar.tribal_goals_oninit(element)
  if game.getPopUp() ~= "tribal_goals" then
    game.pushPopUp("tribal_goals")
  end
end
function ContextBar.close_goals(element)
  game.updateQuestBadges()
  manager:setContext(manager:reserveState())
  game.popPopUp()
end
function ContextBar.close_mail(element)
  game.closeMail()
end
function ContextBar.goals_help(element)
  game.displayNotification("GOALS_HELP_DESC")
end
function ContextBar.close_to_reserve(element)
  manager:setContext(manager:reserveState())
  game.popPopUp()
end
function ContextBar.close_to_default(element)
  manager:setContext(manager:getDefaultContext())
  game.popPopUp()
end
function ContextBar.close_friend_options(element)
  manager:setContext("FRIEND_DEFAULT")
  game.popPopUp()
end
function ContextBar.credits_oninit(element)
  if game.getPopUp() ~= "credits" then
    game.pushPopUp("credits")
  end
end
function ContextBar.close_credits(element)
  game.popPopUp()
  manager:setContext("OPTIONS")
end
function ContextBar.controller_oninit(element)
  if game.getPopUp() ~= "ControllerScheme" then
    game.pushPopUp("ControllerScheme")
  end
end
function ContextBar.close_controller_scheme(element)
  game.popPopUp()
  manager:setContext("OPTIONS")
end
function ContextBar.close_controller_scheme_tutorial(element)
  game.popPopUp()
end
function ContextBar.cancel_move(element)
  game.moveObjectDone(false)
  manager:setContext(manager:getDefaultContext())
  game.popPopUp()
end
function ContextBar.confirm_move(element)
  game.popPopUp()
  game.moveObjectDone(true)
  if game.isQABuild() then
    if game.selectedObjIsMonster() then
      local monster = game.selectedMonster()
      if game.currentIsland() == game.IslandType_GOLD then
        manager:setContext("GOLD_MONSTER")
      elseif monster:isUnderling() then
        manager:setContext("UNDERLING_ACTIVE_HAPPINESS")
      elseif game.isZapMonster() then
        manager:setContext("UNDERLING_ACTIVE")
      elseif game.isComposerIsland() then
        manager:setContext("COMPOSER_MONSTER")
      elseif game.isBattleIsland() then
        manager:setContext("BATTLE_MONSTER")
      else
        manager:setContext("MONSTER")
      end
    end
  else
    manager:setContext(manager:getDefaultContext())
  end
end
function ContextBar.monster_context_oninit(element)
  game.updateMonsterHud()
  local selectedMonster = game.SelectedObject()
  if selectedMonster == nil then
    manager:setContextImmediate(manager:getDefaultContext())
    game.deselectSelectedObject()
    return
  end
  local uniqueMonsterId = game.selectedMonsterId()
  local megaButton = manager:getButton("btn_mega")
  local megaSaleIndicator
  if megaButton ~= nil then
    if game.tutorialDisableExtraFeatures() then
      manager:setButtonEnabled("btn_mega", false)
      megaButton("ReactToTouches"):SetInt(0)
      manager:setButtonFunction("btn_mega", "megaLockedPopup")
      megaButton.Touch("enabled"):SetInt(1)
      megaSaleIndicator = megaButton:GetElement("attachedTemplate")
      if megaSaleIndicator ~= nil then
        megaSaleIndicator:SetInvisible()
      end
    elseif game.isMega_TurnedOn() then
      manager:changeButton("btn_mega", "button_un_megafy", "CONTEXTBAR_UNMEGAFY", "unmegafy")
    elseif game.isMega_TurnedOff() then
      if game.isPermaMega() then
        manager:changeButton("btn_mega", "button_perm_megafy", "CONTEXTBAR_REMEGAFY", "remegafy")
      else
        manager:changeButton("btn_mega", "button_temp_megafy", "CONTEXTBAR_REMEGAFY", "remegafy")
      end
    end
  end
  local filteredCostumes = CostumesHelper.GetFilteredCostumes(uniqueMonsterId)
  if 1 >= filteredCostumes:size() or not game.teleportingUnlocked() or game.battleTutActive() then
    manager:rightShiftFrom("btn_costume", true)
  end
  local canCollect = not game.isMonsterSoulLinked(uniqueMonsterId)
  if not canCollect then
    manager:rightShiftFrom("btn_collect", true)
  elseif game.isEtherealIsland() then
    manager:setButtonImg("btn_collect", "button_collect_shard")
  elseif game.isAmberIsland() then
    manager:setButtonImg("btn_collect", "button_collect_relic")
  end
  if game.monsterLevel(uniqueMonsterId) >= 20 or game.objectFoodRequired() == 0 or game.disableFeedButton() then
    manager:rightShiftFrom("btn_feed", true)
  end
  if not game.isTeleportableMonster(uniqueMonsterId) and not game.canEventuallySendToBattleIsland(uniqueMonsterId) then
    manager:rightShiftFrom("btn_teleport", true)
  elseif not game.teleportingUnlocked() then
    manager:setButtonEnabled("btn_teleport", false)
    local teleportButton = manager:getButton("btn_teleport")
    if teleportButton ~= nil then
      teleportButton("ReactToTouches"):SetInt(0)
      manager:setButtonFunction("btn_teleport", "show_teleport_locked_message")
      teleportButton.Touch("enabled"):SetInt(1)
    end
  end
  local canSendToPaironormal = game.canSendToPaironormalIsland(selectedMonster:monsterTypeId()) and game.currentIsland() ~= game.IslandType_PAIRONORMAL
  local canSendToMagicalNexus = game.canEventuallySendToMagicalNexus(uniqueMonsterId) and not game.isMagicalSanctumIsland()
  local showTransposeButton = game.teleportingUnlocked() and (canSendToMagicalNexus or canSendToPaironormal)
  if canSendToPaironormal then
    manager:setButtonImg("btn_transpose", "button_transpose_paironormal")
  end
  if not showTransposeButton then
    manager:rightShiftFrom("btn_transpose", true)
  end
  if not game.showBoxMonsterContextButton() then
    manager:rightShiftFrom("btn_box_it", true)
  end
  local costumeButton = manager:getButton("btn_costume")
  if costumeButton ~= nil then
    local costumeSaleIndicator = costumeButton:GetElement("attachedTemplate")
    if costumeSaleIndicator ~= nil then
      if game.activeCostumeEvent(uniqueMonsterId) then
        costumeSaleIndicator("setNewScale"):SetFloat(game.hudScale())
        costumeSaleIndicator:SetVisible()
      else
        costumeSaleIndicator:SetInvisible()
      end
    end
  end
  megaButton = manager:getButton("btn_mega")
  if megaButton ~= nil then
    megaSaleIndicator = megaButton:GetElement("attachedTemplate")
    if megaSaleIndicator ~= nil then
      if not game.permaMegaSale() then
        megaSaleIndicator:SetInvisible()
      elseif game.isPermaMega() then
        megaSaleIndicator:SetInvisible()
      else
        megaSaleIndicator("setNewScale"):SetFloat(game.hudScale())
        megaSaleIndicator:SetVisible()
      end
    end
  end
end
function ContextBar.show_teleport_locked_message(element)
  game.displayNotification("TELEPORT_BUTTON_LOCKED_DESC")
end
function ContextBar.box_monster_context_oninit(element)
  game.updateMonsterHud()
  if game.numEggsInInventory() ~= game.minNumEggsRequiredInUnderling() then
    manager:rightShiftFrom("btn_powerup", true)
  end
end
function ContextBar.gold_box_monster_context_oninit(element)
  if game.numEggsInInventory() ~= game.minNumEggsRequiredInUnderling() then
    manager:rightShiftFrom("btn_powerup", true)
  end
end
function ContextBar.gold_evolving_monster_oninit(element)
  game.updateMonsterHud()
  if game.numEggsInInventory() ~= game.minNumEggsRequiredInUnderling() then
    manager:rightShiftFrom("btn_powerup", true)
  end
end
function ContextBar.view_gold_box_inventory(element)
  if game.isObjectSelected() then
    manager:setContext("BOX_INVENTORY_MENU")
  end
end
function ContextBar.powerup_gold_box(element)
  if game.activateBoxMonster() then
    game.popPopUp()
    if game.currentIsland() == game.IslandType_GOLD then
      manager:setContext("GOLD_MONSTER")
    end
  else
  end
end
function ContextBar.active_underling_context_oninit(element)
  game.updateMonsterHud()
  local uniqueMonsterId = game.selectedMonsterId()
  if manager:getButton("btn_costume") ~= nil then
    local filteredCostumes = CostumesHelper.GetFilteredCostumes(uniqueMonsterId)
    if filteredCostumes:size() <= 1 or not game.teleportingUnlocked() or game.battleTutActive() then
      manager:rightShiftFrom("btn_costume", true)
    else
      local costumeSaleIndicator = manager:getButton("btn_costume"):GetElement("attachedTemplate")
      if costumeSaleIndicator ~= nil then
        if game.activeCostumeEvent(uniqueMonsterId) then
          costumeSaleIndicator("setNewScale"):SetFloat(game.hudScale())
          costumeSaleIndicator:SetVisible()
        else
          costumeSaleIndicator:SetInvisible()
        end
      end
    end
  end
  local megaButton = manager:getButton("btn_mega")
  if megaButton ~= nil then
    local megaSaleIndicator = megaButton:GetElement("attachedTemplate")
    if megaSaleIndicator ~= nil then
      if not game.permaMegaSale() then
        megaSaleIndicator:SetInvisible()
      elseif game.isPermaMega() then
        megaSaleIndicator:SetInvisible()
      else
        megaSaleIndicator("setNewScale"):SetFloat(game.hudScale())
        megaSaleIndicator:SetVisible()
      end
    end
    if game.playerLevel() < 4 then
      manager:setButtonEnabled("btn_mega", false)
      megaButton("ReactToTouches"):SetInt(0)
      manager:setButtonFunction("btn_mega", "megaLockedPopup")
      megaButton.Touch("enabled"):SetInt(1)
      megaSaleIndicator:SetInvisible()
    elseif game.isMega_TurnedOn() then
      manager:changeButton("btn_mega", "button_un_megafy", "CONTEXTBAR_UNMEGAFY", "unmegafy")
    elseif game.isMega_TurnedOff() then
      if game.isPermaMega() then
        manager:changeButton("btn_mega", "button_perm_megafy", "CONTEXTBAR_REMEGAFY", "remegafy")
      else
        manager:changeButton("btn_mega", "button_temp_megafy", "CONTEXTBAR_REMEGAFY", "remegafy")
      end
    end
  end
  if not game.showBoxMonsterContextButton() then
    manager:rightShiftFrom("btn_box_it", true)
  end
end
function ContextBar.noMoreEvolutionsOfType(element)
  game.notifyOfMaxWublinEvolutionsOfSelected()
end
function ContextBar.celestialsOutOfSeason(element)
  game.displayNotification("CELESTIAL_OUT_OF_SEASON")
end
function ContextBar.unlockUnderlingEvolution(element)
  local maxEvolves = game.selectedUnderlingMaxNumEvolvesAllowed()
  if maxEvolves ~= -1 then
    local txt = game.getLocalizedText("CONF_UNLOCK_UNDERLING_EVOLUTION")
    txt = select(1, txt:gsub("XXX", game.selectedUnderlingEvolveKeyCost()))
    txt = select(1, txt:gsub("YYY", game.selectedMonsterTypeNumEvolveUnlocks()))
    txt = select(1, txt:gsub("ZZZ", maxEvolves))
    game.displayConfirmation("UNLOCK_UNDERLING_EVOLUTION", txt)
  end
end
function ContextBar.unlockCelestialPowerup(element)
  local txt = game.getLocalizedText("CONF_UNLOCK_CELESTIAL_POWERUP")
  txt = select(1, txt:gsub("XXX", game.celestialAwakenKeyCost()))
  game.displayConfirmation("UNLOCK_CELESTIAL_POWERUP", txt)
end
function ContextBar.early_awaken(element)
  if not game.waitingForEarlyAwakenResponse() then
    local txt = game.getLocalizedText("CONF_CELESTIAL_EARLY_AWAKEN")
    txt = select(1, txt:gsub("XXX", game.selectedCelestialEarlyAwakenKeyCost()))
    game.displayConfirmation("ATTEMPT_EARLY_AWAKEN", txt)
  end
end
function ContextBar.earlyAwakenDisabled(element)
  game.displayNotification("NOTIF_EARLY_AWAKEN_DISABLED")
end
function ContextBar.evolving_underling_happiness_oninit(element)
  game.updateMonsterHud()
  if not game.showBoxMonsterContextButton() then
    manager:rightShiftFrom("btn_box_it", true)
  end
  if CostumesHelper.GetFilteredCostumes(game.selectedMonsterId()):size() <= 1 or not game.teleportingUnlocked() or game.battleTutActive() then
    manager:rightShiftFrom("btn_costume", true)
  else
    local costumeButton = manager:getButton("btn_costume")
    if costumeButton ~= nil then
      local attachedIndicator = costumeButton:GetElement("attachedTemplate")
      if attachedIndicator ~= nil then
        if game.activeCostumeEvent(game.selectedMonsterId()) then
          attachedIndicator("setNewScale"):SetFloat(game.hudScale())
          attachedIndicator:SetVisible()
        else
          attachedIndicator:SetInvisible()
        end
      end
    end
  end
  if game.isCelestialIsland() then
    if game.numEggsInInventory() == game.numEggsRequiredInUnderling() then
      manager:rightShiftFrom("early_waken", true)
    elseif game.showCelestialInventoryLock() then
      manager:rightShiftFrom("early_waken", true)
    else
      if not game.selectedMonsterEarlyAwakenEnabled() then
        local earlyAwakenButton = manager:getButton("early_waken")
        if earlyAwakenButton ~= nil then
          manager:setButtonEnabled("early_waken", false)
          earlyAwakenButton("ReactToTouches"):SetInt(0)
          manager:setButtonFunction("early_waken", "earlyAwakenDisabled")
          earlyAwakenButton.Touch("enabled"):SetInt(1)
          else
            manager:rightShiftFrom("early_waken", true)
          end
        end
      else
      end
    end
  if game.isCelestialIsland() then
    manager:setButtonImg("btn_powerup", "button_ascension")
    manager:setButtonLabel("btn_powerup", "CONTEXTBAR_AWAKEN_LABEL")
  elseif game.onGoldIsland() then
    manager:setButtonImg("btn_powerup", "button_power_up")
    manager:setButtonLabel("btn_powerup", "CONTEXTBAR_POWERUP_LABEL")
  else
    local rarity = game.monsterRarity(game.selectedMonsterId())
    if rarity == game.MonsterRarity_Common then
      manager:setButtonImg("btn_powerup", "button_evolve")
    elseif rarity == game.MonsterRarity_Rare then
      manager:setButtonImg("btn_powerup", "button_evolve_rare_epic")
    end
    manager:setButtonLabel("btn_powerup", "EVOLVE_WUBLIN")
  end
  local button = manager:getButton("btn_powerup")
  if button ~= nil then
    if game.celestialEvoPowerupUnlocked() then
      if button:GetElement("attachedTemplate") ~= nil then
        button:GetElement("attachedTemplate"):SetInvisible()
      end
    else
      manager:setButtonLabel("btn_powerup", "UNLOCK_UNDERLING_EVOLUTION")
      manager:setButtonFunction("btn_powerup", "unlockCelestialPowerup")
    end
  end
  if game.numEggsInInventory() ~= game.minNumEggsRequiredInUnderling() then
    manager:rightShiftFrom("btn_powerup", true)
  end
  local inventoryButton = manager:getButton("btn_inventory")
  if inventoryButton ~= nil then
    if game.isUnderlingIsland() then
      if game.underlingEvolutionUnlocked() then
        local inventoryButtonTemplate = inventoryButton:GetElement("attachedTemplate")
        if inventoryButtonTemplate ~= nil and not game.showInventoryUnderlingTimer() then
          inventoryButtonTemplate:SetInvisible()
        end
      else
        manager:changeAttachedTemplate("btn_inventory", "template_lockedEvolveIndicator")
        manager:setButtonLabel("btn_inventory", "UNLOCK_UNDERLING_EVOLUTION")
        if game.canEvolveMoreOfSelectedType() then
          manager:setButtonFunction("btn_inventory", "unlockUnderlingEvolution")
        else
          manager:setButtonEnabled("btn_inventory", false)
          inventoryButton("ReactToTouches"):SetInt(0)
          manager:setButtonFunction("btn_inventory", "noMoreEvolutionsOfType")
          local inventoryLockIndicator = inventoryButton:GetElement("attachedTemplate")
          if inventoryLockIndicator ~= nil then
            inventoryLockIndicator:SetDisabled()
          end
          inventoryButton.Touch("enabled"):SetInt(1)
        end
      end
    elseif game.isCelestialIsland() then
      if not game.showCelestialInventoryLock() then
        if not game.showInventoryUnderlingTimer() then
          inventoryButton:GetElement("attachedTemplate"):SetInvisible()
        end
      else
        manager:changeAttachedTemplate("btn_inventory", "template_lockedEvolveIndicator")
        manager:setButtonLabel("btn_inventory", "UNLOCK_UNDERLING_EVOLUTION")
        manager:setButtonEnabled("btn_inventory", false)
        inventoryButton("ReactToTouches"):SetInt(0)
        manager:setButtonFunction("btn_inventory", "celestialsOutOfSeason")
        inventoryButton:GetElement("attachedTemplate"):SetDisabled()
        inventoryButton.Touch("enabled"):SetInt(1)
      end
    end
  end
  if game.isHibernating(game.selectedMonsterId()) then
    manager:setButtonEnabled("btn_mute", false)
    local muteButton = manager:getButton("btn_mute")
    if muteButton ~= nil then
      muteButton("ReactToTouches"):SetInt(0)
      manager:setButtonFunction("btn_mute", "")
      muteButton.Touch("enabled"):SetInt(1)
    end
  end
  local megaButton = manager:getButton("btn_mega")
  if megaButton ~= nil then
    local megaSaleIndicator = megaButton:GetElement("attachedTemplate")
    if megaSaleIndicator ~= nil then
      if not game.permaMegaSale() then
        megaSaleIndicator:SetInvisible()
      elseif game.isPermaMega() then
        megaSaleIndicator:SetInvisible()
      else
        megaSaleIndicator("setNewScale"):SetFloat(game.hudScale())
        megaSaleIndicator:SetVisible()
      end
    end
    if game.playerLevel() < 4 then
      manager:setButtonEnabled("btn_mega", false)
      megaButton("ReactToTouches"):SetInt(0)
      manager:setButtonFunction("btn_mega", "megaLockedPopup")
      megaButton.Touch("enabled"):SetInt(1)
      if megaSaleIndicator ~= nil then
        megaSaleIndicator:SetInvisible()
      end
    elseif game.isMega_TurnedOn() then
      manager:changeButton("btn_mega", "button_un_megafy", "CONTEXTBAR_UNMEGAFY", "unmegafy")
    elseif game.isMega_TurnedOff() then
      if game.isPermaMega() then
        manager:changeButton("btn_mega", "button_perm_megafy", "CONTEXTBAR_REMEGAFY", "remegafy")
      else
        manager:changeButton("btn_mega", "button_temp_megafy", "CONTEXTBAR_REMEGAFY", "remegafy")
      end
    end
  end
end
function ContextBar.evolving_underling_oninit(element)
  game.updateMonsterHud()
  if not game.showBoxMonsterContextButton() then
    manager:rightShiftFrom("btn_box_it", true)
  end
  if game.isCelestialIsland() then
    if game.numEggsInInventory() == game.numEggsRequiredInUnderling() then
      manager:rightShiftFrom("early_waken", true)
    elseif game.showCelestialInventoryLock() then
      manager:rightShiftFrom("early_waken", true)
    else
      if not game.selectedMonsterEarlyAwakenEnabled() then
        local earlyAwakenButton = manager:getButton("early_waken")
        if earlyAwakenButton ~= nil then
          manager:setButtonEnabled("early_waken", false)
          earlyAwakenButton("ReactToTouches"):SetInt(0)
          manager:setButtonFunction("early_waken", "earlyAwakenDisabled")
          earlyAwakenButton.Touch("enabled"):SetInt(1)
          else
            manager:rightShiftFrom("early_waken", true)
          end
        end
      else
      end
    end
  if game.isCelestialIsland() then
    manager:setButtonImg("btn_powerup", "button_ascension")
    manager:setButtonLabel("btn_powerup", "CONTEXTBAR_AWAKEN_LABEL")
  elseif game.onGoldIsland() then
    manager:setButtonImg("btn_powerup", "button_power_up")
    manager:setButtonLabel("btn_powerup", "CONTEXTBAR_POWERUP_LABEL")
  else
    local rarity = game.monsterRarity(game.selectedMonsterId())
    if rarity == game.MonsterRarity_Common then
      manager:setButtonImg("btn_powerup", "button_evolve")
    elseif rarity == game.MonsterRarity_Rare then
      manager:setButtonImg("btn_powerup", "button_evolve_rare_epic")
    end
    manager:setButtonLabel("btn_powerup", "EVOLVE_WUBLIN")
  end
  local button = manager:getButton("btn_powerup")
  if button ~= nil then
    if game.celestialEvoPowerupUnlocked() then
      if button:GetElement("attachedTemplate") ~= nil then
        button:GetElement("attachedTemplate"):SetInvisible()
      end
    else
      manager:setButtonLabel("btn_powerup", "UNLOCK_UNDERLING_EVOLUTION")
      manager:setButtonFunction("btn_powerup", "unlockCelestialPowerup")
    end
  end
  if game.numEggsInInventory() ~= game.minNumEggsRequiredInUnderling() then
    manager:rightShiftFrom("btn_powerup", true)
  end
  local inventoryButton = manager:getButton("btn_inventory")
  if inventoryButton ~= nil then
    if game.isUnderlingIsland() then
      if game.underlingEvolutionUnlocked() then
        local inventoryButtonTemplate = inventoryButton:GetElement("attachedTemplate")
        if inventoryButtonTemplate ~= nil and not game.showInventoryUnderlingTimer() then
          inventoryButtonTemplate:SetInvisible()
        end
      else
        manager:changeAttachedTemplate("btn_inventory", "template_lockedEvolveIndicator")
        manager:setButtonLabel("btn_inventory", "UNLOCK_UNDERLING_EVOLUTION")
        if game.canEvolveMoreOfSelectedType() then
          manager:setButtonFunction("btn_inventory", "unlockUnderlingEvolution")
        else
          manager:setButtonEnabled("btn_inventory", false)
          inventoryButton("ReactToTouches"):SetInt(0)
          manager:setButtonFunction("btn_inventory", "noMoreEvolutionsOfType")
          local inventoryLockIndicator = inventoryButton:GetElement("attachedTemplate")
          if inventoryLockIndicator ~= nil then
            inventoryLockIndicator:SetDisabled()
          end
          inventoryButton.Touch("enabled"):SetInt(1)
        end
      end
    elseif game.isCelestialIsland() then
      if not game.showCelestialInventoryLock() then
        local inventoryButtonTemplate = inventoryButton:GetElement("attachedTemplate")
        if inventoryButtonTemplate ~= nil and not game.showInventoryUnderlingTimer() then
          inventoryButtonTemplate:SetInvisible()
        end
      else
        manager:changeAttachedTemplate("btn_inventory", "template_lockedEvolveIndicator")
        manager:setButtonLabel("btn_inventory", "UNLOCK_UNDERLING_EVOLUTION")
        manager:setButtonEnabled("btn_inventory", false)
        inventoryButton("ReactToTouches"):SetInt(0)
        manager:setButtonFunction("btn_inventory", "celestialsOutOfSeason")
        local inventoryButtonTemplate = inventoryButton:GetElement("attachedTemplate")
        if inventoryButtonTemplate ~= nil then
          inventoryButtonTemplate:SetDisabled()
        end
        inventoryButton.Touch("enabled"):SetInt(1)
      end
    end
  end
  if game.isHibernating(game.selectedMonsterId()) then
    manager:setButtonEnabled("btn_mute", false)
    local muteButton = manager:getButton("btn_mute")
    if muteButton ~= nil then
      muteButton("ReactToTouches"):SetInt(0)
      manager:setButtonFunction("btn_mute", "")
      muteButton.Touch("enabled"):SetInt(1)
    end
  end
  local megaButton = manager:getButton("btn_mega")
  if megaButton ~= nil then
    local megaSaleIndicator = megaButton:GetElement("attachedTemplate")
    if megaSaleIndicator ~= nil then
      if not game.permaMegaSale() then
        megaSaleIndicator:SetInvisible()
      elseif game.isPermaMega() then
        megaSaleIndicator:SetInvisible()
      else
        megaSaleIndicator("setNewScale"):SetFloat(game.hudScale())
        megaSaleIndicator:SetVisible()
      end
    end
    if game.playerLevel() < 4 then
      manager:setButtonEnabled("btn_mega", false)
      megaButton("ReactToTouches"):SetInt(0)
      manager:setButtonFunction("btn_mega", "megaLockedPopup")
      megaButton.Touch("enabled"):SetInt(1)
      if megaSaleIndicator ~= nil then
        megaSaleIndicator:SetInvisible()
      end
    elseif game.isMega_TurnedOn() then
      manager:changeButton("btn_mega", "button_un_megafy", "CONTEXTBAR_UNMEGAFY", "unmegafy")
    elseif game.isMega_TurnedOff() then
      if game.isPermaMega() then
        manager:changeButton("btn_mega", "button_perm_megafy", "CONTEXTBAR_REMEGAFY", "remegafy")
      else
        manager:changeButton("btn_mega", "button_temp_megafy", "CONTEXTBAR_REMEGAFY", "remegafy")
      end
    end
  end
end
function ContextBar.inactive_underling_context_oninit(element)
  game.updateMonsterHud()
  if game.numEggsInInventory() ~= game.minNumEggsRequiredInUnderling() then
    manager:rightShiftFrom("btn_powerup", true)
  elseif game.selectedMonsterIsZapMonster() then
    if game.isCelestialIsland() then
      manager:setButtonImg("btn_powerup", "button_revive")
      manager:setButtonLabel("btn_powerup", "WAKE_UP_CELESTIAL")
    elseif game.isAmberIsland() then
      manager:setButtonImg("btn_powerup", "button_to_nursery")
      manager:setButtonLabel("btn_powerup", "CONTEXTBAR_INCUBATE_LABEL")
    else
      manager:setButtonImg("btn_powerup", "button_wakeup")
      manager:setButtonLabel("btn_powerup", "WAKE_UP_UNDERLING")
    end
  else
    manager:setButtonImg("btn_powerup", "button_power_up")
    manager:setButtonLabel("btn_powerup", "CONTEXTBAR_POWERUP_LABEL")
  end
end
function ContextBar.tribal_monster_context_oninit(element)
  game.updateMonsterHud()
  game.updateAdminTribalMonster()
  if game.isObjectMuted() then
    manager:changeButton("btn_mute", "button_unmute", "CONTEXTBAR_UNMUTE_LABEL", "unmute_object")
  end
  if game.isSelectedMonsterOwner() == false or game.tribalTimeRemaining() <= 0 then
    local button = manager:getButton("btn_feed_food")
    if button ~= nil then
      local attachment = button.attachedTemplate
      if attachment ~= nil then
        attachment.Text("visible"):SetInt(0)
      end
    end
    button = manager:getButton("btn_feed_coins")
    if button ~= nil then
      local attachment = button.attachedTemplate
      if attachment ~= nil then
        attachment.Text("visible"):SetInt(0)
      end
    end
    button = manager:getButton("btn_feed_ethereal")
    if button ~= nil then
      local attachment = button.attachedTemplate
      if attachment ~= nil then
        attachment.Text("visible"):SetInt(0)
      end
    end
  end
  if game.isChief() == false then
    manager:rightShiftFrom("btn_move", true)
    manager:rightShiftFrom("btn_mute", true)
    manager:rightShiftFrom("btn_remove", true)
    if game.isSelectedMonsterOwner() == false or game.tribalTimeRemaining() <= 0 then
      manager:rightShiftFrom("btn_feed_ethereal", true)
      manager:rightShiftFrom("btn_feed_coins", true)
      manager:changeButton("btn_feed_food", "button_no", "CONTEXTBAR_CLOSE_LABEL", "basic_close")
    end
  elseif game.isSelectedMonsterOwner() == false or game.tribalTimeRemaining() <= 0 then
    manager:rightShiftFrom("btn_feed_food", true)
    manager:rightShiftFrom("btn_feed_coins", true)
    manager:rightShiftFrom("btn_feed_ethereal", true)
    if game.isSelectedMonsterOwner() == true then
      manager:rightShiftFrom("btn_remove", true)
    end
  else
    manager:rightShiftFrom("btn_remove", true)
  end
end
function ContextBar.basic_close(element)
  manager:setContext(manager:getDefaultContext())
  game.deselectSelectedObject()
end
function ContextBar.megaLockedPopup(element)
  game.displayNotification("POPUP_NO_MEGA_DURING_TUT")
end
function ContextBar.megamonster_context_oninit(element)
end
function ContextBar.mega_context(element)
  if game.getPopUp() ~= "megafy_popup" then
    game.pushPopUp("megafy_popup")
  end
  manager:setReserveState(manager:getContext())
  manager:setContext("MEGAFY_MONSTER")
end
function ContextBar.temp_megafy(element)
  game.makeMegaMonster(false)
  manager:setContext(manager:getDefaultContext())
  game.deselectSelectedObject()
end
function ContextBar.perma_megafy(element)
  game.makeMegaMonster(true)
  manager:setContext(manager:getDefaultContext())
  game.deselectSelectedObject()
end
function ContextBar.unmegafy(element)
  game.megaEnableMonster(false)
  manager:setContext(manager:getDefaultContext())
  game.deselectSelectedObject()
end
function ContextBar.remegafy(element)
  game.megaEnableMonster(true)
  manager:setContext(manager:getDefaultContext())
  game.deselectSelectedObject()
end
function ContextBar.close_megafy_popup(element)
  game.popPopUp()
  manager:setContext(manager:reserveState())
end
function ContextBar.breeding_occupied_oninit(element)
  if game.playerLevel() < 4 then
    manager:setButtonEnabled("btn_reduceTime", false)
  end
  if game.checkPlacementAvailable ~= nil and game.checkPlacementAvailable("shared_rewarded") == false then
    manager:rightShiftFrom("btn_reduceTime", true)
  end
end
function ContextBar.options_oninit(element)
  if game.getPopUp() ~= "options" then
    if game.getPopUp() ~= "MenuReduxElement_Root" then
      game.popPopUp()
    end
    game.pushPopUp("options")
    manager:setAlternateButtonMapping("btn_close", game.Esc)
  end
end
function ContextBar.google_play_oninit(element)
  if game.getPopUp() ~= "google_play" then
    game.pushPopUp("google_play")
    manager:setAlternateButtonMapping("btn_close", game.Esc)
  end
end
function ContextBar.game_circle_oninit(element)
  if game.getPopUp() ~= "game_circle" then
    game.pushPopUp("game_circle")
    manager:setAlternateButtonMapping("btn_close", game.Esc)
  end
end
function ContextBar.monster_box_info_oninit(element)
  if game.getPopUp() ~= "object_info" then
    game.pushPopUp("object_info")
    if game.monsterCount() == 1 then
      manager:setButtonEnabled("btn_sell", false)
      local sellButton = manager:getButton("btn_sell")
      if sellButton ~= nil then
        sellButton("ReactToTouches"):SetInt(0)
        manager:setButtonFunction("btn_sell", "show_sell_locked_message")
        sellButton.Touch("enabled"):SetInt(1)
      end
    end
    manager:setContextInfoVisible(true)
    manager:rightShiftFrom("btn_feed", true)
    if game.isEtherealIsland() then
      manager:setButtonImg("btn_sell", "button_sell_shard")
    elseif game.isAmberIsland() then
      manager:setButtonImg("btn_sell", "button_sell_relics")
    else
      manager:setButtonImg("btn_sell", "button_sell")
    end
  end
end
function ContextBar.sellable_structure_oninit(element)
  if game.isEtherealIsland() then
    manager:setButtonImg("btn_sell", "button_sell_shard")
  else
    manager:setButtonImg("btn_sell", "button_sell")
  end
end
function ContextBar.sellable_decoration_oninit(element)
  if game.isEtherealIsland() then
    manager:setButtonImg("btn_sell", "button_sell_shard")
  else
    manager:setButtonImg("btn_sell", "button_sell")
  end
  local cost = game.decorationCost()
  if cost == 0 then
    manager:rightShiftFrom("btn_buy_another", true)
  end
end
function ContextBar.sellable_buddy_oninit(element)
  if game.isEtherealIsland() then
    manager:setButtonImg("btn_sell", "button_sell_shard")
  else
    manager:setButtonImg("btn_sell", "button_sell")
  end
  if game.isFuzing() or game.numFuzerBuddies() == 2 then
    manager:rightShiftFrom("btn_storage", true)
  else
    local button = manager:getButton("btn_storage")
    if button ~= nil then
      local fuzeIndicator = button:GetElement("attachedTemplate")
      if fuzeIndicator ~= nil then
        local showSale = game.showShortenedFuzingPromoTag() and game.playerLevel() >= 4
        if showSale then
          fuzeIndicator:SetVisible()
        else
          fuzeIndicator:SetInvisible()
        end
      end
    end
  end
end
function ContextBar.buddy_oninit(element)
  game.pushPopUp("buddy_popup")
end
function ContextBar.mine_oninit(element)
  if game.isEtherealIsland() then
    manager:setButtonImg("btn_sell", "button_sell_shard")
  else
    manager:setButtonImg("btn_sell", "button_sell")
  end
  if game.structureUpgradeIsFree() or game.playerLevel() < 4 then
    manager:rightShiftFrom("btn_upgrade", true)
  elseif game.structureUpgradeIsPremium() and not game.premiumPlayer() then
    manager:setButtonEnabled("btn_upgrade", false)
    local upgradeButton = manager:getButton("btn_upgrade")
    if upgradeButton ~= nil then
      upgradeButton("ReactToTouches"):SetInt(0)
      manager:setButtonFunction("btn_upgrade", "premium_content_upgrade_popup")
      upgradeButton.Touch("enabled"):SetInt(1)
      upgradeButton.attachedTemplate.Text("visible"):SetInt(0)
    end
  end
end
function ContextBar.premium_content_upgrade_popup(element)
  local text = game.getLocalizedText("NOTIFICATION_PREMIUM_CONTENT")
  local upgradeName = game.getLocalizedText(game.upgradeStructureName())
  text = select(1, text:gsub("%%ITEM_NAME%%", upgradeName))
  game.displayNotification(text)
end
function ContextBar.monster_info_oninit(element)
  if game.getPopUp() ~= "object_info" then
    game.pushPopUp("object_info")
    if game.selectedObjType() ~= game.SpecificEntityType_MONSTER then
      manager:rightShiftFrom("btn_feed", true)
      manager:setContextInfoVisible(false)
      if game.selectedObjType() == game.SpecificEntityType_OBSTACLE or game.selectedObjType() == game.SpecificEntityType_NURSERY or game.selectedObjType() == game.SpecificEntityType_CASTLE or game.selectedObjType() == game.SpecificEntityType_HOTEL or game.selectedObjType() == game.SpecificEntityType_WAREHOUSE or game.selectedObjType() == game.SpecificEntityType_FUZER or game.selectedObjType() == game.SpecificEntityType_BREEDING or game.selectedObjType() == game.SpecificEntityType_BATTLE_GYM or game.selectedObjType() == game.SpecificEntityType_TORCH or game.selectedObjType() == game.SpecificEntityType_BAKERY or game.selectedObjType() == game.SpecificEntityType_CRUCIBLE or game.selectedObjType() == game.SpecificEntityType_AWAKENER or game.isBattleTrophy() or game.selectedObjType() == game.SpecificEntityType_ATTUNER or game.selectedObjType() == game.SpecificEntityType_SYNTHESIZER or game.selectedObjType() == game.SpecificEntityType_NUCLEUS or game.selectedObjType() == game.SpecificEntityType_DISH_HARMONIZER or game.selectedObjType() == game.SpecificEntityType_POLARITY_AMPLIFIER or game.selectedObjType() == game.SpecificEntityType_FUGUE then
        manager:rightShiftFrom("btn_sell", true)
      end
      if game.isEtherealIsland() then
        manager:setButtonImg("btn_sell", "button_sell_shard")
      else
        manager:setButtonImg("btn_sell", "button_sell")
      end
    else
      manager:setContextInfoVisible(true)
      if game.disableMenuBackButton() then
        manager:setButtonEnabled("btn_close", false)
        manager:setButtonEnabled("btn_sell", false)
      elseif game.monsterCount() == 1 then
        manager:setButtonEnabled("btn_sell", false)
        local sellButton = manager:getButton("btn_sell")
        if sellButton ~= nil then
          sellButton("ReactToTouches"):SetInt(0)
          manager:setButtonFunction("btn_sell", "show_sell_locked_message")
          sellButton.Touch("enabled"):SetInt(1)
        end
      end
      if game.monsterLevel(game.selectedMonsterId()) >= game.maxMonsterLevel() or game.objectFoodRequired() == 0 or game.disableFeedButton() or game.isMagicalNexusIsland() then
        manager:rightShiftFrom("btn_feed", true)
      end
      local monster = game.GetMonster(game.selectedMonsterId())
      if game.monsterBeingEvolved(game.selectedMonsterId()) or game.monsterBeingSynthesized(game.selectedMonsterId()) or monster:isReattuning() then
        manager:setButtonEnabled("btn_sell", false)
        manager:setButtonEnabled("btn_feed", false)
      end
      local percent = 0
      if game.monsterLevel(game.selectedMonsterId()) >= game.maxMonsterLevel() then
        percent = 1
      else
        percent = game.monsterTimesFed(game.selectedMonsterId()) / 4
      end
      manager:setProgressPercent("level", percent)
      local happiness = game.monsterHappiness(game.selectedMonsterId()) .. "%"
      manager:setProgressLabel("happiness", happiness)
      manager:setProgressPercent("happiness", game.monsterHappiness(game.selectedMonsterId()) / 100)
      if game.isEtherealIsland() then
        manager:setButtonImg("btn_sell", "button_sell_shard")
      elseif game.isAmberIsland() then
        manager:setButtonImg("btn_sell", "button_sell_relics")
      else
        manager:setButtonImg("btn_sell", "button_sell")
      end
    end
  end
end
function ContextBar.nexus_monster_info_oninit(element)
  if game.getPopUp() ~= "object_info_nexus" then
    game.pushPopUp("object_info_nexus")
    manager:setButtonImg("btn_sell", "button_sell_shard")
    manager:setContextInfoVisible(true)
    if game.disableMenuBackButton() then
      manager:setButtonEnabled("btn_close", false)
      manager:setButtonEnabled("btn_sell", false)
    elseif game.monsterCount() == 1 then
      manager:setButtonEnabled("btn_sell", false)
      local sellButton = manager:getButton("btn_sell")
      if sellButton ~= nil then
        sellButton("ReactToTouches"):SetInt(0)
        manager:setButtonFunction("btn_sell", "show_sell_locked_message")
        sellButton.Touch("enabled"):SetInt(1)
      end
    end
  end
end
function ContextBar.underling_info_oninit(element)
  if game.getPopUp() ~= "object_info_underling" then
    game.pushPopUp("object_info_underling")
    if game.monsterCount() == 1 then
      manager:setButtonEnabled("btn_sell", false)
      local sellButton = manager:getButton("btn_sell")
      if sellButton ~= nil then
        sellButton("ReactToTouches"):SetInt(0)
        manager:setButtonFunction("btn_sell", "show_sell_locked_message")
        sellButton.Touch("enabled"):SetInt(1)
      end
    end
    manager:setContextInfoVisible(true)
    if game.monsterLevel(game.selectedMonsterId()) >= game.maxMonsterLevel() or game.objectFoodRequired() == 0 then
      manager:rightShiftFrom("btn_feed", true)
    end
    if game.isEtherealIsland() then
      manager:setButtonImg("btn_sell", "button_sell_shard")
    elseif game.isAmberIsland() then
      manager:setButtonImg("btn_sell", "button_sell_relics")
    else
      manager:setButtonImg("btn_sell", "button_sell")
    end
  end
end
function ContextBar.breeding_oninit(element)
  if game.showTestBreedButton() then
    if manager:getButtonFunction("btn_help") ~= "" then
      manager:rightShiftFrom("btn_help", true)
    end
    manager:rightShiftFrom("btn_retry", true)
    local button = manager:getButton("btn_breed")
    if button ~= nil then
      local attachedIndicator = button:GetElement("attachedTemplate")
      if attachedIndicator ~= nil then
        if game.showBreedingPromoTag() then
          attachedIndicator:SetVisible()
          manager:setButtonImg("btn_breed", game.breedingPromoAltIcon())
        else
          attachedIndicator:SetInvisible()
        end
      end
    end
  else
    local button = manager:getButton("btn_breed")
    if button ~= nil then
      local attachedIndicator = button:GetElement("attachedTemplate")
      if attachedIndicator ~= nil then
        if game.showBreedingPromoTag() then
          attachedIndicator:SetVisible()
          manager:setButtonImg("btn_breed", game.breedingPromoAltIcon())
        else
          attachedIndicator:SetInvisible()
        end
      end
    end
    if game.showRetryBreedButton() then
      manager:setButtonEnabled("btn_retry", true)
    else
      manager:setButtonEnabled("btn_retry", false)
    end
    if game.playerLevel() < game.breedingRetryAvailableLevel() then
      manager:rightShiftFrom("btn_retry", true)
    end
    manager:rightShiftFrom("btn_breedtest", true)
    manager:rightShiftFrom("btn_selectEgg", true)
  end
  if game.getPopUp() ~= "breeding" then
    game.pushPopUp("breeding")
  end
end
function ContextBar.breeding_v2_oninit(element)
  if game.showTestBreedButton() then
    if manager:getButtonFunction("btn_help") ~= "" then
      manager:rightShiftFrom("btn_help", true)
    end
    manager:rightShiftFrom("btn_retry", true)
    local button = manager:getButton("btn_breed")
    if button ~= nil then
      local attachedIndicator = button:GetElement("attachedTemplate")
      if attachedIndicator ~= nil then
        if game.showBreedingPromoTag() then
          attachedIndicator:SetVisible()
          manager:setButtonImg("btn_breed", game.breedingPromoAltIcon())
        else
          attachedIndicator:SetInvisible()
        end
      end
    end
  else
    local button = manager:getButton("btn_breed")
    if button ~= nil then
      local attachedIndicator = button:GetElement("attachedTemplate")
      if attachedIndicator ~= nil then
        if game.showBreedingPromoTag() then
          attachedIndicator:SetVisible()
          manager:setButtonImg("btn_breed", game.breedingPromoAltIcon())
        else
          attachedIndicator:SetInvisible()
        end
      end
    end
    if game.showRetryBreedButton() then
      manager:setButtonEnabled("btn_retry", true)
    else
      manager:setButtonEnabled("btn_retry", false)
    end
    if game.playerLevel() < game.breedingRetryAvailableLevel() then
      manager:rightShiftFrom("btn_retry", true)
    end
    manager:rightShiftFrom("btn_breedtest", true)
    manager:rightShiftFrom("btn_selectEgg", true)
  end
  if not game.hasPopUp("breeding_v2") then
    game.pushPopUp("breeding_v2")
  end
end
function ContextBar.show_structure_guide(element)
  local selectedStructureType = game.selectedObjType()
  if element("allowClick"):GetInt() == 1 then
    element("allowClick"):SetInt(0)
    if selectedStructureType == game.SpecificEntityType_BREEDING then
      game.loadNewsFlash("help_breedingv2")
    elseif selectedStructureType == game.SpecificEntityType_SYNTHESIZER then
      game.loadNewsFlash("help_synthesizerv2")
    elseif selectedStructureType == game.SpecificEntityType_ATTUNER then
      game.loadNewsFlash("help_attunerv2")
    elseif selectedStructureType == game.SpecificEntityType_DISH_HARMONIZER then
      game.loadNewsFlash("help_dishharmonizerv2")
    elseif selectedStructureType == game.SpecificEntityType_FUGUE then
      game.loadNewsFlash("help_fugue2")
    end
  end
end
function ContextBar.breeding_structure_oninit(element)
  local island = game.player():getActiveIsland()
  if island and island:type() == game.IslandType_PAIRONORMAL and island:islandMode() == 1 then
    manager:rightShiftFrom("btn_breed", true)
    manager:rightShiftFrom("btn_upgrade", true)
    return
  end
  local button = manager:getButton("btn_breed")
  if button ~= nil then
    local attachedIndicator = button:GetElement("attachedTemplate")
    if attachedIndicator ~= nil then
      if game.showBreedingPromoTag() then
        attachedIndicator:SetVisible()
        manager:setButtonImg("btn_breed", game.breedingPromoAltIcon())
      else
        attachedIndicator:SetInvisible()
      end
    end
  end
  if not game.showRetryBreedButton() then
    manager:rightShiftFrom("btn_retry", true)
  end
  if game.structureUpgradeIsFree() or game.tutorialDisableExtraFeatures() then
    manager:rightShiftFrom("btn_upgrade", true)
  end
end
function ContextBar.castle_oninit(element)
  if game.selectedObjType() == game.SpecificEntityType_CASTLE then
    game.updateStructureHud()
    if game.canMuteIsland() == false then
      manager:rightShiftFrom("btn_mute_all", true)
    elseif game.allMuted() then
      manager:changeButton("btn_mute_all", "button_unmute_all", "CONTEXTBAR_UNMUTE_ALL_LABEL", "unmute_all")
    end
    if game.canMuteStructure() == false then
      manager:rightShiftFrom("btn_mute", true)
    end
    if game.tutorialDisableExtraFeatures() then
      manager:rightShiftFrom("btn_upgrade", true)
      manager:rightShiftFrom("btn_play", true)
      manager:rightShiftFrom("btn_scratch", true)
    elseif game.structureUpgradeIsFree() then
      manager:rightShiftFrom("btn_upgrade", true)
    end
  else
    manager:setContextImmediate(manager:getDefaultContext())
  end
end
function ContextBar.castle_no_upgrade_oninit(element)
  game.updateStructureHud()
  if game.canMuteIsland() == false then
    manager:rightShiftFrom("btn_mute_all", true)
  elseif game.allMuted() then
    manager:changeButton("btn_mute_all", "button_unmute_all", "CONTEXTBAR_UNMUTE_ALL_LABEL", "unmute_all")
  end
  if game.canMuteStructure() == false then
    manager:rightShiftFrom("btn_mute", true)
  end
  if game.tutorialDisableExtraFeatures() then
    manager:rightShiftFrom("btn_play", true)
    manager:rightShiftFrom("btn_scratch", true)
  elseif game.currentIsland() == game.IslandType_GOLD then
    manager:rightShiftFrom("btn_play", true)
  end
end
function ContextBar.bakery_oninit(element)
  if not game.bakeryHasSeasonalSnackAvailability() then
    local button = manager:getButton("btn_bake")
    if button ~= nil then
      local bakeAttachedIndicator = button:GetElement("attachedTemplate")
      if bakeAttachedIndicator ~= nil then
        bakeAttachedIndicator:SetInvisible()
      end
    end
  end
  if game.tutorialDisableBaking() then
    manager:rightShiftFrom("btn_bake", true)
    manager:rightShiftFrom("btn_rebake", true)
  elseif game.tutorialActive() then
    manager:rightShiftFrom("btn_rebake", true)
  end
end
function ContextBar.crucible_oninit(element)
  if game.crucibleFullyUnlocked() then
    if not game.heatToDissipate() then
      manager:setButtonEnabled("btn_retrieve", false)
      local retrieveButton = manager:getButton("btn_retrieve")
      if retrieveButton ~= nil then
        retrieveButton("ReactToTouches"):SetInt(0)
        retrieveButton.Touch("enabled"):SetInt(1)
      end
    else
      game.crucibleTutCheck()
    end
    if game.structureUpgradeIsFree() then
      manager:setButtonVisible("btn_upgrade", false)
    end
    if game.numCrucibleHeatLevels() > 3 then
      manager:setButtonImg("btn_evolve", "button_evolve_both")
    end
    local evolveButton = manager:getButton("btn_evolve")
    if evolveButton ~= nil then
      local attachedIndicator = evolveButton:GetElement("attachedTemplate")
      if attachedIndicator ~= nil then
        if game.showCrucibleEvolveSaleTag() then
          attachedIndicator.Tag("spriteName"):SetString("sale_tag_updated_taller")
          attachedIndicator.Text("text"):SetString(game.localizedUpper("SALE_LABEL"))
          attachedIndicator:SetVisible()
        elseif game.showCrucibleEvolvePromoTag() then
          attachedIndicator:SetVisible()
        else
          attachedIndicator:SetInvisible()
        end
      end
    end
  else
    manager:setButtonVisible("btn_upgrade", false)
    manager:setButtonVisible("btn_retrieve", false)
    manager:setButtonVisible("btn_evolve", false)
  end
end
function ContextBar.speedup_cruc_evolving(element)
  if game.diamondsRequiredToComplete(game.timeLeftToCrucEvolve()) > 0 then
    game.showSpeedUpMessage("AMBER_EVOLVE_SPEEDUP", "SPEED_UP_AMBER_EVOLVE", game.timeLeftToCrucEvolve(), 0, game.getEggGraphic(), "xml_resources/" .. game.getEggGraphic() .. ".xml")
  end
end
function ContextBar.speedup_cruc_evolving_video(element)
  if game.timeLeftToCrucEvolve() > 0 then
    game.showSpeedUpMessage("AMBER_EVOLVE_SPEEDUP_VIDEO", "SPEED_UP_AMBER_EVOLVE_VIDEO", game.timeLeftToCrucEvolve(), 1, game.getEggGraphic(), "xml_resources/" .. game.getEggGraphic() .. ".xml")
  end
end
function ContextBar.show_crucible_menu(element)
  local error = game.crucibleErrorCheck()
  if error == "" then
    if not game.crucibleEntranceKeyCostMet() then
      local keyCost = game.crucibleKeyAccessCost()
      local txt = game.getLocalizedText("CRUCIBLE_ACCESS_KEYS_NEEDED")
      txt = select(1, txt:gsub("XXX", keyCost))
      game.showNotEnoughCurrencyPrompt(game.PurchaseType_CRUCIBLE_ACCESS_keys, 0, game.CurrencyType_Keys, keyCost, txt)
    elseif not game.crucibleEntranceRelicCostMet() then
      local relicsCost = game.crucibleRelicAccessCost()
      local txt = game.getLocalizedText("CRUCIBLE_ACCESS_RELICS_NEEDED")
      txt = select(1, txt:gsub("XXX", relicsCost))
      game.showNotEnoughCurrencyPrompt(game.PurchaseType_CRUCIBLE_ACCESS_relics, 0, game.CurrencyType_Relics, relicsCost, txt)
    else
      manager:setContext("CRUCIBLE_MENU")
    end
  else
    game.displayNotification(error)
  end
end
function ContextBar.crucible_menu_oninit(element)
  if game.getPopUp() ~= "crucible_menu" then
    game.pushPopUp("crucible_menu")
  end
  if game.showRetryEvolveButton() then
    manager:setButtonEnabled("btn_retry", true)
  else
    manager:setButtonEnabled("btn_retry", false)
  end
  if not game.isQABuild() then
    manager:setButtonVisible("btn_evolvetest", false)
  end
end
function ContextBar.goto_retry_crucible(element)
  game.popPopUp()
  manager:setContext("RETRY_CRUCIBLE")
end
function ContextBar.retry_crucible_oninit(element)
  if game.getPopUp() ~= "popup_retry_evolve" then
    game.pushPopUp("popup_retry_evolve")
  end
end
function ContextBar.close_crucible_menu(element)
  game.popPopUp()
  if game.isObjectSelected() then
    manager:setContext("CRUCIBLE")
  else
    manager:setContext(manager:getDefaultContext())
  end
end
function ContextBar.retrieve_heat(element)
  if not game.heatToDissipate() then
    game.displayNotification("NO_HEAT_TO_RETRIEVE")
  else
    game.dissipateCrucibleHeat()
  end
end
function ContextBar.showSaletagOnMarket(element)
  return game.activeEventForCategory(game.StoreCategories_TYPE_MONSTER) or game.activeEventForCategory(game.StoreCategories_TYPE_COSTUMES) or game.activeEventForCategory(game.StoreCategories_TYPE_STRUCTURE) or game.activeEventForCategory(game.StoreCategories_TYPE_DECORATION) or game.activeEventForCategory(game.StoreCategories_TYPE_STARPOWER) or game.activeEventForCategory(game.StoreCategories_TYPE_CURRENCY)
end
function ContextBar.default_context_oninit(element)
  local collectAllButton = manager:getButton("btn_collect_all")
  if collectAllButton ~= nil then
    element("origTextScale"):SetFloat(collectAllButton.ButtonLabel("size"):GetFloat() / 0.5 / collectAllButton("ButtonScale"):GetFloat())
  end
  if game.numIslands() == 1 and game.playerLevel() < game.mapUnlockLevel() or game.tutorialDisableExtraFeatures() then
    manager:rightShiftFrom("btn_map", true)
    manager:rightShiftFrom("btn_book", true)
  end
  if game.tutorialDisableExtraFeatures() then
    manager:rightShiftFrom("btn_mail", true)
    manager:rightShiftFrom("btn_friends", true)
  end
  if game.disableMarketButton() then
    manager:setButtonEnabled("btn_market", false)
    local marketButton = manager:getButton("btn_market")
    if marketButton ~= nil then
      marketButton("ReactToTouches"):SetInt(0)
      marketButton.Touch("enabled"):SetInt(1)
    end
  end
  local mailButton = manager:getButton("btn_mail")
  if mailButton ~= nil and game.disableMailboxButton() then
    manager:setButtonEnabled("btn_mail", false)
    mailButton("ReactToTouches"):SetInt(0)
    mailButton.Touch("enabled"):SetInt(1)
  end
  if game.isComposerIsland() then
    manager:rightShiftFrom("btn_book", true)
  end
  local marketButton = manager:getButton("btn_market")
  if marketButton ~= nil then
    manager:setAlternateButtonMapping("btn_market", game.marketEnterButton())
    local attachedIndicator = marketButton:GetElement("attachedTemplate")
    if attachedIndicator ~= nil then
      if element:showSaletagOnMarket() then
        attachedIndicator("setNewScale"):SetFloat(game.hudScale())
        attachedIndicator:SetVisible()
      else
        attachedIndicator:SetInvisible()
      end
    end
  end
  local infoButton = manager:getButton("btn_info")
  if infoButton ~= nil then
    local themeIndicator = infoButton:GetElement("attachedTemplate")
    if themeIndicator ~= nil then
      if game.showIslandThemeTimedEvent(game.currentIsland()) then
        themeIndicator:SetEventVisible()
      else
        themeIndicator:SetEventInvisible()
      end
    end
  end
  if not game.collectAllUnlocked() then
    element:CollectAllHide()
  elseif game.collectAllDisabled() then
    if game.showCollectAllTimer() then
      element:CollectAllDisableWithTimer()
    else
      element:CollectAllDisableNoTimer()
    end
  else
    element:CollectAllEnable()
  end
  if game.getNewMail() == false then
    game.hideMailIndicator()
  end
  if game.getCurrentCardAlbumEvent() == nil then
    manager:rightShiftFrom("btn_album", true)
  end
end
function ContextBar.friend_context_oninit(element)
  if not ReportMenu.ShowTribeName() and not ReportMenu.ShowUserName() and not ReportMenu.ShowSongName() and not ReportMenu.ShowIslandDesign() then
    manager:rightShiftFrom("btn_report", true)
  end
  if game.isActiveFriendIslandRated() then
    manager:rightShiftFrom("btn_dislike", true)
    manager:rightShiftFrom("btn_like", true)
  end
end
function ContextBar.gold_context_oninit(element)
  if game.getNewMail() == false then
    game.hideMailIndicator()
  end
  local button = manager:getButton("btn_info")
  if button ~= nil then
    local themeIndicator = manager:getButton("btn_info"):GetElement("attachedTemplate")
    if themeIndicator ~= nil then
      if game.showIslandThemeTimedEvent(game.currentIsland()) then
        themeIndicator:SetEventVisible()
      else
        themeIndicator:SetEventInvisible()
      end
    end
  end
end
function ContextBar.tribal_context_oninit(element)
  if game.getNewMail() == false then
    game.hideMailIndicator()
  end
  local button = manager:getButton("btn_info")
  if button ~= nil then
    local themeIndicator = button:GetElement("attachedTemplate")
    if themeIndicator ~= nil then
      if game.showIslandThemeTimedEvent(game.currentIsland()) then
        themeIndicator:SetEventVisible()
      else
        themeIndicator:SetEventInvisible()
      end
    end
  end
  if game.showTribalPlace() == false then
    manager:changeButton("btn_place", "button_tribal_select", "CONTEXTBAR_PICK_ME_LABEL", "pick_my_monster")
  end
  button = manager:getButton("btn_tribal")
  if button ~= nil then
    local attachedIndicator = button:GetElement("attachedTemplate")
    if attachedIndicator ~= nil then
      if (game.numIslands() > 1 or game.playerLevel() >= 10) and (game.newTribalInviteNotice() or game.newTribalRequestNotice()) then
        attachedIndicator:DoStoredScript("show")
      else
        attachedIndicator:DoStoredScript("hide")
      end
    end
  end
end
function ContextBar.cancel_breeding(element)
  game.popPopUp()
  manager:setContext("BREEDING_IDLE")
end
function ContextBar.close_get_now(element)
  game.popPopUp()
  game.deselectSelectedObject()
  manager:setContext(manager:getDefaultContext())
end
function ContextBar.update_oninit(element)
end
function ContextBar.cancel_update(element)
  game.popPopUp()
  manager:setContext(manager:reserveState())
end
function ContextBar.close_bakery(element)
  game.popPopUp()
  if game.isBakeryUpgradable() then
    manager:setContext("BAKERY_IDLE")
  else
    manager:setContext("BAKERY_IDLE_NO_UPGRADE")
  end
end
function ContextBar.close_monster_info(element)
  game.popPopUp()
end
function ContextBar.close_monster_box(element)
  game.popPopUp()
  if game.currentIsland() == game.IslandType_GOLD then
    if game.isObjectSelected() and game.isActiveBoxMonster(game.selectedMonsterId()) and game.selectedIsEvolvableMonsterType() then
      manager:setContext("GOLD_EVOLVING_MONSTER")
    else
      manager:setContext("GOLD_BOX_MONSTER")
    end
  elseif game.isUnderlingIsland() or game.isCelestialIsland() or game.isAmberIsland() then
    if game.isObjectSelected() then
      if game.isInactiveBoxMonster(game.selectedMonsterId()) then
        manager:setContext("UNDERLING_INACTIVE")
      elseif game.selectedIsEvolvableMonsterType() then
        if game.isUnderlingIsland() then
          if game.selectedMonsterIsUnderling() then
            manager:setContext("EVOLVING_UNDERLING_HAPPINESS")
          else
            manager:setContext("EVOLVING_UNDERLING")
          end
        else
          manager:setContext("EVOLVING_CELESTIAL")
        end
      elseif game.selectedMonsterIsUnderling() then
        manager:setContext("UNDERLING_ACTIVE_HAPPINESS")
      else
        manager:setContext("UNDERLING_ACTIVE")
      end
    else
      manager:setContext(manager:getDefaultContext())
    end
  else
    manager:setContext("BOX_MONSTER")
  end
end
function ContextBar.close_underling_inventory(element)
  game.popPopUp()
  manager:setContext("UNDERLING_LIST")
end
function ContextBar.map_help_list_oninit(element)
  if game.getPopUp() ~= "help_newslist" then
    game.pushPopUp("help_newslist")
    game.loadNewsFlash("help_map")
  end
end
function ContextBar.close_island_select_conf(element)
  manager:setContext("BLANK")
  game.popPopUp()
end
function ContextBar.close_friend_map(element)
  if game.isAdmin() then
    game.closeFriendMenuAdmin()
  else
    game.popPopUp()
    if manager:reserveState() == "FRIEND_DEFAULT" then
      manager:setContext("FRIEND_DEFAULT")
    else
      manager:setContext("FRIENDS")
    end
  end
end
function ContextBar.admin_close_friend_map(element)
  manager:setReserveState(manager:getContext())
  element:close_friend_map()
end
function ContextBar.hatch_monster(element)
  local obj = game.SelectedObject()
  if obj and obj:isEggHolder() then
    local diamonds = obj:diamondsRequiredToCompleteAction()
    if diamonds > 0 then
      local timeRemaining = obj:secondsUntilActionDone()
      game.showSpeedUpMessage("HATCH_EGG_SPEEDUP", "SPEED_UP_HATCH_EGG", timeRemaining, 0, game.getEggGraphic(), "xml_resources/" .. game.getEggGraphic() .. ".xml")
    end
  end
end
function ContextBar.hatch_monster_video(element)
  local obj = game.SelectedObject()
  if obj and obj:isEggHolder() then
    local timeRemaining = obj:secondsUntilActionDone()
    if timeRemaining > 0 then
      game.showSpeedUpMessage("HATCH_EGG_SPEEDUP_VIDEO", "SPEED_UP_HATCH_EGG_VIDEO", timeRemaining, 1, game.getEggGraphic(), "xml_resources/" .. game.getEggGraphic() .. ".xml")
    end
  end
end
function ContextBar.remove_breeding(element)
  game.removeBreeding()
end
function ContextBar.finish_breeding(element)
  local obj = game.SelectedObject()
  if obj and obj:isBreeding() then
    local diamonds = obj:diamondsRequiredToCompleteAction()
    if diamonds > 0 then
      local timeRemaining = obj:secondsUntilActionDone()
      game.showSpeedUpMessage("FINISH_BREEDING_SPEEDUP", "SPEED_UP_BREEDING", timeRemaining, 0)
    else
      game.finishBreeding()
    end
  end
end
function ContextBar.finish_breeding_video(element)
  if game.timeLeftToBreed() > 0 then
    game.showSpeedUpMessage("FINISH_BREEDING_SPEEDUP_VIDEO", "SPEED_UP_BREEDING_VIDEO", game.timeLeftToBreed(), 1)
  else
    game.finishBreeding()
  end
end
function ContextBar.open_bake_menu(element)
  manager:setContext("BAKE_MENU")
end
function ContextBar.open_warp_time_menu(element)
  game.setTimeWarpMode(true)
  manager:setContext("WARP_TIME_MENU")
end
function ContextBar.open_breed_menu(element)
  local breedingMonsters = game.worldContext():getAvailableBreedingMonsters()
  if not BreedingRules.AtLeastTwoBreedable(breedingMonsters) then
    game.displayNotification("NOTIFICATION_BREEDING_ABOVE_LVL_4")
  elseif not BreedingRules.ValidRightSideExists(breedingMonsters) then
    if game.isLegendaryShuggaIsland() then
      game.displayNotification("NOTIFICATION_BREEDING_MUST_HAVE_SHUGA")
    elseif game.isMythicalIsland() then
      game.displayNotification("NOTIFICATION_BREEDING_MUST_HAVE_CAT")
    end
  elseif not BreedingRules.ValidLeftSideExists(breedingMonsters) then
    if game.isLegendaryShuggaIsland() then
      game.displayNotification("NOTIFICATION_BREEDING_MUST_HAVE_SHUGA")
    elseif game.isMythicalIsland() then
      game.displayNotification("NOTIFICATION_BREEDING_MUST_HAVE_CAT")
    end
  elseif game.isQABuild() then
    manager:setContext("BREED_MENU")
  else
    manager:setContext("BREED_MENU_V2")
  end
end
function ContextBar.bake_menu_oninit(element)
  if game.disableMenuBackButton() then
    manager:setButtonEnabled("btn_close", false)
  end
  if game.getPopUp() ~= "bakery" then
    game.pushPopUp("bakery")
  end
end
function ContextBar.upgrading_castle_oninit(element)
  game.updateStructureHud()
  if game.canMuteIsland() == false then
    manager:rightShiftFrom("btn_mute_all", true)
  elseif game.allMuted() then
    manager:changeButton("btn_mute_all", "button_unmute_all", "CONTEXTBAR_UNMUTE_ALL_LABEL", "unmute_all")
  end
  if game.canMuteStructure() == false then
    manager:rightShiftFrom("btn_mute", true)
  end
  if game.currentIsland() == game.IslandType_GOLD then
    manager:rightShiftFrom("btn_play", true)
    manager:rightShiftFrom("btn_reduceTime", true)
  elseif game.playerLevel() < 4 or game.checkPlacementAvailable ~= nil and game.checkPlacementAvailable("shared_rewarded") == false then
    manager:rightShiftFrom("btn_reduceTime", true)
  end
end
function ContextBar.finish_baking(element)
  local obj = game.SelectedObject()
  if obj and obj:isBakery() then
    local diamonds = obj:diamondsRequiredToCompleteAction()
    if diamonds > 0 then
      local timeRemaining = obj:secondsUntilActionDone()
      game.showSpeedUpMessage("FINISH_BAKING_SPEEDUP", "SPEED_UP_BAKING", timeRemaining, 0)
    else
      game.finishBaking()
    end
  end
end
function ContextBar.finish_baking_video(element)
  local obj = game.SelectedObject()
  if obj and obj:isBakery() then
    local timeRemaining = obj:secondsUntilActionDone()
    if timeRemaining > 0 then
      game.showSpeedUpMessage("FINISH_BAKING_SPEEDUP_VIDEO", "SPEED_UP_BAKING_VIDEO", timeRemaining, 1)
    else
      game.finishBaking()
    end
  end
end
function ContextBar.buy_spore(element)
  game.loadStoreContext(game.StoreCategories_TYPE_MONSTER)
end
function ContextBar.buy_another(element)
  game.buyAnotherDecoration()
end
function ContextBar.buy_another_monster(element)
  if game.isQABuild() then
    game.buyAnotherMonster()
  end
end
function ContextBar.buy_another_torch(element)
  game.buyAnotherTorch()
end
function ContextBar.friends_oninit(element)
  if game.getPopUp() ~= "social" then
    game.pushPopUp("social")
  end
end
function ContextBar.rank_oninit(element)
  if game.getPopUp() ~= "battle_rank_menu" then
    game.pushPopUp("battle_rank_menu")
  end
end
function ContextBar.set_prev_season(element)
  game.rankMenuChangeSeason(1)
  manager:changeButton("btn_toggle_season", "button_back", "LABEL_CURRENT", "set_cur_season")
  manager:setHFlipForButton("btn_toggle_season", 1)
end
function ContextBar.set_cur_season(element)
  game.rankMenuChangeSeason(0)
  manager:changeButton("btn_toggle_season", "button_back", "LABEL_PREVIOUS", "set_prev_season")
  manager:setHFlipForButton("btn_toggle_season", 0)
end
function ContextBar.friends_tribal_oninit(element)
  if game.getPopUp() ~= "friends_tribal" then
    game.pushPopUp("friends_tribal")
  end
end
function ContextBar.friends_invite_oninit(element)
  if game.getPopUp() ~= "friends_invite" then
    game.pushPopUp("friends_invite")
  end
end
function ContextBar.friends_discover_oninit(element)
  if game.getPopUp() ~= "discover_friends" then
    game.pushPopUp("discover_friends")
  end
end
function ContextBar.user_profile_menu_oninit(element)
  if game.getPopUp() ~= "user_profile" and game.getPopUp() ~= "user_profile_fav_select" then
    game.pushPopUp("user_profile")
  end
end
function ContextBar.close_user_profile_menu(element)
  game.popPopUp()
  local returningMenu = game.getPlayerProfileReturningMenu()
  if returningMenu == "social" then
    manager:setContext("FRIENDS")
  elseif returningMenu == "discover_friends" then
    manager:setContext("DISCOVER_FRIENDS")
  else
    manager:setContext(manager:reserveState())
  end
  game.setPlayerProfileReturningMenu("")
end
function ContextBar.user_profile_editor_menu_oninit(element)
  if game.getPopUp("user_profile_editor") == nil then
    game.pushPopUp("user_profile_editor")
  end
end
function ContextBar.cancel_user_profile_editor_menu(element)
  game.displayConfirmation("CONFIRM_USER_PROFILE_CANCEL", game.getLocalizedText("NOTIFICATION_PAINTING_CANCEL_BODY"))
end
function ContextBar.confirm_user_profile_editor_menu(element)
  game.displayConfirmation("CONFIRM_USER_PROFILE_SAVE", game.getLocalizedText("CONFIRM_USER_PROFILE_SAVE"))
end
function ContextBar.top_islands_oninit(element)
  if game.getPopUp() ~= "top_islands" then
    game.pushPopUp("top_islands")
  end
end
function ContextBar.top_composer_islands_oninit(element)
  if game.getPopUp() ~= "top_composer_islands" then
    game.pushPopUp("top_composer_islands")
  end
end
function ContextBar.top_tribal_islands_oninit(element)
  if game.getPopUp() ~= "top_tribal_islands" then
    game.pushPopUp("top_tribal_islands")
  end
end
function ContextBar.tribal_menu_oninit(element)
  if game.getPopUp() ~= "tribal" then
    game.pushPopUp("tribal")
  end
end
function ContextBar.tribal_choose_oninit(element)
  if game.getPopUp() ~= "tribalisland_choose" then
    game.pushPopUp("tribalisland_choose")
  end
end
function ContextBar.tribal_chief_oninit(element)
  if game.getPopUp() ~= "tribalisland_chief" then
    game.pushPopUp("tribalisland_chief")
  end
end
function ContextBar.close_friends(element)
  game.popPopUp()
  manager:setContext(manager:getDefaultContext())
end
function ContextBar.back_out_of_top_islands_select(element)
  game.popPopUp()
  manager:setContext("FRIENDS")
end
function ContextBar.close_tribal_choose(element)
  game.popPopUp()
  game.setMyTribeRequest(0)
  manager:setContext("TRIBAL_MENU")
end
function ContextBar.close_tribal_chief(element)
  game.popPopUp()
  manager:setContext("TRIBAL_MENU")
end
function ContextBar.close_friends_invite(element)
  game.popPopUp()
  manager:setContext("FRIENDS")
end
function ContextBar.close_friends_discover(element)
  game.popPopUp()
  manager:setContext("FRIENDS")
end
function ContextBar.close_top_islands(element)
  if game.getPopUp() ~= "top_island_select" then
    game.popPopUp()
    manager:setContext("TOP_ISLAND_SELECT")
    game.pushPopUp("top_island_select")
  end
end
function ContextBar.close_warp_time(element)
  manager:setContext("TIME_MACHINE")
  game.popPopUp()
  game.setTimeWarpMode(false)
end
function ContextBar.close_save_warp(element)
  manager:setContext("TIME_MACHINE")
  game.popPopUp()
  game.saveWarpSpeed()
end
function ContextBar.cancel_scale(element)
  game.cancelDecorationScale()
  game.moveObjectDone(false)
  manager:setContext(manager:getDefaultContext())
  game.popPopUp()
end
function ContextBar.confirm_scale(element)
  game.popPopUp()
  game.moveObjectDone(true)
  manager:setContext(manager:getDefaultContext())
end
function ContextBar.cancel_buddy_light(element)
  game.buddyLightDone(false)
  manager:setContext(manager:getDefaultContext())
  game.popPopUp()
end
function ContextBar.confirm_buddy_light(element)
  game.popPopUp()
  game.buddyLightDone(true)
  manager:setContext(manager:getDefaultContext())
end
function ContextBar.cancel_volume(element)
  game.setMonsterVolume(1)
  game.moveObjectDone(false)
  manager:setContext(manager:getDefaultContext())
  game.popPopUp()
end
function ContextBar.confirm_volume(element)
  game.popPopUp()
  game.moveObjectDone(true)
  manager:setContext(manager:getDefaultContext())
end
function ContextBar.go_home(element)
  game.loadWorldContext(true)
end
function ContextBar.warp_oninit(element)
  if game.getPopUp() ~= "warp_popup" then
    game.pushPopUp("warp_popup")
  end
end
function ContextBar.scale_oninit(element)
  if game.getPopUp() ~= "scale_popup" then
    game.startDecorationScale()
    if game.isSelectedObjectPlaceable() == false then
      manager:setButtonEnabled("btn_confirm", false)
    end
    if game.isBattleIsland() or game.isPaironormalIsland() then
      manager:setButtonVisible("btn_storage", false)
    elseif game.maxWarehouseCapacity() == 0 then
      manager:setButtonEnabled("btn_storage", false)
      local storeButton = manager:getButton("btn_storage")
      if storeButton ~= nil then
        storeButton("ReactToTouches"):SetInt(0)
        manager:setButtonFunction("btn_storage", "showNoWarehouseError")
        storeButton.Touch("enabled"):SetInt(1)
      end
    elseif game.isSelectedObjectInStorage() == true or game.isNewSelectedObject() == true then
      manager:setButtonEnabled("btn_storage", false)
    end
    game.pushPopUp("scale_popup")
  end
end
function ContextBar.showNoWarehouseError(element)
  game.showNoWarehouseError()
end
function ContextBar.volume_oninit(element)
  if game.isSelectedObjectPlaceable() == false then
    manager:setButtonEnabled("btn_confirm", false)
  end
  if game.selectedObjIsMonster() then
    local monster = game.GetMonster(game.selectedMonsterId())
    if game.isPaironormalIsland() then
      manager:setButtonVisible("btn_storage", false)
    elseif game.currentIsland() == game.IslandType_GOLD or game.currentIsland() == game.IslandType_TRIBAL or game.isUnderlingIsland() or game.isComposerIsland() or game.isCelestialIsland() or game.isMagicalNexusIsland() or game.isPaironormalIsland() or game.currentIsland() == game.IslandType_AMBER and game.isInactiveBoxMonster(game.selectedMonsterId()) or game.maxHotelBeds() == 0 or game.isSelectedObjectInStorage() == true or game.isNewSelectedObject() == true or game.disableCheckInButton() or game.monsterBeingSynthesized(game.selectedMonsterId()) or game.SelectedObject():isTitansoul() and 0 < game.SelectedObject():numSoulLinks() or monster:isReattuning() then
      manager:setButtonEnabled("btn_storage", false)
      local storeButton = manager:getButton("btn_storage")
      if storeButton ~= nil then
        storeButton("ReactToTouches"):SetInt(0)
        manager:setButtonFunction("btn_storage", "showDisabledHotelError")
        storeButton.Touch("enabled"):SetInt(1)
      end
    end
  end
  game.pushPopUp("volume_popup")
end
function ContextBar.showDisabledHotelError(element)
  if game.currentIsland() == game.IslandType_GOLD or game.currentIsland() == game.IslandType_TRIBAL or game.isUnderlingIsland() or game.isComposerIsland() or game.isCelestialIsland() or game.isMagicalNexusIsland() or game.isEtherealIslet() or game.isPaironormalIsland() then
    game.displayNotification("MSG_HOTEL_BAD_ISLAND")
  elseif game.currentIsland() == game.IslandType_AMBER and game.isInactiveBoxMonster(game.selectedMonsterId()) then
    game.displayNotification("MSG_HOTEL_NO_VESSELS")
  elseif game.isNewSelectedObject() == true then
    game.displayNotification("MSG_HOTEL_NEW_OBJ_DISABLE")
  elseif game.maxHotelBeds() == 0 then
    game.displayNotification("MSG_HOTEL_NONE")
  elseif game.isSelectedObjectInStorage() == true then
    game.displayNotification("MSG_HOTEL_ALREADY_IN_STORAGE")
  elseif game.disableCheckInButton() then
    game.displayNotification("MSG_HOTEL_TUTORIAL_DISABLE")
  elseif game.SelectedObject():isTitansoul() and 0 < game.SelectedObject():numSoulLinks() then
    game.displayNotification("MSG_HOTEL_TITANSOUL_UNLINK")
  end
end
function ContextBar.show_support(element)
  if game.getPopUp() ~= "help" then
    game.pushPopUp("help")
  end
end
function ContextBar.close_help(element)
  game.popPopUp()
  manager:setContext("OPTIONS")
end
function ContextBar.random_default_oninit(element)
  if not ReportMenu.ShowTribeName() and not ReportMenu.ShowUserName() and not ReportMenu.ShowSongName() and not ReportMenu.ShowIslandDesign() then
    manager:rightShiftFrom("btn_report", true)
  end
  if game.isActiveFriendIslandRated() then
    manager:rightShiftFrom("btn_like", true)
    manager:rightShiftFrom("btn_dislike", true)
  end
end
function ContextBar.visit_another(element)
  game.visitRandomUserDynamic()
end
function ContextBar.ranked_default_oninit(element)
  if game.isActiveFriendIslandRated() then
    manager:rightShiftFrom("btn_like", true)
    manager:rightShiftFrom("btn_dislike", true)
  end
  if not ReportMenu.ShowTribeName() and not ReportMenu.ShowUserName() and not ReportMenu.ShowSongName() and not ReportMenu.ShowIslandDesign() then
    manager:rightShiftFrom("btn_report", true)
  end
  if game.friendIslandRank() == 1 then
    manager:rightShiftFrom("btn_previous", true)
  end
end
function ContextBar.tribal_visit_oninit(element)
  if game.isIslandOwned(9) == true then
    manager:setButtonEnabled("btn_join", false)
    local joinButton = manager:getButton("btn_join")
    if joinButton ~= nil then
      joinButton("ReactToTouches"):SetInt(0)
      manager:setButtonFunction("btn_join", "showAlreadyInTribePopup")
      joinButton.Touch("enabled"):SetInt(1)
    end
  elseif game.getMyTribeRequest() ~= 0 then
    manager:setButtonEnabled("btn_join", false)
    local joinButton = manager:getButton("btn_join")
    if joinButton ~= nil then
      joinButton("ReactToTouches"):SetInt(0)
      if game.getMyTribeRequest() == game.currentlyVisitedTribeID() then
        manager:setButtonFunction("btn_join", "showAlreadyRequestedPopup")
      else
        manager:setButtonFunction("btn_join", "showWaitingOnTribalRequestPopup")
      end
      joinButton.Touch("enabled"):SetInt(1)
    end
  elseif game.currentFriendIsland() == 0 then
    manager:rightShiftFrom("btn_friendmap", true)
  end
  if not ReportMenu.ShowTribeName() and not ReportMenu.ShowUserName() and not ReportMenu.ShowSongName() and not ReportMenu.ShowIslandDesign() then
    manager:rightShiftFrom("btn_report", true)
  end
end
function ContextBar.top_tribe_visit_oninit(element)
  if not ReportMenu.ShowTribeName() and not ReportMenu.ShowUserName() and not ReportMenu.ShowSongName() and not ReportMenu.ShowIslandDesign() then
    manager:rightShiftFrom("btn_report", true)
  end
end
function ContextBar.showAlreadyInTribePopup(element)
  game.displayNotification("ALREADY_IN_TRIBE_NOTIFICATION")
end
function ContextBar.showWaitingOnTribalRequestPopup(element)
  game.displayNotification("WAITING_ON_PREV_REQUEST")
end
function ContextBar.showAlreadyRequestedPopup(element)
  game.displayNotification("ALREADY_REQUESTED_TO_JOIN_NOTIFICATION")
end
function ContextBar.join_tribe(element)
  game.joinVisitedTribe()
end
function ContextBar.visit_next_ranked(element)
  game.visitNextRankedIsland()
end
function ContextBar.visit_previous_ranked(element)
  game.visitPreviousRankedIsland()
end
function ContextBar.visit_next_toptribe(element)
  game.visitNextTopTribeIsland()
end
function ContextBar.visit_previous_toptribe(element)
  game.visitPreviousTopTribeIsland()
end
function ContextBar.report_user(element)
  manager:setContext("REPORT_USER")
end
function ContextBar.report_oninit(element)
  if game.getPopUp() ~= "report_user" then
    game.pushPopUp("report_user")
  end
end
function ContextBar.like_island(element)
  game.rateIsland(true)
  manager:setButtonVisible("btn_like", false)
  manager:setButtonVisible("btn_dislike", false)
end
function ContextBar.dislike_island(element)
  game.rateIsland(false)
  manager:setButtonVisible("btn_like", false)
  manager:setButtonVisible("btn_dislike", false)
end
function ContextBar.close_minigame_scratch(element)
  if game.isSpinWheelSpinning() == false then
    game.popTopPopUp()
    game.setScratchDismissed(true)
    manager:setContext(manager:getDefaultContext())
    game.deselectSelectedObject()
  end
end
function ContextBar.gold_place_monster_oninit(element)
  if game.getPopUp() ~= "goldisland_place" then
    game.pushPopUp("goldisland_place")
  end
end
function ContextBar.tribal_place_monster_oninit(element)
  if game.getPopUp() ~= "tribalisland_place" then
    game.pushPopUp("tribalisland_place")
  end
end
function ContextBar.show_tribal_place(element)
  manager:setContext("TRIBAL_PLACE_MONSTER")
end
function ContextBar.pick_my_monster(element)
  game.selectMyTribalMonster()
end
function ContextBar.show_place(element)
  manager:setContext("GOLD_PLACE_MONSTER")
end
function ContextBar.composer_monster_context_oninit(element)
  local costumeButton = manager:getButton("btn_costume")
  if costumeButton ~= nil then
    local attachedIndicator = costumeButton:GetElement("attachedTemplate")
    if attachedIndicator ~= nil then
      if game.activeCostumeEvent(game.selectedMonsterId()) then
        attachedIndicator("setNewScale"):SetFloat(game.hudScale())
        attachedIndicator:SetVisible()
      else
        attachedIndicator:SetInvisible()
      end
    end
  end
  local megaButton = manager:getButton("btn_mega")
  if megaButton ~= nil then
    local megaSaleIndicator = megaButton:GetElement("attachedTemplate")
    if megaSaleIndicator ~= nil then
      if not game.permaMegaSale() then
        megaSaleIndicator:SetInvisible()
      elseif game.isPermaMega() then
        megaSaleIndicator:SetInvisible()
      else
        megaSaleIndicator("setNewScale"):SetFloat(game.hudScale())
        megaSaleIndicator:SetVisible()
      end
    end
  end
  if game.composerIsBuddy() then
    manager:rightShiftFrom("btn_mega", true)
    manager:rightShiftFrom("btn_costume", true)
    manager:rightShiftFrom("btn_mute", true)
  else
    if game.isMega_TurnedOn() then
      manager:changeButton("btn_mega", "button_un_megafy", "CONTEXTBAR_UNMEGAFY", "unmegafy")
    elseif game.isMega_TurnedOff() then
      if game.isPermaMega() then
        manager:changeButton("btn_mega", "button_perm_megafy", "CONTEXTBAR_REMEGAFY", "remegafy")
      else
        manager:changeButton("btn_mega", "button_temp_megafy", "CONTEXTBAR_REMEGAFY", "remegafy")
      end
    end
    if CostumesHelper.GetFilteredCostumes(game.selectedMonsterId()):size() <= 1 or not game.teleportingUnlocked() or game.battleTutActive() then
      manager:rightShiftFrom("btn_costume", true)
    end
    if game.isObjectMuted() then
      manager:changeButton("btn_mute", "button_unmute", "CONTEXTBAR_UNMUTE_LABEL", "unmute_object")
    else
      manager:changeButton("btn_mute", "button_mute", "CONTEXTBAR_MUTE_LABEL", "mute_object")
    end
  end
end
function ContextBar.gold_monster_context_oninit(element)
  if game.showBoxMonsterContextButton() then
    manager:setButtonVisible("btn_box_it", true)
  else
    manager:setButtonVisible("btn_box_it", false)
  end
  if game.isObjectMuted() then
    manager:changeButton("btn_mute", "button_unmute", "CONTEXTBAR_UNMUTE_LABEL", "unmute_object")
  end
end
function ContextBar.remove_gold_monster(element)
  if game.selectedObjectIsActiveBoxMonster() then
    game.displayConfirmation("REMOVE_GOLD_BOX_MONSTER", "CONFIRM_REMOVE_GOLD_ACTIVE_BOX_MONSTER")
    manager:setContext(manager:getDefaultContext())
  else
    game.removeGoldMonster()
    manager:setContext(manager:getDefaultContext())
  end
end
function ContextBar.remove_tribal_monster(element)
  game.displayConfirmation("REMOVE_TRIBAL_MONSTER", "CONFIRM_REMOVE_TRIBAL_MONSTER")
end
function ContextBar.box_monster(element)
  game.boxMonster()
  manager:setReserveState(manager:getContext())
end
function ContextBar.show_sell_locked_message(element)
  game.displayNotification("SELL_MONSTER_LOCKED_MESSAGE")
end
function ContextBar.show_sell_locked_tutorial_message(element)
  game.displayNotification("TUTORIAL_LOCKED_FEATURE")
end
function ContextBar.show_gold_help(element)
  if game.getPopUp() ~= "help_gold" then
    game.pushPopUp("help_gold")
  end
end
function ContextBar.spin_oninit(element)
  manager:setButtonEnabled("btn_play_again", false)
  manager:setButtonEnabled("btn_watch_ad", false)
  if game.checkPlacementAvailable ~= nil and game.checkPlacementAvailable("shared_rewarded") == false then
    manager:setButtonVisible("btn_watch_ad", false)
  end
end
function ContextBar.scratch_play_again(element)
  local txt = game.getLocalizedText("SCRATCH_PLAY_AGAIN_DESC")
  txt = select(1, txt:gsub("%%cost%%", tostring(game.scratchDiamonds())))
  game.displayConfirmation("SCRATCH_PLAY_AGAIN", txt, game.StoreContext_SPRITE_DIAMOND, game.StoreContext_CURRENCY_SPRITESHEET)
end
function ContextBar.scratch_watch_ad(element)
  game.promptForFreeScratchWithAds()
end
function ContextBar.launch_scratch(element)
  game.setScratchDismissed(false)
  game.displayScratchGame("S")
end
function ContextBar.launch_monster_scratch(element)
  manager:setContext(manager:getDefaultContext())
  game.deselectSelectedObject()
  game.setScratchDismissed(false)
  game.displayScratchGame("M")
end
function ContextBar.test_monster_scratch(element)
  game.runScratchTest("M")
end
function ContextBar.bind_account_oninit(element)
  if game.getPopUp() ~= "bind_account" then
    game.pushPopUp("bind_account")
  end
end
function ContextBar.close_bind_account(element)
  game.popPopUp()
  game.setEmailToBind("")
  manager:setContext(manager:getDefaultContext())
end
function ContextBar.bind_email_oninit(element)
  if game.getPopUp() ~= "bind_email" then
    game.pushPopUp("bind_email")
  end
end
function ContextBar.back_to_bind_account(element)
  game.popPopUp()
  manager:setContext("BIND_ACCOUNT")
end
function ContextBar.bind_password_oninit(element)
  if game.getPopUp() ~= "bind_password" then
    game.pushPopUp("bind_password")
  end
end
function ContextBar.back_to_bind_email(element)
  game.popPopUp()
  manager:setContext("BIND_EMAIL")
end
function ContextBar.bind_apple_oninit(element)
  if game.getPopUp() ~= "bind_apple" then
    game.pushPopUp("bind_apple")
  end
end
function ContextBar.bind_amazon_oninit(element)
  if game.getPopUp() ~= "bind_amazon" then
    game.pushPopUp("bind_amazon")
  end
end
function ContextBar.bind_google_oninit(element)
  if game.getPopUp() ~= "bind_google" then
    game.pushPopUp("bind_google")
  end
end
function ContextBar.nursery_idle_oninit(element)
  if game.disableMarketButton() or not game.supportsScratchTicket() or game.tutorialDisableExtraFeatures() then
    manager:rightShiftFrom("btn_scratch", true)
  end
  if not game.showScratchTest() then
    manager:rightShiftFrom("btn_scratchTest", true)
  end
  if game.disableMarketButton() or game.tutorialDisableExtraFeatures() then
    manager:rightShiftFrom("btn_getegg", true)
    manager:rightShiftFrom("btn_upgrade", true)
  elseif game.isAmberIsland() then
    manager:setButtonImg("btn_getegg", "button_buy_vessel")
    manager:setButtonLabel("btn_getegg", "CONTEXTBAR_BUY_VESSEL_LABEL")
  end
end
function ContextBar.nursery_idle_oninit_no_upgrade(element)
  if game.disableMarketButton() or not game.supportsScratchTicket() or game.tutorialDisableExtraFeatures() then
    manager:rightShiftFrom("btn_scratch", true)
  end
  if not game.showScratchTest() then
    manager:rightShiftFrom("btn_scratchTest", true)
  end
  if game.disableMarketButton() or game.tutorialDisableExtraFeatures() then
    manager:rightShiftFrom("btn_getegg", true)
  end
  if game.isMagicalNexusIsland() then
    manager:setButtonImg("btn_getegg", "button_buy_orb")
    manager:setButtonLabel("btn_getegg", "CONTEXTBAR_BUY_ORB_LABEL")
    manager:rightShiftFrom("btn_move", true)
  end
  if game.canMoveSelected() == false then
    manager:rightShiftFrom("btn_move", true)
  end
end
function ContextBar.show_friend_help(element)
  if game.openHelpshiftFAQWithTag ~= nil then
    game.openHelpshiftFAQWithTag("friends")
  end
end
function ContextBar.back_top_islands(element)
  manager:setContext("BACK_TOP_ISLANDS")
end
function ContextBar.close_top_islands_incontext(element)
  game.popPopUp()
  manager:setContext("RANKED_DEFAULT")
end
function ContextBar.back_top_islands_oninit(element)
  game.backToCorrectTopIslands()
end
function ContextBar.nursery_occ_oninit(element)
  if game.tutorialDisableExtraFeatures() then
    manager:setButtonEnabled("btn_reduceTime", false)
  end
  if game.checkPlacementAvailable ~= nil and game.checkPlacementAvailable("shared_rewarded") == false then
    manager:rightShiftFrom("btn_reduceTime", true)
  end
  if game.isMagicalNexusIsland() or game.isEtherealIslet() then
    if game.eggReadyToHatch() then
      manager:rightShiftFrom("btn_hatch", true)
      manager:rightShiftFrom("btn_reduceTime", true)
    end
    manager:rightShiftFrom("btn_move", true)
  elseif game.canMoveSelected() == false then
    manager:rightShiftFrom("btn_move", true)
  end
end
function ContextBar.show_island_help(element)
  if game.openHelpshiftFAQSection ~= nil and game.openHelpshiftFAQWithTag ~= nil then
    local islandid = game.currentIsland()
    if islandid == game.IslandType_PLANT or islandid == game.IslandType_COLD or islandid == game.IslandType_AIR or islandid == game.IslandType_WATER or islandid == game.IslandType_EARTH then
      game.openHelpshiftFAQSection("GAMEPLAY")
    elseif islandid == game.IslandType_GOLD then
      game.openHelpshiftFAQSection("GOLD_ISLAND")
    elseif islandid == game.IslandType_ETHEREAL then
      game.openHelpshiftFAQWithTag("ethereal")
    elseif islandid == game.IslandType_SHUGGA then
      game.openHelpshiftFAQWithTag("shugabush")
    elseif islandid == game.IslandType_TRIBAL then
      game.openHelpshiftFAQSection("TRIBAL_ISLAND")
    elseif islandid == game.IslandType_UNDERLING then
      game.openHelpshiftFAQWithTag("wublin")
    elseif game.isComposerIsland() then
      game.openHelpshiftFAQSection("COMPOSER_ISLAND")
    elseif islandid == game.IslandType_CELESTIAL then
      game.openHelpshiftFAQWithTag("celestial")
    elseif game.isFireBasedIsland() then
      game.openHelpshiftFAQSection("FIRE_ISLANDS")
    elseif game.isMagicalIsland() then
      game.openHelpshiftFAQSection("MAGICAL_ISLANDS")
    elseif islandid == game.IslandType_MAGICAL_SANCTUM then
      game.openHelpshiftFAQWithTag("sanctum")
    elseif islandid == game.IslandType_BATTLE then
      game.openHelpshiftFAQSection("THE_COLOSSINGUM")
    elseif islandid == game.IslandType_SEASONAL then
      game.openHelpshiftFAQWithTag("seasonal-shanty")
    elseif islandid == game.IslandType_AMBER then
      game.openHelpshiftFAQSection("AMBER_ISLAND")
    elseif islandid == game.IslandType_MYTHICAL then
      game.openHelpshiftFAQWithTag("mythical")
    elseif islandid == game.IslandType_ETHEREAL_WORKSHOP then
      game.openHelpshiftFAQSection("ETHEREAL_WORKSHOP")
    elseif islandid == game.IslandType_MAGICAL_NEXUS then
      game.openHelpshiftFAQSection("MAGICAL_NEXUS")
    elseif game.isEtherealIslet() then
      game.openHelpshiftFAQSection("ETHEREAL_ISLETS")
    elseif islandid == game.IslandType_PAIRONORMAL then
      if game.player():getActiveIsland():islandMode() == 0 then
        game.openHelpshiftFAQWithTag("major-paironormal")
      elseif game.player():getActiveIsland():islandMode() == 1 then
        game.openHelpshiftFAQWithTag("minor-paironormal")
      end
    elseif game.isMirrorIsland(islandid) then
      game.openHelpshiftFAQSection("MIRROR_ISLANDS")
    end
    game.endIslandFirstTimeTutorial(islandid)
  end
end
function ContextBar.show_tribal_help(element)
  if game.openHelpshiftFAQSection ~= nil then
    game.openHelpshiftFAQSection("TRIBAL_ISLAND")
  end
end
function ContextBar.goto_retry_breed(element)
  local breedingv2 = game.getPopUp("breeding_v2")
  if breedingv2 then
    breedingv2:RetryBreed()
  else
    game.popPopUp()
    manager:setReserveState(manager:getContext())
    manager:setContext("RETRY_BREED")
  end
end
function ContextBar.retry_breed_oninit(element)
  if game.getPopUp() ~= "popup_retry_breed" then
    game.pushPopUp("popup_retry_breed")
  end
end
function ContextBar.notifications_oninit(element)
  if game.getPopUp() ~= "notifications" then
    game.checkNotificationSettings()
    game.pushPopUp("notifications")
  end
end
function ContextBar.close_context_popup(element)
  game.closeContextPopup()
end
function ContextBar.show_structure_help(element)
  if game.openHelpshiftFAQWithTag ~= nil then
    local selectedStructureType = game.selectedObjType()
    if selectedStructureType == game.SpecificEntityType_CASTLE then
      local islandid = game.currentIsland()
      if islandid == game.IslandType_GOLD then
        game.openHelpshiftFAQWithTag("castle-gold")
      elseif game.isComposerIsland() then
        game.openHelpshiftFAQWithTag("castle-composer")
      else
        game.openHelpshiftFAQWithTag("castle")
      end
    elseif selectedStructureType == game.SpecificEntityType_NURSERY then
      local islandid = game.currentIsland()
      if islandid == game.IslandType_MAGICAL_NEXUS then
        game.openHelpshiftFAQWithTag("stair-shaper")
      else
        game.openHelpshiftFAQWithTag("nursery")
      end
    elseif selectedStructureType == game.SpecificEntityType_BREEDING then
      game.openHelpshiftFAQWithTag("breeding")
    elseif selectedStructureType == game.SpecificEntityType_BAKERY then
      game.openHelpshiftFAQWithTag("bakery")
    elseif selectedStructureType == game.SpecificEntityType_FUZER then
      game.openHelpshiftFAQWithTag("fuzer")
    elseif selectedStructureType == game.SpecificEntityType_HAPPINESS_TREE then
      game.openHelpshiftFAQWithTag("unity-tree")
    elseif selectedStructureType == game.SpecificEntityType_MINE then
      game.openHelpshiftFAQWithTag("mine")
    elseif selectedStructureType == game.SpecificEntityType_RECORDING_STUDIO then
      game.openHelpshiftFAQWithTag("recording-studio")
    elseif selectedStructureType == game.SpecificEntityType_WAREHOUSE then
      game.openHelpshiftFAQWithTag("storage-shed")
    elseif selectedStructureType == game.SpecificEntityType_HOTEL then
      local islandid = game.currentIsland()
      if islandid == game.IslandType_BATTLE then
        game.openHelpshiftFAQWithTag("mess-hall")
      else
        game.openHelpshiftFAQWithTag("hotel")
      end
    elseif selectedStructureType == game.SpecificEntityType_TORCH then
      game.openHelpshiftFAQWithTag("wishing-torch")
    elseif selectedStructureType == game.SpecificEntityType_BATTLE_GYM then
      game.openHelpshiftFAQWithTag("conservatory")
    elseif selectedStructureType == game.SpecificEntityType_CRUCIBLE then
      game.openHelpshiftFAQWithTag("crucible")
    elseif selectedStructureType == game.SpecificEntityType_AWAKENER then
      game.openHelpshiftFAQWithTag("coloss-eye")
    elseif selectedStructureType == game.SpecificEntityType_ATTUNER then
      game.openHelpshiftFAQWithTag("attuner")
    elseif selectedStructureType == game.SpecificEntityType_SYNTHESIZER then
      game.openHelpshiftFAQWithTag("synthesizer")
    elseif selectedStructureType == game.SpecificEntityType_NUCLEUS then
      game.openHelpshiftFAQWithTag("nucleus")
    elseif selectedStructureType == game.SpecificEntityType_DISH_HARMONIZER then
      game.openHelpshiftFAQWithTag("dish-harmonizer")
    elseif selectedStructureType == game.SpecificEntityType_FUGUE then
      game.openHelpshiftFAQWithTag("help_fugue")
    else
      game.openHelpshiftFAQ()
    end
  end
end
function ContextBar.structure_help_list_oninit(element)
  if game.getPopUp() ~= "help_newslist" then
    local selectedStructureType = game.selectedObjType()
    game.pushPopUp("help_newslist")
    if selectedStructureType == game.SpecificEntityType_BREEDING then
      game.loadNewsFlash("help_breeding")
    elseif selectedStructureType == game.SpecificEntityType_SYNTHESIZER then
      game.loadNewsFlash("help_synthesizer")
    elseif selectedStructureType == game.SpecificEntityType_ATTUNER then
      game.loadNewsFlash("help_attuner")
    elseif selectedStructureType == game.SpecificEntityType_DISH_HARMONIZER then
      game.loadNewsFlash("help_dishharmonizer")
    end
  end
end
function ContextBar.show_time_machine_help(element)
  if game.openHelpshiftFAQWithTag ~= nil then
    game.openHelpshiftFAQWithTag("time-machine")
  end
end
function ContextBar.show_island_info(element)
  manager:setReserveState(manager:getContext())
  manager:setContext("ISLAND_INFO")
end
function ContextBar.island_info_oninit(element)
  local IslandPurchaseFanfare = include("IslandPurchaseFanfare")
  local currentIsland = game.currentIsland()
  if not IslandPurchaseFanfare.HasReplayCutscene(currentIsland) then
    manager:setButtonVisible("btn_intro", false)
  end
  if game.getPopUp() ~= "popup_island_info" then
    game.pushPopUp("popup_island_info")
  end
end
function ContextBar.close_island_info(element)
  game.popPopUp()
  manager:setContext(manager:reserveState())
end
function ContextBar.logout(element)
  game.logEvent("options_menu", "action", "logout")
  game.logout()
end
function ContextBar.gotMsgPlacementInfo(element, msg)
  local selectedStructureType = game.selectedObjType()
  if selectedStructureType == game.SpecificEntityType_BREEDING then
    if msg.name == "help_breedingv2" then
      element("allowClick"):SetInt(1)
      if game.getPopUp() ~= "newsflash" then
        game.pushPopUp("newsflash")
        game.topPopUp():GetVar("placement"):SetString("help_breedingv2")
        game.topPopUp():GetVar("index"):SetInt(0)
        game.topPopUp():DoStoredScript("setUpElements")
      end
    end
  elseif selectedStructureType == game.SpecificEntityType_SYNTHESIZER then
    if msg.name == "help_synthesizerv2" then
      element("allowClick"):SetInt(1)
      if game.getPopUp() ~= "newsflash" then
        game.pushPopUp("newsflash")
        game.topPopUp():GetVar("placement"):SetString("help_synthesizerv2")
        game.topPopUp():GetVar("index"):SetInt(0)
        game.topPopUp():DoStoredScript("setUpElements")
      end
    elseif msg.name == "tut_synthesizer" and game.getPopUp() ~= "newsflash" then
      game.pushPopUp("newsflash")
      game.topPopUp():GetVar("placement"):SetString("tut_synthesizer")
      game.topPopUp():DoStoredScript("setUpElements")
    end
  elseif selectedStructureType == game.SpecificEntityType_ATTUNER then
    if msg.name == "help_attunerv2" then
      element("allowClick"):SetInt(1)
      if game.getPopUp() ~= "newsflash" then
        game.pushPopUp("newsflash")
        game.topPopUp():GetVar("placement"):SetString("help_attunerv2")
        game.topPopUp():GetVar("index"):SetInt(0)
        game.topPopUp():DoStoredScript("setUpElements")
      end
    elseif msg.name == "tut_attuner" and game.getPopUp() ~= "newsflash" then
      game.pushPopUp("newsflash")
      game.topPopUp():GetVar("placement"):SetString("tut_attuner")
      game.topPopUp():DoStoredScript("setUpElements")
    end
  elseif selectedStructureType == game.SpecificEntityType_DISH_HARMONIZER then
    if msg.name == "help_dishharmonizerv2" then
      element("allowClick"):SetInt(1)
      if game.getPopUp() ~= "newsflash" then
        game.pushPopUp("newsflash")
        game.topPopUp():GetVar("placement"):SetString("help_dishharmonizerv2")
        game.topPopUp():GetVar("index"):SetInt(0)
        game.topPopUp():DoStoredScript("setUpElements")
      end
    elseif msg.name == "tut_dishharmonizer" and game.getPopUp() ~= "newsflash" then
      game.pushPopUp("newsflash")
      game.topPopUp():GetVar("placement"):SetString("tut_dishharmonizer")
      game.topPopUp():DoStoredScript("setUpElements")
    end
  elseif selectedStructureType == game.SpecificEntityType_FUGUE and msg.name == "help_fugue2" then
    element("allowClick"):SetInt(1)
    if game.getPopUp() ~= "newsflash" then
      game.pushPopUp("newsflash")
      game.topPopUp():GetVar("placement"):SetString("help_fugue2")
      game.topPopUp():GetVar("index"):SetInt(0)
      game.topPopUp():DoStoredScript("setUpElements")
    end
  end
end
function ContextBar.gotMsgPlacementInfoFail(element, msg)
  local selectedStructureType = game.selectedObjType()
  if selectedStructureType == game.SpecificEntityType_BREEDING then
    if msg.name == "help_breedingv2" then
      if game.getPopUp() == "breeding" then
        game.popPopUp()
      end
      element("allowClick"):SetInt(1)
      manager:setReserveState(manager:getContext())
      manager:setContext("STRUCTURE_HELP")
    end
  elseif selectedStructureType == game.SpecificEntityType_SYNTHESIZER then
    if msg.name == "help_synthesizerv2" then
      element("allowClick"):SetInt(1)
      manager:setReserveState(manager:getContext())
      manager:setContext("STRUCTURE_HELP")
    end
  elseif selectedStructureType == game.SpecificEntityType_ATTUNER then
    if msg.name == "help_attunerv2" then
      element("allowClick"):SetInt(1)
      manager:setReserveState(manager:getContext())
      manager:setContext("STRUCTURE_HELP")
    end
  elseif selectedStructureType == game.SpecificEntityType_DISH_HARMONIZER and msg.name == "help_dishharmonizerv2" then
    element("allowClick"):SetInt(1)
    manager:setReserveState(manager:getContext())
    manager:setContext("STRUCTURE_HELP")
  end
end
function ContextBar.gotMsgUpdateMailNotification(element, msg)
  local mailBtn = manager:getButton("btn_mail")
  if mailBtn then
    local mailIndicator = mailBtn:GetElement("attachedTemplate")
    if mailIndicator then
      mailIndicator:DoStoredScript("updateNotification")
    end
  end
end
function ContextBar.gotMsgPermission(element, msg)
  if msg.name == "FRIENDS" and msg.allowed then
    manager:setContext("FRIENDS")
  end
end
function ContextBar.gotMsgTutorialInitialized(element, msg)
  if manager:getContext() == "DEFAULT" then
    if game.tutorialDisableExtraFeatures() then
      manager:setButtonVisible("btn_map", false)
      manager:setButtonVisible("btn_book", false)
      manager:setButtonVisible("btn_mail", false)
      manager:setButtonVisible("btn_friends", false)
    end
    local button = manager:getButton("btn_market")
    if button then
      local attachedIndicator = button:GetElement("attachedTemplate")
      if attachedIndicator ~= nil then
        if element:showSaletagOnMarket() then
          attachedIndicator("setNewScale"):SetFloat(game.hudScale())
          attachedIndicator:SetVisible()
        else
          attachedIndicator:SetInvisible()
        end
      end
    end
  end
end
function ContextBar.gotMsgPlacementImageFail(element, msg)
  local selectedStructureType = game.selectedObjType()
  if selectedStructureType == game.SpecificEntityType_BREEDING then
    if msg.name == "help_breedingv2" then
      if game.getPopUp() == "breeding" then
        game.popPopUp()
      end
      element("allowClick"):SetInt(1)
      manager:setReserveState(manager:getContext())
      manager:setContext("STRUCTURE_HELP")
    end
  elseif selectedStructureType == game.SpecificEntityType_SYNTHESIZER then
    if msg.name == "help_synthesizerv2" then
      element("allowClick"):SetInt(1)
      manager:setReserveState(manager:getContext())
      manager:setContext("STRUCTURE_HELP")
    end
  elseif selectedStructureType == game.SpecificEntityType_ATTUNER then
    if msg.name == "help_attunerv2" then
      element("allowClick"):SetInt(1)
      manager:setReserveState(manager:getContext())
      manager:setContext("STRUCTURE_HELP")
    end
  elseif selectedStructureType == game.SpecificEntityType_DISH_HARMONIZER and msg.name == "help_dishharmonizerv2" then
    element("allowClick"):SetInt(1)
    manager:setReserveState(manager:getContext())
    manager:setContext("STRUCTURE_HELP")
  end
end
function ContextBar.teleportmonster_context_oninit(element)
end
function ContextBar.show_teleport_menu(element)
  if game.selectedObjIsMonster() and game.isMonsterSoulLinked(game.selectedMonsterId()) then
    game.displayConfirmation("CONFIRM_SOUL_UNLINK_TELEPORT", game.removeSoulLinkText())
  else
    if game.getPopUp() ~= "teleport_popup" then
      game.pushPopUp("teleport_popup")
    end
    manager:setContext("TELEPORT_MONSTER")
  end
end
function ContextBar.close_teleport_popup(element)
  game.popPopUp()
  manager:setContext("MONSTER")
end
function ContextBar.transposemonster_context_oninit(element)
end
function ContextBar.show_transpose_menu(element)
  if game.selectedObjIsMonster() and game.isMonsterSoulLinked(game.selectedMonsterId()) then
    game.displayConfirmation("CONFIRM_SOUL_UNLINK_TRANSPOSE", game.removeSoulLinkText())
  else
    local selectedMonster = game.SelectedObject()
    if selectedMonster:data():isPaironormal() and game.currentIsland() ~= game.IslandType_PAIRONORMAL then
      if game.canSendToPaironormalIsland(selectedMonster:monsterTypeId()) then
        if not game.isIslandOwned(game.IslandType_PAIRONORMAL) and game.isPaironormalMinor(selectedMonster:monsterTypeId()) then
          game.displayNotification("TRANSPOSE_PAIRONORMAL_ISLAND_NOT_OWNED")
          return
        end
        if selectedMonster:level() < game.paironormalTransposeLevel() then
          local notificationText = LOC("TRANSPOSE_PAIRONORMAL_MIN_MONSTER_LEVEL")
          notificationText = notificationText:gsub("%${LEVEL}", game.paironormalTransposeLevel())
          game.displayNotification(notificationText)
          return
        end
        local monsterId = selectedMonster:data():monsterId()
        local teleportCost = game.paironormalTransposeCost(monsterId)
        local teleportCurrency = game.paironormalTransposeCurrency(monsterId)
        if teleportCost == -1 or teleportCurrency == "" then
          return
        end
        local msg = game.getLocalizedText("TRANSPOSE_PAIRONORMAL_COST_CONFIRMATION")
        msg = msg:gsub("%${AMOUNT}", game.commaizeNumber(teleportCost))
        msg = msg:gsub("%${CURRENCY}", LOC(teleportCurrency))
        if teleportCurrency == "DIAMONDS" then
          msg = msg:gsub("%${COLOR}", game.StoreContext_diamondColourStr)
        else
          msg = msg:gsub("%${COLOR}", game.StoreContext_coinColourStr)
        end
        msg = msg:gsub("XXX", game.getMonsterName(selectedMonster:uniqueId()))
        game.displayConfirmation("TELEPORT_MONSTER_TO_PAIRONORMAL", msg)
      end
    else
      local selectedMonsterUniqueId = game.selectedMonsterId()
      if game.monsterLevel(selectedMonsterUniqueId) < game.magicalNexusMonsterLevel() then
        local notificationText = LOC("TRANSPOSE_MIN_MONSTER_LEVEL")
        notificationText = notificationText:gsub("%${LEVEL}", game.magicalNexusMonsterLevel())
        game.displayNotification(notificationText)
        return
      end
      local teleportCost = game.magicalNexusTeleportCost()
      local teleportCurrency = game.magicalNexusTeleportCurrency()
      if teleportCost == -1 or teleportCurrency == "" then
        return
      end
      local msg = game.getLocalizedText("TRANSPOSE_COST_CONFIRMATION")
      msg = msg:gsub("%${AMOUNT}", game.commaizeNumber(teleportCost))
      msg = msg:gsub("%${CURRENCY}", LOC(teleportCurrency))
      if teleportCurrency == "DIAMONDS" then
        msg = msg:gsub("%${COLOR}", game.StoreContext_diamondColourStr)
      else
        msg = msg:gsub("%${COLOR}", game.StoreContext_coinColourStr)
      end
      msg = msg:gsub("XXX", game.getMonsterName(selectedMonsterUniqueId))
      game.displayConfirmation("TELEPORT_MONSTER_TO_MAGICAL_NEXUS", msg)
    end
  end
end
function ContextBar.close_transpose_popup(element)
  game.popPopUp()
  manager:setContext("MONSTER")
end
function ContextBar.battle_monster_context_oninit(element)
  game.updateMonsterHud()
  local uniqueMonsterId = game.selectedMonsterId()
  local costumeButton = manager:getButton("btn_costume")
  if costumeButton ~= nil then
    local attachedIndicator = costumeButton:GetElement("attachedTemplate")
    if attachedIndicator ~= nil then
      if game.activeCostumeEvent(uniqueMonsterId) then
        attachedIndicator("setNewScale"):SetFloat(game.hudScale())
        attachedIndicator:SetVisible()
      else
        attachedIndicator:SetInvisible()
      end
    end
  end
  local megaButton = manager:getButton("btn_mega")
  if megaButton ~= nil then
    local megaSaleIndicator = megaButton:GetElement("attachedTemplate")
    if megaSaleIndicator ~= nil then
      if not game.permaMegaSale() then
        megaSaleIndicator:SetInvisible()
      elseif game.isPermaMega() then
        megaSaleIndicator:SetInvisible()
      else
        megaSaleIndicator("setNewScale"):SetFloat(game.hudScale())
        megaSaleIndicator:SetVisible()
      end
    end
    if game.playerLevel() < 4 then
      manager:setButtonEnabled("btn_mega", false)
      megaButton("ReactToTouches"):SetInt(0)
      manager:setButtonFunction("btn_mega", "megaLockedPopup")
      megaButton.Touch("enabled"):SetInt(1)
      if megaSaleIndicator ~= nil then
        megaSaleIndicator:SetInvisible()
      end
    elseif game.isMega_TurnedOn() then
      manager:changeButton("btn_mega", "button_un_megafy", "CONTEXTBAR_UNMEGAFY", "unmegafy")
    elseif game.isMega_TurnedOff() then
      if game.isPermaMega() then
        manager:changeButton("btn_mega", "button_perm_megafy", "CONTEXTBAR_REMEGAFY", "remegafy")
      else
        manager:changeButton("btn_mega", "button_temp_megafy", "CONTEXTBAR_REMEGAFY", "remegafy")
      end
    end
  end
  local trainingButton = manager:getButton("btn_training")
  if trainingButton ~= nil then
    if game.monsterLevel(uniqueMonsterId) >= game.getBattlePlayerData().maxTrainingLevel or game.monsterLevel(uniqueMonsterId) >= game.maxBattleMonsterLevel(uniqueMonsterId) then
      manager:setButtonEnabled("btn_training", false)
      trainingButton("ReactToTouches"):SetInt(0)
      manager:setButtonFunction("btn_training", "training_locked_max_training_level")
      trainingButton.Touch("enabled"):SetInt(1)
    elseif game.disableBattleTraining() then
      manager:setButtonEnabled("btn_training", false)
    end
  end
  manager:setContextInfoVisible(true)
end
function ContextBar.battle_monster_training_context_oninit(element)
  game.updateMonsterHud()
  local uniqueMonsterId = game.selectedMonsterId()
  local isTraining = game.isMonsterTraining(uniqueMonsterId) and game.getTrainingSecsRemaining(uniqueMonsterId) > 0
  if isTraining then
    manager:setButtonVisible("btn_speedup", true)
    if not game.battleTutActive() then
      manager:setButtonVisible("btn_reduceTime", true)
      element:hide_video_oninit()
    else
      manager:setButtonVisible("btn_reduceTime", false)
    end
  else
    manager:setButtonVisible("btn_speedup", false)
    manager:setButtonVisible("btn_reduceTime", false)
  end
  manager:setContextInfoVisible(true)
end
function ContextBar.show_battle_monster_info(element)
  manager:setReserveState(manager:getContext())
  manager:setContext("BATTLE_MONSTER_INFO")
end
function ContextBar.battle_monster_info_oninit(element)
  if game.getPopUp() ~= "battle_object_info" then
    game.pushPopUp("battle_object_info")
    if game.monsterCount() == 1 then
      manager:setButtonEnabled("btn_sell", false)
      local sellButton = manager:getButton("btn_sell")
      if sellButton ~= nil then
        sellButton("ReactToTouches"):SetInt(0)
        manager:setButtonFunction("btn_sell", "show_sell_locked_message")
        sellButton.Touch("enabled"):SetInt(1)
      end
    else
      local selectedMonsterId = game.selectedMonsterId()
      if game.isMonsterTraining(selectedMonsterId) then
        manager:setButtonEnabled("btn_sell", false)
        local sellButton = manager:getButton("btn_sell")
        if sellButton ~= nil then
          sellButton("ReactToTouches"):SetInt(0)
          manager:setButtonFunction("btn_sell", "show_battle_sell_training_message")
          sellButton.Touch("enabled"):SetInt(1)
        end
      end
    end
    manager:setContextInfoVisible(true)
    manager:setButtonImg("btn_sell", "button_sell")
  end
end
function ContextBar.show_battle_sell_training_message(element)
  game.displayNotification("BATTLE_SELL_MONSTER_TRAINING_NOTIFICATION")
end
function ContextBar.show_costumes(element)
  if game.getPopUp() ~= "costumes_popup" then
    game.pushPopUp("costumes_popup")
  end
  manager:setReserveState(manager:getContext())
  manager:setContext("COSTUME_MENU")
end
function ContextBar.costume_menu_oninit(element)
  if not game.isQABuild() then
    manager:setButtonVisible("btn_breedtest", false)
  end
end
function ContextBar.show_costume_help(element)
  if game.openHelpshiftFAQWithTag ~= nil then
    game.openHelpshiftFAQWithTag("costumes")
  end
end
function ContextBar.close_costume_help(element)
  if game.getPopUp() ~= "costumes_popup" then
    if game.getPopUp() == "help_newslist" then
      game.topPopUp():root():popPopUp()
    end
    game.pushPopUp("costumes_popup")
  end
  manager:setContext("COSTUME_MENU")
end
function ContextBar.show_battle_training_prompt(element)
  if game.getMonstersInGym():size() == game.getGymCapacity() then
    if game.getGymCapacity() == game.getAllGymCapacities():size() then
      game.displayConfirmation("GYM_FULL", "GYM_FULL_SPEED_TRAINING")
    else
      game.displayConfirmation("GYM_FULL_UPGRADE", "GYM_FULL_UPGRADE")
    end
  elseif game.getPopUp() ~= "battle_training_popup" then
    game.pushPopUp("battle_training_popup")
    manager:setReserveState(manager:getContext())
    manager:setContext("BATTLE_TRAINING_MENU")
  end
end
function ContextBar.battle_context_oninit(element)
  manager:setAlternateButtonMapping("btn_market", game.marketEnterButton())
  if game.getNewMail() == false then
    game.hideMailIndicator()
  end
  if game.disableMarketButton() then
    local marketButton = manager:getButton("btn_market")
    if marketButton ~= nil then
      manager:setButtonEnabled("btn_market", false)
      marketButton("ReactToTouches"):SetInt(0)
      marketButton.Touch("enabled"):SetInt(1)
    end
  end
  if game.disableMailboxButton() then
    local button = manager:getButton("btn_mail")
    if button ~= nil then
      manager:setButtonEnabled("btn_mail", false)
      button("ReactToTouches"):SetInt(0)
      button.Touch("enabled"):SetInt(1)
    end
  end
  local marketButton = manager:getButton("btn_market")
  if marketButton ~= nil then
    local attachedIndicator = marketButton:GetElement("attachedTemplate")
    if attachedIndicator ~= nil then
      if element:showSaletagOnMarket() then
        attachedIndicator("setNewScale"):SetFloat(game.hudScale())
        attachedIndicator:SetVisible()
      else
        attachedIndicator:SetInvisible()
      end
    end
  end
  local button = manager:getButton("btn_info")
  if button ~= nil then
    local themeIndicator = button:GetElement("attachedTemplate")
    if themeIndicator ~= nil then
      if game.showIslandThemeTimedEvent(game.currentIsland()) then
        themeIndicator:SetEventVisible()
      else
        themeIndicator:SetEventInvisible()
      end
    end
  end
end
function ContextBar.show_battle_type_select(element)
  manager:setContext("BATTLE_TYPE_SELECT")
end
function ContextBar.battle_type_select_oninit(element)
  if game.getPopUp() ~= "battle_type_select_popup" then
    game.pushPopUp("battle_type_select_popup")
  end
end
function ContextBar.show_battle_campaign_menu(element)
  manager:setContext("BATTLE_CAMPAIGN_MENU")
end
function ContextBar.battle_campaign_menu_oninit(element)
  if game.getPopUp() ~= "battle_campaign_popup" then
    game.pushPopUp("battle_campaign_popup")
  else
    local topPopUp = game.topPopUp()
    if topPopUp("showingInfo"):GetInt() == 1 then
      manager:setButtonImg("btn_close", "button_back")
      manager:setButtonLabel("btn_close", "BACK")
    end
  end
end
function ContextBar.close_campaign_menu(element)
  if game.getPopUp() ~= "battle_campaign_popup" then
    return
  end
  local battleMenu = game.topPopUp()
  if battleMenu("transitioning"):GetInt() ~= 1 then
    game.closeContextPopup()
  end
end
function ContextBar.back_campaign_menu(element)
  if game.getPopUp() ~= "battle_campaign_popup" then
    return
  end
  local battleMenu = game.topPopUp()
  if battleMenu("showingInfo"):GetInt() == 1 then
    if battleMenu.InfoPane.SelectMonstersPopup("IsShowing"):GetInt() == 1 then
      battleMenu.InfoPane.SelectMonstersPopup:DoStoredScript("hide")
    else
      battleMenu.ItemList:onCardUnselected()
      battleMenu("showingInfo"):SetInt(0)
      battleMenu:parent().ItemList.Swiper:GetVar("enableMouseScroll"):SetInt(1)
    end
  elseif battleMenu("showingExpiredInfo"):GetInt() == 1 then
    battleMenu.ItemList:onCardUnselected()
    battleMenu("showingExpiredInfo"):SetInt(0)
  end
end
function ContextBar.battle_team_menu_oninit(element)
  if game.getPopUp() ~= "battle_team_select_popup" then
    game.pushPopUp("battle_team_select_popup")
  end
end
function ContextBar.battle_training_menu_oninit(element)
  manager:setButtonVisible("btn_close", false)
end
function ContextBar.battle_gym_oninit(element)
  if game.structureUpgradeIsFree() then
    manager:setButtonVisible("btn_upgrade", false)
  end
end
function ContextBar.show_training_monsters(element)
  if game.getPopUp() ~= "battle_gym" then
    game.pushPopUp("battle_gym")
    manager:setReserveState(manager:getContext())
    manager:setContext("BATTLE_GYM_INVENTORY")
  end
end
function ContextBar.close_battle_gym(element)
  manager:setContext(manager:reserveState())
  game.popPopUp()
end
function ContextBar.battle_gym_inventory_selected_oninit(element)
  local monsterId = game.getSelectedGymMonsterID()
  local timeRemaining = game.getTrainingSecsRemaining(monsterId)
end
function ContextBar.complete_training(element)
  local monsterId = game.getSelectedGymMonsterID()
  local secondsRemaining = game.getTrainingSecsRemaining(monsterId)
  if secondsRemaining > 0 then
    game.showSpeedUpMessage("FINISH_TRAINING_SPEEDUP", "SPEED_UP_TRAINING", secondsRemaining, 0)
  else
    game.finishTrainingMonster(monsterId, false)
    manager:setContext("BATTLE_GYM_INVENTORY")
  end
end
function ContextBar.complete_training_from_placeholder(element)
  local monsterId = game.selectedMonsterId()
  local secondsRemaining = game.getTrainingSecsRemaining(monsterId)
  if secondsRemaining > 0 then
    game.showSpeedUpMessage("FINISH_TRAINING_SPEEDUP", "SPEED_UP_TRAINING", secondsRemaining, 0)
  end
end
function ContextBar.complete_training_from_placeholder_video(element)
  local monsterId = game.selectedMonsterId()
  local secondsRemaining = game.getTrainingSecsRemaining(monsterId)
  if secondsRemaining > 0 then
    game.showSpeedUpMessage("FINISH_TRAINING_SPEEDUP_VIDEO", "SPEED_UP_TRAINING_VIDEO", secondsRemaining, 1)
  end
end
function ContextBar.battle_hotel_oninit(element)
  if game.structureUpgradeIsFree() then
    manager:setButtonVisible("btn_upgrade", false)
  end
  if game.isBattleIslandMuted() then
    manager:changeButton("btn_mute", "button_unmute", "CONTEXTBAR_UNMUTE_LABEL", "unmute_battle_island")
  end
end
function ContextBar.mute_battle_island(element)
  game.muteBattleIsland(true)
  manager:changeButton("btn_mute", "button_unmute", "CONTEXTBAR_UNMUTE_LABEL", "unmute_battle_island")
end
function ContextBar.unmute_battle_island(element)
  game.muteBattleIsland(false)
  manager:changeButton("btn_mute", "button_mute", "CONTEXTBAR_MUTE_LABEL", "mute_battle_island")
end
function ContextBar.show_jukebox(element)
  manager:setReserveState(manager:getContext())
  manager:setContext("JUKEBOX")
end
function ContextBar.jukebox_oninit(element)
  if game.getPopUp() ~= "jukebox" then
    game.pushPopUp("jukebox")
  end
end
function ContextBar.training_locked_max_training_level(element)
  local uniqueMonsterId = game.selectedMonsterId()
  local monsterLevel = game.monsterLevel(uniqueMonsterId)
  local unlockCampaign
  local campaigns = game.getSortedBattleCampaignData()
  for i = 0, campaigns:size() - 1 do
    if monsterLevel < campaigns[i].maxTrainingLevel then
      unlockCampaign = campaigns[i]
      break
    end
  end
  if unlockCampaign then
    local text = LOC("NOTIFICATION_MAX_CAMPAIGN_TRAINING_LEVEL")
    text = text:gsub("%${CAMPAIGN}", LOC(unlockCampaign.name))
    game.displayNotification(text)
  else
    game.displayNotification("NOTIFICATION_MAX_TRAINING_LEVEL")
  end
end
function ContextBar.gotMsgMonsterTrainingStatusUpdated(element, msg)
  local selectedMonsterId = game.selectedMonsterId()
  if selectedMonsterId == msg.monsterId then
    if manager:getContext() == "BATTLE_MONSTER" and msg.isTraining then
      manager:setContext("BATTLE_MONSTER_TRAINING")
    elseif manager:getContext() == "BATTLE_MONSTER_TRAINING" and not msg.isTraining then
      manager:setContext("BATTLE_MONSTER")
    end
  end
end
function ContextBar.battle_versus_menu_oninit(element)
  if game.getPopUp() ~= "battle_versus_popup" then
    game.pushPopUp("battle_versus_popup")
  end
end
function ContextBar.battle_versus_menu_friends_oninit(element)
  if game.getPopUp() ~= "battle_versus_friends_popup" then
    game.pushPopUp("battle_versus_friends_popup")
  else
    local topPopUp = game.topPopUp()
    if topPopUp("showingSeasonInfo"):GetInt() == 1 then
      manager:setButtonImg("btn_close", "button_back")
      manager:setButtonLabel("btn_close", "BACK")
    end
  end
end
function ContextBar.close_versus_menu(element)
  if game.getPopUp() ~= "battle_versus_popup" then
    return
  end
  local versusMenu = game.topPopUp()
  if versusMenu("transitioning"):GetInt() ~= 1 then
    game.closeContextPopup()
  end
end
function ContextBar.back_versus_menu(element)
  if game.getPopUp() ~= "battle_versus_popup" then
    return
  end
  local versusMenu = game.topPopUp()
  if versusMenu("showingSeasonInfo"):GetInt() == 1 then
    if versusMenu.InfoPane.SelectMonstersPopup("IsShowing"):GetInt() == 1 then
      print("== Closing Select Monsters Popup ==")
      versusMenu.InfoPane.SelectMonstersPopup:DoStoredScript("hide")
      versusMenu("checkTimer"):SetInt(1)
    else
      print("== Closing Versus Season Info ==")
      versusMenu:hideSeasonInfo()
    end
  elseif versusMenu("showingChampionInfo"):GetInt() == 1 then
    if versusMenu.InfoPane.SelectMonstersPopup("IsShowing"):GetInt() == 1 then
      print("== Closing Select Monsters Popup ==")
      versusMenu.InfoPane.SelectMonstersPopup:DoStoredScript("hide")
      versusMenu("checkTimer"):SetInt(1)
    else
      print("== Closing Battle Campaign Info ==")
      versusMenu:hideChampionInfo()
    end
  end
end
function ContextBar.collect_all(element)
  game.confirmCollectAll()
end
function ContextBar.building_obj_oninit(element)
  element:hide_video_oninit()
  if not game.canMuteStructure() then
    manager:rightShiftFrom("btn_mute", true)
  end
  if game.canMoveSelected() == false then
    manager:rightShiftFrom("btn_move", true)
  end
  if game.canMuteIsland() == false then
    manager:rightShiftFrom("btn_mute_all", true)
  elseif game.allMuted() then
    manager:changeButton("btn_mute_all", "button_unmute_all", "CONTEXTBAR_UNMUTE_ALL_LABEL", "unmute_all")
  end
  if game.isPaironormalIsland() then
    manager:rightShiftFrom("btn_mute_all", true)
  end
end
function ContextBar.test_breed_costumes(element)
  game.testCostumeBreeding()
end
function ContextBar.test_evolve_monsters(element)
  game.testCrucEvolveRequest()
end
function ContextBar.awakener_oninit(element)
  local IslandAwakening = include("IslandAwakening")
  local currentIsland = game.currentIsland()
  local activeIslandTheme = game.getActiveIslandTheme(currentIsland)
  local awakener = game.SelectedObject()
  if awakener == nil then
    manager:setContextImmediate(manager:getDefaultContext())
    game.deselectSelectedObject()
    return
  end
  if game.isObjectMuted() then
    manager:changeButton("btn_mute", "button_unmute", "CONTEXTBAR_UNMUTE_LABEL", "awakener_unmute_object")
  end
  if awakener:isAwake() then
    manager:setButtonImg("btn_awaken", "button_colossus_sleep")
    manager:setButtonLabel("btn_awaken", "CONTEXTBAR_CLOSE_LABEL")
  else
    manager:setButtonImg("btn_awaken", "button_colossus_awaken")
    manager:setButtonLabel("btn_awaken", "CONTEXTBAR_OPEN_LABEL")
    manager:setButtonEnabled("btn_mute", false)
    local button = manager:getButton("btn_mute")
    button("ReactToTouches"):SetInt(0)
    button.Touch("enabled"):SetInt(1)
  end
  local calendarCompleted = awakener:getCalendarId() < game.player():getDailyCumulativeLogin():calendar()
  if IslandAwakening.HasCutscene(currentIsland, activeIslandTheme) and calendarCompleted then
    manager:setButtonEnabled("btn_awaken", true)
  else
    manager:setButtonEnabled("btn_awaken", false)
    local button = manager:getButton("btn_awaken")
    if button ~= nil then
      button("ReactToTouches"):SetInt(0)
      button.Touch("enabled"):SetInt(1)
    end
  end
  local button = manager:getButton("btn_calendar")
  if button ~= nil then
    local alert = button:GetElement("attachedTemplate")
    alert:Refresh()
  end
end
function ContextBar.awakener_awaken(element)
  local awakener = game.SelectedObject()
  if awakener then
    local calendarCompleted = awakener:getCalendarId() < game.player():getDailyCumulativeLogin():calendar()
    local IslandAwakening = include("IslandAwakening")
    local currentIsland = game.currentIsland()
    local activeIslandTheme = game.getActiveIslandTheme(currentIsland)
    if IslandAwakening.HasCutscene(currentIsland, activeIslandTheme) and calendarCompleted then
      print("Awakener", "CurrentIsland:", currentIsland, "ActiveIslandTheme:", activeIslandTheme)
      if awakener:isAwake() then
        print("Island Slep!")
        awakener:setStatus(0)
        IslandAwakening.PlayHideCutscene(currentIsland, activeIslandTheme)
      else
        print("Island Awaken!")
        awakener:setStatus(1)
        IslandAwakening.PlayShowCutscene(currentIsland, activeIslandTheme)
      end
    elseif not calendarCompleted then
      local txt = game.getLocalizedText("NOTIFICATION_REQUIRES_CONUNDRUM_COMPLETION")
      game.displayNotification(txt)
    else
      local txt = game.getLocalizedText("NOTIFICATION_REQUIRES_ISLAND_AWAKENING_SKIN")
      game.displayNotification(txt)
    end
  end
end
function ContextBar.awakener_open_calendar(element)
  game.pushPopUp("daily_cumulative_login")
end
function ContextBar.rebake(element)
  local availableBakeries = game.getNumAvailableRebakeBakeries()
  local rebakeCost = game.getRebakeAllCost()
  if availableBakeries > 0 and rebakeCost > 0 then
    game.pushPopUp("popup_rebake")
  else
    game.displayNotification("REBAKE_UNAVAILABLE")
  end
end
function ContextBar.attuner_oninit(element)
  if game.structureUpgradeIsFree() then
    manager:setButtonVisible("btn_upgrade", false)
  end
  local attuner = game.FindAttuner()
  if attuner ~= nil and attuner:maxReattuneMonsterRarity() == game.MonsterRarity_Undefined then
    manager:rightShiftFrom("btn_reattune", true)
  end
  local button = manager:getButton("btn_reattune")
  if button ~= nil then
    local attachedIndicator = button:GetElement("attachedTemplate")
    if attachedIndicator ~= nil then
      if game.showReattunePromoTag() then
        attachedIndicator:SetVisible()
      else
        attachedIndicator:SetInvisible()
      end
    end
  end
  if game.popUpLevel() <= 1 and game.getAttunerTutSeen ~= nil and game.getAttunerTutSeen() == false then
    local placement = game.nativePlacement("tut_attuner")
    if placement ~= nil and placement.isLimitReached ~= nil and placement:isLimitReached() == false then
      game.loadNewsFlash("tut_attuner", true, 0, 1, "capping=1")
    end
  end
end
function ContextBar.open_reattune_menu(element)
  if game.worldContext():availableReattuneMonsters(game.MonsterRarity_Common):size() == 0 and game.worldContext():availableReattuneMonsters(game.MonsterRarity_Rare):size() == 0 then
    game.displayNotification("NOTIFICATION_NO_REATTUBALE_MONSTERS")
  else
    manager:setContext("REATTUNE_MENU")
  end
end
function ContextBar.reattune_oninit(element)
  if game.getPopUp() ~= "reattune" then
    game.pushPopUp("reattune")
  end
end
function ContextBar.close_reattune_menu(element)
  game.popPopUp()
  manager:setContext("ATTUNER")
end
function ContextBar.open_attune_menu(element)
  manager:setContext("ATTUNING_MENU")
end
function ContextBar.attuning_oninit(element)
  if game.getPopUp() ~= "attuning" then
    game.pushPopUp("attuning")
  end
end
function ContextBar.close_attuning_menu(element)
  game.popPopUp()
  manager:setContext("ATTUNER")
end
function ContextBar.attuner_attuning_oninit(element)
  if game.playerLevel() < 4 then
    manager:setButtonEnabled("btn_reduceTime", false)
  end
  if game.checkPlacementAvailable ~= nil and game.checkPlacementAvailable("shared_rewarded") == false then
    manager:setButtonVisible("btn_reduceTime", false)
  end
end
function ContextBar.finish_attuning(element)
  local obj = game.SelectedObject()
  if obj and obj:isAttuner() then
    local speedupDiamondsRequired = obj:diamondsRequiredToCompleteAction()
    if speedupDiamondsRequired > 0 then
      local timeRemaining = obj:secondsUntilActionDone()
      game.showSpeedUpMessage("FINISH_ATTUNING_SPEEDUP", "SPEED_UP_ATTUNING", timeRemaining, 0)
    else
      game.finishAttuning()
    end
  end
end
function ContextBar.attuning_speedup_video(element)
  local obj = game.SelectedObject()
  if obj and obj:isAttuner() then
    local timeRemaining = obj:secondsUntilActionDone()
    if timeRemaining > 0 then
      game.showSpeedUpMessage("ATTUNING_SPEEDUP_VIDEO", "SPEED_UP_ATTUNING_VIDEO", timeRemaining, 1)
    end
  end
end
function ContextBar.synthesizer_oninit(element)
  if game.structureUpgradeIsFree() then
    manager:setButtonVisible("btn_upgrade", false)
  end
  if game.popUpLevel() <= 1 and game.getSynthesizerTutSeen ~= nil and game.getSynthesizerTutSeen() == false then
    local placement = game.nativePlacement("tut_synthesizer")
    if placement ~= nil and placement.isLimitReached ~= nil and placement:isLimitReached() == false then
      game.loadNewsFlash("tut_synthesizer", true, 0, 1, "capping=1")
    end
  end
end
function ContextBar.synthesizing_oninit(element)
  if game.getPopUp() ~= "synthesizing" then
    game.pushPopUp("synthesizing")
  end
  if not game.canRetryLastSynthesis() then
    manager:setButtonEnabled("btn_retry", false)
  end
  if not game.showTestBreedButton() then
    manager:setButtonVisible("btn_synthtest", false)
    manager:setButtonVisible("btn_synthtest_mercy", false)
  end
end
function ContextBar.test_synthesis(element)
  if game.getPopUp() == "synthesizing" then
    local synthPopup = game.topPopUp()
    game.testSynthesizing(synthPopup:getGenesForSynthesis(), synthPopup.selectedMonsterId, false)
  end
end
function ContextBar.test_synthesis_mercy(element)
  if game.getPopUp() == "synthesizing" then
    local synthPopup = game.topPopUp()
    game.testSynthesizing(synthPopup:getGenesForSynthesis(), synthPopup.selectedMonsterId, true)
  end
end
function ContextBar.open_synthesizing_menu(element)
  manager:setContext("SYNTHESIZING_MENU")
end
function ContextBar.close_synthesizing_menu(element)
  game.popPopUp()
  manager:setContext("SYNTHESIZER")
end
function ContextBar.goto_retry_synthesis(element)
  if game.getPopUp() == "synthesizing" then
    local synthPopup = game.topPopUp()
    synthPopup:ShowRetry()
  end
end
function ContextBar.retry_synthesis_oninit(element)
  if game.getPopUp() ~= "popup_retry_synthesis" then
    game.pushPopUp("popup_retry_synthesis")
  end
end
function ContextBar.synthesizer_synthesizing_oninit(element)
  if game.playerLevel() < 4 then
    manager:setButtonEnabled("btn_reduceTime", false)
  end
  if game.checkPlacementAvailable ~= nil and game.checkPlacementAvailable("shared_rewarded") == false then
    manager:setButtonVisible("btn_reduceTime", false)
  end
end
function ContextBar.finish_synthesizing(element)
  local obj = game.SelectedObject()
  if obj and obj:isSynthesizer() then
    local speedupDiamondsRequired = obj:diamondsRequiredToCompleteAction()
    if speedupDiamondsRequired > 0 then
      local timeRemaining = obj:secondsUntilActionDone()
      game.showSpeedUpMessage("FINISH_SYNTHESIZING_SPEEDUP", "SPEED_UP_SYNTHESIZING", timeRemaining, 0)
    end
  end
end
function ContextBar.synthesizing_speedup_video(element)
  local obj = game.SelectedObject()
  if obj and obj:isSynthesizer() then
    local timeRemaining = obj:secondsUntilActionDone()
    if timeRemaining > 0 then
      game.showSpeedUpMessage("SYNTHESIZING_SPEEDUP_VIDEO", "SPEED_UP_SYNTHESIZING_VIDEO", timeRemaining, 1)
    end
  end
end
function ContextBar.map_oninit(element)
end
function ContextBar.map_friend_oninit(element)
end
function ContextBar.map_options_oninit(element)
end
function ContextBar.map_exit_options(element)
  game.mapContext():menu():HideOptions()
end
function ContextBar.map_deselect(element)
  local mapBase = game.mapContext():menu()
  mapBase:DeselectIsland()
  if game.mapContext():inMotionSickMode() then
    function mapBase.MotionModeOverlay.FadeTransition.onDoneShow()
      mapBase.MotionModeOverlay.FadeTransition:Hide()
      game.mapContext():deselectNode()
      game.mapContext():showPoiPins(false)
    end
    mapBase:HideIslandInfo()
    mapBase.MotionModeOverlay.FadeTransition:Show()
  else
    game.mapContext():deselectNode()
    game.mapContext():showPoiPins()
  end
end
function ContextBar.map_show_help(element)
  if game.openHelpshiftFAQWithTag ~= nil then
    game.openHelpshiftFAQWithTag("map")
  end
end
function ContextBar.map_exit(element)
  if game.mapContext():isFriendMode() and not game.mapContext():isFromWorld() then
    local currentFriendIsland = game.currentFriendIsland()
    game.visitFriendIsland(currentFriendIsland)
  else
    game.loadWorldContext(false, "load_overlay")
  end
end
function ContextBar.nucleus_oninit(element)
  if not game.showTestBreedButton() then
    manager:rightShiftFrom("btn_nucleustest", true)
  end
  if game.canMuteIsland() == false then
    manager:rightShiftFrom("btn_mute_all", true)
  elseif game.allMuted() then
    manager:changeButton("btn_mute_all", "button_unmute_all", "CONTEXTBAR_UNMUTE_ALL_LABEL", "unmute_all")
  end
  if game.structureUpgradeIsFree() then
    manager:rightShiftFrom("btn_upgrade", true)
  end
end
function ContextBar.test_nucleus(element)
  game.testNucleus()
end
function ContextBar.open_nucleus_menu(element)
  manager:setContext("NUCLEUS_MENU")
end
function ContextBar.nucleus_menu_oninit(element)
  if game.getPopUp() ~= "nucleus" then
    game.pushPopUp("nucleus")
  end
end
function ContextBar.close_nucleus_menu(element)
  game.popPopUp()
  manager:setContext("NUCLEUS")
end
function ContextBar.magical_nexus_monster_context_oninit(element)
  game.updateMonsterHud()
  local uniqueMonsterId = game.selectedMonsterId()
  local button = manager:getButton("btn_costume")
  if button ~= nil then
    local costumeSaleIndicator = button:GetElement("attachedTemplate")
    if costumeSaleIndicator ~= nil then
      if game.activeCostumeEvent(uniqueMonsterId) then
        costumeSaleIndicator("setNewScale"):SetFloat(game.hudScale())
        costumeSaleIndicator:SetVisible()
      else
        costumeSaleIndicator:SetInvisible()
      end
    end
  end
  local megaButton = manager:getButton("btn_mega")
  if megaButton ~= nil then
    local megaSaleIndicator = megaButton:GetElement("attachedTemplate")
    if megaSaleIndicator ~= nil then
      if not game.permaMegaSale() then
        megaSaleIndicator:SetInvisible()
      elseif game.isPermaMega() then
        megaSaleIndicator:SetInvisible()
      else
        megaSaleIndicator("setNewScale"):SetFloat(game.hudScale())
        megaSaleIndicator:SetVisible()
      end
    end
    if game.tutorialDisableExtraFeatures() then
      manager:setButtonEnabled("btn_mega", false)
      megaButton("ReactToTouches"):SetInt(0)
      manager:setButtonFunction("btn_mega", "megaLockedPopup")
      megaButton.Touch("enabled"):SetInt(1)
      if megaSaleIndicator ~= nil then
        megaSaleIndicator:SetInvisible()
      end
    elseif game.isMega_TurnedOn() then
      manager:changeButton("btn_mega", "button_un_megafy", "CONTEXTBAR_UNMEGAFY", "unmegafy")
    elseif game.isMega_TurnedOff() then
      if game.isPermaMega() then
        manager:changeButton("btn_mega", "button_perm_megafy", "CONTEXTBAR_REMEGAFY", "remegafy")
      else
        manager:changeButton("btn_mega", "button_temp_megafy", "CONTEXTBAR_REMEGAFY", "remegafy")
      end
    end
  end
  local filteredCostumes = CostumesHelper.GetFilteredCostumes(uniqueMonsterId)
  if 1 >= filteredCostumes:size() or not game.teleportingUnlocked() or game.battleTutActive() then
    manager:rightShiftFrom("btn_costume", true)
  end
end
function ContextBar.show_island_intro(element)
  game.topPopUp():root():popPopUp()
  game.pushPopUp("popup_purchase_island_fanfare")
end
function ContextBar.titansoul_monster_context_oninit(element)
  if not game.showTestBreedButton() then
    manager:rightShiftFrom("btn_titansoultest", true)
  end
  game.updateMonsterHud()
  local titansoul = game.SelectedObject()
  if titansoul then
    local IslandAwakening = include("IslandAwakening")
    local currentIsland = game.currentIsland()
    local activeIslandTheme = game.getActiveIslandTheme(currentIsland)
    if titansoul:isAwake() then
      manager:setButtonImg("btn_awaken", "button_titan_sleep")
      manager:setButtonLabel("btn_awaken", "CONTEXTBAR_CLOSE_LABEL")
    else
      manager:setButtonImg("btn_awaken", "button_titan_awaken")
      manager:setButtonLabel("btn_awaken", "CONTEXTBAR_OPEN_LABEL")
    end
    if IslandAwakening.HasCutscene(currentIsland, activeIslandTheme) and titansoul:canAwaken() then
      manager:setButtonEnabled("btn_awaken", true)
    else
      manager:setButtonEnabled("btn_awaken", false)
      local button = manager:getButton("btn_awaken")
      if button ~= nil then
        button("ReactToTouches"):SetInt(0)
        button.Touch("enabled"):SetInt(1)
      end
    end
    if titansoul:showFX() then
      manager:setButtonImg("btn_fx", "button_titan_link_off")
      manager:setButtonLabel("btn_fx", "CONTEXTBAR_TITANSOUL_FX_OFF")
    else
      manager:setButtonImg("btn_fx", "button_titan_link_on")
      manager:setButtonLabel("btn_fx", "CONTEXTBAR_TITANSOUL_FX_ON")
    end
  end
end
function ContextBar.test_titansoul_rewards(element)
  game.testTitansoulRewards()
end
function ContextBar.soul_link_menu(element)
  manager:setContext("SOUL_LINK_MENU")
end
function ContextBar.soul_link_menu_oninit(element)
  if game.getPopUp() ~= "soul_link" then
    game.pushPopUp("soul_link")
  end
end
function ContextBar.close_soul_link_menu(element)
  local titansoul = game.SelectedObject()
  if titansoul:power() == 0 then
    manager:setContext("TITANSOUL_MONSTER_NO_POWER")
  else
    manager:setContext("TITANSOUL_MONSTER")
  end
  game.popPopUp()
end
function ContextBar.titansoul_awaken(element)
  local titansoul = game.SelectedObject()
  if titansoul then
    local IslandAwakening = include("IslandAwakening")
    local currentIsland = game.currentIsland()
    local activeIslandTheme = game.getActiveIslandTheme(currentIsland)
    if IslandAwakening.HasCutscene(currentIsland, activeIslandTheme) and titansoul:canAwaken() then
      if titansoul:isAwake() then
        print("Island Slep!")
        titansoul:setAwakenedStatus(0)
        IslandAwakening.PlayHideCutscene(currentIsland, activeIslandTheme)
      else
        print("Island Awaken!")
        titansoul:setAwakenedStatus(1)
        IslandAwakening.PlayShowCutscene(currentIsland, activeIslandTheme)
      end
    else
      local txt = game.getLocalizedText("NOTIFICATION_REQUIRES_ALL_SOUL_LINKS_FILLED")
      game.displayNotification(txt)
    end
  end
end
function ContextBar.titansoul_toggle_fx(element)
  local titansoul = game.SelectedObject()
  if titansoul then
    if titansoul:showFX() then
      titansoul:setShowFX(false)
      manager:setButtonImg("btn_fx", "button_titan_link_on")
      manager:setButtonLabel("btn_fx", "CONTEXTBAR_TITANSOUL_FX_ON")
    else
      titansoul:setShowFX(true)
      manager:setButtonImg("btn_fx", "button_titan_link_off")
      manager:setButtonLabel("btn_fx", "CONTEXTBAR_TITANSOUL_FX_OFF")
    end
  end
end
function ContextBar.show_titansoul_help(element)
  if game.openHelpshiftFAQWithTag ~= nil then
    game.openHelpshiftFAQWithTag("titansoul")
  end
end
function ContextBar.show_titansoul_info(element)
  manager:setReserveState(manager:getContext())
  manager:setContext("TITANSOUL_INFO")
end
function ContextBar.titansoul_monster_info_oninit(element)
  if game.getPopUp() ~= "object_info" then
    game.pushPopUp("object_info")
    local titansoul = game.SelectedObject()
    if titansoul then
      manager:setProgressPercent("titansoul_level", titansoul:percentageComplete())
    end
  end
end
function ContextBar.dish_harmonizer_oninit(element)
  if game.canMuteIsland() == false then
    manager:rightShiftFrom("btn_mute_all", true)
  elseif game.allMuted() == true then
    manager:changeButton("btn_mute_all", "button_unmute_all", "CONTEXTBAR_UNMUTE_ALL_LABEL", "unmute_all")
  end
  local dishHarmonizer = game.FindDishHarmonizer()
  if dishHarmonizer ~= nil and dishHarmonizer:isMonsterTargetingUnlocked() == false then
    manager:rightShiftFrom("btn_mute", true)
  elseif dishHarmonizer ~= nil and game.isObjectMuted() then
    manager:changeButton("btn_mute", "button_unmute", "CONTEXTBAR_UNMUTE_LABEL", "unmute_object")
  end
  if game.structureUpgradeIsFree() then
    manager:rightShiftFrom("btn_upgrade", true)
  end
  if game.popUpLevel() <= 1 and game.getDishHarmonizerTutSeen ~= nil and game.getDishHarmonizerTutSeen() == false then
    local placement = game.nativePlacement("tut_dishharmonizer")
    if placement ~= nil and placement.isLimitReached ~= nil and placement:isLimitReached() == false then
      game.loadNewsFlash("tut_dishharmonizer", true, 0, 1, "capping=1")
    end
  end
end
function ContextBar.open_dish_harmonize_menu(element)
  if game.worldContext():availableDishHarmonizerMonsters():size() == 0 then
    game.displayNotification("NOTIFICATION_DISH_HARMONIZER_MONSTER_REQUIRED")
  else
    manager:setContext("DISH_HARMONIZER_MENU")
  end
end
function ContextBar.dish_harmonizer_menu_oninit(element)
  if game.getPopUp() ~= "dish_harmonizer" then
    game.pushPopUp("dish_harmonizer")
    local dishHarmonizer = game.FindDishHarmonizer()
    if dishHarmonizer and dishHarmonizer:isMonsterTargetingUnlocked() == false then
      manager:setButtonVisible("btn_target", false)
    end
  end
  if not game.showTestBreedButton() then
    manager:setButtonVisible("btn_harmonizetest", false)
    manager:setButtonVisible("btn_harmonizetestmonsterselect", false)
  end
end
function ContextBar.dish_harmonizing_oninit(element)
  local muteAllVisible = true
  if game.canMuteIsland() == false then
    manager:rightShiftFrom("btn_mute_all", true)
  elseif game.allMuted() == true then
    manager:changeButton("btn_mute_all", "button_unmute_all", "CONTEXTBAR_UNMUTE_ALL_LABEL", "unmute_all")
  end
  if game.playerLevel() < 4 then
    manager:setButtonEnabled("btn_reduceTime", false)
  end
  if game.checkPlacementAvailable ~= nil and game.checkPlacementAvailable("shared_rewarded") == false then
    manager:setButtonVisible("btn_reduceTime", false)
  end
  local dishHarmonizer = game.FindDishHarmonizer()
  if dishHarmonizer and dishHarmonizer:isMonsterTargetingUnlocked() == false then
    manager:rightShiftFrom("btn_mute", true)
  elseif dishHarmonizer ~= nil and game.isObjectMuted() then
    manager:changeButton("btn_mute", "button_unmute", "CONTEXTBAR_UNMUTE_LABEL", "unmute_object")
  end
end
function ContextBar.test_dish_harmonize(element)
  if game.getPopUp() == "dish_harmonizer" then
    local dhPopup = game.topPopUp()
    dhPopup:testDishHarmonizing()
  end
end
function ContextBar.dish_harmonizer_test_monster_select(element)
  if game.getPopUp() == "dish_harmonizer" then
    local dhPopup = game.topPopUp()
    local selectedMonsterID = dhPopup:getSelectedMonster()
    if selectedMonsterID == 0 then
      game.displayNotification("NOTIFICATION_DISH_HARMONIZER_SELECT_MONSTER")
    else
      manager:setReserveState(manager:getContext())
      game.topPopUp():root():popPopUp()
      if game.getPopUp() ~= "dish_harmonizer_test_monster_select" then
        game.pushPopUp("dish_harmonizer_test_monster_select")
        local monsterSelectPopup = game.topPopUp()
        monsterSelectPopup:V("InputMonsterID"):SetInt(selectedMonsterID)
      end
    end
  end
end
function ContextBar.close_dish_harmonizer_menu(element)
  game.popPopUp()
  manager:setContext("DISH_HARMONIZER")
end
function ContextBar.finish_dish_harmonizing(element)
  local dishHarmonizer = game.FindDishHarmonizer()
  if dishHarmonizer and dishHarmonizer:secondsUntilDishHarmonizingDone() > 0 then
    game.showSpeedUpMessage("FINISH_DISH_HARMONIZING_SPEEDUP", "SPEED_UP_DISH_HARMONIZING", dishHarmonizer:secondsUntilDishHarmonizingDone(), 0)
  end
end
function ContextBar.dish_harmonizing_speedup_video(element)
  local dishHarmonizer = game.FindDishHarmonizer()
  if dishHarmonizer and dishHarmonizer:secondsUntilDishHarmonizingDone() > 0 then
    game.showSpeedUpMessage("DISH_HARMONIZING_SPEEDUP_VIDEO", "SPEED_UP_DISH_HARMONIZING_VIDEO", dishHarmonizer:secondsUntilDishHarmonizingDone(), 1)
  end
end
function ContextBar.open_dish_harmonizer_targets(element)
  if game.getPopUp() == "dish_harmonizer" then
    local dishHarmonizerPopup = game.topPopUp()
    dishHarmonizerPopup:ShowTargets()
  end
end
function ContextBar.dish_harmonizer_targets_oninit(element)
  if game.getPopUp() ~= "dish_harmonizer_targets" then
    game.pushPopUp("dish_harmonizer_targets")
  end
end
function ContextBar.close_dish_harmonizer_targets(element)
  manager:setContext("BLANK")
  game.popPopUp()
end
function ContextBar.polarity_amplifier_oninit(element)
  local muteAllVisible = true
  if game.canMuteIsland() == false then
    manager:rightShiftFrom("btn_mute_all")
    muteAllVisible = false
  end
  if muteAllVisible and game.allMuted() == true then
    manager:changeButton("btn_mute_all", "button_unmute_all", "CONTEXTBAR_UNMUTE_ALL_LABEL", "unmute_all")
  end
  local polarityAmplifier = game.getPolarityAmplifier()
  if polarityAmplifier ~= nil then
    if polarityAmplifier:getLevel().level == 0 then
      manager:rightShiftFrom("btn_lightshow", true)
    elseif game.isObjectMuted() then
      manager:changeButton("btn_lightshow", "button_bulb_on", "CONTEXTBAR_LIGHTSHOW_ON_LABEL", "lightshow_on")
    end
  end
end
function ContextBar.open_polarity_amplifier_menu(element)
  manager:setContext("POLARITY_AMPLIFIER_MENU")
end
function ContextBar.polarity_amplifier_menu_oninit(element)
  if game.getPopUp() ~= "polarity_amplifier" then
    game.pushPopUp("polarity_amplifier")
  end
end
function ContextBar.close_polarity_amplifier_menu(element)
  game.popPopUp()
  manager:setContext("POLARITY_AMPLIFIER")
end
function ContextBar.lightshow_off(element)
  game.muteObject(true)
  manager:changeButton("btn_lightshow", "button_bulb_on", "CONTEXTBAR_LIGHTSHOW_ON_LABEL", "lightshow_on")
end
function ContextBar.lightshow_on(element)
  game.muteObject(false)
  manager:changeButton("btn_lightshow", "button_bulb_off", "CONTEXTBAR_LIGHTSHOW_OFF_LABEL", "lightshow_off")
end
function ContextBar:breeding_feed_monster()
  print("Feed Monster!")
  local popup = game.getPopUp("breeding_feed_popup")
  if popup then
    popup:feedMonster()
  else
    print("BreedingFeedPopup not found!")
  end
end
function ContextBar.breed_monsters_v2(element)
  print("Breed Monster!")
  local popup = game.getPopUp("breeding_v2")
  if popup then
    local leftMonster = popup.LeftMonsterSelect.SelectedEntry
    local rightMonster = popup.RightMonsterSelect.SelectedEntry
    if not leftMonster or not rightMonster then
      print("Both monsters must be selected to breed.")
      game.displayNotification("BREED_ERROR_SELECT_TWO_MONSTERS")
      return
    end
    popup:breed()
  else
    print("BreedingMenuV2 not found!")
  end
end
function ContextBar.paironormal_context_oninit(element)
  ContextBar.default_context_oninit(element)
  local switchButton = manager:getButton("btn_switch")
  if switchButton then
    if not game.showPaironormalMinor() then
      manager:rightShiftFrom("btn_switch", true)
    else
      local mode = game.player():getActiveIsland():islandMode()
      if mode == 0 then
        manager:setButtonImg("btn_switch", "button_paironormal")
      else
        manager:setButtonImg("btn_switch", "button_paironormal_flip")
      end
    end
  end
end
function ContextBar.paironormal_multimonster_context_oninit(element)
  local uniqueMonsterId = game.selectedMonsterId()
  if uniqueMonsterId == 0 then
    manager:setContextImmediate(manager:getDefaultContext())
    game.deselectSelectedObject()
    return
  end
  game.updateMonsterHud()
  local multiMonster = game.GetMultiMonster(uniqueMonsterId)
  local mode = game.player():getActiveIsland():islandMode()
  local isActive = multiMonster and multiMonster:isModeActivated(mode)
  if not isActive then
    manager:rightShiftFrom("btn_mega", true)
    manager:rightShiftFrom("btn_costume", true)
    manager:rightShiftFrom("btn_mute", true)
    manager:rightShiftFrom("btn_feed", true)
  else
    local megaButton = manager:getButton("btn_mega")
    local megaSaleIndicator
    if megaButton then
      if game.isMega_TurnedOn() then
        manager:changeButton("btn_mega", "button_un_megafy", "CONTEXTBAR_UNMEGAFY", "unmegafy")
      elseif game.isMega_TurnedOff() then
        if game.isPermaMega() then
          manager:changeButton("btn_mega", "button_perm_megafy", "CONTEXTBAR_REMEGAFY", "remegafy")
        else
          manager:changeButton("btn_mega", "button_temp_megafy", "CONTEXTBAR_REMEGAFY", "remegafy")
        end
      end
    end
    local modeMonster = multiMonster:getModeMonster(mode)
    local modeMonsterUniqueId = modeMonster and modeMonster:uniqueId() or 0
    local filteredCostumes = CostumesHelper.GetFilteredCostumes(modeMonsterUniqueId)
    if filteredCostumes:size() <= 1 or not game.teleportingUnlocked() or game.battleTutActive() then
      manager:rightShiftFrom("btn_costume", true)
    end
    if game.monsterLevel(uniqueMonsterId) >= 20 or game.objectFoodRequired() == 0 or game.disableFeedButton() then
      manager:rightShiftFrom("btn_feed", true)
    end
    local costumeButton = manager:getButton("btn_costume")
    if costumeButton ~= nil then
      local costumeSaleIndicator = costumeButton:GetElement("attachedTemplate")
      if costumeSaleIndicator ~= nil then
        if game.activeCostumeEvent(uniqueMonsterId) then
          costumeSaleIndicator("setNewScale"):SetFloat(game.hudScale())
          costumeSaleIndicator:SetVisible()
        else
          costumeSaleIndicator:SetInvisible()
        end
      end
    end
    megaButton = manager:getButton("btn_mega")
    if megaButton then
      megaSaleIndicator = megaButton:GetElement("attachedTemplate")
      if megaSaleIndicator then
        if not game.permaMegaSale() then
          megaSaleIndicator:SetInvisible()
        elseif game.isPermaMega() then
          megaSaleIndicator:SetInvisible()
        else
          megaSaleIndicator("setNewScale"):SetFloat(game.hudScale())
          megaSaleIndicator:SetVisible()
        end
      end
    end
  end
  local fugueButton = manager:getButton("btn_fugue")
  if fugueButton then
    local fugue = game.FindFugue()
    local isfugueInactive = fugue:isInactive()
    local mergeableMonsters = game.worldContext():availableMergeFugueMonsters(uniqueMonsterId)
    if isfugueInactive or multiMonster and multiMonster:isModeActivated(mode) or mergeableMonsters:size() == 0 then
      manager:rightShiftFrom("btn_fugue", true)
    end
  end
end
function ContextBar.show_paironormal_multimonster_info(element)
  manager:setReserveState(manager:getContext())
  manager:setContext("PAIRONORMAL_MULTIMONSTER_INFO")
end
function ContextBar.paironormal_multimonster_info_oninit(element)
  local currentIslandMode = game.player():getActiveIsland():islandMode()
  local multiMonster = game.GetMultiMonster(game.selectedMonsterId())
  local isActive = multiMonster and multiMonster:isModeActivated(currentIslandMode)
  if not isActive then
    if game.getPopUp() ~= "object_info_paironormal_ghost" then
      game.pushPopUp("object_info_paironormal_ghost")
    end
    manager:rightShiftFrom("btn_feed", true)
    manager:setContextInfoVisible(false)
    return
  end
  if game.getPopUp() ~= "object_info_paironormal" then
    game.pushPopUp("object_info_paironormal")
    if game.monsterCount() == 1 then
      manager:setButtonEnabled("btn_sell", false)
      local sellButton = manager:getButton("btn_sell")
      if sellButton ~= nil then
        sellButton("ReactToTouches"):SetInt(0)
        manager:setButtonFunction("btn_sell", "show_sell_locked_message")
        sellButton.Touch("enabled"):SetInt(1)
      end
    end
    if multiMonster:isFuguing() then
      manager:setButtonEnabled("btn_sell", false)
      manager:setButtonEnabled("btn_feed", false)
    end
    manager:setContextInfoVisible(true)
    if game.monsterLevel(game.selectedMonsterId()) >= game.maxMonsterLevel() or game.objectFoodRequired() == 0 then
      manager:rightShiftFrom("btn_feed", true)
    end
    local percent = 0
    if game.monsterLevel(game.selectedMonsterId()) >= game.maxMonsterLevel() then
      percent = 1
    else
      percent = game.monsterTimesFed(game.selectedMonsterId()) / 4
    end
    manager:setProgressPercent("level", percent)
    local happiness = game.monsterHappiness(game.selectedMonsterId()) .. "%"
    manager:setProgressLabel("happiness", happiness)
    manager:setProgressPercent("happiness", game.monsterHappiness(game.selectedMonsterId()) / 100)
    manager:setButtonImg("btn_sell", "button_sell")
  end
end
function ContextBar:switch_island_mode()
  print("Switch Island Mode!")
  local island = game.currentPlayer():getActiveIsland()
  if island then
    local currentMode = island:islandMode()
    game.changeActiveIslandMode(currentMode == 0 and 1 or 0)
  end
end
function ContextBar.clubbox_context_oninit(element)
  local context = game.clubboxContext()
  if context:mode() == game.ClubboxMode_MEMORY then
    manager:rightShiftFrom("btn_help", true)
    manager:rightShiftFrom("btn_hype", true)
  elseif not game.clubboxCustomizeUnlocked() then
    manager:setButtonVisible("btn_customize", false)
  end
end
function ContextBar.show_clubbox_info(element)
  manager:setReserveState(manager:getContext())
  manager:setContext("CLUBBOX_INFO")
end
function ContextBar.clubbox_info_oninit(element)
  if game.getPopUp() ~= "clubbox_how_it_works" then
    game.pushPopUp("clubbox_how_it_works")
  end
end
function ContextBar.show_clubbox_hype(element)
  game.pushPopUp("hype_game")
end
function ContextBar.show_clubbox_mixer(element)
  if game.getPopUp() ~= "clubbox_customization" then
    manager:setContext("BLANK")
    game.pushPopUp("clubbox_customization")
  end
end
function ContextBar.admin_reset_customizations(element)
  game.adminResetClubboxCustomizations()
end
function ContextBar.clubbox_exit(element)
  if game.clubboxContext():mode() == game.ClubboxMode_MEMORY then
    local friendMode = false
    game.loadMapContext(friendMode)
  else
    game.loadWorldContext(false, "load_overlay")
  end
end
function ContextBar.minigame_context_oninit(element)
end
function ContextBar.minigame_exit(element)
  game.verifyMinigameSession("", true)
end
function ContextBar.minigame_info(element)
  if game.getPopUp() ~= "minigame_how_it_works" then
    game.pushPopUp("minigame_how_it_works")
  end
end
function ContextBar.fugue_oninit(element)
end
function ContextBar.open_fugue_menu(element)
  if game.worldContext():availableFugueMonsters():size() == 0 then
    game.displayNotification("NOTIFICATION_NO_FUGUABLE_MONSTERS")
  else
    manager:setContext("FUGUE_MENU")
  end
end
function ContextBar.fugue_menu_oninit(element)
  if game.getPopUp() ~= "fugue" then
    game.pushPopUp("fugue")
    if not game.showTestBreedButton() then
      manager:rightShiftFrom("btn_fuguetest", true)
    end
  end
end
function ContextBar.close_fugue_menu(element)
  game.popPopUp()
  manager:setContext("FUGUE")
end
function ContextBar.fugue_fuguing_oninit(element)
  if game.playerLevel() < 4 then
    manager:setButtonEnabled("btn_reduceTime", false)
  end
  if game.checkPlacementAvailable ~= nil and game.checkPlacementAvailable("shared_rewarded") == false then
    manager:setButtonVisible("btn_reduceTime", false)
  end
end
function ContextBar.finish_fuguing(element)
  local fugue = game.FindFugue()
  if fugue and fugue:secondsUntilFuguingDone() > 0 then
    game.showSpeedUpMessage("FINISH_FUGUING_SPEEDUP", "SPEED_UP_FUGUING", fugue:secondsUntilFuguingDone(), 0)
  end
end
function ContextBar.fuguing_speedup_video(element)
  local fugue = game.FindFugue()
  if fugue and fugue:secondsUntilFuguingDone() > 0 then
    game.showSpeedUpMessage("FUGUING_SPEEDUP_VIDEO", "SPEED_UP_FUGUING_VIDEO", fugue:secondsUntilFuguingDone(), 1)
  end
end
function ContextBar.open_merge_fugue_menu(element)
  manager:setContext("MERGE_FUGUE_MENU")
end
function ContextBar.merge_fugue_menu_oninit(element)
  if game.getPopUp() ~= "merge_fugue" then
    game.pushPopUp("merge_fugue")
  end
end
function ContextBar.close_merge_fugue_menu(element)
  game.popPopUp()
  manager:setContext("PAIRONORMAL_MULTIMONSTER")
end
function ContextBar.gotMsgIslandModeChanged(element, msg)
  if manager:getContext() == "PAIRONORMAL_DEFAULT" then
    if msg.mode == 0 then
      manager:setButtonImg("btn_switch", "button_paironormal")
    else
      manager:setButtonImg("btn_switch", "button_paironormal_flip")
    end
  end
end
function ContextBar.gotMsgClubboxHypeUpdated(element, msg)
  if manager:getContext() == "CLUBBOX_DEFAULT" and game.clubboxCustomizeUnlocked() then
    manager:setButtonVisible("btn_customize", true)
  end
end
function ContextBar.inactive_fugue_menu_oninit(element)
  local text = game.getLocalizedText("CONFIRMATION_UPGRADE_FUGUE")
  local costText = game.structureUpgradeCost()
  text = text:gsub("%${AMOUNT}", costText)
  game.displayConfirmation("UPGRADE_FUGUE", text)
end
function ContextBar.test_fugue_chance(element)
  if game.getPopUp() == "fugue" then
    local fuguePopup = game.topPopUp()
    fuguePopup:testFugueChance()
  end
end
function ContextBar.show_card_album(element)
  if game.getPopUp() ~= "card_album" then
    manager:setContext("BLANK")
    game.pushPopUp("card_album")
  end
end
function ContextBar.goto_clubbox(element)
  if game.existingClubboxAct() == 0 then
    if game.getPopUp() ~= "clubbox_act_select" then
      game.pushPopUp("clubbox_act_select")
    end
  else
    game.goToClubbox(0, 0)
  end
end
function ContextBar.move_clubbox(element)
  if game.existingClubboxAct() ~= 0 and game.getPopUp() ~= "clubbox_switch_island" then
    game.pushPopUp("clubbox_switch_island")
  end
end
function ContextBar.show_world_clubbox_info(element)
  manager:setReserveState(manager:getContext())
  manager:setContext("CLUBBOX_STRUCTURE_INFO")
end
function ContextBar.world_clubbox_info_oninit(element)
  if not game.hasPopUp("popup_clubbox_info") then
    game.pushPopUp("popup_world_clubbox_info")
  end
end
function ContextBar.close_world_clubbox_info(element)
  game.popPopUp()
end
function ContextBar.close_options(element)
  local popup = game.getPopUp("options")
  if popup then
    manager:setContext(manager:getDefaultContext())
    popup:root():removePopUp("options")
  end
end
return ContextBar
