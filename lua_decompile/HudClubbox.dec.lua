local FadeTransition = include("FadeTransition")
local Coroutines = include("Coroutines")
local HudClubbox = {
  HypeBar = {},
  TokenCounter = {},
  ViewButton = {},
  Logo = {
    Sprite = {}
  },
  InfoCard = {
    SongName = {},
    BandName = {},
    AlbumName = {},
    ReleaseDate = {}
  }
}
function HudClubbox:onInit()
  self.startTime = game.serverTime()
  self.tickables = {}
  self.inMemoryMode = game.clubboxContext():mode() == game.ClubboxMode_MEMORY
  self:SetupGenericListener(game.engineReceiver(), "sys::msg::MsgPopPopUpGlobal", "gotMsgPopPopUpGlobal")
end
function HudClubbox:onPostInit()
  self.fadeTransition = FadeTransition:new({
    duration = 1,
    onUpdate = function(alpha)
      self.ScreenFlash("alpha"):SetFloat(alpha)
    end
  })
  self.tickables.Fade = self.fadeTransition
  self.ViewFader = FadeTransition:new({
    duration = 0.33,
    minFade = 0.2,
    maxFade = 0.8,
    onUpdate = function(alpha)
      self.ViewButton.Sprite("alpha"):SetFloat(alpha)
    end
  })
  self.tickables.ViewFader = self.ViewFader
  self.ViewFader:SetAlpha(0.8)
  if self.inMemoryMode then
    self.ViewButton("auto"):SetInt(0)
    self.HypeBar:DoStoredScript("setInvisibleOnIsland")
    self.TokenCounter:DoStoredScript("hide")
    do
      local actData = game.getClubboxActData(game.clubboxContext():actId())
      self.InfoCard.SongName("text"):SetString(actData:songName())
      self.InfoCard.BandName("text"):SetString(actData:title())
      self.InfoCard.AlbumName("text"):SetString(actData:albumName())
      self.InfoCard.ReleaseDate("text"):SetString(actData:debutDate())
      local offset = self.InfoCard.SongName:absH()
      self.InfoCard.BandName("yOffset"):SetFloat(offset)
      offset = offset + self.InfoCard.BandName:absH()
      self.InfoCard.AlbumName("yOffset"):SetFloat(offset)
      offset = offset + self.InfoCard.AlbumName:absH()
      self.InfoCard.ReleaseDate("yOffset"):SetFloat(offset)
      local pulseSize = self.Logo.Sprite:GetVar("size"):GetFloat()
      local TweenerPingPong = include("TweenerPingPong")
      local pulser = TweenerPingPong:new({
        loopTime = 0.67,
        ease = lua_sys.Quadratic_EaseIn,
        onUpdate = function(target, t)
          target:GetVar("size"):SetFloat(pulseSize * (1 + t * 0.05))
        end,
        targets = {
          self.Logo.Sprite
        }
      })
      self.tickables.LogoPulser = pulser
      local fader = FadeTransition:new({
        duration = 1.5,
        maxFade = 1,
        onUpdate = function(alpha)
          self.InfoCard:SetAlpha(alpha)
        end
      })
      fader:SetAlpha(0)
      self.tickables.InfoCardFader = fader
      self.tickables.ShaderNoise = {
        Tick = function(t, dt)
          local shader = game.getShader("ShaderClubboxMemory")
          if shader then
            shader:getUniform("u_Random"):setFloat(math.random())
          end
        end
      }
      self.lastMidiTime = game.getMidiCurrentTime()
      self:ShowInfoCard()
    end
  else
    self.Logo:SetVisible(false)
    self.InfoCard:SetVisible(false)
  end
end
function HudClubbox:onTick(dt)
  for _, tickable in pairs(self.tickables) do
    if tickable.Tick then
      tickable:Tick(dt)
    end
  end
  if self.inMemoryMode then
    local currentTime = game.getMidiCurrentTime()
    if currentTime < self.lastMidiTime then
      self:ShowInfoCard()
    end
    self.lastMidiTime = currentTime
  end
end
function HudClubbox:onDestroy()
  if self.infoCardCo then
    KillCoroutine(self.infoCardCo)
  end
  if self.startTime ~= nil then
    game.logEvent("clubbox_hud", "time_spent_secs", tostring((game.serverTime() - self.startTime) / 1000))
    self.startTime = 0
  end
end
function HudClubbox:hideHUD()
  self.HypeBar:DoStoredScript("hide")
  self.TokenCounter:DoStoredScript("hide")
end
function HudClubbox:showHUD()
  if self.inMemoryMode then
    return
  end
  self.HypeBar:DoStoredScript("show")
  self.TokenCounter:DoStoredScript("show")
end
function HudClubbox.Logo:SetVisible(visible)
  self.Sprite("visible"):SetInt(visible and 1 or 0)
end
function HudClubbox.Logo:SetAlpha(alpha)
  self.Sprite("alpha"):SetFloat(alpha)
end
function HudClubbox.InfoCard:SetVisible(visible)
  self.SongName("visible"):SetInt(visible and 1 or 0)
  self.BandName("visible"):SetInt(visible and 1 or 0)
  self.AlbumName("visible"):SetInt(visible and 1 or 0)
  self.ReleaseDate("visible"):SetInt(visible and 1 or 0)
end
function HudClubbox.InfoCard:SetAlpha(alpha)
  self.SongName("alpha"):SetFloat(alpha)
  self.BandName("alpha"):SetFloat(alpha)
  self.AlbumName("alpha"):SetFloat(alpha)
  self.ReleaseDate("alpha"):SetFloat(alpha)
end
function HudClubbox:ShowInfoCardCo()
  if not coroutine.running() then
    print("need to run as a coroutine!")
    return
  end
  Coroutines.WaitForSeconds(4)
  self.tickables.InfoCardFader:Show()
  Coroutines.WaitForSeconds(8)
  self.tickables.InfoCardFader:Hide()
  self.infoCardCo = nil
end
function HudClubbox:ShowInfoCard()
  if not self.infoCardCo then
    self.infoCardCo = RunIndyCoroutine(self.ShowInfoCardCo, self)
  end
end
function HudClubbox:gotMsgPopPopUpGlobal(msg)
  if msg.menuName == "hype_game_prestige" then
    self.fadeTransition:SetAlpha(1)
    self.fadeTransition:Hide()
  end
end
function HudClubbox:addTickable(name, tickable)
  self.tickables[name] = tickable
end
function HudClubbox:getTickable(name)
  return self.tickables[name]
end
return HudClubbox
