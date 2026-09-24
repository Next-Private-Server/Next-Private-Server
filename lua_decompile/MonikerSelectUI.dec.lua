local MonikerSelectUI = {}
function MonikerSelectUI.onInit(element)
  lua_sys.playSoundFx("audio/sfx/menu_slide.wav")
end
function MonikerSelectUI.onPostInit(element)
  game.hideContextBar()
  MonikerSelectUI.Show(element)
end
function MonikerSelectUI.queuePop(element)
  MonikerSelectUI.Hide(element)
  manager:showContextBar()
end
function MonikerSelectUI.Show(element)
  element.Bg:Show()
  element:GetElement("Fade"):DoStoredScript("show")
  lua_sys.playSoundFx("audio/sfx/menu_slide.wav")
end
function MonikerSelectUI.Hide(element)
  element.Bg:Hide()
  element:GetElement("Fade"):DoStoredScript("hide")
  lua_sys.playSoundFx("audio/sfx/menu_slide.wav")
end
return MonikerSelectUI
