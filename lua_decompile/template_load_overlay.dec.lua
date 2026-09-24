local ElementFader = include("ElementFader")
local template_load_overlay = {FADE_TIME = 0.2}
function template_load_overlay:onPostInit()
  self.fader = ElementFader.New(self, {
    duration = self.FADE_TIME
  })
end
function template_load_overlay:onTick(dt)
  if self.TopElement.Touch:V("enabled"):GetInt() == 0 then
    return
  end
  self.fader:tick(dt)
end
local setVisibleInternal = function(self, value)
  if value then
    self.TopElement.Touch:V("enabled"):SetInt(1)
    self.TopElement.blackout:V("visible"):SetInt(1)
    self.TopElement.LoaderElement.LoaderBG:V("visible"):SetInt(1)
    self.TopElement.LoaderElement.Loader:V("visible"):SetInt(1)
  else
    self.TopElement.Touch:V("enabled"):SetInt(0)
    self.TopElement.blackout:V("visible"):SetInt(0)
    self.TopElement.LoaderElement.LoaderBG:V("visible"):SetInt(0)
    self.TopElement.LoaderElement.Loader:V("visible"):SetInt(0)
  end
end
function template_load_overlay:setVisible(value, fade, fadeCallback)
  if value then
    if self.fader then
      setVisibleInternal(self, true)
      function self.fader.onDone(fader, showing)
        if fadeCallback then
          fadeCallback(true)
        end
      end
      self.fader:Show(not fade)
    else
      setVisibleInternal(self, true)
      if fadeCallback then
        fadeCallback(true)
      end
    end
  elseif self.fader then
    function self.fader.onDone(fader, showing)
      if fadeCallback then
        fadeCallback(false)
      end
      setVisibleInternal(self, false)
    end
    self.fader:Hide(not fade)
  else
    setVisibleInternal(self, false)
    if fadeCallback then
      fadeCallback(self, false)
    end
  end
  self.visible = value
end
function template_load_overlay:updateLoader(completion)
  local loader = self.TopElement.LoaderElement.Loader
  local width = loader("width"):GetInt()
  if completion < 0 then
    completion = 0
  end
  if completion > 1 then
    completion = 1
  end
  loader("maskW"):SetFloat(width * completion)
end
local template_load_overlay_TopElement = {}
local template_load_overlay_TopElement_blackout = {}
function template_load_overlay_TopElement_blackout:onInit(element)
  self.maxFade = 0.5
  self("spriteName"):SetString("__BUILTIN__WHITE_TEXTURE")
  self:setColor(0, 0, 0)
  self("alpha"):SetFloat(0.5)
  self:setScale(lua_sys.Vector2(lua_sys.screenWidth() * 0.25, lua_sys.screenHeight() * 0.25))
  self("layer"):SetString("Loading")
end
template_load_overlay_TopElement.blackout = template_load_overlay_TopElement_blackout
local template_load_overlay_TopElement_LoaderElement = {}
local template_load_overlay_TopElement_LoaderElement_LoaderBG = {}
function template_load_overlay_TopElement_LoaderElement_LoaderBG:onInit(element)
  self("spriteName"):SetString("gfx/loadbar_bg")
  self("layer"):SetString("Loading")
  self("size"):SetFloat(game.hudScale() * 0.5)
end
template_load_overlay_TopElement_LoaderElement.LoaderBG = template_load_overlay_TopElement_LoaderElement_LoaderBG
local template_load_overlay_TopElement_LoaderElement_Loader = {}
function template_load_overlay_TopElement_LoaderElement_Loader:onInit(element)
  self("spriteName"):SetString("gfx/loadbar")
  self("layer"):SetString("Loading")
  self("size"):SetFloat(game.hudScale() * 0.5)
end
template_load_overlay_TopElement_LoaderElement.Loader = template_load_overlay_TopElement_LoaderElement_Loader
template_load_overlay_TopElement.LoaderElement = template_load_overlay_TopElement_LoaderElement
template_load_overlay.TopElement = template_load_overlay_TopElement
return template_load_overlay
