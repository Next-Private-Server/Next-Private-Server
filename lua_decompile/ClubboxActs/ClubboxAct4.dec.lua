local ClubboxFunctions = include("ClubboxFunctions")
local ClubboxAct4 = {
  props = {
    prop_crowd01 = {
      unlockId = 0,
      animFile = "xml_bin/club01-04_prop_crowd01.bin",
      instrument = "000_empty.bin",
      instruments = {
        [0] = "club01_act04-prop_crowd_intro.bin",
        [4] = "club01_act04-prop_crowd01.bin"
      }
    },
    prop_crowd02 = {
      unlockId = 0,
      animFile = "xml_bin/club01-04_prop_crowd02.bin",
      instrument = "000_empty.bin",
      instruments = {
        [0] = "club01_act04-prop_crowd_intro.bin",
        [4] = "club01_act04-prop_crowd02.bin"
      }
    },
    prop_dj = {
      unlockId = 0,
      animFile = "xml_bin/club01-02_prop_off.bin",
      isMonster = 52,
      instrument = "club01_act04-Backing_INTRO.bin",
      customizeIcon = "button_djepic",
      customizeSheet = "clubbox_customization_menu.xml",
      instruments = {
        [3] = ""
      }
    },
    prop_crowd03 = {
      unlockId = 0,
      animFile = "xml_bin/club01-04_prop_crowd03.bin",
      instrument = "000_empty.bin",
      instruments = {
        [0] = "club01_act04-prop_crowd_intro.bin",
        [4] = "club01_act04-prop_crowd03.bin"
      }
    },
    prop_crowd04 = {
      unlockId = 0,
      animFile = "xml_bin/club01-04_prop_crowd04.bin",
      instrument = "000_empty.bin",
      instruments = {
        [0] = "club01_act04-prop_crowd_intro.bin",
        [4] = "club01_act04-prop_crowd04.bin"
      }
    },
    prop_crowd05 = {
      unlockId = 0,
      animFile = "xml_bin/club01-04_prop_crowd05.bin",
      instrument = "000_empty.bin",
      instruments = {
        [0] = "club01_act04-prop_crowd_intro.bin",
        [4] = "club01_act04-prop_crowd05.bin"
      }
    },
    prop_screen_closed = {
      unlockId = 0,
      maxUnlockId = 21,
      animFile = "xml_bin/club01-04_prop_screen_closed.bin"
    },
    prop_center_stage_base = {
      unlockId = 0,
      maxUnlockId = 3,
      animFile = "xml_bin/club01-04_prop_center_stage_base.bin"
    },
    prop_backwall_base = {
      unlockId = 0,
      maxUnlockId = 4,
      animFile = "xml_bin/club01-04_prop_backwall_base.bin"
    },
    prop_performer_Candelavra = {
      unlockId = 0,
      displayName = "BATTLE_COSTUME_ABCDN_2",
      isMonster = 725,
      customizeIcon = "button_candelavra",
      customizeSheet = "clubbox_customization_menu_act04.xml",
      animFile = "xml_bin/club01-04_monster_abcdn.bin",
      costumeId = 603,
      costumeFile = "xml_bin/club01-04_costume_ABCDN_02.bin",
      instrument = "club01_act04-ABCDN_A.bin",
      variants = {
        [1] = {
          name = "metro",
          displayName = "BATTLE_COSTUME_ABCDN_3",
          costumeId = 604,
          animFile = "xml_bin/club01-04_monster_abcdn.bin",
          costumeFile = "xml_bin/club01-04_costume_ABCDN_03.bin",
          instrument = "club01_act04-ABCDN_B.bin",
          unlockId = 15
        }
      }
    },
    prop_center_stage = {
      unlockId = 1,
      customizeIcon = "icon_deco_front_stage",
      customizeSheet = "clubbox_customization_menu_act02.xml",
      animFile = "xml_bin/club01-04_prop_center_stage_drift.bin",
      instrument = "club01_act04-prop_center_stage.bin",
      variants = {
        [0] = {
          name = "none",
          animFile = "xml_bin/club01-04_prop_center_stage_base.bin",
          instrument = "",
          unlockId = 1
        },
        [1] = {
          name = "metro",
          animFile = "xml_bin/club01-04_prop_center_stage_metro.bin",
          instrument = "club01_act04-prop_center_stage.bin",
          unlockId = 12
        }
      }
    },
    prop_dj_booth = {
      unlockId = 2,
      customizeIcon = "icon_deco_front_stage",
      customizeSheet = "clubbox_customization_menu_act02.xml",
      animFile = "xml_bin/club01-04_prop_dj_booth_drift.bin",
      instrument = "club01_act04-prop_dj_booth.bin",
      variants = {
        [0] = {
          name = "none",
          animFile = "xml_bin/club01-04_prop_dj_booth_drift.bin",
          instrument = "",
          unlockId = 2
        },
        [1] = {
          name = "metro",
          animFile = "xml_bin/club01-04_prop_dj_booth_metro.bin",
          instrument = "club01_act04-prop_dj_booth.bin",
          unlockId = 12
        }
      }
    },
    prop_dj_booth_back = {
      unlockId = 2,
      customizeIcon = "icon_deco_front_stage",
      customizeSheet = "clubbox_customization_menu_act02.xml",
      animFile = "xml_bin/club01-04_prop_dj_booth_back_drift.bin",
      instrument = "club01_act04-prop_dj_booth_back.bin",
      variants = {
        [0] = {
          name = "none",
          animFile = "xml_bin/club01-04_prop_dj_booth_back_drift.bin",
          instrument = "",
          unlockId = 2
        },
        [1] = {
          name = "metro",
          animFile = "xml_bin/club01-04_prop_dj_booth_back_metro.bin",
          instrument = "club01_act04-prop_dj_booth_back.bin",
          unlockId = 12
        }
      }
    },
    prop_center_stage_lights = {
      unlockId = 3,
      customizeIcon = "icon_deco_front_stage",
      customizeSheet = "clubbox_customization_menu_act02.xml",
      animFile = "xml_bin/club01-04_prop_center_stage_lights_drift.bin",
      instrument = "club01_act04-prop_center_stage_lights.bin",
      variants = {
        [0] = {
          name = "none",
          animFile = "xml_bin/club01-04_prop_center_stage_base.bin",
          instrument = "",
          unlockId = 3
        },
        [1] = {
          name = "metro",
          animFile = "xml_bin/club01-04_prop_center_stage_lights_metro.bin",
          instrument = "club01_act04-prop_center_stage_lights.bin",
          unlockId = 12
        }
      }
    },
    prop_performer_DJ = {
      unlockId = 3,
      displayName = "BATTLE_COSTUME_S05_6",
      isMonster = 52,
      customizeIcon = "button_djepic_02",
      customizeSheet = "clubbox_customization_menu_act04.xml",
      animFile = "xml_bin/club01-04_monster_s05.bin",
      costumeFile = "xml_bin/club01-04_costume_S05_06.bin",
      costumeId = 612,
      instrument = "club01_act04-Backing_A.bin",
      variants = {
        [0] = {
          name = "metro",
          displayName = "BATTLE_COSTUME_S05_7",
          costumeId = 613,
          animFile = "xml_bin/club01-04_monster_s05.bin",
          costumeFile = "xml_bin/club01-04_costume_S05_07.bin",
          instrument = "club01_act04-Backing_B.bin",
          unlockId = 13
        },
        [2] = {
          name = "booth",
          displayName = "BATTLE_COSTUME_S05_1",
          costumeId = 119,
          animFile = "xml_bin/club01-04_monster_s05.bin",
          instrument = "club01_act04-Backing_INTRO.bin",
          unlockId = 20
        }
      }
    },
    prop_backwall = {
      unlockId = 4,
      customizeIcon = "icon_deco_back_stage",
      customizeSheet = "clubbox_customization_menu_act02.xml",
      animFile = "xml_bin/club01-04_prop_backwall_drift.bin",
      instrument = "club01_act04-prop_backwall.bin",
      variants = {
        [0] = {
          name = "none",
          animFile = "xml_bin/club01-04_prop_backwall_base.bin",
          instrument = "",
          unlockId = 4
        },
        [1] = {
          name = "metro",
          animFile = "xml_bin/club01-04_prop_backwall_metro.bin",
          instrument = "club01_act04-prop_backwall.bin",
          unlockId = 10
        }
      }
    },
    prop_spotlight_left = {
      unlockId = 4,
      customizeIcon = "icon_deco_front_stage",
      customizeSheet = "clubbox_customization_menu_act02.xml",
      animFile = "xml_bin/club01-04_prop_spotlight_drift.bin",
      instrument = "club01_act04-prop_spotlight_left.bin",
      variants = {
        [0] = {
          name = "none",
          animFile = "xml_bin/club01-02_prop_off.bin",
          instrument = "",
          unlockId = 4
        },
        [1] = {
          name = "metro",
          animFile = "xml_bin/club01-04_prop_spotlight_metro.bin",
          instrument = "club01_act04-prop_spotlight_left.bin",
          unlockId = 10
        }
      }
    },
    prop_spotlight_right = {
      unlockId = 4,
      customizeIcon = "icon_deco_front_stage",
      customizeSheet = "clubbox_customization_menu_act02.xml",
      animFile = "xml_bin/club01-04_prop_spotlight_drift.bin",
      instrument = "club01_act04-prop_spotlight_right.bin",
      variants = {
        [0] = {
          name = "none",
          animFile = "xml_bin/club01-02_prop_off.bin",
          instrument = "",
          unlockId = 4
        },
        [1] = {
          name = "metro",
          animFile = "xml_bin/club01-04_prop_spotlight_metro.bin",
          instrument = "club01_act04-prop_spotlight_right.bin",
          unlockId = 10
        }
      }
    },
    prop_performer_Cranchee = {
      unlockId = 5,
      displayName = "BATTLE_COSTUME_P11_RARE_1",
      isMonster = 837,
      customizeIcon = "button_rare_cranchee",
      customizeSheet = "clubbox_customization_menu_act04.xml",
      animFile = "xml_bin/club01-04_monster_p11_rare.bin",
      costumeId = 606,
      costumeFile = "xml_bin/club01-04_costume_P11_RARE_01.bin",
      instrument = "club01_act04-P11_A.bin",
      variants = {
        [1] = {
          name = "metro",
          displayName = "BATTLE_COSTUME_P11_RARE_2",
          costumeId = 607,
          animFile = "xml_bin/club01-04_monster_p11_rare.bin",
          costumeFile = "xml_bin/club01-04_costume_P11_RARE_02.bin",
          instrument = "club01_act04-P11_B.bin",
          unlockId = 9
        }
      }
    },
    prop_glowbes_middle = {
      unlockId = 6,
      customizeIcon = "icon_deco_front_crowd",
      customizeSheet = "clubbox_customization_menu_act02.xml",
      animFile = "xml_bin/club01-04_prop_glowbes_middle_drift.bin",
      instrument = "club01_act04-prop_glowbes_middle.bin",
      variants = {
        [0] = {
          name = "none",
          animFile = "xml_bin/club01-02_prop_off.bin",
          unlockId = 6
        },
        [1] = {
          name = "metro",
          animFile = "xml_bin/club01-04_prop_glowbes_middle_metro.bin",
          instrument = "club01_act04-prop_glowbes_middle.bin",
          unlockId = 14
        }
      }
    },
    prop_performer_Skinsuit = {
      unlockId = 7,
      displayName = "BATTLE_COSTUME_I09_MAJ_1",
      isMonster = 998,
      customizeIcon = "button_skinsuit",
      customizeSheet = "clubbox_customization_menu_act04.xml",
      animFile = "xml_bin/club01-04_monster_i09_maj.bin",
      costumeId = 609,
      costumeFile = "xml_bin/club01-04_costume_I09_MAJ_01.bin",
      instrument = "club01_act04-I09_A.bin",
      variants = {
        [0] = {
          name = "metro",
          displayName = "BATTLE_COSTUME_I09_MAJ_2",
          costumeId = 610,
          animFile = "xml_bin/club01-04_monster_i09_maj.bin",
          costumeFile = "xml_bin/club01-04_costume_I09_MAJ_02.bin",
          instrument = "club01_act04-I09_B.bin",
          unlockId = 11
        }
      }
    },
    prop_on_stage_left = {
      unlockId = 8,
      customizeIcon = "icon_deco_front_stage",
      customizeSheet = "clubbox_customization_menu_act02.xml",
      animFile = "xml_bin/club01-04_prop_on_stage_drift.bin",
      instrument = "club01_act04-prop_on_stage_left.bin",
      variants = {
        [0] = {
          name = "none",
          animFile = "xml_bin/club01-02_prop_off.bin",
          instrument = "",
          unlockId = 8
        },
        [1] = {
          name = "metro",
          animFile = "xml_bin/club01-04_prop_on_stage_metro.bin",
          instrument = "club01_act04-prop_on_stage_left.bin",
          unlockId = 12
        }
      }
    },
    prop_on_stage_right = {
      unlockId = 8,
      customizeIcon = "icon_deco_front_stage",
      customizeSheet = "clubbox_customization_menu_act02.xml",
      animFile = "xml_bin/club01-04_prop_on_stage_drift.bin",
      instrument = "club01_act04-prop_on_stage_right.bin",
      variants = {
        [0] = {
          name = "none",
          animFile = "xml_bin/club01-02_prop_off.bin",
          instrument = "",
          unlockId = 8
        },
        [1] = {
          name = "metro",
          animFile = "xml_bin/club01-04_prop_on_stage_metro.bin",
          instrument = "club01_act04-prop_on_stage_right.bin",
          unlockId = 12
        }
      }
    },
    prop_speaker_left = {
      unlockId = 10,
      customizeIcon = "icon_deco_back_stage",
      customizeSheet = "clubbox_customization_menu_act02.xml",
      animFile = "xml_bin/club01-04_prop_speaker_drift.bin",
      instrument = "club01_act04-prop_speaker_left.bin",
      variants = {
        [0] = {
          name = "none",
          animFile = "xml_bin/club01-02_prop_off.bin",
          instrument = "",
          unlockId = 10
        },
        [1] = {
          name = "metro",
          animFile = "xml_bin/club01-04_prop_speaker_metro.bin",
          instrument = "club01_act04-prop_speaker_left.bin",
          unlockId = 10
        }
      }
    },
    prop_speaker_right = {
      unlockId = 10,
      customizeIcon = "icon_deco_back_stage",
      customizeSheet = "clubbox_customization_menu_act02.xml",
      animFile = "xml_bin/club01-04_prop_speaker_drift.bin",
      instrument = "club01_act04-prop_speaker_right.bin",
      variants = {
        [0] = {
          name = "none",
          animFile = "xml_bin/club01-02_prop_off.bin",
          instrument = "",
          unlockId = 10
        },
        [1] = {
          name = "metro",
          animFile = "xml_bin/club01-04_prop_speaker_metro.bin",
          instrument = "club01_act04-prop_speaker_right.bin",
          unlockId = 10
        }
      }
    },
    prop_box_left = {
      unlockId = 10,
      customizeIcon = "icon_deco_back_stage",
      customizeSheet = "clubbox_customization_menu_act02.xml",
      animFile = "xml_bin/club01-04_prop_box_drift.bin",
      instrument = "club01_act04-prop_box_left.bin",
      variants = {
        [0] = {
          name = "none",
          animFile = "xml_bin/club01-02_prop_off.bin",
          instrument = "",
          unlockId = 10
        },
        [1] = {
          name = "metro",
          animFile = "xml_bin/club01-04_prop_box_metro.bin",
          instrument = "club01_act04-prop_box_left.bin",
          unlockId = 10
        }
      }
    },
    prop_box_right = {
      unlockId = 10,
      customizeIcon = "icon_deco_back_stage",
      customizeSheet = "clubbox_customization_menu_act02.xml",
      animFile = "xml_bin/club01-04_prop_box_drift.bin",
      instrument = "club01_act04-prop_box_right.bin",
      variants = {
        [0] = {
          name = "none",
          animFile = "xml_bin/club01-02_prop_off.bin",
          instrument = "",
          unlockId = 10
        },
        [1] = {
          name = "metro",
          animFile = "xml_bin/club01-04_prop_box_metro.bin",
          instrument = "club01_act04-prop_box_right.bin",
          unlockId = 10
        }
      }
    },
    prop_stage = {
      unlockId = 12,
      customizeIcon = "icon_deco_front_stage",
      customizeSheet = "clubbox_customization_menu_act02.xml",
      animFile = "xml_bin/club01-04_prop_stage_drift.bin",
      instrument = "club01_act04-prop_stage.bin",
      variants = {
        [0] = {
          name = "none",
          animFile = "xml_bin/club01-02_prop_off.bin",
          instrument = "",
          unlockId = 12
        },
        [1] = {
          name = "metro",
          animFile = "xml_bin/club01-04_prop_stage_metro.bin",
          instrument = "club01_act04-prop_stage.bin",
          unlockId = 12
        }
      }
    },
    prop_glowbes_left = {
      unlockId = 14,
      customizeIcon = "icon_deco_front_crowd",
      customizeSheet = "clubbox_customization_menu_act02.xml",
      animFile = "xml_bin/club01-04_prop_glowbes_drift.bin",
      instrument = "club01_act04-prop_glowbes_left.bin",
      variants = {
        [0] = {
          name = "none",
          animFile = "xml_bin/club01-02_prop_off.bin",
          unlockId = 14
        },
        [1] = {
          name = "metro",
          animFile = "xml_bin/club01-04_prop_glowbes_metro.bin",
          instrument = "club01_act04-prop_glowbes_left.bin",
          unlockId = 14
        }
      }
    },
    prop_glowbes_right = {
      unlockId = 14,
      customizeIcon = "icon_deco_front_crowd",
      customizeSheet = "clubbox_customization_menu_act02.xml",
      animFile = "xml_bin/club01-04_prop_glowbes_drift.bin",
      instrument = "club01_act04-prop_glowbes_right.bin",
      variants = {
        [0] = {
          name = "none",
          animFile = "xml_bin/club01-02_prop_off.bin",
          unlockId = 14
        },
        [1] = {
          name = "metro",
          animFile = "xml_bin/club01-04_prop_glowbes_metro.bin",
          instrument = "club01_act04-prop_glowbes_right.bin",
          unlockId = 14
        }
      }
    },
    prop_stage_light_2 = {
      unlockId = 16,
      customizeIcon = "icon_deco_front_stage",
      customizeSheet = "clubbox_customization_menu_act02.xml",
      animFile = "xml_bin/club01-04_prop_light_2_drift.bin",
      instrument = "club01_act04-prop_stage_light_2.bin",
      variants = {
        [0] = {
          name = "none",
          animFile = "xml_bin/club01-02_prop_off.bin",
          instrument = "",
          unlockId = 16
        },
        [1] = {
          name = "metro",
          animFile = "xml_bin/club01-04_prop_light_2_metro.bin",
          instrument = "club01_act04-prop_stage_light_2.bin",
          unlockId = 16
        }
      }
    },
    prop_stage_light_4 = {
      unlockId = 16,
      customizeIcon = "icon_deco_front_stage",
      customizeSheet = "clubbox_customization_menu_act02.xml",
      animFile = "xml_bin/club01-04_prop_light_2_drift.bin",
      instrument = "club01_act04-prop_stage_light_2.bin",
      variants = {
        [0] = {
          name = "none",
          animFile = "xml_bin/club01-02_prop_off.bin",
          instrument = "",
          unlockId = 16
        },
        [1] = {
          name = "metro",
          animFile = "xml_bin/club01-04_prop_light_2_metro.bin",
          instrument = "club01_act04-prop_stage_light_2.bin",
          unlockId = 16
        }
      }
    },
    prop_backstage_left = {
      unlockId = 17,
      customizeIcon = "icon_deco_back_stage",
      customizeSheet = "clubbox_customization_menu_act02.xml",
      animFile = "xml_bin/club01-04_prop_backstage_drift.bin",
      instrument = "club01_act04-prop_backstage_left.bin",
      variants = {
        [0] = {
          name = "none",
          animFile = "xml_bin/club01-02_prop_off.bin",
          instrument = "",
          unlockId = 17
        },
        [1] = {
          name = "metro",
          animFile = "xml_bin/club01-04_prop_backstage_metro.bin",
          instrument = "club01_act04-prop_backstage_left.bin",
          unlockId = 17
        }
      }
    },
    prop_backstage_right = {
      unlockId = 17,
      customizeIcon = "icon_deco_back_stage",
      customizeSheet = "clubbox_customization_menu_act02.xml",
      animFile = "xml_bin/club01-04_prop_backstage_drift.bin",
      instrument = "club01_act04-prop_backstage_right.bin",
      variants = {
        [0] = {
          name = "none",
          animFile = "xml_bin/club01-02_prop_off.bin",
          instrument = "",
          unlockId = 17
        },
        [1] = {
          name = "metro",
          animFile = "xml_bin/club01-04_prop_backstage_metro.bin",
          instrument = "club01_act04-prop_backstage_right.bin",
          unlockId = 17
        }
      }
    },
    prop_back_corner_left = {
      unlockId = 17,
      customizeIcon = "icon_deco_back_stage",
      customizeSheet = "clubbox_customization_menu_act02.xml",
      animFile = "xml_bin/club01-04_prop_back_corner_drift.bin",
      instrument = "club01_act04-prop_back_corner_left.bin",
      variants = {
        [0] = {
          name = "none",
          animFile = "xml_bin/club01-02_prop_off.bin",
          instrument = "",
          unlockId = 17
        },
        [1] = {
          name = "metro",
          animFile = "xml_bin/club01-04_prop_back_corner_metro.bin",
          instrument = "club01_act04-prop_back_corner_left.bin",
          unlockId = 17
        }
      }
    },
    prop_back_corner_right = {
      unlockId = 17,
      customizeIcon = "icon_deco_back_stage",
      customizeSheet = "clubbox_customization_menu_act02.xml",
      animFile = "xml_bin/club01-04_prop_back_corner_drift.bin",
      instrument = "club01_act04-prop_back_corner_right.bin",
      variants = {
        [0] = {
          name = "none",
          animFile = "xml_bin/club01-02_prop_off.bin",
          instrument = "",
          unlockId = 17
        },
        [1] = {
          name = "metro",
          animFile = "xml_bin/club01-04_prop_back_corner_metro.bin",
          instrument = "club01_act04-prop_back_corner_right.bin",
          unlockId = 17
        }
      }
    },
    prop_screen_open = {
      unlockId = 18,
      animFile = "xml_bin/club01-01_prop_screen_open.bin",
      instrument = "club01_act04-prop_screen_open.bin",
      onSetup = function()
        print("=== Setup Wub Screen")
        ClubboxFunctions.SetupWubScreen("prop_screen_open", "wubbox_screen_mask_NOTINT")
        local wubCam = game.clubboxContext():GetWubCam()
        wubCam:setAutoMode(false)
        wubCam:setZoomProperties(2, 6, 4)
        wubCam:acquireTarget("prop_performer_Candelavra")
        wubCam:setOffset(Vector2(0, -32))
      end,
      onTrigger = function()
        local wubCamTargets = {
          [72] = "prop_performer_Candelavra",
          [73] = "prop_performer_Skinsuit",
          [74] = "prop_performer_Cranchee",
          [75] = "prop_performer_DJ",
          [76] = "prop_performer_DJ"
        }
        local wubCam = game.clubboxContext():GetWubCam()
        if ClubboxTrigger.note == 76 then
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
    prop_wubboxarm_right = {
      unlockId = 18,
      animFile = "xml_bin/club01-04_prop_wubboxarm.bin",
      instrument = "club01_act04-prop_wubboxarm_right.bin"
    },
    prop_wubboxarm_left = {
      unlockId = 18,
      animFile = "xml_bin/club01-04_prop_wubboxarm.bin",
      instrument = "club01_act04-prop_wubboxarm_left.bin"
    },
    prop_critter = {
      unlockId = 19,
      animFile = "xml_bin/club01-04_prop_critter.bin",
      instrument = "club01_act04-prop_critter.bin"
    },
    prop_stage_light_1 = {
      unlockId = 20,
      customizeIcon = "icon_deco_front_stage",
      customizeSheet = "clubbox_customization_menu_act02.xml",
      animFile = "xml_bin/club01-04_prop_light_1_drift.bin",
      instrument = "club01_act04-prop_stage_light_1.bin",
      variants = {
        [0] = {
          name = "none",
          animFile = "xml_bin/club01-02_prop_off.bin",
          instrument = "",
          unlockId = 20
        },
        [1] = {
          name = "metro",
          animFile = "xml_bin/club01-04_prop_light_1_metro.bin",
          instrument = "club01_act04-prop_stage_light_1.bin",
          unlockId = 20
        }
      }
    },
    prop_stage_light_3 = {
      unlockId = 20,
      customizeIcon = "icon_deco_front_stage",
      customizeSheet = "clubbox_customization_menu_act02.xml",
      animFile = "xml_bin/club01-04_prop_light_3_drift.bin",
      instrument = "club01_act04-prop_stage_light_3.bin",
      variants = {
        [0] = {
          name = "none",
          animFile = "xml_bin/club01-02_prop_off.bin",
          instrument = "",
          unlockId = 20
        },
        [1] = {
          name = "metro",
          animFile = "xml_bin/club01-04_prop_light_3_metro.bin",
          instrument = "club01_act04-prop_stage_light_3.bin",
          unlockId = 20
        }
      }
    },
    prop_stage_light_5 = {
      unlockId = 20,
      customizeIcon = "icon_deco_front_stage",
      customizeSheet = "clubbox_customization_menu_act02.xml",
      animFile = "xml_bin/club01-04_prop_light_1_drift.bin",
      instrument = "club01_act04-prop_stage_light_1.bin",
      variants = {
        [0] = {
          name = "none",
          animFile = "xml_bin/club01-02_prop_off.bin",
          instrument = "",
          unlockId = 20
        },
        [1] = {
          name = "metro",
          animFile = "xml_bin/club01-04_prop_light_1_metro.bin",
          instrument = "club01_act04-prop_stage_light_1.bin",
          unlockId = 20
        }
      }
    },
    prop_fx_dimmer = {
      unlockId = 0,
      animFile = "xml_bin/club01-02_prop_off.bin",
      instrument = "000_empty.bin",
      instruments = {
        [0] = "club01_act04-prop_fx_dimmer_intro.bin",
        [3] = "club01_act04-prop_fx_dimmer.bin"
      },
      onSetup = function()
        print("Setting up Dimmer!")
        game.clubboxContext():InitDimmer()
        game.clubboxContext():GetDimmer():addExclusion("prop_glowbes_left")
        game.clubboxContext():GetDimmer():addExclusion("prop_glowbes_middle")
        game.clubboxContext():GetDimmer():addExclusion("prop_glowbes_right")
        game.clubboxContext():GetDimmer():setTintMin(Vector3(0, 0, 0.2))
      end,
      onTrigger = function()
        if ClubboxTrigger.note == 72 then
          game.clubboxContext():GetDimmer():setBrightness(0.1, ClubboxTrigger.velocity)
        elseif ClubboxTrigger.note == 73 then
          game.clubboxContext():GetDimmer():setBrightness(0.8, ClubboxTrigger.velocity)
        elseif ClubboxTrigger.note == 74 then
          game.clubboxContext():GetDimmer():setBrightness(1, ClubboxTrigger.velocity)
        elseif ClubboxTrigger.note == 75 then
          game.clubboxContext():GetDimmer():setBrightness(0.7, ClubboxTrigger.velocity)
        end
      end
    },
    prop_fx_lightspeed = {
      unlockId = 0,
      animFile = "xml_bin/club01-02_prop_off.bin",
      instrument = "club01_act04-prop_fx_lightspeed.bin",
      onSetup = function()
        print("=== Setting up Lightspeed...")
        if game.isDebugBuild() then
          game.clearShader("ShaderClubboxLightspeed")
        end
        local shader = include("ShaderClubboxLightspeed")
        if shader then
          game.clubboxContext():SetSkyShader(shader)
          local hud = game.clubboxContext():menu()
          if hud then
            do
              local fadeTransition = include("FadeTransition"):new({
                duration = 1,
                delayOnHide = 1,
                onUpdate = function(alpha)
                  local lightSpeedShader = game.getShader("ShaderClubboxLightspeed")
                  if lightSpeedShader and lightSpeedShader:hasUniform("u_Brightness") then
                    lightSpeedShader:getUniform("u_Brightness"):setFloat(alpha)
                  end
                end
              })
              hud:addTickable("LightspeedFader", fadeTransition)
              fadeTransition:SetAlpha(0)
              local speedTransition = include("FadeTransition"):new({
                delayOnShow = 0.33,
                duration = 1,
                ease = Cubic_EaseOut,
                onUpdate = function(speed)
                  local lightSpeedShader = game.getShader("ShaderClubboxLightspeed")
                  if lightSpeedShader and lightSpeedShader:hasUniform("u_Speed") then
                    shader:getUniform("u_Speed"):setFloat(speed * 2)
                  end
                end
              })
              hud:addTickable("LightspeedSpeeder", speedTransition)
              speedTransition:SetAlpha(0)
              local lightspeedTicker = {
                offset = 0,
                Tick = function(x, dt)
                  local speed = speedTransition.alpha * 2
                  x.offset = x.offset + speed * dt
                  local lightSpeedShader = game.getShader("ShaderClubboxLightspeed")
                  if lightSpeedShader and lightSpeedShader:hasUniform("u_Offset") then
                    shader:getUniform("u_Offset"):setFloat(x.offset)
                  end
                end
              }
              hud:addTickable("LightspeedTicker", lightspeedTicker)
            end
          end
        end
      end,
      onTrigger = function()
        local hud = game.clubboxContext():menu()
        local fader = hud:getTickable("LightspeedFader")
        local speeder = hud:getTickable("LightspeedSpeeder")
        if ClubboxTrigger.note == 72 then
          fader:Show()
          speeder:Show()
        elseif ClubboxTrigger.note == 74 then
          fader:Hide()
          speeder:Hide()
        end
      end
    },
    prop_fx_pulse = {
      unlockId = 18,
      animFile = "xml_bin/club01-02_prop_off.bin",
      instrument = "club01_act04-prop_fx_screenpulse.bin",
      onTrigger = function()
        if not ClubboxFunctions:IsScreenFxEnabled() then
          return
        end
        if ClubboxTrigger.note == 72 then
          game.clubboxContext():PulseCamera(0.2, 5, 0.3)
        end
      end
    }
  }
}
return ClubboxAct4
