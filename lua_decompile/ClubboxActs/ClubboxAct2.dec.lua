local ClubboxFunctions = include("ClubboxFunctions")
local ClubboxAct2 = {
  props = {
    prop_crowd01 = {
      animFile = "xml_bin/club01-02_prop_crowd01.bin",
      instrument = "club01_act02-prop_crowd01.bin"
    },
    prop_critter = {
      unlockId = 14,
      animFile = "xml_bin/club01-02_prop_critter.bin"
    },
    prop_crowd02 = {
      animFile = "xml_bin/club01-02_prop_crowd02.bin",
      instrument = "club01_act02-prop_crowd02.bin"
    },
    prop_dj = {
      animFile = "xml_bin/club01-02_prop_dj.bin",
      instrument = "club01_act02-Backing_A.bin",
      isMonster = 52,
      customizeIcon = "button_djepic",
      customizeSheet = "clubbox_customization_menu.xml",
      instruments = {
        [2] = "club01_act02-Backing_B.bin",
        [4] = "club01_act02-Backing_C.bin",
        [6] = "club01_act02-Backing_D.bin",
        [8] = "club01_act02-Backing_E.bin"
      },
      onPick = ClubboxFunctions.OnPickDJ
    },
    prop_crowd03 = {
      animFile = "xml_bin/club01-02_prop_crowd03.bin",
      instrument = "club01_act02-prop_crowd03.bin"
    },
    prop_crowd04 = {
      animFile = "xml_bin/club01-02_prop_crowd04.bin",
      instrument = "club01_act02-prop_crowd04.bin"
    },
    prop_crowd05 = {
      animFile = "xml_bin/club01-02_prop_crowd05.bin",
      instrument = "club01_act02-prop_crowd05.bin"
    },
    prop_monster_ACE = {
      displayName = "BATTLE_COSTUME_ACE_12",
      isMonster = 19,
      customizeIcon = "button_pompom",
      customizeSheet = "clubbox_customization_menu_act02.xml",
      animFile = "xml_bin/club01-02_monster_ace.bin",
      costumeFile = "xml_bin/club01-02_costume_ACE_12.bin",
      costumeId = 501,
      instrument = "club01_act02-ACE_A.bin",
      variants = {
        [0] = {
          name = "flower",
          displayName = "BATTLE_COSTUME_ACE_13",
          costumeId = 502,
          animFile = "xml_bin/club01-02_monster_ace.bin",
          costumeFile = "xml_bin/club01-02_costume_ACE_13.bin",
          instrument = "club01_act02-ACE_B.bin",
          unlockId = 17
        },
        [1] = {
          name = "bubble",
          displayName = "BATTLE_COSTUME_ACE_14",
          costumeId = 503,
          animFile = "xml_bin/club01-02_monster_ace.bin",
          costumeFile = "xml_bin/club01-02_costume_ACE_14.bin",
          instrument = "club01_act02-ACE_C.bin",
          unlockId = 19
        }
      }
    },
    prop_monster_S05 = {
      unlockId = 1,
      displayName = "BATTLE_COSTUME_S05_2",
      isMonster = 52,
      customizeIcon = "button_hoola",
      customizeSheet = "clubbox_customization_menu_act02.xml",
      animFile = "xml_bin/club01-02_monster_s05.bin",
      costumeFile = "xml_bin/club01-02_costume_S05_02.bin",
      costumeId = 504,
      instrument = "club01_act02-S05_A.bin",
      variants = {
        [0] = {
          name = "flower",
          displayName = "BATTLE_COSTUME_S05_3",
          costumeId = 505,
          animFile = "xml_bin/club01-02_monster_s05.bin",
          costumeFile = "xml_bin/club01-02_costume_S05_03.bin",
          instrument = "club01_act02-S05_B.bin",
          unlockId = 15
        },
        [1] = {
          name = "bubble",
          displayName = "BATTLE_COSTUME_S05_4",
          costumeId = 506,
          animFile = "xml_bin/club01-02_monster_s05.bin",
          costumeFile = "xml_bin/club01-02_costume_S05_04.bin",
          instrument = "club01_act02-S05_C.bin",
          unlockId = 21
        }
      }
    },
    prop_monster_BEN = {
      unlockId = 3,
      displayName = "BATTLE_COSTUME_BEN_2",
      isMonster = 469,
      customizeIcon = "button_sooza",
      customizeSheet = "clubbox_customization_menu_act02.xml",
      animFile = "xml_bin/club01-02_monster_ben.bin",
      costumeFile = "xml_bin/club01-02_costume_BEN_02.bin",
      costumeId = 507,
      instrument = "club01_act02-BEN_A.bin",
      variants = {
        [0] = {
          name = "flower",
          displayName = "BATTLE_COSTUME_BEN_3",
          costumeId = 508,
          animFile = "xml_bin/club01-02_monster_ben.bin",
          costumeFile = "xml_bin/club01-02_costume_BEN_03.bin",
          instrument = "club01_act02-BEN_B.bin",
          unlockId = 13
        },
        [1] = {
          name = "bubble",
          displayName = "BATTLE_COSTUME_BEN_4",
          costumeId = 509,
          animFile = "xml_bin/club01-02_monster_ben.bin",
          costumeFile = "xml_bin/club01-02_costume_BEN_04.bin",
          instrument = "club01_act02-BEN_C.bin",
          unlockId = 23
        }
      }
    },
    prop_monster_BNW = {
      unlockId = 7,
      displayName = "BATTLE_COSTUME_BNW_2",
      isMonster = 475,
      customizeIcon = "button_tootoo",
      customizeSheet = "clubbox_customization_menu_act02.xml",
      animFile = "xml_bin/club01-02_monster_bnw.bin",
      costumeFile = "xml_bin/club01-02_costume_BNW_02.bin",
      costumeId = 513,
      instrument = "club01_act02-BNW_A.bin",
      variants = {
        [0] = {
          name = "flower",
          displayName = "BATTLE_COSTUME_BNW_3",
          costumeId = 514,
          animFile = "xml_bin/club01-02_monster_bnw.bin",
          costumeFile = "xml_bin/club01-02_costume_BNW_03.bin",
          instrument = "club01_act02-BNW_B.bin",
          unlockId = 9
        },
        [1] = {
          name = "bubble",
          displayName = "BATTLE_COSTUME_BNW_4",
          costumeId = 515,
          animFile = "xml_bin/club01-02_monster_bnw.bin",
          costumeFile = "xml_bin/club01-02_costume_BNW_04.bin",
          instrument = "club01_act02-BNW_C.bin",
          unlockId = 27
        }
      }
    },
    prop_monster_BNR = {
      unlockId = 5,
      displayName = "BATTLE_COSTUME_BNR_1",
      isMonster = 409,
      customizeIcon = "button_rooba",
      customizeSheet = "clubbox_customization_menu_act02.xml",
      animFile = "xml_bin/club01-02_monster_bnr.bin",
      costumeFile = "xml_bin/club01-02_costume_BNR_01.bin",
      costumeId = 510,
      instrument = "club01_act02-BNR_A.bin",
      variants = {
        [0] = {
          name = "flower",
          displayName = "BATTLE_COSTUME_BNR_2",
          costumeId = 511,
          animFile = "xml_bin/club01-02_monster_bnr.bin",
          costumeFile = "xml_bin/club01-02_costume_BNR_02.bin",
          instrument = "club01_act02-BNR_B.bin",
          unlockId = 11
        },
        [1] = {
          name = "bubble",
          displayName = "BATTLE_COSTUME_BNR_3",
          costumeId = 512,
          animFile = "xml_bin/club01-02_monster_bnr.bin",
          costumeFile = "xml_bin/club01-02_costume_BNR_03.bin",
          instrument = "club01_act02-BNR_C.bin",
          unlockId = 25
        }
      }
    },
    prop_star_large = {
      unlockId = 22,
      animFile = "xml_bin/club01-02_prop_star_large_kpop.bin",
      customizeIcon = "icon_deco_front_stage",
      customizeSheet = "clubbox_customization_menu_act02.xml",
      instrument = "club01_act02-prop_star_large.bin",
      variants = {
        [0] = {
          name = "none",
          animFile = "xml_bin/club01-02_prop_off.bin",
          unlockId = 22
        },
        [1] = {
          name = "flower",
          animFile = "xml_bin/club01-02_prop_star_large_flower.bin",
          unlockId = 22
        },
        [2] = {
          name = "bubble",
          animFile = "xml_bin/club01-02_prop_star_large_candy.bin",
          unlockId = 22
        }
      }
    },
    prop_stage_upper = {
      animFile = "xml_bin/club01-02_prop_stage_upper_kpop.bin",
      customizeIcon = "icon_deco_front_stage",
      customizeSheet = "clubbox_customization_menu_act02.xml",
      variants = {
        [0] = {
          name = "none",
          animFile = "xml_bin/club01-02_prop_stage_upper_kpop.bin"
        },
        [1] = {
          name = "flower",
          animFile = "xml_bin/club01-02_prop_stage_upper_flower.bin",
          unlockId = 12
        },
        [2] = {
          name = "bubble",
          animFile = "xml_bin/club01-02_prop_stage_upper_candy.bin",
          unlockId = 22
        }
      }
    },
    prop_balloons01 = {
      unlockId = 22,
      animFile = "xml_bin/club01-02_prop_balloons01_kpop.bin",
      customizeIcon = "icon_deco_front_stage",
      customizeSheet = "clubbox_customization_menu_act02.xml",
      instrument = "club01_act02-prop_balloons01.bin",
      variants = {
        [0] = {
          name = "none",
          animFile = "xml_bin/club01-02_prop_off.bin",
          unlockId = 22
        },
        [1] = {
          name = "flower",
          animFile = "xml_bin/club01-02_prop_balloons01_flower.bin",
          unlockId = 22
        },
        [2] = {
          name = "bubble",
          animFile = "xml_bin/club01-02_prop_balloons01_candy.bin",
          unlockId = 22
        }
      }
    },
    prop_star_L = {
      unlockId = 12,
      animFile = "xml_bin/club01-02_prop_star_kpop.bin",
      customizeIcon = "icon_deco_front_stage",
      customizeSheet = "clubbox_customization_menu_act02.xml",
      instrument = "club01_act02-prop_star_L.bin",
      variants = {
        [0] = {
          name = "none",
          animFile = "xml_bin/club01-02_prop_off.bin",
          unlockId = 12
        },
        [1] = {
          name = "flower",
          animFile = "xml_bin/club01-02_prop_star_flower.bin",
          unlockId = 12
        },
        [2] = {
          name = "bubble",
          animFile = "xml_bin/club01-02_prop_star_candy.bin",
          unlockId = 22
        }
      }
    },
    prop_balloons02 = {
      unlockId = 12,
      animFile = "xml_bin/club01-02_prop_balloons02_kpop.bin",
      customizeIcon = "icon_deco_front_stage",
      customizeSheet = "clubbox_customization_menu_act02.xml",
      instrument = "club01_act02-prop_balloons02.bin",
      variants = {
        [0] = {
          name = "none",
          animFile = "xml_bin/club01-02_prop_off.bin",
          unlockId = 12
        },
        [1] = {
          name = "flower",
          animFile = "xml_bin/club01-02_prop_balloons02_flower.bin",
          unlockId = 12
        },
        [2] = {
          name = "bubble",
          animFile = "xml_bin/club01-02_prop_balloons02_candy.bin",
          unlockId = 22
        }
      }
    },
    prop_balloons03 = {
      unlockId = 22,
      animFile = "xml_bin/club01-02_prop_balloons03_kpop.bin",
      customizeIcon = "icon_deco_front_stage",
      customizeSheet = "clubbox_customization_menu_act02.xml",
      instrument = "club01_act02-prop_balloons03.bin",
      variants = {
        [0] = {
          name = "none",
          animFile = "xml_bin/club01-02_prop_off.bin",
          unlockId = 22
        },
        [1] = {
          name = "flower",
          animFile = "xml_bin/club01-02_prop_balloons03_flower.bin",
          unlockId = 22
        },
        [2] = {
          name = "bubble",
          animFile = "xml_bin/club01-02_prop_balloons03_candy.bin",
          unlockId = 22
        }
      }
    },
    prop_balloons04 = {
      unlockId = 22,
      animFile = "xml_bin/club01-02_prop_balloons04_kpop.bin",
      customizeIcon = "icon_deco_front_stage",
      customizeSheet = "clubbox_customization_menu_act02.xml",
      instrument = "club01_act02-prop_balloons04.bin",
      variants = {
        [0] = {
          name = "none",
          animFile = "xml_bin/club01-02_prop_off.bin",
          unlockId = 22
        },
        [1] = {
          name = "flower",
          animFile = "xml_bin/club01-02_prop_balloons04_flower.bin",
          unlockId = 22
        },
        [2] = {
          name = "bubble",
          animFile = "xml_bin/club01-02_prop_balloons04_candy.bin",
          unlockId = 22
        }
      }
    },
    prop_star_R = {
      unlockId = 12,
      animFile = "xml_bin/club01-02_prop_star_kpop.bin",
      customizeIcon = "icon_deco_front_stage",
      customizeSheet = "clubbox_customization_menu_act02.xml",
      instrument = "club01_act02-prop_star_R.bin",
      variants = {
        [0] = {
          name = "none",
          animFile = "xml_bin/club01-02_prop_off.bin",
          unlockId = 12
        },
        [1] = {
          name = "flower",
          animFile = "xml_bin/club01-02_prop_star_flower.bin",
          unlockId = 12
        },
        [2] = {
          name = "bubble",
          animFile = "xml_bin/club01-02_prop_star_candy.bin",
          unlockId = 24
        }
      }
    },
    prop_balloons05 = {
      unlockId = 12,
      animFile = "xml_bin/club01-02_prop_balloons05_kpop.bin",
      customizeIcon = "icon_deco_front_stage",
      customizeSheet = "clubbox_customization_menu_act02.xml",
      instrument = "club01_act02-prop_balloons05.bin",
      variants = {
        [0] = {
          name = "none",
          animFile = "xml_bin/club01-02_prop_off.bin",
          unlockId = 12
        },
        [1] = {
          name = "flower",
          animFile = "xml_bin/club01-02_prop_balloons05_flower.bin",
          unlockId = 12
        },
        [2] = {
          name = "bubble",
          animFile = "xml_bin/club01-02_prop_balloons05_candy.bin",
          unlockId = 22
        }
      }
    },
    prop_balloons06 = {
      unlockId = 22,
      animFile = "xml_bin/club01-02_prop_balloons06_kpop.bin",
      customizeIcon = "icon_deco_front_stage",
      customizeSheet = "clubbox_customization_menu_act02.xml",
      instrument = "club01_act02-prop_balloons06.bin",
      variants = {
        [0] = {
          name = "none",
          animFile = "xml_bin/club01-02_prop_off.bin",
          unlockId = 22
        },
        [1] = {
          name = "flower",
          animFile = "xml_bin/club01-02_prop_balloons06_flower.bin",
          unlockId = 22
        },
        [2] = {
          name = "bubble",
          animFile = "xml_bin/club01-02_prop_balloons06_candy.bin",
          unlockId = 22
        }
      }
    },
    prop_balloons07 = {
      unlockId = 2,
      animFile = "xml_bin/club01-02_prop_balloons07_kpop.bin",
      customizeIcon = "icon_deco_front_stage",
      customizeSheet = "clubbox_customization_menu_act02.xml",
      instrument = "club01_act02-prop_balloons07.bin",
      variants = {
        [0] = {
          name = "none",
          animFile = "xml_bin/club01-02_prop_off.bin",
          unlockId = 2
        },
        [1] = {
          name = "flower",
          animFile = "xml_bin/club01-02_prop_balloons07_flower.bin",
          unlockId = 12
        },
        [2] = {
          name = "bubble",
          animFile = "xml_bin/club01-02_prop_balloons07_candy.bin",
          unlockId = 22
        }
      }
    },
    prop_glitter = {
      unlockId = 4,
      animFile = "xml_bin/club01-02_prop_glitter_kpop.bin",
      customizeIcon = "icon_deco_front_stage",
      customizeSheet = "clubbox_customization_menu_act02.xml",
      variants = {
        [0] = {
          name = "none",
          animFile = "xml_bin/club01-02_prop_off.bin",
          unlockId = 4
        },
        [1] = {
          name = "flower",
          animFile = "xml_bin/club01-02_prop_glitter_flower.bin",
          unlockId = 12
        },
        [2] = {
          name = "bubble",
          animFile = "xml_bin/club01-02_prop_glitter_candy.bin",
          unlockId = 22
        }
      }
    },
    prop_stage = {
      animFile = "xml_bin/club01-02_prop_stage_main_kpop.bin",
      customizeIcon = "icon_deco_front_stage",
      customizeSheet = "clubbox_customization_menu_act02.xml",
      instrument = "club01_act02-prop_stage.bin",
      variants = {
        [0] = {
          name = "none",
          animFile = "xml_bin/club01-02_prop_stage_main_kpop.bin"
        },
        [1] = {
          name = "flower",
          animFile = "xml_bin/club01-02_prop_stage_main_flower.bin",
          unlockId = 12
        },
        [2] = {
          name = "bubble",
          animFile = "xml_bin/club01-02_prop_stage_main_candy.bin",
          unlockId = 22
        }
      }
    },
    prop_star_back_large_R = {
      unlockId = 24,
      animFile = "xml_bin/club01-02_prop_star_back_large_kpop.bin",
      customizeIcon = "icon_deco_back_stage",
      customizeSheet = "clubbox_customization_menu_act02.xml",
      instrument = "club01_act02-prop_star_back_large_R.bin",
      variants = {
        [0] = {
          name = "none",
          animFile = "xml_bin/club01-02_prop_off.bin",
          unlockId = 24
        },
        [1] = {
          name = "flower",
          animFile = "xml_bin/club01-02_prop_star_back_large_flower.bin",
          unlockId = 24
        },
        [2] = {
          name = "bubble",
          animFile = "xml_bin/club01-02_prop_star_back_large_candy.bin",
          unlockId = 24
        }
      }
    },
    prop_star_back_small_R = {
      unlockId = 10,
      animFile = "xml_bin/club01-02_prop_star_back_small_kpop.bin",
      customizeIcon = "icon_deco_back_stage",
      customizeSheet = "clubbox_customization_menu_act02.xml",
      instrument = "club01_act02-prop_star_back_small_R.bin",
      variants = {
        [0] = {
          name = "none",
          animFile = "xml_bin/club01-02_prop_off.bin",
          unlockId = 10
        },
        [1] = {
          name = "flower",
          animFile = "xml_bin/club01-02_prop_star_back_small_flower.bin",
          unlockId = 10
        },
        [2] = {
          name = "bubble",
          animFile = "xml_bin/club01-02_prop_star_back_small_candy.bin",
          unlockId = 24
        }
      }
    },
    prop_drops01_R = {
      unlockId = 4,
      animFile = "xml_bin/club01-02_prop_drops01_kpop.bin",
      customizeIcon = "icon_deco_back_stage",
      customizeSheet = "clubbox_customization_menu_act02.xml",
      instrument = "club01_act02-prop_drops01_R.bin",
      variants = {
        [0] = {
          name = "none",
          animFile = "xml_bin/club01-02_prop_off.bin",
          unlockId = 4
        },
        [1] = {
          name = "flower",
          animFile = "xml_bin/club01-02_prop_drops01_flower.bin",
          unlockId = 10
        },
        [2] = {
          name = "bubble",
          animFile = "xml_bin/club01-02_prop_drops01_candy.bin",
          unlockId = 24
        }
      }
    },
    prop_drops02_R = {
      unlockId = 4,
      animFile = "xml_bin/club01-02_prop_drops02_kpop.bin",
      customizeIcon = "icon_deco_back_stage",
      customizeSheet = "clubbox_customization_menu_act02.xml",
      instrument = "club01_act02-prop_drops02_R.bin",
      variants = {
        [0] = {
          name = "none",
          animFile = "xml_bin/club01-02_prop_off.bin",
          unlockId = 4
        },
        [1] = {
          name = "flower",
          animFile = "xml_bin/club01-02_prop_drops02_flower.bin",
          unlockId = 10
        },
        [2] = {
          name = "bubble",
          animFile = "xml_bin/club01-02_prop_drops02_candy.bin",
          unlockId = 24
        }
      }
    },
    prop_stage_back_R = {
      animFile = "xml_bin/club01-02_prop_stage_back_kpop.bin",
      customizeIcon = "icon_deco_back_stage",
      customizeSheet = "clubbox_customization_menu_act02.xml",
      variants = {
        [0] = {
          name = "none",
          animFile = "xml_bin/club01-02_prop_stage_back_kpop.bin"
        },
        [1] = {
          name = "flower",
          animFile = "xml_bin/club01-02_prop_stage_back_flower.bin",
          unlockId = 10
        },
        [2] = {
          name = "bubble",
          animFile = "xml_bin/club01-02_prop_stage_back_candy.bin",
          unlockId = 24
        }
      }
    },
    prop_star_back_small_L = {
      unlockId = 10,
      animFile = "xml_bin/club01-02_prop_star_back_small_kpop.bin",
      customizeIcon = "icon_deco_back_stage",
      customizeSheet = "clubbox_customization_menu_act02.xml",
      instrument = "club01_act02-prop_star_back_small_L.bin",
      variants = {
        [0] = {
          name = "none",
          animFile = "xml_bin/club01-02_prop_off.bin",
          unlockId = 10
        },
        [1] = {
          name = "flower",
          animFile = "xml_bin/club01-02_prop_star_back_small_flower.bin",
          unlockId = 10
        },
        [2] = {
          name = "bubble",
          animFile = "xml_bin/club01-02_prop_star_back_small_candy.bin",
          unlockId = 24
        }
      }
    },
    prop_star_back_large_L = {
      unlockId = 24,
      animFile = "xml_bin/club01-02_prop_star_back_large_kpop.bin",
      customizeIcon = "icon_deco_back_stage",
      customizeSheet = "clubbox_customization_menu_act02.xml",
      instrument = "club01_act02-prop_star_back_large_L.bin",
      variants = {
        [0] = {
          name = "none",
          animFile = "xml_bin/club01-02_prop_off.bin",
          unlockId = 24
        },
        [1] = {
          name = "flower",
          animFile = "xml_bin/club01-02_prop_star_back_large_flower.bin",
          unlockId = 24
        },
        [2] = {
          name = "bubble",
          animFile = "xml_bin/club01-02_prop_star_back_large_candy.bin",
          unlockId = 24
        }
      }
    },
    prop_drops01_L = {
      unlockId = 4,
      animFile = "xml_bin/club01-02_prop_drops01_kpop.bin",
      customizeIcon = "icon_deco_back_stage",
      customizeSheet = "clubbox_customization_menu_act02.xml",
      instrument = "club01_act02-prop_drops01_L.bin",
      variants = {
        [0] = {
          name = "none",
          animFile = "xml_bin/club01-02_prop_off.bin",
          unlockId = 4
        },
        [1] = {
          name = "flower",
          animFile = "xml_bin/club01-02_prop_drops01_flower.bin",
          unlockId = 10
        },
        [2] = {
          name = "bubble",
          animFile = "xml_bin/club01-02_prop_drops01_candy.bin",
          unlockId = 24
        }
      }
    },
    prop_drops02_L = {
      unlockId = 4,
      animFile = "xml_bin/club01-02_prop_drops02_kpop.bin",
      customizeIcon = "icon_deco_back_stage",
      customizeSheet = "clubbox_customization_menu_act02.xml",
      instrument = "club01_act02-prop_drops02_L.bin",
      variants = {
        [0] = {
          name = "none",
          animFile = "xml_bin/club01-02_prop_off.bin",
          unlockId = 4
        },
        [1] = {
          name = "flower",
          animFile = "xml_bin/club01-02_prop_drops02_flower.bin",
          unlockId = 10
        },
        [2] = {
          name = "bubble",
          animFile = "xml_bin/club01-02_prop_drops02_candy.bin",
          unlockId = 24
        }
      }
    },
    prop_stage_back_L = {
      animFile = "xml_bin/club01-02_prop_stage_back_kpop.bin",
      customizeIcon = "icon_deco_back_stage",
      customizeSheet = "clubbox_customization_menu_act02.xml",
      variants = {
        [0] = {
          name = "none",
          animFile = "xml_bin/club01-02_prop_stage_back_kpop.bin"
        },
        [1] = {
          name = "flower",
          animFile = "xml_bin/club01-02_prop_stage_back_flower.bin",
          unlockId = 10
        },
        [2] = {
          name = "bubble",
          animFile = "xml_bin/club01-02_prop_stage_back_candy.bin",
          unlockId = 24
        }
      }
    },
    prop_wubbox_arm_R = {
      unlockId = 26,
      animFile = "xml_bin/club01-02_prop_wubbox_arm.bin",
      instrument = "club01_act02-prop_wubbox_arm_R.bin"
    },
    prop_wubbox_arm_L = {
      unlockId = 18,
      animFile = "xml_bin/club01-02_prop_wubbox_arm.bin",
      instrument = "club01_act02-prop_wubbox_arm_L.bin"
    },
    prop_screen_closed = {
      maxUnlockId = 28,
      animFile = "xml_bin/club01-02_prop_screen_closed_kpop.bin",
      customizeIcon = "icon_deco_back_stage",
      customizeSheet = "clubbox_customization_menu_act02.xml",
      instrument = "club01_act02-prop_screen.bin",
      variants = {
        [0] = {
          name = "none",
          animFile = "xml_bin/club01-02_prop_off.bin"
        },
        [1] = {
          name = "flower",
          animFile = "xml_bin/club01-02_prop_screen_closed_flower.bin",
          unlockId = 10
        },
        [2] = {
          name = "bubble",
          animFile = "xml_bin/club01-02_prop_screen_closed_candy.bin",
          unlockId = 24
        }
      }
    },
    prop_screen_open = {
      unlockId = 28,
      animFile = "xml_bin/club01-02_prop_screen_open_kpop.bin",
      customizeIcon = "icon_deco_back_stage",
      customizeSheet = "clubbox_customization_menu_act02.xml",
      instrument = "club01_act02-prop_screen.bin",
      variants = {
        [0] = {
          name = "none",
          animFile = "xml_bin/club01-02_prop_off.bin",
          unlockId = 28
        },
        [1] = {
          name = "flower",
          animFile = "xml_bin/club01-02_prop_screen_open_flower.bin",
          unlockId = 28
        },
        [2] = {
          name = "bubble",
          animFile = "xml_bin/club01-02_prop_screen_open_candy.bin",
          unlockId = 28
        }
      }
    },
    prop_backwall_glow_R = {
      unlockId = 26,
      animFile = "xml_bin/club01-02_prop_backwall_glow.bin",
      instrument = "club01_act02-prop_backwall_glow_R.bin"
    },
    prop_backwall_glow_L = {
      unlockId = 18,
      animFile = "xml_bin/club01-02_prop_backwall_glow.bin",
      instrument = "club01_act02-prop_backwall_glow_L.bin"
    },
    prop_particle = {
      unlockId = 6,
      customizeIcon = "icon_deco_front_crowd",
      customizeSheet = "clubbox_customization_menu_act02.xml",
      propType = game.ClubboxPropData_PROP_PARTICLE,
      animFile = "particles/Clubbox/Act2/Promily_Confetti.efkefc",
      variants = {
        [0] = {
          name = "none",
          animFile = "particles/Clubbox/FX_Blank.efkefc",
          unlockId = 6
        },
        [1] = {
          name = "flower",
          animFile = "particles/Clubbox/Act2/Promily_HippieFX.efkefc",
          unlockId = 16
        },
        [2] = {
          name = "bubble",
          animFile = "particles/Clubbox/Act2/Promily_BubbleGum.efkefc",
          unlockId = 20
        }
      }
    }
  }
}
return ClubboxAct2
