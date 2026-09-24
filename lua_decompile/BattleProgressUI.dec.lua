local ScrollingListHelper = include("ScrollingListHelper")
local MenuHelpers = include("MenuHelpers")
local BattleProgressUI = {}
function BattleProgressUI.ListOnInit(element)
  ScrollingListHelper.ListInit(element, {
    direction = lua_sys.MenuSwipeComponent_SwipeDirectionVertical,
    spacing = 4 * game.hudScale()
  })
end
function BattleProgressUI.ListOnTick(element, dt)
  ScrollingListHelper.ListTick(element, dt)
  MenuHelpers.ForEachEntry(element, function(entry)
    entry("clipX"):SetFloat(element:absX())
    entry("clipY"):SetFloat(element:absY())
    entry("clipW"):SetFloat(element:absW())
    entry("clipH"):SetFloat(element:absH())
    entry:DoStoredScript("updateClipping")
  end)
end
function BattleProgressUI.ListClear(element)
  ScrollingListHelper.ListClear(element)
end
function BattleProgressUI.PanelOnInit(element)
  element:setPositionBroadcast(true)
  element("IsShowing"):SetInt(0)
end
function BattleProgressUI.PanelShow(element)
  local isShowing = element("IsShowing"):GetInt()
  if isShowing == 0 then
    element.BG("visible"):SetInt(1)
    element.Sprite("visible"):SetInt(1)
    element.PIP_SCROLLBAR.Sprite("visible"):SetInt(1)
    element.PIP_SCROLLMARKER.Marker("visible"):SetInt(1)
    element.PIP_LIST:DoStoredScript("populate")
    element.PIP_LIST:DoStoredScript("onTick")
    element.PIP_LIST.Touch("enabled"):SetInt(1)
    element("IsShowing"):SetInt(1)
    element:parent():DoStoredScript("OnProgressPanelShow")
  end
end
function BattleProgressUI.PanelHide(element)
  local isShowing = element("IsShowing"):GetInt()
  if isShowing == 1 then
    element.BG("visible"):SetInt(0)
    element.Sprite("visible"):SetInt(0)
    element.PIP_SCROLLBAR.Sprite("visible"):SetInt(0)
    element.PIP_SCROLLMARKER.Marker("visible"):SetInt(0)
    element.PIP_LIST:DoStoredScript("clear")
    element.PIP_LIST.Touch("enabled"):SetInt(0)
    element("IsShowing"):SetInt(0)
    element:parent():DoStoredScript("OnProgressPanelHide")
  end
end
return BattleProgressUI
