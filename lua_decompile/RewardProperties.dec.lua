local TweenerPingPong = include("TweenerPingPong")
local MonsterProperties = include("MonsterProperties")
local RewardProperties = {}
local getStructureName = function(entityId)
  local structureData = game.getStructureByEntityId(entityId)
  if structureData:structureType() == game.SpecificEntityType_AWAKENER then
    local alias = LOC("STRUCTURE_AWAKENER_ISLAND")
    local island = structureData:getExtraString("island")
    if island then
      alias = alias:gsub("%${ISLAND}", LOC(island))
    end
    return alias
  end
  return game.entityName(entityId)
end
local getRewardString = function(textId, amount, hideAmounts)
  if hideAmounts then
    return LOC(textId)
  end
  amount = amount or 1
  if amount == 1 then
    textId = textId .. "_SINGULAR"
  end
  return amount .. "\n" .. LOC(textId)
end
local getContextButtonPosition = function(buttonName)
  local pos = {}
  local contextBar = game.getContextBar()
  if contextBar then
    local btn = contextBar:getButton(buttonName)
    if btn then
      pos.x = btn:absX() + btn:absW() * 0.5
      pos.y = btn:absY() + btn:absH() * 0.5
    end
  end
  return pos
end
local getClubboxTokenTargetPosition = function()
  local pos = {}
  local hud = game.getHUD()
  if hud then
    local btn = hud.LeftButtons.ClubboxButton
    if btn then
      pos.x = btn:absX() + btn:absW() * 0.5
      pos.y = btn:absY()
    end
  elseif game.gameContext() then
    pos.x = 32 * game.menuScaleX()
    pos.y = lua_sys.screenHeight() * 0.5
  end
  return pos
end
local getMinigameTokenTargetPosition = function()
  local pos = {}
  local hud = game.getHUD()
  if hud then
    local btn = hud.LeftButtons.MinigameButton
    if btn then
      pos.x = btn:absX() + btn:absW() * 0.5
      pos.y = btn:absY()
    end
  elseif game.gameContext() then
    pos.x = 32 * game.menuScaleX()
    pos.y = lua_sys.screenHeight() * 0.5
  end
  return pos
