local ReportMenu = {}
function ReportMenu.ShowTribeName()
  return game.friendIslandType() == game.IslandType_TRIBAL and not game.alreadyReportedTribeName()
end
function ReportMenu.ShowUserName()
  return game.friendIslandType() ~= game.IslandType_TRIBAL and game.showReportDisplayName() and not game.alreadyReportedDisplayName()
end
function ReportMenu.ShowSongName()
  return game.friendIslandType() == game.IslandType_COMPOSER and not game.alreadyReportedSongName()
end
function ReportMenu.ShowIslandDesign()
  return not game.alreadyReportedIslandContent()
end
function ReportMenu.ShowButton(index)
  local buttonOrder = {
    [1] = ReportMenu.ShowUserName,
    [2] = ReportMenu.ShowTribeName,
    [3] = ReportMenu.ShowSongName,
    [4] = ReportMenu.ShowIslandDesign
  }
  local func = buttonOrder[index]
  if func then
    return func()
  end
  return false
end
return ReportMenu
