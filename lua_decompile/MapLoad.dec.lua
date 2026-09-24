local ElementFader = include("ElementFader")
local MapLoad = {}
function MapLoad:onPostInit()
  local function updateLoadbarPosition()
    local mapContext = game.mapContext()
    if mapContext then
      local menu = mapContext:menu()
      if menu then
        local main = menu.Main
        if main then
          local x = main.IslandInfo:absX() + main.IslandInfo:absW() * 0.5
          local y = main.IslandInfo:absY() + main.IslandInfo:absH() * 0.5 + 64 * game.bgScale()
          self.LoaderElement:setOrientation(lua_sys.MenuOrientation(x, y, 2, lua_sys.HCENTER, lua_sys.VCENTER))
          self.LoaderElement:setRelativeObjectAnchors(lua_sys.LEFT, lua_sys.TOP)
        end
      end
    end
  end
  local function onDone(fader, showing)
    if not showing then
      self:root():kill()
    end
  end
  self.fader = ElementFader.New(self, {
    autoTick = true,
    duration = 0.2,
    onDone = onDone
  })
  self.fader:Show()
end
function MapLoad:FadeOut()
  self.Touch:V("enabled"):SetInt(0)
  self.fader:Hide()
end
function MapLoad:updateLoader(completion, state)
  local loader = self.LoaderElement.Loader
  local width = loader("width"):GetInt()
  if state == 0 then
    loader("maskW"):SetFloat(0)
  elseif state == 1 then
    loader("maskW"):SetFloat(width * (completion * 0.25))
  elseif state == 2 then
    loader("maskW"):SetFloat(width * (0.25 + completion * 0.75))
  elseif state == 3 then
    loader("maskW"):SetFloat(width)
  end
end
return MapLoad
