local ClubboxFunctions = include("ClubboxFunctions")
local ClubboxAct2 = {
  props = {
    prop_crowd01 = {
      unlockId = 0,
      animFile = "xml_bin/club01-03_prop_crowd01.bin",
      instrument = "club01_act03-prop_crowd01.bin"
    },
    prop_incrowd_blockerR = {
      unlockId = 0,
      maxUnlockId = 10,
      animFile = "xml_bin/club01-03_prop_incrowd_blocker.bin"
    },
    prop_incrowd_blockerL = {
      unlockId = 0,
      maxUnlockId = 10,
      animFile = "xml_bin/club01-03_prop_incrowd_blocker.bin"
    },
    prop_incrowdR = {
      unlockId = 10,
      customizeIcon = "icon_deco_front_crowd",
      customizeSheet = "clubbox_customization_menu_act02.xml",
      animFile = "xml_bin/club01-03_prop_incrowd_punk.bin",
      instrument = "club01_act03-prop_incrowdR.bin",
      variants = {
        [0] = {
          name = "none",
          animFile = "xml_bin/club01-03_prop_incrowd_blocker.bin",
          instrument = "",
          unlockId = 10
        },
        [1] = {
          name = "anime",
          animFile = "xml_bin/club01-03_prop_incrowd_mech.bin",
          unlockId = 15
        }
      }
    },
    prop_incrowdL = {
      unlockId = 10,
      customizeIcon = "icon_deco_front_crowd",
      customizeSheet = "clubbox_customization_menu_act02.xml",
      animFile = "xml_bin/club01-03_prop_incrowd_punk.bin",
      instrument = "club01_act03-prop_incrowdL.bin",
      variants = {
        [0] = {
          name = "none",
          animFile = "xml_bin/club01-03_prop_incrowd_blocker.bin",
          instrument = "",
          unlockId = 10
        },
        [1] = {
          name = "anime",
          animFile = "xml_bin/club01-03_prop_incrowd_mech.bin",
          unlockId = 15
        }
      }
    },
    prop_crowd02 = {
      unlockId = 0,
      animFile = "xml_bin/club01-03_prop_crowd02.bin",
      instrument = "club01_act03-prop_crowd02.bin"
    },
    prop_dj = {
      unlockId = 0,
      animFile = "xml_bin/club01-03_prop_dj.bin",
      instrument = "club01_act03-Backing_A.bin",
      isMonster = 52,
      customizeIcon = "button_djepic",
      customizeSheet = "clubbox_customization_menu.xml",
      instruments = {
        [2] = "club01_act03-Backing_B.bin",
        [4] = "club01_act03-Backing_C.bin",
        [6] = "club01_act03-Backing_D.bin",
        [7] = "club01_act03-Backing_E.bin"
      },
      onPick = ClubboxFunctions.OnPickDJ
    },
    prop_crowd03 = {
      unlockId = 0,
      animFile = "xml_bin/club01-03_prop_crowd03.bin",
      instrument = "club01_act03-prop_crowd03.bin"
    },
    prop_crowd04 = {
      unlockId = 0,
      animFile = "xml_bin/club01-03_prop_crowd04.bin",
      instrument = "club01_act03-prop_crowd04.bin"
    },
    prop_crowd05 = {
      unlockId = 0,
      animFile = "xml_bin/club01-03_prop_crowd05.bin",
      instrument = "club01_act03-prop_crowd05.bin"
    },
    prop_stage_front01 = {
      unlockId = 2,
      customizeIcon = "icon_deco_front_stage",
      customizeSheet = "clubbox_customization_menu_act02.xml",
      animFile = "xml_bin/club01-03_prop_stage_front01_punk.bin",
      instrument = "club01_act03-prop_stage_front01.bin",
      variants = {
        [0] = {
          name = "none",
          animFile = "xml_bin/club01-02_prop_off.bin",
          unlockId = 2
        },
        [1] = {
          name = "anime",
          animFile = "xml_bin/club01-03_prop_stage_front01_mech.bin",
          unlockId = 12
        }
      }
    },
    prop_stage_front02 = {
      unlockId = 0,
      customizeIcon = "icon_deco_front_stage",
      customizeSheet = "clubbox_customization_menu_act02.xml",
      animFile = "xml_bin/club01-03_prop_stage_front02_punk.bin",
      instrument = "club01_act03-prop_stage_front02.bin",
      variants = {
        [0] = {
          name = "none",
          animFile = "xml_bin/club01-02_prop_off.bin",
          unlockId = 0
        },
        [1] = {
          name = "anime",
          animFile = "xml_bin/club01-03_prop_stage_front02_mech.bin",
          unlockId = 12
        }
      }
    },
    prop_performer_Attmoz = {
      unlockId = 3,
      displayName = "BATTLE_COSTUME_T05_1",
      isMonster = 252,
      customizeIcon = "button_attmoz",
      customizeSheet = "clubbox_customization_menu_act03.xml",
      animFile = "xml_bin/club01-03_monster_t05.bin",
      costumeFile = "xml_bin/club01-03_costume_T05_01.bin",
      costumeId = 525,
      instrument = "club01_act03-T05_A.bin",
      variants = {
        [0] = {
          name = "anime",
          displayName = "BATTLE_COSTUME_T05_2",
          costumeId = 526,
          animFile = "xml_bin/club01-03_monster_t05.bin",
          costumeFile = "xml_bin/club01-03_costume_T05_02.bin",
          instrument = "club01_act03-T05_B.bin",
          unlockId = 9
        }
      }
    },
    prop_performer_Phangler = {
      unlockId = 0,
      displayName = "BATTLE_COSTUME_DN_EPIC_1",
      isMonster = 783,
      customizeIcon = "button_epic_phangler",
      customizeSheet = "clubbox_customization_menu_act03.xml",
      animFile = "xml_bin/club01-03_monster_dn_epic.bin",
      costumeFile = "xml_bin/club01-03_costume_DN_EPIC_01.bin",
      costumeId = 516,
      instrument = "club01_act03-DN_A.bin",
      variants = {
        [0] = {
          name = "anime",
          displayName = "BATTLE_COSTUME_DN_EPIC_2",
          costumeId = 517,
          animFile = "xml_bin/club01-03_monster_dn_epic.bin",
          costumeFile = "xml_bin/club01-03_costume_DN_EPIC_02.bin",
          instrument = "club01_act03-DN_B.bin",
          unlockId = 13
        }
      }
    },
    prop_performer_Shellbeat = {
      unlockId = 1,
      displayName = "BATTLE_COSTUME_ABCD_RARE_1",
      isMonster = 110,
      customizeIcon = "button_epic_shellbeat",
      customizeSheet = "clubbox_customization_menu_act03.xml",
      animFile = "xml_bin/club01-03_monster_abcd_rare.bin",
      costumeFile = "xml_bin/club01-03_costume_ABCD_RARE_01.bin",
      costumeId = 519,
      instrument = "club01_act03-ABCD_A.bin",
      variants = {
        [0] = {
          name = "anime",
          displayName = "BATTLE_COSTUME_ABCD_RARE_2",
          costumeId = 520,
          animFile = "xml_bin/club01-03_monster_abcd_rare.bin",
          costumeFile = "xml_bin/club01-03_costume_ABCD_RARE_02.bin",
          instrument = "club01_act03-ABCD_B.bin",
          unlockId = 11
        }
      }
    },
    prop_performer_Fleechwurm = {
      unlockId = 5,
      displayName = "BATTLE_COSTUME_U20_1",
      isMonster = 246,
      customizeIcon = "button_fleechwurm",
      customizeSheet = "clubbox_customization_menu_act03.xml",
      animFile = "xml_bin/club01-03_monster_u20.bin",
      costumeFile = "xml_bin/club01-03_costume_U20_01.bin",
      costumeId = 522,
      instrument = "club01_act03-U20_A.bin",
      variants = {
        [0] = {
          name = "anime",
          displayName = "BATTLE_COSTUME_U20_2",
          costumeId = 523,
          animFile = "xml_bin/club01-03_monster_u20.bin",
          costumeFile = "xml_bin/club01-03_costume_U20_02.bin",
          instrument = "club01_act03-U20_B.bin",
          unlockId = 8
        }
      }
    },
    prop_stage_upper = {
      unlockId = 0,
      customizeIcon = "icon_deco_front_stage",
      customizeSheet = "clubbox_customization_menu_act02.xml",
      animFile = "xml_bin/club01-03_prop_stage_upper_punk.bin",
      instrument = "club01_act03-prop_stage_upper.bin",
      variants = {
        [0] = {
          name = "none",
          animFile = "xml_bin/club01-03_prop_stage_upper_punk.bin",
          unlockId = 0
        },
        [1] = {
          name = "anime",
          animFile = "xml_bin/club01-03_prop_stage_upper_mech.bin",
          unlockId = 12
        }
      }
    },
    prop_speaker09 = {
      unlockId = 19,
      customizeIcon = "icon_deco_front_stage",
      customizeSheet = "clubbox_customization_menu_act02.xml",
      animFile = "xml_bin/club01-03_prop_speaker09_punk.bin",
      instrument = "club01_act03-prop_speaker09.bin",
      variants = {
        [0] = {
          name = "none",
          animFile = "xml_bin/club01-02_prop_off.bin",
          unlockId = 19
        },
        [1] = {
          name = "anime",
          animFile = "xml_bin/club01-03_prop_speaker09_mech.bin",
          unlockId = 19
        }
      }
    },
    prop_speaker01 = {
      unlockId = 6,
      customizeIcon = "icon_deco_front_stage",
      customizeSheet = "clubbox_customization_menu_act02.xml",
      animFile = "xml_bin/club01-03_prop_speaker01_punk.bin",
      instrument = "club01_act03-prop_speaker01.bin",
      variants = {
        [0] = {
          name = "none",
          animFile = "xml_bin/club01-02_prop_off.bin",
          unlockId = 6
        },
        [1] = {
          name = "anime",
          animFile = "xml_bin/club01-03_prop_speaker01_mech.bin",
          unlockId = 12
        }
      }
    },
    prop_speaker02 = {
      unlockId = 6,
      customizeIcon = "icon_deco_front_stage",
      customizeSheet = "clubbox_customization_menu_act02.xml",
      animFile = "xml_bin/club01-03_prop_speaker02_punk.bin",
      instrument = "club01_act03-prop_speaker02.bin",
      variants = {
        [0] = {
          name = "none",
          animFile = "xml_bin/club01-02_prop_off.bin",
          unlockId = 6
        },
        [1] = {
          name = "anime",
          animFile = "xml_bin/club01-03_prop_speaker02_mech.bin",
          unlockId = 12
        }
      }
    },
    prop_critter = {
      unlockId = 14,
      customizeIcon = "icon_deco_front_stage",
      customizeSheet = "clubbox_customization_menu_act02.xml",
      animFile = "xml_bin/club01-03_prop_critter_punk.bin",
      variants = {
        [0] = {
          name = "none",
          animFile = "xml_bin/club01-02_prop_off.bin",
          unlockId = 14
        },
        [1] = {
          name = "anime",
          animFile = "xml_bin/club01-03_prop_critter_mech.bin",
          unlockId = 14
        }
      }
    },
    prop_backstage01 = {
      unlockId = 12,
      customizeIcon = "icon_deco_front_stage",
      customizeSheet = "clubbox_customization_menu_act02.xml",
      animFile = "xml_bin/club01-03_prop_backstage01_punk.bin",
      instrument = "club01_act03-prop_backstage01.bin",
      variants = {
        [0] = {
          name = "none",
          animFile = "xml_bin/club01-02_prop_off.bin",
          unlockId = 12
        },
        [1] = {
          name = "anime",
          animFile = "xml_bin/club01-03_prop_backstage01_mech.bin",
          unlockId = 12
        }
      }
    },
    prop_speaker07 = {
      unlockId = 17,
      customizeIcon = "icon_deco_front_stage",
      customizeSheet = "clubbox_customization_menu_act02.xml",
      animFile = "xml_bin/club01-03_prop_speaker07_punk.bin",
      instrument = "club01_act03-prop_speaker07.bin",
      variants = {
        [0] = {
          name = "none",
          animFile = "xml_bin/club01-02_prop_off.bin",
          unlockId = 17
        },
        [1] = {
          name = "anime",
          animFile = "xml_bin/club01-03_prop_speaker07_mech.bin",
          unlockId = 17
        }
      }
    },
    prop_speaker03 = {
      unlockId = 6,
      customizeIcon = "icon_deco_front_stage",
      customizeSheet = "clubbox_customization_menu_act02.xml",
      animFile = "xml_bin/club01-03_prop_speaker03_punk.bin",
      instrument = "club01_act03-prop_speaker03.bin",
      variants = {
        [0] = {
          name = "none",
          animFile = "xml_bin/club01-02_prop_off.bin",
          unlockId = 6
        },
        [1] = {
          name = "anime",
          animFile = "xml_bin/club01-03_prop_speaker03_mech.bin",
          unlockId = 12
        }
      }
    },
    prop_speaker05 = {
      unlockId = 17,
      customizeIcon = "icon_deco_front_stage",
      customizeSheet = "clubbox_customization_menu_act02.xml",
      animFile = "xml_bin/club01-03_prop_speaker05_punk.bin",
      instrument = "club01_act03-prop_speaker05.bin",
      variants = {
        [0] = {
          name = "none",
          animFile = "xml_bin/club01-02_prop_off.bin",
          unlockId = 17
        },
        [1] = {
          name = "anime",
          animFile = "xml_bin/club01-03_prop_speaker05_mech.bin",
          unlockId = 17
        }
      }
    },
    prop_speaker08 = {
      unlockId = 12,
      customizeIcon = "icon_deco_front_stage",
      customizeSheet = "clubbox_customization_menu_act02.xml",
      animFile = "xml_bin/club01-03_prop_speaker08_punk.bin",
      instrument = "club01_act03-prop_speaker08.bin",
      variants = {
        [0] = {
          name = "none",
          animFile = "xml_bin/club01-02_prop_off.bin",
          unlockId = 19
        },
        [1] = {
          name = "anime",
          animFile = "xml_bin/club01-03_prop_speaker08_mech.bin",
          unlockId = 19
        }
      }
    },
    prop_speaker10 = {
      unlockId = 17,
      customizeIcon = "icon_deco_front_stage",
      customizeSheet = "clubbox_customization_menu_act02.xml",
      animFile = "xml_bin/club01-03_prop_speaker10_punk.bin",
      instrument = "club01_act03-prop_speaker10.bin",
      variants = {
        [0] = {
          name = "none",
          animFile = "xml_bin/club01-02_prop_off.bin",
          unlockId = 17
        },
        [1] = {
          name = "anime",
          animFile = "xml_bin/club01-03_prop_speaker10_mech.bin",
          unlockId = 17
        }
      }
    },
    prop_speaker04 = {
      unlockId = 6,
      customizeIcon = "icon_deco_front_stage",
      customizeSheet = "clubbox_customization_menu_act02.xml",
      animFile = "xml_bin/club01-03_prop_speaker04_punk.bin",
      instrument = "club01_act03-prop_speaker04.bin",
      variants = {
        [0] = {
          name = "none",
          animFile = "xml_bin/club01-02_prop_off.bin",
          unlockId = 6
        },
        [1] = {
          name = "anime",
          animFile = "xml_bin/club01-03_prop_speaker04_mech.bin",
          unlockId = 12
        }
      }
    },
    prop_speaker06 = {
      unlockId = 17,
      customizeIcon = "icon_deco_front_stage",
      customizeSheet = "clubbox_customization_menu_act02.xml",
      animFile = "xml_bin/club01-03_prop_speaker06_punk.bin",
      instrument = "club01_act03-prop_speaker06.bin",
      variants = {
        [0] = {
          name = "none",
          animFile = "xml_bin/club01-02_prop_off.bin",
          unlockId = 17
        },
        [1] = {
          name = "anime",
          animFile = "xml_bin/club01-03_prop_speaker06_mech.bin",
          unlockId = 17
        }
      }
    },
    prop_backstage02 = {
      unlockId = 19,
      customizeIcon = "icon_deco_front_stage",
      customizeSheet = "clubbox_customization_menu_act02.xml",
      animFile = "xml_bin/club01-03_prop_backstage02_punk.bin",
      instrument = "club01_act03-prop_backstage02.bin",
      variants = {
        [0] = {
          name = "none",
          animFile = "xml_bin/club01-02_prop_off.bin",
          unlockId = 19
        },
        [1] = {
          name = "anime",
          animFile = "xml_bin/club01-03_prop_speaker06_mech.bin",
          unlockId = 19
        }
      }
    },
    prop_stage_marker01 = {
      unlockId = 3,
      customizeIcon = "icon_deco_front_stage",
      customizeSheet = "clubbox_customization_menu_act02.xml",
      animFile = "xml_bin/club01-03_prop_stage_marker01_punk.bin",
      variants = {
        [0] = {
          name = "none",
          animFile = "xml_bin/club01-03_prop_stage_marker01_punk.bin",
          unlockId = 3
        },
        [1] = {
          name = "anime",
          animFile = "xml_bin/club01-03_prop_stage_marker01_mech.bin",
          unlockId = 12
        }
      }
    },
    prop_stage_marker02 = {
      unlockId = 5,
      customizeIcon = "icon_deco_front_stage",
      customizeSheet = "clubbox_customization_menu_act02.xml",
      animFile = "xml_bin/club01-03_prop_stage_marker02_punk.bin",
      variants = {
        [0] = {
          name = "none",
          animFile = "xml_bin/club01-03_prop_stage_marker02_punk.bin",
          unlockId = 5
        },
        [1] = {
          name = "anime",
          animFile = "xml_bin/club01-03_prop_stage_marker02_mech.bin",
          unlockId = 12
        }
      }
    },
    prop_stage_marker03 = {
      unlockId = 1,
      customizeIcon = "icon_deco_front_stage",
      customizeSheet = "clubbox_customization_menu_act02.xml",
      animFile = "xml_bin/club01-03_prop_stage_marker03_punk.bin",
      variants = {
        [0] = {
          name = "none",
          animFile = "xml_bin/club01-03_prop_stage_marker03_punk.bin",
          unlockId = 1
        },
        [1] = {
          name = "anime",
          animFile = "xml_bin/club01-03_prop_stage_marker03_mech.bin",
          unlockId = 12
        }
      }
    },
    prop_stage_main = {
      unlockId = 0,
      customizeIcon = "icon_deco_front_stage",
      customizeSheet = "clubbox_customization_menu_act02.xml",
      animFile = "xml_bin/club01-03_prop_stage_main_punk.bin",
      instrument = "club01_act03-prop_stage_main.bin",
      variants = {
        [0] = {
          name = "none",
          animFile = "xml_bin/club01-03_prop_stage_main_punk.bin",
          unlockId = 0
        },
        [1] = {
          name = "anime",
          animFile = "xml_bin/club01-03_prop_stage_main_mech.bin",
          unlockId = 12
        }
      }
    },
    prop_fence = {
      unlockId = 6,
      customizeIcon = "icon_deco_front_stage",
      customizeSheet = "clubbox_customization_menu_act02.xml",
      animFile = "xml_bin/club01-03_prop_fence_punk.bin",
      instrument = "club01_act03-prop_fence.bin",
      variants = {
        [0] = {
          name = "none",
          animFile = "xml_bin/club01-02_prop_off.bin",
          unlockId = 6
        },
        [1] = {
          name = "anime",
          animFile = "xml_bin/club01-03_prop_fence_mech.bin",
          unlockId = 12
        }
      }
    },
    prop_balloon_1R = {
      unlockId = 4,
      customizeIcon = "icon_deco_back_stage",
      customizeSheet = "clubbox_customization_menu_act02.xml",
      animFile = "xml_bin/club01-03_prop_balloon01_punk.bin",
      instrument = "club01_act03-prop_balloon_1R.bin",
      variants = {
        [0] = {
          name = "none",
          animFile = "xml_bin/club01-02_prop_off.bin",
          unlockId = 4
        },
        [1] = {
          name = "anime",
          animFile = "xml_bin/club01-03_prop_balloon01_mech.bin",
          unlockId = 20
        }
      }
    },
    prop_balloon_2R = {
      unlockId = 20,
      customizeIcon = "icon_deco_back_stage",
      customizeSheet = "clubbox_customization_menu_act02.xml",
      animFile = "xml_bin/club01-03_prop_balloon02_punk.bin",
      instrument = "club01_act03-prop_balloon_2R.bin",
      variants = {
        [0] = {
          name = "none",
          animFile = "xml_bin/club01-02_prop_off.bin",
          unlockId = 20
        },
        [1] = {
          name = "anime",
          animFile = "xml_bin/club01-03_prop_balloon02_mech.bin",
          unlockId = 20
        }
      }
    },
    prop_balloon_1L = {
      unlockId = 4,
      customizeIcon = "icon_deco_back_stage",
      customizeSheet = "clubbox_customization_menu_act02.xml",
      animFile = "xml_bin/club01-03_prop_balloon01_punk.bin",
      instrument = "club01_act03-prop_balloon_1L.bin",
      variants = {
        [0] = {
          name = "none",
          animFile = "xml_bin/club01-02_prop_off.bin",
          unlockId = 4
        },
        [1] = {
          name = "anime",
          animFile = "xml_bin/club01-03_prop_balloon01_mech.bin",
          unlockId = 20
        }
      }
    },
    prop_balloon_2L = {
      unlockId = 20,
      customizeIcon = "icon_deco_back_stage",
      customizeSheet = "clubbox_customization_menu_act02.xml",
      animFile = "xml_bin/club01-03_prop_balloon02_punk.bin",
      instrument = "club01_act03-prop_balloon_2L.bin",
      variants = {
        [0] = {
          name = "none",
          animFile = "xml_bin/club01-02_prop_off.bin",
          unlockId = 20
        },
        [1] = {
          name = "anime",
          animFile = "xml_bin/club01-03_prop_balloon02_mech.bin",
          unlockId = 20
        }
      }
    },
    prop_screen_open = {
      unlockId = 21,
      animFile = "xml_bin/club01-03_prop_screen_open.bin",
      instrument = "club01_act03-prop_screen_open.bin"
    },
    prop_screen_closed = {
      unlockId = 0,
      maxUnlockId = 21,
      animFile = "xml_bin/club01-03_prop_screen_closed.bin"
    },
    prop_wubbox_arm_R = {
      unlockId = 18,
      animFile = "xml_bin/club01-03_prop_wubboxarm.bin",
      instrument = "club01_act03-prop_wubbox_arm_R.bin"
    },
    prop_wubbox_arm_L = {
      unlockId = 16,
      animFile = "xml_bin/club01-03_prop_wubboxarm.bin",
      instrument = "club01_act03-prop_wubbox_arm_L.bin"
    },
    prop_lightsR = {
      unlockId = 21,
      customizeIcon = "icon_deco_back_stage",
      customizeSheet = "clubbox_customization_menu_act02.xml",
      animFile = "xml_bin/club01-03_prop_lights_punk.bin",
      instrument = "club01_act03-prop_lightsR.bin",
      variants = {
        [0] = {
          name = "none",
          animFile = "xml_bin/club01-02_prop_off.bin",
          unlockId = 21
        },
        [1] = {
          name = "anime",
          animFile = "xml_bin/club01-03_prop_lights_mech.bin",
          unlockId = 21
        }
      }
    },
    prop_lightsL = {
      unlockId = 21,
      customizeIcon = "icon_deco_back_stage",
      customizeSheet = "clubbox_customization_menu_act02.xml",
      animFile = "xml_bin/club01-03_prop_lights_punk.bin",
      instrument = "club01_act03-prop_lightsL.bin",
      variants = {
        [0] = {
          name = "none",
          animFile = "xml_bin/club01-02_prop_off.bin",
          unlockId = 21
        },
        [1] = {
          name = "anime",
          animFile = "xml_bin/club01-03_prop_lights_mech.bin",
          unlockId = 21
        }
      }
    },
    prop_smokeR = {
      unlockId = 21,
      customizeIcon = "icon_deco_back_stage",
      customizeSheet = "clubbox_customization_menu_act02.xml",
      animFile = "xml_bin/club01-03_prop_smoke_punk.bin",
      instrument = "club01_act03-prop_smokeR.bin",
      variants = {
        [0] = {
          name = "none",
          animFile = "xml_bin/club01-03_prop_smoke_punk.bin",
          unlockId = 21
        },
        [1] = {
          name = "anime",
          animFile = "xml_bin/club01-03_prop_smoke_mech.bin",
          unlockId = 21
        }
      }
    },
    prop_smokeL = {
      unlockId = 21,
      customizeIcon = "icon_deco_back_stage",
      customizeSheet = "clubbox_customization_menu_act02.xml",
      animFile = "xml_bin/club01-03_prop_smoke_punk.bin",
      instrument = "club01_act03-prop_smokeL.bin",
      variants = {
        [0] = {
          name = "none",
          animFile = "xml_bin/club01-03_prop_smoke_punk.bin",
          unlockId = 21
        },
        [1] = {
          name = "anime",
          animFile = "xml_bin/club01-03_prop_smoke_mech.bin",
          unlockId = 21
        }
      }
    },
    prop_backwall_glow_R = {
      animFile = "xml_bin/club01-03_prop_backwall_glow.bin",
      instrument = "club01_act03-prop_backwall_glow_R.bin"
    },
    prop_backwall_glow_L = {
      animFile = "xml_bin/club01-03_prop_backwall_glow.bin",
      instrument = "club01_act03-prop_backwall_glow_L.bin"
    },
    prop_backwall_R = {
      unlockId = 18,
      customizeIcon = "icon_deco_back_stage",
      customizeSheet = "clubbox_customization_menu_act02.xml",
      animFile = "xml_bin/club01-03_prop_backwall_punk.bin",
      instrument = "club01_act03-prop_backwall_R.bin",
      variants = {
        [0] = {
          name = "none",
          animFile = "xml_bin/club01-03_prop_backwall_punk.bin",
          unlockId = 18
        },
        [1] = {
          name = "anime",
          animFile = "xml_bin/club01-03_prop_backwall_mech.bin",
          unlockId = 18
        }
      }
    },
    prop_backwall_L = {
      unlockId = 16,
      customizeIcon = "icon_deco_back_stage",
      customizeSheet = "clubbox_customization_menu_act02.xml",
      animFile = "xml_bin/club01-03_prop_backwall_punk.bin",
      instrument = "club01_act03-prop_backwall_L.bin",
      variants = {
        [0] = {
          name = "none",
          animFile = "xml_bin/club01-03_prop_backwall_punk.bin",
          unlockId = 16
        },
        [1] = {
          name = "anime",
          animFile = "xml_bin/club01-03_prop_backwall_mech.bin",
          unlockId = 16
        }
      }
    },
    prop_particle = {
      unlockId = 10,
      customizeIcon = "icon_deco_front_crowd",
      customizeSheet = "clubbox_customization_menu_act02.xml",
      propType = game.ClubboxPropData_PROP_PARTICLE,
      animFile = "particles/Clubbox/Act3/FX_CrowdEffects.efkefc",
      variants = {
        [0] = {
          name = "none",
          animFile = "particles/Clubbox/FX_Blank.efkefc",
          unlockId = 10
        },
        [1] = {
          name = "anime",
          animFile = "particles/Clubbox/Act3/FX_CrowdEffects2.efkefc",
          unlockId = 15
        }
      }
    }
  }
}
return ClubboxAct2