end
function RewardProperties:getRewardAppearance(rewardData, options)
  options = options or {}
  local amount = rewardData.amount or 1
  local hideAmounts = options.hideAmounts or false
  if not rewardData.type and rewardData.animFile and rewardData.animName then
    return rewardData
  end
  if rewardData.type == game.LootType_Coins then
    return {
      name = getRewardString("COINS", amount, hideAmounts),
      value = amount,
      animFile = "battle_buttons_anim.bin",
      animName = "coin pile",
      tint = {
        r = game.StoreContext_coinColour.r,
        g = game.StoreContext_coinColour.g,
        b = game.StoreContext_coinColour.b
      },
      getTargetUI = function()
        return game.getHUD().CoinCounter
      end,
      iconName = game.StoreContext_SPRITE_COINS,
      iconSheet = game.StoreContext_CURRENCY_SPRITESHEET,
      soundFile = "audio/sfx/collect_coins.wav",
      onComplete = function(e)
        game.engineReceiver():Send(game.MsgFlyingIconLanded(rewardData.type))
      end
    }
  elseif rewardData.type == game.LootType_Shards then
    return {
      name = getRewardString("SHARDS", amount, hideAmounts),
      value = amount,
      animFile = "battle_buttons_anim.bin",
      animName = "shard pile",
      tint = {
        r = game.StoreContext_etherealColour.r,
        g = game.StoreContext_etherealColour.g,
        b = game.StoreContext_etherealColour.b
      },
      getTargetUI = function()
        return game.getHUD().ShardCounter
      end,
      iconName = game.StoreContext_SPRITE_ETH_CURRENCY,
      iconSheet = game.StoreContext_CURRENCY_SPRITESHEET,
      soundFile = "audio/sfx/sticker_tap_shards.wav",
      onComplete = function(e)
        game.engineReceiver():Send(game.MsgFlyingIconLanded(rewardData.type))
      end
    }
  elseif rewardData.type == game.LootType_Diamonds then
    return {
      name = getRewardString("DIAMONDS", amount, hideAmounts),
      value = amount,
      animFile = "battle_buttons_anim.bin",
      animName = "diamond pile",
      tint = {
        r = game.StoreContext_diamondColour.r,
        g = game.StoreContext_diamondColour.g,
        b = game.StoreContext_diamondColour.b
      },
      getTargetUI = function()
        return game.getHUD().DiamondCounter
      end,
      iconName = game.StoreContext_SPRITE_DIAMOND,
      iconSheet = game.StoreContext_CURRENCY_SPRITESHEET,
      soundFile = "audio/sfx/collect_diamonds.wav",
      onComplete = function(e)
        game.engineReceiver():Send(game.MsgFlyingIconLanded(rewardData.type))
      end
    }
  elseif rewardData.type == game.LootType_Food then
    return {
      name = getRewardString("CODE_REWARD_FOOD", amount, hideAmounts),
      value = amount,
      animFile = "battle_buttons_anim.bin",
      animName = "food pile",
      tint = {
        r = game.StoreContext_foodColour.r,
        g = game.StoreContext_foodColour.g,
        b = game.StoreContext_foodColour.b
      },
      getTargetUI = function()
        return game.getHUD().FoodCounter
      end,
      iconName = game.StoreContext_SPRITE_FOOD,
      iconSheet = game.StoreContext_CURRENCY_SPRITESHEET,
      soundFile = "audio/sfx/collect_food.wav",
      onComplete = function(e)
        game.engineReceiver():Send(game.MsgFlyingIconLanded(rewardData.type))
      end
    }
  elseif rewardData.type == game.LootType_Relics then
    return {
      name = getRewardString("RELICS", amount, hideAmounts),
      value = amount,
      animFile = "battle_buttons_anim.bin",
      animName = "relic pile",
      tint = {
        r = game.StoreContext_relicColour.r,
        g = game.StoreContext_relicColour.g,
        b = game.StoreContext_relicColour.b
      },
      getTargetUI = function()
        return game.getHUD().RelicCounter
      end,
      iconName = game.StoreContext_SPRITE_RELIC,
      iconSheet = game.StoreContext_CURRENCY_SPRITESHEET,
      soundFile = "audio/sfx/sticker_tap_relic.wav",
      onComplete = function(e)
        game.engineReceiver():Send(game.MsgFlyingIconLanded(rewardData.type))
      end
    }
  elseif rewardData.type == game.LootType_Keys then
    return {
      name = getRewardString("KEYS", amount, hideAmounts),
      value = amount,
      animFile = "battle_buttons_anim.bin",
      animName = "key pile",
      tint = {
        r = game.StoreContext_keyColour.r,
        g = game.StoreContext_keyColour.g,
        b = game.StoreContext_keyColour.b
      },
      getTargetUI = function()
        return game.getHUD().KeyCounter
      end,
      iconName = game.StoreContext_SPRITE_KEY,
      iconSheet = game.StoreContext_CURRENCY_SPRITESHEET,
      soundFile = "audio/sfx/collect_key.wav",
      onComplete = function(e)
        game.engineReceiver():Send(game.MsgFlyingIconLanded(rewardData.type))
      end
    }
  elseif rewardData.type == game.LootType_Starpower then
    return {
      name = amount .. "\n" .. LOC("STARPOWER"),
      value = amount,
      animFile = "battle_buttons_anim.bin",
      animName = "starpower pile",
      tint = {
        r = game.StoreContext_starpowerColour.r,
        g = game.StoreContext_starpowerColour.g,
        b = game.StoreContext_starpowerColour.b
      },
      getTargetUI = function()
        return game.getHUD().StarCounter
      end,
      iconName = game.StoreContext_SPRITE_STARPOWER,
      iconSheet = game.StoreContext_CURRENCY_SPRITESHEET,
      soundFile = "audio/sfx/collect_starpower.wav",
      onComplete = function(e)
        game.engineReceiver():Send(game.MsgFlyingIconLanded(rewardData.type))
      end
    }
  elseif rewardData.type == game.LootType_Monster then
    do
      local entityId = rewardData.id
      local monsterData = game.getMonsterByEntityId(entityId)
      local iconName = "button_buy_spore"
      local iconSheet = "xml_resources/context_buttons.xml"
      local buttonPos = getContextButtonPosition("btn_market")
      local iconDestX = buttonPos.x
      local iconDestY = buttonPos.y or lua_sys.screenHeight() - 32 * game.menuScaleX()
      if monsterData:monsterId() > 0 then
        local variation = options.variation or 0
        if monsterData:isCelestial() and not monsterData:isDipster() or monsterData:isUnderling() then
          variation = 1
        end
        if variation == 0 then
          local eggInfo = {
            value = amount,
            bgAnimFile = "glow.bin",
            bgAnimName = "glow",
            getTargetUI = function()
              return manager:getButton("btn_market")
            end,
            iconName = iconName,
            iconSheet = iconSheet,
            iconDestX = iconDestX,
            iconDestY = iconDestY
          }
          if monsterData:isDipster() then
            eggInfo.name = LOC(game.entityName(entityId))
            eggInfo.animFile = "dipster_door.bin"
            eggInfo.animName = "idle"
            eggInfo.dipster_door = "gfx/" .. game.getSporeGraphic(monsterData:monsterId())
            if monsterData:isAstralDipster() then
              eggInfo.dipster_door_frame = "egg_dipster_frame_ASTRAL"
              eggInfo.dipster_door_back = "egg_dipster_door_back_ASTRAL"
              eggInfo.dipster_door_shade = "egg_dipster_door_shade_ASTRAL"
            elseif monsterData:isEpicMonster() then
              eggInfo.dipster_door_frame = "egg_dipster_frame_EPIC"
              eggInfo.dipster_door_back = "egg_dipster_door_back"
              eggInfo.dipster_door_shade = "egg_dipster_door_shade"
            elseif monsterData:isRareMonster() then
              eggInfo.dipster_door_frame = "egg_dipster_frame_RARE"
              eggInfo.dipster_door_back = "egg_dipster_door_back_RARE"
              eggInfo.dipster_door_shade = "egg_dipster_door_shade"
            else
              eggInfo.dipster_door_frame = "egg_dipster_frame"
              eggInfo.dipster_door_back = "egg_dipster_door_back"
              eggInfo.dipster_door_shade = "egg_dipster_door_shade"
            end
          else
            eggInfo.name = LOC(game.entityName(entityId)) .. "\n" .. LOC("EGG")
            eggInfo.animFile = "egg_caddy.bin"
            eggInfo.animName = "egg_caddy"
            eggInfo.spore = "gfx/" .. game.getSporeGraphic(monsterData:monsterId())
          end
          return eggInfo
        elseif variation == 1 then
          local isActivated = monsterData:isBoxMonster() and monsterData:getExtraInt("activated") ~= 0
          if rewardData.mail_id and 0 < rewardData.mail_id or rewardData.getExtraLong and 0 < rewardData:getExtraLong("mail_id") or rewardData.box_filled and rewardData.box_filled or rewardData.getExtraBool and rewardData:getExtraBool("box_filled") then
            isActivated = true
          end
          local customSetupFunc
          if isActivated then
            iconName = "button_purchase_promo_old"
            buttonPos = getContextButtonPosition("btn_mail")
            iconDestX = buttonPos.x
            iconDestY = buttonPos.y or lua_sys.screenHeight() - 32 * game.menuScaleX()
            function customSetupFunc(rewardElement)
              local element = rewardElement.Anim
              local component = rewardElement.Anim.Sprite
              component:setScale(Vector2(1, 1))
              component("animation"):SetString("Idle")
              local scale = game.hudScale() * rewardElement:templateVars().scale
              local targetW = 100 * scale
              local targetH = 200 * scale
              local viewBounds = MonsterProperties.getIdleViewBounds(monsterData:monsterId(), component:absW(), component:absH(), targetW, targetH)
              component:setScale(Vector2(viewBounds.scale, viewBounds.scale))
              component("yOffset"):SetInt(viewBounds.yOffset + 20 / viewBounds.scale)
              local facing = MonsterProperties.getFacing(monsterData:monsterId())
              component:GetVar("hFlip"):SetInt(facing)
              local attachedTemplate = menu:addTemplateElement("template_storeitem_sticker", "attachedTemplate", rewardElement)
              attachedTemplate:setParent(rewardElement)
              attachedTemplate:setOrientation(MenuOrientation(-20 * game.menuScaleX(), 20 * game.menuScaleX(), -2, HCENTER, VCENTER))
              attachedTemplate:setRelativeObjectAnchors(RIGHT, TOP)
              attachedTemplate:templateVars().layer = rewardElement:templateVars().layer
              if monsterData:isCelestial() then
                attachedTemplate:templateVars().text = LOC("STICKER_READY_TO_ACTIVATE_CELESTIAL")
              elseif monsterData:isUnderling() then
                attachedTemplate:templateVars().text = LOC("STICKER_READY_TO_ACTIVATE_WUBLIN")
              else
                attachedTemplate:templateVars().text = LOC("STICKER_READY_TO_ACTIVATE")
              end
              attachedTemplate:init()
              attachedTemplate:setPositionBroadcast(true)
              attachedTemplate:postInit()
              local stickerSize = attachedTemplate.Sprite:GetVar("size"):GetFloat()
              local pulseEffect = TweenerPingPong:new({
                loopTime = 0.5,
                ease = lua_sys.Quadratic_EaseIn,
                onUpdate = function(target, t)
                  target:GetVar("size"):SetFloat(stickerSize * (1 + t * 0.25))
                end
              })
              pulseEffect.targets = {
                attachedTemplate.Sprite
              }
              table.insert(rewardElement.gfxList, attachedTemplate.Sprite)
              table.insert(rewardElement.gfxList, attachedTemplate.Text)
              table.insert(rewardElement.tickables, pulseEffect)
            end
          end
          if not isActivated or not "Activate" then
          end
          return {
            name = LOC(game.entityName(entityId)),
            value = amount,
            animFile = monsterData:animationFile(),
            animName = monsterData:animationMenuName(),
            bgAnimFile = "glow.bin",
            bgAnimName = "glow",
            getTargetUI = function()
              return manager:getButton("btn_market")
            end,
            iconName = iconName,
            iconSheet = iconSheet,
            iconDestX = iconDestX,
            iconDestY = iconDestY,
            customSetupFunc = customSetupFunc
          }
        end
      end
    end
  elseif rewardData.type == game.LootType_Structure then
    local entityId = rewardData.id
    local structureData = game.getStructureByEntityId(entityId)
    print("got struct:", entityId, structureData:name())
    local name = LOC(getStructureName(entityId))
    if amount > 1 then
      name = name .. " x" .. amount
    end
    local buttonPos = getContextButtonPosition("btn_market")
    local iconDestX = buttonPos.x
    local iconDestY = buttonPos.y or lua_sys.screenHeight() - 32 * game.menuScaleX()
    local iconName = "icon_structures"
    if structureData:structureType() == 5 then
      iconName = "icon_decos"
      name = name .. "\n" .. LOC("DECORATION")
    end
    return {
      name = name,
      value = amount,
      animFile = game.entityAnimFile(entityId),
      animName = game.entityAnimName(entityId),
      bgAnimFile = "glow.bin",
      bgAnimName = "glow",
      getTargetUI = function()
        return manager:getButton("btn_market")
      end,
      iconName = iconName,
      iconSheet = "xml_resources/hud03.xml",
      iconDestX = iconDestX,
      iconDestY = iconDestY
    }
  elseif rewardData.type == game.LootType_IslandTheme then
    local themeId = rewardData.id
    local islandThemeData = game.islandIdForIslandTheme(themeId)
    local buttonPos = getContextButtonPosition("btn_market")
    local iconDestX = buttonPos.x
    local iconDestY = buttonPos.y or lua_sys.screenHeight() - 32 * game.menuScaleX()
    return {
      name = game.islandThemeName(themeId),
      value = amount,
      animFile = "islands.bin",
      animName = "island" .. game.islandIdForIslandTheme(themeId) .. "_theme" .. themeId,
      bgAnimFile = "glow.bin",
      bgAnimName = "glow",
      getTargetUI = function()
        return manager:getButton("btn_market")
      end,
      iconName = "news_islandskins",
      iconSheet = "xml_resources/hud03.xml",
      iconDestX = iconDestX,
      iconDestY = iconDestY
    }
  elseif rewardData.type == game.LootType_Costume then
    local costumeData = game.getCostumeData(rewardData.id)
    local monsterId = costumeData.monsterId
    local monsterData = game.getMonsterData(monsterId)
    local animName = game.getMonsterAnimationNameFromType(monsterId)
    if monsterData:isBoxMonster() then
      animName = monsterData:animationCostumeMenuName()
    end
    local buttonPos = getContextButtonPosition("btn_market")
    local iconDestX = buttonPos.x
    local iconDestY = buttonPos.y or lua_sys.screenHeight() - 32 * game.menuScaleX()
    return {
      name = LOC(costumeData.name) .. (amount > 1 and " x" .. amount or "") .. "\n" .. LOC("COSTUME"),
      value = amount,
      costumeId = rewardData.id,
      animFile = game.getMonsterAnimationFileFromType(costumeData.monsterId),
      animName = animName,
      bgAnimFile = "glow.bin",
      bgAnimName = "glow",
      getTargetUI = function()
        return manager:getButton("btn_market")
      end,
      iconName = "button_costume",
      iconSheet = "xml_resources/buttons01.xml",
      iconDestX = iconDestX,
      iconDestY = iconDestY
    }
  elseif rewardData.type == game.LootType_Buff then
    local extraInfo = ""
    if rewardData.island_id then
      if rewardData.island_id == "CLUBBOX" then
        extraInfo = LOC(game.existingClubboxIslandName())
      else
        extraInfo = LOC(game.islandName(rewardData.island_id))
      end
      if extraInfo ~= "" then
        extraInfo = " (" .. extraInfo .. ")"
      end
    end
    if rewardData.id == 23 then
      return {
        name = LOC("BUFF_NURSERY_TIME_REDUCTION") .. extraInfo,
        getTargetUI = function()
          return game.getHUD().Buffs
        end,
        animFile = "buff_icons.bin",
        animName = "buff_incubreduc",
        animOffsetY = 8 * game.menuScaleX(),
        iconName = "buff_incubreduc",
        iconSheet = "xml_resources/buffs_sheet.xml",
        iconScale = 0.25 * game.hudScale(),
        bgAnimFile = "glow.bin",
        bgAnimName = "glow"
      }
    elseif rewardData.id == 24 then
      return {
        name = LOC("BUFF_BREEDING_TIME_REDUCTION") .. extraInfo,
        getTargetUI = function()
          return game.getHUD().Buffs
        end,
        animFile = "buff_icons.bin",
        animName = "buff_breedreduc",
        iconName = "buff_breedreduc",
        iconSheet = "xml_resources/buffs_sheet.xml",
        iconScale = 0.25 * game.hudScale(),
        bgAnimFile = "glow.bin",
        bgAnimName = "glow"
      }
    elseif rewardData.id == 25 then
      return {
        name = LOC("BUFF_BREEDING_CHANCE_INCREASE") .. extraInfo,
        getTargetUI = function()
          return game.getHUD().Buffs
        end,
        animFile = "buff_icons.bin",
        animName = "buff_breedincr",
        iconName = "buff_breedincr",
        iconSheet = "xml_resources/buffs_sheet.xml",
        iconScale = 0.25 * game.hudScale(),
        bgAnimFile = "glow.bin",
        bgAnimName = "glow"
      }
    elseif rewardData.id == 26 then
      return {
        name = LOC("BUFF_COSTUME_CHANCE_INCREASE") .. extraInfo,
        getTargetUI = function()
          return game.getHUD().Buffs
        end,
        animFile = "buff_icons.bin",
        animName = "buff_costumeincr",
        iconName = "buff_costumeincr",
        iconSheet = "xml_resources/buffs_sheet.xml",
        iconScale = 0.25 * game.hudScale(),
        bgAnimFile = "glow.bin",
        bgAnimName = "glow"
      }
    elseif rewardData.id == 27 then
      return {
        name = LOC("BUFF_CURRENCY_COLLECTION_BONUS") .. extraInfo,
        getTargetUI = function()
          return game.getHUD().Buffs
        end,
        animFile = "buff_icons.bin",
        animName = "buff_currencyincr",
        iconName = "buff_currencyincr",
        iconSheet = "xml_resources/buffs_sheet.xml",
        iconScale = 0.25 * game.hudScale(),
        bgAnimFile = "glow.bin",
        bgAnimName = "glow"
      }
    elseif rewardData.id == 29 then
      return {
        name = LOC("BUFF_BAKING_TIME_REDUCTION") .. extraInfo,
        getTargetUI = function()
          return game.getHUD().Buffs
        end,
        animFile = "buff_icons.bin",
        animName = "buff_bakingreduc",
        iconName = "buff_bakingreduc",
        iconSheet = "xml_resources/buffs_sheet.xml",
        iconScale = 0.25 * game.hudScale(),
        bgAnimFile = "glow.bin",
        bgAnimName = "glow"
      }
    elseif rewardData.id == 36 then
      return {
        name = LOC("BUFF_BREED_DIAMOND_SPEEDUP_BOOST") .. extraInfo,
        getTargetUI = function()
          return game.getHUD().Buffs
        end,
        animFile = "battle_buttons_anim.bin",
        animName = "buff_breeding_supercharged",
        iconName = "button_buff_breeding_supercharge",
        iconSheet = "xml_resources/battle_buttons.xml",
        iconScale = 0.33 * game.hudScale(),
        bgAnimFile = "glow.bin",
        bgAnimName = "glow"
      }
    elseif rewardData.id == 37 then
      return {
        name = LOC("BUFF_NURSERY_DIAMOND_SPEEDUP_BOOST") .. extraInfo,
        getTargetUI = function()
          return game.getHUD().Buffs
        end,
        animFile = "battle_buttons_anim.bin",
        animName = "buff_incubation_supercharged",
        iconName = "button_buff_incubation_supercharge",
        iconSheet = "xml_resources/battle_buttons.xml",
        iconScale = 0.33 * game.hudScale(),
        bgAnimFile = "glow.bin",
        bgAnimName = "glow"
      }
    elseif rewardData.id == 38 then
      return {
        name = LOC("BUFF_BAKING_DIAMOND_SPEEDUP_BOOST") .. extraInfo,
        getTargetUI = function()
          return game.getHUD().Buffs
        end,
        animFile = "battle_buttons_anim.bin",
        animName = "buff_baking_supercharged",
        iconName = "button_buff_baking_supercharge",
        iconSheet = "xml_resources/battle_buttons.xml",
        iconScale = 0.33 * game.hudScale(),
        bgAnimFile = "glow.bin",
        bgAnimName = "glow"
      }
    end
  elseif rewardData.type == game.LootType_EggWildcards then
    return {
      name = getRewardString("WILDCARD", amount, hideAmounts),
      value = amount,
      animFile = "battle_buttons_anim.bin",
      animName = "wildcard pile",
      tint = {
        r = game.StoreContext_eggWildcardColour.r,
        g = game.StoreContext_eggWildcardColour.g,
        b = game.StoreContext_eggWildcardColour.b
      },
      getTargetUI = function()
        return game.getHUD().WildcardCounter
      end,
      iconName = function()
        local t = {
          "button_wildcard_01",
          "button_wildcard_05",
          "button_wildcard_09"
        }
        return t[math.random(#t)]
      end,
      iconSheet = "xml_resources/Relic_confetti01_sheet.xml",
      iconScale = 0.25 * game.hudScale(),
      soundFile = "audio/sfx/collect_key.wav",
      onComplete = function(e)
        game.engineReceiver():Send(game.MsgFlyingIconLanded(rewardData.type))
      end
    }
  elseif rewardData.type == game.LootType_ClubboxTokens then
    local targetPos = getClubboxTokenTargetPosition()
    local iconDestX = targetPos.x
    local iconDestY = targetPos.y
    return {
      name = getRewardString("CLUBBOX_TOKENS", amount, hideAmounts),
      value = amount,
      animFile = "battle_buttons_anim.bin",
      animName = "clubbox token pile",
      tint = {
        r = game.StoreContext_clubboxTokensColour.r,
        g = game.StoreContext_clubboxTokensColour.g,
        b = game.StoreContext_clubboxTokensColour.b
      },
      iconName = game.StoreContext_SPRITE_CLUBBOX_TOKENS,
      iconSheet = game.StoreContext_CURRENCY_SPRITESHEET,
      iconDestX = iconDestX,
      iconDestY = iconDestY,
      soundFile = "audio/sfx/collect_key.wav",
      onComplete = function(e)
        game.engineReceiver():Send(game.MsgFlyingIconLanded(rewardData.type))
      end
    }
  elseif rewardData.type == game.LootType_ClubboxUnlock then
    if rewardData.reward_anim == "" then
      rewardData.reward_anim = "clubbox performer"
    end
    if rewardData.text_id == "" then
      rewardData.text_id = "REWARD_CLUBBOX_PERFORMER"
    end
    return {
      name = LOC(rewardData.text_id),
      value = amount,
      animFile = "battle_buttons_anim.bin",
      animName = rewardData.reward_anim,
      soundFile = "audio/sfx/collect_key.wav"
    }
  elseif rewardData.type == game.LootType_CardPack then
    if rewardData.id == game.CardPackType_Common then
      return {
        name = getRewardString("CARD_PACK_COMMON", amount, hideAmounts),
        getTargetUI = function()
          return game.getHUD().Buffs
        end,
        animFile = "battle_buttons_anim.bin",
        animName = "sticker pack common",
        iconName = "button_sticker_pack_common",
        iconSheet = "xml_resources/battle_buttons.xml",
        bgAnimFile = "glow.bin",
        bgAnimName = "glow",
        onComplete = function(e)
          game.engineReceiver():Send(game.MsgFlyingIconLanded(rewardData.type))
        end
      }
    elseif rewardData.id == game.CardPackType_Uncommon then
      return {
        name = getRewardString("CARD_PACK_UNCOMMON", amount, hideAmounts),
        getTargetUI = function()
          return game.getHUD().Buffs
        end,
        animFile = "battle_buttons_anim.bin",
        animName = "sticker pack uncommon",
        iconName = "button_sticker_pack_uncommon",
        iconSheet = "xml_resources/battle_buttons.xml",
        bgAnimFile = "glow.bin",
        bgAnimName = "glow",
        onComplete = function(e)
          game.engineReceiver():Send(game.MsgFlyingIconLanded(rewardData.type))
        end
      }
    elseif rewardData.id == game.CardPackType_Rare then
      return {
        name = getRewardString("CARD_PACK_RARE", amount, hideAmounts),
        getTargetUI = function()
          return game.getHUD().Buffs
        end,
        animFile = "battle_buttons_anim.bin",
        animName = "sticker pack rare",
        iconName = "button_sticker_pack_rare",
        iconSheet = "xml_resources/battle_buttons.xml",
        bgAnimFile = "glow.bin",
        bgAnimName = "glow",
        onComplete = function(e)
          game.engineReceiver():Send(game.MsgFlyingIconLanded(rewardData.type))
        end
      }
    elseif rewardData.id == game.CardPackType_Epic then
      return {
        name = getRewardString("CARD_PACK_EPIC", amount, hideAmounts),
        getTargetUI = function()
          return game.getHUD().Buffs
        end,
        animFile = "battle_buttons_anim.bin",
        animName = "sticker pack epic",
        iconName = "button_sticker_pack_epic",
        iconSheet = "xml_resources/battle_buttons.xml",
        bgAnimFile = "glow.bin",
        bgAnimName = "glow",
        onComplete = function(e)
          game.engineReceiver():Send(game.MsgFlyingIconLanded(rewardData.type))
        end
      }
    elseif rewardData.id == game.CardPackType_Legendary then
      return {
        name = getRewardString("CARD_PACK_LEGENDARY", amount, hideAmounts),
        getTargetUI = function()
          return game.getHUD().Buffs
        end,
        animFile = "battle_buttons_anim.bin",
        animName = "sticker pack legendary",
        iconName = "button_sticker_pack_legendary",
        iconSheet = "xml_resources/battle_buttons.xml",
        bgAnimFile = "glow.bin",
        bgAnimName = "glow",
        onComplete = function(e)
          game.engineReceiver():Send(game.MsgFlyingIconLanded(rewardData.type))
        end
      }
    end
  elseif rewardData.type == game.LootType_ProfileItem then
    local profileItem = game.getPlayerProfileItem(rewardData.id)
    local name = ""
    local text = ""
    local spriteName = profileItem:getAssetPath()
    local bgAnimFile = "glow.bin"
    local bgAnimName = "glow"
    local type = profileItem:getItemType()
    if type == game.PlayerProfileItemType_CARD then
      name = "REWARD_PROFILE_ITEM_CARD"
    elseif type == game.PlayerProfileItemType_PHRASE then
      name = "REWARD_PROFILE_ITEM_PHRASE"
      text = profileItem:getTextId()
      spriteName = "gfx/menu/social/PurpleBanner"
    elseif type == game.PlayerProfileItemType_FRAME then
      name = "REWARD_PROFILE_ITEM_FRAME"
      bgAnimFile = ""
      bgAnimName = ""
    elseif type == game.PlayerProfileItemType_BACKGROUND then
      name = "REWARD_PROFILE_ITEM_BACKGROUND"
    elseif type == game.PlayerProfileItemType_PREMIUM then
      name = "REWARD_PROFILE_ITEM_PREMIUM"
    elseif type == game.PlayerProfileItemType_AVATAR then
      name = "REWARD_PROFILE_ITEM_AVATAR"
    end
    local iconDestX = 32 * game.hudScale()
    local iconDestY = 32 * game.hudScale()
    return {
      name = name,
      forceSpriteName = spriteName,
      forceText = text,
      bgAnimFile = bgAnimFile,
      bgAnimName = bgAnimName,
      iconDestX = iconDestX,
      iconDestY = iconDestY
    }
  elseif rewardData.type == game.LootType_MinigameTokens then
    local targetPos = getMinigameTokenTargetPosition()
    local iconDestX = targetPos.x
    local iconDestY = targetPos.y
    return {
      name = getRewardString("MINIGAME_TOKENS", amount, hideAmounts),
      value = amount,
      animFile = "battle_buttons_anim.bin",
      animName = "token pile",
      tint = {
        r = game.StoreContext_minigameTokensColour.r,
        g = game.StoreContext_minigameTokensColour.g,
        b = game.StoreContext_minigameTokensColour.b
      },
      iconName = game.StoreContext_SPRITE_MINIGAME_TOKENS,
      iconSheet = "xml_resources/hud03.xml",
      iconDestX = iconDestX,
      iconDestY = iconDestY,
      soundFile = "audio/sfx/collect_key.wav",
      onComplete = function(e)
        game.engineReceiver():Send(game.MsgFlyingIconLanded(rewardData.type))
      end
    }
  elseif rewardData.type == game.LootType_Xp then
    local iconDestX = 32 * game.hudScale()
    local iconDestY = 32 * game.hudScale()
    return {
      name = getRewardString("XP", amount, hideAmounts),
      value = amount,
      animFile = "battle_buttons_anim.bin",
      animName = "xp pile",
      tint = {
        r = game.StoreContext_xpColour.r,
        g = game.StoreContext_xpColour.g,
        b = game.StoreContext_xpColour.b
      },
      iconDestX = iconDestX,
      iconDestY = iconDestY,
      iconName = game.StoreContext_SPRITE_XP,
      iconSheet = game.StoreContext_CURRENCY_SPRITESHEET,
      soundFile = "audio/sfx/collect_xp.wav",
      onComplete = function(e)
        game.engineReceiver():Send(game.MsgFlyingIconLanded(rewardData.type))
      end
    }
  elseif rewardData.type == game.LootType_Medals then
    return {
      name = getRewardString("MEDALS", amount, hideAmounts),
      value = amount,
      animFile = "battle_buttons_anim.bin",
      animName = "xp pile",
      tint = {
        r = game.StoreContext_medalColour.r,
        g = game.StoreContext_medalColour.g,
        b = game.StoreContext_medalColour.b
      },
      getTargetUI = function()
        return game.getHUD().MedalCounter
      end,
      iconName = game.StoreContext_SPRITE_MEDAL,
      iconSheet = game.StoreContext_CURRENCY_SPRITESHEET,
      soundFile = "audio/sfx/collect_medal.wav",
      onComplete = function(e)
        game.engineReceiver():Send(game.MsgFlyingIconLanded(rewardData.type))
      end
    }
  end
  return {
    name = "REWARD NOT FOUND!",
    forceSpriteName = "gfx/menu/mystery_item"
  }
end
return RewardProperties
