local ClubboxFunctions = include("ClubboxFunctions")
local ClubboxAct1 = {
  props = {
    prop_crowd01 = {
      unlockId = 0,
      animFile = "xml_bin/club01-01_prop_crowd01.bin",
      instrument = "club01_act01-prop_crowd01.bin"
    },
    prop_crowd02 = {
      unlockId = 0,
      animFile = "xml_bin/club01-01_prop_crowd02.bin",
      instrument = "club01_act01-prop_crowd02.bin"
    },
    prop_dj = {
      unlockId = 0,
      animFile = "xml_bin/club01-01_prop_dj.bin",
      instrument = "club01_act01-Backing_A.bin",
      isMonster = 52,
      customizeIcon = "button_djepic",
      customizeSheet = "clubbox_customization_menu.xml",
      instruments = {
        [2] = "club01_act01-Backing_B.bin",
        [4] = "club01_act01-Backing_C.bin",
        [9] = "club01_act01-Backing_D.bin",
        [11] = "club01_act01-Backing_E.bin"
      },
      onPick = ClubboxFunctions.OnPickDJ
    },
    prop_crowd03 = {
      unlockId = 0,
      animFile = "xml_bin/club01-01_prop_crowd03.bin",
      instrument = "club01_act01-prop_crowd03.bin"
    },
    prop_critter = {
      unlockId = 21,
      animFile = "xml_bin/club01-01_prop_critter.bin",
      instrument = "club01_act01-prop_critter.bin"
    },
    prop_crowd04 = {
      unlockId = 0,
      animFile = "xml_bin/club01-01_prop_crowd04.bin",
      instrument = "club01_act01-prop_crowd04.bin"
    },
    Performer_P06 = {
      unlockId = 3,
      displayName = "BATTLE_COSTUME_P06_2",
      isMonster = 641,
      customizeIcon = "button_anglow",
      customizeSheet = "clubbox_customization_menu_act01.xml",
      animFile = "xml_bin/club01-01_monster_p06.bin",
      costumeFile = "xml_bin/club01-01_costume_P06_02.bin",
      costumeId = 572,
      instrument = "club01_act01-P06_A.bin",
      variants = {
        [0] = {
          name = "edm",
          displayName = "BATTLE_COSTUME_P06_3",
          animFile = "xml_bin/club01-01_monster_p06.bin",
          costumeFile = "xml_bin/club01-01_costume_P06_03.bin",
          costumeId = 573,
          instrument = "club01_act01-P06_B.bin",
          unlockId = 14
        },
        [1] = {
          name = "bling",
          displayName = "BATTLE_COSTUME_P06_4",
          animFile = "xml_bin/club01-01_monster_p06.bin",
          costumeFile = "xml_bin/club01-01_costume_P06_04.bin",
          costumeId = 574,
          instrument = "club01_act01-P06_C.bin",
          unlockId = 23
        }
      }
    },
    Performer_T06 = {
      unlockId = 10,
      displayName = "BATTLE_COSTUME_T06_1",
      isMonster = 251,
      customizeIcon = "button_hornacle",
      customizeSheet = "clubbox_customization_menu_act01.xml",
      animFile = "xml_bin/club01-01_monster_t06.bin",
      costumeFile = "xml_bin/club01-01_costume_T06_01.bin",
      costumeId = 578,
      instrument = "club01_act01-T06_A.bin",
      variants = {
        [0] = {
          name = "edm",
          displayName = "BATTLE_COSTUME_T06_2",
          animFile = "xml_bin/club01-01_monster_t06.bin",
          costumeFile = "xml_bin/club01-01_costume_T06_02.bin",
          costumeId = 579,
          instrument = "club01_act01-T06_B.bin",
          unlockId = 18
        },
        [1] = {
          name = "bling",
          displayName = "BATTLE_COSTUME_T06_3",
          animFile = "xml_bin/club01-01_monster_t06.bin",
          costumeFile = "xml_bin/club01-01_costume_T06_03.bin",
          costumeId = 580,
          instrument = "club01_act01-T06_C.bin",
          unlockId = 25
        }
      }
    },
    Performer_U09 = {
      unlockId = 6,
      displayName = "BATTLE_COSTUME_U09_1",
      isMonster = 149,
      customizeIcon = "button_dermit",
      customizeSheet = "clubbox_customization_menu_act01.xml",
      animFile = "xml_bin/club01-01_monster_U09.bin",
      costumeFile = "xml_bin/club01-01_costume_U09_01.bin",
      costumeId = 575,
      instrument = "club01_act01-U09_A.bin",
      variants = {
        [0] = {
          name = "edm",
          displayName = "BATTLE_COSTUME_U09_2",
          animFile = "xml_bin/club01-01_monster_U09.bin",
          costumeFile = "xml_bin/club01-01_costume_U09_02.bin",
          costumeId = 576,
          instrument = "club01_act01-U09_B.bin",
          unlockId = 12
        },
        [1] = {
          name = "bling",
          displayName = "BATTLE_COSTUME_U09_3",
          animFile = "xml_bin/club01-01_monster_U09.bin",
          costumeFile = "xml_bin/club01-01_costume_U09_03.bin",
          costumeId = 577,
          instrument = "club01_act01-U09_C.bin",
          unlockId = 27
        }
      }
    },
    Performer_G = {
      unlockId = 1,
      displayName = "BATTLE_COSTUME_G_8",
      isMonster = 50,
      customizeIcon = "button_ghazt",
      customizeSheet = "clubbox_customization_menu_act01.xml",
      animFile = "xml_bin/club01-01_monster_G.bin",
      costumeFile = "xml_bin/club01-01_costume_G_08.bin",
      costumeId = 569,
      instrument = "club01_act01-G_A.bin",
      variants = {
        [0] = {
          name = "edm",
          displayName = "BATTLE_COSTUME_G_9",
          animFile = "xml_bin/club01-01_monster_G.bin",
          costumeFile = "xml_bin/club01-01_costume_G_09.bin",
          costumeId = 570,
          instrument = "club01_act01-G_B.bin",
          unlockId = 16
        },
        [1] = {
          name = "bling",
          displayName = "BATTLE_COSTUME_G_10",
          animFile = "xml_bin/club01-01_monster_G.bin",
          costumeFile = "xml_bin/club01-01_costume_G_10.bin",
          costumeId = 571,
          instrument = "club01_act01-G_C.bin",
          unlockId = 22
        }
      }
    },
    Performer_Z11 = {
      unlockId = 0,
      displayName = "BATTLE_COSTUME_Z11_1",
      isMonster = 979,
      customizeIcon = "button_autotuna",
      customizeSheet = "clubbox_customization_menu_act01.xml",
      animFile = "xml_bin/club01-01_monster_Z11.bin",
      costumeFile = "xml_bin/club01-01_costume_Z11_01.bin",
      costumeId = 566,
      instrument = "club01_act01-Z11_A.bin",
      variants = {
        [0] = {
          name = "edm",
          displayName = "BATTLE_COSTUME_Z11_2",
          animFile = "xml_bin/club01-01_monster_Z11.bin",
          costumeFile = "xml_bin/club01-01_costume_Z11_02.bin",
          costumeId = 567,
          instrument = "club01_act01-Z11_B.bin",
          unlockId = 20
        },
        [1] = {
          name = "bling",
          displayName = "BATTLE_COSTUME_Z11_3",
          animFile = "xml_bin/club01-01_monster_Z11.bin",
          costumeFile = "xml_bin/club01-01_costume_Z11_03.bin",
          costumeId = 568,
          instrument = "club01_act01-Z11_C.bin",
          unlockId = 29
        }
      }
    },
    prop_stage_frontL = {
      unlockId = 24,
      customizeIcon = "icon_deco_front_stage",
      customizeSheet = "clubbox_customization_menu_act02.xml",
      animFile = "xml_bin/club01-01_prop_stage_frontL_water.bin",
      instrument = "club01_act01-prop_stage_frontL.bin",
      variants = {
        [0] = {
          name = "none",
          animFile = "xml_bin/club01-02_prop_off.bin",
          instrument = "",
          unlockId = 24
        },
        [1] = {
          name = "edm",
          animFile = "xml_bin/club01-01_prop_stage_frontL_edm.bin",
          unlockId = 24
        },
        [2] = {
          name = "bling",
          animFile = "xml_bin/club01-01_prop_stage_frontL_bling.bin",
          unlockId = 24
        }
      }
    },
    prop_crowd05 = {
      unlockId = 0,
      animFile = "xml_bin/club01-01_prop_crowd05.bin",
      instrument = "club01_act01-prop_crowd05.bin"
    },
    prop_wubarmL = {
      unlockId = 19,
      animFile = "xml_bin/club01-01_prop_wubbox_arm.bin",
      instrument = "club01_act01-prop_wubarmL.bin"
    },
    prop_crowd06 = {
      unlockId = 0,
      animFile = "xml_bin/club01-01_prop_crowd06.bin",
      instrument = "club01_act01-prop_crowd06.bin"
    },
    prop_crowd07 = {
      unlockId = 0,
      animFile = "xml_bin/club01-01_prop_crowd07.bin",
      instrument = "club01_act01-prop_crowd07.bin"
    },
    prop_wubarmR = {
      unlockId = 19,
      animFile = "xml_bin/club01-01_prop_wubbox_arm.bin",
      instrument = "club01_act01-prop_wubarmR.bin"
    },
    prop_crowd08 = {
      unlockId = 0,
      animFile = "xml_bin/club01-01_prop_crowd08.bin",
      instrument = "club01_act01-prop_crowd08.bin"
    },
    prop_stage_backL = {
      unlockId = 13,
      customizeIcon = "icon_deco_front_stage",
      customizeSheet = "clubbox_customization_menu_act02.xml",
      animFile = "xml_bin/club01-01_prop_stage_backL_water.bin",
      instrument = "club01_act01-prop_stage_backL.bin",
      variants = {
        [0] = {
          name = "none",
          animFile = "xml_bin/club01-02_prop_off.bin",
          instrument = "",
          unlockId = 13
        },
        [1] = {
          name = "edm",
          animFile = "xml_bin/club01-01_prop_stage_backL_edm.bin",
          unlockId = 13
        },
        [2] = {
          name = "bling",
          animFile = "xml_bin/club01-01_prop_stage_backL_bling.bin",
          unlockId = 24
        }
      }
    },
    prop_stage_backR = {
      unlockId = 8,
      customizeIcon = "icon_deco_front_stage",
      customizeSheet = "clubbox_customization_menu_act02.xml",
      animFile = "xml_bin/club01-01_prop_stage_backR_water.bin",
      instrument = "club01_act01-prop_stage_backR.bin",
      variants = {
        [0] = {
          name = "none",
          animFile = "xml_bin/club01-02_prop_off.bin",
          instrument = "",
          unlockId = 8
        },
        [1] = {
          name = "edm",
          animFile = "xml_bin/club01-01_prop_stage_backR_edm.bin",
          unlockId = 13
        },
        [2] = {
          name = "bling",
          animFile = "xml_bin/club01-01_prop_stage_backR_bling.bin",
          unlockId = 24
        }
      }
    },
    prop_stage_frontR = {
      unlockId = 2,
      customizeIcon = "icon_deco_front_stage",
      customizeSheet = "clubbox_customization_menu_act02.xml",
      animFile = "xml_bin/club01-01_prop_stage_frontR_water.bin",
      instrument = "club01_act01-prop_stage_frontR.bin",
      variants = {
        [0] = {
          name = "none",
          animFile = "xml_bin/club01-02_prop_off.bin",
          instrument = "",
          unlockId = 2
        },
        [1] = {
          name = "edm",
          animFile = "xml_bin/club01-01_prop_stage_frontR_edm.bin",
          unlockId = 13
        },
        [2] = {
          name = "bling",
          animFile = "xml_bin/club01-01_prop_stage_frontR_bling.bin",
          unlockId = 24
        }
      }
    },
    prop_stage_backM = {
      unlockId = 24,
      customizeIcon = "icon_deco_front_stage",
      customizeSheet = "clubbox_customization_menu_act02.xml",
      animFile = "xml_bin/club01-01_prop_stage_backM_water.bin",
      instrument = "club01_act01-prop_stage_backM.bin",
      variants = {
        [0] = {
          name = "none",
          animFile = "xml_bin/club01-02_prop_off.bin",
          instrument = "",
          unlockId = 24
        },
        [1] = {
          name = "edm",
          animFile = "xml_bin/club01-01_prop_stage_backM_edm.bin",
          unlockId = 24
        },
        [2] = {
          name = "bling",
          animFile = "xml_bin/club01-01_prop_stage_backM_bling.bin",
          unlockId = 24
        }
      }
    },
    prop_sidebackR = {
      unlockId = 17,
      customizeIcon = "icon_deco_special_effects",
      customizeSheet = "clubbox_customization_menu_act02.xml",
      animFile = "xml_bin/club01-01_prop_sideback_water.bin",
      instrument = "club01_act01-prop_sidebackR.bin",
      variants = {
        [0] = {
          name = "none",
          animFile = "xml_bin/club01-02_prop_off.bin",
          instrument = "",
          unlockId = 17
        },
        [1] = {
          name = "edm",
          animFile = "xml_bin/club01-01_prop_sideback_edm.bin",
          unlockId = 17
        },
        [2] = {
          name = "bling",
          animFile = "xml_bin/club01-01_prop_sideback_bling.bin",
          unlockId = 24
        }
      }
    },
    prop_sidebackL = {
      unlockId = 5,
      customizeIcon = "icon_deco_special_effects",
      customizeSheet = "clubbox_customization_menu_act02.xml",
      animFile = "xml_bin/club01-01_prop_sideback_water.bin",
      instrument = "club01_act01-prop_sidebackL.bin",
      variants = {
        [0] = {
          name = "none",
          animFile = "xml_bin/club01-02_prop_off.bin",
          instrument = "",
          unlockId = 5
        },
        [1] = {
          name = "edm",
          animFile = "xml_bin/club01-01_prop_sideback_edm.bin",
          unlockId = 17
        },
        [2] = {
          name = "bling",
          animFile = "xml_bin/club01-01_prop_sideback_bling.bin",
          unlockId = 24
        }
      }
    },
    prop_stage = {
      unlockId = 0,
      customizeIcon = "icon_deco_front_stage",
      customizeSheet = "clubbox_customization_menu_act02.xml",
      animFile = "xml_bin/club01-01_prop_stage_water.bin",
      instrument = "club01_act01-prop_stage.bin",
      variants = {
        [0] = {
          name = "none",
          animFile = "xml_bin/club01-01_prop_stage_water.bin",
          instrument = "",
          unlockId = 13
        },
        [1] = {
          name = "edm",
          animFile = "xml_bin/club01-01_prop_stage_edm.bin",
          unlockId = 13
        },
        [2] = {
          name = "bling",
          animFile = "xml_bin/club01-01_prop_stage_bling.bin",
          unlockId = 24
        }
      }
    },
    prop_stage_under = {
      unlockId = 9,
      customizeIcon = "icon_deco_front_stage",
      customizeSheet = "clubbox_customization_menu_act02.xml",
      animFile = "xml_bin/club01-01_prop_stage_under_water.bin",
      variants = {
        [0] = {
          name = "none",
          animFile = "xml_bin/club01-02_prop_off.bin",
          instrument = "",
          unlockId = 9
        },
        [1] = {
          name = "edm",
          animFile = "xml_bin/club01-01_prop_stage_under_edm.bin",
          unlockId = 13
        },
        [2] = {
          name = "bling",
          animFile = "xml_bin/club01-01_prop_stage_under_bling.bin",
          unlockId = 24
        }
      }
    },
    prop_speaker01L = {
      unlockId = 28,
      customizeIcon = "icon_deco_back_stage",
      customizeSheet = "clubbox_customization_menu_act02.xml",
      animFile = "xml_bin/club01-01_prop_speaker01_water.bin",
      instrument = "club01_act01-prop_speaker01L.bin",
      variants = {
        [0] = {
          name = "none",
          animFile = "xml_bin/club01-02_prop_off.bin",
          instrument = "",
          unlockId = 28
        },
        [1] = {
          name = "edm",
          animFile = "xml_bin/club01-01_prop_speaker01_edm.bin",
          unlockId = 28
        },
        [2] = {
          name = "bling",
          animFile = "xml_bin/club01-01_prop_speaker01_bling.bin",
          unlockId = 28
        }
      }
    },
    prop_speaker01R = {
      unlockId = 15,
      customizeIcon = "icon_deco_back_stage",
      customizeSheet = "clubbox_customization_menu_act02.xml",
      animFile = "xml_bin/club01-01_prop_speaker01_water.bin",
      instrument = "club01_act01-prop_speaker01R.bin",
      variants = {
        [0] = {
          name = "none",
          animFile = "xml_bin/club01-02_prop_off.bin",
          instrument = "",
          unlockId = 15
        },
        [1] = {
          name = "edm",
          animFile = "xml_bin/club01-01_prop_speaker01_edm.bin",
          unlockId = 15
        },
        [2] = {
          name = "bling",
          animFile = "xml_bin/club01-01_prop_speaker01_bling.bin",
          unlockId = 28
        }
      }
    },
    prop_speaker02L = {
      unlockId = 4,
      customizeIcon = "icon_deco_back_stage",
      customizeSheet = "clubbox_customization_menu_act02.xml",
      animFile = "xml_bin/club01-01_prop_speaker02_water.bin",
      instrument = "club01_act01-prop_speaker02L.bin",
      variants = {
        [0] = {
          name = "none",
          animFile = "xml_bin/club01-02_prop_off.bin",
          instrument = "",
          unlockId = 4
        },
        [1] = {
          name = "edm",
          animFile = "xml_bin/club01-01_prop_speaker02_edm.bin",
          unlockId = 15
        },
        [2] = {
          name = "bling",
          animFile = "xml_bin/club01-01_prop_speaker02_bling.bin",
          unlockId = 28
        }
      }
    },
    prop_speaker02R = {
      unlockId = 7,
      customizeIcon = "icon_deco_back_stage",
      customizeSheet = "clubbox_customization_menu_act02.xml",
      animFile = "xml_bin/club01-01_prop_speaker02_water.bin",
      instrument = "club01_act01-prop_speaker02R.bin",
      variants = {
        [0] = {
          name = "none",
          animFile = "xml_bin/club01-02_prop_off.bin",
          instrument = "",
          unlockId = 7
        },
        [1] = {
          name = "edm",
          animFile = "xml_bin/club01-01_prop_speaker02_edm.bin",
          unlockId = 15
        },
        [2] = {
          name = "bling",
          animFile = "xml_bin/club01-01_prop_speaker02_bling.bin",
          unlockId = 28
        }
      }
    },
    prop_screen_closed = {
      unlockId = 0,
      maxUnlockId = 30,
      animFile = "xml_bin/club01-01_prop_screen_closed.bin"
    },
    prop_screen_open = {
      unlockId = 30,
      animFile = "xml_bin/club01-01_prop_screen_open.bin",
      instrument = "club01_act01-prop_screen_open.bin",
      onSetup = function()
        print("=== Setup Wub Screen")
        ClubboxFunctions.SetupWubScreen("prop_screen_open", "wubbox_screen_mask_NOTINT")
        local wubCam = game.clubboxContext():GetWubCam()
        wubCam:setAutoMode(false)
        wubCam:setZoomProperties(2, 6, 4)
        wubCam:acquireTarget("Performer_Z11")
      end,
      onTrigger = function()
        local wubCamTargets = {
          [72] = "Performer_Z11",
          [73] = "Performer_P06",
          [74] = "Performer_T06",
          [75] = "Performer_G",
          [76] = "Performer_U09",
          [77] = "prop_dj"
        }
        local wubCam = game.clubboxContext():GetWubCam()
        if ClubboxTrigger.note == 77 then
          wubCam:setZoomProperties(5, 1, 4)
        else
          wubCam:setZoomProperties(2, 6, 4)
        end
        local target = wubCamTargets[ClubboxTrigger.note]
        if target then
          wubCam:acquireTarget(target)
        else
          wubCam:acquireNextTarget()
        end
      end
    },
    prop_aisle_coverR = {
      unlockId = 8,
      customizeIcon = "icon_deco_front_stage",
      customizeSheet = "clubbox_customization_menu_act02.xml",
      animFile = "xml_bin/club01-01_prop_aisle_cover_water.bin",
      instrument = "club01_act01-prop_aisle_coverR.bin",
      variants = {
        [0] = {
          name = "none",
          animFile = "xml_bin/club01-02_prop_off.bin",
          instrument = "",
          unlockId = 8
        },
        [1] = {
          name = "edm",
          animFile = "xml_bin/club01-01_prop_aisle_cover_edm.bin",
          unlockId = 13
        },
        [2] = {
          name = "bling",
          animFile = "xml_bin/club01-01_prop_aisle_cover_bling.bin",
          unlockId = 24
        }
      }
    },
    prop_aisle_coverL = {
      unlockId = 24,
      customizeIcon = "icon_deco_front_stage",
      customizeSheet = "clubbox_customization_menu_act02.xml",
      animFile = "xml_bin/club01-01_prop_aisle_cover_water.bin",
      instrument = "club01_act01-prop_aisle_coverL.bin",
      variants = {
        [0] = {
          name = "none",
          animFile = "xml_bin/club01-02_prop_off.bin",
          instrument = "",
          unlockId = 24
        },
        [1] = {
          name = "edm",
          animFile = "xml_bin/club01-01_prop_aisle_cover_edm.bin",
          unlockId = 24
        },
        [2] = {
          name = "bling",
          animFile = "xml_bin/club01-01_prop_aisle_cover_bling.bin",
          unlockId = 24
        }
      }
    },
    prop_aisleR = {
      unlockId = 30,
      animFile = "xml_bin/club01-01_prop_aisle.bin",
      instrument = "club01_act01-prop_aisleR.bin"
    },
    prop_aisle_staticR = {
      unlockId = 8,
      maxUnlockId = 30,
      animFile = "xml_bin/club01-01_prop_aisle_static.bin"
    },
    prop_aisleL = {
      unlockId = 30,
      animFile = "xml_bin/club01-01_prop_aisle.bin",
      instrument = "club01_act01-prop_aisleL.bin"
    },
    prop_aisle_staticL = {
      unlockId = 19,
      maxUnlockId = 30,
      animFile = "xml_bin/club01-01_prop_aisle_static.bin"
    },
    prop_backwall_glowL = {
      unlockId = 15,
      animFile = "xml_bin/club01-01_prop_backwall_glow.bin",
      instrument = "club01_act01-prop_backwall_glowL.bin"
    },
    prop_backwall_glowR = {
      unlockId = 15,
      animFile = "xml_bin/club01-01_prop_backwall_glow.bin",
      instrument = "club01_act01-prop_backwall_glowR.bin"
    },
    prop_fx_screenshake = {
      unlockId = 15,
      animFile = "xml_bin/club01-02_prop_off.bin",
      instrument = "000_empty.bin",
      instruments = {
        [15] = "club01_act01-fx_screenshake_A.bin",
        [19] = "club01_act01-fx_screenshake_B.bin"
      },
      onTrigger = function()
        if not ClubboxFunctions:IsScreenFxEnabled() then
          return
        end
        if ClubboxTrigger.note == 72 then
          local magnitude, damping, duration = 40 * (ClubboxTrigger.velocity / 100), 0.7, 1.5
          game.clubboxContext():ShakeCamera(magnitude, damping, duration)
        elseif ClubboxTrigger.note == 73 then
          local magnitude, damping, duration = 20 * (ClubboxTrigger.velocity / 100), 0.3, 0.5
          game.clubboxContext():ShakeCamera(magnitude, damping, duration)
        end
      end
    }
  }
}
return ClubboxAct1
