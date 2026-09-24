local DefaultEyeStateAnims = {
  CLOSED = "closed",
  CLOSING = "closing",
  OPENING = "opening",
  OPENED = "opened",
  OPENED_BLINKING = "opened_blinking"
}
local TestEyeStateAnims = {
  CLOSED = "closed",
  CLOSING = "closed",
  OPENING = "opened",
  OPENED = "opened",
  OPENED_BLINKING = "opened"
}
local DefaultEyeData = {
  targetLayer = "Eye",
  insertLayer = "Eye",
  insertLayerOffset = -0.001,
  sprite = "pupil",
  offset = lua_sys.Vector2(240, 262),
  clipping = lua_sys.Vector4(-280, -260, 280, 280),
  clipLayerName = "",
  maxRadius = 80,
  speed = 0.05
}
local IslandAwakeningData = {
  {
    islandId = 1,
    islandTheme = -1,
    EyeAnim = "xml_bin/island01_awaken.bin",
    EyeAnimAttachLayer = "eye_node",
    version = 1,
    Eyes = {
      {
        targetLayer = "pupil_left",
        insertLayer = "pupil_left",
        insertLayerOffset = -0.001,
        sheet = "xml_resources/island01_sheet02.xml",
        sprite = "pupil",
        offset = lua_sys.Vector2(0, 0),
        clipLayerName = "mask_left",
        maxRadius = 80,
        speed = 0.05
      },
      {
        targetLayer = "pupil_right",
        insertLayer = "pupil_right",
        insertLayerOffset = -0.001,
        sheet = "xml_resources/island01_sheet02.xml",
        sprite = "pupil",
        offset = lua_sys.Vector2(0, 0),
        clipLayerName = "mask_right",
        maxRadius = 80,
        speed = 0.05
      }
    },
    EyeStateAnims = DefaultEyeStateAnims
  },
  {
    islandId = 1,
    islandTheme = 6,
    EyeAnim = "xml_bin/island01_halloween_awaken.bin",
    EyeAnimAttachLayer = "eye_node",
    version = 1,
    Eyes = {
      {
        targetLayer = "pupil_left",
        insertLayer = "pupil_left",
        insertLayerOffset = -0.001,
        sheet = "xml_resources/island01_sheet02_hal.xml",
        sprite = "pupil",
        offset = lua_sys.Vector2(0, 0),
        clipLayerName = "mask_left",
        maxRadius = 80,
        speed = 0.05
      },
      {
        targetLayer = "pupil_right",
        insertLayer = "pupil_right",
        insertLayerOffset = -0.001,
        sheet = "xml_resources/island01_sheet02_hal.xml",
        sprite = "pupil",
        offset = lua_sys.Vector2(0, 0),
        clipLayerName = "mask_right",
        maxRadius = 80,
        speed = 0.05
      }
    },
    EyeStateAnims = DefaultEyeStateAnims
  },
  {
    islandId = 1,
    islandTheme = 1,
    EyeAnim = "xml_bin/island01_veggie_awaken.bin",
    EyeAnimAttachLayer = "eye_node",
    version = 1,
    Eyes = {
      {
        targetLayer = "pupil_left",
        insertLayer = "pupil_left",
        insertLayerOffset = -0.001,
        sheet = "xml_resources/island01_sheet01_veggie.xml",
        sprite = "island01_eyeball",
        offset = lua_sys.Vector2(0, 0),
        clipLayerName = "mask_left",
        maxRadius = 80,
        speed = 0.05
      },
      {
        targetLayer = "pupil_right",
        insertLayer = "pupil_right",
        insertLayerOffset = -0.001,
        sheet = "xml_resources/island01_sheet01_veggie.xml",
        sprite = "island01_eyeball",
        offset = lua_sys.Vector2(0, 0),
        clipLayerName = "mask_right",
        maxRadius = 80,
        speed = 0.05
      }
    },
    EyeStateAnims = DefaultEyeStateAnims
  },
  {
    islandId = 2,
    islandTheme = -1,
    EyeAnim = "xml_bin/island02_awaken.bin",
    EyeAnimAttachLayer = "eye_node",
    version = 1,
    Eyes = {
      {
        targetLayer = "pupil_left",
        insertLayer = "pupil_left",
        insertLayerOffset = -0.001,
        sheet = "xml_resources/island02_sheet02.xml",
        sprite = "pupil",
        offset = lua_sys.Vector2(0, 0),
        clipLayerName = "mask_left",
        maxRadius = 80,
        speed = 0.05
      },
      {
        targetLayer = "pupil_right",
        insertLayer = "pupil_right",
        insertLayerOffset = -0.001,
        sheet = "xml_resources/island02_sheet02.xml",
        sprite = "pupil",
        offset = lua_sys.Vector2(0, 0),
        clipLayerName = "mask_right",
        maxRadius = 80,
        speed = 0.05
      }
    },
    EyeStateAnims = DefaultEyeStateAnims
  },
  {
    islandId = 2,
    islandTheme = 7,
    EyeAnim = "xml_bin/island02_xmas_awaken.bin",
    EyeAnimAttachLayer = "eye_node",
    version = 1,
    Eyes = {
      {
        targetLayer = "pupil_left",
        insertLayer = "pupil_left",
        insertLayerOffset = -0.001,
        sheet = "xml_resources/island02_sheet02_xmas.xml",
        sprite = "pupil",
        offset = lua_sys.Vector2(0, 0),
        clipLayerName = "mask_left",
        maxRadius = 80,
        speed = 0.05
      },
      {
        targetLayer = "pupil_right",
        insertLayer = "pupil_right",
        insertLayerOffset = -0.001,
        sheet = "xml_resources/island02_sheet02_xmas.xml",
        sprite = "pupil",
        offset = lua_sys.Vector2(0, 0),
        clipLayerName = "mask_right",
        maxRadius = 80,
        speed = 0.05
      }
    },
    EyeStateAnims = DefaultEyeStateAnims
  },
  {
    islandId = 2,
    islandTheme = 2,
    EyeAnim = "xml_bin/island02_temple_awaken.bin",
    EyeAnimAttachLayer = "eye_node",
    version = 1,
    Eyes = {
      {
        targetLayer = "pupil_left",
        insertLayer = "pupil_left",
        insertLayerOffset = -0.001,
        sheet = "xml_resources/island02_sheet02_temple.xml",
        sprite = "island02_pupil",
        offset = lua_sys.Vector2(0, 0),
        clipLayerName = "mask_left",
        maxRadius = 80,
        speed = 0.05
      },
      {
        targetLayer = "pupil_right",
        insertLayer = "pupil_right",
        insertLayerOffset = -0.001,
        sheet = "xml_resources/island02_sheet02_temple.xml",
        sprite = "island02_pupil",
        offset = lua_sys.Vector2(0, 0),
        clipLayerName = "mask_right",
        maxRadius = 80,
        speed = 0.05
      }
    },
    EyeStateAnims = DefaultEyeStateAnims
  },
  {
    islandId = 3,
    islandTheme = -1,
    EyeAnim = "xml_bin/island03_awaken.bin",
    EyeAnimAttachLayer = "eye_node",
    version = 1,
    Eyes = {
      {
        targetLayer = "pupil_left",
        insertLayer = "pupil_left",
        insertLayerOffset = -0.001,
        sheet = "xml_resources/island03_sheet02.xml",
        sprite = "pupil",
        offset = lua_sys.Vector2(0, 0),
        clipLayerName = "mask_left",
        maxRadius = 80,
        speed = 0.05
      },
      {
        targetLayer = "pupil_right",
        insertLayer = "pupil_right",
        insertLayerOffset = -0.001,
        sheet = "xml_resources/island03_sheet02.xml",
        sprite = "pupil",
        offset = lua_sys.Vector2(0, 0),
        clipLayerName = "mask_right",
        maxRadius = 80,
        speed = 0.05
      }
    },
    EyeStateAnims = DefaultEyeStateAnims
  },
  {
    islandId = 3,
    islandTheme = 8,
    EyeAnim = "xml_bin/island03_val_awaken.bin",
    EyeAnimAttachLayer = "eye_node",
    version = 1,
    Eyes = {
      {
        targetLayer = "pupil_left",
        insertLayer = "pupil_left",
        insertLayerOffset = -0.001,
        sheet = "xml_resources/island03_sheet02_val.xml",
        sprite = "pupil",
        offset = lua_sys.Vector2(0, 0),
        clipLayerName = "mask_left",
        maxRadius = 80,
        speed = 0.05
      },
      {
        targetLayer = "pupil_right",
        insertLayer = "pupil_right",
        insertLayerOffset = -0.001,
        sheet = "xml_resources/island03_sheet02_val.xml",
        sprite = "pupil",
        offset = lua_sys.Vector2(0, 0),
        clipLayerName = "mask_right",
        maxRadius = 80,
        speed = 0.05
      }
    },
    EyeStateAnims = DefaultEyeStateAnims
  },
  {
    islandId = 3,
    islandTheme = 5,
    EyeAnim = "xml_bin/island03_bird_awaken.bin",
    EyeAnimAttachLayer = "eye_node",
    version = 1,
    Eyes = {
      {
        targetLayer = "pupil_left",
        insertLayer = "pupil_left",
        insertLayerOffset = -0.001,
        sheet = "xml_resources/island03_bird_sheet01.xml",
        sprite = "island03_eyeball",
        offset = lua_sys.Vector2(0, 0),
        clipLayerName = "mask_left",
        maxRadius = 80,
        speed = 0.05
      },
      {
        targetLayer = "pupil_right",
        insertLayer = "pupil_right",
        insertLayerOffset = -0.001,
        sheet = "xml_resources/island03_bird_sheet01.xml",
        sprite = "island03_eyeball",
        offset = lua_sys.Vector2(0, 0),
        clipLayerName = "mask_right",
        maxRadius = 80,
        speed = 0.05
      }
    },
    EyeStateAnims = DefaultEyeStateAnims
  },
  {
    islandId = 4,
    islandTheme = -1,
    EyeAnim = "xml_bin/island04_awaken.bin",
    EyeAnimAttachLayer = "eye_node",
    version = 1,
    EyeLayerOffset = -0.02,
    Eyes = {
      {
        targetLayer = "pupil_left",
        insertLayer = "pupil_left",
        insertLayerOffset = 0,
        sheet = "xml_resources/island04_sheet02.xml",
        sprite = "pupil",
        offset = lua_sys.Vector2(0, 0),
        clipLayerName = "mask_left",
        maxRadius = 80,
        speed = 0.05
      },
      {
        targetLayer = "pupil_right",
        insertLayer = "pupil_right",
        insertLayerOffset = 0,
        sheet = "xml_resources/island04_sheet02.xml",
        sprite = "pupil",
        offset = lua_sys.Vector2(0, 0),
        clipLayerName = "mask_right",
        maxRadius = 80,
        speed = 0.05
      }
    },
    EyeStateAnims = DefaultEyeStateAnims
  },
  {
    islandId = 4,
    islandTheme = 9,
    EyeAnim = "xml_bin/island04_easter_awaken.bin",
    EyeAnimAttachLayer = "eye_node",
    version = 1,
    EyeLayerOffset = -0.02,
    Eyes = {
      {
        targetLayer = "pupil_left",
        insertLayer = "pupil_left",
        sheet = "xml_resources/island04_sheet03_easter.xml",
        sprite = "pupil",
        offset = lua_sys.Vector2(0, 0),
        clipLayerName = "mask_left",
        maxRadius = 80,
        speed = 0.05
      },
      {
        targetLayer = "pupil_right",
        insertLayer = "pupil_right",
        sheet = "xml_resources/island04_sheet03_easter.xml",
        sprite = "pupil",
        offset = lua_sys.Vector2(0, 0),
        clipLayerName = "mask_right",
        maxRadius = 80,
        speed = 0.05
      }
    },
    EyeStateAnims = DefaultEyeStateAnims
  },
  {
    islandId = 4,
    islandTheme = 4,
    EyeAnim = "xml_bin/island04_fish_awaken.bin",
    EyeAnimAttachLayer = "eye_node",
    version = 1,
    Eyes = {
      {
        targetLayer = "pupil_left",
        insertLayer = "pupil_left",
        insertLayerOffset = -0.001,
        sheet = "xml_resources/island04_fish_sheet02.xml",
        sprite = "island04_eyeball",
        offset = lua_sys.Vector2(0, 0),
        clipLayerName = "mask_left",
        maxRadius = 80,
        speed = 0.05
      },
      {
        targetLayer = "pupil_right",
        insertLayer = "pupil_right",
        insertLayerOffset = -0.001,
        sheet = "xml_resources/island04_fish_sheet02.xml",
        sprite = "island04_eyeball",
        offset = lua_sys.Vector2(0, 0),
        clipLayerName = "mask_right",
        maxRadius = 80,
        speed = 0.05
      }
    },
    EyeStateAnims = DefaultEyeStateAnims
  },
  {
    islandId = 5,
    islandTheme = -1,
    EyeAnim = "xml_bin/island05_awaken.bin",
    EyeAnimAttachLayer = "eye_node",
    version = 1,
    Eyes = {
      {
        targetLayer = "pupil_left",
        insertLayer = "pupil_left",
        insertLayerOffset = -0.001,
        sheet = "xml_resources/island05_sheet02.xml",
        sprite = "pupil",
        offset = lua_sys.Vector2(0, 0),
        clipLayerName = "mask_left",
        maxRadius = 80,
        speed = 0.05
      },
      {
        targetLayer = "pupil_right",
        insertLayer = "pupil_right",
        insertLayerOffset = -0.001,
        sheet = "xml_resources/island05_sheet02.xml",
        sprite = "pupil",
        offset = lua_sys.Vector2(0, 0),
        clipLayerName = "mask_right",
        maxRadius = 80,
        speed = 0.05
      }
    },
    EyeStateAnims = DefaultEyeStateAnims
  },
  {
    islandId = 5,
    islandTheme = 10,
    EyeAnim = "xml_bin/island05_summer_awaken.bin",
    EyeAnimAttachLayer = "eye_node",
    version = 1,
    Eyes = {
      {
        targetLayer = "pupil_left",
        insertLayer = "pupil_left",
        insertLayerOffset = -0.001,
        sheet = "xml_resources/island05_sheet02_summer.xml",
        sprite = "pupil",
        offset = lua_sys.Vector2(0, 0),
        clipLayerName = "mask_left",
        maxRadius = 80,
        speed = 0.05
      },
      {
        targetLayer = "pupil_right",
        insertLayer = "pupil_right",
        insertLayerOffset = -0.001,
        sheet = "xml_resources/island05_sheet02_summer.xml",
        sprite = "pupil",
        offset = lua_sys.Vector2(0, 0),
        clipLayerName = "mask_right",
        maxRadius = 80,
        speed = 0.05
      }
    },
    EyeStateAnims = DefaultEyeStateAnims
  },
  {
    islandId = 5,
    islandTheme = 3,
    EyeAnim = "xml_bin/island05_sand_awaken.bin",
    EyeAnimAttachLayer = "eye_node",
    version = 1,
    Eyes = {
      {
        targetLayer = "pupil_left",
        insertLayer = "pupil_left",
        insertLayerOffset = -0.001,
        sheet = "xml_resources/island05_sheet01_sand.xml",
        sprite = "island05_eye",
        offset = lua_sys.Vector2(0, 0),
        clipLayerName = "mask_left",
        maxRadius = 80,
        speed = 0.05
      },
      {
        targetLayer = "pupil_left_02",
        insertLayer = "pupil_left_02",
        insertLayerOffset = -0.001,
        sheet = "xml_resources/island05_sheet01_sand.xml",
        sprite = "island05_eye_2",
        offset = lua_sys.Vector2(0, 0),
        maxRadius = 80,
        speed = 0.05
      },
      {
        targetLayer = "pupil_right",
        insertLayer = "pupil_right",
        insertLayerOffset = -0.001,
        sheet = "xml_resources/island05_sheet01_sand.xml",
        sprite = "island05_eye",
        offset = lua_sys.Vector2(0, 0),
        clipLayerName = "mask_right",
        maxRadius = 80,
        speed = 0.05
      },
      {
        targetLayer = "pupil_right_02",
        insertLayer = "pupil_right_02",
        insertLayerOffset = -0.001,
        sheet = "xml_resources/island05_sheet01_sand.xml",
        sprite = "island05_eye_2",
        offset = lua_sys.Vector2(0, 0),
        maxRadius = 80,
        speed = 0.05
      }
    },
    EyeStateAnims = DefaultEyeStateAnims
  },
  {
    islandId = 15,
    islandTheme = -1,
    version = 1,
    EyeAnim = "xml_bin/island15_awaken.bin",
    EyeAnimAttachLayer = "eye_node",
    EyeLayerOffset = -0.01,
    Eyes = {
      {
        targetLayer = "pupil_middle",
        insertLayer = "pupil_middle",
        insertLayerOffset = 0,
        sheet = "xml_resources/island15_sheet02.xml",
        sprite = "Centre_Pupil",
        offset = lua_sys.Vector2(0, 0),
        maxRadius = 60,
        speed = 0.05,
        maxScale = 0.4,
        scaleAmount = lua_sys.Vector2(0.05, 0.2),
        alwaysAwake = true
      },
      {
        targetLayer = "pupil L",
        insertLayer = "pupil L",
        insertLayerOffset = 0,
        sheet = "xml_resources/island15_sheet02.xml",
        sprite = "Side_Pupil",
        offset = lua_sys.Vector2(0, 0),
        maxRadius = 20,
        speed = 0.05,
        maxScale = 0.3,
        scaleAmount = lua_sys.Vector2(-0.025, 0.15),
        alwaysAwake = true
      },
      {
        targetLayer = "pupil R",
        insertLayer = "pupil R",
        insertLayerOffset = 0,
        sheet = "xml_resources/island15_sheet02.xml",
        sprite = "Side_Pupil",
        offset = lua_sys.Vector2(0, 0),
        maxRadius = 20,
        speed = 0.05,
        maxScale = 0.3,
        scaleAmount = lua_sys.Vector2(-0.025, 0.15),
        alwaysAwake = true
      }
    },
    EyeStateAnims = DefaultEyeStateAnims,
    eyeViewWidth = 2800,
    awakenSound = "world_15_titan_awaken.wav",
    sleepSound = "world_15_titan_sleep.wav"
  },
  {
    islandId = 15,
    islandTheme = 20,
    version = 1,
    EyeAnim = "xml_bin/island15_mindboggle_awaken.bin",
    EyeAnimAttachLayer = "eye_node",
    Eyes = {
      {
        targetLayer = "pupil_middle",
        insertLayer = "pupil_middle",
        insertLayerOffset = 0,
        sheet = "xml_resources/island15_mindboggle_sheet01.xml",
        sprite = "Centre_Pupil",
        offset = lua_sys.Vector2(0, 0),
        maxRadius = 60,
        speed = 0.05,
        maxScale = 0.4,
        scaleAmount = lua_sys.Vector2(0.05, 0.2),
        alwaysAwake = true
      },
      {
        targetLayer = "pupil L",
        insertLayer = "pupil L",
        insertLayerOffset = 0,
        sheet = "xml_resources/island15_mindboggle_sheet02.xml",
        sprite = "Side_Pupil",
        offset = lua_sys.Vector2(0, 0),
        maxRadius = 20,
        speed = 0.05,
        maxScale = 0.3,
        scaleAmount = lua_sys.Vector2(-0.025, 0.15),
        alwaysAwake = true
      },
      {
        targetLayer = "pupil R",
        insertLayer = "pupil R",
        insertLayerOffset = 0,
        sheet = "xml_resources/island15_mindboggle_sheet02.xml",
        sprite = "Side_Pupil",
        offset = lua_sys.Vector2(0, 0),
        maxRadius = 20,
        speed = 0.05,
        maxScale = 0.3,
        scaleAmount = lua_sys.Vector2(-0.025, 0.15),
        alwaysAwake = true
      }
    },
    EyeStateAnims = DefaultEyeStateAnims,
    eyeViewWidth = 2800,
    awakenSound = "world_15_titan_awaken.wav",
    sleepSound = "world_15_titan_sleep.wav"
  },
  {
    islandId = 115,
    islandTheme = -1,
    version = 1,
    EyeAnim = "xml_bin/island15_mirror_awaken.bin",
    EyeAnimAttachLayer = "eye_node",
    EyeLayerOffset = -0.02,
    Eyes = {
      {
        targetLayer = "pupil_middle",
        insertLayer = "pupil_middle",
        insertLayerOffset = 0,
        sheet = "xml_resources/island15_MIRROR_sheet03.xml",
        sprite = "Centre_Pupil",
        offset = lua_sys.Vector2(0, 0),
        maxRadius = 60,
        speed = 0.05,
        maxScale = 0.4,
        scaleAmount = lua_sys.Vector2(0.05, 0.2),
        alwaysAwake = true
      },
      {
        targetLayer = "pupil",
        insertLayer = "pupil",
        insertLayerOffset = 0,
        sheet = "xml_resources/island15_MIRROR_sheet03.xml",
        sprite = "Side_Pupil",
        offset = lua_sys.Vector2(0, 0),
        maxRadius = 20,
        speed = 0.05,
        maxScale = 0.3,
        scaleAmount = lua_sys.Vector2(-0.025, 0.15),
        alwaysAwake = true
      }
    },
    EyeStateAnims = DefaultEyeStateAnims,
    eyeViewWidth = 2800,
    awakenSound = "world_15_titan_awaken.wav",
    sleepSound = "world_15_titan_sleep.wav"
  },
  {
    islandId = 16,
    islandTheme = -1,
    version = 1,
    EyeAnim = "xml_bin/island16_awaken.bin",
    EyeAnimAttachLayer = "eye_node",
    EyeLayerOffset = -0.01,
    Eyes = {
      {
        targetLayer = "pupil_left",
        insertLayer = "pupil_left",
        insertLayerOffset = 0,
        sheet = "xml_resources/island16_sheet02.xml",
        sprite = "pupil",
        offset = lua_sys.Vector2(0, 0),
        clipLayerName = "mask_left",
        maxRadius = 80,
        speed = 0.05
      },
      {
        targetLayer = "pupil_right",
        insertLayer = "pupil_right",
        insertLayerOffset = 0,
        sheet = "xml_resources/island16_sheet02.xml",
        sprite = "pupil",
        offset = lua_sys.Vector2(0, 0),
        clipLayerName = "mask_right",
        maxRadius = 80,
        speed = 0.05
      }
    },
    EyeStateAnims = DefaultEyeStateAnims,
    eyeViewWidth = 2800
  },
  {
    islandId = 16,
    islandTheme = 15,
    version = 1,
    EyeAnim = "xml_bin/island16_cloverspell_awaken.bin",
    EyeAnimAttachLayer = "eye_node",
    Eyes = {
      {
        targetLayer = "pupil_left",
        insertLayer = "pupil_left",
        insertLayerOffset = 0,
        sheet = "xml_resources/island16_sheet03_clover.xml",
        sprite = "pupil",
        offset = lua_sys.Vector2(0, 0),
        clipLayerName = "mask_left",
        maxRadius = 80,
        speed = 0.05
      },
      {
        targetLayer = "pupil_right",
        insertLayer = "pupil_right",
        insertLayerOffset = 0,
        sheet = "xml_resources/island16_sheet03_clover.xml",
        sprite = "pupil",
        offset = lua_sys.Vector2(0, 0),
        clipLayerName = "mask_right",
        maxRadius = 80,
        speed = 0.05
      }
    },
    EyeStateAnims = DefaultEyeStateAnims,
    eyeViewWidth = 2800
  },
  {
    islandId = 116,
    islandTheme = -1,
    version = 1,
    EyeAnim = "xml_bin/island16_mirror_awaken.bin",
    EyeAnimAttachLayer = "eye_node",
    EyeLayerOffset = -0.02,
    Eyes = {
      {
        targetLayer = "pupil_left",
        insertLayer = "pupil_left",
        insertLayerOffset = 0,
        sheet = "xml_resources/island16_MIRROR_sheet03.xml",
        sprite = "pupil_M",
        offset = lua_sys.Vector2(0, 0),
        clipLayerName = "mask_left",
        maxRadius = 80,
        speed = 0.05
      },
      {
        targetLayer = "pupil_right",
        insertLayer = "pupil_right",
        insertLayerOffset = 0,
        sheet = "xml_resources/island16_MIRROR_sheet03.xml",
        sprite = "pupil",
        offset = lua_sys.Vector2(0, 0),
        clipLayerName = "mask_right",
        maxRadius = 80,
        speed = 0.05
      }
    },
    EyeStateAnims = DefaultEyeStateAnims,
    eyeViewWidth = 2800
  },
  {
    islandId = 18,
    islandTheme = -1,
    version = 1,
    EyeAnim = "xml_bin/island18_awaken.bin",
    EyeAnimAttachLayer = "eye_node",
    Eyes = {
      {
        targetLayer = "pupil_left",
        insertLayer = "pupil_left",
        insertLayerOffset = 0,
        sheet = "xml_resources/island18_sheet02.xml",
        sprite = "pupil",
        offset = lua_sys.Vector2(0, 0),
        clipLayerName = "mask_left",
        maxRadius = 80,
        speed = 0.05
      },
      {
        targetLayer = "pupil_right",
        insertLayer = "pupil_right",
        insertLayerOffset = 0,
        sheet = "xml_resources/island18_sheet02.xml",
        sprite = "pupil",
        offset = lua_sys.Vector2(0, 0),
        clipLayerName = "mask_right",
        maxRadius = 80,
        speed = 0.05
      }
    },
    EyeStateAnims = DefaultEyeStateAnims
  },
  {
    islandId = 18,
    islandTheme = 19,
    version = 1,
    EyeAnim = "xml_bin/island18_skypainting_awaken.bin",
    EyeAnimAttachLayer = "eye_node",
    Eyes = {
      {
        targetLayer = "pupil_left",
        insertLayer = "pupil_left",
        insertLayerOffset = 0,
        sheet = "xml_resources/island18_skypainting_sheet03.xml",
        sprite = "pupil",
        offset = lua_sys.Vector2(0, 0),
        clipLayerName = "mask_left",
        maxRadius = 80,
        speed = 0.05
      },
      {
        targetLayer = "pupil_right",
        insertLayer = "pupil_right",
        insertLayerOffset = 0,
        sheet = "xml_resources/island18_skypainting_sheet03.xml",
        sprite = "pupil",
        offset = lua_sys.Vector2(0, 0),
        clipLayerName = "mask_right",
        maxRadius = 80,
        speed = 0.05
      }
    },
    EyeStateAnims = DefaultEyeStateAnims
  },
  {
    islandId = 118,
    islandTheme = -1,
    version = 1,
    EyeAnim = "xml_bin/island18_mirror_awaken.bin",
    EyeAnimAttachLayer = "eye_node",
    Eyes = {
      {
        targetLayer = "pupil_left",
        insertLayer = "pupil_left",
        insertLayerOffset = 0,
        sheet = "xml_resources/island18_MIRROR_sheet03.xml",
        sprite = "pupil_left",
        offset = lua_sys.Vector2(0, 0),
        clipLayerName = "mask_left",
        maxRadius = 80,
        speed = 0.05
      },
      {
        targetLayer = "pupil_right",
        insertLayer = "pupil_right",
        insertLayerOffset = 0,
        sheet = "xml_resources/island18_MIRROR_sheet03.xml",
        sprite = "pupil",
        offset = lua_sys.Vector2(0, 0),
        clipLayerName = "mask_right",
        maxRadius = 80,
        speed = 0.05
      }
    },
    EyeStateAnims = DefaultEyeStateAnims
  }
}
return IslandAwakeningData
