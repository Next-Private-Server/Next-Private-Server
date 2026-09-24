local IslandPropData = {}
local islandProps = {
  {
    islandId = 10,
    themeId = -1,
    props = {
      prop_light_01_L01 = {
        animFile = "xml_bin/island10_prop_light_01.bin",
        instrument = "010_prop_light_01.bin",
        minPower = 1
      },
      prop_light_01_R01 = {
        animFile = "xml_bin/island10_prop_light_01.bin",
        instrument = "010_prop_light_01.bin",
        minPower = 1
      },
      prop_light_07_L01 = {
        animFile = "xml_bin/island10_prop_light_07.bin",
        instrument = "010_prop_light_01.bin",
        minPower = 1
      },
      prop_light_07_R01 = {
        animFile = "xml_bin/island10_prop_light_07.bin",
        instrument = "010_prop_light_01.bin",
        minPower = 1
      },
      prop_light_13_L01 = {
        animFile = "xml_bin/island10_prop_light_13.bin",
        instrument = "010_prop_light_01.bin",
        minPower = 1
      },
      prop_light_13_R01 = {
        animFile = "xml_bin/island10_prop_light_13.bin",
        instrument = "010_prop_light_01.bin",
        minPower = 1
      },
      prop_light_08_L01 = {
        animFile = "xml_bin/island10_prop_light_08.bin",
        instrument = "010_prop_light_02.bin",
        minPower = 1
      },
      prop_light_08_R01 = {
        animFile = "xml_bin/island10_prop_light_08.bin",
        instrument = "010_prop_light_02.bin",
        minPower = 1
      },
      prop_light_01_L02 = {
        animFile = "xml_bin/island10_prop_light_01.bin",
        instrument = "010_prop_light_02.bin",
        minPower = 1
      },
      prop_light_01_R02 = {
        animFile = "xml_bin/island10_prop_light_01.bin",
        instrument = "010_prop_light_02.bin",
        minPower = 1
      },
      prop_light_05_L01 = {
        animFile = "xml_bin/island10_prop_light_05.bin",
        instrument = "010_prop_light_03.bin",
        minPower = 1
      },
      prop_light_05_R01 = {
        animFile = "xml_bin/island10_prop_light_05.bin",
        instrument = "010_prop_light_03.bin",
        minPower = 1
      },
      prop_light_01_L03 = {
        animFile = "xml_bin/island10_prop_light_01.bin",
        instrument = "010_prop_light_03.bin",
        minPower = 1
      },
      prop_light_01_R03 = {
        animFile = "xml_bin/island10_prop_light_01.bin",
        instrument = "010_prop_light_03.bin",
        minPower = 1
      },
      prop_light_12_L01 = {
        animFile = "xml_bin/island10_prop_light_12.bin",
        instrument = "010_prop_light_04.bin",
        minPower = 2
      },
      prop_light_12_R01 = {
        animFile = "xml_bin/island10_prop_light_12.bin",
        instrument = "010_prop_light_04.bin",
        minPower = 2
      },
      prop_light_12_L02 = {
        animFile = "xml_bin/island10_prop_light_12.bin",
        instrument = "010_prop_light_05.bin",
        minPower = 2
      },
      prop_light_12_R02 = {
        animFile = "xml_bin/island10_prop_light_12.bin",
        instrument = "010_prop_light_05.bin",
        minPower = 2
      },
      prop_light_12_L03 = {
        animFile = "xml_bin/island10_prop_light_12.bin",
        instrument = "010_prop_light_06.bin",
        minPower = 2
      },
      prop_light_12_R03 = {
        animFile = "xml_bin/island10_prop_light_12.bin",
        instrument = "010_prop_light_06.bin",
        minPower = 2
      },
      prop_light_11_L01 = {
        animFile = "xml_bin/island10_prop_light_11.bin",
        instrument = "010_prop_light_07.bin",
        minPower = 3
      },
      prop_light_11_R01 = {
        animFile = "xml_bin/island10_prop_light_11.bin",
        instrument = "010_prop_light_07.bin",
        minPower = 3
      },
      prop_light_02_L01 = {
        animFile = "xml_bin/island10_prop_light_02.bin",
        instrument = "010_prop_light_07.bin",
        minPower = 3
      },
      prop_light_02_R01 = {
        animFile = "xml_bin/island10_prop_light_02.bin",
        instrument = "010_prop_light_07.bin",
        minPower = 3
      },
      prop_light_14 = {
        animFile = "xml_bin/island10_prop_light_14.bin",
        instrument = "010_prop_light_07.bin",
        minPower = 3
      },
      prop_light_12_L04 = {
        animFile = "xml_bin/island10_prop_light_12.bin",
        instrument = "010_prop_light_08.bin",
        minPower = 4
      },
      prop_light_12_L05 = {
        animFile = "xml_bin/island10_prop_light_12.bin",
        instrument = "010_prop_light_09.bin",
        minPower = 4
      },
      prop_light_12_R04 = {
        animFile = "xml_bin/island10_prop_light_12.bin",
        instrument = "010_prop_light_10.bin",
        minPower = 4
      },
      prop_light_12_R05 = {
        animFile = "xml_bin/island10_prop_light_12.bin",
        instrument = "010_prop_light_11.bin",
        minPower = 4
      },
      prop_lightning_L = {
        animFile = "xml_bin/island10_prop_lightning.bin",
        instrument = "010_prop_lightning_L.bin",
        minPower = 4
      },
      prop_lightning_M = {
        animFile = "xml_bin/island10_prop_lightning.bin",
        instrument = "010_prop_lightning_M.bin",
        minPower = 4
      },
      prop_lightning_R = {
        animFile = "xml_bin/island10_prop_lightning.bin",
        instrument = "010_prop_lightning_R.bin",
        minPower = 4
      }
    }
  },
  {
    islandId = 18,
    themeId = -1,
    props = {
      prop_aurora = {
        minPower = 1,
        animFile = "xml_bin/island18_prop_aurora.bin",
        layer = "gridLayer",
        priority = 4000,
        instrument = "018_prop_aurora.bin",
        instruments = {
          [4] = "018_prop_aurora_finale.bin"
        }
      },
      prop_firefly = {
        minPower = 2,
        animFile = "xml_bin/island18_prop_firefly.bin",
        layer = "gridLayer1",
        instrument = "018_prop_fireflies.bin",
        instruments = {
          [4] = "018_prop_fireflies_finale.bin"
        }
      },
      prop_node_01 = {
        minPower = 3,
        animFile = "xml_bin/island18_prop_node_01.bin",
        instrument = "018_prop_lamp_01.bin",
        instruments = {
          [4] = "018_prop_lamp_finale_01.bin"
        }
      },
      prop_node_02 = {
        minPower = 3,
        animFile = "xml_bin/island18_prop_node_02.bin",
        instrument = "018_prop_lamp_02.bin",
        instruments = {
          [4] = "018_prop_lamp_finale_02.bin"
        }
      },
      prop_node_03 = {
        minPower = 3,
        animFile = "xml_bin/island18_prop_node_03.bin",
        instrument = "018_prop_lamp_03.bin",
        instruments = {
          [4] = "018_prop_lamp_finale_03.bin"
        }
      },
      prop_node_04 = {
        minPower = 3,
        animFile = "xml_bin/island18_prop_node_04.bin",
        instrument = "018_prop_lamp_04.bin",
        instruments = {
          [4] = "018_prop_lamp_finale_04.bin"
        }
      },
      prop_node_05 = {
        minPower = 3,
        animFile = "xml_bin/island18_prop_node_05.bin",
        instrument = "018_prop_lamp_05.bin",
        instruments = {
          [4] = "018_prop_lamp_finale_05.bin"
        }
      },
      prop_node_06 = {
        minPower = 3,
        animFile = "xml_bin/island18_prop_node_05.bin",
        instrument = "018_prop_lamp_05.bin",
        instruments = {
          [4] = "018_prop_lamp_finale_05.bin"
        }
      },
      prop_node_07 = {
        minPower = 3,
        animFile = "xml_bin/island18_prop_node_04.bin",
        instrument = "018_prop_lamp_04.bin",
        instruments = {
          [4] = "018_prop_lamp_finale_04.bin"
        }
      },
      prop_node_08 = {
        minPower = 3,
        animFile = "xml_bin/island18_prop_node_03.bin",
        instrument = "018_prop_lamp_03.bin",
        instruments = {
          [4] = "018_prop_lamp_finale_03.bin"
        }
      },
      prop_node_09 = {
        minPower = 3,
        animFile = "xml_bin/island18_prop_node_02.bin",
        instrument = "018_prop_lamp_02.bin",
        instruments = {
          [4] = "018_prop_lamp_finale_02.bin"
        }
      },
      prop_node_10 = {
        minPower = 3,
        animFile = "xml_bin/island18_prop_node_01.bin",
        instrument = "018_prop_lamp_01.bin",
        instruments = {
          [4] = "018_prop_lamp_finale_01.bin"
        }
      }
    }
  },
  {
    islandId = 18,
    themeId = 19,
    props = {
      prop_aurora = {
        minPower = 1,
        animFile = "xml_bin/island18_skypainting_prop_aurora.bin",
        layer = "gridLayer",
        priority = 4000,
        instrument = "018_prop_aurora.bin",
        instruments = {
          [4] = "018_prop_aurora_finale.bin"
        }
      },
      prop_firefly = {
        minPower = 2,
        animFile = "xml_bin/island18_skypainting_prop_firefly.bin",
        layer = "gridLayer1",
        instrument = "018_prop_fireflies.bin",
        instruments = {
          [4] = "018_prop_fireflies_finale.bin"
        }
      },
      prop_node_01 = {
        minPower = 3,
        animFile = "xml_bin/island18_skypainting_prop_node_01.bin",
        instrument = "018_prop_lamp_01.bin",
        instruments = {
          [4] = "018_prop_lamp_finale_01.bin"
        }
      },
      prop_node_02 = {
        minPower = 3,
        animFile = "xml_bin/island18_skypainting_prop_node_02.bin",
        instrument = "018_prop_lamp_02.bin",
        instruments = {
          [4] = "018_prop_lamp_finale_02.bin"
        }
      },
      prop_node_03 = {
        minPower = 3,
        animFile = "xml_bin/island18_skypainting_prop_node_03.bin",
        instrument = "018_prop_lamp_03.bin",
        instruments = {
          [4] = "018_prop_lamp_finale_03.bin"
        }
      },
      prop_node_04 = {
        minPower = 3,
        animFile = "xml_bin/island18_skypainting_prop_node_04.bin",
        instrument = "018_prop_lamp_04.bin",
        instruments = {
          [4] = "018_prop_lamp_finale_04.bin"
        }
      },
      prop_node_05 = {
        minPower = 3,
        animFile = "xml_bin/island18_skypainting_prop_node_05.bin",
        instrument = "018_prop_lamp_05.bin",
        instruments = {
          [4] = "018_prop_lamp_finale_05.bin"
        }
      },
      prop_node_06 = {
        minPower = 3,
        animFile = "xml_bin/island18_skypainting_prop_node_05.bin",
        instrument = "018_prop_lamp_05.bin",
        instruments = {
          [4] = "018_prop_lamp_finale_05.bin"
        }
      },
      prop_node_07 = {
        minPower = 3,
        animFile = "xml_bin/island18_skypainting_prop_node_04.bin",
        instrument = "018_prop_lamp_04.bin",
        instruments = {
          [4] = "018_prop_lamp_finale_04.bin"
        }
      },
      prop_node_08 = {
        minPower = 3,
        animFile = "xml_bin/island18_skypainting_prop_node_03.bin",
        instrument = "018_prop_lamp_03.bin",
        instruments = {
          [4] = "018_prop_lamp_finale_03.bin"
        }
      },
      prop_node_09 = {
        minPower = 3,
        animFile = "xml_bin/island18_skypainting_prop_node_02.bin",
        instrument = "018_prop_lamp_02.bin",
        instruments = {
          [4] = "018_prop_lamp_finale_02.bin"
        }
      },
      prop_node_10 = {
        minPower = 3,
        animFile = "xml_bin/island18_skypainting_prop_node_01.bin",
        instrument = "018_prop_lamp_01.bin",
        instruments = {
          [4] = "018_prop_lamp_finale_01.bin"
        }
      }
    }
  },
  {
    islandId = 118,
    themeId = -1,
    props = {
      prop_aurora = {
        minPower = 1,
        animFile = "xml_bin/island18_mirror_prop_aurora.bin",
        layer = "gridLayer",
        priority = 4000,
        instrument = "018_prop_aurora.bin",
        instruments = {
          [4] = "018_prop_aurora_finale.bin"
        }
      },
      prop_firefly = {
        minPower = 2,
        animFile = "xml_bin/island18_mirror_prop_firefly.bin",
        layer = "gridLayer1",
        instrument = "018_prop_fireflies.bin",
        instruments = {
          [4] = "018_prop_fireflies_finale.bin"
        }
      },
      prop_node_01 = {
        minPower = 3,
        animFile = "xml_bin/island18_mirror_prop_node_left_01.bin",
        instrument = "018_prop_lamp_01.bin",
        instruments = {
          [4] = "018_prop_lamp_finale_01.bin"
        }
      },
      prop_node_02 = {
        minPower = 3,
        animFile = "xml_bin/island18_mirror_prop_node_left_02.bin",
        instrument = "018_prop_lamp_02.bin",
        instruments = {
          [4] = "018_prop_lamp_finale_02.bin"
        }
      },
      prop_node_03 = {
        minPower = 3,
        animFile = "xml_bin/island18_mirror_prop_node_left_03.bin",
        instrument = "018_prop_lamp_03.bin",
        instruments = {
          [4] = "018_prop_lamp_finale_03.bin"
        }
      },
      prop_node_04 = {
        minPower = 3,
        animFile = "xml_bin/island18_mirror_prop_node_left_04.bin",
        instrument = "018_prop_lamp_04.bin",
        instruments = {
          [4] = "018_prop_lamp_finale_04.bin"
        }
      },
      prop_node_05 = {
        minPower = 3,
        animFile = "xml_bin/island18_mirror_prop_node_left_05.bin",
        instrument = "018_prop_lamp_05.bin",
        instruments = {
          [4] = "018_prop_lamp_finale_05.bin"
        }
      },
      prop_node_06 = {
        minPower = 3,
        animFile = "xml_bin/island18_mirror_prop_node_right_05.bin",
        instrument = "018_prop_lamp_05.bin",
        instruments = {
          [4] = "018_prop_lamp_finale_05.bin"
        }
      },
      prop_node_07 = {
        minPower = 3,
        animFile = "xml_bin/island18_mirror_prop_node_right_04.bin",
        instrument = "018_prop_lamp_04.bin",
        instruments = {
          [4] = "018_prop_lamp_finale_04.bin"
        }
      },
      prop_node_08 = {
        minPower = 3,
        animFile = "xml_bin/island18_mirror_prop_node_right_03.bin",
        instrument = "018_prop_lamp_03.bin",
        instruments = {
          [4] = "018_prop_lamp_finale_03.bin"
        }
      },
      prop_node_09 = {
        minPower = 3,
        animFile = "xml_bin/island18_mirror_prop_node_right_02.bin",
        instrument = "018_prop_lamp_02.bin",
        instruments = {
          [4] = "018_prop_lamp_finale_02.bin"
        }
      },
      prop_node_10 = {
        minPower = 3,
        animFile = "xml_bin/island18_mirror_prop_node_right_01.bin",
        instrument = "018_prop_lamp_01.bin",
        instruments = {
          [4] = "018_prop_lamp_finale_01.bin"
        }
      }
    }
  },
  {
    islandId = 15,
    themeId = -1,
    props = {
      prop_eyesL_bg = {
        minPower = 3,
        animFile = "xml_bin/island15_prop_eyesL_bg.bin",
        layer = "gridLayer",
        priority = 4100,
        volume = 1,
        instrument = "015_prop_eyes_solo.bin",
        instruments = {
          [4] = "015_prop_eyes_finale.bin"
        }
      },
      prop_eyesL_fg = {
        minPower = 3,
        animFile = "xml_bin/island15_prop_eyesL_fg.bin",
        layer = "gridLayer1",
        priority = 10,
        volume = 0,
        instrument = "015_prop_eyes_solo.bin",
        instruments = {
          [4] = "015_prop_eyes_finale.bin"
        }
      },
      prop_eyesR_bg = {
        minPower = 3,
        animFile = "xml_bin/island15_prop_eyesR_bg.bin",
        layer = "gridLayer",
        priority = 4100,
        volume = 0,
        instrument = "015_prop_eyes_solo.bin",
        instruments = {
          [4] = "015_prop_eyes_finale.bin"
        }
      },
      prop_eyesR_fg = {
        minPower = 3,
        animFile = "xml_bin/island15_prop_eyesR_fg.bin",
        layer = "gridLayer1",
        priority = 10,
        volume = 0,
        instrument = "015_prop_eyes_solo.bin",
        instruments = {
          [4] = "015_prop_eyes_finale.bin"
        }
      },
      prop_tentacleL01 = {
        minPower = 2,
        animFile = "xml_bin/island15_prop_tentacle01.bin",
        volume = 1,
        instrument = "015_prop_tentacles_solo.bin",
        instruments = {
          [4] = "015_prop_tentacles_finale.bin"
        }
      },
      prop_tentacleL02 = {
        minPower = 2,
        animFile = "xml_bin/island15_prop_tentacle02.bin",
        volume = 0,
        instrument = "015_prop_tentacles_solo.bin",
        instruments = {
          [4] = "015_prop_tentacles_finale.bin"
        }
      },
      prop_tentacleL03 = {
        minPower = 2,
        animFile = "xml_bin/island15_prop_tentacle03.bin",
        volume = 0,
        instrument = "015_prop_tentacles_solo.bin",
        instruments = {
          [4] = "015_prop_tentacles_finale.bin"
        }
      },
      prop_tentacleL04 = {
        minPower = 2,
        animFile = "xml_bin/island15_prop_tentacle04.bin",
        volume = 0,
        instrument = "015_prop_tentacles_solo.bin",
        instruments = {
          [4] = "015_prop_tentacles_finale.bin"
        }
      },
      prop_tentacleL05 = {
        minPower = 2,
        animFile = "xml_bin/island15_prop_tentacle05.bin",
        volume = 0,
        instrument = "015_prop_tentacles_solo.bin",
        instruments = {
          [4] = "015_prop_tentacles_finale.bin"
        }
      },
      prop_tentacleL06 = {
        minPower = 2,
        animFile = "xml_bin/island15_prop_tentacle06.bin",
        volume = 0,
        instrument = "015_prop_tentacles_solo.bin",
        instruments = {
          [4] = "015_prop_tentacles_finale.bin"
        }
      },
      prop_tentacleR01 = {
        minPower = 2,
        animFile = "xml_bin/island15_prop_tentacle01.bin",
        volume = 0,
        instrument = "015_prop_tentacles_solo.bin",
        instruments = {
          [4] = "015_prop_tentacles_finale.bin"
        }
      },
      prop_tentacleR02 = {
        minPower = 2,
        animFile = "xml_bin/island15_prop_tentacle02.bin",
        volume = 0,
        instrument = "015_prop_tentacles_solo.bin",
        instruments = {
          [4] = "015_prop_tentacles_finale.bin"
        }
      },
      prop_tentacleR03 = {
        minPower = 2,
        animFile = "xml_bin/island15_prop_tentacle03.bin",
        volume = 0,
        instrument = "015_prop_tentacles_solo.bin",
        instruments = {
          [4] = "015_prop_tentacles_finale.bin"
        }
      },
      prop_tentacleR04 = {
        minPower = 2,
        animFile = "xml_bin/island15_prop_tentacle04.bin",
        volume = 0,
        instrument = "015_prop_tentacles_solo.bin",
        instruments = {
          [4] = "015_prop_tentacles_finale.bin"
        }
      },
      prop_tentacleR05 = {
        minPower = 2,
        animFile = "xml_bin/island15_prop_tentacle05.bin",
        volume = 0,
        instrument = "015_prop_tentacles_solo.bin",
        instruments = {
          [4] = "015_prop_tentacles_finale.bin"
        }
      },
      prop_tentacleR06 = {
        minPower = 2,
        animFile = "xml_bin/island15_prop_tentacle06.bin",
        volume = 0,
        instrument = "015_prop_tentacles_solo.bin",
        instruments = {
          [4] = "015_prop_tentacles_finale.bin"
        }
      },
      prop_meteors = {
        minPower = 1,
        animFile = "xml_bin/island15_prop_meteors.bin",
        layer = "gridLayer",
        priority = 4000,
        instrument = "015_prop_meteors_solo.bin",
        instruments = {
          [4] = "015_prop_meteors_finale.bin"
        }
      }
    }
  },
  {
    islandId = 15,
    themeId = 20,
    props = {
      prop_eyesL_bg = {
        minPower = 3,
        animFile = "xml_bin/island15_mindboggle_prop_eyesL_bg.bin",
        layer = "gridLayer",
        priority = 4100,
        volume = 1,
        instrument = "015_prop_eyes_solo.bin",
        instruments = {
          [4] = "015_prop_eyes_finale.bin"
        }
      },
      prop_eyesL_fg = {
        minPower = 3,
        animFile = "xml_bin/island15_mindboggle_prop_eyesL_fg.bin",
        layer = "gridLayer1",
        priority = 10,
        volume = 0,
        instrument = "015_prop_eyes_solo.bin",
        instruments = {
          [4] = "015_prop_eyes_finale.bin"
        }
      },
      prop_eyesR_bg = {
        minPower = 3,
        animFile = "xml_bin/island15_mindboggle_prop_eyesR_bg.bin",
        layer = "gridLayer",
        priority = 4100,
        volume = 0,
        instrument = "015_prop_eyes_solo.bin",
        instruments = {
          [4] = "015_prop_eyes_finale.bin"
        }
      },
      prop_eyesR_fg = {
        minPower = 3,
        animFile = "xml_bin/island15_mindboggle_prop_eyesR_fg.bin",
        layer = "gridLayer1",
        priority = 10,
        volume = 0,
        instrument = "015_prop_eyes_solo.bin",
        instruments = {
          [4] = "015_prop_eyes_finale.bin"
        }
      },
      prop_tentacleL01 = {
        minPower = 2,
        animFile = "xml_bin/island15_mindboggle_prop_tentacleL01.bin",
        volume = 1,
        instrument = "015_prop_tentacles_solo.bin",
        instruments = {
          [4] = "015_prop_tentacles_finale.bin"
        }
      },
      prop_tentacleL02 = {
        minPower = 2,
        animFile = "xml_bin/island15_mindboggle_prop_tentacle02.bin",
        volume = 0,
        instrument = "015_prop_tentacles_solo.bin",
        instruments = {
          [4] = "015_prop_tentacles_finale.bin"
        }
      },
      prop_tentacleL03 = {
        minPower = 2,
        animFile = "xml_bin/island15_mindboggle_prop_tentacle03.bin",
        volume = 0,
        instrument = "015_prop_tentacles_solo.bin",
        instruments = {
          [4] = "015_prop_tentacles_finale.bin"
        }
      },
      prop_tentacleL04 = {
        minPower = 2,
        animFile = "xml_bin/island15_mindboggle_prop_tentacleL04.bin",
        volume = 0,
        instrument = "015_prop_tentacles_solo.bin",
        instruments = {
          [4] = "015_prop_tentacles_finale.bin"
        }
      },
      prop_tentacleL05 = {
        minPower = 2,
        animFile = "xml_bin/island15_mindboggle_prop_tentacle05.bin",
        volume = 0,
        instrument = "015_prop_tentacles_solo.bin",
        instruments = {
          [4] = "015_prop_tentacles_finale.bin"
        }
      },
      prop_tentacleL06 = {
        minPower = 2,
        animFile = "xml_bin/island15_mindboggle_prop_tentacle06.bin",
        volume = 0,
        instrument = "015_prop_tentacles_solo.bin",
        instruments = {
          [4] = "015_prop_tentacles_finale.bin"
        }
      },
      prop_tentacleL07 = {
        minPower = 2,
        animFile = "xml_bin/island15_mindboggle_prop_tentacle07.bin",
        volume = 0,
        instrument = "015_prop_tentacles_solo.bin",
        instruments = {
          [4] = "015_prop_tentacles_finale.bin"
        }
      },
      prop_tentacleL08 = {
        minPower = 2,
        animFile = "xml_bin/island15_mindboggle_prop_tentacleL08.bin",
        volume = 0,
        instrument = "015_prop_tentacles_solo.bin",
        instruments = {
          [4] = "015_prop_tentacles_finale.bin"
        }
      },
      prop_tentacleR01 = {
        minPower = 2,
        animFile = "xml_bin/island15_mindboggle_prop_tentacleR01.bin",
        volume = 0,
        instrument = "015_prop_tentacles_solo.bin",
        instruments = {
          [4] = "015_prop_tentacles_finale.bin"
        }
      },
      prop_tentacleR02 = {
        minPower = 2,
        animFile = "xml_bin/island15_mindboggle_prop_tentacle02.bin",
        volume = 0,
        instrument = "015_prop_tentacles_solo.bin",
        instruments = {
          [4] = "015_prop_tentacles_finale.bin"
        }
      },
      prop_tentacleR03 = {
        minPower = 2,
        animFile = "xml_bin/island15_mindboggle_prop_tentacle03.bin",
        volume = 0,
        instrument = "015_prop_tentacles_solo.bin",
        instruments = {
          [4] = "015_prop_tentacles_finale.bin"
        }
      },
      prop_tentacleR04 = {
        minPower = 2,
        animFile = "xml_bin/island15_mindboggle_prop_tentacleR04.bin",
        volume = 0,
        instrument = "015_prop_tentacles_solo.bin",
        instruments = {
          [4] = "015_prop_tentacles_finale.bin"
        }
      },
      prop_tentacleR05 = {
        minPower = 2,
        animFile = "xml_bin/island15_mindboggle_prop_tentacle05.bin",
        volume = 0,
        instrument = "015_prop_tentacles_solo.bin",
        instruments = {
          [4] = "015_prop_tentacles_finale.bin"
        }
      },
      prop_tentacleR06 = {
        minPower = 2,
        animFile = "xml_bin/island15_mindboggle_prop_tentacle06.bin",
        volume = 0,
        instrument = "015_prop_tentacles_solo.bin",
        instruments = {
          [4] = "015_prop_tentacles_finale.bin"
        }
      },
      prop_tentacleR07 = {
        minPower = 2,
        animFile = "xml_bin/island15_mindboggle_prop_tentacle07.bin",
        volume = 0,
        instrument = "015_prop_tentacles_solo.bin",
        instruments = {
          [4] = "015_prop_tentacles_finale.bin"
        }
      },
      prop_tentacleR08 = {
        minPower = 2,
        animFile = "xml_bin/island15_mindboggle_prop_tentacleR08.bin",
        volume = 0,
        instrument = "015_prop_tentacles_solo.bin",
        instruments = {
          [4] = "015_prop_tentacles_finale.bin"
        }
      },
      prop_meteors = {
        minPower = 1,
        animFile = "xml_bin/island15_prop_meteors.bin",
        layer = "gridLayer",
        priority = 4000,
        instrument = "015_prop_meteors_solo.bin",
        instruments = {
          [4] = "015_prop_meteors_finale.bin"
        }
      }
    }
  },
  {
    islandId = 115,
    themeId = -1,
    props = {
      prop_eyesL_bg = {
        minPower = 3,
        animFile = "xml_bin/island15_mirror_prop_eyesL_bg.bin",
        layer = "gridLayer",
        priority = 4100,
        volume = 1,
        instrument = "015_prop_eyes_solo.bin",
        instruments = {
          [4] = "015_prop_eyes_finale.bin"
        }
      },
      prop_eyesL_fg = {
        minPower = 3,
        animFile = "xml_bin/island15_mirror_prop_eyesL_fg.bin",
        layer = "gridLayer1",
        priority = 10,
        volume = 0,
        instrument = "015_prop_eyes_solo.bin",
        instruments = {
          [4] = "015_prop_eyes_finale.bin"
        }
      },
      prop_eyesR_bg = {
        minPower = 3,
        animFile = "xml_bin/island15_mirror_prop_eyesR_bg.bin",
        layer = "gridLayer",
        priority = 4100,
        volume = 0,
        instrument = "015_prop_eyes_solo.bin",
        instruments = {
          [4] = "015_prop_eyes_finale.bin"
        }
      },
      prop_eyesR_fg = {
        minPower = 3,
        animFile = "xml_bin/island15_mirror_prop_eyesR_fg.bin",
        layer = "gridLayer1",
        priority = 10,
        volume = 0,
        instrument = "015_prop_eyes_solo.bin",
        instruments = {
          [4] = "015_prop_eyes_finale.bin"
        }
      },
      prop_tentacleL_01 = {
        minPower = 2,
        animFile = "xml_bin/island15_mirror_prop_tentacleL01.bin",
        volume = 1,
        instrument = "015_prop_tentacles_solo.bin",
        instruments = {
          [4] = "015_prop_tentacles_finale.bin"
        }
      },
      prop_tentacleL_02 = {
        minPower = 2,
        animFile = "xml_bin/island15_mirror_prop_tentacleL02.bin",
        volume = 0,
        instrument = "015_prop_tentacles_solo.bin",
        instruments = {
          [4] = "015_prop_tentacles_finale.bin"
        }
      },
      prop_tentacleL_03 = {
        minPower = 2,
        animFile = "xml_bin/island15_mirror_prop_tentacleL03.bin",
        volume = 0,
        instrument = "015_prop_tentacles_solo.bin",
        instruments = {
          [4] = "015_prop_tentacles_finale.bin"
        }
      },
      prop_tentacleL_04 = {
        minPower = 2,
        animFile = "xml_bin/island15_mirror_prop_tentacle04.bin",
        volume = 0,
        instrument = "015_prop_tentacles_solo.bin",
        instruments = {
          [4] = "015_prop_tentacles_finale.bin"
        }
      },
      prop_tentacleL_05 = {
        minPower = 2,
        animFile = "xml_bin/island15_mirror_prop_tentacleL05.bin",
        volume = 0,
        instrument = "015_prop_tentacles_solo.bin",
        instruments = {
          [4] = "015_prop_tentacles_finale.bin"
        }
      },
      prop_tentacleR_01 = {
        minPower = 2,
        animFile = "xml_bin/island15_mirror_prop_tentacleR01.bin",
        volume = 0,
        instrument = "015_prop_tentacles_solo.bin",
        instruments = {
          [4] = "015_prop_tentacles_finale.bin"
        }
      },
      prop_tentacleR_02 = {
        minPower = 2,
        animFile = "xml_bin/island15_mirror_prop_tentacleR02.bin",
        volume = 0,
        instrument = "015_prop_tentacles_solo.bin",
        instruments = {
          [4] = "015_prop_tentacles_finale.bin"
        }
      },
      prop_tentacleR_03 = {
        minPower = 2,
        animFile = "xml_bin/island15_mirror_prop_tentacleR03.bin",
        volume = 0,
        instrument = "015_prop_tentacles_solo.bin",
        instruments = {
          [4] = "015_prop_tentacles_finale.bin"
        }
      },
      prop_tentacleR_04 = {
        minPower = 2,
        animFile = "xml_bin/island15_mirror_prop_tentacle04.bin",
        volume = 0,
        instrument = "015_prop_tentacles_solo.bin",
        instruments = {
          [4] = "015_prop_tentacles_finale.bin"
        }
      },
      prop_tentacleR_05 = {
        minPower = 2,
        animFile = "xml_bin/island15_mirror_prop_tentacleR05.bin",
        volume = 0,
        instrument = "015_prop_tentacles_solo.bin",
        instruments = {
          [4] = "015_prop_tentacles_finale.bin"
        }
      },
      prop_tentacleR_06 = {
        minPower = 2,
        animFile = "xml_bin/island15_mirror_prop_tentacleR06.bin",
        volume = 0,
        instrument = "015_prop_tentacles_solo.bin",
        instruments = {
          [4] = "015_prop_tentacles_finale.bin"
        }
      },
      prop_meteors = {
        minPower = 1,
        animFile = "xml_bin/island15_mirror_prop_meteors.bin",
        layer = "gridLayer",
        priority = 4000,
        instrument = "015_prop_meteors_solo.bin",
        instruments = {
          [4] = "015_prop_meteors_finale.bin"
        }
      }
    }
  },
  {
    islandId = 16,
    themeId = -1,
    props = {
      prop_L_facevines = {
        minPower = 3,
        animFile = "xml_bin/island16_prop_L_facevines.bin",
        layer = "gridLayer1",
        volume = 1,
        instrument = "016_prop_facevines_solo.bin",
        instruments = {
          [4] = "016_prop_facevines_finale.bin"
        }
      },
      prop_R_facevines = {
        minPower = 3,
        animFile = "xml_bin/island16_prop_R_facevines.bin",
        layer = "gridLayer1",
        volume = 1,
        instrument = "016_prop_facevines_solo.bin",
        instruments = {
          [4] = "016_prop_facevines_finale.bin"
        }
      },
      prop_L_front_mushrooms = {
        minPower = 2,
        animFile = "xml_bin/island16_prop_L_front_mushrooms.bin",
        layer = "gridLayer1",
        volume = 1,
        instrument = "016_prop_mushrooms_solo.bin",
        instruments = {
          [4] = "016_prop_mushrooms_finale.bin"
        }
      },
      prop_R_front_mushrooms = {
        minPower = 2,
        animFile = "xml_bin/island16_prop_R_front_mushrooms.bin",
        layer = "gridLayer1",
        volume = 1,
        instrument = "016_prop_mushrooms_solo.bin",
        instruments = {
          [4] = "016_prop_mushrooms_finale.bin"
        }
      },
      prop_L_back_mushrooms = {
        minPower = 2,
        animFile = "xml_bin/island16_prop_L_back_mushrooms.bin",
        volume = 1,
        instrument = "016_prop_mushrooms_solo.bin",
        instruments = {
          [4] = "016_prop_mushrooms_finale.bin"
        }
      },
      prop_R_back_mushrooms = {
        minPower = 2,
        animFile = "xml_bin/island16_prop_R_back_mushrooms.bin",
        volume = 1,
        instrument = "016_prop_mushrooms_solo.bin",
        instruments = {
          [4] = "016_prop_mushrooms_finale.bin"
        }
      },
      prop_L_ear = {
        minPower = 1,
        animFile = "xml_bin/island16_prop_L_ear.bin",
        layer = "gridLayer",
        volume = 1,
        instrument = "016_prop_earclouds_solo.bin",
        instruments = {
          [4] = "016_prop_earclouds_finale.bin"
        }
      },
      prop_R_ear = {
        minPower = 1,
        animFile = "xml_bin/island16_prop_R_ear.bin",
        layer = "gridLayer",
        volume = 1,
        instrument = "016_prop_earclouds_solo.bin",
        instruments = {
          [4] = "016_prop_earclouds_finale.bin"
        }
      }
    }
  },
  {
    islandId = 16,
    themeId = 15,
    props = {
      prop_L_facevines = {
        minPower = 3,
        animFile = "xml_bin/island16_cloverspell_prop_L_facevines.bin",
        layer = "gridLayer1",
        volume = 1,
        instrument = "016_prop_facevines_solo.bin",
        instruments = {
          [4] = "016_prop_facevines_finale.bin"
        }
      },
      prop_R_facevines = {
        minPower = 3,
        animFile = "xml_bin/island16_cloverspell_prop_R_facevines.bin",
        layer = "gridLayer1",
        volume = 1,
        instrument = "016_prop_facevines_solo.bin",
        instruments = {
          [4] = "016_prop_facevines_finale.bin"
        }
      },
      prop_L_front_mushrooms = {
        minPower = 2,
        animFile = "xml_bin/island16_cloverspell_prop_L_front_mushrooms.bin",
        layer = "gridLayer1",
        volume = 1,
        instrument = "016_prop_mushrooms_solo.bin",
        instruments = {
          [4] = "016_prop_mushrooms_finale.bin"
        }
      },
      prop_R_front_mushrooms = {
        minPower = 2,
        animFile = "xml_bin/island16_cloverspell_prop_R_front_mushrooms.bin",
        layer = "gridLayer1",
        volume = 1,
        instrument = "016_prop_mushrooms_solo.bin",
        instruments = {
          [4] = "016_prop_mushrooms_finale.bin"
        }
      },
      prop_L_back_mushrooms = {
        minPower = 2,
        animFile = "xml_bin/island16_cloverspell_prop_L_back_mushrooms.bin",
        volume = 1,
        instrument = "016_prop_mushrooms_solo.bin",
        instruments = {
          [4] = "016_prop_mushrooms_finale.bin"
        }
      },
      prop_R_back_mushrooms = {
        minPower = 2,
        animFile = "xml_bin/island16_cloverspell_prop_R_back_mushrooms.bin",
        volume = 1,
        instrument = "016_prop_mushrooms_solo.bin",
        instruments = {
          [4] = "016_prop_mushrooms_finale.bin"
        }
      },
      prop_L_ear = {
        minPower = 1,
        animFile = "xml_bin/island16_cloverspell_prop_L_ear.bin",
        layer = "gridLayer",
        volume = 1,
        instrument = "016_prop_earclouds_solo.bin",
        instruments = {
          [4] = "016_prop_earclouds_finale.bin"
        }
      },
      prop_R_ear = {
        minPower = 1,
        animFile = "xml_bin/island16_cloverspell_prop_R_ear.bin",
        layer = "gridLayer",
        volume = 1,
        instrument = "016_prop_earclouds_solo.bin",
        instruments = {
          [4] = "016_prop_earclouds_finale.bin"
        }
      }
    }
  },
  {
    islandId = 116,
    themeId = -1,
    props = {
      prop_L_facevines = {
        minPower = 3,
        animFile = "xml_bin/island16_mirror_prop_L_facevines.bin",
        layer = "gridLayer1",
        volume = 1,
        instrument = "016_prop_facevines_solo.bin",
        instruments = {
          [4] = "016_prop_facevines_finale.bin"
        }
      },
      prop_R_facevines = {
        minPower = 3,
        animFile = "xml_bin/island16_mirror_prop_R_facevines.bin",
        layer = "gridLayer1",
        volume = 1,
        instrument = "016_prop_facevines_solo.bin",
        instruments = {
          [4] = "016_prop_facevines_finale.bin"
        }
      },
      prop_L_front_mushrooms = {
        minPower = 2,
        animFile = "xml_bin/island16_mirror_prop_L_front_mushrooms.bin",
        layer = "gridLayer1",
        volume = 1,
        instrument = "016_prop_mushrooms_solo.bin",
        instruments = {
          [4] = "016_prop_mushrooms_finale.bin"
        }
      },
      prop_R_front_mushrooms = {
        minPower = 2,
        animFile = "xml_bin/island16_mirror_prop_R_front_mushrooms.bin",
        layer = "gridLayer1",
        volume = 1,
        instrument = "016_prop_mushrooms_solo.bin",
        instruments = {
          [4] = "016_prop_mushrooms_finale.bin"
        }
      },
      prop_L_back_mushrooms = {
        minPower = 2,
        animFile = "xml_bin/island16_mirror_prop_L_back_mushrooms.bin",
        volume = 1,
        instrument = "016_prop_mushrooms_solo.bin",
        instruments = {
          [4] = "016_prop_mushrooms_finale.bin"
        }
      },
      prop_R_back_mushrooms = {
        minPower = 2,
        animFile = "xml_bin/island16_mirror_prop_R_back_mushrooms.bin",
        volume = 1,
        instrument = "016_prop_mushrooms_solo.bin",
        instruments = {
          [4] = "016_prop_mushrooms_finale.bin"
        }
      },
      prop_L_ear = {
        minPower = 1,
        animFile = "xml_bin/island16_mirror_prop_L_ear.bin",
        volume = 1,
        instrument = "016_prop_earclouds_solo.bin",
        instruments = {
          [4] = "016_prop_earclouds_finale.bin"
        }
      },
      prop_R_ear = {
        minPower = 1,
        animFile = "xml_bin/island16_mirror_prop_R_ear.bin",
        volume = 1,
        instrument = "016_prop_earclouds_solo.bin",
        instruments = {
          [4] = "016_prop_earclouds_finale.bin"
        }
      }
    }
  }
}
local function findProps(islandId, themeId)
  for _, v in pairs(islandProps) do
    if v.islandId == islandId and v.themeId == themeId then
      return v
    end
  end
  return nil
end
function IslandPropData:GetProps(islandId, themeId, propList)
  local propData = findProps(islandId, themeId)
  if propData then
    for k, v in pairs(propData.props) do
      local prop = game.IslandPropData()
      prop.name = k
      prop.animFile = v.animFile
      prop.attach = v.attach or ""
      prop.layer = v.layer or ""
      prop.priority = v.priority or -0.001
      prop.minPower = v.minPower or 0
      prop.maxPower = v.maxPower or 0
      prop.volume = v.volume or 1
      prop.instrument = v.instrument or ""
      if v.instruments then
        for power, instrument in pairs(v.instruments) do
          prop:addInstrument(power, instrument)
        end
      end
      propList.props:push_back(prop)
    end
    return true
  end
  return false
end
function IslandPropData:AllPropInstruments(islandId, instrumentList)
  instrumentList:clear()
  local instrumentSet = {}
  for _, v in pairs(islandProps) do
    if v.islandId == islandId then
      local props = v.props
      for k, v2 in pairs(props) do
        if v2.instrument then
          instrumentSet[v2.instrument] = true
        end
        if v2.instruments then
          for power, instrument in pairs(v2.instruments) do
            instrumentSet[instrument] = true
          end
        end
      end
    end
  end
  for k, v in pairs(instrumentSet) do
    instrumentList:push_back(k)
  end
  return true
end
return IslandPropData
